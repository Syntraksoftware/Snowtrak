# Deploy Authorization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Put an enforced gate between "has push access" and "production changes", and make the deployed artifact the same bytes CI scanned.

**Architecture:** GitHub rulesets block direct pushes to `main`/`develop` and restrict who can create `v*` tags. CI already publishes Trivy-scanned images to GHCR; the deploy workflow stops building on the VPS and instead pins each service to a resolved image digest. The iOS release path gains a reviewer gate before anything reaches Apple.

**Tech Stack:** GitHub Actions, GitHub rulesets API, Docker Compose, GHCR, fastlane

**Spec:** `DEPLOY_AUTHORIZATION_SPEC.md` (repository root)

## Status as of 2026-08-20

| Task | State |
|---|---|
| 1. `appstore` environment + reviewer | done — live, verified |
| 2. iOS reviewer gate, tag pattern narrowed | done — PR #30 |
| 3. backend-ci always runs | done — PR #30, plus a duplicate-run fix not in this plan |
| 4. Rulesets installed | done — PR #31, both verified against a live push |
| 5. Tag trigger for image publish | done — PR #32 |
| 6. Compose runs published images | done — PR #32 |
| 7. Deploy by resolved digest | done — PR #32, plus a teardown fix not in this plan |
| 8. Staging verification | **blocked** — needs the GHCR packages made public, then a UI-run deploy |
| 9. Documentation | done — PR #33 |

Deviations from this plan, both found while implementing:

- Task 3 gained a scope on the `push:` trigger. Dropping the paths filter left
  `push` unscoped, so every PR-branch commit ran the five jobs twice.
- Task 7 gained a teardown branch. `docker compose down` parses the Compose
  file, so with the image variables unset a `down` would have aborted on `:?`
  instead of stopping the stack.

## Global Constraints

- Image names are `ghcr.io/syntraksoftware/snowtrak-<service>` where `<service>` is one of `main-backend`, `community-backend`, `activity-backend`, `map-backend`.
- Production Compose has 4 services; staging Compose has 3 (no `map-backend`).
- Compose project names: `snowtrak-prod`, `snowtrak-staging`. Always passed with `-p`.
- Health ports: production `8080`, staging `15080`.
- Required status check contexts, exact strings: `Backend Tests`, `Frontend Tests`, `Lint`, `Test (main-backend)`, `Test (community-backend)`, `Test (activity-backend)`, `Test (shared)`, `GitGuardian Security Checks`.
- `Build, Scan, Push (*)` and `Validate iOS development build` are deliberately NOT required checks.
- Never reorder `docker-images.yml` steps: build → smoke → Trivy report → upload SARIF → Trivy gate → push.
- No YAML linter is installed. Validate workflow YAML with `ruby -ryaml -e 'YAML.load_file(ARGV[0])'` and Compose with `docker compose config`.

## Order of operations

Task 4 installs the rulesets. Every task before it lands by ordinary PR; every task after it goes through the new gate. Task 1 must precede Task 2 because a workflow referencing a non-existent environment does not get the reviewer gate.

---

### Task 1: Create the `appstore` environment with a required reviewer

**Files:** none — GitHub API only.

**Interfaces:**
- Produces: a GitHub environment named `appstore` that Task 2's workflow references.

- [ ] **Step 1: Confirm the environment does not already exist**

```bash
gh api repos/Syntraksoftware/Snowtrak/environments --jq '.environments[].name'
```

Expected: output does not include `appstore`.

- [ ] **Step 2: Get the admin's numeric user id**

```bash
gh api users/chefmatteo --jq '.id'
```

Record the number; the next step needs it.

- [ ] **Step 3: Create the environment with the admin as required reviewer**

Replace `<USER_ID>` with the number from Step 2.

```bash
gh api -X PUT repos/Syntraksoftware/Snowtrak/environments/appstore \
  -F "wait_timer=0" \
  -F "prevent_self_review=false" \
  -f "reviewers[][type]=User" \
  -F "reviewers[][id]=<USER_ID>"
```

- [ ] **Step 4: Verify the reviewer stuck**

```bash
gh api repos/Syntraksoftware/Snowtrak/environments/appstore \
  --jq '{name, reviewers: [.protection_rules[]? | select(.type=="required_reviewers") | .reviewers[].reviewer.login]}'
```

Expected: `{"name":"appstore","reviewers":["chefmatteo"]}`. If `reviewers` is empty the gate does not exist — re-run Step 3 before continuing.

- [ ] **Step 5: No commit** — this task changes no files.

---

### Task 2: Gate the iOS release path

**Files:**
- Modify: `.github/workflows/flutter-release.yml` (trigger block, job block)
- Modify: `.github/workflows/ios-testflight.yml` (trigger block)

**Interfaces:**
- Consumes: the `appstore` environment from Task 1.
- Produces: nothing later tasks depend on.

- [ ] **Step 1: Narrow the release tag pattern**

In `.github/workflows/flutter-release.yml`, replace:

```yaml
on:
  workflow_dispatch:
  push:
    tags:
      - 'v*'
```

with:

```yaml
on:
  workflow_dispatch:
  push:
    tags:
      # Final versions only. 'v*' also matched pre-release tags such as
      # v0.0.1-rc1, so the release candidate used to verify the backend deploy
      # path would itself have uploaded a build to App Store Connect.
      - 'v[0-9]+.[0-9]+.[0-9]+'
```

- [ ] **Step 2: Add the reviewer gate**

In the same file, add `environment: appstore` to the job. Replace:

```yaml
jobs:
  build-and-upload:
    name: Build iOS and Upload to App Store Connect
    runs-on: macos-latest
```

with:

```yaml
jobs:
  build-and-upload:
    name: Build iOS and Upload to App Store Connect
    runs-on: macos-latest
    # Pauses for an admin's approval before any binary reaches Apple. The tag
    # still starts the run; the upload waits.
    environment: appstore
```

- [ ] **Step 3: Stop TestFlight builds on main**

In `.github/workflows/ios-testflight.yml`, replace:

```yaml
  push:
    branches: [ develop, main ]
```

with:

```yaml
  push:
    # develop only. main releases through v* tags, so a merge to main used to
    # produce a redundant TestFlight build of the same code.
    branches: [ develop ]
```

- [ ] **Step 4: Validate both files parse**

```bash
ruby -ryaml -e 'YAML.load_file(".github/workflows/flutter-release.yml"); YAML.load_file(".github/workflows/ios-testflight.yml"); puts "both parse OK"'
```

Expected: `both parse OK`

- [ ] **Step 5: Verify the tag pattern rejects RC tags**

The pattern is a GitHub filter pattern, not a regex, and must match the whole ref name. Confirm the intent by hand:

| Tag | `v[0-9]+.[0-9]+.[0-9]+` |
|---|---|
| `v1.2.3` | matches |
| `v10.0.1` | matches |
| `v0.0.1-rc1` | does not match — trailing `-rc1` is unmatched |

- [ ] **Step 6: Commit**

```bash
git add .github/workflows/flutter-release.yml .github/workflows/ios-testflight.yml
git commit -m "ci(ios): require review before App Store upload, and stop releasing from main pushes"
```

---

### Task 3: Make the backend CI checks always run

**Files:**
- Modify: `.github/workflows/backend-ci.yml` (trigger block, lines 3-11)

**Interfaces:**
- Produces: the check contexts `Lint`, `Test (main-backend)`, `Test (community-backend)`, `Test (activity-backend)`, `Test (shared)` running on every PR, which Task 4 requires.

- [ ] **Step 1: Remove the path filters**

Replace:

```yaml
on:
  push:
    paths:
      - 'backend/**'
      - '.github/workflows/backend-ci.yml'
  pull_request:
    paths:
      - 'backend/**'
      - '.github/workflows/backend-ci.yml'
```

with:

```yaml
on:
  # No paths filter, deliberately. These jobs are required status checks, and a
  # required check that never starts leaves the PR permanently pending and
  # unmergeable -- which is exactly what a docs-only PR would have done while
  # this was filtered on 'backend/**'.
  push:
  pull_request:
```

- [ ] **Step 2: Validate it parses**

```bash
ruby -ryaml -e 'p YAML.load_file(".github/workflows/backend-ci.yml")[true]'
```

Expected: `{"push"=>nil, "pull_request"=>nil}` (Ruby parses the `on:` key as boolean `true`; that is a YAML quirk, not a problem in the file).

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/backend-ci.yml
git commit -m "ci(backend): drop the paths filter so these checks can gate merges"
```

- [ ] **Step 4: Open and merge the PR for Tasks 2-3**

```bash
git push -u origin feat/deploy-authorization
gh pr create --base main --title "Gate the release paths before locking the branches" --body "Implements Tasks 1-3 of DEPLOY_AUTHORIZATION_SPEC.md. The iOS reviewer gate lands before any tag can be cut; backend-ci loses its paths filter so its checks can be required."
```

Wait for checks, then merge:

```bash
gh pr checks --watch
gh pr merge --merge
```

- [ ] **Step 5: Confirm the backend checks now run on a docs-only change**

This is the assumption Task 4 depends on. After the merge, confirm the five contexts appeared on the PR just merged:

```bash
gh api "repos/Syntraksoftware/Snowtrak/commits/$(git rev-parse origin/main)/check-runs?per_page=100" \
  --jq '[.check_runs[].name] | map(select(startswith("Test (") or . == "Lint")) | sort'
```

Expected: all five of `Lint`, `Test (activity-backend)`, `Test (community-backend)`, `Test (main-backend)`, `Test (shared)`.

---

### Task 4: Install the branch and tag rulesets

**Files:**
- Create: `.github/rulesets/protected-branches.json` (record of what was applied)
- Create: `.github/rulesets/release-tags.json` (record of what was applied)

The JSON files are committed so the configuration is reviewable and re-appliable. GitHub does not read them; the API calls do.

**Interfaces:**
- Consumes: the always-running check contexts from Task 3.
- Produces: an enforced gate that every later task's PR passes through.

- [ ] **Step 1: Write the branch ruleset definition**

Create `.github/rulesets/protected-branches.json`:

```json
{
  "name": "protected-branches",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "include": ["refs/heads/main", "refs/heads/develop"],
      "exclude": []
    }
  },
  "rules": [
    { "type": "deletion" },
    { "type": "non_fast_forward" },
    {
      "type": "pull_request",
      "parameters": {
        "required_approving_review_count": 0,
        "dismiss_stale_reviews_on_push": false,
        "require_code_owner_review": false,
        "require_last_push_approval": false,
        "required_review_thread_resolution": false
      }
    },
    {
      "type": "required_status_checks",
      "parameters": {
        "strict_required_status_checks_policy": false,
        "required_status_checks": [
          { "context": "Backend Tests" },
          { "context": "Frontend Tests" },
          { "context": "Lint" },
          { "context": "Test (main-backend)" },
          { "context": "Test (community-backend)" },
          { "context": "Test (activity-backend)" },
          { "context": "Test (shared)" },
          { "context": "GitGuardian Security Checks" }
        ]
      }
    }
  ],
  "bypass_actors": []
}
```

- [ ] **Step 2: Write the tag ruleset definition**

Create `.github/rulesets/release-tags.json`:

```json
{
  "name": "release-tags",
  "target": "tag",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "include": ["refs/tags/v*"],
      "exclude": []
    }
  },
  "rules": [
    { "type": "creation" },
    { "type": "update" },
    { "type": "deletion" }
  ],
  "bypass_actors": [
    {
      "actor_id": 5,
      "actor_type": "RepositoryRole",
      "bypass_mode": "always"
    }
  ]
}
```

`actor_id: 5` is the built-in `admin` repository role.

- [ ] **Step 3: Apply both rulesets**

```bash
gh api -X POST repos/Syntraksoftware/Snowtrak/rulesets \
  --input .github/rulesets/protected-branches.json
gh api -X POST repos/Syntraksoftware/Snowtrak/rulesets \
  --input .github/rulesets/release-tags.json
```

- [ ] **Step 4: Verify both are active**

```bash
gh api repos/Syntraksoftware/Snowtrak/rulesets --jq '.[]|"\(.name)  target=\(.target)  \(.enforcement)"'
```

Expected two lines: `protected-branches  target=branch  active` and `release-tags  target=tag  active`.

- [ ] **Step 5: Verify a direct push to main is now refused**

This is the behaviour the whole plan exists for. Prove it:

```bash
git checkout main && git pull
git commit --allow-empty -m "probe: this push must be rejected"
git push origin main
```

An empty commit is used deliberately, so that if the ruleset is somehow not in
force the pushed commit changes no file.

Expected: the push is REJECTED, with a message naming the `protected-branches` ruleset.

Then undo the local commit:

```bash
git reset --hard origin/main
```

If the push SUCCEEDS, the ruleset is not working. Stop, delete the pushed commit, and re-check Step 3 before going further.

- [ ] **Step 6: Commit the ruleset records**

```bash
git checkout -b chore/ruleset-records
git add .github/rulesets/
git commit -m "chore: record the applied branch and tag rulesets"
git push -u origin chore/ruleset-records
gh pr create --base main --title "Record the applied rulesets" --body "The JSON that was POSTed to the rulesets API, committed so the configuration is reviewable."
```

This PR is also the first live test of the gate. Confirm it cannot merge until the eight required checks pass.

---

### Task 5: Publish images for release tags

**Files:**
- Modify: `.github/workflows/docker-images.yml` (trigger block, lines 3-9)

**Interfaces:**
- Produces: `ghcr.io/syntraksoftware/snowtrak-<service>:v<x.y.z>` for every `v*` tag, which Task 7 resolves to digests.

Do not add a login or push step. The workflow already logs in to GHCR and pushes after the Trivy gate, and both steps are confirmed working on `main`. Only the trigger is missing.

- [ ] **Step 1: Add the tag trigger**

Replace:

```yaml
on:
  push:
    branches: [main, develop, restructure]
  pull_request:
    branches: [main, develop, restructure]
  workflow_dispatch:
```

with:

```yaml
on:
  push:
    branches: [main, develop, restructure]
    # Release tags publish too. Without this a v1.2.3 tag builds nothing, and
    # the deploy workflow's digest lookup has no image to find.
    tags: ['v*']
  pull_request:
    branches: [main, develop, restructure]
  workflow_dispatch:
```

- [ ] **Step 2: Confirm no tag-naming change is needed**

Read the `Prepare image names and tags` step. It sets `branch_tag="${image}:${GITHUB_REF_NAME}"`, and for a tag push `GITHUB_REF_NAME` is the tag name, so `v1.2.3` produces `snowtrak-<service>:v1.2.3` with no edit. `:latest` is added only when the ref is `main`, so a tag will not move it. Confirm by reading lines 47-79; change nothing.

- [ ] **Step 3: Validate it parses**

```bash
ruby -ryaml -e 'YAML.load_file(".github/workflows/docker-images.yml"); puts "parses OK"'
```

Expected: `parses OK`

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/docker-images.yml
git commit -m "ci(docker): publish images for release tags"
```

---

### Task 6: Point the Compose files at published images

**Files:**
- Modify: `backend/deploy/docker-compose.production.yml` (4 service blocks)
- Modify: `backend/deploy/docker-compose.staging.yml` (3 service blocks)

**Interfaces:**
- Produces: the variable names `SNOWTRAK_MAIN_IMAGE`, `SNOWTRAK_COMMUNITY_IMAGE`, `SNOWTRAK_ACTIVITY_IMAGE`, `SNOWTRAK_MAP_IMAGE`, which Task 7 sets.

- [ ] **Step 1: Replace the build blocks in the production file**

In `backend/deploy/docker-compose.production.yml`, for each of the four services replace the `build:` block with an `image:` line. `main-backend` becomes:

```yaml
  main-backend:
    image: ${SNOWTRAK_MAIN_IMAGE:?set by the deploy workflow to a pinned digest}
    env_file:
      - ../main-backend/.env
```

Apply the same shape to the other three, keeping every other key in each service untouched:

| Service | Replaces its `build:` block with |
|---|---|
| `main-backend` | `image: ${SNOWTRAK_MAIN_IMAGE:?set by the deploy workflow to a pinned digest}` |
| `community-backend` | `image: ${SNOWTRAK_COMMUNITY_IMAGE:?set by the deploy workflow to a pinned digest}` |
| `activity-backend` | `image: ${SNOWTRAK_ACTIVITY_IMAGE:?set by the deploy workflow to a pinned digest}` |
| `map-backend` | `image: ${SNOWTRAK_MAP_IMAGE:?set by the deploy workflow to a pinned digest}` |

Leave `redis` as `image: redis:7-alpine`.

The `:?` is required. An unset variable must abort the deploy loudly instead of resolving to an empty image reference.

- [ ] **Step 2: Replace the build blocks in the staging file**

`backend/deploy/docker-compose.staging.yml` has three services and no `map-backend`. Apply the same three replacements: `main-backend`, `community-backend`, `activity-backend`.

- [ ] **Step 3: Verify the files fail loudly when the variables are unset**

```bash
docker compose -f backend/deploy/docker-compose.production.yml config >/dev/null 2>&1 \
  && echo "UNEXPECTED: config succeeded with no image vars" \
  || echo "correctly refused with unset image vars"
```

Expected: `correctly refused with unset image vars`

- [ ] **Step 4: Verify the files resolve when the variables are set**

```bash
SNOWTRAK_MAIN_IMAGE=ghcr.io/syntraksoftware/snowtrak-main-backend:latest \
SNOWTRAK_COMMUNITY_IMAGE=ghcr.io/syntraksoftware/snowtrak-community-backend:latest \
SNOWTRAK_ACTIVITY_IMAGE=ghcr.io/syntraksoftware/snowtrak-activity-backend:latest \
SNOWTRAK_MAP_IMAGE=ghcr.io/syntraksoftware/snowtrak-map-backend:latest \
docker compose -f backend/deploy/docker-compose.production.yml config \
  | grep -E "^\s+image:"
```

Expected: five `image:` lines — the four `ghcr.io/...` images plus `redis:7-alpine`. No `build:` key anywhere in the output.

- [ ] **Step 5: Repeat Step 4 for staging**

```bash
SNOWTRAK_MAIN_IMAGE=ghcr.io/syntraksoftware/snowtrak-main-backend:latest \
SNOWTRAK_COMMUNITY_IMAGE=ghcr.io/syntraksoftware/snowtrak-community-backend:latest \
SNOWTRAK_ACTIVITY_IMAGE=ghcr.io/syntraksoftware/snowtrak-activity-backend:latest \
docker compose -f backend/deploy/docker-compose.staging.yml config \
  | grep -E "^\s+image:"
```

Expected: four `image:` lines (three services plus redis).

- [ ] **Step 6: Commit**

```bash
git add backend/deploy/docker-compose.production.yml backend/deploy/docker-compose.staging.yml
git commit -m "deploy: run published images instead of building on the box"
```

---

### Task 7: Deploy by resolved digest

**Files:**
- Modify: `.github/workflows/deploy-backend-vps.yml` (inputs block, and the deploy job)

**Interfaces:**
- Consumes: the image variables from Task 6, the tag publishing from Task 5.

- [ ] **Step 1: Retarget the `ref` input**

In the `workflow_dispatch.inputs` block, replace the whole `ref` input with:

```yaml
      ref:
        description: 'Release tag (v1.2.3), or a 40-char commit SHA for staging only'
        required: true
        default: ''
        type: string
```

The default was `main`. It must not stay a branch name: Step 2 rejects anything
that is not a `v*` tag or a 40-character SHA, so leaving `main` as the default
makes the obvious button-press fail.

- [ ] **Step 2: Add a validation and digest-resolution step before the SSH step**

Insert this as the first step of the `deploy` job, before `Reject a production teardown`:

```yaml
      - name: Resolve image digests
        id: images
        if: inputs.action == 'up'
        shell: bash
        env:
          REF: ${{ inputs.ref }}
          DEPLOY_ENV: ${{ inputs.environment }}
        run: |
          set -euo pipefail

          # Production takes release tags only. Staging additionally takes a raw
          # commit SHA so a develop commit can be tested without cutting a tag.
          if [[ "$REF" =~ ^v ]]; then
            image_tag="$REF"
          elif [[ "$REF" =~ ^[0-9a-f]{40}$ ]]; then
            if [ "$DEPLOY_ENV" = "production" ]; then
              echo "::error::production deploys a v* release tag, not a raw SHA." >&2
              exit 1
            fi
            image_tag="sha-$REF"
          else
            echo "::error::ref must be a v* tag or a 40-character commit SHA, got '$REF'." >&2
            exit 1
          fi

          # map-backend is production-only; the staging Compose file has no such
          # service, so resolving it would fail on an image that is never used.
          services="main-backend community-backend activity-backend"
          if [ "$DEPLOY_ENV" = "production" ]; then
            services="$services map-backend"
          fi

          echo "Resolving $image_tag" >> "$GITHUB_STEP_SUMMARY"
          for svc in $services; do
            image="ghcr.io/syntraksoftware/snowtrak-${svc}"
            digest=$(docker buildx imagetools inspect "${image}:${image_tag}" \
              --format '{{.Manifest.Digest}}')
            if [ -z "$digest" ]; then
              echo "::error::could not resolve ${image}:${image_tag}" >&2
              exit 1
            fi
            pinned="${image}@${digest}"
            echo "- \`${svc}\` → \`${digest}\`" >> "$GITHUB_STEP_SUMMARY"

            case "$svc" in
              main-backend)      echo "SNOWTRAK_MAIN_IMAGE=$pinned"      >> "$GITHUB_ENV" ;;
              community-backend) echo "SNOWTRAK_COMMUNITY_IMAGE=$pinned" >> "$GITHUB_ENV" ;;
              activity-backend)  echo "SNOWTRAK_ACTIVITY_IMAGE=$pinned"  >> "$GITHUB_ENV" ;;
              map-backend)       echo "SNOWTRAK_MAP_IMAGE=$pinned"       >> "$GITHUB_ENV" ;;
            esac
          done
```

- [ ] **Step 3: Pass the pinned images into the SSH script**

In the `Deploy over SSH` step, extend the `env:` block and the `envs:` list:

```yaml
        env:
          DEPLOY_ENV: ${{ inputs.environment }}
          DEPLOY_REF: ${{ inputs.ref }}
          DEPLOY_ACTION: ${{ inputs.action }}
          SNOWTRAK_MAIN_IMAGE: ${{ env.SNOWTRAK_MAIN_IMAGE }}
          SNOWTRAK_COMMUNITY_IMAGE: ${{ env.SNOWTRAK_COMMUNITY_IMAGE }}
          SNOWTRAK_ACTIVITY_IMAGE: ${{ env.SNOWTRAK_ACTIVITY_IMAGE }}
          SNOWTRAK_MAP_IMAGE: ${{ env.SNOWTRAK_MAP_IMAGE }}
        with:
          host: ${{ secrets.VPS_HOST }}
          username: ${{ secrets.VPS_USER }}
          key: ${{ secrets.VPS_SSH_KEY }}
          envs: DEPLOY_ENV,DEPLOY_REF,DEPLOY_ACTION,SNOWTRAK_MAIN_IMAGE,SNOWTRAK_COMMUNITY_IMAGE,SNOWTRAK_ACTIVITY_IMAGE,SNOWTRAK_MAP_IMAGE
```

- [ ] **Step 4: Stop building on the box**

Inside the SSH `script:`, replace:

```bash
            docker compose -f "$COMPOSE" -p "$PROJECT" up -d --build
            docker image prune -f
```

with:

```bash
            # Pull the exact digests CI scanned. The box no longer builds: the
            # image that Trivy passed is the image that runs.
            docker compose -f "$COMPOSE" -p "$PROJECT" pull
            docker compose -f "$COMPOSE" -p "$PROJECT" up -d
            docker image prune -f
```

- [ ] **Step 5: Keep the checkout on the release ref**

The existing checkout lines already handle this and need no change; they fetch and detach onto `origin/$REF` or `$REF`. The checkout is still required because it holds the Compose files and the per-service `.env` files.

- [ ] **Step 6: Validate it parses**

```bash
ruby -ryaml -e 'YAML.load_file(".github/workflows/deploy-backend-vps.yml"); puts "parses OK"'
```

Expected: `parses OK`

- [ ] **Step 7: Verify the ref validation logic in isolation**

The validation is the only branching logic added, so test it directly rather than by deploying. Save as `/tmp/refcheck.sh`:

```bash
#!/usr/bin/env bash
check() {
  REF="$1"; DEPLOY_ENV="$2"
  if [[ "$REF" =~ ^v ]]; then echo "tag:$REF"
  elif [[ "$REF" =~ ^[0-9a-f]{40}$ ]]; then
    [ "$DEPLOY_ENV" = "production" ] && echo "REJECT sha-on-prod" || echo "sha-$REF"
  else echo "REJECT bad-ref"; fi
}
[ "$(check v1.2.3 production)" = "tag:v1.2.3" ] || { echo FAIL 1; exit 1; }
[ "$(check v0.0.1-rc1 staging)" = "tag:v0.0.1-rc1" ] || { echo FAIL 2; exit 1; }
[ "$(check 0123456789abcdef0123456789abcdef01234567 staging)" = "sha-0123456789abcdef0123456789abcdef01234567" ] || { echo FAIL 3; exit 1; }
[ "$(check 0123456789abcdef0123456789abcdef01234567 production)" = "REJECT sha-on-prod" ] || { echo FAIL 4; exit 1; }
[ "$(check main production)" = "REJECT bad-ref" ] || { echo FAIL 5; exit 1; }
[ "$(check develop staging)" = "REJECT bad-ref" ] || { echo FAIL 6; exit 1; }
echo "all ref validation cases pass"
```

Run: `bash /tmp/refcheck.sh`
Expected: `all ref validation cases pass`

- [ ] **Step 8: Commit and open the PR for Tasks 5-7**

```bash
git add .github/workflows/deploy-backend-vps.yml
git commit -m "deploy: pin each service to a resolved image digest"
git checkout -b feat/deploy-by-digest
git push -u origin feat/deploy-by-digest
gh pr create --base main --title "Deploy the images CI scanned" --body "Implements Tasks 5-7 of DEPLOY_AUTHORIZATION_SPEC.md."
gh pr checks --watch
gh pr merge --merge
```

---

### Task 8: Verify on staging before production

**Files:** none — this is the acceptance gate for Tasks 5-7.

Do not proceed to Task 9, and do not deploy production through the new path, until every step here passes.

- [ ] **Step 1: Make the packages public**

Required, and not doable with the current CLI token scopes. In the browser: **github.com/orgs/Syntraksoftware/packages** → for each of the four `snowtrak-*-backend` packages → **Package settings** → **Change visibility** → **Public**.

Without this the VPS cannot pull and Step 5 fails with `denied`.

- [ ] **Step 2: Cut the release candidate tag**

```bash
git checkout main && git pull
git tag v0.0.1-rc1
git push origin v0.0.1-rc1
```

The `-rc1` suffix keeps this outside the App Store pattern set in Task 2. Only an admin can create it, per Task 4's tag ruleset.

- [ ] **Step 3: Confirm the images published for that tag**

```bash
gh run list --workflow "Docker Images" --limit 1 --json headBranch,status,conclusion
```

Expected: a run for `v0.0.1-rc1` that concludes `success`. If no run appears, Task 5's trigger did not take effect.

- [ ] **Step 4: Deploy it to staging**

**Actions → Deploy Backend to VPS → Run workflow**, with `environment: staging`, `ref: v0.0.1-rc1`, `action: up`.

- [ ] **Step 5: Confirm the job summary lists three digests**

Open the run summary. Expected: `main-backend`, `community-backend` and `activity-backend` each with a `sha256:...` digest. `map-backend` must be absent — staging has no such service.

- [ ] **Step 6: Confirm the containers run those exact digests**

On the VPS:

```bash
docker compose -f backend/deploy/docker-compose.staging.yml -p snowtrak-staging ps -q \
  | xargs docker inspect --format '{{.Name}} {{.Image}}'
```

Expected: the image IDs correspond to the digests from Step 5. Any mismatch means the box built its own image and Task 7 Step 4 did not take effect.

- [ ] **Step 7: Confirm staging is healthy**

```bash
curl -fsS http://127.0.0.1:15080/health && echo " staging ok"
```

Expected: `staging ok`

- [ ] **Step 8: Take staging down**

**Actions → Deploy Backend to VPS → Run workflow**, `environment: staging`, `action: down`.

---

### Task 9: Make the documentation match

**Files:**
- Modify: `docs/vps_setup.md` (§8 first-deploy commands)
- Modify: `docs/developer_handoff.md` (§5 manual VPS update)
- Modify: `backend/deploy/README.md` (cutover section)
- Modify: `.github/branch-protection.md` (whole file)

**Interfaces:** none.

- [ ] **Step 1: Replace the manual first-deploy commands in `docs/vps_setup.md`**

The §8 block that runs `docker compose ... up -d --build` no longer reflects how deploys work, and its `--build` is now wrong. Replace the code block and its preamble with:

```markdown
## 8. First deploy

Deploys run through **Actions → Deploy Backend to VPS → Run workflow**. Pick the
environment and give it a release tag (`v1.2.3`). Staging also accepts a raw
commit SHA.

The workflow resolves each service to a published image digest and the box pulls
it. Nothing is built on the VPS.

Check status:

```bash
docker compose -f backend/deploy/docker-compose.staging.yml -p snowtrak-staging ps
docker compose -f backend/deploy/docker-compose.production.yml -p snowtrak-prod ps
```
```

- [ ] **Step 2: Replace the manual update sections in `docs/developer_handoff.md`**

Replace both "Manual VPS update for staging" and "Manual VPS update for production" sections with:

```markdown
### Updating the VPS

Use **Actions → Deploy Backend to VPS → Run workflow**. There is no manual path
for a routine deploy: the workflow pins each service to the image digest CI
scanned, which a hand-run `docker compose` does not do.

- staging: `environment: staging`, `ref: v1.2.3` or a 40-character commit SHA
- production: `environment: production`, `ref: v1.2.3`

Production pauses for a required reviewer before it touches the live stack.
```

- [ ] **Step 3: Update the cutover section in `backend/deploy/README.md`**

The cutover section describes a one-time migration off `backend/docker-compose.yml` that still stands, but its production `up -d` line must not rebuild. Change:

```bash
docker compose -f backend/deploy/docker-compose.production.yml \
  -p snowtrak-prod build
```

to a note that the build now happens in CI:

```bash
# Images are built and scanned in CI and pulled by digest at deploy time, so
# there is nothing to build here. Run the deploy workflow instead.
```

- [ ] **Step 4: Add the break-glass section to `backend/deploy/README.md`**

Append:

```markdown
## Break glass

**Rolling back.** Re-run the deploy workflow with the previous release tag. That
is the whole procedure — the images for older tags stay in GHCR.

**If Actions is unavailable.** On the box, with digests taken from the last good
deploy's job summary:

```bash
cd <VPS_APP_DIR>
export SNOWTRAK_MAIN_IMAGE=ghcr.io/syntraksoftware/snowtrak-main-backend@sha256:...
export SNOWTRAK_COMMUNITY_IMAGE=ghcr.io/syntraksoftware/snowtrak-community-backend@sha256:...
export SNOWTRAK_ACTIVITY_IMAGE=ghcr.io/syntraksoftware/snowtrak-activity-backend@sha256:...
export SNOWTRAK_MAP_IMAGE=ghcr.io/syntraksoftware/snowtrak-map-backend@sha256:...
docker compose -f backend/deploy/docker-compose.production.yml -p snowtrak-prod pull
docker compose -f backend/deploy/docker-compose.production.yml -p snowtrak-prod up -d
```

**The limit of all this.** Anyone with SSH to the droplet can bypass every
control above. That is a trust boundary, not a technical one. The controls are
that the bypass is not the documented route and that SSH access is granted
narrowly — not that it is impossible.
```

- [ ] **Step 5: Rewrite `.github/branch-protection.md`**

Replace the whole file with what is actually enforced:

```markdown
# Branch and tag protection

These are applied as GitHub rulesets, not suggestions. The JSON that was applied
is in `.github/rulesets/`.

## `protected-branches` — `main`, `develop`

- No direct pushes: changes land through a pull request.
- No force-pushes, no branch deletion.
- Zero approvals required, by choice. One person can open and merge their own
  PR. The brake on releasing is at the deploy layer, not here.
- These checks must pass: `Backend Tests`, `Frontend Tests`, `Lint`,
  `Test (main-backend)`, `Test (community-backend)`, `Test (activity-backend)`,
  `Test (shared)`, `GitGuardian Security Checks`.
- `Build, Scan, Push (*)` and `Validate iOS development build` run but do not
  block. Both have failed on GitHub CDN faults rather than on code; as required
  checks, a GitHub incident would block every merge.
- No bypass actors. An admin editing the ruleset is the break-glass path, and
  that edit shows up in the audit log.

## `release-tags` — `v*`

Only repository admins can create, move or delete a `v*` tag. Branch rules do
not cover tags, and a `v` tag starts an App Store release.
```

- [ ] **Step 6: Check no doc still teaches the bypass**

```bash
grep -rn "up -d --build\|reset --hard" docs/ backend/deploy/README.md || echo "no bypass instructions remain"
```

Expected: `no bypass instructions remain`. Any hit outside the break-glass section must be removed.

- [ ] **Step 7: Check no doc links to a file that does not exist**

```bash
python3 - <<'PY'
import re, os, glob
bad = 0
for f in glob.glob('docs/**/*.md', recursive=True) + ['backend/deploy/README.md', 'README.md', '.github/branch-protection.md']:
    if not os.path.exists(f):
        continue
    for m in re.finditer(r'\[[^\]]*\]\(([^)]+)\)', open(f).read()):
        t = m.group(1).split('#')[0].strip()
        if not t or t.startswith(('http', 'mailto:')):
            continue
        if not os.path.exists(os.path.normpath(os.path.join(os.path.dirname(f), t))):
            print(f"DEAD  {f} -> {t}")
            bad += 1
print(f"{bad} dead links")
PY
```

Expected: the two pre-existing dead links listed in the spec's "Out of scope", and no new ones.

- [ ] **Step 8: Commit and open the PR**

```bash
git add docs/ backend/deploy/README.md .github/branch-protection.md
git commit -m "docs: make the deploy instructions match the pipeline"
git checkout -b docs/deploy-pipeline
git push -u origin docs/deploy-pipeline
gh pr create --base main --title "Documentation: the workflow is the deploy path" --body "Implements Task 9 of DEPLOY_AUTHORIZATION_SPEC.md."
gh pr checks --watch
gh pr merge --merge
```

---

## Manual steps that cannot be automated

Collected so they are not discovered mid-task:

1. **Task 8 Step 1** — making the four GHCR packages public. Needs the packages UI; the CLI token lacks `write:packages`.
2. **Task 8 Steps 4 and 8** — triggering the deploy workflow. `workflow_dispatch` on a workflow with an environment gate is run from the Actions UI.
3. **Task 8 Step 6** — inspecting containers requires SSH to the droplet.

## Rollback for the pipeline change itself

Every task is a separate commit on a separate PR. If the digest deploy misbehaves in staging (Task 8), revert the Task 5-7 PR; the previous `build:`-based Compose files and the old deploy workflow come back intact, and production was never touched.
