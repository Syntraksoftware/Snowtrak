# Nivus trail server (external microservice)

Nivus is a **dedicated compute service** outside `syntrak-application`. It owns track post-processing (Engines 1–3) and PostGIS trail matching.

Repository: `~/Desktop/nivus/` (Python package `nivus`).

Legacy doc name: `theta-trail-server.md` (deprecated).

## Single client endpoint

```
POST /api/v1/pipeline/process
```

Default port: **5201**

### Request (minimal)

```json
{
  "id": "activity-uuid",
  "recorded_at": "2026-06-08T10:00:00+00:00",
  "source_type": "gpx",
  "match_trails": true,
  "points": [
    {
      "lat": 47.0,
      "lon": 8.0,
      "elevation_m": 2000.0,
      "timestamp": "2026-06-08T10:00:00+00:00",
      "speed_kmh": 0
    }
  ]
}
```

### Response (shape)

- `processed_track` — cleaned points with computed speeds
- `segments` — descent / lift / flat / pause slices with optional `trail_name`
- `stats` — activity totals
- `run_summaries` — per-descent rollups
- `metrics` — timing breakdown

## Service boundaries

| Concern | Owner |
|---------|--------|
| Track math + trail match | **Nivus** |
| DEM elevation | **map-backend** `POST /elevation/correct` |
| `map_trail` persistence | **map-backend** `POST /activities` |
| Social feed record | **activity-backend** |

Mobile orchestration (sync bridge): `frontend/lib/features/track_pipeline/application/track_pipeline_coordinator.dart`

## Run locally

```bash
cd ~/Desktop
PYTHONPATH=. uvicorn nivus.app.main:app --reload --port 5201
```

Env: `NIVUS_DATABASE_URL` or `SYNTRAK_DATABASE_URL` (Supabase pooler port **6543** recommended).
