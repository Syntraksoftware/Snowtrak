"""
Trail matching and resort GeoJSON for map-backend.
"""

from __future__ import annotations

import json
import logging
from collections.abc import AsyncGenerator

from fastapi import APIRouter, Depends, HTTPException, Query, status
import asyncpg
from shared.track_pipeline_schemas import (
    SegmentOut,
    SegmentType,
    TrackPointIn,
    TrackPointOut,
    TrailMatchRequest,
    TrailMatchResponse,
)
from shared.trail_detection_thresholds import TRAIL_MATCH_RADIUS_M

from db.connection import get_pool
from services.trail_matcher import DescentSegmentInput, match_all_descents

logger = logging.getLogger(__name__)

router = APIRouter(tags=["trails"])

_RESORT_BBOX_SQL = """
SELECT
    r.id::text AS id,
    r.name AS name,
    r.difficulty AS difficulty,
    r.source_id AS source_id,
    ST_AsGeoJSON(r.geom)::text AS geom_json
FROM map_trail.ski_runs AS r
WHERE r.geom && ST_MakeEnvelope($1::float8, $2::float8, $3::float8, $4::float8, 4326)
ORDER BY r.name NULLS LAST, r.id::text
"""


async def get_trails_conn() -> AsyncGenerator[asyncpg.Connection, None]:
    pool = get_pool()
    if pool is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Postgres pool not configured (set SYNTRAK_DATABASE_URL)",
        )
    async with pool.acquire() as conn:
        yield conn


def _point_in_to_out(p: TrackPointIn) -> TrackPointOut:
    return TrackPointOut(
        lat=p.lat,
        lon=p.lon,
        elevation_m=p.elevation_m if p.elevation_m is not None else 0.0,
        timestamp=p.timestamp,
        speed_kmh=p.speed_kmh,
        segment_type=p.segment_type,
    )


def _track_points_in(request: TrailMatchRequest) -> list[TrackPointIn]:
    if request.processed_track is not None:
        return list(request.processed_track.points)
    if request.points is not None:
        return list(request.points)
    return []


def _input_segments(request: TrailMatchRequest) -> list[SegmentOut]:
    if request.segments is not None and len(request.segments) > 0:
        return list(request.segments)
    pts_in = _track_points_in(request)
    if not pts_in:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="No points available to build a synthetic descent segment",
        )
    outs = [_point_in_to_out(p) for p in pts_in]
    return [
        SegmentOut(
            type=SegmentType.descent,
            points=outs,
            start_index=0,
            end_index=max(0, len(outs) - 1),
        )
    ]


def _descent_inputs(segments: list[SegmentOut]) -> list[DescentSegmentInput]:
    inputs: list[DescentSegmentInput] = []
    for seg in segments:
        if seg.type != SegmentType.descent or not seg.points:
            continue
        inputs.append(DescentSegmentInput(points=[(p.lat, p.lon) for p in seg.points]))
    return inputs


@router.post("/trails/match", response_model=TrailMatchResponse)
async def match_trails(
    request: TrailMatchRequest,
    conn: asyncpg.Connection = Depends(get_trails_conn),
) -> TrailMatchResponse:
    """
    Fill ``trail_name`` / ``difficulty`` on **descent** ``SegmentOut`` rows using PostGIS.

    Non-descent segments are returned unchanged. Order and count match the working segment list.
    """
    segments = _input_segments(request)
    descent_inputs = _descent_inputs(segments)
    if not descent_inputs:
        return TrailMatchResponse(segments=segments)

    try:
        matches = await match_all_descents(conn, descent_inputs, TRAIL_MATCH_RADIUS_M)
    except Exception as e:
        logger.exception("trail match failed")
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Trail matching failed: {e!s}",
        ) from None

    mi = 0
    out: list[SegmentOut] = []
    for seg in segments:
        if seg.type == SegmentType.descent and seg.points:
            m = matches[mi]
            mi += 1
            out.append(
                seg.model_copy(
                    update={
                        "trail_name": m.trail_name if m is not None else None,
                        "difficulty": m.difficulty if m is not None else None,
                    }
                )
            )
        else:
            out.append(seg)

    return TrailMatchResponse(segments=out)


def _parse_bbox(bbox: str) -> tuple[float, float, float, float]:
    parts = [p.strip() for p in bbox.split(",")]
    if len(parts) != 4:
        raise ValueError(
            "bbox must be four comma-separated numbers: min_lon,min_lat,max_lon,max_lat"
        )
    try:
        min_lon, min_lat, max_lon, max_lat = (float(x) for x in parts)
    except ValueError as e:
        raise ValueError("bbox values must be numeric") from e
    if min_lon >= max_lon or min_lat >= max_lat:
        raise ValueError("bbox must satisfy min_lon < max_lon and min_lat < max_lat")
    if not (-180.0 <= min_lon <= 180.0 and -180.0 <= max_lon <= 180.0):
        raise ValueError("longitude out of range")
    if not (-90.0 <= min_lat <= 90.0 and -90.0 <= max_lat <= 90.0):
        raise ValueError("latitude out of range")
    return min_lon, min_lat, max_lon, max_lat


@router.get("/trails/resort")
async def resort_trails_geojson(
    bbox: str = Query(
        ...,
        description="Bounding box WGS84: min_lon,min_lat,max_lon,max_lat",
        examples=["8.0,47.0,9.0,48.0"],
    ),
    conn: asyncpg.Connection = Depends(get_trails_conn),
) -> dict:
    """
    GeoJSON ``FeatureCollection`` of ``map_trail.ski_runs`` lines intersecting the bbox envelope.

    Intended for Engine 4 clients to prefetch a resort vector layer.
    """
    try:
        min_lon, min_lat, max_lon, max_lat = _parse_bbox(bbox)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=str(e),
        ) from None

    try:
        rows = await conn.fetch(_RESORT_BBOX_SQL, min_lon, min_lat, max_lon, max_lat)
    except Exception as e:
        logger.exception("resort bbox query failed")
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Query failed: {e!s}",
        ) from None

    features: list[dict] = []
    for row in rows:
        geom_raw = row["geom_json"]
        geometry = json.loads(geom_raw) if isinstance(geom_raw, str) else geom_raw
        features.append(
            {
                "type": "Feature",
                "id": row["id"],
                "properties": {
                    "name": row["name"],
                    "difficulty": row["difficulty"],
                    "source_id": row["source_id"],
                },
                "geometry": geometry,
            }
        )

    return {"type": "FeatureCollection", "features": features}
