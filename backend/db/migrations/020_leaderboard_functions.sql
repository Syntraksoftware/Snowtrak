-- Run this in the Supabase SQL editor after 019. Three read-only functions,
-- no schema change.
--
-- PostgREST cannot express a GROUP BY, and the alternative -- pulling every
-- opted-in activity for the week into the service and folding it there --
-- is an unbounded read that grows with the user base. The aggregate belongs
-- next to the rows.
--
-- Every one of these mirrors a rule in
-- activity-backend/domain/competition/metrics.py. The two must agree:
--   * windows are half-open, [start, end)
--   * speed is 3600 / smallest positive max_pace, in km/h, so that higher
--     wins for every metric and one ORDER BY serves them all
--   * a zero max_pace is a missing reading, not an infinite speed
--
-- Design: docs/superpowers/specs/2026-09-02-duel-and-leaderboard-design.md

begin;

-- Which rows a scope admits. One definition, three callers -- the board, the
-- placing and the snapshot must agree on who is on a board, and repeating
-- this predicate three times is how they would stop agreeing.
--
-- ponytail: the friends clause is a correlated exists per grouped user. It
-- is two indexed lookups on a two-column table; make it a join against a
-- materialised mutual-follow set if the board gets slow.
create or replace function public.leaderboard_in_scope(
  p_scope text,
  p_viewer uuid,
  p_user uuid,
  p_country char(2)
) returns boolean
language sql
stable
as $$
  select case
    when p_scope = 'global' then true
    when p_scope = 'friends' then
      p_viewer is not null and (
        p_user = p_viewer
        or exists (
          select 1
          from follows outbound
          join follows inbound
            on inbound.follower_id = outbound.followee_id
           and inbound.followee_id = outbound.follower_id
          where outbound.follower_id = p_viewer
            and outbound.followee_id = p_user
        )
      )
    else p_country = p_scope
  end;
$$;

-- One user's score over one window. The duel settler's whole read.
create or replace function public.activity_total(
  p_user uuid,
  p_metric text,
  p_start timestamptz,
  p_end timestamptz
) returns double precision
language sql
stable
as $$
  select coalesce(
    case p_metric
      when 'vertical' then sum(a.elevation_gain_meters)
      when 'distance' then sum(a.distance_meters)
      when 'speed'    then 3600.0 / nullif(min(nullif(a.max_pace, 0)), 0)
    end,
    0
  )
  from activities a
  where a.user_id = p_user
    and a.start_time >= p_start
    and a.start_time <  p_end;
$$;

-- The board. `p_scope` is 'global' or an ISO-2 country code.
--
-- Note this reads `on_leaderboard`, which activity_total deliberately does
-- not: a duel counts everything you skied, a board counts only what you
-- chose to publish.
create or replace function public.leaderboard_top(
  p_metric text,
  p_scope text,
  p_start timestamptz,
  p_end timestamptz,
  p_limit int default 50,
  p_viewer uuid default null
) returns table (rank int, user_id uuid, value double precision)
language sql
stable
as $$
  select
    row_number() over (order by t.value desc, t.user_id)::int as rank,
    t.user_id,
    t.value
  from (
    select
      a.user_id,
      case p_metric
        when 'vertical' then sum(a.elevation_gain_meters)
        when 'distance' then sum(a.distance_meters)
        when 'speed'    then 3600.0 / nullif(min(nullif(a.max_pace, 0)), 0)
      end as value
    from activities a
    left join profiles p on p.id = a.user_id
    where a.on_leaderboard
      and a.start_time >= p_start
      and a.start_time <  p_end
      and public.leaderboard_in_scope(
            p_scope, p_viewer, a.user_id, p.country_code
          )
    group by a.user_id
  ) t
  -- A null value means the metric had nothing to read; a zero means the
  -- user opted in and recorded nothing. Neither is a placing.
  where t.value is not null and t.value > 0
  order by t.value desc, t.user_id
  limit least(p_limit, 100);
$$;

-- Where one user placed, whether or not they are on the page the client
-- fetched. Someone ranked 8,000th still has to see their own position, and
-- paging to find it is not an option.
create or replace function public.leaderboard_placing(
  p_user uuid,
  p_metric text,
  p_scope text,
  p_start timestamptz,
  p_end timestamptz,
  p_viewer uuid default null
) returns table (rank int, value double precision)
language sql
stable
as $$
  with totals as (
    select
      a.user_id,
      case p_metric
        when 'vertical' then sum(a.elevation_gain_meters)
        when 'distance' then sum(a.distance_meters)
        when 'speed'    then 3600.0 / nullif(min(nullif(a.max_pace, 0)), 0)
      end as value
    from activities a
    left join profiles p on p.id = a.user_id
    where a.on_leaderboard
      and a.start_time >= p_start
      and a.start_time <  p_end
      and public.leaderboard_in_scope(
            p_scope, p_viewer, a.user_id, p.country_code
          )
    group by a.user_id
  ),
  ranked as (
    select
      user_id,
      value,
      row_number() over (order by value desc, user_id)::int as rank
    from totals
    where value is not null and value > 0
  )
  select ranked.rank, ranked.value
  from ranked
  where ranked.user_id = p_user;
$$;

-- Which country boards actually exist for a window. The weekly settlement
-- writes one snapshot per metric per scope, and without this it would have
-- to guess -- either at a hardcoded country list or by reading every
-- profile row.
create or replace function public.leaderboard_scopes(
  p_start timestamptz,
  p_end timestamptz
) returns table (scope text)
language sql
stable
as $$
  select distinct p.country_code::text
  from activities a
  join profiles p on p.id = a.user_id
  where a.on_leaderboard
    and a.start_time >= p_start
    and a.start_time <  p_end
    and p.country_code is not null;
$$;

commit;
