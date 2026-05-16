"""Port contracts for activities_service."""

from collections.abc import AsyncGenerator
from typing import Protocol

import asyncpg


class ActivitiesConnectionProvider(Protocol):
    """Dependency provider that yields one activity DB connection."""

    def __call__(self) -> AsyncGenerator[asyncpg.Connection, None]: ...


_activities_conn_provider: ActivitiesConnectionProvider | None = None


def set_activities_conn_provider(provider: ActivitiesConnectionProvider) -> None:
    """Register the runtime implementation for activities DB connections."""
    global _activities_conn_provider
    _activities_conn_provider = provider


async def get_activities_conn() -> AsyncGenerator[asyncpg.Connection, None]:
    """Yield one activity connection through the configured provider."""
    if _activities_conn_provider is None:
        raise RuntimeError("activities connection provider is not configured")
    async for conn in _activities_conn_provider():
        yield conn
