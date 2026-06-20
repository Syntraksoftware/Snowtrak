# Map-backend domain packages

Modular boundaries for the map geospatial service (`map-backend`, port 5200).

## Service split (map-backend vs theta)

| Responsibility | Owner |
|----------------|-------|
| DEM elevation correction | `elevation_dem_service` |
| Resort ski-run GeoJSON (MapLibre overlay) | `trails_service` |
| Map activity persistence (`map_trail.*`) | `activities_service` |
| OpenSkiMap ingest | `sync_worker_service` |
| **Track pipeline math + trail matching** | **theta trail server** (separate repo) |

The mobile app calls **Nivus** for post-processing:

```
POST http://<theta-host>:5201/api/v1/pipeline/process
```

## Domain packages

| Package | HTTP routes | Infra |
|---------|-------------|-------|
| `elevation_dem_service` | `POST /elevation/correct` | Copernicus DEM provider |
| `trails_service` | `GET /trails/resort` | PostGIS read (`queries.py`, `geojson.py`) |
| `activities_service` | `POST/GET/DELETE /activities` | `map_trail` persistence |
| `sync_worker_service` | (scheduled job) | OpenSkiMap GeoJSON upsert |

## Layering rules

```
api.py       → HTTP handlers, validation, response mapping
ports.py     → contracts injected at startup (`application.py`)
infra.py     → default DB/external implementations
queries.py   → raw SQL (trails_service)
```

- Domain packages must **not** import each other.
- Shared API types: `backend/shared/track_pipeline_schemas.py`
- Composition root: `application.py` wires port providers → infra

## Extending a domain

1. Add SQL or provider logic in `infra.py` (or a focused module like `queries.py`).
2. Expose a contract in `ports.py` if tests need to swap implementations.
3. Keep `api.py` thin — no direct `services.*` imports (enforced by `test_architecture_rules.py`).

## Removed from map-backend

`POST /trails/match` and `services/trail_matcher.py` were removed. Trail matching now lives only in the **theta** trail server to keep a single pipeline endpoint for clients.
