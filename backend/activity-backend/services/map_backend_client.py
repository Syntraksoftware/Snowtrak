"""Internal HTTP client for map-backend (map_trail persistence)."""

from __future__ import annotations

import logging

import httpx

from config import get_config

logger = logging.getLogger(__name__)


class MapBackendClient:
    """Thin S2S client — activity-backend orchestrates; map-backend stays unaware."""

    def __init__(self, base_url: str | None = None, timeout_s: float | None = None) -> None:
        cfg = get_config()
        self._base_url = (base_url or cfg.MAP_BACKEND_BASE_URL).rstrip("/")
        self._timeout = httpx.Timeout(timeout_s or cfg.MAP_BACKEND_TIMEOUT_S)

    async def delete_map_activity(self, map_activity_id: str) -> None:
        """Delete map_trail activity; DB cascade removes track_points and segments."""
        url = f"{self._base_url}/activities/{map_activity_id}"
        async with httpx.AsyncClient(timeout=self._timeout) as client:
            response = await client.delete(url)

        if response.status_code == httpx.codes.NO_CONTENT:
            return
        if response.status_code == httpx.codes.NOT_FOUND:
            logger.warning(
                "map-backend activity %s not found during delete orchestration",
                map_activity_id,
            )
            return

        response.raise_for_status()

    async def correct_elevations(self, points: list[dict]) -> list[dict]:
        url = f"{self._base_url}/elevation/correct"
        async with httpx.AsyncClient(timeout=self._timeout) as client:
            response = await client.post(url, json={"points": points})
        response.raise_for_status()
        body = response.json()
        return list(body.get("points") or [])

    async def persist_pipeline_activity(self, body: dict) -> dict:
        url = f"{self._base_url}/activities"
        async with httpx.AsyncClient(timeout=self._timeout) as client:
            response = await client.post(url, json=body)
        response.raise_for_status()
        return response.json()


_map_backend_client: MapBackendClient | None = None


def get_map_backend_client() -> MapBackendClient:
    global _map_backend_client
    if _map_backend_client is None:
        _map_backend_client = MapBackendClient()
    return _map_backend_client
