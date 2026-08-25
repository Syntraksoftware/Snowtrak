-- Run this in the Supabase SQL editor (or via psql against the Supabase Postgres).
--
-- activity_comments, activity_kudos and activity_shares all reference
-- activities without a foreign key, and their activity_id carries
-- `DEFAULT gen_random_uuid()` -- copied, by the look of it, from the id column
-- beside it. Two consequences:
--
--   * an insert that omits activity_id succeeds, attaching the row to a random
--     activity that does not exist, and nothing complains;
--   * deleting an activity leaves its comments, kudos and shares behind, since
--     no code deletes them and no constraint cascades.
--
-- At the time of writing each of those three tables held exactly one row, and
-- all three rows were orphans. activity_locations, the one sibling that does
-- have the foreign key, held none.
--
-- Safe for the code that is deployed: every insert in
-- activity-backend/services/supabase_client.py supplies activity_id, so the
-- constraint only rejects what was already wrong, and the dropped default was
-- never being relied on.

begin;

-- 1. What is about to be deleted. Run this first and look at it: the rows are
--    unreachable in the app (their activity is gone), but they are still rows.
select 'activity_comments' as table_name, id, activity_id from activity_comments
  where activity_id not in (select id from activities)
union all
select 'activity_kudos', id, activity_id from activity_kudos
  where activity_id not in (select id from activities)
union all
select 'activity_shares', id, activity_id from activity_shares
  where activity_id not in (select id from activities);

-- 2. The constraint cannot be added while they exist.
delete from activity_comments where activity_id not in (select id from activities);
delete from activity_kudos     where activity_id not in (select id from activities);
delete from activity_shares    where activity_id not in (select id from activities);

-- 3. A foreign key is not a default. Dropping these is idempotent.
alter table activity_comments alter column activity_id drop default;
alter table activity_kudos     alter column activity_id drop default;
alter table activity_shares    alter column activity_id drop default;

-- user_id on these two carries the same stray default. It has a foreign key,
-- so a random value errors rather than corrupting -- still not a default.
alter table activity_kudos  alter column user_id drop default;
alter table activity_shares alter column user_id drop default;

-- 4. Cascade, because nothing in the code deletes these rows when an activity
--    goes. That is how the orphans above were made.
alter table activity_comments drop constraint if exists activity_comments_activity_id_fkey;
alter table activity_comments add  constraint activity_comments_activity_id_fkey
  foreign key (activity_id) references activities(id) on delete cascade;

alter table activity_kudos drop constraint if exists activity_kudos_activity_id_fkey;
alter table activity_kudos add  constraint activity_kudos_activity_id_fkey
  foreign key (activity_id) references activities(id) on delete cascade;

alter table activity_shares drop constraint if exists activity_shares_activity_id_fkey;
alter table activity_shares add  constraint activity_shares_activity_id_fkey
  foreign key (activity_id) references activities(id) on delete cascade;

commit;

-- Afterwards: python scripts/dump_supabase_schema.py, and commit the result.
