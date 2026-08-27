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

All four services accept **either** `SECRET_KEY` or `JWT_SECRET`, so the name
in each file does not have to match -- but the **value** does. `main-backend`
signs; the other three verify. If the values disagree, every token minted is
rejected everywhere else, and nothing in the logs says "misconfigured".

`main-backend` refuses to start on its built-in development secret whenever
`FASTAPI_ENV` says production or staging, so the failure that used to be silent
is now a container that will not come up. The deploy workflow checks for the
key before it gets that far.

Still by hand: `main-backend` reads `ALGORITHM` where the other three read
`JWT_ALGORITHM`. Both default to HS256, so this only bites if you change one.

## The cutover, and what it cost

Done on 2026-08-25 at `v0.0.2-rc1`. Until then the droplet had run
`backend/docker-compose.yml` -- the development stack, project name `backend`,
images built on the box -- continuously for seven weeks. `snowtrak-prod` had
never started. Every service bound `0.0.0.0` and relied on the cloud firewall;
they now bind `127.0.0.1`, and Redis publishes no host port at all.

The swap is what it always was: the new stack cannot bind the host ports while
the old one holds them, so the old one goes down first.

```bash
cd <VPS_APP_DIR>
docker compose ls        # confirm the old project name before trusting it

# Pull first. This touches nothing that is running and takes the outage from
# minutes to seconds.
for s in main community activity map; do
  docker pull ghcr.io/syntraksoftware/snowtrak-$s-backend:<tag>
done

docker compose -f backend/docker-compose.yml -p backend down   # outage starts here
# then: Actions -> Deploy Backend to VPS -> production, ref: <tag>
```

Queue the workflow *before* taking the old stack down: the production
environment pauses for a reviewer, and the stack stays down for however long
that approval takes.

Verify, stopping at the first failure so a later pass cannot mask an earlier
one:

```bash
for p in 8080 5001 5100 5200; do
  curl -fsS "http://127.0.0.1:$p/health" && echo " :$p ok" || { echo " :$p FAILED"; break; }
done
curl -fsS https://main.syntrak.io/health && echo " public ok"
```

Rollback, if the new stack misbehaves. The old images are still on the box as
`backend-*:latest`, and `backend/docker-compose.yml` is still tracked, so it
survives the detached checkout the deploy performs:

```bash
docker compose -f backend/deploy/docker-compose.production.yml -p snowtrak-prod down
docker compose -f backend/docker-compose.yml -p backend up -d
```

Note that the first production deploy has no automatic rollback. The workflow
recovers by putting back the digests it replaced, and on a first deploy there
are no `snowtrak-prod` containers to read them from; it says so and leaves the
stack for inspection. From the second deploy onwards the net is there.

### What the box has to look like

The cutover was planned at under a minute of downtime and took roughly fifteen,
because three preconditions were only discovered when the deploy hit them. None
were in the release. All of them are checkable in advance, and a second
environment will meet them again.

| Requirement | How it failed | Check |
|---|---|---|
| The checkout is owned by `VPS_USER` | `git` had been run as root in it, so `git fetch` could not write refs: `cannot lock ref ... Permission denied` | `find <VPS_APP_DIR> -not -user <VPS_USER>` returns nothing |
| No local modifications in the checkout | `backend/docker-compose.yml` had been hand-edited on the box (a `dns:` override). `git checkout --detach` refuses rather than discard it | `git status --short` shows no ` M` lines |
| Every service has its `.env`, in **both** checkouts | Staging had none at all, so its first deploy stopped at the env gate | `ls <VPS_APP_DIR>/backend/*-backend/.env` |
| The env files hold current credentials | They still carried a database password that had since been rotated, so `map-backend` crash-looped until Supabase's auth circuit breaker tripped | Start a throwaway container and connect once, before deploying |

The env gate stops before pulling or starting anything, so a failure there
changes nothing on the box. The other three do not: they leave you mid-cutover
with the old stack already down.

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
same as the other staging hosts. As of 2026-08-25 it still has none, so that
one hostname does not resolve and Caddy cannot obtain a certificate for it.
The backend behind it runs regardless -- the deploy health-checks
`127.0.0.1:15200` on the box, not the public name.

### Caddy is maintained by hand, and was wrong

`Caddyfile.example` is a reference, not something any pipeline applies. Until
2026-08-25 the live Caddyfile pointed all three staging hostnames at the
**production** ports:

```
staging-main.syntrak.io      -> 127.0.0.1:8080    # production main-backend
staging-community.syntrak.io -> 127.0.0.1:5001    # production community-backend
staging-activity.syntrak.io  -> 127.0.0.1:5100    # production activity-backend
```

So "staging" answered every request with production, and had done for as long
as the hostnames existed. Anything anyone tested on staging was tested against
the live stack. The correct mapping is the 15xxx range:

| Hostname | Upstream |
|---|---|
| `staging-main` | `127.0.0.1:15080` |
| `staging-community` | `127.0.0.1:15001` |
| `staging-activity` | `127.0.0.1:15100` |
| `staging-map` | `127.0.0.1:15200` |

The lesson generalises: a staging hostname that answers is not evidence that
staging is running. Check what it is proxying to, not whether it returns 200.

Every upstream now imports the `restart_tolerant` snippet, which retries for
10s so the seconds a container spends restarting during a deploy do not surface
as 502s. Applied live on 2026-08-25; keep `Caddyfile.example` and the real file
in step by hand.

## Break glass

**Rolling back.** Usually you do not have to. A deploy records the digests it
is replacing, and puts them back itself if any of the four services fails to
answer `/health` within five minutes. The run still ends red -- a rollback is a
failed deploy -- but the stack is already back on the last good images.

To go back deliberately, re-run the deploy workflow with the previous release
tag. Images for older tags stay in GHCR, so there is nothing to rebuild.

The one case the automatic path cannot cover is a release that changed the
database. Migrations are applied by hand and are not reverted, so a rollback
pairs old code with a new schema. The ordering that keeps that safe is in
[docs/database_changes.md](../../docs/database_changes.md).

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
