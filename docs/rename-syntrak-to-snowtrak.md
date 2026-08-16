# Rename: Syntrak → Snowtrak

The product is **Snowtrak**. The codebase was originally named `syntrak`, and the
two names still coexist. This document records what has been renamed, what has
been deliberately deferred, and the exact steps each deferred item needs.

Deferred items are deferred because renaming them touches running
infrastructure or an external identity, not because they were missed.

## Done

| Scope | Change |
|---|---|
| Dart package | `pubspec.yaml` `name: syntrak` → `snowtrak`; 538 `package:syntrak/` imports rewritten across 155 files |
| Dart identifiers | `SyntrakApp`, `SyntrakTheme`, `SyntrakColors`, `SyntrakTypography`, `SyntrakSpacing` → `Snowtrak*` |
| iOS display name | `CFBundleDisplayName` → `Snowtrak`, `CFBundleName` → `snowtrak` |
| Android display name | `android:label` → `Snowtrak` |
| UI strings | `'SynTrak'` label in `lib/screens/groups/active_tab.dart` |
| Local log file | `systemTemp/syntrak-*.log.jsonl` → `snowtrak-*.log.jsonl` |
| IDE module | `frontend/syntrak.iml` → `frontend/snowtrak.iml` |
| Docker containers | `syntrak-redis`, `syntrak-postgis`, `syntrak-{main,map,activity,community}-backend` → `snowtrak-*` |
| Prose | READMEs, `docs/`, playbooks, backend docstrings |
| Clone URLs | The GitHub repository was already renamed to `Syntraksoftware/Snowtrak`; docs still pointed at `syntrak-application` and relied on GitHub's redirect |

Verified: `dart analyze lib test` reports 0 errors and 0 warnings; all backend
suites pass (157 passed, 1 skipped).

Container renames take effect on the next `docker compose down && docker compose up -d`.
Old containers keep the previous names until recreated.

## Deferred — environment variables

**Why deferred:** these names are read from the deployed environment. Renaming
them in code without updating the VPS `.env` and the GitHub Actions secrets in
the same deploy leaves the backend unable to reach Postgres.

| Variable | Occurrences |
|---|---|
| `SYNTRAK_DATABASE_URL` | 39 |
| `SYNTRAK_DEM_CACHE_DIR` | 4 |

Read sites that actually matter (the rest are docs and comments):

- `backend/db/connection.py:48` — `os.environ.get("SYNTRAK_DATABASE_URL")`
- `backend/db/migrations/env.py:30` — Alembic offline/online URL
- `backend/map-backend/config.py:35` — Pydantic settings field
- `backend/map-backend/application.py:119` — pool DSN resolution
- `backend/scripts/run_initial_sync.py:88`
- `backend/map-backend/services/dem_service.py:42` — `SYNTRAK_DEM_CACHE_DIR`

**Recommended migration (no downtime):**

1. Change each read site to prefer the new name and fall back to the old one:
   ```python
   dsn = os.environ.get("SNOWTRAK_DATABASE_URL") or os.environ.get("SYNTRAK_DATABASE_URL")
   ```
   For `map-backend/config.py`, add a `SNOWTRAK_DATABASE_URL` field and resolve
   it ahead of the existing one.
2. Deploy. Nothing breaks — the old variable is still honoured.
3. Add `SNOWTRAK_DATABASE_URL` to the VPS `.env`, `backend/deploy/env/*.env`,
   and GitHub Actions secrets. Leave the old one in place.
4. Confirm the services read the new variable, then remove the fallback and the
   old variable in a follow-up commit.

Also update when this lands: `backend/deploy/env/production.env.example:15`,
`backend/map-backend/.env.example:15`, `backend/postgres.env.example:2`,
`backend/alembic.ini:89-90`, and the `SYNTRAK_DATABASE_URL` mentions in
`backend/db/migrations/README.md`, `docs/vps_setup.md`,
`docs/playbook/map-flow/README.md`, and `docs/playbook/nivus-trail-server.md`.

Note `docs/playbook/nivus-trail-server.md:63` — Nivus accepts either
`NIVUS_DATABASE_URL` or `SYNTRAK_DATABASE_URL`. Nivus lives outside this
repository, so its side has to be updated separately.

## Deferred — database and infrastructure names

**Why deferred:** these name live data and running processes.

| Item | Location | What renaming costs |
|---|---|---|
| `POSTGRES_USER=syntrak` | `backend/postgres.env{,.example}:8` | `ALTER ROLE` on the local PostGIS instance |
| `POSTGRES_DB=syntrak` | `backend/postgres.env{,.example}:10` | `ALTER DATABASE`, or drop and re-migrate |
| `POSTGRES_PASSWORD=syntrak_local_dev` | `backend/postgres.env{,.example}:9` | Local dev credential only |
| `sqlalchemy.url = …syntrak:syntrak_local_dev@…/syntrak` | `backend/alembic.ini:93` | Must match the role/database above |
| `syntrak:activity-pipeline` | `backend/activity-backend/config.py:38` | Redis stream key — a rename orphans in-flight messages |
| `/srv/syntrak-application` | `backend/deploy/bootstrap_droplet.sh:5`, `docs/developer_handoff.md:74,84`, `docs/playbook/map-backend_beta.md:22`, `docs/vps_setup.md:88` | VPS checkout path; needs a move plus a systemd/Caddy update. `docs/vps_setup.md` now clones the renamed repo into this directory explicitly (`git clone …/Snowtrak.git syntrak-application`) so the documented path still matches the server. |
| `~/.ssh/syntrak_do_ed25519` | `docs/developer_handoff.md:32,38` | Local SSH key filename on each developer's machine |
| `$XDG_CACHE_HOME/syntrak/dem_glo30` | `backend/map-backend/services/dem_service.py:41` | Re-downloads the DEM tile cache |

These are all internal identifiers. None is visible to users, so the rename buys
consistency rather than correctness. Batch it with the environment-variable work
above if it is done at all.

## Deferred — external identity

**Do not change without a deliberate decision.**

| Item | Location | Consequence |
|---|---|---|
| `com.syntrak.snowtrak.app` | `frontend/ios/Runner.xcodeproj/project.pbxproj` (×5), `frontend/ios/fastlane/Appfile:1` | The bundle ID **is** the App Store app identity. Changing it creates a new app: existing App Store/TestFlight records, testers, provisioning profiles, and installed-app upgrade paths are all lost. |
| `com.syntrak.snowtrak.app.RunnerTests` | `project.pbxproj` (×3) | Must stay consistent with the app bundle ID |
| `*.syntrak.io` (8 hosts) | `frontend/lib/core/config/app_config.dart:112-123` | Live staging and production API hostnames — see the DNS state below. |
| `support@syntrak.app` | `frontend/lib/screens/settings/help_support_screen.dart:144` | Requires a working mailbox on the new domain before switching |

The bundle ID already contains both names (`com.syntrak.snowtrak.app`), so the
product name is correct in the part users see. Leaving it alone costs nothing.

### DNS state

Measured while preparing this document:

| Host | A record | Notes |
|---|---|---|
| `main.syntrak.io` | `167.172.140.49` | The production VPS (`docs/developer_handoff.md:32`). `/health` returns 200. |
| `activity.syntrak.io`, `staging-main.syntrak.io` | `167.172.140.49` | Same host |
| `syntrak.app`, `main.syntrak.app` | none | Domain does not resolve |
| `snowtrak.app` | `104.21.27.34`, `172.67.168.221` | Cloudflare; apex returns 200. No API subdomains exist. |
| `snowtrak.io` | none | Not registered or not configured |

Two consequences:

1. **`*.syntrak.io` is the live API and must not be renamed yet.** `snowtrak.io`
   does not resolve at all.
2. **`syntrak.app` is dead.** Anything still pointing at it is broken, not merely
   inconsistent. `docs/playbook/auth-flow/README.md` was updated to `.io` for
   this reason.

If the domain rename is wanted later, `snowtrak.app` is the realistic target
since it is already registered. It needs the four API subdomains
(`main`, `activity`, `community`, `map`, plus `staging-*`) pointed at
`167.172.140.49`, Caddy vhosts added, TLS issued, and the backend
`ALLOWED_ORIGINS` updated — then `app_config.dart` last.

## Checking progress

```bash
# remaining references, excluding generated output
grep -rniI "syntrak" backend docs scripts packages .github README.md frontend \
  | grep -vE "graphify-out|frontend/build|\.dart_tool|\.test-venv|coverage\.xml"
```
