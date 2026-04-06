"""
Smoke tests for the full map FastAPI app (``application.create_app`` and ``backend/main.py``).

Validates routes respond and JSON bodies match declared response shapes where checked.
"""

from __future__ import annotations

import importlib.util
import sys
from pathlib import Path
from typing import Any
from unittest.mock import AsyncMock, MagicMock

import httpx
import numpy as np
import pytest
from pydantic import TypeAdapter

BACKEND = Path(__file__).resolve().parents[1]


def _ensure_paths() -> None:
    for p in (BACKEND / "map-backend", BACKEND):
        if str(p) not in sys.path:
            sys.path.insert(0, str(p))


@pytest.fixture
def smoke_env(monkeypatch: pytest.MonkeyPatch):
    _ensure_paths()
    monkeypatch.setenv("JWT_SECRET", "smoke-test-jwt-secret")
    monkeypatch.setenv("MAP_STORAGE_BACKEND", "supabase")
    monkeypatch.setenv("SUPABASE_URL", "https://smoke-test.supabase.co")
    monkeypatch.setenv("SUPABASE_SERVICE_ROLE_KEY", "smoke-test-service-role")

    import services.storage_backend as storage_backend

    def _mark_storage_ok() -> None:
        storage_backend._storage_state["initialized"] = True
        storage_backend._storage_state["backend"] = "supabase"

    monkeypatch.setattr(storage_backend, "initialize_storage_backend", _mark_storage_ok)

    import db.connection as db_connection

    monkeypatch.setattr(db_connection, "create_pool", AsyncMock(return_value=None))
    monkeypatch.setattr(db_connection, "close_pool", AsyncMock(return_value=None))

    from config import get_config

    get_config.cache_clear()
    yield


@pytest.fixture
def map_app_full(smoke_env: None, monkeypatch: pytest.MonkeyPatch):
    from db.connection import require_pool_conn
    from domains.trails_service.api import get_trails_conn

    from application import create_app

    app = create_app()

    async def _mock_trails_conn():
        c = MagicMock()
        c.fetch = AsyncMock(return_value=[])
        c.fetchrow = AsyncMock(return_value=None)
        yield c

    async def _mock_pool_conn():
        c = MagicMock()
        c.fetch = AsyncMock(return_value=[])
        c.fetchrow = AsyncMock(return_value=None)
        c.fetchval = AsyncMock(return_value=0)
        yield c

    app.dependency_overrides[get_trails_conn] = _mock_trails_conn
    app.dependency_overrides[require_pool_conn] = _mock_pool_conn

    from services import dem_service

    monkeypatch.setattr(
        dem_service,
        "batch_correct",
        lambda *_a, **_k: np.array([100.0], dtype=np.float64),
    )

    yield app
    app.dependency_overrides.clear()


@pytest.mark.anyio
async def test_map_app_get_routes_return_expected_shape(map_app_full) -> None:
    transport = httpx.ASGITransport(app=map_app_full)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        r_root = await client.get("/")
        assert r_root.status_code == 200
        root_ta = TypeAdapter(dict[str, str])
        root_ta.validate_python(r_root.json())

        r_health = await client.get("/health")
        assert r_health.status_code == 200
        TypeAdapter(dict[str, Any]).validate_python(r_health.json())

        r_openapi = await client.get("/openapi.json")
        assert r_openapi.status_code == 200
        spec = r_openapi.json()
        assert spec["openapi"].startswith("3.")
        paths = spec["paths"]
        assert "/trails/match" in paths
        assert "/trails/resort" in paths
        assert "/activities" in paths
        assert "/activities/{activity_id}" in paths
        assert "/elevation/correct" in paths

        r_docs = await client.get("/docs")
        assert r_docs.status_code == 200
        r_redoc = await client.get("/redoc")
        assert r_redoc.status_code == 200


@pytest.mark.parametrize(
    ("method", "path", "kwargs", "expected"),
    [
        ("POST", "/elevation/correct", {"json": {"points": []}}, 422),
        ("POST", "/trails/match", {"json": {}}, 422),
        ("GET", "/trails/resort", {}, 422),
    ],
)
@pytest.mark.anyio
async def test_map_app_validation_wired(
    map_app_full, method: str, path: str, kwargs: dict, expected: int
) -> None:
    transport = httpx.ASGITransport(app=map_app_full)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        r = await client.request(method, path, **kwargs)
    assert r.status_code == expected


@pytest.mark.anyio
async def test_trails_resort_geojson_schema(map_app_full) -> None:
    transport = httpx.ASGITransport(app=map_app_full)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        r = await client.get("/trails/resort", params={"bbox": "0,0,1,1"})
    assert r.status_code == 200
    body = r.json()
    assert body["type"] == "FeatureCollection"
    assert "features" in body
    assert isinstance(body["features"], list)


@pytest.mark.anyio
async def test_elevation_dem_correct_schema(map_app_full) -> None:
    from datetime import UTC, datetime

    from shared.track_pipeline_schemas import ElevationCorrectionResponse

    transport = httpx.ASGITransport(app=map_app_full)
    body = {
        "points": [
            {
                "lat": 47.5,
                "lon": 8.5,
                "elevation_m": None,
                "timestamp": datetime(2026, 1, 1, 12, 0, 0, tzinfo=UTC).isoformat(),
                "speed_kmh": 0.0,
            }
        ]
    }
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        r = await client.post("/elevation/correct", json=body)
    assert r.status_code == 200
    ElevationCorrectionResponse.model_validate(r.json())


@pytest.mark.anyio
async def test_backend_main_py_exports_same_app_type(
    smoke_env: None, monkeypatch: pytest.MonkeyPatch
) -> None:
    from db.connection import require_pool_conn
    from domains.trails_service.api import get_trails_conn

    async def _mock_trails_conn():
        c = MagicMock()
        c.fetch = AsyncMock(return_value=[])
        yield c

    async def _mock_pool_conn():
        c = MagicMock()
        c.fetch = AsyncMock(return_value=[])
        c.fetchrow = AsyncMock(return_value=None)
        c.fetchval = AsyncMock(return_value=0)
        yield c

    spec = importlib.util.spec_from_file_location("_syntrak_backend_main", BACKEND / "main.py")
    assert spec.loader is not None
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    app = mod.app
    app.dependency_overrides[get_trails_conn] = _mock_trails_conn
    app.dependency_overrides[require_pool_conn] = _mock_pool_conn
    from services import dem_service

    monkeypatch.setattr(
        dem_service,
        "batch_correct",
        lambda *_a, **_k: np.array([100.0], dtype=np.float64),
    )

    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        r = await client.get("/")
        assert r.status_code == 200
    app.dependency_overrides.clear()
