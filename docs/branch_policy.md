# Branch policy

## The branches

| Branch | Role |
|---|---|
| `main` | Production. What ships. Release tags (`v*`) are cut from here. |
| `develop` | Integration. Feature branches land here first. |
| `stage` | Code only. Holds the latest merged tree and builds nothing. |
| `feat/*`, `fix/*`, `docs/*`, `chore/*` | Short-lived work branches. Merge into `develop` via PR. |
| `wip/*` | Personal or backup branches for experiments. Never pushed to `develop` directly. |

Work branch prefixes match the Conventional Commits types used in commit
subjects, so `feat/follower-mechanism` carries `feat(follows): …` commits. Use
the abbreviated form (`feat/`, not `feature/`).

The flow is `feat/* → develop → main`. A merge to `main` is a release
decision, not an integration step.

## Why `stage` exists

`develop` publishes. A push there builds and pushes four Docker images
(`docker-images.yml`) and uploads a build to TestFlight (`ios-testflight.yml`).
Both are durable and externally visible, which is right for an integration
branch and wrong when the only thing wanted is a copy of the current code.

`stage` is that copy. Created 2026-09-01 from `develop`. No workflow names it:

| Workflow | Fires on `stage`? |
|---|---|
| `tests.yml`, `ios-dev.yml` | No — `[main, develop]` |
| `docker-images.yml` | No — `[main, develop, restructure]` |
| `ios-testflight.yml` | No — `[develop]` |
| `flutter-release.yml` | No — `v*` tags |
| `deploy-backend-vps.yml` | No — `workflow_dispatch` |
| `backend-ci.yml` | **On a PR into it, yes.** Its `pull_request:` has no branch filter, deliberately: see the comment at the top of that file. It runs tests and publishes nothing. |

So `stage` produces no artifact. It is also **not protected** — the ruleset in
`.github/rulesets/protected-branches.json` names `refs/heads/main` and
`refs/heads/develop` exactly — so it accepts direct pushes, force-pushes and
deletion. That is the trade for having no ceremony on it.

It is a mirror, not a stage in the flow. Nothing merges *out of* it, and it
drifts the moment somebody forgets to update it. If it is ever used to decide
anything, give it protection and a required check first.

## Why `develop` exists

CI is built around it, not just convention:

| Workflow | Triggers on |
|---|---|
| `tests.yml`, `backend-ci.yml`, `docker-images.yml` | push + PR to `main` and `develop` |
| `ios-dev.yml` | PRs into `main` and `develop` |
| `ios-testflight.yml` | **push to `develop` only** |
| `flutter-release.yml` | `v*` tags |
| `deploy-backend-vps.yml` | manual (`workflow_dispatch`) |

`develop` is where a build reaches TestFlight. `main` releases through tags.
Merging a feature straight into `main` skips the TestFlight step entirely,
which is the practical reason the flow matters.

## Resynced 2026-08-27

Between PR #19 and PR #36, work was merged directly into `main` and `develop`
was left behind — `main` ran 134 commits ahead. `develop` held no unique
content (`git diff main...develop` was empty), so it was resynced from `main`
via PR rather than force-push.

If the branches drift apart again, the fix is the same: open a `main` →
`develop` PR. It cannot be a fast-forward, because `develop`'s tip is not an
ancestor of `main`, so it costs exactly one merge commit. That is the floor —
rebase-and-merge would rewrite every commit, and force-push is blocked.

## Protection

`main` and `develop` are both protected by GitHub rulesets. No direct pushes,
no force-pushes, no branch deletion, no bypass actors — admins included.
Required checks and the applied JSON are in `.github/branch-protection.md` and
`.github/rulesets/`.

Zero approvals are required by choice: one person can open and merge their own
PR. The brake on *releasing* sits at the deploy layer, where production and the
App Store both need a reviewer.

## Large files

Do not commit `backend/data/*.geojson` or other large assets to `main` or
`develop`. Use a `.gitkeep` placeholder and keep the asset in external storage
(S3 or Git LFS).

When restoring from a `wip/*` branch, cherry-pick or check out source, tests,
and docs only — never the data directories.
