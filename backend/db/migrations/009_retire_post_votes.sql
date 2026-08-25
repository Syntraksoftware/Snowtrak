-- Run this AFTER the release that reads and writes post_likes is deployed and
-- healthy -- not in the same step as 008.
--
-- This is the contract half of an expand-contract change. 008 put the data in
-- both places; the release in between moved the code; this removes what is no
-- longer read. Run it too early and the deployed code loses its likes table.

begin;

-- post_votes is superseded by post_likes. Its rows were carried over in 008,
-- except one belonging to a deleted user.
drop table if exists post_votes;

-- Denormalised counters that nothing maintains. community_post_read_operations
-- computes both from the child tables and overwrites these values in the
-- response, so they have been dead data rather than a cache: 8 posts carry
-- like_count = 1 from the post_likes era, and 12 carry a repost_count against
-- 3 actual reposts. Reading a stale number is worse than reading none.
alter table posts drop column if exists like_count;
alter table posts drop column if exists repost_count;

commit;

-- Afterwards: python scripts/dump_supabase_schema.py, and commit the result.
