-- Run this in the Supabase SQL editor BEFORE deploying the release that reads
-- the column. Additive with a default, so every existing post keeps the
-- behaviour it has today and code that predates this is unaffected.
--
-- The three words are the ones activities already declares in
-- backend/activity-backend/models.py: private | followers | public. That file
-- has never written 'followers' -- the route maps a boolean is_public, and the
-- read check is `visibility == 'public' or owner` -- so the tier is declared
-- there and not honoured. Posts using the same vocabulary means the app has
-- one privacy language rather than two, and leaves that tier ready to wire up.
--
-- 'public' is the default on purpose. A post whose author never made a choice
-- is a post they expected everyone to see, which is what they got before this
-- column existed.

begin;

alter table posts
  add column if not exists visibility text not null default 'public';

alter table posts
  drop constraint if exists posts_visibility_check;

alter table posts
  add constraint posts_visibility_check
  check (visibility in ('public', 'followers', 'private'));

-- The feed filters on this column on every read, alongside user_id.
create index if not exists posts_visibility_user_idx on posts (visibility, user_id);

commit;

-- Verify: every existing row is public, and nothing else can be written.
--   select visibility, count(*) from posts group by visibility;
--   insert into posts (user_id, subthread_id, title, content, visibility)
--     values (gen_random_uuid(), gen_random_uuid(), 'x', 'x', 'nonsense');
--     -- expected: violates check constraint "posts_visibility_check"
--
-- Afterwards: python scripts/dump_supabase_schema.py, and commit the result.
