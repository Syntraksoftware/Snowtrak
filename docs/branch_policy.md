**Branch Policy**

- **develop**: Production-ready code only. Branch must pass CI, tests, and code review. No large binary or data files should be committed here.
- **main**: Release snapshots only; merges to `main` require an approved PR and passing release pipeline.
- **feature/**: Short-lived branches for features and fixes. Merge into `develop` via PR.
- **wip/**: Personal or backup branches for in-progress work and experiments. These may store uncommitted work but should not be pushed to `develop` directly.
- **wip/* restore guidance**: When restoring from `wip/*`, selectively cherry-pick or checkout only source, tests, and docs. Do NOT restore `backend/data/*.geojson` or other large assets; replace with `.gitkeep` or store assets in external storage (S3 or Git LFS).

Branch owners and PR rules are defined in `.github/branch-protection.md`.
