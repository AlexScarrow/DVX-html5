# DVX Codebase Synopsis

Last reviewed: 2026-06-26

This document is a maintainer map for the current Defold/Lua codebase. It is not
an exhaustive API reference. Use it to answer "where should I look first?" before
debugging, adding comments, or extracting code from `main/game.script`.

## Current Shape

DVX is still orchestrated primarily by `main/game.script`. That script owns the
Defold lifecycle (`init`, `update`, `on_input`), most runtime state on `self`,
core game flow, UI creation, multiplayer command handling, and many legacy helper
functions.

Several large systems have already been split into modules. The safest
maintenance direction is to keep `main/game.script` as the coordinator and move
self-contained systems into modules only when their inputs/outputs are clear.

Detailed audit notes:

- `main/game.script` is roughly 39.5K lines and contains hundreds of function definitions.
- Many helpers are intentionally chunk-global because this project has hit Lua local-variable pressure before.
- The most sensitive area is the multiplayer command/event/snapshot region, which spans several thousand lines and is wired into `update`, `on_input`, `on_message`, and many `multiplayer_apply_*` handlers.
- The middle of `game.script` has a clearer structure than it first appears, but the structure is under-commented and hard to navigate without grep.

Do not treat "not obviously referenced" as dead code without proof. Lua globals,
Defold messages, factory URLs, sprite animation ids, multiplayer event strings,
and save keys can all be indirect references.

## High-Level Runtime Flow

At startup, `main/game.script` builds the base world and runtime state:

- Initializes edge/cell helpers and creates the 15x15 world grid.
- Loads tile and level definitions from `main/tile_defs.lua` and `main/level_defs.lua`.
- Bakes the selected level into runtime cells.
- Initializes camera, HUD layout, realtime scaffold flags, multiplayer state, SFX state, UI factories, and flow state.
- Acquires input and enters the current screen or gameplay flow.

During `update`, `game.script` acts as the central scheduler:

- Advances camera, panning, zoom, UI transforms, animation pulses, particle cleanup, and advisory timers.
- Updates alien/civilian movement, projectiles, reactive fire, environmental hazards, tile/object loops, score tracking, and mission completion.
- Runs multiplayer transport pumps, snapshot/heartbeat checks, ready-gate state, host/client reconciliation, and lobby state.
- Runs leaderboard fetch/submit callbacks and flow screen rendering.

During `on_input`, input is first normalized by `map_window_input_to_logical`, then routed by flow state:

- Non-gameplay screens go through `handle_flow_touch`.
- Level editor input is delegated to `LEVEL_EDITOR.handle_input`.
- Gameplay input is split between UI panel actions, portrait selection, command/resource dragging, zoom/pan, direct world interaction, and multiplayer command dispatch.

## Major Files And Ownership

`main/game.script`

- Main coordinator and largest maintenance risk.
- Owns top-level constants, feature flags, flow state constants, UI positions, global helper functions, Defold lifecycle functions, input routing, and most state mutation.
- Contains critical multiplayer logic, including host/client authority, event application, snapshots, ready gate, stale player handling, and MP setup/lobby glue.
- Contains core board/path helpers, alien/civilian movement, human selection/action routing, UI rendering, audio loop control, title/score/demo flows, and local wrappers around newer modules.

`main/config.lua`

- Central config and balance table.
- Owns feature flags, solo progression mapping, spawn pressure defaults, visual FX tuning, UI config construction, class role hooks, AP costs, alien balance, realtime scaffold settings, buff registry, and hazard damage.
- Good place for future explicit "test only" or "release" toggles, but keep shipped defaults conservative.

`main/level_defs.lua`

- Authored mission layouts.
- Defines mission type, spawn setup, spawn pressure triggers, and unit loadouts per level.
- High-impact for progression/testing because `main/config.lua` maps solo mission slots onto these level indices.

`main/tile_defs.lua`

- Tile library and tile/object definitions used by level baking.
- Look here for tile contents, object names, interactable machinery, doors, vents, visual overlays, and object dependency data.

`main/loot_runtime_actions.lua`

- Large extension module for item, backpack, command, turret, factory/workshop, corpse, drag/drop, and object interaction behavior.
- Exposes functions by mutating/extending a runtime table through `M.extend(runtime, ctx)`.
- Uses a context table from `game.script`; check context dependencies before extracting further.

`main/loot_runtime_markers.lua`

- Companion runtime extension for visual markers and UI/world item rendering.
- Owns marker updates for turrets, items, pips, pickup/factory visuals, and related sprite transforms.

`main/loot_runtime_utils.lua`

- Small shared utility helpers for loot/runtime modules.
- Good target for additional low-risk pure helpers if duplication appears.

`main/cleanse_runtime.lua`

- Cleanse/weed/flame mission runtime extension.
- Owns cleanse-specific state, weed visuals, flame cells, flamer shot behavior, and mission-specific effects.
- Good model for future mission-specific modules, but it still depends on a broad context table.

`main/melee_runtime.lua`

- Melee combat helper/runtime logic.
- Includes target naming, alien/human melee resolution, and combat feedback hooks.

`main/score_runtime.lua` and `main/score_profiles.lua`

- Mission scoring state, event recording, and score calculation profiles.
- `score_runtime.lua` tracks raw metrics and deduplication sets.
- `score_profiles.lua` owns mission-aware scoring weights and thresholds.

`main/leaderboard_remote.lua`

- Supabase/local-fallback leaderboard abstraction.
- Owns local save keys, upload queue/cache, Solo/MP payload normalization, Supabase REST reads, winner badge reads, and local fallback behavior.
- Runtime cache files named `dvx_leaderboard_*` are local state and should not be committed.

`main/multiplayer_transport.lua`

- Transport abstraction between loopback/websocket/Steam style transports.
- Owns message encoding/decoding, queueing, status dispatch, and Steam transport integration.

`main/steam_transport_gateb.lua`

- Steam lobby/P2P transport implementation.
- Owns Steam lobby discovery, session metadata, join handshake, lobby offers, peer mapping, and low-level wire packets.
- Treat as high risk because protocol strings and state transitions must match `game.script` expectations.

`main/multiplayer_lobby_lifecycle.lua`

- Explicit lobby lifecycle state helper.
- Tracks guest/host lifecycle labels and logs transitions.
- Low-risk module and a good example of a small focused extraction.

`main/multiplayer_session_ticket.lua`

- Session ticket/display helper for multiplayer lobby identity and session sharing.
- Helps keep lobby ticket behavior out of `game.script`.

`main/input_calibration_profiles.lua`

- Native input/HUD profile database.
- Owns Windows/Mac calibration presets, ultrawide HUD offsets, and profile matching by platform/window size.
- Check this file first for PC fullscreen/maximize click offset issues.

`main/outro_plate.lua`, `main/outro_sequences.lua`, `main/outro_slideshow.lua`

- Outro plate/slideshow flow helpers.
- Used for win/loss/mission result presentation and should remain mostly presentation-only.

`main/demo_config.lua`

- Demo-specific flow/config helper.
- Keep demo behavior isolated here or in `main/config.lua` feature flags where possible.

`main/level_editor.lua`

- In-game/editor tooling for level editing.
- Currently disabled by config in release defaults.
- Quarantine candidate if the release build does not need editor code loaded.

`main/character.lua`

- Older/smaller character module.
- Appears to be an early prototype module with type names that do not match the current live alien taxonomy.
- Only remove after verifying `main/test_systems.script` and any editor/test paths are not needed.

`main/multiplayer_ws_adapter.lua`

- WebSocket adapter support for older/non-Steam multiplayer transport.
- Likely maintenance-only while current transport mode is Steam.

## Important Docs

`AGENTS.md`

- Project guidance for AI/code maintenance.
- Especially important: small reversible changes, host-authoritative MP, avoid desync risk, and beware Lua chunk local pressure in `main/game.script`.

`CURRENT_STATE.md`

- Handover state for current release work.
- Some branch references may become stale after promotion to `main`; update when beginning a new major work phase.

`Docs/MP_LOBBY_LIFECYCLE_SPEC.md`

- Multiplayer lobby lifecycle design background.
- Use before changing lobby join/leave/session handling.

`Docs/SUPABASE_LEADERBOARDS.md`

- Supabase leaderboard backend contract, table/view setup, client read endpoints, and Edge Function expectations.

`Docs/SUPABASE_MONTHLY_SEASON_CLOSE.sql`

- Source-of-truth SQL for monthly leaderboard close/archive/reset automation.

`Docs/TEST_BUILD_RELEASE_CHECKLIST.md` and `Docs/TESTERS_README_FIRST.md`

- Release/test wave guidance.
- Useful before pushing builds to Steam/itch testers.

## `main/game.script` Section Map

The file is too large to understand linearly. Treat it as these rough zones:

- Constants, require statements, feature flags, UI positions, global tuning values.
- Multiplayer lobby/name/display helpers and debug logging.
- HUD expansion/input calibration helpers.
- Cell, tile, grid, coordinate, adjacency, movement, door, vent, and pathfinding helpers.
- Level baking and authored content integration.
- Unit/human/alien/civilian runtime data creation.
- Visual spawning, shadows, boardgame/computer aesthetic mode, particles, impact rings, blood, smoke, and overlays.
- UI factory helpers, global UI buttons, portrait UI, human panel UI, flow screen sprites, title/setup/score/leaderboard/demo screens.
- Loot/runtime context assembly and wrappers around `LOOT_RUNTIME`.
- Door/object/factory/workshop/power/escape pod/fabricator interactions.
- Audio/SFX loop state, spatial SFX, adaptive music, and HTML5 music muting.
- Flow-state transitions and score/leaderboard submission.
- Multiplayer setup/lobby UI, session lifecycle, seat assignment, launch logic, host/client synchronization.
- Multiplayer gameplay events, command dispatch, snapshots, stale player handling, ready gate, host reclaim, and reconciliation.
- Realtime scaffold and experimental mode hooks.
- `init`, `update`, and `on_input`.

## High-Risk Areas

Multiplayer sync and authority

- Any function that mutates units, turn id, world objects, inventory, score, or mission outcome during MP can desync host and clients.
- Host should remain authoritative unless a function explicitly exists for local prediction or client display.
- Strings used as command/event types are part of the wire protocol. Search before renaming.
- The highest-risk maintenance zone is the large multiplayer gameplay sync block: command dispatch, event application, snapshot build/apply, digest comparison, heartbeat correction, and stale-player recovery.

Input mapping and HUD layout

- `map_window_input_to_logical`, `screen_to_world`, `apply_runtime_hud_layout`, and `main/input_calibration_profiles.lua` are tightly coupled.
- A visual HUD move may require matching hitbox/input treatment.
- HTML5 and native paths intentionally differ.

Flow-state transitions

- `enter_flow_state`, `handle_flow_touch`, title/demo/score/leaderboard routing, and post-mission flows are user-facing.
- Avoid changing back-button destinations without checking Solo, MP chooser, post-match MP leaderboard, and demo flow.

Audio

- Native and HTML5 audio behavior differ.
- Current web build mutes music loops to avoid browser crackle while preserving gameplay SFX.
- Do not assume a fix for HTML5 should apply to Steam/Mac native builds.

Realtime scaffold

- Realtime/insane-mode code exists but is not release-polished.
- It can keep alien activity active and block human actions if enabled casually.
- Treat as deferred experimental work, especially in multiplayer.

Leaderboard/Supabase data

- The game client should not call monthly close functions.
- Do not add prize/contact/shipping/private data to leaderboard tables.
- Keep local fallback/queue behavior so gameplay never depends on network availability.

Lua chunk pressure

- `main/game.script` has historically been close to Lua local-variable/chunk limits.
- Prefer module-level helpers or existing modules over adding many new locals to the script.

## Likely Quarantine Or Extraction Candidates

These are candidates for future maintenance branches, not immediate deletions.

- `main/character.lua` and `main/test_systems.script`: likely early prototype/test path.
- Vent pathfinding scaffold: explicitly marked inactive in `game.script`.
- `create_cell_visuals`: appears to be an early cell factory stub and should be verified.
- Level editor: isolate behind config and consider loading only when enabled.
- Realtime scaffold: document as experimental and consider moving to `main/realtime_runtime.lua`.
- MP debug/telemetry/lag simulation: move to a debug module once stable.
- Flow screen rendering: title, demo, Solo setup, MP setup, score, leaderboard, and outro rendering could become separate UI modules.
- Leaderboard UI: Supabase transport is already in `leaderboard_remote.lua`; on-screen leaderboard rendering still appears to live mostly in `game.script`.
- Input/HUD calibration: profile data is modular, but application logic remains in `game.script`.
- Audio mixer: loop state and HTML5 music policy could move to a small audio runtime module.
- Door/path/grid helpers: many are pure-ish helpers and could eventually move into `main/grid_runtime.lua` or similar.

## Possible Dead Or Legacy Code Categories

Do not delete these based only on this list. Use it as an investigation queue.

- WebSocket multiplayer transport while current config uses Steam transport.
- Level editor code when `level_editor_enabled = false`.
- Realtime scaffold while `realtime_toggle_disabled = true` and `REALTIME_MODE.enabled = false`.
- MP lag simulation UI while `mp_lag_sim_ui_enabled = false`.
- Debug outro preview toggles and debug level buttons.
- Older docs and duplicate untracked `" 2"` files in the local working tree.
- Recovery/backup branches outside current `main`.

Safe proof before deletion should include:

- Text search for direct calls and string/event references.
- Defold collection/factory/atlas references.
- Save key and network protocol compatibility check.
- A small playtest of affected flow.
- A banked commit before deletion.

## Commenting Guidelines

Prefer comments that explain ownership and risk:

```lua
-- Host-only MP turn advancement. Mutates authoritative turn state and
-- broadcasts the snapshot guests use to reconcile; do not call from clients.
```

Avoid comments that simply restate the line:

```lua
-- Set x to y.
```

Good first comment targets:

- `map_window_input_to_logical`: explain native/HTML5 and ultrawide assumptions.
- `enter_flow_state`: explain major flow destinations and side effects.
- MP command/event handlers: mark host-only, client-only, or shared reconciliation paths.
- Ready gate and stale player handling: explain active/inactive guest behavior.
- Leaderboard submission/fetch functions: mark local fallback vs Supabase calls.
- HTML5 audio mute block: explain why web music loops are disabled.
- Realtime scaffold: mark experimental/deferred.

## Suggested Maintenance Plan

1. Keep `main` as the release-candidate branch and do audit work on maintenance branches.
2. Add comments and docs first; avoid behavior changes.
3. For each candidate extraction, create a small branch and move one bounded system at a time.
4. After extraction, run focused smoke tests for the affected flow.
5. Delete code only after proving no references and banking a safe checkpoint.

Recommended first low-risk follow-up:

- Add section/function comments to input mapping, HTML5 audio policy, Supabase leaderboard flow, and MP ready-gate/stale-player areas.

Recommended first extraction follow-up:

- Move audio loop policy or leaderboard UI helpers before touching MP gameplay code.

## Quick Reference

- Balance/AP/alien stats: start in `main/config.lua`.
- New tile/object behavior: start in `main/tile_defs.lua`, then search `game.script` and `LOOT_RUNTIME` for the object name.
- New mission layout: start in `main/level_defs.lua`.
- Solo progression/unlocks: start in `main/config.lua` and Solo setup helpers in `game.script`.
- Scoring weights: start in `main/score_profiles.lua`; score event recording is in `main/score_runtime.lua`.
- Cleanse/flamer/weed behavior: start in `main/cleanse_runtime.lua`.
- Pickup/factory/turret/backpack behavior: start in `main/loot_runtime_actions.lua`.
- Multiplayer transport/lobby: start in `main/multiplayer_transport.lua`, `main/steam_transport_gateb.lua`, and the MP docs.
- Multiplayer gameplay sync/desync: start in the `multiplayer_*` command/event/snapshot region of `main/game.script`.
- Leaderboard submit/read: start in `main/leaderboard_remote.lua` and the Supabase docs.
- PC fullscreen/click offsets: start in `map_window_input_to_logical`, `apply_runtime_hud_layout`, and `main/input_calibration_profiles.lua`.
- Outro comic flow: start in `main/outro_sequences.lua`, `main/outro_slideshow.lua`, and `main/outro_plate.lua`.
