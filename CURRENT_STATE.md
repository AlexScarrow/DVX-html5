# DVX Multiplayer Discovery — Current State & AI Handover

**Last updated:** 2026-06-17  
**Working path:** `/Users/alexscarrow/Desktop/DVX/DVX-html5`  
**Branch:** `feature/lobby-discovery`  
**Transport:** `transport_mode = steam` in `game.project`  
**Last banked commit:** Phase 6 — handover doc refresh; `MP RECLAIM` → debug log.  
**Status:** **2P remote Host/Find green.** **3/4P rewiring Phases 1–6 banked** (3P join → launch → in-match smoke passed). **4P not smoke-tested** (same N=2–4 code paths). **Next:** Implement **Update settings** (spec agreed, code not started).

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
| **6** Docs + cleanup | Phase 6 bank | Handover doc refresh; `MP RECLAIM` → debug log | Post-rewiring sanity |

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

### Update settings — agreed spec (NOT implemented)

**User intent:** Host must be able to change advertised player count mid-lobby without aborting — e.g. advertised 4P with only one guest should be able to commit 2P and launch. Idle 2/3/4 toggling must not desync Steam browse from setup. **Lock-on-first-join was rejected** as too rigid.

**Problem (three “truths” today):**

| Layer | Source today | When it updates |
|-------|----------------|-----------------|
| Steam browse (`dvx_offer.mx`) | `session.max_players` | Only on `steam_publish_session` via `multiplayer_lobby_emit_offer_upsert` |
| Host setup UI | `mp_setup.player_count` | Instant on 2/3/4 tap |
| Wire to guests | `setup_state_updated` | Instant via `multiplayer_setup_push_state` on toggle |

Tapping 2/3/4 today calls `multiplayer_setup_set_player_count` **and** `multiplayer_setup_push_state` (~20793) — guests see new count immediately; Steam offer does not update.

**Additional gap:** `session.max_players` is minted as **4** default (`multiplayer_session_ticket_mint_host_session` does not pass `max_players`). Browse cards often show 4 max regardless of host UI. Phase 4 added `multiplayer_lobby_committed_player_count` but it returns `min(session.max_players, mp_setup.player_count)` — with `max_players` stuck at 4, **committed ≈ UI toggle**, not a real committed/pending split.

---

#### Core design (locked)

Treat **player count only** as pending vs committed. Mission, seat drag, and unit picks keep live wire sync (not in Steam blob).

| State | Meaning |
|-------|---------|
| **Pending** | Host toggled 2/3/4 in setup UI (local) |
| **Committed** | Host clicked **Update settings** → session + Steam + wire |

**Only committed** drives: browse `mx`, join capacity (`session_full`), launch gate (`guest_count == committed_N - 1`).

**Host UX:**
- Not dirty → **LAUNCH** (same slot as today, ~20514)
- Dirty (pending ≠ committed) → **UPDATE SETTINGS** replaces launch; launch hidden/disabled
- Optional hint while dirty: *“Listing still shows N players until you update.”*

**Update click (atomic on host):**
1. Validate: `guest_count ≤ pending_N - 1` (else block + advisory)
2. Commit pending → `session.max_players` + stored committed field
3. `multiplayer_lobby_emit_offer_upsert` → `steam_publish_session` (refreshes `dvx_offer.mx`)
4. Push `setup_state_updated` to rostered guests (consider roster fan-out + `require_setup_ack` like Phase 4 join)
5. Guest advisory: *“Host set session to N players.”*
6. Clear dirty → restore launch if rules pass

**Launch rules:** blocked while dirty; requires committed N and `guest_count == N - 1` (via `multiplayer_lobby_joined_guests_setup_synced`).

---

#### Edge cases (locked)

| Case | Behavior |
|------|----------|
| Downgrade with too many guests | Block Update + advisory (*“Can’t reduce player count — players already joined.”*). **No kicking.** |
| Launch while dirty | Blocked |
| Guest joins during dirty window | Join uses **committed** capacity; browse still shows old `mx` |
| Host Updates after guests joined | Validate roster; if OK all rostered guests keep seats; advisory + `setup_state_updated` |
| Awkward but fair | Committed 4P, pending 2P (dirty), more guests join under 4P rules → Update to 2P blocked until leavers or commit 3P/4P |
| Mid-join race | Host-authoritative: join checks committed at accept time; Update validates roster before commit |
| Private/PIN | Same Update flow; republish refreshes Steam lobby metadata |

**Out of scope unless user asks:** pause joins while dirty; kicking on downgrade; browse card “2/3 players” display.

---

#### Implementation plan (suggested order)

1. **State split:** `mp_setup.committed_player_count` (or on session) + `mp_setup.player_count_dirty`; initialize both on publish (see open pin below)
2. **Count toggle:** set pending only; **remove** `multiplayer_setup_push_state` from count button handler (~20793)
3. **Fix** `multiplayer_lobby_committed_player_count` to return stored committed, not UI toggle
4. **New** `multiplayer_lobby_commit_player_count_settings(self)` — validation, commit, `emit_offer_upsert`, wire push, clear dirty
5. **Setup UI** (~20438): if dirty → Update button; else Launch; `can_launch` requires `not dirty`
6. **Match config:** `multiplayer_setup_build_session_config` / launch use committed count when launching
7. **Smoke tests** (see below)

Prefer **module-level helpers** in `game.script` (Lua local limit).

---

#### Open pins (confirm with user before or during implementation)

1. **Auto-commit on publish?** Recommended **yes** — first publish commits count selected before “Open Game” so browse matches setup from second zero; dirty only on later toggles.
2. **Update button art?** New sprite (`update_settings_button`) or reuse `launch_button` / `disabled_button` sprite for v1?
3. **Setup sync on Update:** plain `setup_push_state` vs roster fan-out with `require_setup_ack` (Phase 4 pattern — safer for layout changes).

---

#### Key code touchpoints

| Symbol / area | File | Notes |
|---------------|------|-------|
| Count toggle + immediate push | `game.script` ~20786–20796 | Remove push on toggle |
| `multiplayer_setup_set_player_count` | `game.script` ~16508 | Pending UI + seat reshape |
| `multiplayer_setup_push_state` | `game.script` ~16758 | Call on Update commit, not toggle |
| `multiplayer_lobby_committed_player_count` | `game.script` ~17169 | Must read real committed |
| Join accept capacity | `game.script` ~25294–25310 | Already uses committed helper |
| Launch UI | `game.script` ~20438–20517 | Swap Launch ↔ Update |
| `multiplayer_lobby_emit_offer_upsert` | `game.script` ~18407 | Republish on commit |
| `encode_discovery_offer` (`mx`) | `steam_transport_gateb.lua` ~79 | Reads `session.max_players` |
| Mint session (no max from UI) | `game.script` ~18323 | Set max on publish/commit |
| Roster setup fan-out | `multiplayer_lobby_append_roster_setup_sync_events` | Optional on Update |

---

#### Update settings smoke tests (after implementation)

1. Host 4P → publish → browse shows 4 → toggle 2P (dirty) → guests still see committed layout; finder still sees 4 max
2. Host 4P, 1 guest → toggle 2P → Update → launch OK
3. Host 4P, 2 guests → toggle 2P → Update **blocked** with advisory
4. Host 3P, 2 guests, launch OK (no dirty)
5. 2P regression spot-check
6. Private/PIN: same Update flow

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
| **Update settings (to build)** | `multiplayer_lobby_commit_player_count_settings`, dirty flag, Update UI — `game.script` |
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
| *(HEAD)* | Phase 6 docs + reclaim log cleanup |
| `232bd26` | Phase 5 in-match connected players + fan-out |
| `17c9a03` | Phase 4 committed count, launch gate, roster sync |
| `fb08b29` | Phase 3 steam↔wire seats |
| `588c04f` | Phase 2 per-peer wire send |
| `32b9f62` | Phase 1 Gate B multi-guest |
| `1701984` | 2P remote loop banked; local MP save gitignore |
| `feature/lobby-discovery` | Current branch — 7 commits ahead of origin at last bank |

---

## Current stage (one paragraph)

**Steam Host/Find remote 2P and 3P rewiring are done** (Phases 1–6 banked). 3P join, launch, and in-match smoke-tested. **4P not smoke-tested.** **Next: implement Update settings** — spec fully agreed in design discussion (pending/committed split, Update button replaces Launch while dirty, no kicking on downgrade). Code not started; see section above. Deferred: Steam persona names, abort→chooser UX, 4P smoke.
