# Writing the changelog

`CHANGELOG.md` follows [Common Changelog](https://common-changelog.org). This
page is the short version plus the few things specific to this repository. When
the two disagree, Common Changelog wins.

The changelog is for people deciding whether to upgrade and what will break.
It is not a commit log — git already has one.

## Shape

````markdown
# Changelog

## [0.0.3] - 2026-08-27

_One sentence, only when a release needs a caveat or an upgrade note._

### Changed

- **Breaking:** rename the feed cursor parameter ([`abc1234`](url))
- Store follower counts in a table maintained by a trigger ([`8a24183`](url))

### Fixed

- Render the profile header while it loads ([`d8fa466`](url))

[0.0.3]: https://github.com/Syntraksoftware/Snowtrak/releases/tag/v0.0.3
````

Releases newest first by version, never by date. Version is semver with no `v`
prefix and matches the git tag. Date is ISO 8601.

## The four groups, in this order

`Changed`, `Added`, `Removed`, `Fixed`. Only these four, and only the ones that
have entries. Performance work is `Changed`. A new endpoint is `Added`. There
is no `Security`, no `Deprecated`, no `Performance`.

Within a group: breaking changes first, then whatever matters most, then
newest.

## One line each

Imperative mood — finish the sentence *"applying this will…"*:

> Store follower counts in a table maintained by a trigger

Not `Stored`, not `Storing`, not `Follower counts are now stored`.

Each line must stand on its own, because someone will read it without the
group heading above it. `Fix the bug` says nothing; `Render the profile header
while it loads` says what changed.

Keep it to one line. The reasoning belongs in the commit message and, when it
is worth keeping, in `docs/`. If a line needs a paragraph, write the paragraph
somewhere else and let the line point at the result.

Breaking changes get a bold `**Breaking:**` prefix and sort to the top of their
group.

## References are required

Every entry ends with a link, in parentheses:

```markdown
- Add follow and unfollow ([`8a24183`](https://github.com/Syntraksoftware/Snowtrak/commit/8a24183))
- Fix the feed cursor ([#194](https://github.com/Syntraksoftware/Snowtrak/pull/194))
```

Prefer the pull request when there is one; a commit hash otherwise. Several
references of the same kind go in one pair of parentheses: `(#1, #2)`.

**This means the changelog is written after the commits exist**, not before.
Write the entries from the commits you just made.

Authors are optional and go after the references — `(Alice Meerkat)` — and are
omitted when a release has one contributor.

## Do not

- No `Unreleased` section. If it is not released, it is not in here.
- No copied commit subjects or PR titles. Rewrite for a reader who was not
  there.
- No Conventional Commits prefixes. `feat(follows):` belongs in the commit, not
  the changelog.
- No maintenance noise: lockfiles, dev dependencies, formatting, CI tweaks,
  internal refactors nobody outside the repo can observe.
- No regional dates. `2026-08-27`, never `27/08/2026`.
- No `[YANKED]`. Use the release notice instead.

## Where the detail goes

A changelog line says *what changed*. Three other places carry *why*:

| Question | Where |
|---|---|
| Why was it built this way? | `docs/superpowers/specs/` |
| Why is it fast/slow, and what did we measure? | the relevant `docs/` page |
| What exactly did this commit do? | the commit message |

Link to those from the notice or from an `Added` line when the reader needs
them. Do not inline them.
