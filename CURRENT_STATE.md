# DVX Multiplayer Discovery — Current State & AI Handover

**Last updated:** 2026-06-18  
**Working path:** `/Users/alexscarrow/Desktop/DVX/DVX-html5`  
**Branch:** `feature/lobby-discovery`  
**Transport:** `transport_mode = steam` in `game.project`  
**Last banked commit:** `b1bf889` — launch-time N, min-1-guest gate, 2P leave/rejoin lifecycle  
**Status:** **2P rituals pass** (join, setup Back→FIND, rejoin). **3P join works; P3 leave/rejoin broken** (next L2 tranche). **4P not smoke-tested.**

Also read:
- `AGENTS.md` — global safety rules (small diffs, host-authoritative MP, no desync risk)
- `Docs/MP_LOBBY_LIFECYCLE_SPEC.md` — lobby lifecycle redesign (L1–L5)
- `Docs/MP_LOBBY_TICKET_HANDOVER.md` — supermarket ticket architecture, Option A wire dispatch

---

## START HERE ← next AI priority

1. **P3 leave/rejoin** — enter, exit, cannot re-enter host session; extend L2 hardening (see Issue D)  
2. **Lobby card player count UI** — sprite digits, not fonts — see Issue A  
3. **Dual-host browse visibility** — investigate with logs — see Issue C  
4. Retest matrix at bottom

---

## Open bugs (2026-06-18 smoke)

### Issue A — No player count on lobby session cards

**Symptom:** Finder lobby cards show host name + status strip only; no `N/M` occupancy.

**Root cause:** Feature never wired. `multiplayer_lobby_render_session_cards` (~19650 in `main/game.script`) renders host label via **`letter_*` sprite glyphs** (same atlas pattern as setup/score names). There is **no digit rendering** and **no Defold font** on cards — so this is not a font-vs-atlas bug.

**Proposed fix:**
- Add a small digit sprite pool to lobby UI init (reuse `score_0`…`score_9` pattern from score HUD / `loot_marker_factory`).
- In `multiplayer_lobby_render_session_cards`, render `players/max_players` (e.g. `2/3`) below or beside host name from `session.players` and `session.max_players`.
- Do **not** use Defold fonts (known rendering problems elsewhere).

**Touchpoints:** `multiplayer_lobby_render_session_cards`, lobby UI init (~12564), existing score digit helpers.

---

### Issue D — P3 leave/rejoin (open, 2026-06-18)

**Symptom:** P3 can join a 3P lobby and reach setup, but after setup Back → FIND cannot re-enter P1’s session.

**Status:** **P2 same ritual passes** after launch-time N + L2 join hardening in this bank. P3 not yet fixed — likely multi-guest seat map, per-peer wire routing, or stale offer path specific to p3.

**Next:** Reproduce with P3 debug log; grep `guest_setup_evicted`, `join_session_wire`, `pending_join_incomplete`, `seat_assign local=p3`. Extend L2 per `Docs/MP_LOBBY_LIFECYCLE_SPEC.md`.

---

### Issue B — Post-abort re-join stuck on “joining” advisory (P2/P3) — P2 fixed in this bank

**Symptom:** After setup back/abort, P2 and P3 return to FIND, tap session again, see **joining** advisory indefinitely. Never reach setup.

**Log evidence (2026-06-18 11:11, three-machine test):**

| Client | Key lines |
|--------|-----------|
| **P1 host** | `leave_session_reject` ×2 (`player_not_in_session`) for P2 and P3; guests still heartbeating after abort |
| **P2 finder** | First join OK (`join_session_wire`, `gateb_ok`, `gatec_ok`). Abort: `lobby_leave` 11:11:55. Re-join 11:11:59: Steam `lobby_enter` OK but **no `gateb_ok`**, **no `join_session_wire`**; `pending_join_incomplete … players=2 joined=0` for ~2+ min |
| **P3 finder** | Same re-join pattern as P2 |

**Failure chain (most likely):**

1. **Host roster wiped by Steam discovery merge (regression from uncommitted fix)**  
   `multiplayer_lobby_merge_incoming_offer_fields` returns `{}` for `joined_player_ids` on every `steam_discovery` upsert (~18897). Host applies own browse readback via `on_discovery_offer` → `discovery_apply` (~29646), which **clears wire roster** while Steam `players` count may still show guests in lobby.

2. **Leave path fails**  
   Guests send `lobby_leave_session` on setup back; host rejects with `player_not_in_session` because roster already empty. Steam lobby membership and wire roster diverge.

3. **Re-join handshake never completes**  
   Guest re-enters Steam lobby (`lobby_enter`, `peer_resolved`) but **Gate B ping/pong never finishes** → no `gateb_ok` → `multiplayer_lobby_complete_pending_steam_join` never sends `lobby_join_session` wire. User stuck on joining advisory (shown at join start ~18326; no stuck-state timeout).

4. **`pending_join_incomplete` is misleading here**  
   `multiplayer_lobby_try_complete_pending_join_from_offer` (~17769) blocks fast-path to setup when guest not yet in roster — expected during normal join. On re-join the real blocker is **missing wire join**, not this check alone.

**Proposed fixes (in order):**

| # | Change | Rationale |
|---|--------|-----------|
| B1 | **Discovery merge:** On `steam_discovery`, update `players`/`max_players` only; **preserve** existing `joined_player_ids`, `steam_id_by_wire_id`, `wire_id_by_steam_id` when incoming discovery has empty roster | Stops host self-wipe |
| B2 | **Skip or guard host `discovery_apply`** for own `local_active_offer_id` (wire roster is authoritative on host) | Belt-and-suspenders |
| B3 | **Leave path:** Ensure roster prune succeeds; on reject, host runs `multiplayer_lobby_prune_steam_disconnected_guests` / `lobby_alone_prune` from Steam guest enumeration | Recover when wire leave fails |
| B4 | **Guest teardown:** Don’t fully shutdown transport until `lobby_leave_session` ack or explicit fallback | Avoid desynced Steam-in / wire-out |
| B5 | **Re-join:** If in Steam lobby + wire ready but not in roster, allow/resend `lobby_join_session` (re-admit path); reset pending join state on abort return to FIND | Unstick re-join |
| B6 | **UX:** Joining advisory timeout → clear pending + show join-failed advisory | User feedback |

**Earlier related fix (still needed, refine per B1):** Stale `players` on finders — `math.max` merge prevented occupancy decreasing after guests left → `join_blocked_preflight session_full`. Uncommitted merge change fixed finder stale count but introduced host roster wipe.

**Log grep hints:**
- Host success: `leave_session_roster_prune`
- Host failure: `leave_session_reject`
- Finder stuck: `pending_join_incomplete`, absence of `join_session_wire` after re-tap
- Merge regression: `discovery_apply` on host after guests joined, then roster-empty join accepts

---

### Issue C — Dual host: P3 only saw one session

**Symptom:** P1 and P2 both launched/hosted; P3 browse showed **1 card** only. No debug logs for this run.

**What we know from instrumented runs:** Steam browse consistently logs `discovery_list count=1` when only P1 is hosting. Dual-host case not yet logged.

**Hypotheses (check in order):**

| Hypothesis | Check |
|------------|-------|
| P2 never published Open (`discovery_publish`) | Grep P2 log for `discovery_publish` / `published_open` |
| P2 still in draft / wrong `lobby_status` | Host flow before Open Game |
| Same Steam account on two “hosts” | Compare `local_steam_id` on both |
| Steam browse filter | `filter_slots_available(1)` in `steam_transport_gateb.lua` — both should pass if slots free |
| Dedup in `multiplayer_lobby_apply_offer_upsert` | `same_host_steam` replaces prior offer — **one card per Steam host** (correct); different Steam IDs → two cards |
| Timing | P3 browsed before P2 publish completed |
| `multiplayer_lobby_session_is_browse_visible` | Filters non-published sessions |

**Proposed investigation:** Re-run with debug on all three; on P3 grep `discovery_list count`, `discovery_offer`; on each host grep `discovery_publish` and distinct `host_steam_id` / session id (`76561198…:N`).

---

## What works (do not rebuild)

- Steam Host/Find 2P remote (historical pass)
- 3P join ritual → launch → in-match → NEW TURN (prior cycle)
- Update settings (pending/committed split) — **implemented** in `f8a0958`; P1 log shows `update_settings_committed count=3`
- Phases 1–6 rewiring (Gate B multi-guest, per-peer wire, steam↔wire seats, launch gate, in-match fan-out)

---

## Update settings — IMPLEMENTED (`f8a0958`)

Previously spec-only; now banked. Core behavior:

| State | Meaning |
|-------|---------|
| **Pending** | Host 2/3/4 toggle in setup UI |
| **Committed** | Host **Update settings** → session + Steam + wire |

- Dirty → **UPDATE SETTINGS** replaces Launch; launch blocked while dirty
- `multiplayer_lobby_committed_player_count` reads stored committed count
- Auto-commit on first publish

**Remaining gap (ties to Issue A):** Browse cards still don’t **display** player count visually even though `mx` / `players` may be correct in data.

---

## Banked in this milestone (launch-time N + 2P lifecycle)

- **Launch-time N:** roster-baked at Launch; removed 2/3/4 buttons and Update settings traffic  
- **Min-1-guest launch gate** on host setup  
- **Guest setup Back → FIND** (`multiplayer_lobby_guest_leave_setup_to_find`) — transport stays alive  
- **Wire roster join truth:** stale snapshot eviction removed; offer merge guards; `steam_rejoin`, `forget_peer`, find-idle ping ignore  
- **L1 lifecycle logging:** `main/multiplayer_lobby_lifecycle.lua`  
- **Spec:** `Docs/MP_LOBBY_LIFECYCLE_SPEC.md`

---

## Architecture (three roles)

| Role | Responsibility |
|------|----------------|
| **Steam lobby (Gate B/C)** | Pairing, P2P wire, browse metadata (`dvx_offer`) |
| **Supermarket ticket** | Session authority — publish, join, launch, cancel (`main/multiplayer_session_ticket.lua`) |
| **Wire dispatch host (Option A)** | Gameplay command authority — `host_wire_player_id` / `host_player_id` |

---

## Key files & functions

| Area | Path / symbols |
|------|----------------|
| Session card render | `multiplayer_lobby_render_session_cards` — `game.script` ~19650 |
| Discovery merge | `multiplayer_lobby_merge_incoming_offer_fields`, `multiplayer_lobby_apply_offer_upsert` — ~18895 |
| Discovery apply callback | `on_discovery_offer` — ~29632 |
| Pending join / wire | `multiplayer_lobby_complete_pending_steam_join`, `multiplayer_lobby_try_complete_pending_join_from_offer` — ~17740, ~18231 |
| Leave session | `lobby_leave_session` handler — ~26094 |
| Update settings | `multiplayer_lobby_commit_player_count_settings`, dirty helpers — ~17287+ |
| Steam browse filters | `add_gate_lobby_list_filters` — `steam_transport_gateb.lua` ~319 |
| Discovery encode | `encode_discovery_offer` (`pl`, `mx`) — `steam_transport_gateb.lua` |
| Debug log | `multiplayer_debug_log` → `dvx_mp_debug.txt` |

---

## Retest matrix (after fixes)

| # | Scenario | Pass criteria |
|---|----------|---------------|
| 1 | 3P join ritual (baseline) | All reach setup; launch OK |
| 2 | P2/P3 setup back → host roster 1/N | Host: `leave_session_roster_prune` (not reject) |
| 3 | P2 re-join same session | `join_session_wire` + setup; no stuck joining |
| 4 | Finder after abort | No `join_blocked_preflight session_full` on valid slot |
| 5 | Lobby cards | Visible `N/M` player count on each card |
| 6 | P1 + P2 simultaneous host | P3 `discovery_list count=2`, two cards |
| 7 | Update settings regression | Dirty toggle → Update → launch with correct N |
| 8 | 2P spot-check | Unaffected |

---

## Tester ritual (regression)

### 2P (baseline)
1. Host: HOST → Publish Open → setup  
2. Finder: FIND → tap card → setup  
3. Host: Launch → play → NEW TURN → abort  

### 3P
1. Host 3P, publish  
2. Two guests join via Find (order may vary)  
3. Launch blocked with 1 guest; OK with 2  
4. All three in match; abort optional  

### Post-abort re-join
1. 3P in setup  
2. P2 and P3 back to FIND  
3. **P2 re-joins → setup** — passes (2026-06-18)  
4. **P3 re-joins → setup** — fails (Issue D)  

### 4P (not yet run)
Same as 3P with three guests.

---

## Constraints for the next AI

1. Small, reversible diffs; host-authoritative MP; no desync risk.  
2. Do not commit unless user explicitly requests.  
3. Lua chunk local limit in `main/game.script` — prefer module-level helpers.  
4. Lobby digits: sprite atlas only, not Defold fonts.  
5. Do not rework Gate E/G without discussion.

---

## Related checkpoints

| Commit | Notes |
|--------|-------|
| `b1bf889` *(HEAD)* | Launch-time N, min-1-guest gate, 2P leave/rejoin lifecycle, L1 logging |
| `6231a20` | Checkpoint before launch-time N reset |
| `f8a0958` | Update settings, cycle-2 sync, session-full reject UX |
| `232bd26` | Phase 5 in-match connected players + fan-out |
| `17c9a03` | Phase 4 committed count, launch gate, roster sync |
| `fb08b29` | Phase 3 steam↔wire seats |
| `588c04f` | Phase 2 per-peer wire send |
| `32b9f62` | Phase 1 Gate B multi-guest |

---

## Current stage (one paragraph)

**Launch-time N milestone banked:** wire roster is sole join truth; host bakes N at Launch; min-1-guest gate; 2P join → setup → Back → FIND → rejoin → setup **passes**. L1 lifecycle logging landed. **Open:** P3 leave/rejoin (Issue D), lobby card N/M digits (Issue A), dual-host browse (Issue C). Next L2 tranche targets 3P/4P guest re-entry per `Docs/MP_LOBBY_LIFECYCLE_SPEC.md`.
