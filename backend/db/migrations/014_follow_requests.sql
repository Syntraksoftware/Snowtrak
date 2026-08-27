-- Run this in the Supabase SQL editor BEFORE deploying the release that
-- reads it. Additive: a new table nothing yet queries.
--
-- Pending follows live here rather than as a status column on `follows`,
-- so that `follows` keeps meaning exactly one thing: an accepted edge.
-- Five read paths already ship against that table. A status column would
-- need every one of them, forever, to remember `status = 'accepted'` --
-- and forgetting it fails open, handing a pending stranger somebody's
-- followers-only posts. A separate table deletes the failure mode rather
-- than guarding it, and leaves follow_counts and its trigger untouched.

begin;

create table if not exists follow_requests (
  requester_id uuid not null references user_info(id) on delete cascade,
  target_id    uuid not null references user_info(id) on delete cascade,
  created_at   timestamptz not null default now(),
  primary key (requester_id, target_id),
  check (requester_id <> target_id)
);

-- The one list query: "my incoming requests, newest first".
create index if not exists follow_requests_target_idx
  on follow_requests (target_id, created_at desc);

alter table follow_requests enable row level security;

commit;

-- Verify:
--   insert into follow_requests (requester_id, target_id)
--     select id, id from user_info limit 1;
--     -- expected: violates check constraint "follow_requests_check"
