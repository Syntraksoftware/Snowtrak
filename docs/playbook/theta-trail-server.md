# Theta trail server (deprecated — see Nivus)

> **Renamed to Nivus.** See [nivus-trail-server.md](./nivus-trail-server.md).  
> Repository: `~/Desktop/nivus/` · package `nivus` · env `NIVUS_DATABASE_URL`

Theta is a **dedicated server** outside `syntrak-application`. It owns all track post-processing and PostGIS trail matching.

Repository location: sibling workspace (e.g. `~/Desktop/nivus/`).

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
- `metrics` — timing + trail match counts

## map-backend (this repo)

Still used for:

- `POST /api/v1/map/elevation/correct` — DEM fill
- `GET /api/v1/map/trails/resort?bbox=` — MapLibre overlay
- `POST /api/v1/map/activities` — persist processed tracks

Do **not** re-add trail matching to map-backend.

## Branch workflow

Finish math migration on the **`math`** branch in both repos, then merge into `develop`.
