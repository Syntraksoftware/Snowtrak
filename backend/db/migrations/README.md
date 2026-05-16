Alembic revision scripts for PostGIS (`map_trail` schema and public cache tables). Metadata comes from `map-backend/orm/` (`env.py` prepends `map-backend/` on `sys.path`).

## Supabase (default)

Use the **same Supabase project** as the rest of the app so `map_trail.*` lives next to your existing tables (names are isolated under schema `map_trail`).

1. **Enable PostGIS**  
   Supabase Dashboard → **SQL Editor** → run:
   ```sql
   CREATE EXTENSION IF NOT EXISTS postgis;
   ```

2. **Connection string**  
   Dashboard → your project → **Connect** (or **Settings → Database**).  
   - **Direct** (`db.<project-ref>.supabase.co:5432`) is ideal for DDL when your network can reach it.  
   - If you see **`No route to host`** to an **IPv6** address (e.g. `2406:…`), your network likely has no working IPv6 to Supabase. Use the **pooler** string instead — in the Connect UI choose **Session mode** (IPv4-friendly). User is often `postgres.<project-ref>` and host looks like `aws-0-<region>.pooler.supabase.com` (copy exactly what Supabase shows).  
   - **Transaction** pooler (**port 6543**) can break some migration patterns; **Session mode** is safer for `alembic upgrade`.

3. **Format for Alembic (psycopg3)**  
   Use the `postgresql+psycopg://` scheme (not `postgres://` alone). Example shape:
   ```bash
   export SYNTRAK_DATABASE_URL="postgresql+psycopg://postgres:YOUR_DB_PASSWORD@db.YOUR_PROJECT_REF.supabase.co:5432/postgres?sslmode=require"
   ```
   If the password contains `@`, `#`, or other reserved characters, **URL-encode** it.

4. **Run migrations** (from `backend/`):
   ```bash
   alembic upgrade head
   ```

5. **map-backend + OpenSkiMap sync**  
   Set the same value as **`SYNTRAK_DATABASE_URL`** in `map-backend/.env` (or the process environment) so `create_pool()` and scheduled sync use Supabase Postgres.

## Optional: local Docker PostGIS

For offline-only work, use `docker compose --profile postgis` and `postgres.env` from `postgres.env.example`. Then either set `SYNTRAK_DATABASE_URL` to that instance or rely on the fallback `sqlalchemy.url` in `backend/alembic.ini` (see comments there).

## Troubleshooting: `FATAL: role "syntrak" does not exist`

You ran Alembic **without** `SYNTRAK_DATABASE_URL`, so Alembic used **`backend/alembic.ini`** → default user **`syntrak`** on **`127.0.0.1:5432`**. That user only exists in the **Docker PostGIS** profile, not on a stock Mac Postgres.

**Fix:** export `SYNTRAK_DATABASE_URL` to your **Supabase** URI (above), then `alembic upgrade head` again.

## Troubleshooting: IPv6 / `No route to host` (direct `db.*.supabase.co`)

Postgres resolved `db.<ref>.supabase.co` to **IPv6** and your Mac/network cannot route to it.

**Fix:** In Supabase **Connect**, switch from **Direct connection** to **Session pooler** (session mode), copy the URI, convert to `postgresql+psycopg://`, add `?sslmode=require` if missing, set `SYNTRAK_DATABASE_URL`, run `alembic upgrade head` again. Use the **same** pooler URL for `map-backend` / asyncpg if direct fails there too.

**Optional:** Fix IPv6 on your LAN/VPN, or use another network — then direct connection may work.
