# Map Backend

FastAPI microservice for static map image generation and elevation data lookup for the Syntrak skiing application.

## 1. Purpose and scope

The Map Backend provides location-based utilities: generating static map images for activity recording and detail views, and enriching GPS coordinates with elevation data. This service acts as a facade over Google Maps (map images) and Open Elevation API (elevation lookup), reducing direct API calls from the frontend.

**Key responsibilities:**
- Static map generation (`/api/maps/*`)
- Elevation lookup for GPS coordinates (`/api/elevation/*`)
- JWT authentication and service integration
- Caching map images for offline access

## 2. Architecture overview

### High-level design

Map Backend is a lightweight FastAPI microservice that wraps external mapping APIs and exposes simplified endpoints for the Flutter frontend. It does not manage persistent data; instead, it acts as a pass-through with optional result caching.

```
Flutter Frontend (map_api.dart)
  ↓ HTTP POST (coordinates, zoom level)
Map Backend (/api/maps/*, /api/elevation/*)
  ↓ HTTPS
Google Maps Static API + Open Elevation API
  ↓
Static map image URL + elevation data
```

### Key design patterns

- **Facade pattern**: Wraps Google Maps and Open Elevation API behind simplified HTTP endpoints
- **Service locator**: External API credentials (API keys) managed centrally in config; credentials injected into service instances
- **Optional JWT auth**: Endpoints support optional authorization for tracking/billing purposes; unauthenticated requests allowed
- **Supabase coordination**: Can query Supabase for user preferences (saved map styles, zoom defaults) if needed in future

### Data contracts/models

**Static Map request:**
- `center_lat`, `center_lng`: Center point latitude/longitude
- `zoom`: Zoom level (1–21)
- `width`, `height`: Image dimensions in pixels (default: 600×400)
- `path`: Optional polyline of GPS coordinates to overlay on map
- `markers`: Optional array of marker locations

**Static Map response:**
- `url`: HTTPS URL to static map image
- `cache_key`: Optional identifier for offline caching

**Elevation Lookup request:**
- `locations`: Array of {latitude, longitude} objects (up to 1000 points)

**Elevation Lookup response:**
- `results`: Array of {latitude, longitude, elevation_meters} objects

**Elevation correction (`POST /api/elevation/correct`):**
- Request/response types live in `backend/shared/track_pipeline_schemas.py` as `ElevationCorrectionRequest` / `ElevationCorrectionResponse` (mirrors Dart `TrackPoint` and the map pipeline contract).
- Up to 512 points per call; returns the same track with `elevation_m` filled from the configured elevation API.

Canonical Pydantic models for the full track pipeline (`TrackPointIn`, `ProcessedTrackOut`, `SegmentOut`, `ActivityStatsOut`, `RunSummaryOut`, `TrailMatchRequest`/`Response`, `ActivityIn`/`Out`, etc.) also live in that shared module for use across services.

**Note:** Server-generated **dynamic map HTML** was removed; the mobile app renders maps natively.

### External integrations

- **Google Maps Static API** (https://maps.googleapis.com/maps/api/staticmap): Generates static map images with paths and markers
- **Open Elevation API** (https://api.open-elevation.com/api/v1/lookup): Bulk elevation data for coordinates
- **Supabase**: Optional coordination for user preferences (reserved for future use)

## 3. Code structure and key components

### File map

```
backend/map-backend/
├── domains/                    # Domain-owned API modules (active)
│   ├── activities_service/
│   ├── trails_service/
│   ├── elevation_dem_service/
│   ├── sync_worker_service/
│   └── README.md
├── main.py                     # FastAPI app setup, lifespan, startup hooks
├── config.py                   # Environment variables & settings
├── orm/                        # SQLAlchemy ORM for PostGIS (optional; see below)
│   ├── base.py
│   └── orm_models.py          # ski_runs, ski_lifts, activities, track_points, segments
├── services/
│   ├── openskimap_sync.py     # GeoJSON → map_trail.ski_runs (optional scheduled sync)
│   ├── storage_backend.py
│   └── supabase_client.py
├── engine/geometry/           # Legacy reference SQL (prefer Alembic under backend/db/)
│   ├── 001_init_postgis_storage.sql
│   └── 002_map_pipeline_tables.sql
├── middleware/
│   └── auth.py                # JWT extraction (optional auth)
├── CURL_TESTS.md              # Manual endpoint testing guide
├── LOCAL_SETUP.md             # Local development walkthrough
└── requirements.txt           # Python dependencies
```

### PostGIS ORM applicability

- **Requires PostGIS**:
  - Target database must have PostGIS enabled (`CREATE EXTENSION postgis;`)
  - Optional Docker service (`docker compose --profile postgis up postgis`) provides PostGIS
  - Plain Postgres without PostGIS cannot store `geometry` columns

- **Supabase compatibility**:
  - Supabase uses Postgres; enable PostGIS extension in the Supabase dashboard to support these tables

- **Schema organization**:
  - All map-related pipeline tables (`ski_runs`, `ski_lifts`, `activities`, `track_points`, `segments`) are in the `map_trail` schema
  - Prevents collisions with `public.activities` or other Supabase/activity-backend tables

- **Database migrations (Alembic/DDL)**:
  - From `backend/`, install dependencies: `psycopg`, `alembic`, `sqlalchemy`, `geoalchemy2`
  - Set environment variable: `SYNTRAK_DATABASE_URL=postgresql+psycopg://USER:PASS@HOST:PORT/DB`
  - Run migrations: `alembic upgrade head`
  - Migration files are in `backend/db/migrations/versions/`
  - If port **5432** is in use, set `POSTGRES_PORT` (see `postgres.env.example`) when starting Docker PostGIS

- **Standalone SQL initialization**:
  - `001_init_postgis_storage.sql` can be used instead of Alembic
  - Revision `001_initial` creates `map_cache_entries` and `elevation_samples` in `public` with GiST indexes

- **Database connection pool (`backend/db/connection.py`)**:
  - Module-level `_pool`: one global `asyncpg.Pool | None`, created at app startup if DSN is provided
  - `normalize_asyncpg_dsn(url)`: converts DSN by stripping the driver for asyncpg compatibility
  - `create_pool(...)`:
    - If `_pool` exists, does nothing (idempotent)
    - DSN order of precedence: argument → `SYNTRAK_DATABASE_URL` → no pool if unset
    - Uses `asyncpg.create_pool(...)` with config params
  - `close_pool()`: closes and clears `_pool` (run on app shutdown)
  - `get_pool()`: returns pool or None (if never created/no DB URL)
  - `get_db()` (FastAPI dependency):
    - Requires live pool or raises RuntimeError
    - Borrows a connection as a short-lived context (`async with pool.acquire() as connection`)
    - Yields the connection to the route, which auto-releases after use

- **App integration (`map-backend/main.py`)**:
  - Pool handled in FastAPI’s lifespan:
    - After `initialize_storage_backend()`
    - Pool creation logic:
      - If `SYNTRAK_DATABASE_URL` set: `await create_pool(dsn=dsn)`
      - Else if `MAP_STORAGE_BACKEND == "postgis"`: `await create_pool(dsn=config.postgis_dsn)`
      - Else: `await create_pool()` (may result in no pool if URL unset)
    - App serves traffic after pool is initialized (`yield`)
    - On shutdown: `await close_pool()`
    - Asyncpg pool is optional—if no DB URL, app runs without it and routes with `Depends(get_db)` will fail

- **Python import path and Docker**:
  - Local: `main.py` extends `sys.path` to include `backend/` if needed
  - Docker: `db/` is placed alongside app to ensure imports like `from db.connection import ...` work

- **Using the DB pool in a FastAPI route** (pattern, not yet in use):
  ```python
  from fastapi import Depends
  from db.connection import get_db
  import asyncpg

  @router.get("/example")
  async def example(conn: asyncpg.Connection = Depends(get_db)):
      row = await conn.fetchrow("SELECT 1 AS n")
      return {"n": row["n"]}
  ```
  - `get_db` is an async generator dependency: yields connection to handler, then releases it back after use

- **Comparison: asyncpg vs. SQLAlchemy/Alembic**:
  - Alembic/GeoAlchemy2: migrations, ORM metadata (typically uses sync driver e.g. `psycopg`)
  - asyncpg pool: used for async, runtime SQL (e.g. raw queries, spatial operations) without blocking
  - Both can access the same Postgres DB; asyncpg just normalizes URL differently

- **OpenSkiMap GeoJSON sync (`services/openskimap_sync.py`)**:
  - OpenSkiMap’s site uses vector tiles from `tiles.openskimap.org` (see [openskimap.org front-end](https://github.com/russellporter/openskimap.org)); bulk GeoJSON is not published as a single daily file on that CDN, so you typically host output from [openskidata-processor](https://github.com/russellporter/openskidata-processor) (`prepare-geojson`) or another FeatureCollection of run lines.
  - `download_geojson(url=...)`: HTTPS fetch; defaults to `OPENSKIMAP_RUNS_GEOJSON_URL`; appends a date `v=YYYYMMDD` query param for cache busting.
  - `parse_runs(geojson)`: keeps `LineString` features and the longest line from `MultiLineString`; reads `name` / `piste:difficulty`-style properties and a stable `source_id` for upserts.
  - `upsert_to_postgis(conn, runs)`: `INSERT ... ON CONFLICT (source_id) DO UPDATE` into `map_trail.ski_runs` (requires Alembic revision `002_ski_runs_source` for the `source_id` column + unique index).
  - When **both** `OPENSKIMAP_SYNC_ENABLED=true` and a non-empty `OPENSKIMAP_RUNS_GEOJSON_URL` are set (`openskimap_sync_armed` on `Config`), `main.py` registers an **APScheduler** `AsyncIOScheduler` (UTC) job at **03:00** daily. Enabling sync without a URL fails **Pydantic** validation at startup.
  - **Manual first ingest:** `backend/scripts/run_initial_sync.py` — loads env, then either fetches a URL (`sync_ski_runs_from_openskimap`) or reads a local file with `--file` (`sync_ski_runs_from_geojson_file`). Prints `COUNT(*)` on `map_trail.ski_runs` and a sample `ST_DWithin` query. Does not require `OPENSKIMAP_SYNC_ENABLED`. Local test files: put GeoJSON under `backend/data/` (gitignored). Example: `./.venv/bin/python backend/scripts/run_initial_sync.py --file backend/data/runs.geojson`.

### Entry points

- **main.py**: Initializes FastAPI app, registers routes, starts ASGI server on port 5200
- **domains/elevation_dem_service/api.py**: Defines `POST /elevation/correct` (Copernicus DEM correction)
- **domains/trails_service/api.py**: Defines trail matching and resort GeoJSON endpoints
- **domains/activities_service/api.py**: Defines map activity persistence/read endpoints

### Critical logic

1. **DEM elevation correction** (`/elevation/correct`): Corrects track point elevations using Copernicus DEM tiles with response caching.
2. **Trail matching** (`/trails/match`): Maps descent segments to named ski runs in `map_trail.ski_runs`.
3. **Resort GeoJSON** (`/trails/resort`): Returns vector line features for runs in a requested bounding box.
4. **Activity persistence** (`/activities*`): Stores and retrieves processed tracks, points, segments, and stats.

### Configuration

Environment variables (set via `.env` or deployment config):
- `MAP_STORAGE_BACKEND`: `supabase` (default) or `postgis`
- `GOOGLE_MAPS_API_KEY`: Google Maps Static API key
- `OPEN_ELEVATION_API_URL`: Open Elevation API endpoint (default: https://api.open-elevation.com/api/v1/lookup)
- `JWT_SECRET`: Shared secret for token validation (from deployment config)
- `HOST`, `PORT`: Server bind address (default: 127.0.0.1:5200)
- `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`: Required when `MAP_STORAGE_BACKEND=supabase`
- `POSTGIS_DSN` or `POSTGIS_HOST/PORT/DB/USER/PASSWORD`: Used when `MAP_STORAGE_BACKEND=postgis`

## 4. Development and maintenance guidelines

### Setup instructions

1. **Install and run:**
   ```bash
  # From repository root
  python3.11 -m venv .venv
  ./.venv/bin/pip install -r backend/requirements.txt

  cd backend/map-backend
  ../../.venv/bin/python -m pip install -r requirements.txt
   cp .env.example .env
   # Edit .env: set GOOGLE_MAPS_API_KEY, OPEN_ELEVATION_API_URL, JWT_SECRET
  ../../.venv/bin/python main.py
   ```

2. **Obtain API credentials:**
   - Google Maps Static API: Create project in Google Cloud Console, enable Static Maps API, generate API key
   - Open Elevation API: Free service; no key required (but rate-limited; optional fallback to paid elevation service)

### Testing strategy

- Unit tests for map URL construction and elevation request batching
- Integration tests against live Google Maps and Open Elevation APIs (use test coordinates)
- Manual curl tests in CURL_TESTS.md for endpoint verification

**Run tests:**
```bash
pytest tests/
pytest tests/ -v --tb=short  # Verbose output
```

### Code standards

- Service classes encapsulate external API calls (separation of concerns)
- Routes handle HTTP marshaling; services handle business logic
- Config.py centralizes all environment variable loading
- Shared auth middleware via `backend/shared/auth.py` (consistent token validation)

### Common pitfalls

- **Google Maps API key leakage**: Never commit `.env` file; rotate keys if accidentally exposed
- **Elevation API rate limits**: Batch requests and implement retry logic; consider caching results
- **Coordinate validation**: Ensure latitude (-90..90) and longitude (-180..180) are valid before sending to external APIs
- **Cache invalidation**: If caching elevation results, set TTL appropriately (e.g., 7 days for static terrain)

### Logging and monitoring

- Logs: Standard Python logging to stdout
- Key log points: External API calls (request/response), rate limit hits, authentication errors
- Monitor: External API latency, cache hit ratio, token validation failures

## 5. Deployment and operations

### Build and deployment

```bash
# Local Docker build
docker build -t syntrak-map-backend:latest .

# Via docker-compose from backend root
cd backend
docker-compose up -d syntrak-map-backend

# Run map-backend with local PostGIS storage ownership
MAP_STORAGE_BACKEND=postgis docker-compose up -d postgis map-backend

# Optional: initialize local map storage tables
psql "postgresql://syntrak:syntrak_local_dev@localhost:5432/syntrak" \
  -f map-backend/engine/geometry/001_init_postgis_storage.sql
```

Service runs on port 5200 and communicates with Google Maps and Open Elevation API over HTTPS.

### Runtime requirements

- Python 3.11+ (FastAPI, Pydantic)
- Internet access to Google Maps Static API and Open Elevation API (HTTPS)
- Environment variables: `GOOGLE_MAPS_API_KEY`, `JWT_SECRET`
- Shared backend/shared/ directory for auth utilities

### Health checks

- **Liveness**: HTTP GET `/health` (returns 200 if service running)
- **Readiness**: Successful external API call (test static map or elevation endpoint)

### Backward compatibility

- Static map endpoint response format (URL + cache_key) should remain stable
- Adding optional parameters to elevation request is non-breaking
- Version API if major contract changes needed (e.g., elevation units)

## 6. Examples and usage

### Generate static map image

```bash
curl -X POST http://localhost:5200/api/maps/static \
  -H "Content-Type: application/json" \
  -d '{
    "center_lat": 39.2847,
    "center_lng": -106.5007,
    "zoom": 13,
    "width": 600,
    "height": 400
  }'
```

Response:
```json
{"url": "https://maps.googleapis.com/maps/api/staticmap?..."}
```

### Generate map with activity path overlay

```bash
curl -X POST http://localhost:5200/api/maps/static \
  -H "Content-Type: application/json" \
  -d '{
    "center_lat": 39.2847,
    "center_lng": -106.5007,
    "zoom": 13,
    "path": [
      {"lat": 39.2847, "lng": -106.5007},
      {"lat": 39.2848, "lng": -106.5006},
      {"lat": 39.2850, "lng": -106.5005}
    ]
  }'
```

### Lookup elevation for GPS points

```bash
curl -X POST http://localhost:5200/api/elevation/lookup \
  -H "Content-Type: application/json" \
  -d '{
    "locations": [
      {"latitude": 39.2847, "longitude": -106.5007},
      {"latitude": 39.2848, "longitude": -106.5006}
    ]
  }'
```

Response:
```json
{
  "results": [
    {"latitude": 39.2847, "longitude": -106.5007, "elevation_meters": 3208},
    {"latitude": 39.2848, "longitude": -106.5006, "elevation_meters": 3205}
  ]
}
```

### Simple single-point elevation

```bash
curl "http://localhost:5200/api/elevation/point?lat=39.2847&lng=-106.5007"
```

## 7. Troubleshooting and FAQs

### Common errors

**403 Forbidden (Google Maps API)**: Invalid or restricted API key
- Check: Google Maps API key is correct and has Static Maps API enabled
- Check: API key has appropriate usage restrictions (IP allowlist, referrer domain)
- Check: Quota not exceeded in Google Cloud Console

**429 Too Many Requests (Open Elevation)**: Rate limit exceeded
- Implement exponential backoff for retries
- Cache elevation results (TTL 7 days)
- Consider upgrade to paid elevation API if frequent lookups needed

**Invalid coordinates**: Latitude or longitude out of range
- Ensure latitude is -90..90 and longitude is -180..180
- Check for null or NaN values in GPS data

### Debugging tips

- Use Google Maps Static API URL builder (https://mapsplatform.google.com/maps-products/#static-maps) to test API calls directly
- Trace elevation requests via logs; compare against Open Elevation API documentation
- Test with fixed test coordinates to isolate frontend vs. backend issues

### Performance tuning

- Cache static map URLs for repeated center/zoom/path combinations (Redis or Supabase)
- Batch elevation requests to minimize API calls (supported by Open Elevation API batch endpoint)
- Consider CDN (CloudFront, Cloudflare) for static map image caching
- Monitor Google Maps API costs; implement request rate limiting if budget needed

## 8. Change log and versioning

### Recent updates

- **2024-01**: Initial FastAPI service with static map and elevation endpoints
- **2024-02**: Added optional JWT authentication for usage tracking
- **2024-03**: Integrated Open Elevation API as primary elevation provider

### Version compatibility

- Map Backend v1 expects: static map requests with {center_lat, center_lng, zoom, width, height}; elevation requests with {locations: [{latitude, longitude}]}
- Frontend expects map-backend running on port 5200 via app configuration (app_config.dart)
- Shared backend services (auth) imported from `backend/shared`
