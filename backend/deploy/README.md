# VPS deployment

Caddy runs on the host and terminates TLS. Everything else runs in Docker
Compose, bound to loopback, reachable only through Caddy.

```
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
| `env/*.env.example` | Templates. The real `env/production.env` and `env/staging.env` live only on the box. |
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

## Building the env file

Each Compose file reads one `env/<environment>.env`. That file is not in git.

Copy the template and fill it in from the four per-service `.env` files:

```bash
cd backend/deploy
cp env/production.env.example env/production.env
chmod 600 env/production.env
$EDITOR env/production.env
```

Three things to get right when merging four files into one:

1. **`RATE_LIMIT_NAMESPACE` must not be in the merged file.** Each service
   needs its own (`main-backend`, `community-backend`, `activity-backend`,
   `map-backend`). The Compose files pin them per service, and Compose's
   `environment:` block wins over `env_file:`, so a stray value in the env
   file is overridden rather than collapsing all four onto one shared
   rate-limit counter. Leave it out and let the Compose files decide.

2. **`HOST`, `PORT`, and `FASTAPI_ENV` are also set per service in Compose.**
   Anything you put in the env file for those is ignored.

3. **`main-backend` names its JWT settings differently.** It reads
   `SECRET_KEY` and `ALGORITHM`; the other three read `JWT_SECRET` and
   `JWT_ALGORITHM`. Set both pairs to the same values or tokens minted by one
   service will not verify in another.

`SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, and the JWT settings are shared
by all four and belong in the merged file.

## Cutting over from the old layout

The droplet previously ran `backend/docker-compose.yml` -- the development
stack -- which publishes on `0.0.0.0`. Moving to this directory's production
file is a one-time swap with roughly a minute of downtime.

```bash
cd <VPS_APP_DIR>
git fetch origin && git checkout --detach origin/main

# 1. Build the env file first; the deploy workflow refuses to start without it.
ls -l backend/deploy/env/production.env

# 2. Start the new stack under its own project name. It cannot bind the
#    host ports while the old one holds them, so stop the old one first.
docker compose -f backend/docker-compose.yml down

docker compose -f backend/deploy/docker-compose.production.yml \
  -p snowtrak-prod up -d --build

# 3. Verify before trusting it.
for p in 8080 5001 5100 5200; do curl -fsS "http://127.0.0.1:$p/health" && echo " :$p ok"; done
curl -fsS https://main.syntrak.io/health && echo " public ok"
```

Rollback, if the new stack misbehaves:

```bash
docker compose -f backend/deploy/docker-compose.production.yml -p snowtrak-prod down
docker compose -f backend/docker-compose.yml up -d
```

The old stack's Redis data does not carry over: the new one uses the
`snowtrak-prod_redis_data` volume. Redis here holds rate-limit counters,
caches, and the activity pipeline stream, all of which rebuild -- but let the
pipeline drain before cutting over if an upload is in flight.

## Staging

Staging is not kept running. The droplet has 1 vCPU and under 2 GB of RAM;
four more services would leave production without headroom. Bring it up for a
test and take it down after.

```
Actions → Deploy Backend to VPS → Run workflow
  environment: staging
  ref:         the branch to test
  action:      up      ... then later ...  down
```

It uses `snowtrak-staging` as its project name and ports 15080/15001/15100, so
it runs beside production rather than replacing it. It has no `map-backend`;
the Flutter staging flavour ships with map features disabled.

Staging and production use different `VPS_APP_DIR` values, set per GitHub
environment, so they are separate checkouts and neither can `git reset --hard`
over the other.

`staging-map.syntrak.io` has no DNS record. Add one only if a staging
map-backend is ever introduced.

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
