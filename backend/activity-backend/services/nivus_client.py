"""Internal HTTP client for the Nivus compute microservice."""

from __future__ import annotations

import httpx

from config import get_config


class NivusClient:
    def __init__(self, base_url: str | None = None, timeout_s: float | None = None) -> None:
        cfg = get_config()
        self._base_url = (base_url or cfg.NIVUS_BASE_URL).rstrip("/")
        self._timeout = httpx.Timeout(timeout_s or cfg.NIVUS_TIMEOUT_S)

    async def process_pipeline(self, body: dict) -> dict:
        url = f"{self._base_url}/api/v1/pipeline/process"
        async with httpx.AsyncClient(timeout=self._timeout) as client:
            response = await client.post(url, json=body)
        response.raise_for_status()
        return response.json()


_nivus_client: NivusClient | None = None


def get_nivus_client() -> NivusClient:
    global _nivus_client
    if _nivus_client is None:
        _nivus_client = NivusClient()
    return _nivus_client
