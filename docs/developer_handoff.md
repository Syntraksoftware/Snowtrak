# Developer Handoff Guide

This document is for future developers who need to continue the VPS deployment work, push changes, or operate the app in a predictable way.

Use this together with [docs/vps_setup.md](vps_setup.md), [docs/key_inventory.md](key_inventory.md), [docs/branch_policy.md](branch_policy.md), [docs/api_standardization.md](api_standardization.md), and [docs/playbook/map-backend_beta.md](playbook/map-backend_beta.md).

## 1. What this project uses

- `develop` is the working branch for production-ready code.
- `main` is reserved for release snapshots.
- `feature/*` branches should merge into `develop` through PRs.
- The backend runs on a DigitalOcean VPS with Docker Compose and Caddy.
- The frontend uses lane-based iOS builds: `dev`, `staging`, and `production`.

## 2. What a new developer needs

- A GitHub account with access to the repository.
- Git installed locally.
- SSH key access to the VPS.
- GitHub repository secrets for the Apple and VPS credentials listed in [docs/key_inventory.md](key_inventory.md).
- Access to the VPS environment files for staging and production.

## 3. How to connect to the server

### First-time VPS bootstrap

For a fresh DigitalOcean droplet, run [backend/deploy/bootstrap_droplet.sh](../backend/deploy/bootstrap_droplet.sh) as root. It installs Docker, Caddy, creates the `deploy` user, and configures UFW.

From a Mac, connect with the private key that matches the uploaded public key:

```bash
ssh -i ~/.ssh/syntrak_do_ed25519 root@167.172.140.49
```

After the initial server setup, the normal deploy user is:

```bash
ssh -i ~/.ssh/syntrak_do_ed25519 deploy@167.172.140.49
```

If SSH fails with `Permission denied (publickey)`, the key is not installed for that user on the server yet.

## 4. Local development flow

```bash
git checkout develop
git pull origin develop
cd frontend
flutter pub get
flutter run -t lib/main_dev.dart
```

For backend work:

```bash
cd backend
python run.py
```

## 5. How to push changes to the server later

The standard path is:

1. Make your code change locally.
2. Run the relevant local checks.
3. Commit and push to GitHub.
4. Update the VPS by either:
   - triggering the GitHub Actions deploy workflow, or
   - SSHing into the server and pulling the matching branch manually.

### Manual VPS update for staging

```bash
cd /srv/syntrak-application
git fetch origin
git checkout develop
git reset --hard origin/develop
docker compose -f backend/deploy/docker-compose.staging.yml up -d --build
```

### Manual VPS update for production

```bash
cd /srv/syntrak-application
git fetch origin
git checkout main
git reset --hard origin/main
docker compose -f backend/deploy/docker-compose.production.yml up -d --build
```

## 6. How deployment should work

- Staging deploys from `develop`.
- Production deploys from `main` or a tagged release.
- Caddy handles HTTPS and reverse proxying.
- The backend containers should stay bound to `127.0.0.1` only.
- Do not expose raw container ports to the public internet.

### GitHub Actions deploy option

Use [.github/workflows/deploy-backend-vps.yml](../.github/workflows/deploy-backend-vps.yml) when you want to deploy without logging into the VPS.

Required GitHub secrets:

- `VPS_HOST`
- `VPS_USER`
- `VPS_SSH_KEY`
- `VPS_APP_DIR`

## 7. Secrets and env files

Keep App Store Connect secrets in GitHub repository secrets.

Keep backend runtime secrets in the per-service VPS env files, one per
backend, in each environment's own checkout:

- `/srv/syntrak-application/backend/<service>-backend/.env` (production)
- `/srv/snowtrak-staging/backend/<service>-backend/.env` (staging)

Deploy credentials themselves live in GitHub environment secrets
(`VPS_HOST`, `VPS_USER`, `VPS_SSH_KEY`, `VPS_APP_DIR`), one set per
environment, not in repository secrets.

Do not commit real `.env` files to git.

## 8. Checkpoints before pushing changes

- Run the relevant tests or analyzer checks.
- If API routes changed, refresh OpenAPI snapshots: `backend/scripts/export_openapi.sh`.
- Confirm branch target: `develop` for staging work, `main` only for releases.
- Review whether the change touches backend runtime secrets or GitHub secrets.
- If the change affects deployment, update [docs/vps_setup.md](vps_setup.md) as well.

## 9. Common failure points

- SSH key not installed on the VPS.
- Wrong branch checked out on the VPS.
- Missing or incorrect env values in staging or production.
- Caddy not pointing at the correct localhost port.
- Secrets added to git instead of GitHub secrets or VPS env files.

## 10. If you are taking over this work

Start with:

1. Read [docs/branch_policy.md](branch_policy.md).
2. Read [docs/key_inventory.md](key_inventory.md).
3. Read [docs/vps_setup.md](vps_setup.md).
4. Verify you can SSH into the VPS.
5. Verify staging can deploy before changing production.
