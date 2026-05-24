"""Unit tests for shared deprecation header middleware."""

from __future__ import annotations

import httpx
import pytest
from fastapi import FastAPI

from shared.deprecation import add_deprecation_middleware


@pytest.fixture
def deprecation_app() -> FastAPI:
    app = FastAPI()
    add_deprecation_middleware(
        app,
        {
            "/api/legacy": {
                "sunset_date": "Sun, 21 Jun 2026 00:00:00 GMT",
                "replacement": "/api/v1/current",
                "message": "Use /api/v1/current instead.",
            }
        },
    )

    @app.get("/api/legacy/items")
    def legacy_items() -> dict[str, str]:
        return {"status": "ok"}

    @app.get("/api/v1/current")
    def current_items() -> dict[str, str]:
        return {"status": "ok"}

    return app


@pytest.mark.anyio
async def test_deprecated_path_gets_headers(deprecation_app: FastAPI) -> None:
    transport = httpx.ASGITransport(app=deprecation_app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/api/legacy/items")

    assert response.status_code == 200
    assert response.headers.get("Deprecation") == "true"
    assert response.headers.get("Sunset") == "Sun, 21 Jun 2026 00:00:00 GMT"
    assert response.headers.get("Link") == '</api/v1/current>; rel="successor-version"'
    assert response.headers.get("X-Deprecation-Message") == "Use /api/v1/current instead."


@pytest.mark.anyio
async def test_canonical_path_has_no_deprecation_headers(deprecation_app: FastAPI) -> None:
    transport = httpx.ASGITransport(app=deprecation_app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/api/v1/current")

    assert response.status_code == 200
    assert "Deprecation" not in response.headers
