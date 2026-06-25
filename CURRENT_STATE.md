# DVX Leaderboards + Supabase — Current State & AI Handover

**Last updated:** 2026-06-25
**Working path:** `/Users/alexscarrow/Desktop/DVX/DVX-html5`
**Branch:** `feature/holdout-mission`
**Current focus:** Supabase-backed leaderboards are implemented. Current/next work is release polish around leaderboard prize-claim UX, multiplayer testing, and small UI fixes.

Also read:
- `AGENTS.md` — small diffs, host-authoritative MP, avoid desync risk, beware `main/game.script` Lua chunk local pressure.
- `Docs/MP_LOBBY_LIFECYCLE_SPEC.md` — MP lifecycle background; lobby work is maintenance-only unless regressions appear.
- `Docs/SUPABASE_LEADERBOARDS.md` — current Supabase leaderboard contract and setup checklist.
- `Docs/SUPABASE_MONTHLY_SEASON_CLOSE.sql` — repeatable SQL source for monthly winner/archive/reset automation.

---

## 2026-06-25 Handover Update

This file previously described the upcoming Supabase leaderboard feature. That feature has now largely been implemented and banked. Treat the older sections below as design history/spec context; this section is the current state.

### Banked Recent Commits

Important recent commits on this branch:

| Commit | Summary |
|--------|---------|
| `7bf25e0` | Bank monthly leaderboard prizes. |
| `af1e703` | Bank multiplayer ready gate tweaks. |
| `7e12fb7` | mplayer fixes yet to be tested |
| `60b5c59` | Bank brute FX client cleanup. |
| `e01050c` | Bank remaining visual and demo tweaks. |
| `895f08c` | Bank blood impact ring effects. |
| `7072b36` | Bank turret target power accuracy. |
| `5243c30` | Bank corpse item visual fix. |
| `c06175b` | Bank crate pickup animation tweaks. |
| `2bf697c` | Bank dropped item stacking tweaks. |
| `85ccc31` | Bank holdout objective and brute visibility tweaks. |
| `beb7cc8` | Bank GO buffer safety fix. |

`feature/holdout-mission` is likely ahead of origin if recent banks have not been pushed.

### Supabase Leaderboards Implemented

The game now has Supabase-backed Solo and Multiplayer leaderboard support with local fallback/cache/queueing through `main/leaderboard_remote.lua`.

Client-side reads:

- Solo: `/rest/v1/solo_leaderboard_totals?select=steam_id,display_name,score...`
- MP: `/rest/v1/mp_leaderboard_top?select=team_entry_id,score,created_at,players...`
- Winner badges: `/rest/v1/winner_badges_public?select=steam_id,solo_count,coop_count`

Submission behavior:

- Solo mission completion records/uploads the latest result for the completed level.
- Solo win stores score; solo loss stores `0`, replacing previous score for that level.
- Solo leaderboard is fetched only from title-screen Solo Leaderboard.
- MP host submits team rows; clients do not duplicate-submit.
- MP post-mission flow routes to MP leaderboard, then back to MP chooser.

Privacy/data minimization:

- The intended public leaderboard data remains SteamID, Steam display name, score, and MP units played.
- Do not add email, shipping, prize, chat, IP, or other contact details to leaderboard tables.
- Prize fulfilment should be separate, voluntary, and outside the leaderboard schema.

### Supabase Monthly Winner Automation

Supabase setup was completed/tested in the project dashboard on 2026-06-25.

Installed/stored in Supabase Postgres:

- `public.close_leaderboard_month(p_period text, p_dry_run boolean)`
- `public.leaderboard_season_closes`
- `public.solo_leaderboard_archive`
- `public.mp_leaderboard_archive`
- `pg_cron` job `dvx-monthly-leaderboard-close`

Automation:

- Cron schedule is active: `5 0 1 * *`.
- This runs at `00:05 UTC` on the 1st of each month.
- It closes the previous month by calling `close_leaderboard_month(..., false)`.
- It archives live leaderboard rows, awards winner badge rows, and clears live solo/MP score tables.

Manual test already performed:

- Dry run for `2026-06` succeeded.
- Real close for `2026-06` was run.
- Solo archive had 6 rows; top solo winner score was `53423`.
- MP archive had 6 rows; top MP team score was `3698`.
- Winner badge counts updated in `winner_badges_public`.
- Live MP leaderboard was cleared.
- Solo totals view originally showed retained players with `0` scores because `players` rows remain while `solo_level_scores` was cleared.
- The source SQL has since been updated so `solo_leaderboard_totals` only returns players with live `solo_level_scores` rows; after applying that view update in Supabase, a fresh month should show an empty Solo leaderboard until new solo results are submitted.

Tie rule:

- All tied top solo players receive a solo winner badge row.
- All Steam IDs on tied top MP teams receive a co-op winner badge row.

Important:

- The game client should never call `close_leaderboard_month`.
- `close_leaderboard_month` execute is granted to `service_role`, not `anon`.
- Keep `Docs/SUPABASE_MONTHLY_SEASON_CLOSE.sql` as the source-of-truth script for recreating/modifying the server-side setup.

### Winner Badges and Prize Claim UX

Winner badge display exists:

- Solo and co-op badge icons appear beside leaderboard names.
- In lobby/MP setup, badges appear beneath display names.
- Multiple wins render as icon plus count.
- Badge counts come from Supabase `winner_badges_public` and local fallback cache.

Prize concept:

- Player gets a modest optional prize after reaching `5x` solo or `5x` co-op winner badges.
- Leaderboard panel art has been updated with prize explainer text and a `CLAIM PRIZE!` button.
- The current button action is only a dummy debug action.

Current dummy claim behavior:

- `assets/images/leaderboard_panel.png` includes the visible text/button.
- `main/game.script` defines `LEADERBOARD_CLAIM_PRIZE_BUTTON_*` constants.
- Clicking the hotspot on Solo or MP leaderboard prints:
  - `PRIZE CLAIM | prize applied for`

Future release task:

- Replace the dummy print with a real URL/contact flow closer to release date.
- Likely flow: a website/contact page explains that winners must prove control of the winning Steam account, then voluntarily provide prize/shipping details outside Supabase leaderboard data.
- Do not store prize fulfilment details in Supabase leaderboard tables.

### Recent Multiplayer Fixes Still Needing Wider Testing

Several multiplayer robustness/UI fixes are banked but still need full 2-4 player Steam testing:

- Host reclaims humans from stale/disconnected/desynced players.
- Host marks stale players inactive and rejects late commands from inactive players.
- Stale/desynced clients are pushed back toward chooser/lobby instead of remaining in a phantom mission.
- `advisory_playerLeft.png` shows a player-left/host-control advisory.
- Host `NEW TURN` is now ready-gated:
  - active guests must click ready before host can advance,
  - departed/inactive guests do not block the gate,
  - host button tints red while waiting.
- Portrait UI shows Steam display names above HP/AP pips in MP.
- Portrait display names are max 12 characters, 0.315 scale, shifted left from the initial placement.
- Brute ghost/smoke FX are explicitly deleted on snapshot reconciliation.
- Pickup fallback visuals are hardened to avoid invisible/black crate fallback where item visual data is missing.

### Other Recently Banked Gameplay/Visual Work

Recent banked work also includes:

- Boardgame alien movement now mirrors human counter/token movement more closely.
- Alien boardgame proxy shadow uses `human_proxyShadow_boardgame.png`.
- Turret ammo count/persistent packed turret ammo.
- Turret burst hit feedback timing improved.
- Tile dimming when no human selected.
- Simplified single-image outro plate system.
- Outro letterbox/backdrop/zoom/pulse tuning.
- Collection `max_instances` raised and turret projectile fallback hardened.
- Ultrawide identity input profile added.
- Holdout objective explainer added.
- Dropped item stacking/scale/z-layer tweaks.
- Crate pickup animation to backpack slots with pulse/stagger.
- Corpse drag/world visuals use dead human sprites.
- Turret hit chance is now power-based: guaranteed hit if target tile is powered, otherwise 50%.
- Alien/human blood impact rings and particle timing were tuned.

### Current Working Tree Notes

At the time of this update, the only expected untracked files are local runtime caches:

- `dvx_leaderboard_remote_cache_mp_v1`
- `dvx_leaderboard_remote_cache_solo_v1`
- `dvx_leaderboard_solo_progress_sync_v1`
- `dvx_leaderboard_winner_badges_v1`

Do not commit these. They can contain local player/leaderboard identifiers and test state.

### Recommended Next Tasks

1. Full multiplayer test pass with 2-4 Steam clients:
   - ready gate,
   - stale/left player handling,
   - portrait names,
   - player-left advisory,
   - MP leaderboard flow after mission/outro.
2. Verify leaderboard panel prize hotspot position after any further panel art edits.
3. Closer to release, replace dummy `PRIZE CLAIM | prize applied for` behavior with a real web/contact URL flow.
4. Before public release, clean test Supabase rows/badges such as `local_*`, `test_steam_*`, and edge-test entries.
5. Before public release, prepare privacy/prize terms page:
   - leaderboard data scope,
   - public display of Steam names/scores,
   - monthly reset timing/timezone,
   - tie handling,
   - prize eligibility and verification,
   - voluntary contact/shipping details,
   - deletion/access request path.

---

## Recent Banked State

Important recent commits on this branch:

| Commit | Summary |
|--------|---------|
| `4325b20` | Bank explicit alien spawn weights. |
| `8471206` | Bank alien path cache optimization. |
| `30b91f7` | Bank Brute visual tuning. |
| `9ac5c5a` | Bank Brute melee reveal tuning. |
| `5825e31` | Bank Brute ghost smoke effect. |
| `292dbbf` | Bank level spawn pressure migration. |
| `d45c1b6` | Bank config and spawn pressure migration. |

`feature/holdout-mission` may be ahead of origin if the latest banks have not been pushed.

---

## Current Objective

Design and implement Supabase-backed leaderboards:

1. Multiplayer leaderboard first.
2. Solo leaderboard next.
3. Add clickable leaderboard entry detail panels.
4. Keep local leaderboard/cache/fallback behavior so gameplay never depends on network availability.

The current local leaderboard code is embedded in `main/game.script`, using `FLOW_STATE_SCORE_SOLO`, `FLOW_STATE_SCORE_MP`, local save keys, sprite glyph rendering, and existing score breakdown data from `score_runtime.lua`.

---

## Multiplayer Leaderboard Spec

### Core Model

Each multiplayer leaderboard row represents a **team result**.

- The team score is owned by all contributing players.
- If a later monthly competition names a winning team, every Steam ID in that team entry counts as a winner.
- Only the host should auto-submit the multiplayer team result.
- Clients should not submit duplicate team rows.

### Multiplayer Flow

After a multiplayer mission ends:

1. Mission completes.
2. Outro plays, or is skipped.
3. Players go directly to the Multiplayer leaderboard screen.
4. Host submits/queues the team score.
5. Leaderboard screen fetches remote MP rows from Supabase.
6. Back button exits to MP chooser screen: `host / find / back`.

This differs from Solo because team play is expected to be more leaderboard/social-comparison focused immediately after a match.

### Multiplayer Team Entry Data

Store at least:

- `team_entry_id` or deterministic `match_id`
- `team_score`
- `mission_type`
- `level_id`
- `result = "win"` only for uploads
- `completed_at`
- `host_steam_id`
- `player_count`
- `score_breakdown`
- useful performance stats:
  - turns elapsed
  - aliens killed by type
  - humans alive/dead/escaped
  - civilians rescued
  - objective-specific stats

Store team players separately:

- `team_entry_id`
- `steam_id`
- Steam display name at time of upload
- assigned/played humans, e.g. `Sarge`, `Medic`
- player slot/order
- optional later per-player stats

### Multiplayer Detail Panel

Clicking a multiplayer leaderboard row opens a panel on the right side of the leaderboard screen.

Panel should show:

- Header: mission, level, team score, date
- One row per player:
  - Steam user name
  - humans played, e.g. `Sarge`, `Medic`
- Lower section:
  - score breakdown and mission performance stats
- Bottom:
  - Back button to close panel, returning to the leaderboard list

This panel is important because the compact row cannot show up to four full Steam names plus detail.

---

## Solo Leaderboard Spec

### Core Model

Solo leaderboard is cumulative across levels `1-20`, but each level contributes only the **latest result** for that player.

Rules:

- A win records that level's latest score.
- A loss records `0` for that level.
- Replaying a level replaces that level's previous contribution.
- This means replaying a level is risky: a player can improve or lower their cumulative score.
- Levels never played contribute `0`.

Example:

- Level 3 win: `2000`
- Level 18 win: `3500`
- Total: `5500`
- Replay Level 3 and lose: Level 3 becomes `0`
- New total: `3500`

### Solo Flow

Mission end:

1. Record latest level result locally.
2. Queue or submit Supabase upsert for `steam_id + level_id`.
3. Do **not** fetch the Supabase leaderboard.
4. Do **not** automatically enter the solo leaderboard.

Title screen:

1. Add a `Solo Leaderboard` button.
2. Player clicks it.
3. Retry any pending solo uploads.
4. Fetch current solo leaderboard from Supabase.
5. Show Solo leaderboard.
6. Back returns to title screen.

This avoids “paging” Supabase leaderboard reads every time a solo mission ends.

### Solo Data

Store one current row per player and level:

- `steam_id`
- latest Steam display name
- `level_id`
- `mission_type`
- `latest_score`
- `latest_result = "win" | "loss"`
- `played_at`
- `score_breakdown`
- optional stats for detail panel later

The displayed Solo leaderboard is:

`SUM(latest_score) GROUP BY steam_id`

### Solo Detail Panel

Not required first, but should follow the same pattern as MP:

- Click a row.
- Show player name, cumulative score, and per-level latest scores/results.
- Back closes the panel.

---

## Title Screen Leaderboard Access

Add title-screen access for both boards:

- `Solo Leaderboard`
- `Multiplayer Leaderboard`

Solo button:

- Fetches Solo leaderboard on demand.
- Back returns to title.

Multiplayer button:

- Fetches MP leaderboard on demand.
- Back returns to title when entered from title.
- Back returns to MP chooser when entered from post-match MP flow.

Implementation should track entry origin for back-button behavior, e.g. `leaderboard_return_flow = "title"` or `"mp_chooser"`.

---

## Supabase Integration Spec

### Recommended Tables / Views

`players`

- `steam_id` primary key
- `latest_display_name`
- `updated_at`

`solo_level_scores`

- primary or unique key: `steam_id + level_id`
- `latest_score`
- `latest_result`
- `mission_type`
- `score_breakdown`
- `played_at`

`mp_team_score_events`

- `team_entry_id` primary key
- `match_id` unique if available
- `team_score`
- `mission_type`
- `level_id`
- `score_breakdown`
- `completed_at`
- `host_steam_id`
- `player_count`

`mp_team_players`

- `team_entry_id`
- `steam_id`
- `display_name_at_upload`
- `humans_played`
- `player_slot`

Views/RPCs:

- `solo_leaderboard_totals`: sum `solo_level_scores.latest_score` by `steam_id`
- `mp_leaderboard_top`: team rows sorted by `team_score`
- optional detail RPCs for selected team/player rows

### Upload Rules

Solo:

- Upload/upsert on every completed solo attempt.
- Win uploads score.
- Loss uploads `0`.
- Network failure queues local pending upload.

Multiplayer:

- Host auto-submits only.
- Upload only winning team results unless design changes later.
- Clients fetch/read but do not submit the team row.
- Host failure queues pending team upload locally.

### Fetch Rules

Solo:

- Fetch only when player clicks title-screen Solo Leaderboard.

Multiplayer:

- Fetch after MP mission/outro because the flow lands on MP leaderboard.
- Fetch when player clicks title-screen Multiplayer Leaderboard.

Both:

- If fetch fails, show local cached leaderboard or advisory.
- Never block mission completion or gameplay on Supabase.

---

## Edge Cases / Gotchas

### Identity and Display Names

- Current local leaderboard can show placeholder names like `playerone/playertwo`; Supabase rows should store Steam IDs and display names so remote boards render correct names.
- Store latest display name in `players`, but also snapshot display names in score/team rows for historical display if needed.
- Steam display names can change, include profanity, unusual Unicode, or unsupported glyphs.
- Existing UI uses sprite glyphs, so names may need sanitizing/truncation or a richer text strategy.

### Duplicate MP Submissions

- Host-only submission avoids most duplicate team rows.
- Still use a unique `match_id` or deterministic team submission key if possible.
- Supabase upsert/idempotency should prevent double submits if host retries.

### Offline / Failed Uploads

- Maintain a local pending upload queue.
- Retry at title screen, score screen, or leaderboard entry.
- Avoid infinite tight retry loops.
- Show a small advisory only if useful.

### Solo Replay Risk

- Loss overwrites previous score with `0`.
- This is intentional.
- Confirm local solo progression/score UI uses the same latest-result model so local and remote totals agree.

### Monthly Competitions Later

MP:

- Monthly winner can be highest team score in date range; all team players are winners.

Solo:

- Needs a later decision:
  - monthly total from latest level rows as of month end, or
  - only attempts played inside the month.
- Do not overbuild this now; keep timestamps so both are possible later.

### Privacy / GDPR / Legal Risk

Not legal advice; get professional advice before public launch.

Likely considerations:

- Steam ID and display name are personal data under GDPR/UK GDPR when tied to a person/account.
- Publish a clear privacy notice explaining:
  - what data is collected,
  - why it is collected,
  - how long it is retained,
  - who processes it,
  - how deletion/access requests can be made.
- Collect the minimum data needed for leaderboard function.
- Avoid storing IP addresses, emails, chat, or unnecessary personal data.
- Supabase region matters; consider UK/EU hosting if targeting UK/EU users.
- Use Supabase Row Level Security.
- Do not embed privileged service-role keys in the client.
- Use anon keys only with strict RLS, or preferably Supabase Edge Functions / a small backend for writes.
- Rate-limit writes/reads where possible.
- Plan for deletion requests:
  - delete/anonymize `players`
  - delete/anonymize solo rows and MP team player rows
  - decide whether team scores remain with anonymized contributors.
- Add terms/privacy wording that leaderboard names/scores are public.
- Database hack risk cannot be eliminated; reduce exposure by:
  - storing minimal data,
  - using least-privilege keys,
  - enabling RLS,
  - keeping secrets out of the game client,
  - using backups and audit logs,
  - documenting deletion/contact process.

### Security / Anti-Cheat

- Client-side scores can be spoofed if the client can write directly.
- For a first pass this may be acceptable, but leaderboard competition will eventually need stronger validation.
- Prefer backend/Edge Function validation:
  - requires Steam ID/session proof if possible,
  - validates expected fields,
  - rejects impossible values,
  - deduplicates MP match submissions.

---

## Suggested Implementation Order

1. Document local leaderboard entry shape and score payloads.
2. Add title-screen buttons for Solo Leaderboard and Multiplayer Leaderboard.
3. Add a remote leaderboard abstraction module, e.g. `leaderboard_remote.lua`, with stub/local fallback first.
4. Add Supabase config placeholders, disabled by default until credentials/schema are ready.
5. Implement local pending upload queue.
6. Implement Solo latest-per-level upsert payload.
7. Implement host-only MP team submission payload.
8. Implement remote fetch for Solo and MP boards.
9. Add right-side detail panel for MP rows.
10. Add Solo detail panel later if desired.

Keep each step bankable and testable.

---

## Current Constraints / Warnings

1. Keep changes small and reversible.
2. Treat multiplayer as host-authoritative.
3. Only host should auto-submit MP team results.
4. Do not spam Supabase reads; fetch leaderboards on deliberate leaderboard entry.
5. Keep local fallback/queue behavior so gameplay is not blocked by network.
6. `main/game.script` is near Lua chunk local limits; prefer module-level/global helpers or new modules.
7. UI text uses sprite glyphs, not Defold fonts.
8. Do not commit or push unless explicitly asked.

---

## One-Sentence Handoff

Supabase-backed Solo/MP leaderboards and monthly winner badge automation are implemented and banked; the next likely work is multiplayer test/fix polish plus, later near release, replacing the leaderboard `CLAIM PRIZE!` dummy hotspot with a real website/contact URL flow.
