-- Run this in the Supabase SQL editor after 020. Corrects which table the
-- competition surfaces read.
--
-- 019 and 020 hung the country column and every display join off `profiles`.
-- That table is empty and always will be: `profiles.id` carries a foreign key
-- to Supabase auth's `users`, registration writes `user_info`, so every insert
-- in main-backend's create_profile fails with 23503 and the row is never made.
-- main-backend already works around this by rendering a profile from
-- `user_info` at read time (see _profile_from_user_info in
-- app/api/v1/users_profile_routes.py).
--
-- So the board and the duel cards read `user_info`, which is what
-- `activities.user_id` references and is therefore always present.
--
-- `profiles.country_code` from 019 is left in place rather than dropped. It
-- is unread and on an empty table; a drop buys nothing and the profiles
-- repair tracked in issue #43 may want it back. Nothing should write to it.

begin;

-- ISO 3166-1 alpha-2, chosen by the user. Null means they have not picked one
-- and appear on the global board only.
alter table user_info
  add column if not exists country_code char(2);

create index if not exists user_info_country_idx
  on user_info (country_code)
  where country_code is not null;

-- Same predicate as 020, unchanged. Restated only because the callers below
-- are being replaced and they must all agree on who is on a board.
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
    join user_info u on u.id = a.user_id
    where a.on_leaderboard
      and a.start_time >= p_start
      and a.start_time <  p_end
      and public.leaderboard_in_scope(p_scope, p_viewer, a.user_id, u.country_code)
    group by a.user_id
  ) t
  where t.value is not null and t.value > 0
  order by t.value desc, t.user_id
  limit least(p_limit, 100);
$$;

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
    join user_info u on u.id = a.user_id
    where a.on_leaderboard
      and a.start_time >= p_start
      and a.start_time <  p_end
      and public.leaderboard_in_scope(p_scope, p_viewer, a.user_id, u.country_code)
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

create or replace function public.leaderboard_scopes(
  p_start timestamptz,
  p_end timestamptz
) returns table (scope text)
language sql
stable
as $$
  select distinct u.country_code::text
  from activities a
  join user_info u on u.id = a.user_id
  where a.on_leaderboard
    and a.start_time >= p_start
    and a.start_time <  p_end
    and u.country_code is not null;
$$;

commit;
