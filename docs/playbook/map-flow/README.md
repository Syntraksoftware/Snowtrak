# Map flow

How location data moves from capture through processing to map surfaces and supporting APIs.

## Purpose

This document is the short operational view of the map pipeline. Use it when wiring recording, imports, analytics, or map-backend calls. For a full UI and storage plan, see `frontend/docs/map.md`. For HTTP contracts and deployment of static maps and elevation, see `backend/map-backend/README.md`.

## Engines

The numbered engines are logical stages in the client-side track pipeline (implementations may live in `frontend/lib/map/` or dedicated modules). Each stage has a clear contract: inputs and outputs are defined by the Dart models below (and mirrored in `backend/shared/track_pipeline_schemas.py`).


| Engine | Serves                                                                                                                                                                                                                                                                                                 | Primary output (contract)                                   |
| ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------- |
| **1**  | **Normalization** — turn raw recordings or file imports into one consistent time-ordered track: stable units, cleaned points, identity and provenance (`gpx` / `fit` / `live`).                                                                                                                        | `ProcessedTrack`                                            |
| **2**  | **Segmentation** — classify motion along the track (descent, lift, flat, pause), slice the point list with `startIndex` / `endIndex`, optional trail/difficulty hints for matching.                                                                                                                    | `List<Segment>`                                             |
| **3**  | **Activity analytics** — activity-level totals and per-descent rollups for summaries, lists, and skiing-oriented metrics (distance, vertical, speeds, moving time, trail count).                                                                                                                       | `ActivityStats` + `List<RunSummary>`                        |
| **4**  | **Downstream product logic** — anything that needs a normalized track plus segments and/or stats but is not chart-specific (e.g. trail matching responses, social or resort features, exports). Concrete outputs are feature-specific; inputs are typically `ProcessedTrack` and Engine 2–3 artifacts. | (per feature; e.g. [trail-matcher.md](./trail-matcher.md), trail match contracts in shared schemas) |
| **5**  | **Elevation visualization** — data shaped for `fl_chart`: distance vs elevation samples, min/max elevation, and lift intervals along the horizontal axis for shaded bands.                                                                                                                             | `ElevationChartData`                                        |


**map-backend** is not an engine: it supplies **static map images** and **elevation correction/lookup** HTTP APIs so the app can enrich geometry without shipping provider keys in the client.

## Data contracts (Dart)

Canonical types live under `frontend/lib/models/`:


| Model                | Role                                                                                                                                                                                                                   |
| -------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `TrackPoint`         | One GPS sample: latitude/longitude, elevation, time, speed, optional per-point segment hint (`PointSegmentType`).                                                                                                      |
| `ProcessedTrack`     | **Engine 1 output** : normalized track: `id`, `points`, `recordedAt`, `SourceType` (`gpx`, `fit`, `live`). Feeds **Engines 2, 4, and 5**.                                                                              |
| `Segment`            | **Engine 2 output** : classified slice: `type` (`SegmentType`: descent, lift, flat, pause), `points`, `startIndex` / `endIndex` into the parent track, optional `trailName` / `difficulty`.                            |
| `ActivityStats`      | **Engine 3 output** : activity totals — `totalDistanceKm`, `totalVerticalDropM`, `topSpeedKmh`, `avgSpeedKmh`, `movingTime`, `trailCount` (distinct trails touched in the activity).                                   |
| `RunSummary`         | **Engine 3 output** : one row per descent — distance, vertical drop, speeds, `movingTime`, optional `trailName`.                                                                                                       |
| `ElevationChartData` | **Engine 5 output** : data for `fl_chart` — `spots` (`List<FlSpot>`, distance vs elevation), `liftBandRanges` (list of `(start, end)` along the horizontal axis, as `LiftBandRange` records), `minElevM` / `maxElevM`. |


- **Point:** Refers to a single `TrackPoint` object, which represents an individual GPS sample (latitude, longitude, elevation, timestamp, etc.) as defined in `frontend/lib/models/track_point.dart`.
- Continuous movement or a trajectory is represented as a series of `TrackPoint` objects.
- `PointSegmentType` on `TrackPoint` is a lightweight hint before Engine 2; `SegmentType` on `Segment` is the Engine 2 classification (different enum values on purpose).
- `**liftBandRanges`**: Ranges along the elevation chart marking sections where the user was on a lift; used to highlight lift rides on route profiles (vertical displacement).

## Processing pipeline (conceptual)

```text
Raw samples / file parse (GPX·FIT·live)
        → Engine 1: normalize → ProcessedTrack
        → Engine 2: classify runs/lifts/etc. → List<Segment>
        → Engine 3: aggregate stats → ActivityStats + List<RunSummary>
        → Engines 4 & 5: consume ProcessedTrack (and typically segments / stats); Engine 5 → ElevationChartData (`fl_chart` elevation + lift bands)
Map UI / polylines / stats read the same structures (or projections of them).
```

Implementations may live in `frontend/lib/map/` or dedicated services as the codebase grows; the **models define the boundaries** between stages.

## Map backend (separate concern)

**map-backend** does not own the Engine 1–5 pipeline. It provides **static map images** and **elevation** utilities over HTTP (Google Static Maps and the configured elevation API), so the app can enrich points or render previews without embedding keys in the client. See `backend/map-backend/README.md` for routes and env vars.

### HTTP routing (map-backend)

- **Main entry:** The FastAPI app is built by `backend/map-backend/application.py` (`create_app()`). **`backend/map-backend/main.py`** is what `run.py` / Docker use (`uvicorn main:app` from `map-backend/`). **`backend/main.py`** re-exports the same `app` for a unified entry from `backend/` (e.g. `python -m uvicorn main:app --host 127.0.0.1 --port 5200`).
- **Maps endpoints (`/api/maps`):**
  - `POST /api/maps/static`: Get a static map URL (JSON).
  - `POST /api/maps/static/image`: Get a map image (bytes).
  - `GET /api/maps/static/simple`: Get a simplified static map.
- **Elevation endpoints (`/api/elevation`):**
  - `POST /api/elevation/correct`: Fix/fill elevations for multiple points.
  - `POST /api/elevation/lookup`: Lookup elevations for multiple points.
  - `GET /api/elevation/point`: Lookup elevation for one point.
  - **`POST /elevation/correct`** (Copernicus GLO-30 via `dem_service`, bbox-keyed response cache): see [dem-copernicus-glo30.md](./dem-copernicus-glo30.md).
- **Meta endpoints:** `GET /` shows service info; `GET /health` checks health and storage status.
- **Background task (not an HTTP endpoint):** OpenSkiMap GeoJSON sync runs on a **daily schedule** only when **`OPENSKIMAP_SYNC_ENABLED`** and **`OPENSKIMAP_RUNS_GEOJSON_URL`** are both set. There is no public HTTP route for the bulk file; imported runs live in PostGIS (`map_trail.ski_runs`).
- **Trails (`/trails`, PostGIS, needs DB pool):**
  - **`POST /trails/match`**: **`TrailMatchRequest`** → **`TrailMatchResponse`** (per-descent names on **`SegmentOut`**).
  - **`GET /trails/resort?bbox=min_lon,min_lat,max_lon,max_lat`**: GeoJSON **`FeatureCollection`** for **`map_trail.ski_runs`** (Engine 4 layer).
  - Details: [trail-matcher.md](./trail-matcher.md).


### Data download (who pulls what from where)
- App sends HTTPS JSON requests to map-backend (no full ski map is sent to the phone).
- Map-backend fetches map/elevation data from Google APIs (or others) using secure server keys; returns results to app or caches them.
#### Secure server keys (API credentials)
- Map-backend (when **both** OpenSkiMap env flags are set) daily downloads run GeoJSON from the configured URL, upserts `map_trail.ski_runs`, and does not push that bulk file to the app.
- Only the PostGIS database stores the ski run data; raw GeoJSON files are not needed in cloud storage unless team decides otherwise.


**PostGIS persistence (optional):** see **Alembic and map-related database** below.

## Alembic and map-related database

### What changed

- **Before:** PostGIS DDL lived mainly in raw SQL under `backend/map-backend/engine/geometry/` (`001_init_postgis_storage.sql` for cache/elevation tables, setting up database for storage; `002_map_pipeline_tables.sql` for ski runs, lifts, activities, track points, segments).
- **Now:** **Alembic** is the canonical way to create and evolve that schema. Revision `**001_initial`** (`backend/db/migrations/versions/001_initial_postgis_and_map_trail.py`) was added and `**alembic upgrade head`** applies everything in one transaction-aware flow. The old `002_*.sql` file is **not** the source of truth anymore (it only points at Alembic); you can still use `001_*.sql` as a human-readable reference for the public cache tables, but Alembic’s initial revision creates those tables too so a fresh DB only needs Alembic.

**Alembic**:

- Is used to manage changes to the database schema over time, allowing you to version, upgrade, or rollback database structures in a controlled, trackable way. 
- In this context, Alembic is used to create and evolve all map-related database tables and PostGIS extensions within the project, ensuring the schema stays in sync with code changes through migration scripts instead of raw SQL files.

### File locations: 


| Piece                         | Location                                                                                  |
| ----------------------------- | ----------------------------------------------------------------------------------------- |
| Alembic config                | `backend/alembic.ini` (`script_location` → `db/migrations`), root level                   |
| Migration env + revisions     | `backend/db/migrations/` (`env.py`, `versions/…`; `001_initial`, `002_ski_runs_source`)   |
| SQLAlchemy ORM (map geo)      | `backend/map-backend/orm/` (`orm_models.py` aligned with migrations)                      |
| Asyncpg pool + `get_db`       | `backend/db/connection.py` (opened in map-backend FastAPI `lifespan`)                     |
| OpenSkiMap-style GeoJSON sync | `backend/map-backend/services/openskimap_sync.py` (optional APScheduler job in `main.py`) |


`env.py` prepends `map-backend/` to `sys.path` and imports `Base` / ORM models from `orm` so metadata stays aligned with the Python definitions.

### How to run migrations

From `**backend/`**:

1. Install Python deps that include `**alembic**`, `**sqlalchemy**`, `**geoalchemy2**`, and `**psycopg**` (sync URL `postgresql+psycopg://…`).
2. In **Supabase** SQL Editor: `CREATE EXTENSION IF NOT EXISTS postgis;`
3. Set `**SYNTRAK_DATABASE_URL**` to your **Supabase direct Postgres** URI (`postgresql+psycopg://…`, typically `db.<ref>.supabase.co:5432`; see `backend/db/migrations/README.md`). This overrides `sqlalchemy.url` in `alembic.ini`.
4. Run `**alembic upgrade head**`.

Details and troubleshooting: `backend/db/migrations/README.md`. Optional **Docker PostGIS** (offline) uses `postgres.env` + `POSTGRES_PORT` if port **5432** is busy.

### Current database layout (map-related)

All of this requires the **PostGIS** extension (`CREATE EXTENSION postgis` — included in the initial revision).

**Schema `public` (map-backend operational cache, not the trail pipeline)**

- `**map_cache_entries`**  
  - Caches generated static map image URLs for requested map views.
  - Key columns:
    - `center`: `GEOGRAPHY(POINT, 4326)`, supports geospatial queries (has a GiST index).
    - `cache_key`: Uniquely identifies each cached map preview.
    - Stores info like zoom, dimensions, provider, URL, and expiry.
- `**elevation_samples`**  
  - Stores sampled elevation data for specific locations.
  - Key columns:
    - `location`: `GEOGRAPHY(POINT, 4326)`, indexed for fast spatial lookups (GiST).
    - `elevation_meters`: Altitude value in meters.
    - `source` & `sampled_at`: Records the data source and time of sample.
  - Ensures quick elevation lookups; deduplicates frequent queries.

*These tables are for caching and lookup efficiency in map-backend; all pipeline data lives under the `map_trail` schema.*

**Schema `map_trail` (resort geometry + recorded track pipeline — avoids name clashes)**

- Pipeline tables are **not** in `public` so they do not collide with `**public.activities`** (or similar) from Supabase / activity-backend.


| Table                    | Role                                                                                                                                         |
| ------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------- |
| `map_trail.ski_runs`     | Resort run polylines (`geometry(LINESTRING, 4326)` + GiST); optional `source_id` (unique) for bulk upserts (migration `002_ski_runs_source`) |
| `map_trail.ski_lifts`    | Lift polylines + GiST                                                                                                                        |
| `map_trail.activities`   | Session header: `user_id`, `recorded_at`, `stats` (JSONB)                                                                                    |
| `map_trail.track_points` | Samples: `geometry(POINTZ, 4326)`, `speed_kmh`, `segment_type` + GiST on `geom`                                                              |
| `map_trail.segments`     | Classified intervals: `type`, `start_idx`, `end_idx`, `trail_name`                                                                           |


- **GiST** is created on every geography/geometry column above so spatial predicates such as `**ST_DWithin`** can use an index.

> What is `ST_DWithin`?

- `[ST_DWithin](https://postgis.net/docs/ST_DWithin.html)` is a spatial SQL function provided by PostGIS (the geospatial extension for PostgreSQL).
- Determines whether two geometries (such as points, lines, or polygons) are within a specified distance of each other.
- Usage example: `ST_DWithin(geom1, geom2, distance_in_meters)` returns `TRUE` if `geom1` is within `distance_in_meters` of `geom2`.
- "Within a specified distance" means that one object (such as a point or line) is close enough to another object, as defined by a distance you provide. 
- For example, with `ST_DWithin`, you can ask: “Is this GPS point within 50 meters of this trail polyline?” If the answer is yes (the distance between them is less than or equal to 50 meters), the function returns `TRUE`.
- Used in mapping applications to quickly find features (like trails, lifts, or landmarks) that are near a given location, enabling fast spatial searches and matching.
- For map-backend, this is heavily used for:
  - Finding all trails or features within a radius of a GPS sample (for proximity-based searches)
  - Quickly matching points to polylines (e.g., determining if a recorded GPS track is "on" a given trail)
- Because `ST_DWithin` leverages GiST indexes on geometry/geography columns, these spatial queries are fast—even on large datasets.

### Asyncpg pool (runtime SQL)

- Uses a pool of TCP connections to Postgres for efficient query handling.
- Each HTTP request borrows a connection (`async with pool.acquire()`), runs SQL, then returns it.
- Main pool logic in `backend/db/connection.py`: `create_pool()`, `close_pool()`, `get_pool()`, `get_db()`, `normalize_asyncpg_dsn()`.
- FastAPI app lifecycle (`backend/map-backend/main.py`): pool created at startup (`create_pool()`), closed on shutdown.
- Connection provided to routes via FastAPI's dependency injection: `Depends(get_db)`.
- DSN handling: `normalize_asyncpg_dsn()` converts URLs for asyncpg compatibility.
- Docker image includes all DB connection code.
- Database schema migrations use Alembic/ORM, but API queries run as raw SQL via asyncpg (no SQLAlchemy session).


### Alembic `002_ski_runs_source` (`map_trail.ski_runs.source_id`)

**Migration: Add ski run `source_id` for upserts**
- Migration file: `backend/db/migrations/versions/002_ski_runs_source_id.py`
- Adds `source_id` column (`TEXT`, nullable, unique) to `map_trail.ski_runs`
- Creates unique index on `source_id` for upserts (`INSERT ... ON CONFLICT (source_id) DO UPDATE`)
- ORM mirror: `SkiRun.source_id` in `backend/map-backend/orm/orm_models.py`
- To apply: run `alembic upgrade head` with correct DB URL

**OpenSkiMap GeoJSON sync (`openskimap_sync`):**
- Loads run polylines from GeoJSON into `map_trail.ski_runs` using `source_id` for idempotent upserts
- Main logic: `backend/map-backend/services/openskimap_sync.py`
- Pipeline:
  - Downloads GeoJSON via `httpx` (URL from env or parameter, cache-busting enabled)
  - Parses each run, extracting name, difficulty, and a stable ID (`source_id`)
  - Stores runs via PostGIS using upsert (`ON CONFLICT (source_id) DO UPDATE`)
- Daily **03:00 UTC** job is registered only when **`OPENSKIMAP_SYNC_ENABLED`** and a non-empty **`OPENSKIMAP_RUNS_GEOJSON_URL`** are both set (`config.openskimap_sync_armed`). If sync is enabled without a URL, **config validation fails** at startup.
- Upstream GeoJSON must be provided/hosted manually (OpenSkiMap does not host a bulk file)
- Key dependencies: `httpx`, `asyncpg`, `shapely`, `apscheduler`


### Sample GeoJSON input (sync)

Minimal shape the parser accepts (one run line; add more objects under `features` for batches):

```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "properties": {
        "id": 123456789,
        "name": "Example Run",
        "piste:difficulty": "advanced"
      },
      "geometry": {
        "type": "LineString",
        "coordinates": [[6.8, 45.8], [6.801, 45.801], [6.802, 45.799]]
      }
    }
  ]
}
```

- **MultiLineString:** longest component line is kept as the stored `LINESTRING`.
- **Missing name:** stored as `"Unnamed run"` (truncated to DB length limits in code).

### Sample structures (client pipeline, Dart)

- **Sources:** `frontend/lib/models/track_point.dart`, `segment.dart`, `processed_track.dart`, etc.; mirrored in `backend/shared/track_pipeline_schemas.py` for HTTP.
- **TrackPoint fields:** `lat`, `lon`, `elevationM`, `timestamp`, `speedKmh`, optional `segmentType` (`PointSegmentType`: lift, run, transition) — per-point hint before Engine 2.
- **Segment fields:** `type` (`SegmentType`: descent, lift, flat, pause), `points` (list of `TrackPoint`), `startIndex`, `endIndex`, optional `trailName`, `difficulty` — Engine 2 output.

Illustrative JSON (API-style; Dart uses typed `DateTime` and nested `points` on real `Segment` objects):

```json
{
  "lat": 45.92,
  "lon": 6.87,
  "elevationM": 2100.0,
  "timestamp": "2026-04-05T10:00:00.000Z",
  "speedKmh": 12.4,
  "segmentType": "run"
}
```

```json
{
  "type": "descent",
  "startIndex": 0,
  "endIndex": 42,
  "trailName": "Example trail",
  "difficulty": "advanced",
  "points": [{ "lat": 45.92, "lon": 6.87, "elevationM": 2100, "timestamp": "2026-04-05T10:00:00.000Z", "speedKmh": 15.0 }]
}
```

### In-memory parsed row (`ParsedSkiRun`)


| Field          | Type         | Notes                                                           |
| -------------- | ------------ | --------------------------------------------------------------- |
| `source_id`    | `str`        | e.g. `openskimap:123456789` or `openskimap:idx:0`               |
| `name`         | `str`        | max 512 chars in DB                                             |
| `difficulty`   | `str | None` | max 64 chars in DB                                              |
| `geom_geojson` | `str`        | JSON `LineString` (may include Z); DB insert uses `ST_Force2D(ST_GeomFromGeoJSON(...))` |


### PostGIS row (`map_trail.ski_runs`) after sync

- `**id`:** `UUID` default `gen_random_uuid()` (unchanged on upsert).
- `**source_id`:** external stable key for `ON CONFLICT`.
- `**name`**, `**difficulty`:** from feature properties.
- `**geom`:** `geometry(LINESTRING, 4326)` from GeoJSON; upstream dumps may be **LineString Z** — ingest uses **`ST_Force2D`** so the column stays 2D.

### Upsert SQL (reference)

```164:174:backend/map-backend/services/openskimap_sync.py
UPSERT_SQL = """
INSERT INTO map_trail.ski_runs (source_id, name, difficulty, geom)
VALUES (
    $1, $2, $3,
    ST_SetSRID(ST_Force2D(ST_GeomFromGeoJSON($4::text)), 4326)
)
ON CONFLICT (source_id) DO UPDATE SET
    name = EXCLUDED.name,
    difficulty = EXCLUDED.difficulty,
    geom = EXCLUDED.geom
"""
```

### Scheduler wiring (reference)

```88:100:backend/map-backend/main.py
    scheduler: AsyncIOScheduler | None = None
    if config.openskimap_sync_armed:
        scheduler = AsyncIOScheduler(timezone=ZoneInfo("UTC"))
        scheduler.add_job(
            _openskimap_scheduled_sync,
            "cron",
            hour=3,
            minute=0,
            id="openskimap_ski_runs_sync",
            replace_existing=True,
        )
        scheduler.start()
        logger.info("OpenSkiMap ski_runs sync scheduled daily at 03:00 UTC")
```

### Optional: `get_db` in a route

```python
from fastapi import Depends
import asyncpg
from db.connection import get_db

@router.get("/example")
async def example(conn: asyncpg.Connection = Depends(get_db)):
    row = await conn.fetchrow("SELECT 1 AS n")
    return {"n": row["n"]}
```

### Related code (quick index)

- `backend/db/connection.py` — asyncpg pool, `get_db`.
- `backend/map-backend/main.py` — lifespan, pool DSN selection, OpenSkiMap scheduler.
- `backend/map-backend/config.py` — PostGIS DSN pieces, OpenSkiMap env flags.
- `backend/map-backend/services/openskimap_sync.py` — download / parse / upsert / `sync_ski_runs_from_openskimap`.
- `backend/scripts/run_initial_sync.py` — manual first ingest + `COUNT(*)` + `ST_DWithin` verification (uses `SYNTRAK_DATABASE_URL` + `OPENSKIMAP_RUNS_GEOJSON_URL`).
- `backend/db/migrations/versions/001_initial_postgis_and_map_trail.py` — PostGIS + `map_trail` tables + GiST.
- `backend/db/migrations/versions/002_ski_runs_source_id.py` — `ski_runs.source_id` + unique index.
- `backend/map-backend/orm/orm_models.py` — `SkiRun`, `SkiLift`, `Activity`, `TrackPoint`, `Segment`.
- `backend/shared/track_pipeline_schemas.py` — Pydantic mirrors of Dart pipeline types.
- `frontend/lib/core/constants/trail_detection_thresholds.dart` + `backend/shared/trail_detection_thresholds.py` — shared detection constants.
- `frontend/lib/models/` — Dart pipeline models (`TrackPoint`, `Segment`, `ProcessedTrack`, `ActivityStats`, …).

## Python API contracts (Pydantic v2)

Canonical request/response models mirroring the Dart types in `frontend/lib/models/` live in `backend/shared/track_pipeline_schemas.py`. Import them from any service that has `shared` on `PYTHONPATH` (see map-backend Docker layout).


| Python type                                                  | Role                                                                                               |
| ------------------------------------------------------------ | -------------------------------------------------------------------------------------------------- |
| `TrackPointIn` / `TrackPointOut`                             | GPS sample in/out; correction fills `elevation_m`.                                                 |
| `ProcessedTrackIn` / `ProcessedTrackOut`                     | Engine 1 track.                                                                                    |
| `SegmentOut`                                                 | Engine 2 slice; used in `TrailMatchResponse`.                                                      |
| `ActivityStatsOut`, `RunSummaryOut`                          | Engine 3 aggregates.                                                                               |
| `ElevationChartDataOut`, `ChartSpot`, `LiftBandRange`        | Engine 5 chart payload.                                                                            |
| `ElevationCorrectionRequest` / `ElevationCorrectionResponse` | `POST /api/elevation/correct` body (map-backend).                                                  |
| `TrailMatchRequest` / `TrailMatchResponse`                   | Trail-name matching contract (implementations TBD); see [trail-matcher.md](./trail-matcher.md).    |
| `ActivityIn` / `ActivityOut`                                 | Activity create/read aligned with the Flutter `Activity` model plus optional pipeline attachments. |


Envelope types (`ErrorResponse`, `SuccessResponse`, …) remain in `backend/shared/contracts.py`.

## Detection thresholds (Dart + Python)

Segmentation and trail matching share the same numeric tuning in two places; **keep them in sync** when you change behavior:

- **Dart:** `frontend/lib/core/constants/trail_detection_thresholds.dart` — `descentVvThreshold`, `liftVvThreshold`, `pauseSpeedKmh`, `pauseMinSeconds`, `rdpEpsilon`, `trailMatchRadiusM`.
- **Python:** `backend/shared/trail_detection_thresholds.py` — `DESCENT_VV_THRESHOLD`, `LIFT_VV_THRESHOLD`, `PAUSE_SPEED_KMH`, `PAUSE_MIN_SECONDS`, `RDP_EPSILON`, `TRAIL_MATCH_RADIUS_M`.

Values: descent VV −0.5 m/s, lift VV +0.3 m/s, pause speed ≤2 km/h for ≥8 s, RDP ε 0.0001 (degrees), trail match radius 50 m.

**Trail search radius** (how **`trailMatchRadiusM`** / **`TRAIL_MATCH_RADIUS_M`** map to PostGIS matching and representative points): [trail-matcher.md](./trail-matcher.md#radius-and-shared-thresholds).

## Ramer-Douglas-Peucker(RDP tolerance):

- user-defined distance threshold used to simplify polylines or polygones by reducing the number of points in a curve while maintaining its overall shape. Represents the max allowable prependicular distance that a point on the original curve can deviate from the simplified straight line approximation. 
  > High vs. low tolerance: 
- higher tolerance: a simpler line with fewer points, but less fidelity to the original shape. 
- lower tolerance: more retained points and higher accuracy.

## Related docs

- [trail-matcher.md](./trail-matcher.md) — PostGIS trail matching against `map_trail.ski_runs`, Python API, Supabase SQL samples.
- `docs/service-ownership.md` — which backend owns which domain (map-backend is geography/utilities, not activity CRUD).
- `frontend/docs/map.md` — recording state machine, widgets, and persistence direction.

