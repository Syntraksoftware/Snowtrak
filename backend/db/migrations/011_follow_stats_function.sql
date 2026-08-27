-- Run this in the Supabase SQL editor. It only adds a function; nothing that
-- is live reads it until the release that calls it ships, and older code is
-- unaffected either way.
--
-- Why a database function rather than four queries from Python:
--
-- The database is in ap-south-1 and the app is not. One round trip measures
-- ~440ms of pure distance, so the four obvious queries -- follower count,
-- following count, and the two edge checks -- cost about a second before
-- Postgres does any work at all. They are four trivial index lookups; the
-- travel is the whole bill.
--
-- Counting in Python after one wide `select` would also be one round trip,
-- but it has to cap the rows it pulls, and past that cap the counts are
-- silently wrong. This keeps the counts exact and still costs one trip.

begin;

create or replace function public.follow_stats(target uuid, viewer uuid)
returns json
language sql
stable
as $$
  select json_build_object(
    'follower_count',
      (select count(*) from follows where followee_id = target),
    'following_count',
      (select count(*) from follows where follower_id = target),
    'is_following',
      (viewer is not null and exists (
        select 1 from follows where follower_id = viewer and followee_id = target
      )),
    'is_followed_by',
      (viewer is not null and exists (
        select 1 from follows where follower_id = target and followee_id = viewer
      ))
  );
$$;

commit;

-- Verify (any two user_info ids, or nulls):
--   select public.follow_stats(
--     (select id from user_info limit 1),
--     null
--   );
