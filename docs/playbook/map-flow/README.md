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
| **4**  | **Downstream product logic** — anything that needs a normalized track plus segments and/or stats but is not chart-specific (e.g. trail matching responses, social or resort features, exports). Concrete outputs are feature-specific; inputs are typically `ProcessedTrack` and Engine 2–3 artifacts. | (per feature; e.g. trail match contracts in shared schemas) |
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
- `**liftBandRanges`**: Ranges along the elevation chart marking sections where the user was on a lift; used to highlight lift rides on route profiles. (vertical displacement)

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

## Python API contracts (Pydantic v2)

Canonical request/response models mirroring the Dart types in `frontend/lib/models/` live in `**backend/shared/track_pipeline_schemas.py`**. Import them from any service that has `shared` on `PYTHONPATH` (see map-backend Docker layout).


| Python type                                                  | Role                                                                                               |
| ------------------------------------------------------------ | -------------------------------------------------------------------------------------------------- |
| `TrackPointIn` / `TrackPointOut`                             | GPS sample in/out; correction fills `elevation_m`.                                                 |
| `ProcessedTrackIn` / `ProcessedTrackOut`                     | Engine 1 track.                                                                                    |
| `SegmentOut`                                                 | Engine 2 slice; used in `TrailMatchResponse`.                                                      |
| `ActivityStatsOut`, `RunSummaryOut`                          | Engine 3 aggregates.                                                                               |
| `ElevationChartDataOut`, `ChartSpot`, `LiftBandRange`        | Engine 5 chart payload.                                                                            |
| `ElevationCorrectionRequest` / `ElevationCorrectionResponse` | `POST /api/elevation/correct` body (map-backend).                                                  |
| `TrailMatchRequest` / `TrailMatchResponse`                   | Trail-name matching contract (implementations TBD).                                                |
| `ActivityIn` / `ActivityOut`                                 | Activity create/read aligned with the Flutter `Activity` model plus optional pipeline attachments. |


Envelope types (`ErrorResponse`, `SuccessResponse`, …) remain in `backend/shared/contracts.py`.

## Detection thresholds (Dart + Python)

Segmentation and trail matching share the same numeric tuning in two places; **keep them in sync** when you change behavior:

- **Dart:** `frontend/lib/core/constants/trail_detection_thresholds.dart` — `descentVvThreshold`, `liftVvThreshold`, `pauseSpeedKmh`, `pauseMinSeconds`, `rdpEpsilon`, `trailMatchRadiusM`.
- **Python:** `backend/shared/trail_detection_thresholds.py` — `DESCENT_VV_THRESHOLD`, `LIFT_VV_THRESHOLD`, `PAUSE_SPEED_KMH`, `PAUSE_MIN_SECONDS`, `RDP_EPSILON`, `TRAIL_MATCH_RADIUS_M`.

Values: descent VV −0.5 m/s, lift V +0.3 m/s, pause speed ≤2 km/h for ≥8 s, RDP ε 0.0001 (degrees), trail match radius 50 m.
- `trailMatchRadiusM` defines how close a track sample must be to a trail polyline (within 50 meters) for it to be considered a match. This ensures that only samples that are physically near (and plausibly on) a given trail are matched to its name, reducing false positives from nearby but
separate paths.

## Ramer-Douglas-Peucker(RDP tolerance): 
- user-defined distance threshold used to simplify polylines or polygones by reducing the number of points in a curve while maintaining its overall shape. Represents the max allowable prependicular distance that a point on the original curve can deviate from the simplified straight line approximation. 
> High vs. low tolerance: 
- higher tolerance: a simpler line with fewer points, but less fidelity to the original shape. 
- lower toleranceL more retained points and higer accuracy. 

## Related docs

- `docs/service-ownership.md` — which backend owns which domain (map-backend is geography/utilities, not activity CRUD).
- `frontend/docs/map.md` — recording state machine, widgets, and persistence direction.

