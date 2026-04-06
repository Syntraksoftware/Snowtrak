"""
Copernicus DEM elevation correction over HTTP (``POST /elevation/correct``).
"""

from __future__ import annotations

import asyncio
import logging
import math
import threading
import time
from collections import OrderedDict
from dataclasses import dataclass

from fastapi import APIRouter, HTTPException, status
import numpy as np
from shared.track_pipeline_schemas import (
    ElevationCorrectionRequest,
    ElevationCorrectionResponse,
    TrackPointOut,
)

from domains.elevation_dem_service.adapters import batch_correct

logger = logging.getLogger(__name__)

router = APIRouter(tags=["elevation-dem"])

# --- Response cache (bounding box + point signature) ---

_CACHE_MAX = 256
_CACHE_TTL_S = 3600.0
_cache_lock = threading.Lock()
_cache: OrderedDict[tuple, _CacheEntry] = OrderedDict()


@dataclass
class _CacheEntry:
    payload: dict
    expires_at: float


def _normalize_lon(lon: float) -> float:
    return ((float(lon) + 180.0) % 360.0) - 180.0


def _bbox_cache_key(request: ElevationCorrectionRequest) -> tuple[tuple[float, ...], ...]:
    """
    Cache key: quantized WGS84 bbox of the request plus a stable point sequence signature.

    The bbox buckets responses geographically; the point tuple prevents collisions when
    different tracks share the same bounding box.
    """
    lats: list[float] = []
    lons: list[float] = []
    pt_sig: list[tuple[float, float]] = []
    for p in request.points:
        la = float(p.lat)
        lo = _normalize_lon(float(p.lon))
        lats.append(la)
        lons.append(lo)
        pt_sig.append((round(la, 6), round(lo, 6)))
    bbox = (min(lons), min(lats), max(lons), max(lats))
    bbox_q = tuple(round(x, 5) for x in bbox)
    return (bbox_q, tuple(pt_sig))


def clear_dem_correction_cache() -> None:
    """Drop all cached correction responses (for tests)."""
    with _cache_lock:
        _cache.clear()


def _cache_get(key: tuple) -> ElevationCorrectionResponse | None:
    now = time.monotonic()
    with _cache_lock:
        entry = _cache.get(key)
        if entry is None:
            return None
        if entry.expires_at <= now:
            del _cache[key]
            return None
        _cache.move_to_end(key)
        return ElevationCorrectionResponse.model_validate(entry.payload)


def _cache_set(key: tuple, response: ElevationCorrectionResponse) -> None:
    now = time.monotonic()
    payload = response.model_dump(mode="json")
    with _cache_lock:
        _cache[key] = _CacheEntry(payload=payload, expires_at=now + _CACHE_TTL_S)
        _cache.move_to_end(key)
        while len(_cache) > _CACHE_MAX:
            _cache.popitem(last=False)


@router.post("/elevation/correct", response_model=ElevationCorrectionResponse)
async def correct_elevation_dem(request: ElevationCorrectionRequest) -> ElevationCorrectionResponse:
    """
    Correct ``elevation_m`` using Copernicus GLO-30 DEM tiles (local cache + rasterio).

    Responses are cached by **quantized bounding box** and **per-point (lat, lon) signature**
    for the lifetime of the process (LRU + TTL).
    """
    key = _bbox_cache_key(request)
    hit = _cache_get(key)
    if hit is not None:
        return hit

    coords = np.array([[p.lat, p.lon] for p in request.points], dtype=np.float64)

    def _run_batch() -> np.ndarray:
        return batch_correct(coords, ensure_tiles=True)

    try:
        elevs = await asyncio.to_thread(_run_batch)
    except Exception as e:
        logger.exception("DEM batch_correct failed")
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"DEM correction failed: {e!s}",
        ) from None

    if elevs.shape[0] != len(request.points):
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="DEM returned a mismatched result count",
        )

    corrected: list[TrackPointOut] = []
    for pt, raw in zip(request.points, elevs, strict=True):
        if math.isnan(float(raw)):
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="DEM sample unavailable for one or more coordinates (tile gap or nodata)",
            )
        corrected.append(
            TrackPointOut(
                lat=pt.lat,
                lon=pt.lon,
                elevation_m=float(raw),
                timestamp=pt.timestamp,
                speed_kmh=pt.speed_kmh,
                segment_type=pt.segment_type,
            )
        )

    out = ElevationCorrectionResponse(points=corrected)
    _cache_set(key, out)
    logger.info("DEM elevation correction for %d points (cached key bbox=%s)", len(corrected), key[0])
    return out
