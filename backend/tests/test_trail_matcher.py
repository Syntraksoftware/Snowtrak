"""Unit tests for ``services.trail_matcher`` (asyncpg mocked)."""

from __future__ import annotations

from datetime import UTC, datetime
from unittest.mock import AsyncMock, MagicMock

import pytest
from shared.track_pipeline_schemas import PointSegmentType, SegmentOut, SegmentType, TrackPointOut

from services.trail_matcher import (
    DescentSegmentInput,
    TrailMatch,
    descent_segments_from_engine2,
    match_all_descents,
    match_segment,
)


def _tp(lat: float, lon: float) -> TrackPointOut:
    return TrackPointOut(
        lat=lat,
        lon=lon,
        elevation_m=1000.0,
        timestamp=datetime(2026, 1, 1, 12, 0, 0, tzinfo=UTC),
        speed_kmh=10.0,
        segment_type=PointSegmentType.run,
    )


@pytest.mark.anyio
async def test_match_segment_returns_none_when_no_row() -> None:
    conn = MagicMock()
    conn.fetchrow = AsyncMock(return_value=None)
    assert await match_segment(conn, 47.5, 8.5, 50.0) is None
    conn.fetchrow.assert_awaited_once()


@pytest.mark.anyio
async def test_match_segment_returns_trail_match() -> None:
    conn = MagicMock()
    conn.fetchrow = AsyncMock(
        return_value={
            "name": "Test Piste",
            "difficulty": "intermediate",
            "source_id": "openskimap:1",
            "dist_m": 22.5,
        }
    )
    m = await match_segment(conn, 47.5, 8.5, 80.0)
    assert m is not None
    assert m.trail_name == "Test Piste"
    assert m.difficulty == "intermediate"
    assert m.source_id == "openskimap:1"
    assert m.distance_m == pytest.approx(22.5)
    assert m.piste_type is None
    args = conn.fetchrow.await_args
    assert args.args[1:4] == (8.5, 47.5, 80.0)


@pytest.mark.anyio
async def test_match_all_descents_preserves_order_and_none() -> None:
    conn = MagicMock()
    conn.fetch = AsyncMock(
        return_value=[
            {"ord": 1, "name": "A", "difficulty": "easy", "source_id": None, "dist_m": 10.0},
            {"ord": 2, "name": None, "difficulty": None, "source_id": None, "dist_m": None},
        ]
    )
    segs = [
        DescentSegmentInput(points=[(47.5, 8.5), (47.51, 8.51)]),
        DescentSegmentInput(points=[(0.0, 0.0)]),
    ]
    out = await match_all_descents(conn, segs, 100.0)
    assert len(out) == 2
    assert out[0] == TrailMatch(
        trail_name="A",
        difficulty="easy",
        piste_type=None,
        distance_m=10.0,
        source_id=None,
    )
    assert out[1] is None


def test_descent_segments_from_engine2_filters_non_descent() -> None:
    seg_run = SegmentOut(
        type=SegmentType.descent,
        points=[_tp(47.0, 8.0)],
        start_index=0,
        end_index=0,
    )
    seg_lift = SegmentOut(
        type=SegmentType.lift,
        points=[_tp(47.1, 8.1)],
        start_index=0,
        end_index=0,
    )
    got = descent_segments_from_engine2([seg_lift, seg_run])
    assert len(got) == 1
    assert got[0].points == [(47.0, 8.0)]


def test_representative_lat_lon_centroid() -> None:
    s = DescentSegmentInput(points=[(0.0, 0.0), (2.0, 2.0)])
    assert s.representative_lat_lon() == (1.0, 1.0)
