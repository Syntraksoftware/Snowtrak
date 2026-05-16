# Copernicus DEM (GLO-30) local service

Operational notes for the **server-side** Digital Elevation Model helper used to sample heights from **Copernicus DEM GLO-30 Public** tiles. This complements (and may eventually back) the map-backend **Google** elevation HTTP client; it is not an HTTP route by itself.

## Purpose

- **Cache** 1°×1° **Cloud Optimized GeoTIFF** tiles on disk.
- **Sample** elevation at arbitrary WGS84 `(lat, lon)` using **rasterio** and **vectorised numpy** so large batches (for example track correction) stay fast once tiles are local.

Implementation: `backend/map-backend/services/dem_service.py`.

## Data source

| Item | Detail |
|------|--------|
| Dataset | Copernicus DEM **GLO-30 Public** (DSM: surface including vegetation and structures). |
| Hosting | [Registry of Open Data on AWS](https://registry.opendata.aws/copernicus-dem/) — bucket `copernicus-dem-30m`, same paths over **HTTPS** (`https://copernicus-dem-30m.s3.amazonaws.com/...`). |
| Format | Per-tile COG (DEFLATE, internal overviews). |
| Coverage gaps | Some 1° cells return **404** (ocean, or areas not released as public GLO-30). Treat as “no sample”: `NaN` / `None`. |
| Licence | Use follows [Copernicus DEM licence](https://spacedata.copernicus.eu/en/web/guest/collections/copernicus-digital-elevation-model/#Licencing); attribute Copernicus / ESA in user-facing products if required by policy. |

Official naming and grid notes: `https://copernicus-dem-30m.s3.amazonaws.com/readme.html`.

## Tile naming (AWS layout)

Tiles follow the documented folder pattern:

`Copernicus_DSM_COG_10_{northing}_{easting}_DEM/{same}.tif`

- **`10`** is the **arc-second** resolution label used on AWS for GLO-30 (not “30 m” in the string).
- **Northing** examples: `N47_00`, `S50_00` (integer degree, `.00` suffix).
- **Easting** examples: `E008_00`, `W105_00` (longitude padded to three digits in the easting part).

The code maps a point’s **floored** integer degree `(lat, lon)` to that stem, downloads to the cache as `{stem}.tif`, and opens it with rasterio.

## Bounding box and antimeridian

- **`download_dem_tiles(bbox)`** takes **`(min_lon, min_lat, max_lon, max_lat)`** in WGS84.
- If the box crosses the **180° meridian**, the service iterates longitude floors in two segments: `[floor(min_lon), 180]` and `[-180, floor(max_lon)]` so the correct tile columns are requested.

**`batch_correct`** wraps longitudes to **`[-180, 180)`** before tiling and sampling so inputs like `350°` still resolve consistently.

## Local cache

| Env var | Effect |
|---------|--------|
| `SYNTRAK_DEM_CACHE_DIR` | If set, absolute or user-relative directory for `*.tif` tiles. |
| `XDG_CACHE_HOME` | If `SYNTRAK_DEM_CACHE_DIR` is unset, tiles go under `$XDG_CACHE_HOME/syntrak/dem_glo30`. |
| (default) | Otherwise `~/.cache/syntrak/dem_glo30` (typical on Linux; macOS often still uses `~/.cache` unless `XDG_CACHE_HOME` is set). |

Downloads stream to a `*.part` file and **rename** to the final name to avoid half-written tiles. Existing non-empty files are skipped.

## Public API (Python)

| Function | Behaviour |
|----------|-----------|
| `default_dem_cache_dir()` | Resolved cache root. |
| `tile_key_stem(lat_floor, lon_floor)` | AWS folder/object stem for that integer-degree cell. |
| `tile_tif_url(stem)` | HTTPS URL for the `.tif`. |
| `download_dem_tiles(bbox, cache_dir=None)` | For every stem covering the bbox, download if missing; return list of **local paths** that exist after the run (404 tiles omitted). |
| `sample_elevation(lat, lon, cache_dir=None, ensure_tile=True)` | One point; returns `float` metres or **`None`** if missing/nodata. |
| `batch_correct(points, cache_dir=None, ensure_tiles=True)` | `points` is `(N, 2)` **float64** or sequence of `(lat, lon)`; returns **`float64` `numpy` array** shape `(N,)` with **`numpy.nan`** where no value. |

**`ensure_tiles=True`:** derives a bbox from the points, runs `download_dem_tiles`, then for each distinct degree cell tries to fetch the tile if still missing. First run can take **minutes** (tens of MB per tile).

**`ensure_tiles=False`:** only reads tiles already on disk — use this after **`download_dem_tiles`** for predictable latency.

## Performance notes

Sampling is optimised for **many points per tile**:

1. Group points by **integer-degree** `(lat_floor, lon_floor)`.
2. For each tile file, compute **pixel row/column** with rasterio’s **`rowcol`** on **arrays** of coordinates.
3. Read a single **window** that tightly bounds the used pixels (not necessarily the full 3600×3600 raster), then **numpy** fancy-indexing fills the output.

Rough expectation (local SSD, **one** tile, tiles **already cached**, **`ensure_tiles=False`**): on the order of **hundreds of ms** for **5 000** points. If the batch spans **many** tiles, expect multiple opens and larger combined IO. Cold download dominates wall time; **prefetch** the bbox before tight latency budgets.

## Dependencies

Declared for map-backend images and unified backend installs: **`rasterio`**, **`numpy`**, **`httpx`** (see `backend/map-backend/requirements.txt` and `backend/requirements.txt`).

## HTTP (map-backend)

**`POST /elevation/correct`** (no `/api` prefix) is registered on the map-backend app from `backend/routers/elevation.py`. It accepts **`ElevationCorrectionRequest`** / returns **`ElevationCorrectionResponse`** (`shared/track_pipeline_schemas.py`), calls **`dem_service.batch_correct`**, and caches successful JSON responses in-process keyed by **quantized bbox** plus a **per-point (lat, lon) signature** (LRU max 256 entries, TTL 1 hour).

The existing **`/api/elevation/*`** routes still use the **Google** elevation client (`map-backend/services/elevation_client.py`). Choose the contract that matches your client: Google batch vs Copernicus DEM.

## Relation to map-backend elevation HTTP API

Use **`/elevation/correct`** when the client should rely on **Copernicus GLO-30** and local tile cache; use **`/api/elevation/correct`** when using the **Google** provider.

## Related playbook sections

- Map-backend overview and routes: [README.md in this folder](./README.md) (section **Map backend**).
- Ski run bulk ingest and `map_trail.ski_runs`: [map-flow README](./README.md) (**OpenSkiMap / PostGIS**); matching descents to runs: [trail-matcher.md](./trail-matcher.md).

## curl tests: 
```bash
../.venv/bin/pytest tests/test_elevation.py -v
```