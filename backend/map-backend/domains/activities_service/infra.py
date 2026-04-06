"""Infrastructure implementations for activities_service ports."""

from collections.abc import AsyncGenerator

import asyncpg

from db.connection import require_pool_conn


async def get_activities_conn() -> AsyncGenerator[asyncpg.Connection, None]:
    """Yield one pooled connection for activities routes."""
    async for conn in require_pool_conn():
        yield conn
