"""Infrastructure implementations for trails_service ports."""

from collections.abc import AsyncGenerator

import asyncpg
from db.connection import get_pool
from fastapi import HTTPException, status


async def get_trails_conn() -> AsyncGenerator[asyncpg.Connection, None]:
    """Yield one pooled connection for trails routes."""
    pool = get_pool()
    if pool is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Postgres pool not configured (set SYNTRAK_DATABASE_URL)",
        )
    async with pool.acquire() as conn:
        yield conn
