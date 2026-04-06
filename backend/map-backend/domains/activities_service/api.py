"""
Persist and read ``map_trail`` activities (PostGIS): track points, segments, stats JSONB.
"""

from __future__ import annotations

import logging
from datetime import datetime
from typing import Any
from uuid import UUID, uuid4

from fastapi import APIRouter, Depends, HTTPException, Query, status
import asyncpg
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

from domains.activities_service.infra import get_activities_conn

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/activities", tags=["activities"])

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
    if stats is not None and not isinstance(stats, dict):
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
                stats_blob,
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

            return await _detail_response(conn, aid)
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
