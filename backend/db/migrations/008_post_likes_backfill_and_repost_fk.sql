-- Run this in the Supabase SQL editor BEFORE deploying the release that moves
-- likes onto post_likes. Both halves are safe against the code that is live
-- right now, so there is no window where either is a problem.
--
-- Background: likes had two implementations. post_likes (8 rows, last written
-- 2026-01-29) came first, and it maintained posts.like_count. post_votes came
-- later and the current code counts its vote_value > 0 rows as likes. All 17
-- of those votes are +1 -- no downvote has ever been cast, and the app only
-- ever sends 1 or 0 -- so the vote model was never used as one. post_likes is
-- also the sounder table: uuid user_id, foreign keys to both parents,
-- created_at, and a unique constraint on the pair.

begin;

-- 1. Carry the votes over as likes. The unique constraint makes the one pair
--    that already exists in both a no-op.
--
--    One vote is left behind on purpose: it belongs to a user that no longer
--    exists, and post_likes has a foreign key to user_info. That is the
--    constraint doing its job -- post_votes accepted the row because its
--    user_id is text with nothing to check it against.
insert into post_likes (post_id, user_id)
select v.post_id, v.user_id::uuid
from post_votes v
where v.vote_value > 0
  and exists (select 1 from user_info u where u.id::text = v.user_id)
on conflict (post_id, user_id) do nothing;

-- 2. post_reposts has the same defect post_votes has: user_id is text, so it
--    cannot reference user_info and nothing has ever checked it. Its three
--    rows are all valid uuids belonging to users that exist, so the conversion
--    is clean. Reposting is unaffected -- the client sends a uuid string
--    either way and Postgres casts it on write.
alter table post_reposts alter column user_id type uuid using user_id::uuid;

alter table post_reposts drop constraint if exists post_reposts_user_id_fkey;
alter table post_reposts add  constraint post_reposts_user_id_fkey
  foreign key (user_id) references user_info(id) on delete cascade;

commit;

-- Verify: the like count per post should now match what the feed shows.
--   select p.post_id, p.like_count as stale_column,
--          (select count(*) from post_likes l where l.post_id = p.post_id) as likes
--   from posts p where p.like_count > 0
--      or exists (select 1 from post_likes l where l.post_id = p.post_id);
--
-- Afterwards: python scripts/dump_supabase_schema.py, and commit the result.
