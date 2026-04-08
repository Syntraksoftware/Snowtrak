# GPS Ingestion Pipeline Debug Guide

This guide explains how to run the frontend GPS ingestion pipeline end-to-end with a GPX file, validate output quality constraints, and visualize route cleanliness.

## Short Changelog

- Added timestamp-aware outlier filtering so missing timestamps do not trigger false jump rejection.
- Added adaptive ingestion behavior for sparse timestamps (skip Kalman + lower RDP epsilon to `0.00003`).
- Added frontend segmentation stage 1 modules (vertical velocity, point classifier, segment grouper).
- Added segmentation facade modules (`gap_merger`, `trail_matcher`, `segment_detection_engine`) and e2e coverage.

## Goal

Given a GPX file from a ski resort, produce a `ProcessedTrack` such that:

- every `TrackPoint.elevationM` is present,
- every `TrackPoint.speedKmh` is present,
- final point count is under `1500`,
- route shape looks visually clean on a debug map.

## Pipeline Order

The facade is:

- `frontend/lib/engines/ingestion/gps_ingestion_engine.dart`

Public methods:

- `processGpxFile(File)`
- `processFitFile(File)`
- `processLiveSession(List<RawPoint>)`

Execution sequence:

1. parse (`gpx_parser.dart` or `fit_parser.dart`)
2. outlier removal (`outlier_remover.dart`)
3. conditional Kalman smoothing (`kalman_filter.dart`)
4. RDP downsample (`rdp_downsampler.dart`)
5. elevation correction (`elevation_corrector.dart`)
6. speed computation (`speed_calculator.dart`)
7. return `ProcessedTrack`

### Current implementation details (important)

- Timestamp-aware outlier filtering:
  - speed and elevation-jump rejection are only applied when both points have timestamps.
  - when timestamps are missing, points are not rejected by fake 1-second delta assumptions.
- Adaptive smoothing/downsampling in `gps_ingestion_engine.dart`:
  - if timestamp coverage is strong (`>= 0.8`), engine uses:
    - Kalman smoothing,
    - default RDP epsilon `0.0001`.
  - if timestamp coverage is sparse (`< 0.8`), engine uses:
    - no Kalman smoothing,
    - smaller RDP epsilon `0.00003` to preserve geometry.

This was added to prevent sparse-time GPX files from collapsing to a near 2-point route.

## Run Debug Validation (Frontend)

A runnable debug test is available at:

- `frontend/test/engines/ingestion/manual_real_gpx_debug_test.dart`

It enforces the three constraints and emits artifacts:

- `frontend/docs/debug-ingestion/processed_track_debug.json`
- `frontend/docs/debug-ingestion/processed_track_debug_map.html`

Run with your real resort GPX path:

```bash
cd frontend
flutter test test/engines/ingestion/manual_real_gpx_debug_test.dart \
  --dart-define=REAL_GPX_PATH=/absolute/path/to/your_resort_track.gpx
```

Run with real backend DEM correction (instead of mock DEM):

```bash
cd frontend
flutter test test/engines/ingestion/manual_real_gpx_debug_test.dart \
  --dart-define=REAL_GPX_PATH=/absolute/path/to/your_resort_track.gpx \
  --dart-define=INGEST_USE_REAL_DEM=true \
  --dart-define=MAP_BACKEND_BASE_URL=http://localhost:5200/api \
  --dart-define=MAP_BACKEND_TOKEN=YOUR_JWT_IF_REQUIRED
```

Expected result:

- test passes,
- JSON contains `allElevationPresent: true`, `allSpeedPresent: true`, `under1500: true`,
- JSON also reports `demMode` (`mock` or `real-backend`),
- HTML map overlays raw (red) and processed (green) routes for visual check.

## Visual Verification Checklist

Open `frontend/docs/debug-ingestion/processed_track_debug_map.html` and confirm:

- processed route follows the same ski run geometry as raw input,
- GPS jitter is reduced (processed line less noisy),
- no unrealistic jumps/teleports,
- major turns and endpoints are preserved.

## CURL Samples (Map Backend)

Use these to validate backend correction/trail APIs independently.

### 1) Elevation correction

```bash
curl -X POST "http://localhost:5200/api/elevation/correct" \
  -H "Content-Type: application/json" \
  -d '{
    "points": [
      {
        "lat": 46.8001,
        "lon": 8.2001,
        "elevation_m": null,
        "timestamp": "2026-01-01T10:00:00Z",
        "speed_kmh": 0,
        "segment_type": null
      },
      {
        "lat": 46.8005,
        "lon": 8.2005,
        "elevation_m": null,
        "timestamp": "2026-01-01T10:00:01Z",
        "speed_kmh": 0,
        "segment_type": null
      }
    ]
  }'
```

Expected result:

- HTTP `200`,
- response body has `points[]`,
- each point includes numeric `elevation_m` (non-null),
- response point count equals request point count.

### 2) Trail matching

```bash
curl -X POST "http://localhost:5200/api/trails/match" \
  -H "Content-Type: application/json" \
  -d '{
    "points": [
      {
        "lat": 46.8001,
        "lon": 8.2001,
        "elevation_m": 1800,
        "timestamp": "2026-01-01T10:00:00Z",
        "speed_kmh": 35,
        "segment_type": "run"
      },
      {
        "lat": 46.8005,
        "lon": 8.2005,
        "elevation_m": 1790,
        "timestamp": "2026-01-01T10:00:01Z",
        "speed_kmh": 38,
        "segment_type": "run"
      }
    ]
  }'
```

Expected result:

- HTTP `200` when route is mounted on your running map backend,
- matched trail metadata appears for descent segments when candidate runs exist,
- if no matching runs nearby, response still succeeds with empty/low-confidence matches.

If you receive `404 Not Found`, confirm the running backend instance, base URL, and mounted route path in OpenAPI docs (`/docs`).

## Example Debug Output Snapshot

From the tiny parser fixture run:

- `rawPointCount`: `3`
- `processedPointCount`: `2`
- `allElevationPresent`: `true`
- `allSpeedPresent`: `true`
- `under1500`: `true`

From the current real demo GPX run (`0aa14c983ee47e72869c53e34a9bb550.gpx`):

- `rawPointCount`: `629`
- `processedPointCount`: `364`
- `allElevationPresent`: `true`
- `allSpeedPresent`: `true`
- `under1500`: `true`

This confirms the timestamp-aware + adaptive pipeline preserves meaningful route detail while meeting performance bounds.

## Segmentation Engine (Current)

After ingestion returns `ProcessedTrack`, segmentation modules are now available under:

- `frontend/lib/engines/segmentation/vertical_velocity_computer.dart`
- `frontend/lib/engines/segmentation/point_classifier.dart`
- `frontend/lib/engines/segmentation/segment_grouper.dart`

Flow:

1. compute smoothed vertical velocity per point,
2. classify each point into `descent/lift/flat/pause` using shared thresholds,
3. group consecutive states into raw segments.
