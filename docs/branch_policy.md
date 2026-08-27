# Branch policy

## The branches

| Branch | Role |
|---|---|
| `main` | Production. What ships. Release tags (`v*`) are cut from here. |
| `develop` | Integration. Feature branches land here first. |
| `feat/*`, `fix/*`, `docs/*`, `chore/*` | Short-lived work branches. Merge into `develop` via PR. |
| `wip/*` | Personal or backup branches for experiments. Never pushed to `develop` directly. |

Work branch prefixes match the Conventional Commits types used in commit
subjects, so `feat/follower-mechanism` carries `feat(follows): …` commits. Use
the abbreviated form (`feat/`, not `feature/`).

The flow is `feat/* → develop → main`. A merge to `main` is a release
decision, not an integration step.

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
