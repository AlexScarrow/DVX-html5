# AGENTS.md

Persistent project guidance for AI assistants working on DVX.

## Project Context
- Engine: Defold + Lua.
- Repository: `DVX-html5`.
- Priority: preserve gameplay stability and multiplayer sync safety.

## Core Working Rules
- Favor small, reversible changes over broad refactors.
- Do not change unrelated systems while fixing a targeted issue.
- Treat multiplayer logic as host-authoritative unless existing code says otherwise.
- Avoid introducing desync risk (state mutation should follow existing MP event/snapshot patterns).
- Be mindful of Lua chunk local-variable pressure in `main/game.script` (historical 200-local limit issue).
  - Prefer module-level/global helper functions over adding many new locals in the same chunk.

## Safety / Change Management
- Before risky or wide-impact edits, checkpoint current state (commit/bank first when requested).
- If unexpected unrelated diffs appear, stop and ask before proceeding.
- Never run destructive git operations unless explicitly requested.

## UI / Asset Integration
- For new UI sprites:
  - Add image to atlas used by that sprite path.
  - Ensure correct blend mode (`alpha`) where needed.
  - Verify z-order and scale in existing UI transform flow.
- Prefer reusing existing letter/score sprite rendering helpers for consistency.

## Solo Progression / Scoring Notes
- Production tier thresholds: `10000, 30000, 45000`.
- A temporary debug unlock toggle may exist; keep test toggles explicit and easy to disable.
- Older saves may lack newer breakdown fields; maintain backward-compatible defaults.

## Performance / Diagnostics
- If memory/perf instrumentation exists, keep it lightweight and gated by toggles.
- Avoid per-frame heavy refreshes unless required by gameplay correctness.

## Communication Style
- For “Discuss” requests: explain cause, risk, and exact proposed fix before broad edits.
- Keep implementation notes concise and include affected paths/toggles.
