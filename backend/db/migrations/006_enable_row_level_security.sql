-- Run this in the Supabase SQL editor (or via psql against the Supabase Postgres).
--
-- Six tables have RLS on with no policies; fifteen have it off entirely. The
-- inconsistency is the problem, not either state: a table with RLS off is
-- readable and writable by anyone holding the project's anon key, which is
-- designed to be public.
--
-- Nothing in this repository uses that key -- the Flutter app never talks to
-- Supabase directly, and all four backends authenticate with the service role.
-- So this is not an open door today. It is the lock on a door nobody currently
-- knocks on, and it costs nothing: service_role bypasses RLS, and a table's
-- owner is exempt unless FORCE ROW LEVEL SECURITY is set. No policies are
-- added, so the default for every other role is deny.
--
-- If the app ever does talk to Supabase directly with the anon key, this file
-- is where the policies go, and they must be written before that happens.
--
-- spatial_ref_sys is left alone: it belongs to the PostGIS extension.

begin;

alter table activities        enable row level security;
alter table activity_locations enable row level security;
alter table comments          enable row level security;
alter table posts             enable row level security;
alter table post_reposts      enable row level security;
alter table post_votes        enable row level security;
alter table profiles          enable row level security;
alter table subthreads        enable row level security;
alter table user_stats        enable row level security;

-- Alembic owns these three. Included anyway so the rule is "every table in
-- public has RLS", with no exceptions to remember.
alter table alembic_version   enable row level security;
alter table map_cache_entries enable row level security;
alter table elevation_samples enable row level security;

commit;

-- Verify: every row should read true.
--   select relname, relrowsecurity from pg_class c
--   join pg_namespace n on n.oid = c.relnamespace
--   where n.nspname = 'public' and c.relkind = 'r' and relname <> 'spatial_ref_sys'
--   order by relrowsecurity, relname;
