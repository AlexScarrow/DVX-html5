# DVX Holdout Mission — Current State & AI Handover

**Last updated:** 2026-06-19  
**Working path:** `/Users/alexscarrow/Desktop/DVX/DVX-html5`  
**Branch:** `feature/holdout-mission`  
**Base branch:** `feature/lobby-discovery` pushed to `origin` at `a40cf26`  
**Last banked baseline:** `a40cf26` — noEnter cell support and Steam callback pump fixes

Also read:
- `AGENTS.md` — small diffs, host-authoritative MP, avoid desync risk, beware `main/game.script` Lua chunk local pressure.
- `Docs/MP_LOBBY_LIFECYCLE_SPEC.md` — MP lifecycle background; lobby work is now maintenance-only unless regressions appear.

---

## Current Objective

Implement a new **Holdout** mission type.

Definition from user:
- A Holdout mission has a configurable turn countdown, defaulting to **50** turns.
- If at least one human is alive when the countdown reaches zero, the players win.
- The per-instance countdown must live in `level_defs.lua` for levels of this mission type, e.g. `holdout_turns = 50`.
- The countdown display should be visually similar to the deployed bomb countdown used by Purge/Cleanse missions, but **without repeated alert SFX**.
- Victory may need a different LAUNCH/victory button sprite later, e.g. "you did it!", and may eventually need a Holdout-specific outro. First pass can fall back to existing win outro if needed.
- The level editor will need another mission tab/category for Holdout missions.

---

## Recommended Implementation Plan

1. **Inspect existing mission plumbing**
   - `MISSION_TYPE_HOLDOUT = "holdout"` already exists in `main/game.script`.
   - Map how existing mission types are declared in `main/level_defs.lua`, selected in setup/editor, rendered in UI, scored, and completed.
   - Inspect Purge/Cleanse countdown HUD before adding Holdout display code.

2. **Add level definition support**
   - Add `holdout_turns` support for Holdout level defs.
   - Default missing/invalid values to `50`.
   - Keep field per-level so future Holdout instances can vary the timer.

3. **Add runtime state**
   - Track `self.holdout_turns_remaining` and original configured count.
   - Initialize/reset on level load.
   - Decrement exactly once per full turn boundary.
   - In MP, host must own the countdown and victory trigger; include state in snapshots/checksums if needed.

4. **Add victory condition**
   - If `holdout_turns_remaining <= 0` and at least one human is alive, trigger mission win.
   - All-humans-dead loss remains unchanged and should override.
   - Prefer a reason tag like `holdout_survived`, e.g. `enter_mission_outro(self, "win", "holdout_survived")`, with generic win fallback.

5. **Add countdown UI**
   - Reuse or minimally branch from Purge/Cleanse bomb countdown digit rendering.
   - Do not play the bomb alert SFX each turn.
   - Keep sprite/digit rendering consistent with the existing UI style.

6. **Add level editor support**
   - Add Holdout to mission type/category selection.
   - Expose/configure `holdout_turns` for Holdout levels.
   - Keep editor changes small and avoid touching unrelated editor flows.

7. **Polish hooks, if requested**
   - Victory button sprite for Holdout completion.
   - Holdout-specific outro or outro slide path.

---

## Completed Baseline Before This Branch

The following work is banked and pushed on `feature/lobby-discovery`:

| Commit | Summary |
|--------|---------|
| `a40cf26` | Bank noEnter and Steam pump fixes. |
| `e27f04d` | Bank visual and human UI polish. |
| `5166e5c` | Bank lobby UI polish. |
| `cf9d2ad` | Bank Steam persona lobby names. |
| `a9d9185` | Bank dual-host lobby discovery fixes. |

Recent important outcomes:
- Steam lobby/matchmaking pass is considered complete enough to set aside, except 4P smoke testing remains unverified.
- Dual-host browse works.
- Steam persona names render with alphanumeric sprite glyph support.
- Lobby cards show inline player count.
- Host/finder chooser UI and advisory sprites were polished.
- Human UI panel is now closed by default and opens on selecting the already-selected human.
- `noEnter` cell support exists: tile cells default `noEnter = false`; authored `noEnter = true` cells are treated as out of bounds for movement/pathing/spawn/cell selection.
- Global Steam callback pump was removed from solo/global update; Steam callbacks are pumped through the Steam transport after init.

---

## Current Git State Expected

After this handoff update is committed:
- Branch should be `feature/holdout-mission`.
- Working tree should be clean.
- `feature/lobby-discovery` is already pushed to `origin`.
- No Holdout implementation has started yet.

---

## Constraints / Warnings

1. Keep changes small and staged by subsystem.
2. Treat multiplayer as host-authoritative.
3. Avoid desync: Holdout countdown and win condition must be deterministic or host-broadcast/snapshotted.
4. `main/game.script` is near Lua chunk local limits; prefer module-level/global helpers over adding many locals.
5. UI text uses sprite glyphs, not Defold fonts.
6. Do not refactor mission/outro/editor broadly just to add Holdout.
7. Do not commit or push unless explicitly asked.

---

## Suggested First Test Matrix

| Scenario | Expected |
|----------|----------|
| Solo Holdout level, default missing `holdout_turns` | Starts at 50 turns |
| Solo Holdout level with custom `holdout_turns` | Starts at configured value |
| Human survives to zero | Win outro triggers |
| All humans die before zero | Loss still triggers |
| Countdown HUD | Updates like Purge/Cleanse timer but no repeated alert SFX |
| MP Holdout 2P smoke | Host/client countdown agree; host triggers win |

---

## One-Sentence Handoff

We are starting `feature/holdout-mission` from banked/pushed lobby work; implement a configurable Holdout mission where players win by surviving until a turn countdown reaches zero, reusing the existing countdown HUD style and preserving host-authoritative MP sync.
