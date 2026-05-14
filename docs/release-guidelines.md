# Release & Branching Guidelines

This document outlines a minimal, practical workflow for keeping `production` and `dev` branches clean and for publishing iOS builds to TestFlight.

## Branch model (recommended)
- `main` — Production branch (always deployable). Protected: require PR reviews, CI pass, signed commits.
- `develop` — Integration branch for the next release (CI required). Merge here from feature branches.
- `feature/*` — Developer branches off `develop`.
- `release/*` — Created from `develop` when preparing a release; final fixes applied here and then merged to `main` and `develop`.
- `hotfix/*` — For urgent production fixes off `main`, merged back to `main` and `develop`.

Keep `main` clean: always create a tag `vX.Y.Z` when merging release into `main`.

## CI & PR rules
- Require passing CI checks (backend tests, linters, frontend tests) before merging.
- Require at least 1 code review approval for non-trivial changes.

## iOS TestFlight release (summary)
1. Create `release/X.Y` branch from `develop` when ready.
2. Stabilize and run CI. Run manual acceptance tests on staging environment.
3. Merge `release/X.Y` into `main` and tag `vX.Y.Z`.
4. Push tag to GitHub — a GitHub Actions workflow (`flutter-release.yml`) will build the iOS `ipa` and run `fastlane` to upload to App Store Connect.
5. In App Store Connect, create TestFlight build and distribute to testers.

## Storing builds and artifacts
- Keep small API specs and build metadata in `packages/shared/openapi/` and `docs/releases/`.
- Avoid storing large binary builds in git. Use GitHub Releases or an external artifact store.

## Secrets and Credentials
- Use GitHub Secrets for App Store Connect API keys and any certificate management. Do not commit secrets into the repository.
