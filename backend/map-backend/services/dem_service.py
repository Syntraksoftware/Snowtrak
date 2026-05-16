"""
Copernicus DEM **GLO-30 Public** (AWS Open Data) tile cache and raster sampling.

Tiles are 1°×1° Cloud Optimized GeoTIFFs under ``s3://copernicus-dem-30m/`` (HTTPS
same host). Some cells are missing (ocean / non-public); those return ``NaN`` /
``None``.

Typical workflow: call ``download_dem_tiles`` for the track bounding box, then
``batch_correct(..., ensure_tiles=False)`` for many points. For sub-500 ms on
>5,000 points, keep tiles on disk and limit geographic spread (few 1° tiles);
sampling uses **windowed reads** and **vectorised** ``numpy`` indexing per tile.
"""

from __future__ import annotations

import logging
import math
import os
from collections.abc import Sequence
from pathlib import Path
from typing import TypeAlias

import httpx
import numpy as np
import rasterio
from rasterio.transform import rowcol
from rasterio.windows import Window

logger = logging.getLogger(__name__)

BBoxLonLat: TypeAlias = tuple[float, float, float, float]
# (min_lon, min_lat, max_lon, max_lat), WGS84

COP30_BASE_URL = "https://copernicus-dem-30m.s3.amazonaws.com"
COP30_RES_ARCSEC = "10"  # GLO-30 on AWS uses 10 arc-second naming
DEFAULT_CACHE_SUBDIR = "syntrak/dem_glo30"
HTTP_TIMEOUT_S = 120.0


def default_dem_cache_dir() -> Path:
    """``SYNTRAK_DEM_CACHE_DIR`` or ``$XDG_CACHE_HOME/syntrak/dem_glo30`` (else ``~/.cache/...``)."""
    raw = (os.environ.get("SYNTRAK_DEM_CACHE_DIR") or "").strip()
    if raw:
        return Path(raw).expanduser().resolve()
    root = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache"))
    return (root / DEFAULT_CACHE_SUBDIR).resolve()


def _normalize_lon(lon: float) -> float:
    """Wrap longitude to ``[-180, 180)`` for tiling."""
    return ((float(lon) + 180.0) % 360.0) - 180.0


def _format_northing(lat_floor: int) -> str:
    if lat_floor >= 0:
        return f"N{lat_floor:02d}_00"
    return f"S{abs(lat_floor):02d}_00"


def _format_easting(lon_floor: int) -> str:
    if lon_floor >= 0:
        return f"E{lon_floor:03d}_00"
    return f"W{abs(lon_floor):03d}_00"


def tile_key_stem(lat_floor: int, lon_floor: int) -> str:
    """S3 folder / object prefix, e.g. ``Copernicus_DSM_COG_10_N47_00_E008_00_DEM``."""
    n = _format_northing(lat_floor)
    e = _format_easting(lon_floor)
    return f"Copernicus_DSM_COG_{COP30_RES_ARCSEC}_{n}_{e}_DEM"


def tile_tif_url(stem: str) -> str:
    return f"{COP30_BASE_URL}/{stem}/{stem}.tif"


def tile_local_path(cache_dir: Path, stem: str) -> Path:
    return cache_dir / f"{stem}.tif"


def _iter_lon_floors(min_lon: float, max_lon: float) -> list[int]:
    """Integer tile columns, handling antimeridian crossing."""
    a, b = _normalize_lon(min_lon), _normalize_lon(max_lon)
    lo0, lo1 = int(math.floor(a)), int(math.floor(b))
    if lo0 <= lo1:
        return list(range(lo0, lo1 + 1))
    # Crosses dateline: [lo0, 180) ∪ [-180, lo1]
    return list(range(lo0, 181)) + list(range(-180, lo1 + 1))


def _iter_tile_stems_for_bbox(bbox: BBoxLonLat) -> list[str]:
    min_lon, min_lat, max_lon, max_lat = bbox
    lat0, lat1 = int(math.floor(min_lat)), int(math.floor(max_lat))
    stems: list[str] = []
    for la in range(lat0, lat1 + 1):
        if la < -90 or la > 90:
            continue
        for lo in _iter_lon_floors(min_lon, max_lon):
            stems.append(tile_key_stem(la, lo))
    return stems


def _download_one_tile(stem: str, dest: Path) -> bool:
    """Stream GeoTIFF to ``dest``; return True if file exists and non-empty after."""
    if dest.exists() and dest.stat().st_size > 0:
        return True
    dest.parent.mkdir(parents=True, exist_ok=True)
    url = tile_tif_url(stem)
    tmp = dest.with_suffix(dest.suffix + ".part")
    try:
        with (
            httpx.Client(timeout=HTTP_TIMEOUT_S, follow_redirects=True) as client,
            client.stream("GET", url) as r,
        ):
            if r.status_code == 404:
                logger.debug("Copernicus GLO-30 tile missing (404): %s", stem)
                return False
            r.raise_for_status()
            with tmp.open("wb") as f:
                for chunk in r.iter_bytes():
                    f.write(chunk)
        tmp.replace(dest)
        return True
    except (httpx.HTTPError, OSError) as e:
        logger.warning("DEM download failed for %s: %s", stem, e)
        if tmp.exists():
            tmp.unlink(missing_ok=True)
        return False


def download_dem_tiles(
    bbox: BBoxLonLat,
    cache_dir: Path | None = None,
) -> list[Path]:
    """
    Ensure Copernicus GLO-30 tiles covering ``bbox`` are present under ``cache_dir``.

    ``bbox`` is ``(min_lon, min_lat, max_lon, max_lat)`` in WGS84.
    Skips tiles that return 404 (ocean / withheld). Returns paths for tiles that exist on disk.
    """
    root = cache_dir or default_dem_cache_dir()
    out: list[Path] = []
    for stem in _iter_tile_stems_for_bbox(bbox):
        path = tile_local_path(root, stem)
        ok = _download_one_tile(stem, path)
        if ok and path.exists():
            out.append(path)
    return out


def _floors_for_points(lats: np.ndarray, lons: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    """Tile degree indices; ``lons`` must already be in ``[-180, 180)``."""
    lat_f = np.floor(lats.astype(np.float64)).astype(np.int64)
    lon_f = np.floor(lons.astype(np.float64)).astype(np.int64)
    return lat_f, lon_f


def _sample_one_tile_file(
    path: Path,
    lons: np.ndarray,
    lats: np.ndarray,
) -> np.ndarray:
    """Elevations for points known to lie in this tile's degree cell; same shape as ``lons``."""
    out = np.full(lons.shape[0], np.nan, dtype=np.float64)
    if lons.size == 0:
        return out

    with rasterio.open(path) as ds:
        t = ds.transform
        nodata = ds.nodata
        h, w = int(ds.height), int(ds.width)

        rows, cols = rowcol(t, lons, lats)
        rows = np.asarray(rows, dtype=np.int64)
        cols = np.asarray(cols, dtype=np.int64)
        valid = (rows >= 0) & (rows < h) & (cols >= 0) & (cols < w)
        if not np.any(valid):
            return out

        r_v, c_v = rows[valid], cols[valid]
        r0, r1 = int(r_v.min()), int(r_v.max()) + 1
        c0, c1 = int(c_v.min()), int(c_v.max()) + 1
        win = Window(col_off=c0, row_off=r0, width=c1 - c0, height=r1 - r0)
        arr = ds.read(1, window=win)

        loc_r = rows[valid] - r0
        loc_c = cols[valid] - c0
        vals = arr[loc_r, loc_c].astype(np.float64, copy=False)
        if nodata is not None:
            vals = np.where(vals == float(nodata), np.nan, vals)
        out[valid] = vals
    return out


def batch_correct(
    points: Sequence[tuple[float, float]] | np.ndarray,
    *,
    cache_dir: Path | None = None,
    ensure_tiles: bool = True,
) -> np.ndarray:
    """
    DEM elevations (meters) for ``points`` as ``(lat, lon)`` in WGS84.

    Returns ``float64`` array, shape ``(N,)``; missing tiles or nodata → ``NaN``.

    With ``ensure_tiles=True``, downloads any missing tiles for the points' bounding box first
    (can take minutes on first run). For latency-sensitive batches, prefetch with
    ``download_dem_tiles`` and pass ``ensure_tiles=False``.
    """
    root = cache_dir or default_dem_cache_dir()
    pts = np.asarray(points, dtype=np.float64)
    if pts.ndim != 2 or pts.shape[1] != 2:
        raise ValueError("points must be shape (N, 2) with rows (lat, lon)")
    lats = pts[:, 0]
    lons = ((pts[:, 1] + 180.0) % 360.0) - 180.0

    if ensure_tiles and pts.shape[0] > 0:
        bbox = (
            float(lons.min()),
            float(lats.min()),
            float(lons.max()),
            float(lats.max()),
        )
        download_dem_tiles(bbox, cache_dir=root)

    lat_f, lon_f = _floors_for_points(lats, lons)
    pair = np.column_stack([lat_f, lon_f])
    unique_pairs, inverse = np.unique(pair, axis=0, return_inverse=True)

    elevations = np.full(pts.shape[0], np.nan, dtype=np.float64)

    for k in range(unique_pairs.shape[0]):
        mask = inverse == k
        la_i, lo_i = int(unique_pairs[k, 0]), int(unique_pairs[k, 1])
        stem = tile_key_stem(la_i, lo_i)
        path = tile_local_path(root, stem)
        if not path.exists() and ensure_tiles:
            _download_one_tile(stem, path)
        if not path.exists():
            continue
        sub_lons = lons[mask]
        sub_lats = lats[mask]
        elevations[mask] = _sample_one_tile_file(path, sub_lons, sub_lats)

    return elevations


def sample_elevation(
    lat: float,
    lon: float,
    *,
    cache_dir: Path | None = None,
    ensure_tile: bool = True,
) -> float | None:
    """Single-point elevation (meters) or ``None`` if unavailable."""
    v = batch_correct(
        [(lat, lon)],
        cache_dir=cache_dir,
        ensure_tiles=ensure_tile,
    )[0]
    if math.isnan(v):
        return None
    return float(v)
