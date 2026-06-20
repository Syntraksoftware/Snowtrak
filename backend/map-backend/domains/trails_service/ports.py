"""Port contracts for trails_service (resort GeoJSON reads)."""

import asyncpg

_trails_conn_provider = None


def set_trails_conn_provider(provider) -> None:
    """Register the runtime implementation for trails DB connections."""
    global _trails_conn_provider
    _trails_conn_provider = provider


async def get_trails_conn():
    """Yield one trails connection through the configured provider."""
    if _trails_conn_provider is None:
        raise RuntimeError("trails connection provider is not configured")
    async for conn in _trails_conn_provider():
        yield conn
