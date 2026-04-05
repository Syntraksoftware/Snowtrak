-- Superseded by Alembic: `backend/db/migrations/versions/001_initial_postgis_and_map_trail.py`
--
-- Pipeline tables now live in schema `map_trail` to avoid clashing with `public.activities`
-- (e.g. Supabase). Apply migrations from repo root:
--   cd backend && SYNTRAK_DATABASE_URL=postgresql+psycopg://... alembic upgrade head
--
-- Historical DDL (public schema) is below for reference only — do not run on production
-- if Alembic has already been applied.

/*
CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TABLE IF NOT EXISTS ski_runs (...);
...
*/
