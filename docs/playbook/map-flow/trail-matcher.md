# Trail matcher — technical reference

End-to-end description of how **GPS points** are associated with **named ski runs** in PostGIS (`map_trail.ski_runs`). Implementation: `backend/map-backend/services/trail_matcher.py`. Runnable SQL for Supabase: [trail-matcher-samples.sql](./trail-matcher-samples.sql).

## Problem shape

- **Database:** Each ski run is a **polyline** (`geometry(LINESTRING, 4326)`), not a single latitude/longitude pair. Columns today: `id`, `name`, `difficulty`, `geom`, optional `source_id`. There are **no** per-run `lat`/`lon` scalar columns; the trail geometry **is** the spatial data.
- **Application:** The user track supplies **points** `(lat, lon)` (or full descent polylines). The matcher asks: *which stored run line is closest to this query geometry, and is it within a maximum distance?*

So matching is **point-to-linestring** (or conceptually **point-to-curve**) in WGS84, with a **metre-based** search radius.

## Pipeline placement

1. **Engine 2** (`SegmentOut`, `SegmentType`) classifies intervals: descent, lift, flat, pause.
2. **Trail matcher** is intended for **descents** (and similar “on-piste” intervals). It does not classify motion; it only **labels** geometry against the resort layer.
3. **OpenSkiMap-style sync** (`openskimap_sync.py`) fills `map_trail.ski_runs`. Without populated rows, every query returns no match.

Helper **`descent_segments_from_engine2`** filters an iterable of **`SegmentOut`** to **`SegmentType.descent`** with non-empty **`points`**, and maps each segment to **`DescentSegmentInput`** as `[(lat, lon), …]` from **`TrackPointOut`**.

## Representative point (batch path)

For **`match_all_descents`**, each **`DescentSegmentInput`** has many points. The service uses **one** query point per segment:

- **`representative_lat_lon()`** = arithmetic mean of latitudes and mean of longitudes (component-wise average in degrees).
- This is **not** a rigorous geodesic centroid; it is cheap and stable for short segments (typical ski descents). For very long spans near poles or the antimeridian, a geodesic centroid would differ; the current code does not implement that.

Empty **`points`** raises **`ValueError`** before SQL runs.

## PostGIS and CRS semantics

### Why `::geography`

`geom` is stored as **`geometry(LINESTRING, 4326)`** (degrees). **`ST_DWithin`** / **`ST_Distance`** on raw **geometry** in EPSG:4326 use **degree** units for distance — wrong for “50 m” thresholds.

The SQL casts:

- `r.geom::geography`
- query point: `ST_SetSRID(ST_MakePoint(...), 4326)::geography`

so distances use the **WGS84 geography** type (spheroid, **metres**).

### Point construction order

**PostGIS `ST_MakePoint(x, y)`** = **(longitude, latitude)**. The Python API uses **`(lat, lon)`** for ergonomics; **`match_segment`** passes **`$1 = lon`**, **`$2 = lat`** into **`ST_MakePoint($1, $2)`**. The batch query uses **`ST_MakePoint(s.lon, s.lat)`** from parallel **`unnest`** arrays (**`lats[]`**, **`lons[]`**).

### Predicates used

1. **`ST_DWithin(line_geog, point_geog, radius_m)`** — true when the **shortest** geodesic distance from the query **point** to **anywhere on the line** is ≤ **`radius_m`** (not “the whole line fits inside a disc”).
2. **`ST_Distance(line_geog, point_geog)`** — that same minimum distance in metres, used for **`dist_m`** and **`ORDER BY dist_m ASC`**.
3. **`ORDER BY dist_m ASC LIMIT 1`** — **closest** qualifying run. Ties (identical distance) are broken by PostgreSQL’s arbitrary stable ordering among tied rows unless a secondary key is added (not implemented).

If **no** row satisfies **`ST_DWithin`**, the single-query path returns **`fetchrow` → `None`**; batch uses **`LEFT JOIN LATERAL … ON TRUE`** so each ordinal still produces a row with **`name` NULL**, interpreted as **no match**.

## Single-segment SQL (conceptual)

Equivalent to constant **`_MATCH_SEGMENT_SQL`** in code:

- Bindings: **`$1 = lon`**, **`$2 = lat`**, **`$3 = radius_m`**.
- Select **`name`**, **`difficulty`**, **`source_id`**, **`dist_m`**.
- Filter with **`ST_DWithin`**; sort by distance; **`LIMIT 1`**.

## Batch SQL (conceptual)

**`_MATCH_BATCH_SQL`**:

1. **`unnest($1::float8[], $2::float8[]) WITH ORDINALITY AS s(lat, lon, ord)`** — parallel arrays of representative lat/lon per segment, preserving **1-based ordinality** **`ord`** aligned with segment index order in the query.
2. **`LEFT JOIN LATERAL ( … ) r ON TRUE`** — for each row, subquery scans **`map_trail.ski_runs`**, applies the same **`ST_DWithin`** / **`ST_Distance`** pattern, **`ORDER BY dist_m`**, **`LIMIT 1`**.
3. Outer **`ORDER BY s.ord`** — result rows ordered by segment index.

Python maps returned rows by **`ord`** into **`list[TrailMatch | None]`** the same length and order as **`segments`**. Missing **`ord`** keys (should not happen) yield **`None`** in the slot.

**`radius_m`** is shared across all segments in one batch call.

## Python layer

| Item | Behaviour |
|------|-----------|
| **`match_segment(conn, lat, lon, radius_m)`** | **`radius_m < 0`** → **`ValueError`**. Returns **`TrailMatch \| None`**. |
| **`match_all_descents(conn, segments, radius_m)`** | Empty **`segments`** → **`[]`**. Otherwise list of **`TrailMatch \| None`** per input segment. |
| **`_row_to_match`** | **`None`** row or **`name` NULL** → **`None`**. **`piste_type`** always **`None`** (no DB column). **`dist_m`** cast to **`float`**. |

**`TrailMatch`:** `trail_name`, `difficulty`, `piste_type` (reserved), `distance_m`, `source_id`.

## Shared radius constant

**`TRAIL_MATCH_RADIUS_M`** in `backend/shared/trail_detection_thresholds.py` is **50.0** metres (mirror **`trailMatchRadiusM`** in Dart). Call sites **should** pass this constant (or a deliberate override) into **`match_segment`** / **`match_all_descents`** so client and server agree on “near enough to name the trail.” See also [README.md — Detection thresholds](./README.md#detection-thresholds-dart--python).

## Performance and indexing

- GiST exists on **`geometry`** (`idx_map_trail_ski_runs_geom`). Queries cast to **geography**; planner may still use geometry indexes in some plans, but **`geom::geography`** can limit index use. For high QPS, consider an expression index such as **`USING gist ((geom::geography))`** (documented as optional in [trail-matcher-samples.sql](./trail-matcher-samples.sql)).
- **Batch** path issues **one** round-trip for **N** segments instead of **N** **`fetchrow`** calls.

## HTTP (map-backend)

| Method / path | Body / query | Role |
|---------------|--------------|------|
| **`POST /trails/match`** | **`TrailMatchRequest`** JSON | Returns **`TrailMatchResponse`**: same segment list order; **`descent`** rows get **`trail_name`** / **`difficulty`** from **`match_all_descents`** (`TRAIL_MATCH_RADIUS_M`). Provide **`segments`** (Engine 2) or **`processed_track`** / **`points`** (single synthetic descent). |
| **`GET /trails/resort`** | **`bbox=min_lon,min_lat,max_lon,max_lat`** | GeoJSON **`FeatureCollection`** of **`map_trail.ski_runs`** lines intersecting the envelope (Engine 4 map layer). |

Router: **`backend/routers/trails.py`**. Requires **`SYNTRAK_DATABASE_URL`** so the asyncpg pool exists; otherwise **503**.

**`TrailMatchRequest`** also accepts optional **`segments: list[SegmentOut]`** (see `shared/track_pipeline_schemas.py`). **`resort_id`** is reserved and ignored today.

## Failure and edge cases

| Situation | Outcome |
|-----------|---------|
| No run within **`radius_m`** | **`None`** for that segment. |
| Multiple runs inside radius | Closest by **`ST_Distance`** wins. |
| **`difficulty` NULL** in DB | **`TrailMatch.difficulty`** is **`None`**; still a match if **`name`** present. |
| Ocean / empty **`ski_runs`** | No rows; all **`None`**. |
| GPS far from any ingested resort | Same. |

## Testing

- **`backend/tests/test_trail_matcher.py`** — mocks **`asyncpg`**, asserts bind order **`(lon, lat, radius)`**, batch ordinals, **`descent_segments_from_engine2`** filtering.
- **`backend/tests/test_trails.py`** — HTTP **`POST /trails/match`** and **`GET /trails/resort`** with dependency override and mocked **`conn.fetch`**.

## Related

- Map flow overview: [README.md](./README.md).
- DEM / elevation (orthogonal): [dem-copernicus-glo30.md](./dem-copernicus-glo30.md).
