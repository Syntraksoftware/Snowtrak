"""
Resort trail GeoJSON for map overlays.

Trail **matching** and track post-processing are handled by the external
**theta trail server** (`POST /api/v1/pipeline/process`).
"""

from __future__ import annotations

import logging

from fastapi import APIRouter, Depends, HTTPException, Query, status
import asyncpg

from .bbox import parse_bbox
from .geojson import rows_to_feature_collection
from .ports import get_trails_conn
from .queries import RESORT_BBOX_SQL

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/trails", tags=["trails"])


@router.get("/resort")
async def resort_trails_geojson(
    bbox: str = Query(
        ...,
        description="Bounding box WGS84: min_lon,min_lat,max_lon,max_lat",
        examples=["8.0,47.0,9.0,48.0"],
    ),
    conn: asyncpg.Connection = Depends(get_trails_conn),
) -> dict:
    """
    GeoJSON ``FeatureCollection`` of ``map_trail.ski_runs`` lines intersecting the bbox.

    Used by MapLibre to prefetch a resort vector layer. For segment enrichment,
    call the theta trail server instead of map-backend.
    """
    try:
        min_lon, min_lat, max_lon, max_lat = parse_bbox(bbox)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=str(e),
        ) from None

    try:
        rows = await conn.fetch(RESORT_BBOX_SQL, min_lon, min_lat, max_lon, max_lat)
    except Exception as e:
        logger.exception("resort bbox query failed")
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Query failed: {e!s}",
        ) from None

    return rows_to_feature_collection(rows)
