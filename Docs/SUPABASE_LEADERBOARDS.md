# DVX Supabase Leaderboards

This is the implementation contract for the minimal-data leaderboard backend.
It is not a privacy notice or legal advice.

## Data Scope

The client and backend should store only:

- SteamID as an internal stable key.
- Steam display name for public display.
- Score.
- For multiplayer team details only: units played.
- Winner badge metadata, managed by an admin: solo/co-op category and count.

Do not store email addresses, prize fulfilment details, IP addresses, chat,
score breakdowns, performance stats, or unnecessary telemetry in the leaderboard
tables.

## Client Keys

The game client may contain:

- Supabase project URL.
- Supabase anon key, only for public reads or Edge Function calls.

The game client must not contain:

- Supabase service-role key.
- Any admin key.
- Prize/contact data.

Current client config keys in `game.project`:

```ini
[leaderboard]
supabase_enabled = 0
supabase_url =
supabase_anon_key =
supabase_submit_function = submit-leaderboard-score
supabase_read_limit = 100
```

Keep `supabase_enabled = 0` until the Supabase project, views, RLS, and anon
read tests are ready.

## Tables

```sql
create table if not exists public.players (
  steam_id text primary key,
  display_name text not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.solo_level_scores (
  steam_id text not null references public.players(steam_id) on delete cascade,
  level_id integer not null check (level_id between 1 and 20),
  score integer not null check (score >= 0),
  result text not null check (result in ('win', 'loss')),
  updated_at timestamptz not null default now(),
  primary key (steam_id, level_id)
);

create table if not exists public.mp_team_entries (
  team_entry_id text primary key,
  score integer not null check (score >= 0),
  created_at timestamptz not null default now()
);

create table if not exists public.mp_team_players (
  team_entry_id text not null references public.mp_team_entries(team_entry_id) on delete cascade,
  steam_id text not null references public.players(steam_id) on delete cascade,
  display_name text not null,
  units_played text[] not null default '{}',
  player_slot integer not null default 0,
  primary key (team_entry_id, steam_id)
);

create table if not exists public.winner_badges (
  steam_id text not null references public.players(steam_id) on delete cascade,
  badge_type text not null default 'winner',
  board text not null default 'all',
  period text not null default '',
  active boolean not null default true,
  awarded_at timestamptz not null default now(),
  primary key (steam_id, badge_type, board, period)
);
```

## Public Views

```sql
create or replace view public.solo_leaderboard_totals as
select
  p.steam_id,
  p.display_name,
  coalesce(sum(s.score), 0)::integer as score
from public.players p
left join public.solo_level_scores s on s.steam_id = p.steam_id
group by p.steam_id, p.display_name
order by score desc, p.display_name asc;

create or replace view public.mp_leaderboard_top as
select
  e.team_entry_id,
  e.score,
  e.created_at,
  coalesce(
    jsonb_agg(
      jsonb_build_object(
        'steam_id', tp.steam_id,
        'display_name', tp.display_name,
        'units_played', tp.units_played,
        'solo_count', coalesce(wb.solo_count, 0),
        'coop_count', coalesce(wb.coop_count, 0)
      )
      order by tp.player_slot asc, tp.display_name asc
    ) filter (where tp.steam_id is not null),
    '[]'::jsonb
  ) as players
from public.mp_team_entries e
left join public.mp_team_players tp on tp.team_entry_id = e.team_entry_id
left join (
  select
    steam_id,
    count(*) filter (where board = 'solo')::integer as solo_count,
    count(*) filter (where board in ('mp', 'coop'))::integer as coop_count
  from public.winner_badges
  where active = true
  group by steam_id
) wb on wb.steam_id = tp.steam_id
group by e.team_entry_id, e.score, e.created_at
order by e.score desc, e.created_at desc;

create or replace view public.winner_badges_public as
select
  steam_id,
  count(*) filter (where board = 'solo')::integer as solo_count,
  count(*) filter (where board in ('mp', 'coop'))::integer as coop_count
from public.winner_badges
where active = true
group by steam_id;
```

## RLS Baseline

Enable RLS on all tables. Public reads can be allowed through views or direct
select policies once you are comfortable with what each view exposes.

```sql
alter table public.players enable row level security;
alter table public.solo_level_scores enable row level security;
alter table public.mp_team_entries enable row level security;
alter table public.mp_team_players enable row level security;
alter table public.winner_badges enable row level security;

create policy "public read players"
on public.players for select
to anon
using (true);

create policy "public read solo scores"
on public.solo_level_scores for select
to anon
using (true);

create policy "public read mp entries"
on public.mp_team_entries for select
to anon
using (true);

create policy "public read mp players"
on public.mp_team_players for select
to anon
using (true);

create policy "public read active badges"
on public.winner_badges for select
to anon
using (active = true);
```

Do not add anon insert/update/delete policies for score tables. Score writes
should go through Edge Functions.

If "Automatically expose new tables" was disabled when creating the project,
also grant explicit read access:

```sql
grant usage on schema public to anon;

grant select on public.players to anon;
grant select on public.solo_level_scores to anon;
grant select on public.mp_team_entries to anon;
grant select on public.mp_team_players to anon;
grant select on public.winner_badges to anon;

grant select on public.solo_leaderboard_totals to anon;
grant select on public.mp_leaderboard_top to anon;
grant select on public.winner_badges_public to anon;
```

For Edge Function writes, grant table write privileges to the server-side
`service_role` role only:

```sql
grant usage on schema public to service_role;

grant select, insert, update on public.players to service_role;
grant select, insert, update on public.solo_level_scores to service_role;
grant select, insert, update on public.mp_team_entries to service_role;
grant select, insert, update on public.mp_team_players to service_role;
grant select, insert, update on public.winner_badges to service_role;
```

## Edge Function Contract

Recommended function name: `submit-leaderboard-score`.

Client sends one of:

```json
{
  "board": "solo",
  "steam_id": "76561198000000000",
  "display_name": "Player Name",
  "level_id": 3,
  "score": 1200,
  "result": "win"
}
```

```json
{
  "board": "mp",
  "team_entry_id": "session_t20_win",
  "score": 4200,
  "players": [
    {
      "steam_id": "76561198000000000",
      "display_name": "Player One",
      "units_played": ["sarge", "medic"]
    }
  ]
}
```

Edge Function responsibilities:

- Reject payloads missing SteamID/display name/score.
- Clamp or reject impossible values.
- Upsert `players`.
- Solo: upsert one row by `steam_id + level_id`; loss writes score `0`.
- MP: insert/upsert one team entry by `team_entry_id`, then upsert team players.
- Never require or store email addresses.
- Use the service-role key only inside the Edge Function environment.

In newer Supabase projects, custom secret names cannot start with
`SUPABASE_`. Store the service role key as an Edge Function secret named
`DVX_SERVICE_ROLE_KEY` and have the function read that secret. Do not put this
key in `game.project` or client code.

## Client Read Endpoints

When `supabase_enabled = 1`, the client reads these public REST endpoints with
the anon key:

```text
GET /rest/v1/solo_leaderboard_totals?select=steam_id,display_name,score&order=score.desc,display_name.asc&limit=100
GET /rest/v1/mp_leaderboard_top?select=team_entry_id,score,created_at,players&order=score.desc,created_at.desc&limit=100
GET /rest/v1/winner_badges_public?select=steam_id,solo_count,coop_count
```

Reads are asynchronous. The game shows local cache/fallback rows immediately and
updates the screen after a successful remote response. Failed reads should never
block gameplay.

## Winner Badges

Winner badges are server-managed. The shipped game should read badges but never
write them.

The recommended monthly process is implemented in
`Docs/SUPABASE_MONTHLY_SEASON_CLOSE.sql`.

At month close, Supabase should:

1. Archive the current live solo and multiplayer leaderboard rows.
2. Award one `winner_badges` row for every top solo player.
3. Award one `winner_badges` row for every Steam ID on the top MP team.
4. Clear the live score tables so the next month starts empty.

The public badge count view already counts `winner_badges` rows, so adding one
row per winning period automatically increments the visible badge count. If a
player wins solo twice, they have two active `board = 'solo'` rows and the game
shows the solo icon count as `2`.

The monthly close function uses all tied top scores as winners. For MP, if two
teams tie for top score, every player on both teams receives a co-op winner row.
This is the least surprising tie rule and avoids silent subjective tie breaks.

The function should be run by Supabase/server-side privileges only. Do not expose
it to the game client or grant execute permission to `anon`.

Winners still contact you voluntarily outside the game to claim any prize.

## Manual Setup Checklist

1. Create the Supabase project.
2. Pick a hosting region appropriate for your player/privacy obligations.
3. Run the table and view SQL.
4. Enable and review RLS.
5. Run `Docs/SUPABASE_MONTHLY_SEASON_CLOSE.sql`.
6. Deploy the Edge Function.
7. Store the service-role key only as an Edge Function secret.
8. Put only URL/anon key/function name into client config.
9. Test with fake SteamIDs before enabling live submissions.
10. Enable the optional monthly cron only after dry-run output looks correct.
