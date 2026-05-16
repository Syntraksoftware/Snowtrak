Branch protection rules (recommended):

- Protect `main` and `develop` branches.
- Require pull request reviews before merging (at least one approval).
- Require passing CI checks and unit tests before merge.
- Prevent merging PRs that change or add large binary/data files above 5MB.
- Restrict who can push directly to `main` and `develop` (maintainers only).

Implement these via GitHub branch protection settings and CODEOWNERS.
