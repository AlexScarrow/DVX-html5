# DVX Multiplayer Discovery — Current State & AI Handover

**Last updated:** 2026-06-18  
**Working path:** `/Users/alexscarrow/Desktop/DVX/DVX-html5`  
**Branch:** `feature/lobby-discovery` (pushed to origin)  
**Transport:** `transport_mode = steam` in `game.project`  
**Last banked commit:** `b1bf889` — launch-time N, min-1-guest gate, 2P leave/rejoin lifecycle  
**Lobby stage:** **Core rituals pass for 2P/3P join→launch→in-match.** Lobby is **not yet “good enough to set aside”** — three tidy-up tasks remain (below). After those, treat lobby as maintenance-only unless regressions appear.

Also read:
- `AGENTS.md` — global safety rules (small diffs, host-authoritative MP, no desync risk)
- `Docs/MP_LOBBY_LIFECYCLE_SPEC.md` — lobby lifecycle redesign (L1–L5); wire roster = sole join truth
- `Docs/MP_LOBBY_TICKET_HANDOVER.md` — supermarket ticket architecture, Option A wire dispatch

---

## START HERE ← next AI priority (lobby “good enough” gate)

Implement these **three tasks in order** before considering lobby work done for now:

| # | Task | Issue | Goal |
|---|------|-------|------|
| **1** | **Dual-host browse** | C | Finder must show **two cards** when two Steam accounts host open sessions (third account Find) |
| **2** | **Restore 2×2 setup layout** | E | Host MP setup defaults to classic layout: Sarge+Techie on seat 1, Medic+Gunner on seat 2 — **not** four units in one column while host is alone |
| **3** | **Steam display names** | F | Show real Steam persona names in browse cards and setup seat labels instead of `playerone` / `playertwo` |

**Deferred until after the above** (do not block “set aside” on these unless user asks):
- **Issue D** — P3 leave/rejoin (P2 same ritual passes)
- **Issue A** — Lobby card `N/M` occupancy digits (sprite atlas)

---

### Issue C — Dual host: finder only shows one session (TASK 1)

**Symptom:** Two Steam accounts host open sessions; a third account on Find **always sees one card**.

**UI is not the cap:** Browse supports 8 cards (2×4 paginated). Problem is upstream — Steam list and/or offer merge.

**Most likely root cause (code-reviewed, not yet fixed):**  
`multiplayer_lobby_apply_offer_upsert` (~19151) dedupes offers when `same_host_steam` **or** when incoming `host_steam_id` is empty **and** `owner_player_id` matches. Every host uses `owner_player_id = "p1"`. Discovery payloads do not embed Steam id; finder fills via `matchmaking_get_lobby_owner`. If that fails, **second host replaces first** in `offers_by_id`.

**Proposed fix (small, safe):**
1. Dedup **only** on `host_steam_id` or `session_key` (`76561198…:N`) — never on wire `owner_player_id`.
2. Embed `host_steam_id` in `encode_discovery_offer` / decode in finder (don’t rely solely on `get_lobby_owner`).
3. Log on finder: `discovery_list count`, `offers_by_id` size, distinct `host_steam_id` after merge.

**Touchpoints:** `multiplayer_lobby_apply_offer_upsert`, `encode_discovery_offer` / `decode_discovery_offer` — `main/steam_transport_gateb.lua`, `on_discovery_offer` callback ~29859.

**Pass test:** P1 + P2 both Open Game; P3 Find → `discovery_list count=2`, two visible cards.

---

### Issue E — Setup 2×2 layout regression (TASK 2)

**Symptom:** Host alone in setup sees **all four unit sprites stacked in seat 1 column**. When a guest joins, layout snaps to **2×2** (Sarge+Techie seat 1, Medic+Gunner seat 2). User wants **2×2 always** as the default — same as before launch-time N solo-host work.

**Root cause:** Launch-time N tied setup visuals to roster size. When roster = host only (`N=1`), these special cases apply:
- `multiplayer_get_slot_count_for_player` — p1 gets 4 slots, others 0
- `multiplayer_get_default_seat_assignments(1)` — all four units on p1
- `multiplayer_setup_is_valid` — requires 4 units on p1 when count=1

`multiplayer_setup_sync_player_count_from_roster` calls `multiplayer_setup_set_player_count(roster_n)`, which **resets** seat assignments whenever roster changes.

**Proposed fix:**
- Revert N=1 setup layout to **same 2×2 as N=2** for unit placement (keep launch-time N from roster at **Launch** only — product rule unchanged).
- Do **not** reshuffle unit sprites on every roster bump; guest join updates names/readiness, not column layout.
- Sarge must remain on seat 1 (existing validation).

**Touchpoints:** `multiplayer_get_slot_count_for_player`, `multiplayer_get_default_seat_assignments`, `multiplayer_setup_is_valid`, `multiplayer_setup_sync_player_count_from_roster` — `main/game.script` ~11742–11801, ~16577–16661.

**Pass test:** Host Open Game alone → setup shows 2×2 immediately; guest joins → layout unchanged (no column snap).

---

### Issue F — Steam display names (TASK 3)

**Symptom:** Browse cards and setup seat labels show `playerone`, `playertwo`, etc.

**Root cause:** All labels go through `mp_alpha_label_from_network_id` (~914), which maps wire ids `p1`→`playerone`. `lobby.local_username` is seeded from that helper (~18132), then baked into `host_display_name` at session mint (~18923). No Steam persona API is wired; `lobby_join_session` payload has no `display_name`; no `display_name_by_wire_id` on session.

**What already exists:** `session.host_display_name` / `host_name`; discovery `host` field; `steam_id_by_wire_id` roster maps; `steam_get_local_steam_id`.

**Proposed fix (phased in one tranche if possible):**
1. Read local Steam persona at MP init (needs backend call e.g. `user_get_persona_name` — **only `user_get_steam_id` exists today** in `steam_transport_gateb.lua`).
2. Set `lobby.local_username` from persona (still sanitize via `mp_lobby_sanitize_name` for letter sprites).
3. Browse cards: use `session.host_display_name` via sanitize — not wire-id mapping (~19911 currently runs `host_name` through `mp_alpha_label_from_network_id`).
4. Guest join: include `display_name` in `lobby_join_session`; host stores `display_name_by_wire_id` on offer; new `mp_display_name_for_wire_id(self, wire_id)` for setup labels.

**Touchpoints:** `mp_alpha_label_from_network_id`, `multiplayer_lobby_ensure_runtime`, `multiplayer_session_ticket_mint_host_session`, `lobby_join_session` handler ~25944, `multiplayer_lobby_render_session_cards`, setup name letters ~21245.

---

## “Good enough for now” — what lobby already does

Treat the following as **working baseline** — do not rewrite; extend with small diffs only.

| Area | Status |
|------|--------|
| Wire roster = join truth | ✅ Host-authoritative; Steam = transport |
| Launch-time N | ✅ Baked from `#joined_player_ids` at Launch |
| Min-1-guest launch gate | ✅ Host cannot launch solo without at least one synced guest |
| 2P join → setup → launch → in-match | ✅ Passes |
| 3P join → setup → launch → in-match | ✅ Passes |
| 2P setup Back → FIND → rejoin → setup | ✅ Passes (L2 hardening in `b1bf889`) |
| 3P setup Back → FIND → rejoin | ❌ P3 fails (Issue D — deferred) |
| 4P | Not smoke-tested |
| 2/3/4 player count buttons + Update settings | **Removed** — roster drives N |
| L1 lifecycle logging | ✅ `main/multiplayer_lobby_lifecycle.lua` |

**Architecture (unchanged):**
- **Steam (Gate B/C)** — discovery shell, P2P wire, `dvx_offer` metadata
- **Session ticket** — publish, join, launch, cancel (`main/multiplayer_session_ticket.lua`)
- **Wire roster** — `joined_player_ids`, steam↔wire seat maps

---

## Recently banked (`b1bf889`)

- Launch-time N from roster; removed 2/3/4 buttons and Update settings traffic
- Min-1-guest launch gate on host setup
- Guest setup Back → FIND (`multiplayer_lobby_guest_leave_setup_to_find`) — transport stays alive
- Wire roster join hardening: find-idle ping ignore, `steam_rejoin`, `forget_peer`, offer merge guards, fixed aggressive `guest_setup_evicted` on first join
- L1 lifecycle logging + `Docs/MP_LOBBY_LIFECYCLE_SPEC.md`

**Uncommitted / in-progress:** None at handover (working tree clean on `feature/lobby-discovery`).

---

## Open bugs (deferred)

### Issue A — No player count on lobby session cards

Browse cards show host name + status only; no `N/M`. Needs sprite digit pool (reuse score digit pattern). See ~19883 `multiplayer_lobby_render_session_cards`.

### Issue D — P3 leave/rejoin

P3 joins 3P lobby and reaches setup; after setup Back → FIND cannot re-enter. P2 same ritual passes. Extend L2 per lifecycle spec.

### Issue B — Post-abort re-join (P2 fixed in `b1bf889`)

Historical notes retained for context. P2 re-join passes; discovery merge B1 guards landed in prior cycles.

---

## Key files & functions

| Area | Path / symbols |
|------|----------------|
| Offer dedup (Task 1) | `multiplayer_lobby_apply_offer_upsert` — ~19125 |
| Discovery encode/decode | `encode_discovery_offer`, `decode_discovery_offer`, `emit_discovery_from_match_list` — `steam_transport_gateb.lua` |
| Setup 2×2 (Task 2) | `multiplayer_get_slot_count_for_player`, `multiplayer_get_default_seat_assignments`, `multiplayer_setup_sync_player_count_from_roster` — ~11742, ~16577 |
| Display names (Task 3) | `mp_alpha_label_from_network_id`, `lobby.local_username`, `multiplayer_session_ticket_mint_host_session` — ~914, ~18132, ~18908 |
| Session card render | `multiplayer_lobby_render_session_cards` — ~19883 |
| Setup name letters | MP setup UI block — ~21245 |
| Join wire | `lobby_join_session` handler — ~25944 |
| Lifecycle spec | `Docs/MP_LOBBY_LIFECYCLE_SPEC.md` |
| Debug log | `multiplayer_debug_log` → `dvx_mp_debug.txt` |

---

## Retest matrix (after Tasks 1–3)

| # | Scenario | Pass criteria |
|---|----------|---------------|
| 1 | Dual-host browse (Task 1) | P3 `discovery_list count=2`, two cards with distinct host names |
| 2 | Host-alone setup (Task 2) | 2×2 layout immediately; no 4-in-a-column; no snap on guest join |
| 3 | Steam names (Task 3) | Browse card + setup labels show persona names (sanitized letters), not `playerone` |
| 4 | 2P regression | Join → setup → Back → FIND → rejoin → launch |
| 5 | 3P join ritual | Three reach setup; launch with 2 guests |
| 6 | Solo launch blocked | Host alone cannot launch (`no_guests`) |

---

## Tester ritual (regression)

### 2P (baseline)
1. Host: HOST → Publish Open → setup  
2. Finder: FIND → tap card → setup  
3. Host: Launch → play → NEW TURN → abort  

### 3P
1. Host publish; two guests join via Find  
2. Launch blocked with 0–1 guests synced; OK with 2 guests synced  
3. All three in match; abort optional  

### Post-abort re-join (deferred Issue D)
1. 3P in setup  
2. P2 Back → FIND → rejoin → setup — **passes**  
3. P3 same — **fails today**  

---

## Constraints for the next AI

1. Small, reversible diffs; host-authoritative MP; no desync risk.  
2. Do not commit unless user explicitly requests.  
3. Lua chunk local limit in `main/game.script` — prefer module-level helpers over new chunk locals.  
4. Lobby UI names/digits: sprite atlas / letter glyphs only — no Defold fonts.  
5. Do not rework Gate E/G gameplay wire without discussion.  
6. Tasks 1–3 are **browse/setup polish** — do not refactor lifecycle (L3–L5) in the same pass.

---

## Related checkpoints

| Commit | Notes |
|--------|-------|
| `b5758f0` *(HEAD)* | Docs: record `b1bf889` in CURRENT_STATE |
| `b1bf889` | Launch-time N, min-1-guest gate, 2P leave/rejoin lifecycle, L1 logging |
| `6231a20` | Checkpoint before launch-time N reset |
| `f8a0958` | Update settings, cycle-2 sync, session-full reject UX |
| `232bd26` | Phase 5 in-match connected players + fan-out |

---

## Current stage (one paragraph)

**Launch-time N + L2 join hardening banked in `b1bf889`:** wire roster is sole join truth; 2P/3P join→launch→in-match and 2P leave/rejoin pass. Lobby is **functionally usable** but needs **three polish tasks** before we set it aside: (1) dual-host offer dedup/browse, (2) restore default 2×2 setup layout for host-alone, (3) Steam persona names instead of `playerone` placeholders. P3 leave/rejoin and lobby card N/M digits remain deferred. Next AI should implement Tasks 1→2→3 with the retest matrix above, then stop unless regressions appear.
