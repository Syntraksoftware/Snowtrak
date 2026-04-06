"""Tests for ``POST /elevation/correct`` (Copernicus DEM router)."""

from __future__ import annotations

from datetime import UTC, datetime

import httpx
import numpy as np
import pytest
from fastapi import FastAPI
from domains.elevation_dem_service.api import clear_dem_correction_cache, router


@pytest.fixture(autouse=True)
def _clear_dem_cache() -> None:
    clear_dem_correction_cache()
    yield
    clear_dem_correction_cache()


@pytest.fixture
def dem_app() -> FastAPI:
    app = FastAPI()
    app.include_router(router)
    return app


def _sample_request(*, lat: float = 47.5, lon: float = 8.5) -> dict:
    return {
        "points": [
            {
                "lat": lat,
                "lon": lon,
                "elevation_m": None,
                "timestamp": datetime(2026, 1, 1, 12, 0, 0, tzinfo=UTC).isoformat(),
                "speed_kmh": 0.0,
            }
        ]
    }


@pytest.mark.anyio
async def test_elevation_correct_returns_dem_values(
    dem_app: FastAPI, monkeypatch: pytest.MonkeyPatch
) -> None:
    def fake_batch(coords: np.ndarray, **kwargs) -> np.ndarray:
        assert coords.shape == (2, 2)
        return np.array([123.4, 456.7], dtype=np.float64)

    monkeypatch.setattr("domains.elevation_dem_service.api.batch_correct", fake_batch)

    body = {
        "points": [
            {
                "lat": 47.5,
                "lon": 8.5,
                "elevation_m": None,
                "timestamp": datetime(2026, 1, 1, 12, 0, 0, tzinfo=UTC).isoformat(),
                "speed_kmh": 1.0,
            },
            {
                "lat": 47.51,
                "lon": 8.51,
                "elevation_m": 100.0,
                "timestamp": datetime(2026, 1, 1, 12, 1, 0, tzinfo=UTC).isoformat(),
                "speed_kmh": 2.0,
            },
        ]
    }

    transport = httpx.ASGITransport(app=dem_app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        r = await client.post("/elevation/correct", json=body)

    assert r.status_code == 200
    data = r.json()
    assert len(data["points"]) == 2
    assert data["points"][0]["elevation_m"] == pytest.approx(123.4)
    assert data["points"][1]["elevation_m"] == pytest.approx(456.7)
    assert data["points"][0]["lat"] == pytest.approx(47.5)


@pytest.mark.anyio
async def test_elevation_correct_cache_hits_on_identical_bbox_and_points(
    dem_app: FastAPI, monkeypatch: pytest.MonkeyPatch
) -> None:
    calls = {"n": 0}

    def fake_batch(coords: np.ndarray, **kwargs) -> np.ndarray:
        calls["n"] += 1
        return np.array([99.0], dtype=np.float64)

    monkeypatch.setattr("domains.elevation_dem_service.api.batch_correct", fake_batch)
    body = _sample_request()

    transport = httpx.ASGITransport(app=dem_app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        assert (await client.post("/elevation/correct", json=body)).status_code == 200
        assert (await client.post("/elevation/correct", json=body)).status_code == 200

    assert calls["n"] == 1


@pytest.mark.anyio
async def test_elevation_correct_cache_miss_when_points_differ(
    dem_app: FastAPI, monkeypatch: pytest.MonkeyPatch
) -> None:
    calls = {"n": 0}

    def fake_batch(coords: np.ndarray, **kwargs) -> np.ndarray:
        calls["n"] += 1
        n = coords.shape[0]
        return np.arange(100.0, 100.0 + n, dtype=np.float64)

    monkeypatch.setattr("domains.elevation_dem_service.api.batch_correct", fake_batch)

    transport = httpx.ASGITransport(app=dem_app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        assert (
            await client.post("/elevation/correct", json=_sample_request(lat=47.5))
        ).status_code == 200
        assert (
            await client.post("/elevation/correct", json=_sample_request(lat=47.6))
        ).status_code == 200

    assert calls["n"] == 2


@pytest.mark.anyio
async def test_elevation_correct_502_on_dem_nan(
    dem_app: FastAPI, monkeypatch: pytest.MonkeyPatch
) -> None:
    monkeypatch.setattr(
        "domains.elevation_dem_service.api.batch_correct",
        lambda *a, **k: np.array([float("nan")], dtype=np.float64),
    )

    transport = httpx.ASGITransport(app=dem_app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        r = await client.post("/elevation/correct", json=_sample_request())

    assert r.status_code == 502


@pytest.mark.anyio
async def test_elevation_correct_validation_error(dem_app: FastAPI) -> None:
    transport = httpx.ASGITransport(app=dem_app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        r = await client.post("/elevation/correct", json={"points": []})

    assert r.status_code == 422
