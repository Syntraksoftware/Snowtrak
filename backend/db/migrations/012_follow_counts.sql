-- Run this in the Supabase SQL editor. Additive: it adds a table, a trigger,
-- and redefines follow_stats to read the stored numbers. Code that predates
-- it is unaffected, and the trigger keeps the table correct from the moment
-- it exists.
--
-- Stored counts, the way Instagram and Strava show them.
--
-- Be clear about what this buys, because it is not latency today: the profile
-- read costs one round trip to ap-south-1 either way, and count(*) over an
-- indexed column with a handful of rows is microseconds. This pays off when a
-- screen draws many people at once -- a followers list, search results,
-- suggestions -- where per-row counting turns into an N+1, and at the scale
-- where count(*) genuinely stops being free.
--
-- The counts are maintained by a trigger, not by application code. This
-- matters: posts.like_count is maintained by application code and has already
-- drifted away from post_likes (see 008_post_likes_backfill_and_repost_fk.sql).
-- A trigger cannot be bypassed by a second writer, a migration, or a psql
-- session, so the number cannot silently stop being true.

begin;

create table if not exists follow_counts (
  user_id         uuid primary key references user_info(id) on delete cascade,
  follower_count  integer not null default 0 check (follower_count >= 0),
  following_count integer not null default 0 check (following_count >= 0)
);

alter table follow_counts enable row level security;

create or replace function public.apply_follow_counts()
returns trigger
language plpgsql
as $$
begin
  if tg_op = 'INSERT' then
    insert into follow_counts (user_id, follower_count) values (new.followee_id, 1)
      on conflict (user_id) do update
      set follower_count = follow_counts.follower_count + 1;

    insert into follow_counts (user_id, following_count) values (new.follower_id, 1)
      on conflict (user_id) do update
      set following_count = follow_counts.following_count + 1;

  elsif tg_op = 'DELETE' then
    -- greatest(): the check constraint would otherwise turn a double-delete
    -- race into a failed transaction on the follows table itself.
    update follow_counts set follower_count = greatest(follower_count - 1, 0)
      where user_id = old.followee_id;

    update follow_counts set following_count = greatest(following_count - 1, 0)
      where user_id = old.follower_id;
  end if;

  return null;
end;
$$;

drop trigger if exists follows_apply_counts on follows;
create trigger follows_apply_counts
  after insert or delete on follows
  for each row execute function public.apply_follow_counts();

-- Backfill. Only users who actually have edges get a row; follow_stats
-- coalesces a missing row to zero, and the trigger creates one on first use.
insert into follow_counts (user_id, follower_count, following_count)
select u.id,
       (select count(*) from follows f where f.followee_id = u.id),
       (select count(*) from follows f where f.follower_id = u.id)
from user_info u
where exists (select 1 from follows f where f.followee_id = u.id or f.follower_id = u.id)
on conflict (user_id) do update
  set follower_count  = excluded.follower_count,
      following_count = excluded.following_count;

-- Same signature as 011, now reading the stored numbers. Still one round trip.
create or replace function public.follow_stats(target uuid, viewer uuid)
returns json
language sql
stable
as $$
  select json_build_object(
    'follower_count',
      coalesce((select follower_count from follow_counts where user_id = target), 0),
    'following_count',
      coalesce((select following_count from follow_counts where user_id = target), 0),
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

-- Drift check. This should always return no rows; if it ever does not, the
-- trigger was bypassed and the backfill above is also the repair.
--
--   select c.user_id, c.follower_count, c.following_count,
--          (select count(*) from follows f where f.followee_id = c.user_id) as real_followers,
--          (select count(*) from follows f where f.follower_id = c.user_id) as real_following
--   from follow_counts c
--   where c.follower_count  <> (select count(*) from follows f where f.followee_id = c.user_id)
--      or c.following_count <> (select count(*) from follows f where f.follower_id = c.user_id);
