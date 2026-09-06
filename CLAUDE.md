# Snowtrak Coding Guidelines for Agents

Style rules here come from the
[Google Style Guides](https://google.github.io/styleguide/), for the reason
they give themselves:

> It is much easier to understand a large codebase when all the code in it is
> in a consistent style.

The point isn't that Google is right. It's that *one* set of rules applied
everywhere beats each agent inventing its own.

When this file and an upstream guide disagree, **this file wins**. When this
file is silent, follow the upstream guide for that language.

## Which guide applies where

| Path | Language | Upstream guide | Enforced by |
|---|---|---|---|
| `backend/**` | Python 3.11 | [pyguide](https://google.github.io/styleguide/pyguide.html) | `ruff` (see `backend/pyproject.toml`), `mypy` |
| `frontend/**`, `packages/**` | Dart / Flutter | [Effective Dart](https://dart.dev/effective-dart) | `flutter analyze` (see `frontend/analysis_options.yaml`) |
| `scripts/**`, `backend/deploy/**` | Bash | [Shell guide](https://google.github.io/styleguide/shellguide.html) | review |
| `docs/**`, `*.md` | Markdown | [Markdown guide](https://google.github.io/styleguide/docguide/style.html) | review |
| API payloads, config | JSON | [JSON guide](https://google.github.io/styleguide/jsoncstyleguide.xml) | review |

## Rule 0: run the checks

An agent does not get to claim work is done on unrun checks.

```bash
# Backend, from backend/
../.venv/bin/ruff check .                # gated by CI
../.venv/bin/ruff format --check .       # NOT gated — run it anyway
../.venv/bin/mypy shared run.py          # NOT gated; per-service, dirs are hyphenated
pytest                                   # gated by CI; run from the service dir

# Frontend, from frontend/
flutter analyze                          # NOT gated — run it anyway
flutter test                             # gated by CI
```

Only `ruff check` and the test suites run in CI today. Everything marked NOT
gated is on you, and a green PR is not evidence you ran it. If a check fails,
fix it or say so in the summary. Never disable a lint to make a check pass
without a one-line comment saying why.

## Rule 1: match the file you are in

Local consistency beats this document. A file that already picked a pattern
keeps it; do not "modernize" surrounding code in an unrelated change. Reformat
only the lines you touch.

## Rule 2: catch where you can act, nowhere else

Python is EAFP — exceptions are meant to travel to the code that can actually
do something about them. Catching one anywhere else costs CPU, adds noise, and
produces a worse traceback.

### Never catch to re-raise

```python
# BAD: pure ceremony. Rewrites the traceback, fixes nothing.
try:
    track = parse_gpx(payload)
except ValueError as e:
    raise e

# BAD: same, with extra steps.
except ValueError as e:
    raise ValueError(str(e))

# GOOD: it isn't your error. Say nothing.
track = parse_gpx(payload)
```

If you catch purely to clean up, use a bare `raise` — it preserves the original
traceback exactly:

```python
try:
    file = open("data.txt")
    data = file.read()
except IOError:
    file.close()
    raise           # re-raises the active exception, untouched
```

…though that case is usually `with` or `try/finally`, which is shorter still.
Reach for those first.

`raise X from err` belongs only at a real domain boundary — a `psycopg` error
becoming a service-level error the caller is meant to understand. Not as a
reflex on every layer.

### The places that legitimately catch

**Backend:**

1. `shared/exception_handlers.py` — turns exceptions into HTTP responses.
2. Background task and worker loops — one bad item must not kill the loop.
3. Any call to a third party (Supabase, OpenSkiMap, Nivus) where you have a
   retry, a fallback, or a degraded response to return. No plan means no catch.

**Frontend:** the network boundary is different, because failure is the normal
case on a mountain.

1. `services/**` — catch to retry, fall back to cache, or queue for later sync.
   This is required, not optional; without it the app is unusable offline.
2. Providers — catch at the state boundary (`AsyncValue.guard` or equivalent)
   so the screen gets an error state instead of a grey screen.
3. Nowhere else. Never inside `build()`.

A silent catch needs **a fallback or a log**, plus a comment saying which.
`catch (_) {}` with neither is the bug — not the `catch (_)` itself. One that
returns cached data, clears a corrupt entry, or keeps a poll alive is correct.

The 9 in `frontend/lib/` all qualify (cache-corruption recovery, a polling loop,
a log-recursion guard, a config fallback). **Do not "fix" them.**

### Two more

- **Keep the `try` small.** Wrap the one call that raises, not the twenty lines
  around it, or the handler catches failures you never considered.
- **No exceptions for control flow in hot paths.** The GPS pipeline runs
  per-point; a raise-per-point is a real cost. Check the condition.

The backend currently has ~139 `except Exception` blocks. Do **not** sweep
them. Narrow one when you're already editing its file.

## Rule 3: bound your resources

A feed-shaped app dies of unbounded growth, not of slow functions.

- Every query against a growing table (`activities`, `posts`, GPS points) takes
  a `LIMIT` and an explicit ordering. No unbounded `SELECT` reaches production.
  See `docs/client_feed_cache_and_rate_limiting.md` for the pagination shape.
- Large results stream or chunk. A full GPS track does not get materialized
  into a list so it can be iterated once — use a generator or a cursor.
- Caches are bounded: `@lru_cache(maxsize=N)`, never `maxsize=None` on anything
  keyed by user, activity, or trail. An unbounded cache is a memory leak that
  passes code review.
- `with` for every file, DB session, and HTTP client.
- Dart: every `StreamSubscription`, `AnimationController`, and
  `TextEditingController` is disposed. `cancel_subscriptions` and `close_sinks`
  catch most of it, not all of it.
- Check `mounted` after every `await` before touching state or context.
- Watch for N+1 in feed and profile queries. One round trip per post is the
  classic way to take down a social feed.

## Python

Follows pyguide, with the repo's `ruff` config as the enforcement layer
(`E`, `W`, `F`, `I`, `UP`, `B`, `SIM`; line length 100; double quotes).

### Naming

| Type | Public | Internal |
|---|---|---|
| Modules, packages | `lower_with_under` | `_lower_with_under` |
| Classes, exceptions | `CapWords` | `_CapWords` |
| Functions, methods | `lower_with_under()` | `_lower_with_under()` |
| Constants | `CAPS_WITH_UNDER` | `_CAPS_WITH_UNDER` |
| Variables, parameters | `lower_with_under` | `_lower_with_under` |

Service directories are hyphenated (`main-backend`, `map-backend`) and are
therefore *not* importable packages. That is the reason for the `E402` / `I001`
per-file ignores in `pyproject.toml` — do not add new ones without the same
kind of comment explaining the `sys.path` bootstrap.

### Imports

Grouped most-generic to least: `__future__`, stdlib, third party, then repo
packages (`shared`, `db`, service-local). Sorted lexicographically inside each
group — `ruff`'s isort rule does this for you. No relative imports.
`from typing import ...` and `from collections.abc import ...` are the
sanctioned exceptions to "import modules, not names"; FastAPI's
`from fastapi import Depends` is another, by convention here.

### Docstrings

Required on modules, public functions, classes, and anything non-obvious.
One-line summary ending in a period, blank line, then detail. Use Google
sections in order: `Args:`, `Returns:` / `Yields:`, `Raises:`.

```python
def sample_track(points: list[GpsPoint], hz: float) -> list[GpsPoint]:
    """Downsamples a raw GPS track to a fixed rate.

    Args:
        points: Raw fixes, ordered by timestamp.
        hz: Target sample rate in samples per second.

    Returns:
        A new list; the input is not mutated.

    Raises:
        ValueError: If `hz` is not positive.
    """
```

Skip the docstring on a short, obviously-named private helper. A docstring that
restates the signature is noise — delete it.

### Types

Annotate public APIs. `X | None`, never a bare default of `None` on a
non-optional type. Skip annotations on `self`, `cls`, and `__init__`'s return.
Pydantic schemas and FastAPI route signatures are fully annotated — they are the
API contract.

### async

Nothing blocking inside `async def`. A synchronous DB call, a synchronous HTTP
request, or `time.sleep` in a coroutine stalls the whole event loop for every
other request. Use the async client, or push it to a thread with
`run_in_executor` / `anyio.to_thread`.

### Things that are not allowed

- Mutable default arguments. Use `b: list[int] | None = None` and fill it in.
- `assert` for validating input or preconditions. Raise `ValueError` /
  `HTTPException`. Asserts vanish under `-O`.
- Mutable module-level state. Constants are fine, `CAPS_WITH_UNDER`.
- Metaclasses, `getattr` reflection, import hacks, `eval`, `exec`, `__del__`.
  `dataclasses`, `enum`, and `abc` are fine — that's the stdlib doing it for
  you, once, correctly.
- New runtime dependencies without asking. `requirements.txt` is a shared cost.

### Logging

Module logger, never `print`. Never log tokens, JWTs, emails, or raw
coordinates tied to a user.

## Dart / Flutter

Follows Effective Dart plus the lints already on in
`frontend/analysis_options.yaml`: return types declared, single quotes,
`prefer_final_fields`, `unawaited_futures`, `cancel_subscriptions`,
`close_sinks`.

- `UpperCamelCase` for types, `lowerCamelCase` for members and locals,
  `lowercase_with_underscores` for files and directories.
- `final` by default. `var` when it genuinely rebinds. `const` on every widget
  and constructor that can take it — it's a rebuild you don't pay for.
- Colours, spacing, and type come from `lib/core/theme.dart`. See
  **Design tokens** below — this is the rule agents get wrong most often.
- Keep layers where they are: `screens/` renders, `providers/` holds state,
  `services/` talks to the network, `models/` are data. A screen file that
  builds an HTTP request is in the wrong place.
- Generated files (`*.g.dart`, `*.freezed.dart`, `*.mocks.dart`) are never
  hand-edited; they are excluded from analysis for that reason.
- No new pub dependency without asking.

### Design tokens

Full protocol, migration plan, and the `Colors.*` mapping table:
[`docs/frontend_design_system.md`](docs/frontend_design_system.md). Read it
before converting anything. The short version:

**UI code names a role. It never names a value.**

```dart
Colors.grey                     // ✗ names a colour — frozen, ignores theme
SnowtrakColors.textSecondary    // ✗ right role, wrong layer — a const can't change
context.colors.textSecondary    // ✓
```

`lib/core/theme.dart` has three layers: `SnowtrakColors` (raw ramp, read by
`theme.dart` only), `SnowtrakPalette` (semantic roles), and `context.colors`
(those roles resolved for the active mode — **this is the one UI code reads**).
Tokens mirror `pencil_assets/Snowtrak_DesignSystem.fig`, page `12 layout now`.

| You want | Use |
|---|---|
| CTA, FAB, active nav, heading | `context.colors.primary` |
| Text on `primary` | `context.colors.textOnPrimary` |
| Surfaces | `background` (page), `surface` (cards), `surfaceVariant` (tiles) |
| Text, most to least prominent | `textPrimary`, `textSecondary`, `textTertiary`, `textQuaternary` |
| Lines | `divider`, `border` |
| Status meaning | `success`, `warning`, `error`, `info`, `live` |
| Overlays and shadows | `scrim`, alpha applied at the call site |
| Activity type | `SnowtrakColors.alpine`, `crossCountry`, … — data, not chrome, so mode-invariant |

Colour is only allowed to *mean* something. Decorative colour — a gradient, a
banner, a badge picked because it looked nice — resolves to the neutral ramp.

A literal `Color(0xFF...)`, or a Material `Colors.grey` / `.white` / `.black`,
is a bug anywhere outside `theme.dart` — with three exceptions.
(`Colors.transparent` is fine: it isn't a colour, it's the absence of paint.)

**The three legitimate exceptions, all outside `screens/`:**

1. `core/theme.dart` itself. That is the definition.
2. Third-party brand marks. The Google `G` in `ui/liquid/auth_social_button.dart`
   is `4285F4/34A853/FBBC05/EA4335` because Google's brand guidelines require
   those exact values. Never tokenise someone else's logo.
3. Developer-only surfaces, like the debug log overlay in
   `core/logging/app_logger.dart`.

**The conversion is done, and a test keeps it that way.** Every call site in
`lib/` reads `context.colors`; zero raw hex and zero Material colours remain
outside the three exceptions above. The guard test at
`frontend/test/core/design_system_guard_test.dart` fails the build on a new
one, and names the file and line.

That test is the authority, not this paragraph. If it trips, the fix is
essentially never to widen its allowlist.

`const` data that needs a role stores the **role** and resolves it at build
time — a `const` cannot read a `BuildContext`, and holding the `Color` instead
freezes it. See `ChallengeAccent` in `screens/groups/active_tab_widgets.dart`.

Needing a colour with no role is a design-system change, not a screen change.
Say so rather than inventing a hex.

## Security and visibility

Post visibility, follower relationships, and any other access rule are enforced
**server-side**. Filtering in the client to hide something is a privacy
incident, not a bug — the data already left the server. Every endpoint that
returns user content resolves the viewer's permission in the query.

Never touch `.env`, `postgres.env`, secrets, or anything
`scripts/check_secrets.sh` guards.

## Shell

`#!/usr/bin/env bash` and `set -euo pipefail` at the top of every script.
Quote every expansion (`"$var"`, `"$@"`). Prefer `$(...)` over backticks,
`[[ ]]` over `[ ]`. Functions are `lower_with_under`, constants and exported
env vars are `CAPS_WITH_UNDER`. If a script grows past ~100 lines or needs an
array of structs, rewrite it in Python.

## Markdown

80-column lines, ATX headings (`##`), one H1 per document. Fenced code blocks
with the language declared. Lazy numbering (`1.` repeated) for lists likely to
change. Link to repo files by relative path.

## JSON and API shapes

`snake_case` keys end to end — the Dart models mirror the Python schemas, so a
casing change is a two-sided break. Timestamps are ISO 8601 UTC. See
`docs/api_standardization.md` and `backend/shared/contracts.py`; a response
shape change means updating the contract test in the same commit.

## Comments and TODOs

Comment *why*, not *what*. Assume the reader knows the language.

```python
# TODO(#123): Drop the fallback once the map-backend v2 rollout completes.
```

Every TODO carries an issue number or a name. An unattributed TODO is a
comment that will never be resolved, so write it as a comment instead.

The `ponytail:` prefix marks a deliberate simplification and names its ceiling:

```python
# ponytail: linear scan; index it if the trail table passes ~10k rows.
```

## Tests

New logic ships with a test — the smallest thing that fails if the logic
breaks. Backend tests live in each service's `tests/`; contract tests for
cross-service shapes go through `shared/contract_tests.py`. Frontend tests live
in `frontend/test/`. No test for a one-line passthrough.

## Commits and PRs

[Conventional Commits](https://www.conventionalcommits.org/), scoped:

```
feat(community): add follower feed cursor
fix(map): clamp elevation lookups to tile bounds
docs(deploy): record the first production deploy
```

Types: `feat`, `fix`, `docs`, `refactor`, `perf`, `test`, `chore`, `ci`.
Scope is the service or feature area (`community`, `map`, `activity`, `auth`,
`deploy`, `follows`, …). Subject in the imperative, under ~72 characters, no
trailing period. Branch off `main`; see `docs/branch_policy.md` and
`.github/PULL_REQUEST_TEMPLATE.md`. Never commit or push unless asked.

The body is where the reasoning goes — why this shape, what was measured,
what was deliberately left out. The changelog cannot hold any of that.

## The changelog

`CHANGELOG.md` follows [Common Changelog](https://common-changelog.org):
releases only, no `Unreleased`, four groups in the order `Changed`, `Added`,
`Removed`, `Fixed`, one imperative line per change, and every line ends with a
link to its PR or commit.

That last rule means **the changelog is written after the commits**, from the
commits. Full rules and the reasons behind them: [changelog_style.md](docs/changelog_style.md).

## For agents specifically

1. Read before you write. The pattern probably already exists in this repo.
2. Smallest diff that works. No speculative abstraction, no interface with one
   implementation, no config for a value that never changes.
3. Do not add dependencies, do not restructure directories, do not rename
   things across the codebase without being asked.
4. Report honestly. If a check failed or you skipped part of the task, say
   which part and why.
