"""Tests for ``GET /trails/resort`` (map-backend resort GeoJSON layer)."""

from __future__ import annotations

from unittest.mock import AsyncMock, MagicMock

import httpx
import pytest
from fastapi import FastAPI

from domains.trails_service.api import router
from domains.trails_service.ports import get_trails_conn


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
async def test_trails_resort_503_without_pool(
    trails_app: FastAPI, monkeypatch: pytest.MonkeyPatch
) -> None:
    import db.connection as db_conn

    from domains.trails_service.infra import get_trails_conn as trails_conn_impl
    from domains.trails_service.ports import set_trails_conn_provider

    set_trails_conn_provider(trails_conn_impl)
    monkeypatch.setattr(db_conn, "get_pool", lambda: None)

    transport = httpx.ASGITransport(app=trails_app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        r = await client.get("/trails/resort", params={"bbox": "0,0,1,1"})

    assert r.status_code == 503
