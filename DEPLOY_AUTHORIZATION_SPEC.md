# Deploy authorization: spec

**Status:** approved, not yet implemented
**Date:** 2026-08-18
**Scope:** who is allowed to change production, and what artifact reaches it

## The problem

Nothing currently stands between "has push access" and "production changes".

Verified against the repository on 2026-08-18:

| Finding | Evidence |
|---|---|
| `main` and `develop` have no branch protection and no rulesets | `GET /repos/Syntraksoftware/Snowtrak/branches/{main,develop}/protection` → 404; `GET /rulesets` → empty |
| 10 collaborators hold `push` on a public repo | `GET /collaborators` — 10 with `push`, 1 with `admin` |
| A push to `main` ships to TestFlight with no PR and no test gate | `.github/workflows/ios-testflight.yml` triggers on `push: branches: [develop, main]` |
| Any `v*` tag uploads a binary to App Store Connect with no reviewer | `.github/workflows/flutter-release.yml` triggers on `push: tags: ['v*']`, no `environment:` |
| Production deploys mutable branch HEAD, so there is no rollback target | `deploy-backend-vps.yml` checks out `origin/main` |
| The image Trivy scans is not the image production runs | `deploy-backend-vps.yml` runs `up -d --build`, so the VPS builds its own from source. CI publishes scanned images to GHCR that nothing consumes |
| The docs teach the bypass as normal practice | `git reset --hard` + `docker compose up` appears in `vps_setup.md`, `developer_handoff.md`, `backend/deploy/README.md` |

`.github/branch-protection.md` describes the right rules but labels them "recommended". They were never applied.

Two consequences worth separating. The first is unauthorized change: anyone can push to a deploy-eligible branch. The second is artifact drift: even an authorized deploy runs bytes that no scan ever saw, because the VPS rebuilds from source.

## Decisions taken

| Question | Decision |
|---|---|
| Merge gate | PR required, CI required, **0 approvals** |
| Deploy artifact | CI pushes to GHCR; deploy pins by digest |
| iOS gate | `v*` tag ruleset (admin only) + `appstore` environment with required reviewer |
| Release identity | One `v*` tag is one release, covering backend and iOS |
| SSH bypass | Documentation change only; workflow becomes the sole documented path |

The 0-approvals choice is deliberate and has a known limit, recorded here so it is not mistaken for an oversight: one person can open and merge their own PR. It stops direct pushes and force-pushes, which was the stated concern, but it does not stop one person landing a change alone. The brake on *release* is the deploy-layer gate in section 3 — production and App Store both still require the admin to approve. The gate is at the deploy layer, not the merge layer.

## 1. Authorization model

### 1.1 Branch ruleset

Name: `protected-branches`. Target: `main`, `develop`. Enforcement: active.

Rules:
- `deletion` — blocked
- `non_fast_forward` — blocked (no force-push)
- `pull_request` — required, `required_approving_review_count: 0`
- `required_status_checks` — the contexts in 1.2

No bypass actors. The admin is bound too; an admin editing the ruleset is the break-glass path (section 4.2), and that edit is visible in the audit log, which a silent force-push is not.

### 1.2 Required status checks

A required check that does not run leaves the PR permanently pending and unmergeable. `backend-ci.yml` is filtered on `paths: ['backend/**', '.github/workflows/backend-ci.yml']`, so on a docs-only PR its jobs never start. **Removing that `paths:` filter is a prerequisite for requiring its checks**, not an optional tidy-up.

Required:

| Context | Source | Note |
|---|---|---|
| `Backend Tests` | `tests.yml` | no path filter |
| `Frontend Tests` | `tests.yml` | no path filter |
| `Lint` | `backend-ci.yml` | after the filter is removed |
| `Test (main-backend)` | `backend-ci.yml` | after the filter is removed |
| `Test (community-backend)` | `backend-ci.yml` | after the filter is removed |
| `Test (activity-backend)` | `backend-ci.yml` | after the filter is removed |
| `Test (shared)` | `backend-ci.yml` | after the filter is removed |
| `GitGuardian Security Checks` | GitGuardian app | public repo; a leaked secret is the costliest failure here |

Deliberately **not** required, though they still run and stay visible:

- `Build, Scan, Push (main-backend | community-backend | activity-backend | map-backend)`
- `Validate iOS development build`

Both failed on PR #29 on 2026-08-17 from GitHub CDN faults, not from code: `429 Too Many Requests` on `codeload.github.com` fetching the `trivy-action` tarball, and `429` on `raw.githubusercontent.com` fetching CocoaPods podspecs. Making them merge gates means a GitHub incident blocks all merges. Their security value is in the scan gate before publish (section 2.2), which is enforced where it matters.

Known redundancy, recorded and deliberately out of scope: `tests.yml`'s `Backend Tests` runs only `backend/main-backend`, duplicating `backend-ci.yml`'s `Test (main-backend)`. Worth collapsing in a separate change.

### 1.3 Tag ruleset

Name: `release-tags`. Target: tags matching `v*`. Enforcement: active.

Rules: `creation`, `update`, `deletion` all restricted. Bypass actor: `RepositoryRole: admin`.

Branch rulesets do not cover tags. Without this, the tag that triggers an App Store upload can be created by any of the 10 collaborators.

## 2. Build once, deploy by digest

### 2.1 What already exists

More than an earlier draft of this spec credited. `docker-images.yml` already:

- names images `ghcr.io/syntraksoftware/snowtrak-<service>`
- builds locally with `load: true` for scanning, then logs in to GHCR and pushes in a separate step, gated on `github.event_name != 'pull_request'`
- orders those steps correctly: build → smoke check → Trivy report → upload SARIF → Trivy gate → push, so a failing scan never publishes

Verified: the `Log in to GHCR` and `Push image tags to GHCR` steps both completed successfully on the latest `main` run (`32045435488`). Images for `:main`, `:latest` and `:sha-<sha>` exist today.

The `push: false` that appears in the file is on the *first* build step and is deliberate — that build exists to be loaded locally for scanning, not to publish.

So the publish half is done. The gap is entirely on the consuming side: **nothing pulls those images.** The VPS builds its own from source, which is what makes the scanned artifact and the running artifact different.

### 2.2 Changes to `docker-images.yml`

One change only:

- **Add a tag trigger.** The workflow fires on `push: branches: [main, develop, restructure]` — no tags. A `v1.2.3` tag therefore publishes nothing, and section 2.4's digest resolution would find no such image. Add `tags: ['v*']` under the existing `push:`.

No login step, no push step, no tag-logic change is needed. The existing `vars` step builds its image tag from `GITHUB_REF_NAME`, which for a tag push is the tag name itself, so `v1.2.3` yields `snowtrak-<service>:v1.2.3` with no edit. `:latest` is applied only when the ref is `main`, so tags will not move it.

Known imprecision, accepted: the push step is a second `build-push-action` invocation reusing the `type=gha` cache rather than pushing the exact image object that was scanned. With a cache hit it produces identical bytes. Tightening this to push the scanned image by digest is a possible follow-up, not a blocker.

Package visibility: must be **public**. The repository is public and the images contain only already-public source — env files are mounted at runtime via `env_file:` and are not in the image. A public package lets the VPS pull with no credentials, removing a secret from the deploy path rather than adding one. This is set in the package settings UI and cannot be done with the current CLI token scopes (`gist`, `read:org`, `repo`, `workflow`), so it is a manual step.

### 2.3 Changes to the Compose files

`backend/deploy/docker-compose.production.yml` — replace the `build:` block on `main-backend`, `community-backend`, `activity-backend`, `map-backend` with:

```yaml
image: ${SNOWTRAK_MAIN_IMAGE:?}
image: ${SNOWTRAK_COMMUNITY_IMAGE:?}
image: ${SNOWTRAK_ACTIVITY_IMAGE:?}
image: ${SNOWTRAK_MAP_IMAGE:?}
```

`backend/deploy/docker-compose.staging.yml` — the same for its three services. It has no `map-backend`.

`redis` keeps `image: redis:7-alpine`.

The `:?` is required, not stylistic. An unset variable must abort the deploy loudly rather than silently resolve to an empty image reference.

### 2.4 Changes to `deploy-backend-vps.yml`

The `ref` input keeps its name but narrows to two accepted forms, resolved to image tags:

| Input form | Image tag used | Allowed for |
|---|---|---|
| any tag matching `v*` (e.g. `v1.2.3`, `v0.0.1-rc1`) | `:<tag>` | staging and production |
| 40-character commit SHA | `:sha-<sha>` | staging only |

Production accepts `v*` tags only and rejects anything else before touching the box. It does not further restrict the tag shape, so an RC tag is deployable to production if you choose — the App Store pattern in section 3 is narrower than this one on purpose, because a bad server deploy is revertible in minutes and a binary sent to Apple is not. Staging also accepts a SHA so a `develop` commit can be tested without cutting a release tag.

- Before the SSH step, resolve each service's `:<tag>` to a digest and export `SNOWTRAK_*_IMAGE=ghcr.io/...@sha256:...`. Production resolves four (including `map-backend`); staging resolves three, since its Compose file has no `map-backend`.
  Resolution command: `docker buildx imagetools inspect <ref> --format '{{.Manifest.Digest}}'`. If that format string is unavailable on the runner's buildx, `docker manifest inspect -v <ref>` and reading `.Descriptor.digest` is the fallback.
- Pass those variables through `envs:` into the SSH script.
- The VPS runs `docker compose pull` then `up -d`. **`--build` is removed** — the box no longer builds.
- Keep: the production-teardown rejection, the per-service env-file presence check, the health-poll loop, `-p` project pinning.
- Echo the resolved digests into the job summary, so the deploy record names the exact bytes.

The checkout on the VPS is still needed — it holds the Compose files and the per-service `.env` files. It checks out the release tag (or SHA) rather than a branch.

**Accepted regression:** staging can no longer deploy an arbitrary feature branch, because `docker-images.yml` only publishes images for `main`, `develop`, `restructure` and `v*` tags — a feature-branch commit has no published image. Feature work reaches staging by merging to `develop` first, which is now PR-and-CI gated. This is a consequence of deploying only scanned artifacts and is preferred over publishing an image for every branch.

Net effect: the bytes Trivy scanned are the bytes production runs; a 1-vCPU box stops building four images per deploy; rollback is re-running the workflow with an earlier tag.

## 3. iOS release gate

- Create a GitHub environment named `appstore` with the admin as a required reviewer.
- `flutter-release.yml` gains `environment: appstore`. The tag still triggers the run, but the upload pauses for approval. A tag created by mistake costs a declined approval, not an App Store submission.
- **Narrow the tag pattern from `v*` to final releases only:** `v[0-9]+.[0-9]+.[0-9]+`. The current `v*` matches pre-release tags such as `v0.0.1-rc1`, so the release-candidate tag used to verify the backend path in section 5 would itself fire an App Store upload. Backend deploys can still consume RC tags; only the App Store path is restricted to final versions.
- `ios-testflight.yml` trigger narrows from `[develop, main]` to `[develop]`. Merging to `main` stops producing a redundant TestFlight build; `main` releases through tags.
- `submit_for_review: false` in `frontend/ios/fastlane/Fastfile` is unchanged. Public release stays a manual action in App Store Connect. The risk being closed is unreviewed binaries reaching Apple, not surprise public releases.

## 4. Documentation

### 4.1 Remove the bypass from the docs

Delete the manual `git reset --hard` + `docker compose up` recipes from `docs/vps_setup.md` (§8), `docs/developer_handoff.md` (§5), and `backend/deploy/README.md` (the cutover section). Replace with the workflow as the single documented path. Rewrite `.github/branch-protection.md` to state what is enforced instead of what is recommended.

### 4.2 Break glass

Add one clearly-labelled section covering:
- Rollback: re-run the deploy workflow with the previous `v*` tag.
- Actions unavailable: the manual `docker compose pull` + `up -d` sequence with digests supplied by hand.
- The honest limit: anyone with SSH to the box can bypass all of this. This is a trust boundary, not a technical one. The control is that the bypass is not documented as routine and that SSH access is granted narrowly — not that it is impossible.

## 5. Sequencing and verification

1. Rulesets (1.1, 1.3) and removal of the `backend-ci.yml` path filter (1.2). No application code changes; effective immediately.
2. iOS gate (3) — the `appstore` environment, the reviewer, and the narrowed tag pattern.
3. GHCR publish, Compose `image:`, digest deploy (2.2–2.4).
4. Documentation (4).

Step 1 is independent and lands first. Steps 2–4 go through the gate step 1 just created, which also serves as its first live test.

**The iOS gate precedes the backend work deliberately.** Step 3's verification cuts a tag, and any tag is capable of triggering an iOS release. Landing the reviewer gate and the narrowed tag pattern first means no tag can reach Apple unreviewed at any point during the rollout.

**Verification gate before production:** cut `v0.0.1-rc1`, deploy it to staging, and confirm the three staging containers are running the expected digests (`docker inspect --format '{{.Image}}'`) before production is touched. Production is not deployed through the new path until staging has been. The `-rc1` suffix keeps the tag outside the App Store pattern set in step 2.

Rollback for the pipeline change itself: the previous deploy workflow and `build:`-based Compose files remain in git history and can be restored by revert if the digest path fails in staging.

## Out of scope

- Collapsing the `Backend Tests` / `Test (main-backend)` duplication (1.2).
- SHA-pinning the 11 tag-pinned GitHub Actions — all or nothing, its own change.
- Two dead documentation links found while surveying: `docs/community/community_threads_implementation.md → ./community_debug_curl.md` and `README.md → frontend/docs/architecture_map_service.md`.
- Reducing who holds `push`, and who holds SSH to the VPS. Both are access-review decisions, not pipeline changes.
