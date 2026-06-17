# DVX Multiplayer Discovery — Current State & AI Handover

**Last updated:** 2026-06-16  
**Working path:** `/Users/alexscarrow/Desktop/DVX/DVX-html5` (only valid repo for this work)  
**Branch:** `feature/lobby-discovery` (based on `feature/lobby-supermarket-ticket-system`)  
**Transport:** `transport_mode = steam` in `game.project`  
**Last banked commit:** `1701984` — *Ignore local MP session save and hide lobby host debug hitboxes.*  
**Working tree:** clean; branch up to date with `origin/feature/lobby-discovery`.  
**Status:** **Banked** — remote 2P Host/Find loop passes repeated testing (see below). **Next work:** 3/4P transport/seat rewiring (Phases 1–5 below), then Update settings spec.

Also read:
- `AGENTS.md` — global safety rules (small diffs, host-authoritative MP, no desync risk)
- `Docs/MP_LOBBY_TICKET_HANDOVER.md` — supermarket ticket architecture, Option A wire dispatch, prior stable checkpoint history

---

## What we are trying to achieve

### Product goal

Enable **Steam public browse discovery** for multiplayer so two remote friends can play without Mac relay or manual Steam invite gymnastics:

1. **Host path:** HOST → Steam lobby → Publish Open → setup → launch when guest ready.
2. **Find path:** FIND → browse → tap session → Steam lobby join + wire → setup → host launches.

**Success criteria for 2P remote test (currently met):**
- Both reach setup and launch into the same match.
- Each player controls their assigned units (2 each in 2P).
- Control persists after host presses NEW TURN.
- Repeatable across role swaps (A host / B find, then B host / A find).
- Join/browse advisories visible to non-dev users; host uses `dvx_mp_debug.txt` when diagnosing.

### Architecture (three roles — intentionally split)

| Role | Responsibility |
|------|----------------|
| **Steam lobby (Gate B/C)** | Pairing, P2P wire, browse metadata (`dvx_offer`) |
| **Supermarket ticket** | Session authority — publish, join, launch, cancel (`main/multiplayer_session_ticket.lua`) |
| **Wire dispatch host (Option A)** | Gameplay command authority — `host_wire_player_id` / `host_player_id` |

---

## Current status — PASSED (2026-06-16)

### User test: 4 cycles per direction, no issues

**Ritual run:** A hosts / B joins → launch → play (incl. NEW TURN) → abort → swap roles. **×2 cycles each direction.**

| Scenario | Result |
|----------|--------|
| A hosts, B joins | **Pass** — join, launch, unit control, NEW TURN, abort |
| B hosts, A joins | **Pass** — same |
| Repeated cycles (×2 each) | **Pass** — no regressions |
| Join advisory UI | **Visible** (user confirmed) |

### Debug log confirmation (2026-06-16 afternoon)

**Files** (user-attached; not in repo):
- `dvx_mp_debug_a.txt` — `007FC59C-4730-4906-BC86-BE3B794BC7A4/`
- `dvx_mp_debug_b.txt` — `48A238F2-6FA1-4F1D-9919-4DB7731AB08F/`

**Healthy signals observed:**
- `event_sent type=lobby_join_accepted` and `event_sent type=match_started` on host (per-event wire send working)
- `match_started_guest local=p2 slot=p2 units=2` on guest every cycle
- `new_turn_request` → `turn_advanced` without guest losing control
- `move_unit_applied` for guest moves when guest is wire peer
- Clean abort: `leave_match_request` → `match_aborted_to_lobby` → `lobby_leave` / transport shutdown
- Role swap: `pairing_intent=host` / `find` alternation between cycles

**Known log noise (not failures):**
- Guest may still log `discovery_refresh_requested` during/after join — cosmetic; do not use as sole failure indicator
- `wire_not_ready` queue on join still appears; mitigations deliver events successfully afterward

### Issues fixed in this banked commit

**Join / launch / wire:**
- Per-event `send_events` on Steam (`match_started` highest priority) — `main/multiplayer_transport.lua`
- Join notify resend on `gatec_ok`, wire queue flush, join-response queuing
- Guest `mp_state.seat_assignments` sync (`multiplayer_guest_sync_runtime_from_session_config`)
- Setup fallbacks, launch gates, `show_mp_lobby_advisory`, `flow_state` → `game_flow_state` fix
- Host/Find discovery UI + Steam browse integration (`steam_transport_gateb.lua`)

**NEW TURN / guest liveness (critical fix):**
- `multiplayer_mark_remote_player_alive` — host tracks guest `connected_players` + `last_seen`
- Mark alive on every inbound guest command, lobby join, and match launch
- Fixed ping handler referencing undefined `is_local_host` (was never marking guests connected on Steam path)
- Guest ignores erroneous `turn_boundary_reclaim` seat payloads as safety net

---

## Active work — 3/4P rewiring (for new chat)

**Goal:** Two remote guests can join a 3P host, get distinct seats (`p2`/`p3`), sync setup, and launch. 4P is the same wiring with `N=4`. **Bank after each phase** when its smoke test passes. Keep **2P regression** in mind every slice.

**Why before Update settings:** Setup UI already supports 3/4P toggles and seat layouts, but Steam transport and seat identity are still **2P-shaped**. The agreed **Update settings** spec (pending vs committed player count, republish on Update) depends on this wiring — do not implement Update settings until Phases 1–4 (ideally 5) are green.

### Known 2P-shaped blockers

| # | Area | Problem |
|---|------|---------|
| 1 | Gate B (`steam_transport_gateb.lua`) | `resolve_peer_from_lobby` returns first non-self member — Guest 3 may handshake with Guest 2, not host |
| 2 | Seat assign (`game.script` ~17096) | `multiplayer_apply_steam_transport_seat_ids` sets all guests to `p2` |
| 3 | Gate C (`multiplayer_transport.lua`) | `steam_send_wire` / `steam_send_events_individually` send to single `peer_steam_id` only |
| 4 | Join accept (`game.script` ~25157) | `desired_player_count = min(mx, #joined)` forces 2P on first guest join |
| 5 | Launch gate (`game.script` ~17359) | Does not require `guest_count == committed_N - 1` |
| 6 | Roster | No stable host-authoritative Steam ID ↔ wire seat map (`p2`/`p3`/`p4`) |
| 7 | Command path | Wire `peer_id` not plumbed into join handler; host can't assign seats from Steam identity |

### What already works (do not rebuild)

- Setup UI: 2/3/4 toggles, seat layouts, `MP_SETUP_PLAYER_IDS`
- Events carry `target_player_id`; guests filter `setup_state_updated` by local seat
- `multiplayer_lobby_should_apply_join_accepted` can adopt host-assigned seat from `lobby_join_accepted`
- Steam **inbound:** host can receive wire from multiple peers (`accept_peers` + `poll_messages`)

---

### Phase 0 — Baseline guard (optional, small)

**Purpose:** Make 3P failures obvious in logs before changing behavior.

| Slice | Work | Files |
|-------|------|-------|
| 0.1 | Log duplicate wire id on join, single-peer send, launch when `guest_count < N-1` | `game.script` (debug only) |

**Test:** 2P unchanged. **Skip if** prefer zero pre-work.

**Status:** Not started.

---

### Phase 1 — Guest always peers with host (Gate B fix) ← **START HERE**

**Problem:** Guests resolve wrong peer in 3+ member lobbies.

| Slice | Work | Files |
|-------|------|-------|
| 1.1 | Guests: resolve peer = **lobby owner** (`matchmaking_get_lobby_owner`), not first other member | `steam_transport_gateb.lua` |
| 1.2 | Host: keep current first-guest peer for 2P ping/pong (unchanged for now) | same |

**Smoke test:** 3 Steam clients in one lobby; Guest 2 and Guest 3 both reach `gateb_ok` with host (not with each other).

**2P regression:** Host + 1 guest still passes Gate B.

**Status:** Not started.

---

### Phase 2 — Host multi-peer wire send (Gate C)

**Problem:** All outbound events/commands go to one `peer_steam_id`.

| Slice | Work | Files |
|-------|------|-------|
| 2.1 | Expose all non-host lobby member Steam IDs; track `accepted_peers` per member | `steam_transport_gateb.lua` |
| 2.2 | `send_wire(peer_id, raw)` — send to a specific peer | `steam_transport_gateb.lua` |
| 2.3 | Transport: `steam_send_wire_to_peer` + per-peer queue if needed | `multiplayer_transport.lua` |
| 2.4 | Route outbound events by `target_player_id` → peer via host map; fallback broadcast to all guests | `multiplayer_transport.lua` |
| 2.5 | Same routing for command responses (`steam_send_response_events`) | `multiplayer_transport.lua` |

**Smoke test:** Host sends two targeted events; each guest receives only its own.

**Note:** Host Gate B `wire_ready` can stay 2P-shaped (≥1 guest passed) until Phase 4.

**Status:** Not started. **Depends on:** Phase 1.

---

### Phase 3 — Steam ID ↔ wire seat map (host roster)

**Problem:** Every guest is `p2`; join identity collides.

| Slice | Work | Files |
|-------|------|-------|
| 3.1 | Session fields: `steam_id_by_wire_id` / `wire_id_by_steam_id` | `game.script`, possibly `multiplayer_session_ticket.lua` |
| 3.2 | Plumb wire `peer_id` into join command handling (transport → handler or `guest_steam_id` in payload) | `multiplayer_transport.lua`, `game.script` |
| 3.3 | On `lobby_join_session` (host): assign lowest free slot `p2`…`p(N-1)`; re-join same Steam ID → same seat | `game.script` (~25108+) |
| 3.4 | Use assigned wire id for `joined_player_ids`, `target_player_id`, `multiplayer_mark_remote_player_alive` | `game.script` |
| 3.5 | Stop blanket `p2` in `multiplayer_apply_steam_transport_seat_ids`; guests adopt seat via existing join-accept path | `game.script` (~17096, ~17164) |
| 3.6 | Wire map drives Phase 2 routing | `game.script` + transport |

**Smoke test:** 3P — Guest A = `p2`, Guest B = `p3`; both get `lobby_join_accepted` + `setup_state_updated`.

**Status:** Not started. **Depends on:** Phase 2.

---

### Phase 4 — Lobby rules (committed count + launch gate)

**Problem:** Join accept forces 2P; launch doesn't require `N-1` guests.

| Slice | Work | Files |
|-------|------|-------|
| 4.1 | Join accept: `player_count` = host **committed** setup count, not `min(mx, #joined)` | `game.script` (~25157) |
| 4.2 | Launch gate: require `guest_count == committed_player_count - 1` and all synced | `game.script` (`multiplayer_lobby_joined_guests_setup_synced`) |
| 4.3 | Join reject when `#guests >= committed_max - 1` | `game.script` (~25072) |
| 4.4 | (Optional) Host Gate B wire ready when all rostered guests have passed | `steam_transport_gateb.lua` |

**Smoke test — 3P milestone:**
1. Host selects 3P, publishes
2. Two guests join via Find
3. Launch **blocked** with 1 guest; **allowed** with 2
4. Match starts with `p1` / `p2` / `p3` distinct

**4P:** Same with three guests → `p4`.

**Status:** Not started. **Depends on:** Phase 3.

---

### Phase 5 — In-match sanity (minimal)

| Slice | Work | Files |
|-------|------|-------|
| 5.1 | Audit `multiplayer_steam_should_host_dispatch_local` + broadcast for match commands | `game.script`, `multiplayer_transport.lua` |
| 5.2 | Ensure host fan-out reaches all connected wire ids | transport + game |
| 5.3 | `connected_players` / alive tracking includes p3/p4 | `game.script` |

**Smoke test:** 3P — NEW TURN, one action per player, no silent guest.

**Status:** Not started. **Depends on:** Phase 4.

---

### Phase 6 — Docs + cleanup (after 3P green)

- Update this file with phase completion status
- Remove Phase 0 debug logs if noisy
- Note follow-up: **Update settings** spec (below)

---

### Dependency order

```
Phase 1 (guest→host peer) → Phase 2 (multi-peer send) → Phase 3 (seat map)
  → Phase 4 (lobby rules) → Phase 5 (in-match) → Phase 6 (docs)
  → Update settings spec
```

### Suggested bank points

| After | Commit theme |
|-------|----------------|
| Phase 1 | Fix Steam guest Gate B to peer with host only |
| Phase 2 | Per-peer Steam wire send and targeted event routing |
| Phase 3 | Host-authoritative steam↔wire seat assignment for 3/4P |
| Phase 4 | 3/4P launch gate and committed player count on join |
| Phase 5 | Multi-guest in-match wire fan-out (if needed) |

### Out of scope for 3/4P rewiring

- Update settings button / pending vs committed UI (see spec below — **after** rewiring)
- Abort → Host/Find chooser polish
- Kicking players on downgrade
- Non-Steam transport paths (verify loopback/WS separately if needed)

---

## Deferred — Update settings spec (after 3/4P rewiring)

**Problem:** Host toggling 2/3/4 while Steam `dvx_offer` lags causes browse/setup desync. Lock-on-first-join is too rigid.

**Design (agreed, not implemented):**
- Toggle 2/3/4 → **pending** only (dirty flag)
- **Update settings** button (replaces Launch while dirty) → commits + republishes Steam offer + wire push
- Only player count needs Update; mission/seats already sync via `setup_state_updated`
- **Launch:** blocked while dirty; requires committed count and `guest_count == committed_N - 1`
- **Downgrade:** block if `guest_count > new_count - 1` with advisory; no kicking
- **Join during dirty window:** accept uses **committed** capacity (browse shows old `mx` until Update)
- **After Update:** rostered guests keep seats; guests get advisory + `setup_state_updated`
- Private/PIN: same Update flow

**Key code areas:** `multiplayer_setup_set_player_count`, `multiplayer_setup_push_state`, `multiplayer_lobby_emit_offer_upsert`, `encode_discovery_offer` (`mx`), launch button UI (~20576), join accept (~25157).

---

## Deferred polish (after 3/4P or when user asks)

### Abort flow UX

**Problem:** Abort returns to MP lobby browse; user must back out to chooser to Host/Find again.

**Proposed fix:** Return to `FLOW_STATE_MP_CHOOSER` on `match_aborted_to_lobby`.

**Key code:** `multiplayer_leave_in_progress_match_to_lobby` (~16997), exit button (~29026), `match_aborted_to_lobby` (~27110).

### Other optional polish

- Pause guest `discovery_refresh` after pending join / in setup / in match
- Move `MP RECLAIM |` debug into `multiplayer_debug_log`
- Friend / non-dev test (HOST or FIND only)
- Bank / ship / merge decision

### Explicitly out of scope unless user asks

- Gate E/G gameplay sync rework
- Solo progression (`feature/solo-progression-revamp`)

---

## Key files & functions

| Area | Path / symbols |
|------|----------------|
| Gate B peer resolve | `resolve_peer_from_lobby` in `main/steam_transport_gateb.lua` (~216) |
| Gate B wire send | `gateb.send_wire`, `is_wire_ready` in `steam_transport_gateb.lua` (~938) |
| Gate C wire send | `steam_send_events_individually`, `steam_send_wire` in `main/multiplayer_transport.lua` |
| Steam seat assign (2P bug) | `multiplayer_apply_steam_transport_seat_ids` ~17096 |
| Join accept seat adoption | `multiplayer_lobby_should_apply_join_accepted` ~17164 |
| Launch gate | `multiplayer_lobby_joined_guests_setup_synced` ~17359 |
| Lobby join handler | `lobby_join_session` ~25070+ |
| Join accept player_count bug | ~25157 in `main/game.script` |
| Discovery offer encode | `encode_discovery_offer` in `steam_transport_gateb.lua` (`mx`) |
| Guest liveness | `multiplayer_mark_remote_player_alive` ~17125 |
| Abort → lobby (deferred UX) | `multiplayer_leave_in_progress_match_to_lobby` ~16997 |
| Host/Find chooser | `FLOW_STATE_MP_CHOOSER`, `multiplayer_lobby_enter_with_pairing_intent` |
| Session ticket | `main/multiplayer_session_ticket.lua` |
| Join advisory | `show_mp_lobby_advisory` |

---

## Tester ritual (regression)

1. **Host:** HOST → ~15s → Publish Open → setup
2. **Finder:** FIND → tap card once → wait for setup / advisory
3. **Host:** Launch after guest in setup
4. **Play:** Move units, host presses NEW TURN, guest still controls units
5. **Abort** → (today: lobby; desired: chooser)
6. Swap roles, repeat ×2 each direction

---

## Constraints for the next AI

1. Small, reversible diffs; host-authoritative MP; no desync risk.
2. Do not commit unless user explicitly requests.
3. Lua chunk local limit in `main/game.script` — prefer module-level helpers.
4. Do not rework Gate E/G without discussion.

---

## Related branches / checkpoints

| Item | Notes |
|------|-------|
| `1701984` | **Current HEAD** — gitignore local MP session save; hide lobby host debug hitboxes |
| `97839cf` | Fix lobby host publish button sprite rendering |
| `f09379f` | Require roster membership before pending Steam join completion |
| `1ce36ae` | Lobby host publish button art |
| `92bfad5` | Option A wire dispatch host (interchangeable 2P local) |
| `feature/lobby-discovery` | **Current branch** — 2P remote loop banked; 3/4P rewiring next |
| `Docs/MP_LOBBY_TICKET_HANDOVER.md` | Architecture history |

---

## Current stage (one paragraph)

**Steam Host/Find remote 2P is working** and banked at `1701984` (clean tree, synced with `origin/feature/lobby-discovery`). **Next work is 3/4P rewiring** before the agreed Update settings spec: Phase 1 (guest Gate B peers with host only) is the first implementation slice. Setup UI already supports 3/4P but transport/seat identity is 2P-shaped — see blockers and phase plan above. Abort→chooser UX and other polish are deferred until after 3/4P wiring (or when user asks).
