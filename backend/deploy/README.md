# VPS Deployment Blueprint

This folder contains the backend-side pieces of the VPS setup.

If you want the full walkthrough, start with [docs/vps_setup.md](../../docs/vps_setup.md).

What lives here:

- `docker-compose.staging.yml` for the beta/staging backend stack
- `docker-compose.production.yml` for the live backend stack
- `Caddyfile.example` for the reverse proxy layout
- `env/*.env.example` for VPS secret templates

Short version:

- DigitalOcean Ubuntu LTS droplet
- Docker Compose on the VPS
- Caddy on the host for HTTPS and routing
- Managed Supabase/Postgres for the database
- Manual GitHub Actions deploys at first

Environment mapping:

- `develop` -> staging backend
- `main` or release tags -> production backend

Service layout:

- Staging runs `main-backend`, `community-backend`, and `activity-backend`
- Production runs all four services, including `map-backend`
- Staging keeps map features disabled in the Flutter app