"""Tests for ``POST /trails/match`` and ``GET /trails/resort``."""

from __future__ import annotations

from datetime import UTC, datetime
from unittest.mock import AsyncMock, MagicMock

import httpx
import pytest
from fastapi import FastAPI
from domains.trails_service.api import get_trails_conn, router


def _iso_ts() -> str:
    return datetime(2026, 1, 1, 12, 0, 0, tzinfo=UTC).isoformat()


@pytest.fixture
def trails_app() -> FastAPI:
    app = FastAPI()
    app.include_router(router)
    return app


@pytest.fixture
def mock_conn() -> MagicMock:
    c = MagicMock()
    c.fetch = AsyncMock()
    return c


@pytest.fixture
def override_trails_db(trails_app: FastAPI, mock_conn: MagicMock):
    async def _dep():
        yield mock_conn

    trails_app.dependency_overrides[get_trails_conn] = _dep
    yield
    trails_app.dependency_overrides.clear()


@pytest.mark.anyio
async def test_trails_match_fills_descents_only(
    trails_app: FastAPI,
    mock_conn: MagicMock,
    override_trails_db: None,
) -> None:
    mock_conn.fetch.return_value = [
        {"ord": 1, "name": "Piste A", "difficulty": "easy", "source_id": "x", "dist_m": 12.0},
    ]

    body = {
        "segments": [
            {
                "type": "lift",
                "points": [
                    {
                        "lat": 47.5,
                        "lon": 8.5,
                        "elevation_m": 1000.0,
                        "timestamp": _iso_ts(),
                        "speed_kmh": 5.0,
                    }
                ],
                "start_index": 0,
                "end_index": 0,
            },
            {
                "type": "descent",
                "points": [
                    {
                        "lat": 47.51,
                        "lon": 8.51,
                        "elevation_m": 990.0,
                        "timestamp": _iso_ts(),
                        "speed_kmh": 20.0,
                    }
                ],
                "start_index": 0,
                "end_index": 0,
            },
        ]
    }

    transport = httpx.ASGITransport(app=trails_app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        r = await client.post("/trails/match", json=body)

    assert r.status_code == 200
    data = r.json()
    assert len(data["segments"]) == 2
    assert data["segments"][0]["trail_name"] is None
    assert data["segments"][1]["trail_name"] == "Piste A"
    assert data["segments"][1]["difficulty"] == "easy"
    mock_conn.fetch.assert_awaited_once()


@pytest.mark.anyio
async def test_trails_resort_geojson(
    trails_app: FastAPI,
    mock_conn: MagicMock,
    override_trails_db: None,
) -> None:
    mock_conn.fetch.return_value = [
        {
            "id": "uuid-1",
            "name": "Run One",
            "difficulty": "intermediate",
            "source_id": "s1",
            "geom_json": '{"type":"LineString","coordinates":[[8.0,47.0],[8.1,47.1]]}',
        }
    ]

    transport = httpx.ASGITransport(app=trails_app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        r = await client.get("/trails/resort", params={"bbox": "7.9,46.9,8.2,47.2"})

    assert r.status_code == 200
    data = r.json()
    assert data["type"] == "FeatureCollection"
    assert len(data["features"]) == 1
    f0 = data["features"][0]
    assert f0["properties"]["name"] == "Run One"
    assert f0["geometry"]["type"] == "LineString"
    mock_conn.fetch.assert_awaited_once()


@pytest.mark.anyio
async def test_trails_resort_bbox_validation(trails_app: FastAPI, override_trails_db: None) -> None:
    transport = httpx.ASGITransport(app=trails_app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        r = await client.get("/trails/resort", params={"bbox": "1,2,3"})

    assert r.status_code == 422


@pytest.mark.anyio
async def test_trails_match_503_without_pool(
    trails_app: FastAPI, monkeypatch: pytest.MonkeyPatch
) -> None:
    import db.connection as db_conn

    monkeypatch.setattr(db_conn, "get_pool", lambda: None)

    transport = httpx.ASGITransport(app=trails_app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        r = await client.post(
            "/trails/match",
            json={
                "points": [
                    {
                        "lat": 47.5,
                        "lon": 8.5,
                        "elevation_m": 1000.0,
                        "timestamp": _iso_ts(),
                        "speed_kmh": 1.0,
                    }
                ]
            },
        )

    assert r.status_code == 503
