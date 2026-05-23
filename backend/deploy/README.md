# VPS Deployment Blueprint

This directory contains the VPS deployment shape for Syntrak's backend.

Recommended target:

- DigitalOcean Ubuntu LTS droplet
- Docker + Docker Compose plugin
- Caddy as the reverse proxy
- GitHub Actions manual deploys at first, then branch/tag automation later

## Environment mapping

- `develop` -> staging backend
- `main` or release tags -> production backend

## Service layout

- Staging runs `main-backend`, `community-backend`, and `activity-backend`
- Production runs all four services, including `map-backend`
- Staging should keep map features disabled in the Flutter app

## One-time VPS setup

1. Create a non-root deploy user.
2. Install Docker, Docker Compose plugin, and Caddy.
3. Open only `22`, `80`, and `443` in the firewall.
4. Clone this repository onto the VPS, for example under `/srv/syntrak-application`.
5. Create `backend/deploy/env/staging.env` and `backend/deploy/env/production.env` on the VPS with the real secrets.
6. Copy `backend/deploy/Caddyfile.example` to the live Caddy config and replace the placeholder domains.

## Manual deploy commands

From the repository root on the VPS:

```bash
docker compose -f backend/deploy/docker-compose.staging.yml up -d --build
docker compose -f backend/deploy/docker-compose.production.yml up -d --build
```

## GitHub Actions deploy flow

The manual deploy workflow in `.github/workflows/deploy-backend-vps.yml` connects to the VPS over SSH and runs the correct compose file for the selected environment.

Secrets required in GitHub:

- `VPS_HOST`
- `VPS_USER`
- `VPS_SSH_KEY`
- `VPS_APP_DIR`

The repo is already split so the frontend `staging` lane can point at staging backend URLs while the production lane uses the live services.