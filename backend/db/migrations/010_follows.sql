-- Run this in the Supabase SQL editor BEFORE deploying the release that adds
-- the follow endpoints. Nothing that is live today reads or writes this table,
-- so applying it early is safe and rolling the code back afterwards is too.
--
-- Design notes, so the next person does not have to re-derive them:
--
--   * The composite primary key is both the uniqueness constraint (you cannot
--     follow someone twice) and the index for "who do I follow". The separate
--     index covers the other direction, "who follows me".
--
--   * No follower_count / following_count columns. posts.like_count is the
--     cautionary tale -- it is already out of step with post_likes. count(*)
--     is correct and cheap at this size. Add the columns when a count shows up
--     in a slow query log, not before.
--
--   * on delete cascade on both sides. This is what post_likes does, and it is
--     why post_likes never collected the orphan rows post_votes did (see
--     008_post_likes_backfill_and_repost_fk.sql).
--
--   * RLS on with no policies, matching 006_enable_row_level_security.sql:
--     service_role bypasses it and everything else is denied by default.

begin;

create table if not exists follows (
  follower_id uuid not null references user_info(id) on delete cascade,
  followee_id uuid not null references user_info(id) on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (follower_id, followee_id),
  constraint follows_no_self check (follower_id <> followee_id)
);

create index if not exists follows_followee_idx on follows (followee_id);

alter table follows enable row level security;

commit;

-- Verify:
--   select count(*) from follows;                        -- 0
--   select relrowsecurity from pg_class where relname = 'follows';  -- true
--
-- Afterwards: python scripts/dump_supabase_schema.py, and commit the result.
