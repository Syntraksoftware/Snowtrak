# VPS Setup Guide

This guide walks through the recommended lean VPS deployment for Snowtrak backend services.

The target architecture is:

Local machine or Git push -> GitHub Actions -> DigitalOcean VPS -> Caddy reverse proxy -> Docker Compose stacks

Staging and production share one VPS, but they must remain isolated:

- Staging uses its own Compose file and backend secrets
- Production uses a separate Compose file and separate secrets
- The Flutter staging lane disables map features so beta testing stays focused on threads, auth, and activity flows

## 1. What to use

Recommended stack:

- DigitalOcean Ubuntu LTS droplet
- Docker Engine + Docker Compose plugin
- Caddy as the reverse proxy
- GitHub Actions for manual deploys first
- Managed Supabase/Postgres for data storage

Why this setup:

- One clean VPS instead of ad hoc server management
- Repeatable deploys
- Automatic HTTPS through Caddy
- Clear staging and production separation

## 2. Domains to prepare

Create DNS records for the following hostnames:

- `staging-main.example.com`
- `staging-community.example.com`
- `staging-activity.example.com`
- `main.example.com`
- `community.example.com`
- `activity.example.com`
- `map.example.com`

Point each record at the VPS public IP.

## 3. One-time VPS setup

SSH into the droplet once as root or the provider default user, then create a non-root deploy user.

### Install Docker and Caddy

On Ubuntu LTS:

```bash
sudo apt update
sudo apt install -y ca-certificates curl gnupg
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker

sudo apt install -y caddy
```

### Create a deploy user

```bash
sudo adduser deploy
sudo usermod -aG docker deploy
```

Log out and back in as `deploy` so the Docker group membership applies.

### Open the firewall

Allow only SSH, HTTP, and HTTPS:

```bash
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

## 4. Clone the repository on the VPS

Use a stable location such as `/srv/syntrak-application`:

```bash
sudo mkdir -p /srv
sudo chown deploy:deploy /srv
cd /srv
# The repo is now Snowtrak; clone into the existing deploy directory name.
git clone https://github.com/Syntraksoftware/Snowtrak.git syntrak-application
cd syntrak-application
```

## 5. Create VPS env files

Each backend reads its own env file. They are not merged into one file per
environment: `POSTGRES_SCHEMA` alone differs per service, so a shared file
would point three services at one schema. See `backend/deploy/README.md`.

```bash
for svc in main community activity map; do
  cp "backend/${svc}-backend/.env.example" "backend/${svc}-backend/.env"
  chmod 600 "backend/${svc}-backend/.env"
done
```

Staging and production separate by checkout directory, not by filename -- each
has its own clone with its own set of these files.

Populate:

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `SECRET_KEY` or `JWT_SECRET`
- `ALLOWED_ORIGINS`
- `SYNTRAK_DATABASE_URL` for production
- `GOOGLE_MAPS_API_KEY` for map service usage in production

Keep secrets out of git. These files should live only on the VPS.

## 6. Configure Caddy

Copy the example Caddyfile and replace the placeholder domains.

```bash
sudo cp backend/deploy/Caddyfile.example /etc/caddy/Caddyfile
sudo caddy validate --config /etc/caddy/Caddyfile
sudo systemctl reload caddy
```

Caddy handles HTTPS automatically. You do not need Certbot.

## 7. Compose layout

The repo already contains:

- `backend/deploy/docker-compose.staging.yml`
- `backend/deploy/docker-compose.production.yml`

Both stacks bind their service ports to `127.0.0.1` only, so Caddy is the public entrypoint.

Staging stack:

- `main-backend` on local port `15080`
- `community-backend` on local port `15001`
- `activity-backend` on local port `15100`

Production stack:

- `main-backend` on local port `8080`
- `community-backend` on local port `5001`
- `activity-backend` on local port `5100`
- `map-backend` on local port `5200`

## 8. First deploy

Deploys run through **Actions -> Deploy Backend to VPS -> Run workflow**. Pick
the environment and give it a release tag (`v1.2.3`); staging also accepts a
40-character commit SHA.

The workflow resolves each service to a published image digest and the box
pulls it. **Nothing is built on the VPS.** The image CI scanned with Trivy is
the image that runs, which is not true of a hand-run `docker compose`.

Production pauses for a required reviewer before it touches the live stack.

Check status. `-p` is required: neither Compose file sets a `name:`, so Compose
would otherwise derive the project from the checkout directory and two stacks
run from one checkout would collide. These names match
`.github/workflows/deploy-backend-vps.yml` and `backend/deploy/Caddyfile.example`.

```bash
docker compose -f backend/deploy/docker-compose.staging.yml -p snowtrak-staging ps
docker compose -f backend/deploy/docker-compose.production.yml -p snowtrak-prod ps
```

Health checks:

```bash
# staging
curl http://127.0.0.1:15080/health
curl http://127.0.0.1:15001/health
curl http://127.0.0.1:15100/health

# production
curl http://127.0.0.1:8080/health
curl http://127.0.0.1:5001/health
curl http://127.0.0.1:5100/health
curl http://127.0.0.1:5200/health
```

## 9. GitHub Actions deploy workflow

The workflow at [.github/workflows/deploy-backend-vps.yml](../.github/workflows/deploy-backend-vps.yml) is manual-first.

It expects these GitHub secrets:

- `VPS_HOST`
- `VPS_USER`
- `VPS_SSH_KEY`
- `VPS_APP_DIR`

How it works:

- You trigger it manually from the GitHub Actions UI.
- It SSHes into the VPS.
- It checks out `develop` for staging or `main` for production.
- It runs the matching Compose file.

Later, you can automate it by branch or tag if you want, but manual-first is the safer start.

## 10. Frontend alignment

The Flutter app already has lane-specific entrypoints:

- `lib/main_dev.dart`
- `lib/main_staging.dart`
- `lib/main_prod.dart`

The staging lane disables map features, so it can safely point at the staging backend while map work is still unstable.

## 11. Operational rules

- Never expose backend container ports directly to the internet.
- Let Caddy terminate TLS and route traffic.
- Keep staging and production secrets separate.
- Use managed Supabase/Postgres for data instead of running a database on the VPS at first.
- Treat the VPS as disposable infrastructure: the repo should be enough to rebuild it.

## 12. Troubleshooting

If Caddy fails to start:

- Check DNS points to the VPS IP.
- Make sure ports `80` and `443` are open.
- Run `sudo caddy validate --config /etc/caddy/Caddyfile`.

If a backend container fails:

- Check the relevant service's `backend/<service>-backend/.env`.
- Use `docker compose logs -f <service-name>`.
- Confirm Supabase credentials and JWT secrets are correct.

If Flutter staging still tries to use the map backend:

- Confirm the staging lane is using `lib/main_staging.dart`.
- Confirm `ENABLE_MAP_FEATURES=false` for staging.

## 13. Recommended next step

Start with staging only on the VPS, verify the API and Flutter beta flow, then bring production online once the staging path is stable.