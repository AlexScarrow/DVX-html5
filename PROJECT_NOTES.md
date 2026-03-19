# Project Notes (DVX)

## Working style
- Discuss before implementing major/new systems.
- Keep changes small and testable.
- If a change goes wrong, revert to the last known-good state.
- Bank (commit) frequently after verified in-game behavior.

## Coding preferences
- Prefer minimal-risk edits over large refactors.
- Keep visuals data-driven and easy to tune via constants.
- Preserve existing gameplay behavior unless explicitly requested.
- Avoid introducing broad system changes when a targeted fix is enough.

## Gameplay conventions
- Prioritize player readability (clear feedback, clear state).
- Keep AP/movement changes explicit and predictable.
- New mechanics should default to robust fallback behavior.

## Rendering conventions
- Be explicit about Z values for new visuals.
- Verify layer ordering against doors, units, tile overlays, and UI.
- Prefer reusable marker objects where possible to avoid instance churn.

## Git workflow
- Create feature branches for larger feature work.
- Commit with concise intent-focused messages.
- Push after banking and verification.
- Keep local and remote in sync after merge.

## Handover checklist (for any new developer/agent)
- Current branch and latest commit hash.
- What was changed and why.
- What is still pending.
- Known issues/risks.
- Exact files touched.
