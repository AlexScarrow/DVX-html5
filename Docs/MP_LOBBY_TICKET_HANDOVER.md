# MP Lobby / Supermarket Ticket — Session Handover

**Last updated:** 2026-06-14  
**Branch:** `feature/lobby-supermarket-ticket-system`  
**Stable checkpoint (git):** `92bfad5` — *Make session host the wire dispatch player for interchangeable 2P hosting.*

Read this document **first** when continuing multiplayer lobby / ticket / hosting work. Also read `AGENTS.md` (repo root) for global safety rules.

---

## Path lock

- **Only valid working path:** `/Users/alexscarrow/Desktop/DVX/DVX-html5`
- Do not edit other project folders.
- Confirm `git status` before changes. **Do not commit unless the user explicitly asks.**

---

## What we are working on now

### Product goal

Build **stable Steam multiplayer for 2–4 players** where **any seated player can host a session** (starting with interchangeable **P1 / P2** hosting on two machines). Stability beats shipping speed.

### Architecture in one sentence

**Steam = discovery / invite shell (Gate B/C).**  
**In-game “supermarket ticket” = session authority (who can publish, launch, cancel).**  
**Wire dispatch host = who processes inbound gameplay commands during a match (Option A).**

These three roles are **intentionally split** — session host is **not** always Steam lobby owner and is **not** always product seat `p1`.

### Current stable scope (banked)

| Area | Status |
|------|--------|
| Ticket mint / lifecycle | Done — `main/multiplayer_session_ticket.lua` |
| Lobby authority (`host_steam_id`, launch/cancel/join) | Done — Phase 2 |
| Match wire dispatch (`host_wire_player_id` → `host_player_id`) | Done — Option A |
| Local / LAN 2P: P1 host ×2 cycles | Pass |
| Local / LAN 2P: P2 host → P1 joins → launch → play | Pass |
| P2 host: units + NEW TURN on correct peer | Pass (after Option A) |
| Remote `mp_internal` friend sees host session in browse | **Not working — diagnosed, deferred** |

### Explicitly **not** done yet

- Remote session browse for friends not in the same Steam lobby (Phase 3 / discovery proxy)
- 3–4 player roster + wire fan-out at scale
- UI clarity for “searching vs alone in empty Steam lobby”
- Fix for **P2 session host** publishing via Steam discovery (only Steam lobby owner can `publish_session` today)

---

## Brief history — what we built, tried, and what failed

### Steam gate progression (foundation)

Commits from `e24d510` through `f7ed171` established Steam Gates **A–G**:

- Gate B: Steam lobby search/create/join (`main/steam_transport_gateb.lua`)
- Gate D: `dvx_offer` metadata discovery on Steam lobbies
- Gate E: enter session / seat assignment
- Gate F: host-local match launch
- Gate G: host-authoritative gameplay commands over P2P wire

This gave a working **2-peer Steam shell** when both clients land in the **same Steam lobby** and Gate C wire comes up.

### Supermarket ticket foundation (`43c699e`)

Added `main/multiplayer_session_ticket.lua`:

- Session key: `host_steam_id:session_number`
- Terminal states, monotonic session allocator
- Helpers: `is_session_host`, `can_host_launch`, etc.
- Product seat default `SESSION_HOST_NETWORK_ID = "p1"` — **seat label, not wire authority**

Fixed P1-host multi-cycle lobby hygiene issues discovered during first ticket integration.

### Phase 2 — lobby plane authority (`4e94f54`)

**Problem:** Launch/cancel/join still keyed off “Steam lobby owner == local player” (`owner_player_id`), so **P2 session host** could not drive lobby actions even when they minted the ticket.

**Fix:** Lobby authority on **`host_steam_id`** (ticket minter), plus:

- `host_wire_player_id` on tickets (who sends wire for that session)
- `lobby_ticket_id` split from match `session_id`
- Wire upserts as browse path when peer already connected

**Result:** P2 could host; P1 could see/join and launch from lobby. **But match gameplay broke** (P2 moves / NEW TURN wrong).

### Option A — wire dispatch host (`92bfad5`) — **current bank**

**Problem:** Match plane still treated **Steam host** or fixed **`p1`** as gameplay command authority. When P2 was session host, inbound commands were processed on the wrong peer → broken turns and unit control.

**Fix:** `host_player_id` = **wire dispatch player** from ticket `host_wire_player_id`:

- Helpers in `main/game.script`: `multiplayer_resolve_wire_dispatch_player_id`, `multiplayer_apply_wire_dispatch_player_id`, `multiplayer_is_wire_dispatch_host`, `multiplayer_apply_steam_lobby_wire_defaults`
- `wire_dispatch_player_id` in `session_config` / `match_started`
- Gate G: dispatch when `multiplayer_is_wire_dispatch_host` — **removed** `steam_is_host()` requirement
- Gate E: only sets `local_player_id` (p1/p2); does **not** force `host_player_id = p1`
- Inbound gameplay commands only on wire dispatch peer

**Result:** Full P1↔P2 host interchangeability **within a paired 2-peer shell** — user-confirmed pass.

### Remote friend test — **failed (deferred, not a regression)**

User asked `mp_internal` invited friend to update, join lobby, spot host’s published session. **Friend saw nothing.**

**Diagnosis (discuss-only, no code yet):**

1. Session cards are **not global**. They come from **Steam `dvx_offer` on a shared lobby** and/or **wire upsert after Gate C** — friend must be in host’s Steam lobby (or matching discovery must find it).
2. Gate B auto-searches; if `lobby_match_list count=0` twice, client **creates its own empty Steam lobby** — friend can be “in MP” but isolated.
3. Hard filter on `dvx_proto` / `net_protocol_version` — mismatched builds never see each other’s lobbies.
4. Steam `discovery_publish` only when **`steam_is_host`** — P2 session host cannot publish to Steam metadata; remote browse depends on wire after pairing.
5. Draft sessions do not appear; must be **`published_open`**.

**Conclusion:** Local interchangeable hosting work is sound; **remote pairing / browse layer** is the open problem — separate from Option A.

---

## Checkpoint stack (git)

| Commit | Summary |
|--------|---------|
| `f7ed171` | Gate G anchor |
| `43c699e` | Ticket foundation + P1-host cycle fixes |
| `4e94f54` | Phase 2 — lobby authority via `host_steam_id` |
| `92bfad5` | **Option A** — session host = wire dispatch player (**HEAD, clean tree**) |

---

## Key files

| File | Role |
|------|------|
| `main/multiplayer_session_ticket.lua` | Ticket mint, states, session host helpers |
| `main/game.script` | Lobby UI, wire dispatch, Gate E/F/G integration (~large; 200-local limit risk) |
| `main/steam_transport_gateb.lua` | Steam lobby search/create/join, `dvx_offer` discovery publish |
| `main/multiplayer_transport.lua` | Transport abstraction |
| `game.project` | `env_name`, `net_protocol_version`, `transport_mode`, `transport_room_id` |
| `Docs/TESTERS_README_FIRST.md` | Tester instructions |
| `Docs/TEST_BUILD_RELEASE_CHECKLIST.md` | Pre-release smoke + protocol mismatch checks |
| `AGENTS.md` | AI safety rules (host-authoritative, small diffs, no casual Gate G edits) |

### Config defaults (repo `game.project`)

- `env_name = LOCAL`
- `net_protocol_version = 1`
- `transport_mode = steam`
- `transport_room_id = dvx_remote_friend_20260509`

Test builds must match on **protocol version** and ideally same release wave.

---

## Rules for the next AI session

### Do casually **without** discussion

- Read-only investigation, logging analysis, docs
- Small bugfixes clearly scoped to lobby browse / discovery (when user asks)

### Discuss **before** editing

- **Gate E** (seat assignment) or **Gate G** (gameplay command dispatch) — high desync risk
- Changing who is authoritative for launch vs wire vs Steam metadata
- Broad refactors in `main/game.script` — local-variable compile ceiling (~200 locals)

### User terminology

- **Bank / bank this** = accepted stable state; may or may not mean git commit (only commit when asked)

### Testing expectations before claiming “fixed”

1. P1 host ×2 lobby cycles (create → publish → launch → leave → repeat)
2. P2 host → P1 joins → launch → play (moves + NEW TURN on session host peer)
3. For remote browse fixes: two real clients, same build/protocol, host up first, compare `dvx_mp_debug.txt` (`lobby_match_list`, `lobby_join` vs `lobby_create`, `discovery_*`, `gateb_ok`, `gatec_ok`)

---

## Recommended next work (priority order)

1. **Remote browse / pairing** — friend visibility in `mp_internal` (build parity, Gate B pairing UX, optional longer search-before-create, discovery proxy for guest session hosts)
2. **Phase 3 polish** — wire-first browse at scale; clearer “alone vs paired” lobby UI
3. **3–4 player** — roster + wire fan-out (do not assume 2P patterns generalize)
4. **Hygiene** — `lobby_ticket_id` / match cleanup on long sessions if issues resurface

---

## Bootstrap prompt (paste at start of new chat)

```
Read Docs/MP_LOBBY_TICKET_HANDOVER.md first, then AGENTS.md.
Path lock: /Users/alexscarrow/Desktop/DVX/DVX-html5 only.
Branch: feature/lobby-supermarket-ticket-system, banked at 92bfad5.
Confirm git status before edits. Do not commit unless I ask.
We deferred remote mp_internal browse — do not rework Gate E/G without discussing first.
```

---

## Related older doc

`Docs/AI_HANDOFF.md` has general project workflow and path-lock history but is **partially stale** on multiplayer (still mentions relay-first and “host always p1”). For MP ticket/lobby work, **this document is authoritative.**
