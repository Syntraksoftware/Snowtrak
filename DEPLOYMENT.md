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

## The rules, in one place

| Thing | Rule |
|---|---|
| Landing code | PR only. No direct pushes to `main` or `develop`. No force-push. |
| Merging | 8 checks must pass. No approval required — you may merge your own PR. |
| Creating a `v*` tag | Repository admins only. |
| Production backend deploy | `v*` tags only. Pauses for a reviewer. |
| Staging backend deploy | A `v*` tag, or a 40-character commit SHA. No reviewer. |
| App Store upload | Final versions only (`v1.2.3`, not `v1.2.3-rc1`). Pauses for a reviewer. |
| TestFlight | Automatic on every push to `develop`. |
| What runs in production | The exact image digest CI built and Trivy scanned. The VPS never builds. |

## Routine release, start to finish

Roughly 30–40 minutes of wall clock, most of it the iOS build. Apple's own
review afterwards is 1–3 days and is not counted here.

### 1. Land the work on `develop`

Open a PR into `develop`, wait for the 8 required checks, merge.

Merging to `develop` automatically starts a TestFlight build (~15–25 min). No
action needed unless you want to test on device.

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

### 4. Approve the App Store upload

Actions → the waiting **iOS Production Release** run → **Review deployments** →
approve `appstore`.

Uploading takes ~15–25 min. It lands the build in App Store Connect; it does
**not** submit it for review.

### 5. Deploy the backend

**Actions → Deploy Backend to VPS → Run workflow**

| Field | Value |
|---|---|
| environment | `production` |
| ref | `v1.2.3` |
| action | `up` |

Approve the `production` environment when it pauses.

The workflow resolves each service to an image digest, prints them in the run
summary, pulls, and polls `/health` for up to 5 minutes. Takes ~3–5 min.

### 6. Check it

```bash
curl -fsS https://main.syntrak.io/health && echo " public ok"
```

On the box, if you want to confirm the running images match the summary:

```bash
docker compose -f backend/deploy/docker-compose.production.yml -p snowtrak-prod ps
```

### 7. Submit the app to Apple

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

Two things to know:

- A feature branch cannot be deployed. Images are published only for `main`,
  `develop` and `v*` tags, so merge to `develop` first and deploy its SHA.
- An `-rc` tag is safe. It deploys to staging but does **not** reach the App
  Store, because the iOS release only matches final version numbers.

## Rolling back

Re-run the deploy workflow with the previous tag. That is the whole procedure —
older images stay in GHCR, so there is nothing to rebuild.

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
| Deploy rejects your ref | Production takes `v*` tags only; a raw SHA is staging-only | Deploy a tag |
| `could not resolve ...:v1.2.3` | Docker Images did not publish for that tag | Check the Docker Images run for that tag; a failed Trivy gate blocks publishing |
| Tag push rejected | You are not a repository admin | Ask an admin to cut the tag |
| PR will not merge | One of the 8 required checks has not passed | Check the PR's checks; `Build, Scan, Push` and `Validate iOS` do not block |
| Health poll times out | Service did not start | The workflow prints the last 50 log lines of `main-backend` on failure |

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
