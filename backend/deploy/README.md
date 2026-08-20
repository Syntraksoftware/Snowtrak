# VPS deployment

Caddy runs on the host and terminates TLS. Everything else runs in Docker
Compose, bound to loopback, reachable only through Caddy.

```text
internet ──▶ Caddy (host, :80 :443) ──▶ 127.0.0.1:8080  main-backend
                                    ├─▶ 127.0.0.1:5001  community-backend
                                    ├─▶ 127.0.0.1:5100  activity-backend
                                    └─▶ 127.0.0.1:5200  map-backend
                                                         redis (no host port)
```

| File | Purpose |
|---|---|
| `docker-compose.production.yml` | Live stack. Project name `snowtrak-prod`. |
| `docker-compose.staging.yml` | On-demand test stack. Project name `snowtrak-staging`, ports in the 15xxx range. |
| `Caddyfile.example` | Reverse-proxy layout for both. |
| `../*-backend/.env` | Live credentials, one file per service, never in git. Templates are each service's own `.env.example`. |
| `bootstrap_droplet.sh` | First-time host setup. |

Deploys are manual: **Actions → Deploy Backend to VPS → Run workflow**. The
`production` environment carries a required reviewer, so it pauses for
approval. A merge to `main` does not deploy anything.

## The firewall is not optional

Inbound must allow **22, 80, 443 only**. Port 80 is required: Caddy renews
certificates over ACME HTTP-01 and redirects plain HTTP.

Use the DigitalOcean cloud firewall, not `ufw`. Docker writes its own iptables
rules ahead of ufw's chain, so `ufw deny 6379` does not close a published
Docker port. The Compose files bind every port to `127.0.0.1` as a second
layer, so a missing or misedited firewall is no longer sufficient on its own
to expose a service.

## Environment configuration

Each service reads its own `backend/<service>-backend/.env`. They are
deliberately **not** merged into one file per environment.

An earlier design did merge them. It does not work, and the reason is not
cosmetic:

```text
main-backend       POSTGRES_SCHEMA=main
community-backend  POSTGRES_SCHEMA=community
map-backend        POSTGRES_SCHEMA=map
```

One shared file points all three at a single schema. `APP_NAME`,
`CORS_ALLOWED_ORIGINS`, and `JWT_ACCESS_TOKEN_EXPIRE_MINUTES` diverge the same
way. Keeping the files per service keeps those differences intact and means
there is nothing to migrate -- the files the droplet already runs on are the
files the production stack reads.

Staging and production stay separate by living in **different checkouts**, not
different filenames:

```text
/srv/syntrak-application/backend/<service>-backend/.env   production
/srv/snowtrak-staging/backend/<service>-backend/.env      staging
```

`HOST`, `PORT`, `FASTAPI_ENV` and the rate-limit and cache namespaces are set
in the Compose files instead, where `environment:` wins over `env_file:`. That
protects those keys, and only those keys. `POSTGRES_SCHEMA`, `APP_NAME`,
`CORS_ALLOWED_ORIGINS` and the JWT settings live in the env files alone, so
consolidating the files still collapses them. Keep the files per service.

One thing to keep consistent by hand: `main-backend` reads `SECRET_KEY` and
`ALGORITHM` where the other three read `JWT_SECRET` and `JWT_ALGORITHM`. If
those disagree, tokens minted by one service will not verify in another.

## Cutting over from the old layout

The droplet previously ran `backend/docker-compose.yml` -- the development
stack. It now binds to `127.0.0.1` as well, so the swap is about the project
name, Redis persistence, and having a file that is meant for production, not
about closing an exposure. Built ahead of time, the outage is seconds, not
minutes.

```bash
cd <VPS_APP_DIR>
git fetch origin && git checkout --detach origin/main

# 1. The env files are already there from the old layout; confirm, don't rebuild.
ls -l backend/*-backend/.env

# 2. There is nothing to build. Images are built and scanned in CI and pulled
#    by digest at deploy time, so the slow four-image build on one vCPU is
#    gone. Run the deploy workflow to bring the new stack up (step 3 shows what
#    it does on the box).

# 3. Swap. The new stack cannot bind the host ports while the old one holds
#    them, so the old one goes down first. The old stack has no `name:` in its
#    Compose file, so its project name is whatever `docker compose ls` reports
#    -- Compose derives it from the checkout directory. Confirm, then pass it
#    explicitly: guessing wrong leaves the old containers up and the new stack
#    fails to bind.
docker compose ls
docker compose -f backend/docker-compose.yml -p <old-project-name> down

# Then run: Actions -> Deploy Backend to VPS -> production, ref: v1.2.3

# 4. Verify before trusting it. Stop on the first failure -- without the
#    `|| break` a later passing check masks an earlier one.
for p in 8080 5001 5100 5200; do
  curl -fsS "http://127.0.0.1:$p/health" && echo " :$p ok" || { echo " :$p FAILED"; break; }
done
curl -fsS https://main.syntrak.io/health && echo " public ok"
```

Rollback, if the new stack misbehaves:

```bash
docker compose -f backend/deploy/docker-compose.production.yml -p snowtrak-prod down
docker compose -f backend/docker-compose.yml -p <old-project-name> up -d
```

Nothing carries over from the old stack's Redis, and nothing needs to: it ran
without a volume, so its data was already lost on every restart. The new
service has one, plus `appendonly`, so the activity pipeline stream survives a
restart for the first time. Still worth letting an in-flight upload finish
before the swap.

The env files are untouched by the cutover -- both stacks read the same
`backend/<service>-backend/.env` files -- so the only differences are the
project name and Redis gaining persistence. Caddy needs no change: both stacks
publish the same loopback ports.

## Staging

Staging is not kept running. The droplet has 1 vCPU and under 2 GB of RAM;
four more services would leave production without headroom. Bring it up for a
test and take it down after.

```text
Actions → Deploy Backend to VPS → Run workflow
  environment: staging
  ref:         the branch to test
  action:      up      ... then later ...  down
```

It uses `snowtrak-staging` as its project name and ports
15080/15001/15100/15200, so it runs beside production rather than replacing it.
It runs the same four services as production: the Flutter staging flavour
builds with map features enabled and points at `staging-map.syntrak.io`, so a
staging stack without a map-backend left every map call in the staging app
failing on DNS.

Staging and production use different `VPS_APP_DIR` values, set per GitHub
environment, so they are separate checkouts and neither can `git reset --hard`
over the other.

`staging-map.syntrak.io` needs a DNS A record pointing at the droplet, the
same as the other staging hosts. Until it exists, the staging app's map calls
fail even though the backend is running.

## Break glass

**Rolling back.** Re-run the deploy workflow with the previous release tag.
That is the whole procedure -- images for older tags stay in GHCR, so there is
nothing to rebuild.

**If Actions is unavailable.** On the box, with digests taken from the last
good deploy's job summary:

```bash
cd <VPS_APP_DIR>
export SNOWTRAK_MAIN_IMAGE=ghcr.io/syntraksoftware/snowtrak-main-backend@sha256:...
export SNOWTRAK_COMMUNITY_IMAGE=ghcr.io/syntraksoftware/snowtrak-community-backend@sha256:...
export SNOWTRAK_ACTIVITY_IMAGE=ghcr.io/syntraksoftware/snowtrak-activity-backend@sha256:...
export SNOWTRAK_MAP_IMAGE=ghcr.io/syntraksoftware/snowtrak-map-backend@sha256:...
docker compose -f backend/deploy/docker-compose.production.yml -p snowtrak-prod pull
docker compose -f backend/deploy/docker-compose.production.yml -p snowtrak-prod up -d
```

This is the only sanctioned manual path, and it exists for the case where the
normal one is down. It is not a shortcut for a routine deploy.

**The limit of all this.** Anyone with SSH to the droplet can bypass every
control above. That is a trust boundary, not a technical one. The controls are
that the bypass is not the documented route, and that SSH access is granted
narrowly -- not that it is impossible.

## GitHub environments

`Settings → Environments`. Each holds its own copy of four secrets:

| Secret | Notes |
|---|---|
| `VPS_HOST` | Droplet IP |
| `VPS_USER` | SSH user |
| `VPS_SSH_KEY` | Private key, full PEM including the header and footer lines |
| `VPS_APP_DIR` | Checkout path -- **different for each environment** |

On `production`, add a required reviewer and restrict the deployment branch to
`main`. Leave `staging` ungated.
