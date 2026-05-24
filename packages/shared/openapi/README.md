# OpenAPI artifacts for shared contracts

Checked-in OpenAPI JSON for each backend service. Used for frontend codegen, contract review, and CI diffs.

| File | Service | Canonical prefix |
|------|---------|------------------|
| `openapi-main.json` | main-backend | `/api/v1` |
| `openapi-activity.json` | activity-backend | `/api/v1` |
| `openapi-community.json` | community-backend | `/api/v1` |
| `openapi-map.json` | map-backend | `/api/v1/map` |

## Refresh snapshots

From repo root (no running servers required):

```bash
backend/scripts/export_openapi.sh
```

This runs `backend/scripts/generate_openapi_snapshots.py`, which builds each FastAPI app factory and writes filtered canonical schemas.

Live Swagger UI remains at `http://localhost:<port>/docs` when services are running. See [docs/api_standardization.md](../../docs/api_standardization.md).

## When to update

- After adding, renaming, or removing `/api/v1/*` routes
- Before merging API-facing PRs (include snapshot diff in review)
