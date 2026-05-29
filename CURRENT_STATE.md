# DVX Current State Snapshot

## Repo State
- Branch: `feature/solo-progression-revamp`
- HEAD: `52fdf95`
- Working tree: clean
- Remote: pushed (`feature/solo-progression-revamp` on origin)

## Active Debug/Test Toggles
- `SOLO_SETUP_DEBUG_UNLOCK_ALL_MISSIONS = true` in `main/game.script`
- `RUNTIME_MEMORY_PROBE_ENABLED = true` in `main/game.script`
- `RUNTIME_MEMORY_PROBE_INTERVAL_S = 10.0` in `main/game.script`

## Recent Changes Landed
- Solo mission score breakdown panel implemented and tuned in solo setup UI.
- Solo score details persisted per mission entry (`score_details`).
- DNA retrieved score contribution set to `1000` for DNA/holdout profile.
- Portal row mapping fixed to include purge portal deployment points.
- Memory probe logging added (`MEM PROBE | ...`).
- Score runtime event log capped at 512 entries.
- Solo thresholds restored to `10000, 30000, 45000`.
- Temporary all-missions-unlock debug toggle added for testing.

## Known Notes
- Older solo mission saves without `score_details` will show category zeros until replayed and re-saved.
- Current memory probe behavior indicates GC churn, not confirmed leak growth.

## Quick Restore Checklist After Tool/IDE Updates
1. Open workspace folder `DVX-html5`.
2. Verify branch `feature/solo-progression-revamp`.
3. Verify HEAD commit `52fdf95`.
4. Confirm `git status` is clean.
5. Confirm debug toggles above are set as intended for current testing.
