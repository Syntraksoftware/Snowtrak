"""
Persist and read ``map_trail`` activities (PostGIS): track points, segments, stats JSONB.
"""

from __future__ import annotations

import asyncio
import json
import logging
from datetime import datetime
from typing import Any
from uuid import UUID, uuid4

from fastapi import APIRouter, Depends, HTTPException, Query, status
import asyncpg
from pydantic import BaseModel
from shared.track_pipeline_schemas import (
    ActivityStatsOut,
    MapActivityCreateRequest,
    MapActivityDetailResponse,
    MapActivityListItem,
    MapActivityListResponse,
    PointSegmentType,
    ProcessedTrackOut,
    SegmentOut,
    SegmentType,
    SourceType,
    TrackPointOut,
)

from config import get_config
from domains.activities_service.ports import get_activities_conn, upload_thumbnail
from engine.thumbnail import render_route_png

logger = logging.getLogger(__name__)


async def _render_and_upload(activity_id: str, latlon: list[tuple[float, float]]) -> str | None:
    """Render route PNG and upload to storage; returns public URL or None on failure."""
    try:
        cfg = get_config()
        # ponytail: asyncio.to_thread keeps Pillow off the event loop
        png = await asyncio.to_thread(
            render_route_png, latlon, cfg.STATIC_MAP_WIDTH, cfg.STATIC_MAP_HEIGHT
        )
        return await asyncio.to_thread(upload_thumbnail, activity_id, png)
    except Exception:
        logger.warning("thumbnail generation failed for %s", activity_id, exc_info=True)
        return None


async def _generate_thumbnail(activity_id: UUID, points: list) -> str | None:
    return await _render_and_upload(str(activity_id), [(p.lat, p.lon) for p in points])


router = APIRouter(prefix="/activities", tags=["activities"])


class _ThumbnailRequest(BaseModel):
    activity_id: str
    points: list[dict]  # [{lat: float, lon: float}, ...]


@router.post("/thumbnail")
async def generate_activity_thumbnail(body: _ThumbnailRequest) -> dict:
    """Generate and upload a route thumbnail from raw GPS points (live recording path)."""
    latlon = [(p["lat"], p["lon"]) for p in body.points if "lat" in p and "lon" in p]
    url = await _render_and_upload(body.activity_id, latlon)
    return {"thumbnail_url": url}


_INSERT_ACTIVITY = """
INSERT INTO map_trail.activities (user_id, recorded_at, stats)
VALUES ($1::uuid, $2::timestamptz, $3::jsonb)
RETURNING id
"""

_INSERT_TRACK_POINT = """
INSERT INTO map_trail.track_points (
    id, activity_id, geom, speed_kmh, segment_type, sort_idx
) VALUES (
    $1::uuid, $2::uuid,
    ST_SetSRID(ST_MakePoint($3::float8, $4::float8, $5::float8), 4326),
    $6::float8, $7::text, $8::int
)
"""

_INSERT_SEGMENT = """
INSERT INTO map_trail.segments (activity_id, type, start_idx, end_idx, trail_name, difficulty)
VALUES ($1::uuid, $2::text, $3::int, $4::int, $5::text, $6::text)
"""

_SELECT_ACTIVITY = """
SELECT id::text AS id, user_id::text AS user_id, recorded_at, stats
FROM map_trail.activities
WHERE id = $1::uuid
"""

_SELECT_POINTS = """
SELECT
    ST_X(geom::geometry) AS lon,
    ST_Y(geom::geometry) AS lat,
    ST_Z(geom::geometry) AS elev_m,
    speed_kmh,
    segment_type
FROM map_trail.track_points
WHERE activity_id = $1::uuid
ORDER BY sort_idx ASC
"""

_SELECT_SEGMENTS = """
SELECT type, start_idx, end_idx, trail_name, difficulty
FROM map_trail.segments
WHERE activity_id = $1::uuid
ORDER BY start_idx ASC
"""


def _stats_blob_for_insert(body: MapActivityCreateRequest) -> dict[str, Any]:
    blob: dict[str, Any] = {}
    if body.stats is not None:
        if isinstance(body.stats, ActivityStatsOut):
            blob.update(body.stats.model_dump(mode="json"))
        else:
            blob.update(body.stats)
    blob["point_timestamps"] = [p.timestamp.isoformat() for p in body.processed_track.points]
    blob["source_type"] = body.processed_track.source_type.value
    return blob


def _segment_type_to_db(v: PointSegmentType | None) -> str | None:
    if v is None:
        return None
    return v.value


def _build_processed_track_out(
    activity_id: str,
    recorded_at: datetime,
    source_type: SourceType,
    rows: list[asyncpg.Record],
    point_timestamps: list[str] | None,
) -> ProcessedTrackOut:
    points_out: list[TrackPointOut] = []
    for i, r in enumerate(rows):
        lon = float(r["lon"])
        lat = float(r["lat"])
        z = float(r["elev_m"])
        ts_raw = point_timestamps[i] if point_timestamps and i < len(point_timestamps) else None
        if ts_raw:
            ts = datetime.fromisoformat(ts_raw.replace("Z", "+00:00"))
        else:
            ts = recorded_at
        st = r["segment_type"]
        seg_type = PointSegmentType(st) if st else None
        points_out.append(
            TrackPointOut(
                lat=lat,
                lon=lon,
                elevation_m=z,
                timestamp=ts,
                speed_kmh=float(r["speed_kmh"]),
                segment_type=seg_type,
            )
        )
    return ProcessedTrackOut(
        id=activity_id,
        points=points_out,
        recorded_at=recorded_at,
        source_type=source_type,
    )


def _source_type_from_stats(stats: dict[str, Any] | None) -> SourceType:
    if not stats:
        return SourceType.live
    raw = stats.get("source_type")
    if raw is None:
        return SourceType.live
    return SourceType(str(raw))


def _point_timestamps_from_stats(stats: dict[str, Any] | None) -> list[str] | None:
    if not stats:
        return None
    pt = stats.get("point_timestamps")
    if not isinstance(pt, list):
        return None
    return [str(x) for x in pt]


def _segments_out_from_rows(
    seg_rows: list[asyncpg.Record],
    points: list[TrackPointOut],
) -> list[SegmentOut]:
    out: list[SegmentOut] = []
    for r in seg_rows:
        a = int(r["start_idx"])
        b = int(r["end_idx"])
        slice_pts = points[a : b + 1]
        out.append(
            SegmentOut(
                type=SegmentType(r["type"]),
                points=slice_pts,
                start_index=a,
                end_index=b,
                trail_name=r["trail_name"],
                difficulty=r["difficulty"],
            )
        )
    return out


async def _detail_response(
    conn: asyncpg.Connection,
    activity_id: UUID,
) -> MapActivityDetailResponse:
    row = await conn.fetchrow(_SELECT_ACTIVITY, activity_id)
    if row is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Activity not found")

    stats = row["stats"]
    if isinstance(stats, str):
        stats = json.loads(stats)
    elif stats is not None and not isinstance(stats, dict):
        stats = dict(stats)

    pt_rows = await conn.fetch(_SELECT_POINTS, activity_id)
    seg_rows = await conn.fetch(_SELECT_SEGMENTS, activity_id)

    src = _source_type_from_stats(stats if isinstance(stats, dict) else None)
    ts_list = _point_timestamps_from_stats(stats if isinstance(stats, dict) else None)
    processed = _build_processed_track_out(
        str(activity_id),
        row["recorded_at"],
        src,
        list(pt_rows),
        ts_list,
    )
    segments = _segments_out_from_rows(list(seg_rows), processed.points)

    return MapActivityDetailResponse(
        id=row["id"],
        user_id=row["user_id"],
        recorded_at=row["recorded_at"],
        stats=stats if isinstance(stats, dict) else None,
        processed_track=processed,
        segments=segments,
    )


@router.post("", status_code=status.HTTP_201_CREATED, response_model=MapActivityDetailResponse)
async def create_activity(
    body: MapActivityCreateRequest,
    conn: asyncpg.Connection = Depends(get_activities_conn),
) -> MapActivityDetailResponse:
    stats_blob = _stats_blob_for_insert(body)
    recorded_at = body.processed_track.recorded_at

    try:
        async with conn.transaction():
            aid = await conn.fetchval(
                _INSERT_ACTIVITY,
                body.user_id,
                recorded_at,
                json.dumps(stats_blob),
            )
            assert aid is not None

            point_tuples: list[tuple[Any, ...]] = []
            for i, p in enumerate(body.processed_track.points):
                z = p.elevation_m if p.elevation_m is not None else 0.0
                point_tuples.append(
                    (
                        uuid4(),
                        aid,
                        float(p.lon),
                        float(p.lat),
                        z,
                        float(p.speed_kmh),
                        _segment_type_to_db(p.segment_type),
                        i,
                    )
                )
            if point_tuples:
                await conn.executemany(_INSERT_TRACK_POINT, point_tuples)

            seg_tuples = [
                (
                    aid,
                    seg.type.value,
                    seg.start_index,
                    seg.end_index,
                    seg.trail_name,
                    seg.difficulty,
                )
                for seg in body.segments
            ]
            if seg_tuples:
                await conn.executemany(_INSERT_SEGMENT, seg_tuples)

            detail = await _detail_response(conn, aid)

        thumbnail_url = await _generate_thumbnail(aid, body.processed_track.points)
        return detail.model_copy(update={"thumbnail_url": thumbnail_url})
    except asyncpg.PostgresError:
        logger.exception("activity insert failed (rolled back)")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to persist activity",
        ) from None


@router.get("/{activity_id}", response_model=MapActivityDetailResponse)
async def get_activity(
    activity_id: UUID,
    conn: asyncpg.Connection = Depends(get_activities_conn),
) -> MapActivityDetailResponse:
    try:
        return await _detail_response(conn, activity_id)
    except HTTPException:
        raise
    except asyncpg.PostgresError:
        logger.exception("activity read failed")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to load activity",
        ) from None


_DELETE_ACTIVITY = """
DELETE FROM map_trail.activities
WHERE id = $1::uuid
RETURNING id
"""


@router.delete("/{activity_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_activity(
    activity_id: UUID,
    conn: asyncpg.Connection = Depends(get_activities_conn),
) -> None:
    """Delete activity header; ``track_points`` and ``segments`` cascade via FK."""
    try:
        deleted_id = await conn.fetchval(_DELETE_ACTIVITY, activity_id)
    except asyncpg.PostgresError:
        logger.exception("activity delete failed")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to delete activity",
        ) from None

    if deleted_id is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Activity not found",
        )


@router.get("", response_model=MapActivityListResponse)
async def list_activities(
    user_id: UUID = Query(..., description="Filter activities for this user"),
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    conn: asyncpg.Connection = Depends(get_activities_conn),
) -> MapActivityListResponse:
    count_sql = "SELECT count(*)::int FROM map_trail.activities WHERE user_id = $1::uuid"
    list_sql = """
    SELECT id::text AS id, user_id::text AS user_id, recorded_at, stats
    FROM map_trail.activities
    WHERE user_id = $1::uuid
    ORDER BY recorded_at DESC
    LIMIT $2 OFFSET $3
    """
    try:
        total = await conn.fetchval(count_sql, user_id)
        assert total is not None
        rows = await conn.fetch(list_sql, user_id, limit, offset)
    except asyncpg.PostgresError:
        logger.exception("activity list failed")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to list activities",
        ) from None

    items: list[MapActivityListItem] = []
    for r in rows:
        st = r["stats"]
        if st is not None and not isinstance(st, dict):
            st = dict(st)
        items.append(
            MapActivityListItem(
                id=r["id"],
                user_id=r["user_id"],
                recorded_at=r["recorded_at"],
                stats=st if isinstance(st, dict) else None,
            )
        )
    return MapActivityListResponse(items=items, total=int(total), limit=limit, offset=offset)
