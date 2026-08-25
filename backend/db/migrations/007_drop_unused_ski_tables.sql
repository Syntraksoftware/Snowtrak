-- Run this in the Supabase SQL editor (or via psql against the Supabase Postgres).
--
-- public.ski_resorts and public.ski_trails are empty, referenced by no code in
-- backend/ or frontend/, absent from git history, and created by no migration
-- in this repository -- someone made them in the dashboard and nothing ever
-- used them. The map pipeline uses the map_trail schema that Alembic owns
-- (map_trail.ski_runs, map_trail.ski_lifts).
--
-- The expand-contract rule in docs/database_changes.md says code stops using a
-- thing one release before the database drops it. That gap is already served
-- here: no release ever used them, so there is no version to roll back to that
-- would miss them.
--
-- Confirm before running. Both counts must be zero:
--   select 'ski_resorts' as t, count(*) from ski_resorts
--   union all select 'ski_trails', count(*) from ski_trails;

begin;

drop table if exists ski_trails;
drop table if exists ski_resorts;

commit;
