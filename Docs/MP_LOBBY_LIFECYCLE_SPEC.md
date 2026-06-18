# MP Lobby Lifecycle Spec — Wire-Roster Authority

**Status:** L1 in progress (2026-06-18) — launch-time N + min-1-guest on `6231a20` base; lifecycle logging added.  
**Branch:** `feature/lobby-discovery`  
**Read with:** `AGENTS.md`, `CURRENT_STATE.md`, `Docs/MP_LOBBY_TICKET_HANDOVER.md`

---

## Problem

Join/leave/rejoin fails because **three truths diverge**:

| Layer | Tracks | Can lie |
|-------|--------|---------|
| Steam lobby | Physical lobby membership | Ghost peers after leave |
| Wire roster | `session.joined_player_ids` | Authoritative when correct |
| Guest local flags | `pending_join_wire_sent`, flow state | Stale shortcuts |

Handlers run on different triggers (`gateb_ok`, `gatec_ok`, discovery merge, reconcile). Each patch closes one gap; the next edge case finds another.

**Rule going forward:** Wire roster is the **only** join truth. Steam is transport. UI and launch read roster only.

---

## Roles (unchanged)

- **Steam** — discovery shell, lobby membership, P2P transport (Gate B/C).
- **Session ticket** — who may publish, launch, cancel (`host_steam_id:session_number`).
- **Wire roster** — who is in the game (`joined_player_ids`, steam↔wire seat maps).
- **Launch-time N** — `#joined_player_ids` at Launch (Phase 1 product direction stays).

---

## Guest lifecycle

```
DISCONNECTED
    │  tap session card / enter lobby id
    ▼
STEAM_JOINING          (Steam lobby enter + gate roundtrip)
    │  wire ready (single signal, see below)
    ▼
JOIN_WIRE_PENDING      (must send lobby_join_session; no shortcuts)
    │  host adds to roster + join_accepted
    ▼
IN_ROSTER              (on wire joined_player_ids)
    │  setup_state synced + ack
    ▼
SETUP_SYNCED           (host setup_sync_player_ids[pid] == true)
    │  host launches
    ▼
IN_MATCH
```

### Guest transitions

| From | To | Trigger | Side effects |
|------|----|---------|--------------|
| `*` | `DISCONNECTED` | Back to title, host cancel, session closed | Clear **all** join flags; `steam_leave_lobby`; reset Gate B handshake |
| `DISCONNECTED` | `STEAM_JOINING` | `request_join_session` | Set `pending_join_session_id`; **clear** `pending_join_wire_sent` |
| `STEAM_JOINING` | `JOIN_WIRE_PENDING` | Wire ready | Send `lobby_join_session` exactly once per attempt |
| `JOIN_WIRE_PENDING` | `IN_ROSTER` | `lobby_join_accepted` + local id in roster | Enter MP setup |
| `IN_ROSTER` | `SETUP_SYNCED` | `setup_state_updated` applied + optional ack | — |
| `SETUP_SYNCED` | `IN_MATCH` | `match_started` | — |
| `IN_ROSTER` / `SETUP_SYNCED` | `JOIN_WIRE_PENDING` | Host evicted guest (`lobby_state_updated` / roster prune) | Clear wire-sent flag; reset handshake; **stay on setup or lobby** but not “joined” |

### Guest invariants

1. **`pending_join_wire_sent` means nothing** unless local wire id is in host roster.
2. **Never infer “joined” from flow state** (`MP_SETUP`, Steam presence, or prior session).
3. **Leave is always full disconnect** — no “soft leave” that keeps Steam membership.
4. **Rejoin is always a fresh join** — no resume from cached wire state.

---

## Host lifecycle

```
ALONE                  (roster = host only)
    │  guest join wire accepted
    ▼
GUESTS_JOINING         (roster growing; setup sync pending)
    │  all guests SETUP_SYNCED
    ▼
READY_TO_LAUNCH        (guest_count >= 1, setup valid, all synced)
    │  Launch pressed
    ▼
LAUNCHED               (terminal for lobby; match plane)
```

### Host transitions

| From | To | Trigger | Side effects |
|------|----|---------|--------------|
| `*` | `ALONE` | Last guest leaves / lobby_alone | Prune roster to host; release wire seats; emit offer upsert |
| `ALONE` | `GUESTS_JOINING` | `lobby_join_session` adds guest | Assign steam↔wire seat; fanout setup; **do not** infer from Steam enum |
| `GUESTS_JOINING` | `READY_TO_LAUNCH` | All roster guests setup-synced | Log `launch_ready` |
| `READY_TO_LAUNCH` | `LAUNCHED` | Launch | Snapshot guest ids **before** offer remove; fanout `match_started` |

### Host invariants

1. **Only `lobby_join_session` (or explicit host invite path) adds to roster** — no Steam→roster reconcile.
2. **Only `lobby_leave_session` or steam-not-in-lobby prune removes from roster** — never prune at join time.
3. **Launch requires `guest_count >= 1`** on wire roster (MP-only product rule).
4. **Discovery merge never overwrites `joined_player_ids`** when host has a wire roster (B1 — keep).

---

## Wire-ready (collapse Gate B/C signals)

Replace split handling with **one callback**:

```
on_wire_ready(peer_steam_id)
  guest: if state == STEAM_JOINING → send join wire
  host:  flush wire queue only (no roster mutation)
```

- `gatec_ok` remains internal to transport; **game.script** listens to `wire_ready` only.
- Pending join work runs in **one function** called from `wire_ready`, not duplicated on `gateb_ok` / `gatec_ok`.

---

## Retire (do not extend)

| Mechanism | Reason |
|-----------|--------|
| `multiplayer_lobby_reconcile_steam_guests_into_roster` | Steam→roster inference; causes ghost readmission |
| `pending_join_wire_sent` early exit on `MP_SETUP` | Already removed; do not reintroduce |
| Prune at start of `lobby_join_session` | Drops guests during multi-join |
| `lobby_state_updated` as no-op on guest | Guests must react to roster eviction |
| Multiple “complete pending join” triggers | Consolidate to `wire_ready` |

**Keep:** B1 discovery merge roster preservation, launch guest snapshot before offer remove, steam↔wire seat maps, launch-time N from roster.

---

## Implementation phases

### Phase L1 — State + logging (no behavior change)

- Add `mp_lobby.lifecycle_state` enum (guest/host tables above).
- Log every transition: `MP LOBBY | lifecycle guest DISCONNECTED→STEAM_JOINING`.
- Map existing code paths to states; find orphan transitions.

### Phase L2 — Join path hardening

- Single `multiplayer_lobby_on_wire_ready(self)` entry point.
- Guest: join wire only when `lifecycle == STEAM_JOINING` or evicted retry.
- Remove reconcile; remove duplicate gateb/gatec join hooks.

### Phase L3 — Leave path hardening

- Guest leave: always `steam_leave_lobby` + clear all pending + `DISCONNECTED`.
- Host leave handler: roster prune only; no forget-peer/reconcile compensators.
- Guest eviction handler: transition to `JOIN_WIRE_PENDING` or `DISCONNECTED`, not silent stale setup.

### Phase L4 — Launch gate + UI

- Launch blocked unless host state `READY_TO_LAUNCH`.
- Setup UI reads roster for names/count (not cached setup alone).

### Phase L5 — Delete dead code

- Remove reconcile, departed-steam lists, guest_join_resend_pending if superseded by lifecycle.
- Grep cleanup; update test rituals in `CURRENT_STATE.md`.

---

## Test rituals (pass/fail gates)

| # | Ritual | Pass criteria |
|---|--------|---------------|
| 1 | Solo blocked | Host alone → Launch disabled; log `launch_blocked reason=no_guests` |
| 2 | 2P join + launch | `roster=p1,p2` → launch → both in match |
| 3 | 3P join + launch | `roster=p1,p2,p3` → launch → three in match |
| 4 | **P2 leave + rejoin** | Leave → host `guests=0`; rejoin → `join_session_wire` + `roster=p1,p2`; launch OK |
| 5 | Post-abort rejoin | 3P setup → all back to FIND → rejoin both → setup → launch |

**Log grep (host, ritual 4):**

```
leave_session_roster_prune … guests=0
join_session_wire OR join_session_complete … requester=p2
roster_after_join … roster=p1,p2
launch_ready guests_synced=true
start_match … roster_guests=1
```

**Fail signals (stop, do not patch):**

- `start_match … roster_guests=0` with Steam peers connected
- Rejoin window with `gateb_ok` but no `join_session_complete` within 10s
- Second Steam id in lobby for same logical guest without leave

---

## Open product decisions

1. **Guest evicted while on setup** — auto retry join wire vs kick to FIND lobby UI?
2. **Solo host** — block launch only (current) vs hide setup until guest joins?
3. **Toggle** — ship L1–L2 behind `MP_LOBBY_LIFECYCLE_V2` for A/B against banked `f8a0958`?

---

## Suggested checkpoint before L1

Bank current dirty work or tag `pre-lifecycle-redesign` so L1+ can diff cleanly against the patch stack.
