# Branch and tag protection

These are applied as GitHub rulesets, not suggestions. The JSON that was
applied lives in `.github/rulesets/`, and the live state is readable with:

```bash
gh api repos/Syntraksoftware/Snowtrak/rulesets --jq '.[]|"\(.name) \(.target) \(.enforcement)"'
```

## `protected-branches` -- `main`, `develop`

- No direct pushes. Changes land through a pull request.
- No force-pushes, no branch deletion.
- Zero approvals required, by choice. One person can open and merge their own
  PR. The brake on *releasing* is at the deploy layer, not here: production and
  App Store both require an approval from a reviewer.
- These checks must pass: `Backend Tests`, `Frontend Tests`, `Lint`,
  `Test (main-backend)`, `Test (community-backend)`, `Test (activity-backend)`,
  `Test (shared)`, `GitGuardian Security Checks`.
- `Build, Scan, Push (*)` and `Validate iOS development build` run but do not
  block. Both have failed on GitHub CDN faults rather than on code -- 429s from
  `codeload.github.com` and `raw.githubusercontent.com` on 2026-08-17. As
  required checks, a GitHub incident would block every merge in the repository.
  Their security value is the scan gate before publish, which is enforced where
  it matters.
- No bypass actors. Admins are bound too. An admin editing the ruleset is the
  break-glass path, and that edit appears in the audit log, which a silent
  force-push would not.

## `release-tags` -- `v*`

Only repository admins can create, move or delete a `v*` tag.

Branch rules do not cover tags, and a `v` tag is what starts a release: it
publishes images to GHCR and, for a final version number, opens an App Store
upload for review. Without this rule, anyone with push access could start
either.

## What is deliberately not here

There is no CODEOWNERS file. With zero required approvals it would not enforce
anything, so it would be decoration.
