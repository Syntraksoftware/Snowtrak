# Branch Protection & CI Gating Rules

This document explains how to configure GitHub branch protection for `main` and `develop` to maintain clean production and dev branches.

## Recommended branch protection for `main` (production)

Set these rules on GitHub repository settings under "Branches" > "Branch protection rules" > "Add rule" with pattern `main`:

1. **Require a pull request before merging**
   - ✓ Require approvals: **1** (minimum)
   - ✓ Dismiss stale pull request approvals when new commits are pushed
   - ✓ Require approval of the most recent reviewable push

2. **Require status checks to pass before merging**
   - ✓ Require branches to be up to date before merging
   - ✓ Status checks to pass (select from list):
     - `Backend CI / test-and-lint` (all services)
     - `Flutter CI` (if you have one, or manual sign-off)
     - Any linter/security checks

3. **Require code reviews from code owners**
   - ✓ Require code owner review (optional; set up `.github/CODEOWNERS` first)

4. **Restrict who can push**
   - ✓ Include administrators (recommended to enforce on yourself too)

5. **Allow force pushes**
   - ✗ Uncheck this (force push should be disabled)

6. **Allow deletions**
   - ✗ Uncheck this (prevent accidental branch deletion)

**Summary rule**: No PR can merge to `main` without at least 1 approval + CI pass.

## Recommended branch protection for `develop` (integration)

Set these rules on pattern `develop`:

1. **Require a pull request before merging**
   - ✓ Require approvals: **1**
   - ✓ Dismiss stale pull request approvals

2. **Require status checks to pass before merging**
   - ✓ Require branches to be up to date before merging
   - ✓ Status checks: same as `main`

3. Allow force pushes: ✗ (same as main)

4. Allow deletions: ✗ (same as main)

**Summary rule**: Slightly more relaxed than `main` (1 approval + CI pass).

## Release workflow with protected branches

1. Create `release/vX.Y.Z` from `develop`.
2. Stabilize, run manual tests, and push small fixes to `release/vX.Y.Z`.
3. Open a PR from `release/vX.Y.Z` → `main`. Once approved and CI passes, merge and tag `main` with `vX.Y.Z`.
4. Open a PR from `release/vX.Y.Z` → `develop` to keep `develop` in sync.
5. GitHub Actions workflow (`flutter-release.yml`) triggers on tag `v*` and uploads to TestFlight.

## GitHub Secrets required for CI

For `.github/workflows/flutter-release.yml` and similar workflows to work, add these secrets to your repo settings (Settings > Secrets and variables > Actions):

- `APP_STORE_CONNECT_API_KEY` — JSON file content from App Store Connect API key
- `FASTLANE_SESSION` — fastlane session token (or use App Store Connect API key instead)
- `APPLE_DEVELOPER_TEAM_ID` — Your Apple Developer Team ID (e.g., `ABCD12345E`)
- (Optional) `APPLE_DEVELOPER_APP_ID` — App ID from App Store Connect

For backend CI, no additional secrets needed (unless you have private package repos).

## Setting up `.github/CODEOWNERS` (optional)

Create `.github/CODEOWNERS` to enforce code owner review on sensitive paths:

```
# Example
/backend/main-backend/  @maintainer-username
/frontend/  @flutter-maintainer-username
```

Then enable "Require code owner review" in branch protection.

## Workflow summary (Git branch tree)

```
┌─ hotfix/* (off main, merge back to main + develop)
│
├─ main (protected, always deployable, tagged vX.Y.Z)
│
├─ release/vX.Y.Z (from develop, fix & merge to main + develop)
│
├─ develop (protected, integration branch)
│
└─ feature/* (off develop, PR to develop)
```

All PRs must pass CI and at least 1 review before merge.
