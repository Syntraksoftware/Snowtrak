API standardization
====================

Syntrak backends expose a single canonical **`/api/v1/*`** contract. Legacy paths have been removed.

---

Canonical surface by service

| Service | Port (local) | Canonical prefix | Swagger UI | OpenAPI JSON |
|---------|--------------|------------------|------------|--------------|
| main-backend | 8080 | `/api/v1/*` | http://localhost:8080/docs | http://localhost:8080/openapi.json |
| activity-backend | 5100 | `/api/v1/activities` | http://localhost:5100/docs | http://localhost:5100/openapi.json |
| community-backend | 5001 | `/api/v1/feed`, `/api/v1/posts`, … | http://localhost:5001/docs | http://localhost:5001/openapi.json |
| map-backend | 5200 | `/api/v1/map/*` | http://localhost:5200/docs | http://localhost:5200/openapi.json |

Map routes:

| Route | Method | Purpose |
|-------|--------|---------|
| `/api/v1/map/elevation/correct` | POST | Copernicus DEM elevation correction |
| `/api/v1/map/trails/match` | POST | GPS track → trail segments |
| `/api/v1/map/trails/resort` | GET | Resort trail GeoJSON |
| `/api/v1/map/activities` | POST/GET | Map activity persistence |
| `/api/v1/map/activities/{id}` | GET/PUT/DELETE | Single map activity |

---

Where Swagger / OpenAPI lives

**Live (runtime)**

Each FastAPI service generates OpenAPI at boot:

- **Swagger UI:** `http://localhost:<port>/docs`
- **ReDoc:** `http://localhost:<port>/redoc`
- **Raw JSON:** `http://localhost:<port>/openapi.json`

The generator is configured in `backend/shared/openapi_canonical.py` and wired in each service entry point (`main.py` / `application.py`). It filters the schema to canonical `/api/v1/*` paths only.

**Checked-in snapshots (for CI / codegen)**

Static copies live under [`packages/shared/openapi/`](../packages/shared/openapi/):

| File | Service |
|------|---------|
| `openapi-main.json` | main-backend |
| `openapi-community.json` | community-backend |
| `openapi-activity.json` | activity-backend |
| `openapi-map.json` | map-backend |

Refresh all snapshots (no running servers required):

```bash
backend/scripts/export_openapi.sh
```

Implementation: `backend/scripts/generate_openapi_snapshots.py`.

---

Frontend configuration

Map API base URL includes the v1 prefix (`frontend/lib/core/config/app_config.dart`):

```
http://localhost:5200/api/v1/map   # dev
```

Engine clients use relative paths (`/elevation/correct`, `/trails/match`, …) because the base URL already carries `/api/v1/map`.

---

Deprecating routes later

When phasing out a path, attach `backend/shared/deprecation.py` middleware with a sunset config and run the unit tests in `backend/tests/test_deprecation_middleware.py` as a reference.

Example:

```python
from shared.deprecation import add_deprecation_middleware

add_deprecation_middleware(app, {
    "/api/v1/old-path": {
        "sunset_date": "Sun, 21 Dec 2026 00:00:00 GMT",
        "replacement": "/api/v1/new-path",
        "message": "Use /api/v1/new-path instead.",
    },
})
```

---

Related

- Client feed cache + Redis rate limiting: [client_feed_cache_and_rate_limiting.md](./client_feed_cache_and_rate_limiting.md)
- VPS bootstrap script: [backend/deploy/bootstrap_droplet.sh](../backend/deploy/bootstrap_droplet.sh)
- Map backend beta/staging note: [playbook/map-backend_beta.md](./playbook/map-backend_beta.md)
