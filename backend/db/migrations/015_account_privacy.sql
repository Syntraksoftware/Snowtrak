-- Run this in the Supabase SQL editor BEFORE deploying the release that
-- reads it. Additive with a default that matches how every existing
-- account already behaves, so no backfill and no behaviour change.
--
-- On user_info, not profiles. Most users have no profiles row at all --
-- that is why users_profile_routes.py carries a user_info fallback -- and
-- a privacy flag that is absent for some users is not a privacy flag.

begin;

alter table user_info
  add column if not exists is_private boolean not null default false;

commit;

-- Verify: every existing account is public.
--   select is_private, count(*) from user_info group by is_private;
