# Applied rulesets

The JSON in this directory is what was POSTed to the repository rulesets API.
GitHub does not read these files; they are here so the configuration is
reviewable in a PR and re-appliable if a ruleset is ever deleted.

Re-apply with:

```bash
gh api -X POST repos/Syntraksoftware/Snowtrak/rulesets \
  --input .github/rulesets/protected-branches.json
gh api -X POST repos/Syntraksoftware/Snowtrak/rulesets \
  --input .github/rulesets/release-tags.json
```

Read what is currently live with:

```bash
gh api repos/Syntraksoftware/Snowtrak/rulesets --jq '.[]|"\(.name) \(.target) \(.enforcement)"'
```

`release-tags` uses `actor_id: 5`, the built-in `admin` repository role. This
was verified by pushing a `v*` tag as an admin and getting "Bypassed rule
violations" rather than a rejection.
