# DVX Multiplayer Discovery — Current State & AI Handover

**Last updated:** 2026-06-17  
**Working path:** `/Users/alexscarrow/Desktop/DVX/DVX-html5`  
**Branch:** `feature/lobby-discovery`  
**Transport:** `transport_mode = steam` in `game.project`  
**Last banked commit:** Phase 6 — handover doc refresh; `MP RECLAIM` → debug log.  
**Status:** **2P remote Host/Find green.** **3/4P rewiring Phases 1–6 banked** (3P join → launch → in-match smoke passed). **4P not smoke-tested** (same N=2–4 code paths). **Next:** Update settings spec.

Also read:
- `AGENTS.md` — global safety rules (small diffs, host-authoritative MP, no desync risk)
- `Docs/MP_LOBBY_TICKET_HANDOVER.md` — supermarket ticket architecture, Option A wire dispatch

---

## What we are trying to achieve

### Product goal

Enable **Steam public browse discovery** for multiplayer so remote friends can play without Mac relay or manual Steam invite gymnastics:

1. **Host path:** HOST → Steam lobby → Publish Open → setup → launch when guests ready.
2. **Find path:** FIND → browse → tap session → Steam lobby join + wire → setup → host launches.

**Success criteria (met for 2P; 3P join/launch/in-match met):**
- All players reach setup and launch into the same match.
- Each player controls their assigned units.
- Control persists after host presses NEW TURN.
- Repeatable across role swaps.

### Architecture (three roles — intentionally split)

| Role | Responsibility |
|------|----------------|
| **Steam lobby (Gate B/C)** | Pairing, P2P wire, browse metadata (`dvx_offer`) |
| **Supermarket ticket** | Session authority — publish, join, launch, cancel (`main/multiplayer_session_ticket.lua`) |
| **Wire dispatch host (Option A)** | Gameplay command authority — `host_wire_player_id` / `host_player_id` |

---

## 3/4P rewiring — COMPLETE (Phases 1–6)

**Goal:** Remote guests join a 3P/4P host, get distinct wire seats (`p2`/`p3`/`p4`), sync setup, launch, and play in-match. **Banked per phase.**

| Phase | Commit | What shipped | Smoke |
|-------|--------|--------------|-------|
| **1** Gate B guest→host peer | `32b9f62` | Guests peer with lobby owner; host pings each guest | 3P Gate B |
| **2** Per-peer wire send | `588c04f` | `send_wire_to_peer`, targeted events, host broadcast | 3P wire routing |
| **3** Steam↔wire seat map | `fb08b29` | `steam_id_by_wire_id`, distinct `p2`/`p3`/`p4` on join | 3P seats |
| **4** Lobby rules | `17c9a03` | Committed player count, launch gate, roster setup fan-out + ack | 3P join/launch |
| **5** In-match sanity | `232bd26` | Match `connected_players` seed, multi-guest event fan-out | 3P NEW TURN + moves |
| **6** Docs + cleanup | `fb4748a` | Handover doc refresh; `MP RECLAIM` → debug log | Post-rewiring sanity |

**4P:** Code paths are `N=2..4` throughout; **not smoke-tested yet** — treat as high-confidence untested.

**Phase 0** (optional baseline debug) — **skipped**; `launch_blocked` / `multiplayer_debug_log` cover diagnostics.

### Resolved blockers (were 2P-shaped)

| Area | Fix (phase) |
|------|-------------|
| Gate B wrong peer in 3+ lobbies | Guests resolve lobby owner (1) |
| Single `peer_steam_id` send | Per-peer send + host fan-out (2, 4, 5) |
| All guests assigned `p2` | Host roster `steam_id_by_wire_id` (3) |
| Join shrinks to 2P on first guest | Committed `player_count` on join (4) |
| Launch without full roster | `guest_count == N-1` + setup sync (4) |
| Guest stuck on setup at launch | `match_started` fan-out to all guests (4) |
| Guest silent in-match | Roster peer map + `connected_players` seed (5) |

### What already works (do not rebuild)

- Setup UI: 2/3/4 toggles, seat layouts, `MP_SETUP_PLAYER_IDS`
- Events carry `target_player_id`; guests filter by local seat
- Host-authoritative join, setup sync, launch, and in-match command broadcast
- Steam inbound: host receives wire from multiple peers

---

## Next work ← **START HERE**

### Update settings spec (agreed design, not implemented)

**Problem:** Host toggling 2/3/4 while Steam `dvx_offer` lags causes browse/setup desync. Lock-on-first-join is too rigid.

**Design:**
- Toggle 2/3/4 → **pending** only (dirty flag)
- **Update settings** button (replaces Launch while dirty) → commits + republishes Steam offer + wire push
- Only player count needs Update; mission/seats already sync via `setup_state_updated`
- **Launch:** blocked while dirty; requires committed count and `guest_count == committed_N - 1`
- **Downgrade:** block if `guest_count > new_count - 1` with advisory; no kicking
- **Join during dirty window:** accept uses **committed** capacity (browse shows old `mx` until Update)
- **After Update:** rostered guests keep seats; guests get advisory + `setup_state_updated`
- Private/PIN: same Update flow

**Key code areas:** `multiplayer_setup_set_player_count`, `multiplayer_setup_push_state`, `multiplayer_lobby_emit_offer_upsert`, `encode_discovery_offer` (`mx`), launch button UI (~20576), join accept (~25290).

---

## Deferred polish (when user asks)

| Item | Notes |
|------|-------|
| **4P smoke test** | Three guests; same ritual as 3P |
| **Steam persona names** | Replace `playerone`/`playertwo` placeholders in lobby/setup (`Docs/steam-multiplayer-model-a-checklist.md`) |
| **Abort → chooser UX** | Return to `FLOW_STATE_MP_CHOOSER` on `match_aborted_to_lobby` |
| Pause guest `discovery_refresh` in join/setup/match | Reduce log noise |
| 2P regression spot-check | After any MP change |
| Kicking players on downgrade | Out of scope |
| Non-Steam transport | Verify loopback/WS separately if needed |

**Out of scope unless user asks:** Gate E/G gameplay sync rework; solo progression branch.

---

## Key files & functions

| Area | Path / symbols |
|------|----------------|
| Gate B peer resolve | `resolve_peer_from_lobby`, `enumerate_lobby_guest_ids` — `steam_transport_gateb.lua` |
| Gate B per-guest ping | `try_send_guest_pings` — `steam_transport_gateb.lua` |
| Gate C multi-peer send | `steam_send_events_individually`, `steam_resolve_event_peer_ids` — `multiplayer_transport.lua` |
| Steam seat assign | `multiplayer_steam_assign_wire_id_for_guest`, `steam_sync_peer_map` — `game.script` |
| Join / launch gate | `lobby_join_session`, `multiplayer_lobby_joined_guests_setup_synced` — `game.script` |
| Roster setup fan-out | `multiplayer_lobby_append_roster_setup_sync_events` — `game.script` |
| Match start | `multiplayer_host_start_match_from_setup`, `multiplayer_seed_match_connected_players` — `game.script` |
| Guest liveness | `multiplayer_mark_remote_player_alive`, `multiplayer_is_match_player_connected` — `game.script` |
| Discovery offer | `encode_discovery_offer` (`mx`) — `steam_transport_gateb.lua` |
| Session ticket | `main/multiplayer_session_ticket.lua` |
| Debug log file | `multiplayer_debug_log` → `dvx_mp_debug.txt` |

---

## Tester ritual (regression)

### 2P (baseline)
1. **Host:** HOST → Publish Open → setup  
2. **Finder:** FIND → tap card → setup  
3. **Host:** Launch  
4. **Play:** Move units, NEW TURN, guest retains control  
5. **Abort** → swap roles, repeat ×2 each direction  

### 3P (rewiring milestone — passed)
1. Host selects **3P**, publishes  
2. Two guests join via Find  
3. Launch blocked with 1 guest; allowed with 2  
4. All three enter match; each moves; host NEW TURN  
5. Abort optional  

### 4P (not yet run)
Same as 3P with three guests → expect `p1`–`p4` distinct.

---

## 2P remote — historical pass (2026-06-16)

User test: 4 cycles per direction, no issues. Healthy log signals: `lobby_join_accepted`, `match_started` to guest, `match_started_guest`, `new_turn_request` → `turn_advanced`, `move_unit_applied`, clean abort.

**Known log noise (not failures):** guest `discovery_refresh_requested` during join; `wire_not_ready` queue then flush succeeds.

---

## Constraints for the next AI

1. Small, reversible diffs; host-authoritative MP; no desync risk.
2. Do not commit unless user explicitly requests.
3. Lua chunk local limit in `main/game.script` — prefer module-level helpers.
4. Do not rework Gate E/G without discussion.

---

## Related checkpoints

| Commit | Notes |
|--------|-------|
| `fb4748a` | **HEAD** — Phase 6 docs + reclaim log cleanup |
| `232bd26` | Phase 5 in-match connected players + fan-out |
| `17c9a03` | Phase 4 committed count, launch gate, roster sync |
| `fb08b29` | Phase 3 steam↔wire seats |
| `588c04f` | Phase 2 per-peer wire send |
| `32b9f62` | Phase 1 Gate B multi-guest |
| `1701984` | 2P remote loop banked; local MP save gitignore |
| `feature/lobby-discovery` | Current branch — 7 commits ahead of origin at last bank |

---

## Current stage (one paragraph)

**Steam Host/Find remote 2P and 3P rewiring are done** (Phases 1–6). 3P join, launch, and in-match smoke-tested. **4P not smoke-tested.** **Next: Update settings** spec. Deferred: Steam persona names, abort→chooser UX, 4P smoke.
