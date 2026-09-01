-- Run this in the Supabase SQL editor AFTER the pre-flight in
-- docs/superpowers/plans/2026-08-27-account-privacy.md passes. This is the
-- only irreversible step in that plan.
--
-- Three things activities never got and posts did: a real default, a check
-- constraint, and an index the visibility filter can use.
--
-- The default is 'private' where posts defaults to 'public'. That
-- asymmetry is deliberate. A post is written for an audience; a GPS track
-- starts at somebody's front door. The application already agrees --
-- ActivityCreate defaults to "private" and activities_upload_routes.py
-- writes "private" -- the column simply never carried the same default.
--
-- is_public is dropped because two services disagreed about it. The API's
-- is_public is derived from visibility at
-- routes/activity_transformers.py:175 and is unaffected by this; the
-- column is a different thing wearing the same name.
--
-- activity-backend has never written the column, so it kept its `not null
-- default true` on every row -- including the one activity stored
-- visibility = 'private', which reads is_public = true to this day.
--
-- main-backend meanwhile had a whole unmounted activities implementation
-- that did write it, filter on it, and use it for access control. That was
-- deleted first; see docs/service-ownership.md, "Migration Decision".
--
-- One table, one privacy column. Left in place, somebody believes the
-- wrong one.
--
-- Dropping is_public also drops idx_activities_is_public, the one index
-- built on it. Postgres removes a column's indexes automatically -- no
-- separate `drop index` here, and no cause for alarm when it disappears.

begin;

alter table activities alter column visibility set default 'private';

alter table activities drop constraint if exists activities_visibility_check;
alter table activities add constraint activities_visibility_check
  check (visibility in ('public', 'followers', 'private'));

create index if not exists activities_visibility_user_idx
  on activities (visibility, user_id);

alter table activities drop column if exists is_public;

commit;

-- Verify:
--   select visibility, count(*) from activities group by visibility;
--   select column_name from information_schema.columns
--     where table_name = 'activities' and column_name = 'is_public';
--     -- expected: no rows
