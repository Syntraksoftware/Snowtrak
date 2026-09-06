-- Run this in the Supabase SQL editor after 018. Purely additive: two
-- columns, two tables, three indexes. Nothing existing changes shape, so
-- deployed code that predates this migration keeps working.
--
-- Design: docs/superpowers/specs/2026-09-02-duel-and-leaderboard-design.md

begin;

-- Per-activity opt-in for the global board. Default false so nothing joins
-- the leaderboard by accident -- an activity is published to a ranking only
-- because its owner said so, one activity at a time.
alter table activities
  add column if not exists on_leaderboard boolean not null default false;

-- Partial: the board only ever reads opted-in rows, and the index stays the
-- size of that subset rather than the size of `activities`. start_time
-- leads because every board query is a window, and user_id follows because
-- every board query groups by it.
create index if not exists activities_leaderboard_idx
  on activities (start_time desc, user_id)
  where on_leaderboard;

-- ISO 3166-1 alpha-2, chosen by the user. Null means they have not picked
-- one and appear on the global board only. Inferring this from GPS would
-- reclassify anyone who takes a single trip abroad.
alter table profiles
  add column if not exists country_code char(2);

-- user_stats.week_start rolls over and the previous week's numbers are gone
-- with it, so the board's history has to be written down before that
-- happens. Top 100 per metric per scope: enough for "who won last week" and
-- for a trophy, bounded at a few thousand rows a year.
create table if not exists leaderboard_weeks (
  week_start date not null,
  metric     text not null,
  scope      text not null,
  rank       int  not null,
  user_id    uuid not null references user_info(id) on delete cascade,
  value      double precision not null,
  primary key (week_start, metric, scope, rank),
  constraint leaderboard_weeks_metric_check
    check (metric in ('vertical', 'speed', 'distance')),
  constraint leaderboard_weeks_rank_check check (rank >= 1)
);

-- Reading one week's board is the only access pattern; the primary key
-- already serves it. This index serves the other one: "where did I place".
create index if not exists leaderboard_weeks_user_idx
  on leaderboard_weeks (user_id, week_start desc);

create table if not exists duels (
  id                uuid primary key default gen_random_uuid(),
  challenger_id     uuid not null references user_info(id) on delete cascade,
  opponent_id       uuid not null references user_info(id) on delete cascade,
  metric            text not null,
  duration          text not null,
  status            text not null default 'pending',
  -- Written when the challenge is accepted, never before. That is what
  -- makes a window non-retroactive: neither player can bank a head start
  -- by choosing when to send the challenge.
  starts_at         timestamptz,
  ends_at           timestamptz,
  challenger_value  double precision,
  opponent_value    double precision,
  -- Null while unfinished, and also null on a draw. settled_at is what
  -- distinguishes the two.
  winner_id         uuid references user_info(id) on delete set null,
  created_at        timestamptz not null default now(),
  settled_at        timestamptz,
  constraint duels_metric_check
    check (metric in ('vertical', 'speed', 'distance')),
  constraint duels_duration_check
    check (duration in ('today', 'weekend', 'week')),
  constraint duels_status_check
    check (status in ('pending', 'active', 'finished',
                      'declined', 'cancelled', 'expired')),
  constraint duels_distinct_players check (challenger_id <> opponent_id)
);

-- One live duel per pair, in either direction. least/greatest normalise the
-- pair so that A challenging B and B challenging A collide on the same key
-- rather than both being accepted.
create unique index if not exists duels_one_live_per_pair
  on duels (least(challenger_id, opponent_id),
            greatest(challenger_id, opponent_id))
  where status in ('pending', 'active');

-- The two list queries: "my duels" and the settlement sweep.
create index if not exists duels_participant_idx
  on duels (challenger_id, created_at desc);
create index if not exists duels_opponent_idx
  on duels (opponent_id, created_at desc);
create index if not exists duels_settlement_idx
  on duels (ends_at)
  where status = 'active';

commit;
