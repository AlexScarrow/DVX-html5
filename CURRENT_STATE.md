# DVX Multiplayer Discovery — Current State & AI Handover

**Last updated:** 2026-06-16  
**Working path:** `/Users/alexscarrow/Desktop/DVX/DVX-html5` (only valid repo for this work)  
**Branch:** `feature/lobby-discovery` (based on `feature/lobby-supermarket-ticket-system`)  
**Transport:** `transport_mode = steam` in `game.project`  
**Status:** **Banked** — remote 2P Host/Find loop passes repeated testing (see below).

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

## Sensible next steps (for new chat)

### Priority 1 — Abort flow UX (user-requested)

**Problem:** Abort from in-match returns both players to **MP lobby browse** (`FLOW_STATE_MP_LOBBY`). To Host or Find again, user must back out to title → chooser. Extra friction when swapping roles between rounds.

**Proposed fix:** On match abort (exit button / `match_aborted_to_lobby`), return to **Host/Find chooser** (`FLOW_STATE_MP_CHOOSER`) instead of lobby — with transport shutdown and session/ticket cleanup. User leans toward chooser over title if chooser is where Host/Find lives.

**Key code:** `multiplayer_leave_in_progress_match_to_lobby` (~16997), exit button handler (~29026), `match_aborted_to_lobby` event handler (~27110).

**Scope:** Small, self-contained UX slice. Both players should land in same destination (host already broadcasts `match_aborted_to_lobby`).

### Priority 2 — Bank / ship decision

- Consider merge to main or tag milestone after abort UX (or ship without if user prefers).
- Optional: push `feature/lobby-discovery` to remote for backup.

### Priority 3 — Friend / non-dev test

- One non-technical tester: HOST or FIND only, no debug ritual.
- Success = advisory visible, join within ~15s, play a full turn, no confusion on abort.

### Priority 4 — Optional polish (defer unless needed)

- Pause guest `discovery_refresh` after pending join / in setup / in match
- Move `MP RECLAIM |` reclaim debug from `print()` into `multiplayer_debug_log` for future diagnosis
- Tighten launch gate further (guest truly in `FLOW_STATE_MP_SETUP` before LAUNCH)
- Defer join wire response until `gatec_ok` (store pending events on host)

### Explicitly out of scope unless user asks

- Gate E/G gameplay sync rework
- Solo progression (`feature/solo-progression-revamp`)
- 3–4 player scale

---

## Key files & functions

| Area | Path / symbols |
|------|----------------|
| Guest liveness | `multiplayer_mark_remote_player_alive` ~17042 |
| Abort → lobby (change target here) | `multiplayer_leave_in_progress_match_to_lobby` ~16997 |
| Exit button | ~29026 in `main/game.script` |
| Match abort event | `match_aborted_to_lobby` ~27110 |
| Host/Find chooser | `FLOW_STATE_MP_CHOOSER`, `multiplayer_lobby_enter_with_pairing_intent` |
| Turn boundary reclaim | `multiplayer_reconcile_departed_ownership_on_turn_boundary` ~16917 |
| Wire send | `steam_send_events_individually` in `main/multiplayer_transport.lua` |
| Lobby join | `lobby_join_session` ~24695 |
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
| `92bfad5` | Option A wire dispatch host (interchangeable 2P local) |
| `feature/lobby-discovery` | **Current** — Steam Host/Find remote loop banked |
| `Docs/MP_LOBBY_TICKET_HANDOVER.md` | Architecture history |

---

## Current stage (one paragraph)

**Steam Host/Find remote 2P is working:** discover → join → launch → multi-turn play → abort, repeatable with role swaps. Fixes spanned per-event wire delivery, guest seat sync, join completion fallbacks, and guest liveness on NEW TURN. **Next work is polish:** primarily **abort → Host/Find chooser** instead of lobby browse, then optional friend test and minor log/UX cleanup. No open sync blocker for the core 2P remote loop.
