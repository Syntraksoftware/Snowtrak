"""Infrastructure implementations for trails_service ports."""

from collections.abc import AsyncGenerator, Sequence

import asyncpg
from fastapi import HTTPException, status

from db.connection import get_pool
from services.trail_matcher import DescentSegmentInput, match_all_descents


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


async def match_descents(
    conn: asyncpg.Connection,
    segments: Sequence[DescentSegmentInput],
    radius_m: float,
):
    """Run trail matching through the default matcher implementation."""
    return await match_all_descents(conn, segments, radius_m)
