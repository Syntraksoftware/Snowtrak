"""Storage backend initialization and health checks for map-backend."""

from __future__ import annotations

import logging
from importlib import import_module

from config import get_config
from services.supabase_client import initialize_map_client

logger = logging.getLogger(__name__)

_storage_state: dict[str, bool | str] = {
    "initialized": False,
    "backend": "unknown",
}


def _postgis_probe(dsn: str, timeout: int) -> None:
    psycopg = import_module("psycopg")
    with psycopg.connect(dsn, connect_timeout=timeout) as connection, connection.cursor() as cursor:
        cursor.execute("SELECT 1")
        cursor.fetchone()


def initialize_storage_backend() -> None:
    """Initialize the configured map storage backend once at startup."""
    config = get_config()
    backend = config.MAP_STORAGE_BACKEND

    if backend == "supabase":
        initialize_map_client()
        _storage_state["initialized"] = True
        _storage_state["backend"] = "supabase"
        return

    if backend == "postgis":
        # Validate connectivity early so misconfiguration fails fast at startup.
        _postgis_probe(config.postgis_dsn, timeout=5)

        _storage_state["initialized"] = True
        _storage_state["backend"] = "postgis"
        return

    raise RuntimeError(f"Unsupported MAP_STORAGE_BACKEND: {backend}")


def get_storage_health() -> dict[str, str | bool]:
    """Return backend + connectivity details for health reporting."""
    config = get_config()
    backend = config.MAP_STORAGE_BACKEND

    if backend == "supabase":
        return {
            "backend": "supabase",
            "initialized": bool(_storage_state.get("initialized", False)),
            "status": "healthy" if _storage_state.get("initialized") else "uninitialized",
        }

    if backend == "postgis":
        try:
            _postgis_probe(config.postgis_dsn, timeout=3)
            return {
                "backend": "postgis",
                "initialized": bool(_storage_state.get("initialized", False)),
                "status": "healthy",
            }
        except Exception as exception:
            logger.warning("PostGIS health check failed: %s", exception)
            return {
                "backend": "postgis",
                "initialized": bool(_storage_state.get("initialized", False)),
                "status": "unhealthy",
                "error": "storage_error",
            }

    return {
        "backend": backend,
        "initialized": bool(_storage_state.get("initialized", False)),
        "status": "unknown",
    }
