-- DVX monthly leaderboard close-out.
--
-- Run this in Supabase SQL Editor after the base leaderboard schema from
-- Docs/SUPABASE_LEADERBOARDS.md is installed.
--
-- Model:
-- - Live tables are the current season/month only.
-- - This function archives the live rows, awards winner badge rows for the
--   top solo score and top MP team score, then clears live score tables.
-- - Re-running for the same period is idempotent: badge/archive inserts use
--   ON CONFLICT DO NOTHING.
-- - Archives are intentionally not granted to anon. Keep them admin-only unless
--   you explicitly decide to publish season history later.

create table if not exists public.leaderboard_season_closes (
  period text primary key,
  closed_at timestamptz not null default now(),
  solo_winner_score integer not null default 0,
  solo_winner_count integer not null default 0,
  mp_winner_score integer not null default 0,
  mp_team_winner_count integer not null default 0
);

create table if not exists public.solo_leaderboard_archive (
  period text not null,
  rank integer not null,
  steam_id text not null,
  display_name text not null,
  score integer not null,
  archived_at timestamptz not null default now(),
  primary key (period, steam_id)
);

create table if not exists public.mp_leaderboard_archive (
  period text not null,
  rank integer not null,
  team_entry_id text not null,
  score integer not null,
  created_at timestamptz not null,
  players jsonb not null default '[]'::jsonb,
  archived_at timestamptz not null default now(),
  primary key (period, team_entry_id)
);

-- Keep the current-season Solo board empty after a monthly reset. Players are
-- retained for identity/badge history, but only players with live solo score
-- rows should appear on the public Solo leaderboard.
create or replace view public.solo_leaderboard_totals as
select
  p.steam_id,
  p.display_name,
  sum(s.score)::integer as score
from public.players p
join public.solo_level_scores s on s.steam_id = p.steam_id
group by p.steam_id, p.display_name
order by score desc, p.display_name asc;

alter table public.leaderboard_season_closes enable row level security;
alter table public.solo_leaderboard_archive enable row level security;
alter table public.mp_leaderboard_archive enable row level security;

create or replace function public.close_leaderboard_month(
  p_period text default to_char(((now() at time zone 'UTC') - interval '1 month'), 'YYYY-MM'),
  p_dry_run boolean default true
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_period text := coalesce(nullif(trim(p_period), ''), to_char(((now() at time zone 'UTC') - interval '1 month'), 'YYYY-MM'));
  v_solo_winner_score integer := 0;
  v_solo_winner_count integer := 0;
  v_mp_winner_score integer := 0;
  v_mp_team_winner_count integer := 0;
  v_mp_player_winner_count integer := 0;
  v_live_solo_rows integer := 0;
  v_live_mp_rows integer := 0;
begin
  select count(*)::integer into v_live_solo_rows
  from public.solo_leaderboard_totals
  where score > 0;

  select count(*)::integer into v_live_mp_rows
  from public.mp_team_entries
  where score > 0;

  select coalesce(max(score), 0)::integer into v_solo_winner_score
  from public.solo_leaderboard_totals;

  select count(*)::integer into v_solo_winner_count
  from public.solo_leaderboard_totals
  where score > 0
    and score = v_solo_winner_score;

  select coalesce(max(score), 0)::integer into v_mp_winner_score
  from public.mp_team_entries;

  select count(*)::integer into v_mp_team_winner_count
  from public.mp_team_entries
  where score > 0
    and score = v_mp_winner_score;

  select count(distinct tp.steam_id)::integer into v_mp_player_winner_count
  from public.mp_team_entries e
  join public.mp_team_players tp on tp.team_entry_id = e.team_entry_id
  where e.score > 0
    and e.score = v_mp_winner_score;

  if p_dry_run then
    return jsonb_build_object(
      'dry_run', true,
      'period', v_period,
      'live_solo_rows', v_live_solo_rows,
      'live_mp_rows', v_live_mp_rows,
      'solo_winner_score', v_solo_winner_score,
      'solo_winner_count', v_solo_winner_count,
      'mp_winner_score', v_mp_winner_score,
      'mp_team_winner_count', v_mp_team_winner_count,
      'mp_player_winner_count', v_mp_player_winner_count
    );
  end if;

  insert into public.solo_leaderboard_archive (period, rank, steam_id, display_name, score)
  select
    v_period,
    (rank() over (order by score desc))::integer as rank,
    steam_id,
    display_name,
    score
  from public.solo_leaderboard_totals
  where score > 0
  on conflict (period, steam_id) do nothing;

  insert into public.mp_leaderboard_archive (period, rank, team_entry_id, score, created_at, players)
  select
    v_period,
    (rank() over (order by e.score desc, e.created_at asc))::integer as rank,
    e.team_entry_id,
    e.score,
    e.created_at,
    coalesce(
      jsonb_agg(
        jsonb_build_object(
          'steam_id', tp.steam_id,
          'display_name', tp.display_name,
          'units_played', tp.units_played,
          'player_slot', tp.player_slot
        )
        order by tp.player_slot asc, tp.display_name asc
      ) filter (where tp.steam_id is not null),
      '[]'::jsonb
    ) as players
  from public.mp_team_entries e
  left join public.mp_team_players tp on tp.team_entry_id = e.team_entry_id
  where e.score > 0
  group by e.team_entry_id, e.score, e.created_at
  on conflict (period, team_entry_id) do nothing;

  insert into public.winner_badges (steam_id, badge_type, board, period, active)
  select steam_id, 'winner', 'solo', v_period, true
  from public.solo_leaderboard_totals
  where score > 0
    and score = v_solo_winner_score
  on conflict (steam_id, badge_type, board, period) do nothing;

  insert into public.winner_badges (steam_id, badge_type, board, period, active)
  select distinct tp.steam_id, 'winner', 'coop', v_period, true
  from public.mp_team_entries e
  join public.mp_team_players tp on tp.team_entry_id = e.team_entry_id
  where e.score > 0
    and e.score = v_mp_winner_score
  on conflict (steam_id, badge_type, board, period) do nothing;

  insert into public.leaderboard_season_closes (
    period,
    closed_at,
    solo_winner_score,
    solo_winner_count,
    mp_winner_score,
    mp_team_winner_count
  )
  values (
    v_period,
    now(),
    v_solo_winner_score,
    v_solo_winner_count,
    v_mp_winner_score,
    v_mp_team_winner_count
  )
  on conflict (period) do update set
    closed_at = excluded.closed_at,
    solo_winner_score = excluded.solo_winner_score,
    solo_winner_count = excluded.solo_winner_count,
    mp_winner_score = excluded.mp_winner_score,
    mp_team_winner_count = excluded.mp_team_winner_count;

  delete from public.solo_level_scores;
  delete from public.mp_team_entries;

  return jsonb_build_object(
    'dry_run', false,
    'period', v_period,
    'archived_solo_rows', v_live_solo_rows,
    'archived_mp_rows', v_live_mp_rows,
    'solo_winner_score', v_solo_winner_score,
    'solo_winner_count', v_solo_winner_count,
    'mp_winner_score', v_mp_winner_score,
    'mp_team_winner_count', v_mp_team_winner_count,
    'mp_player_winner_count', v_mp_player_winner_count
  );
end;
$$;

revoke all on function public.close_leaderboard_month(text, boolean) from public;
revoke all on function public.close_leaderboard_month(text, boolean) from anon;
revoke all on function public.close_leaderboard_month(text, boolean) from authenticated;
grant execute on function public.close_leaderboard_month(text, boolean) to service_role;

-- Manual dry-run check. This does not award badges or clear tables.
select public.close_leaderboard_month('TEST-DRY-RUN', true);

-- Manual real close example. Replace the period with the month being closed.
-- select public.close_leaderboard_month('2026-06', false);

-- Optional automatic schedule.
-- In Supabase Dashboard, first enable the `pg_cron` extension if it is not
-- already enabled. Then run the statements below.
--
-- create extension if not exists pg_cron with schema extensions;
--
-- select cron.schedule(
--   'dvx-monthly-leaderboard-close',
--   '5 0 1 * *',
--   $$select public.close_leaderboard_month(to_char(((now() at time zone 'UTC') - interval '1 month'), 'YYYY-MM'), false);$$
-- );
--
-- To inspect scheduled jobs:
-- select * from cron.job;
--
-- To remove the schedule:
-- select cron.unschedule('dvx-monthly-leaderboard-close');
