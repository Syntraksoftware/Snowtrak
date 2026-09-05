# Deployment

How to ship Snowtrak. This is the operational runbook — what to click, in what
order, and how to tell it worked.

For *why* the pipeline is shaped this way, see
[DEPLOY_AUTHORIZATION_SPEC.md](DEPLOY_AUTHORIZATION_SPEC.md). For the VPS
itself, see [backend/deploy/README.md](backend/deploy/README.md).

## Before your first deploy

**The GHCR packages must be public.** Until they are, every deploy fails at the
pull step with `denied`.

github.com/orgs/Syntraksoftware/packages → each of the four
`snowtrak-*-backend` packages → **Package settings** → **Change visibility** →
**Public**.

The repository is already public and the images hold only public source — env
files are mounted at runtime and are not baked in. Making the packages public
means the VPS pulls with no credentials, so there is one less secret in the
deploy path.

Check it without deploying — a token request for a public package needs no
login, and a 200 means the pull step will work:

```bash
for s in main community activity map; do
  img="syntraksoftware/snowtrak-$s-backend"
  tok=$(curl -sf "https://ghcr.io/token?scope=repository:$img:pull&service=ghcr.io" \
        | sed -n 's/.*"token":"\([^"]*\)".*/\1/p')
  printf "%-18s %s\n" "$s" "$(curl -s -o /dev/null -w '%{http_code}' \
    -H "Authorization: Bearer $tok" "https://ghcr.io/v2/$img/manifests/<tag>")"
done
```

**The box itself has preconditions too**, and they are worth checking before a
release rather than during one: the checkout owned by `VPS_USER`, no local
modifications in it, an `.env` per service, and credentials in those files that
are still current. Each is spelled out in
[backend/deploy/README.md](backend/deploy/README.md#what-the-box-has-to-look-like).

## The rules, in one place

| Thing | Rule |
|---|---|
| Landing code | PR only. No direct pushes to `main` or `develop`. No force-push. |
| Merging | 8 checks must pass. No approval required — you may merge your own PR. |
| Creating a `v*` tag | Repository admins only. |
| Production backend deploy | Final `v1.2.3` tags only, never `-rc`. Pauses for a reviewer. |
| Staging backend deploy | A `v*` tag, or a 40-character commit SHA. No reviewer. |
| App Store upload | Final versions only (`v1.2.3`, not `v1.2.3-rc1`). Pauses for a reviewer. |
| TestFlight | Manual. Actions -> iOS Staging -> Run workflow, any branch. |
| What runs in production | The exact image digest CI built and Trivy scanned. The VPS never builds. |

## Routine release, start to finish

Roughly 30–40 minutes of wall clock, most of it the iOS build. Apple's own
review afterwards is 1–3 days and is not counted here.

### 1. Land the work on `develop`

Open a PR into `develop`, wait for the 8 required checks, merge.

Merging to `develop` builds and publishes the Docker images. It no longer
uploads to TestFlight — putting a build in front of testers is a decision, so
it is a separate click. When you want one:

```bash
gh workflow run ios-testflight.yml --ref develop
```

~15–25 min. See [docs/ios_release_pipeline.md](docs/ios_release_pipeline.md).

### 2. Promote `develop` to `main`

Open a PR from `develop` into `main`, wait for checks, merge.

This does **not** deploy anything. `main` is the release candidate, not the
release.

### 3. Cut the release tag

```bash
git checkout main && git pull
git tag v1.2.3
git push origin v1.2.3
```

Only an admin can do this. The push reports `Bypassed rule violations`, which
is normal and means the admin bypass worked.

The tag starts two things at once:

- **Docker Images** builds, scans and publishes four images tagged `:v1.2.3`
  (~3–5 min). If Trivy finds a fixable CRITICAL/HIGH, nothing is published.
- **iOS Production Release** builds the app, then **waits for your approval**
  before uploading to Apple.

The tag is also the version number: `v1.2.3` ships to Apple as `1.2.3`. There
is no `pubspec.yaml` bump to remember, and nothing else to keep in step.

### 4. Approve the App Store upload

Actions → the waiting **iOS Production Release** run → **Review deployments** →
approve `appstore`.

Uploading takes ~15–25 min. It lands the build in App Store Connect; it does
**not** submit it for review.

### 5. Apply any schema change

**Before the deploy, not after.** The deploy workflow rolls itself back when a
release fails its health check, and that restores the images only — nothing
reverts a migration. Deploying first means the window where new code meets an
old schema is the window you are least watching.

Does this release touch the database?

```bash
cd backend && .test-venv/bin/python -m alembic current   # is it behind head?
git log --oneline main@{1}..main -- backend/db/migrations # anything new?
```

- **Alembic revision** (PostGIS, `map_trail`): `python -m alembic upgrade head`
  from `backend/`.
- **Supabase table**: run the numbered `.sql` in the Supabase SQL editor, then
  `python scripts/dump_supabase_schema.py` and commit the refreshed record.
- **Neither**: skip to step 6.

Whatever you run must leave the *previous* release able to run against it — add
columns, do not remove them, and drop the old one a release later. The full rule
is in [docs/database_changes.md](docs/database_changes.md).

### 6. Deploy the backend

**Actions → Deploy Backend to VPS → Run workflow**

| Field | Value |
|---|---|
| environment | `production` |
| ref | `v1.2.3` |
| action | `up` |

Approve the `production` environment when it pauses.

The workflow resolves each service to an image digest, prints them in the run
summary, pulls, and polls all four `/health` endpoints for up to 5 minutes. If
any of them never answers, it puts the previous digests back before failing.
Takes ~3–5 min.

### 7. Check it

```bash
curl -fsS https://main.syntrak.io/health && echo " public ok"
```

On the box, if you want to confirm the running images match the summary:

```bash
docker compose -f backend/deploy/docker-compose.production.yml -p snowtrak-prod ps
```

### 8. Submit the app to Apple

App Store Connect → your build → submit for review. This step is deliberately
manual and outside CI.

## Testing on staging first

Staging is not kept running. The droplet has 1 vCPU; bring it up for a test and
take it down after.

**Actions → Deploy Backend to VPS → Run workflow**

| Field | Value |
|---|---|
| environment | `staging` |
| ref | `v1.2.3-rc1`, or a 40-character commit SHA from `develop` |
| action | `up` |

No approval needed. Check `http://127.0.0.1:15080/health` on the box.

Take it down with the same workflow and `action: down`.

Three things to know:

- **Staging shares production's Supabase project.** There is only one, so a
  staging stack reads and writes the live database. It is a code sandbox, not a
  data one — a like made on staging is a real like.
- A feature branch cannot be deployed. Images are published only for `main`,
  `develop` and `v*` tags, so merge to `develop` first and deploy its SHA.
- An `-rc` tag is safe. It deploys to staging but reaches neither production
  nor the App Store — both gates match final version numbers only.

## Rolling back

A deploy that fails its health check rolls itself back — it recorded the digests
it replaced and puts them back. The run ends red, because a rollback is a failed
deploy, but production is already on the last good images. Read the log to see
which service refused to start.

To go back deliberately, re-run the deploy workflow with the previous tag. Older
images stay in GHCR, so there is nothing to rebuild.

Neither path touches the database. Migrations are applied by hand and are not
reverted, so keep them backward-compatible: add, do not remove, and drop the old
column a release later. See [docs/database_changes.md](docs/database_changes.md).

| Field | Value |
|---|---|
| environment | `production` |
| ref | the previous good `v*` tag |
| action | `up` |

Takes the same ~3–5 min as a deploy.

## When something fails

| Symptom | Cause | Fix |
|---|---|---|
| Deploy fails pulling, `denied` | Packages are private | Make them public — see the top of this file |
| Deploy rejects your ref | Production takes a final `v1.2.3` tag; `-rc` tags and raw SHAs are staging-only | Cut a final tag, or deploy to staging |
| `could not resolve ...:v1.2.3` | Docker Images did not publish for that tag | Check the Docker Images run for that tag; a failed Trivy gate blocks publishing |
| Tag push rejected | You are not a repository admin | Ask an admin to cut the tag |
| PR will not merge | One of the 8 required checks has not passed | Check the PR's checks; `Build, Scan, Push` and `Validate iOS` do not block |
| Health poll times out | One of the four services did not start | The workflow prints the last 30 log lines of each, then rolls back to the previous digests |
| Deploy fails on `missing env config` | An `.env` on the box has no `SECRET_KEY`/`JWT_SECRET`, `SUPABASE_URL` or `SUPABASE_SERVICE_ROLE_KEY` | Set it — see [backend/deploy/README.md](backend/deploy/README.md#environment-configuration) |
| `cannot lock ref ... Permission denied` | Something ran `git` as root in the checkout, so the deploy user cannot write `.git` | `chown -R <VPS_USER>:<VPS_USER> <VPS_APP_DIR>` |
| `Your local changes would be overwritten by checkout` | A tracked file was hand-edited on the box | Back it up outside the repo, then `git checkout -- <file>` |
| A service starts, then exits on a database error | The `.env` holds a credential that has since been rotated | Update the `.env` in **every** checkout; a running container keeps working on the old one until it restarts, which hides this until a deploy |
| `(ECIRCUITBREAKER) too many authentication failures` | A container crash-looped against a wrong database password and Supabase blocked new connections | Fix the credential, stop the stack so it stops retrying, wait a few minutes |

## Break glass

Only for when Actions itself is unavailable. This bypasses the scan gate and
the reviewer, so it is the exception, not a shortcut.

The procedure lives in
[backend/deploy/README.md](backend/deploy/README.md#break-glass), with the
digests taken from the last good deploy's job summary.

Worth stating plainly: anyone with SSH to the droplet can bypass every control
described in this document. That is a trust boundary, not a technical one. The
protection is that the bypass is not the routine path and that SSH is granted
narrowly.
