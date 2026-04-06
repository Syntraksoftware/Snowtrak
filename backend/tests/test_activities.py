"""Tests for ``POST /activities``, ``GET /activities/{id}``, ``GET /activities``."""

from __future__ import annotations

from datetime import UTC, datetime
from unittest.mock import AsyncMock, MagicMock
from uuid import uuid4

import httpx
import pytest
from fastapi import FastAPI

from db.connection import require_pool_conn
from domains.activities_service.api import router


def _iso_ts() -> str:
    return datetime(2026, 1, 1, 12, 0, 0, tzinfo=UTC).isoformat()


@pytest.fixture
def activities_app() -> FastAPI:
    app = FastAPI()
    app.include_router(router)
    return app


@pytest.fixture
def mock_conn() -> MagicMock:
    c = MagicMock()
    c.fetchval = AsyncMock()
    c.fetchrow = AsyncMock()
    c.fetch = AsyncMock()
    c.executemany = AsyncMock()

    class _Tx:
        async def __aenter__(self) -> None:
            return None

        async def __aexit__(self, *_a: object) -> None:
            return None

    c.transaction = MagicMock(return_value=_Tx())
    return c


@pytest.fixture
def override_activities_db(activities_app: FastAPI, mock_conn: MagicMock):
    async def _dep():
        yield mock_conn

    activities_app.dependency_overrides[require_pool_conn] = _dep
    yield
    activities_app.dependency_overrides.clear()


@pytest.mark.anyio
async def test_post_activity_persists_in_transaction(
    activities_app: FastAPI,
    mock_conn: MagicMock,
    override_activities_db: None,
) -> None:
    aid = uuid4()
    uid = uuid4()
    mock_conn.fetchval.return_value = aid

    mock_conn.fetchrow.return_value = {
        "id": str(aid),
        "user_id": str(uid),
        "recorded_at": datetime(2026, 1, 1, 12, 0, 0, tzinfo=UTC),
        "stats": {
            "point_timestamps": [_iso_ts()],
            "source_type": "gpx",
        },
    }
    mock_conn.fetch.side_effect = [
        [
            {
                "lon": 8.5,
                "lat": 47.5,
                "elev_m": 1000.0,
                "speed_kmh": 5.0,
                "segment_type": None,
            }
        ],
        [],
    ]

    body = {
        "user_id": str(uid),
        "processed_track": {
            "id": "track-1",
            "points": [
                {
                    "lat": 47.5,
                    "lon": 8.5,
                    "elevation_m": 1000.0,
                    "timestamp": _iso_ts(),
                    "speed_kmh": 5.0,
                }
            ],
            "recorded_at": _iso_ts(),
            "source_type": "gpx",
        },
        "segments": [],
    }

    transport = httpx.ASGITransport(app=activities_app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        r = await client.post("/activities", json=body)

    assert r.status_code == 201
    data = r.json()
    assert data["id"] == str(aid)
    assert len(data["processed_track"]["points"]) == 1
    mock_conn.transaction.assert_called_once()
    assert mock_conn.executemany.await_count == 1


@pytest.mark.anyio
async def test_get_activity_detail(
    activities_app: FastAPI,
    mock_conn: MagicMock,
    override_activities_db: None,
) -> None:
    aid = uuid4()
    uid = uuid4()
    mock_conn.fetchrow.return_value = {
        "id": str(aid),
        "user_id": str(uid),
        "recorded_at": datetime(2026, 1, 1, 12, 0, 0, tzinfo=UTC),
        "stats": {"point_timestamps": [_iso_ts()], "source_type": "gpx"},
    }
    mock_conn.fetch.side_effect = [
        [
            {
                "lon": 8.5,
                "lat": 47.5,
                "elev_m": 1000.0,
                "speed_kmh": 5.0,
                "segment_type": None,
            }
        ],
        [
            {
                "type": "descent",
                "start_idx": 0,
                "end_idx": 0,
                "trail_name": "Run A",
                "difficulty": "easy",
            }
        ],
    ]

    transport = httpx.ASGITransport(app=activities_app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        r = await client.get(f"/activities/{aid}")

    assert r.status_code == 200
    d = r.json()
    assert d["segments"][0]["trail_name"] == "Run A"
    assert d["segments"][0]["difficulty"] == "easy"


@pytest.mark.anyio
async def test_get_activity_404(activities_app: FastAPI, mock_conn: MagicMock, override_activities_db: None) -> None:
    mock_conn.fetchrow.return_value = None

    transport = httpx.ASGITransport(app=activities_app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        r = await client.get(f"/activities/{uuid4()}")

    assert r.status_code == 404


@pytest.mark.anyio
async def test_list_activities_paginated(
    activities_app: FastAPI,
    mock_conn: MagicMock,
    override_activities_db: None,
) -> None:
    uid = uuid4()
    mock_conn.fetchval.return_value = 2
    mock_conn.fetch.return_value = [
        {
            "id": str(uuid4()),
            "user_id": str(uid),
            "recorded_at": datetime(2026, 1, 2, 12, 0, 0, tzinfo=UTC),
            "stats": None,
        },
        {
            "id": str(uuid4()),
            "user_id": str(uid),
            "recorded_at": datetime(2026, 1, 1, 12, 0, 0, tzinfo=UTC),
            "stats": None,
        },
    ]

    transport = httpx.ASGITransport(app=activities_app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        r = await client.get("/activities", params={"user_id": str(uid), "limit": 10, "offset": 0})

    assert r.status_code == 200
    data = r.json()
    assert data["total"] == 2
    assert data["limit"] == 10
    assert data["offset"] == 0
    assert len(data["items"]) == 2


@pytest.mark.anyio
async def test_list_activities_requires_user_id(activities_app: FastAPI, override_activities_db: None) -> None:
    transport = httpx.ASGITransport(app=activities_app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        r = await client.get("/activities")

    assert r.status_code == 422


@pytest.mark.anyio
async def test_create_activity_segment_index_validation(
    activities_app: FastAPI, override_activities_db: None
) -> None:
    uid = str(uuid4())
    body = {
        "user_id": uid,
        "processed_track": {
            "id": "t",
            "points": [
                {
                    "lat": 47.5,
                    "lon": 8.5,
                    "elevation_m": 1000.0,
                    "timestamp": _iso_ts(),
                    "speed_kmh": 5.0,
                }
            ],
            "recorded_at": _iso_ts(),
            "source_type": "gpx",
        },
        "segments": [
            {
                "type": "descent",
                "points": [],
                "start_index": 0,
                "end_index": 5,
                "trail_name": None,
                "difficulty": None,
            }
        ],
    }

    transport = httpx.ASGITransport(app=activities_app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        r = await client.post("/activities", json=body)

    assert r.status_code == 422


@pytest.mark.anyio
async def test_activities_503_without_pool(activities_app: FastAPI, monkeypatch: pytest.MonkeyPatch) -> None:
    import db.connection as db_conn

    monkeypatch.setattr(db_conn, "get_pool", lambda: None)

    transport = httpx.ASGITransport(app=activities_app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        r = await client.get(f"/activities/{uuid4()}")

    assert r.status_code == 503
