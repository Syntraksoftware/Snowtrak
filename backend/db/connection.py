"""
Asyncpg connection pool for Postgres/PostGIS (map-backend).

Use with FastAPI ``lifespan``: ``await create_pool(...)`` on startup,
``await close_pool()`` on shutdown. Inject ``Depends(get_db)`` for a per-request
connection leased from the pool.
"""

from __future__ import annotations

import logging
import os
import re
from collections.abc import AsyncGenerator

import asyncpg
from fastapi import HTTPException, status

logger = logging.getLogger(__name__)

_pool: asyncpg.Pool | None = None


def normalize_asyncpg_dsn(url: str) -> str:
    """Turn SQLAlchemy-style URLs into a datasource name (DSN) asyncpg accepts (``postgresql://...``)."""
    return re.sub(r"^postgresql\+\w+://", "postgresql://", url.strip())
    # should return something like: postgresql://user:password@host:port/database


async def create_pool(
    *,
    dsn: str | None = None,
    min_size: int = 1,
    max_size: int = 10,
    command_timeout: float | None = 60.0,
) -> None:
    """
    Open a global asyncpg pool. Idempotent if already open (logs and returns).

    If ``dsn`` is omitted, reads ``SYNTRAK_DATABASE_URL``. If still unset, the pool
    is not created (map-backend can run without a local DB).
    """
    global _pool
    if _pool is not None:
        logger.warning("asyncpg pool already exists; skipping create_pool()")
        return

    raw = dsn if dsn is not None else os.environ.get("SYNTRAK_DATABASE_URL")
    if not raw:
        logger.info("No Postgres DSN provided; asyncpg pool disabled")
        return

    dsn_norm = normalize_asyncpg_dsn(raw)
    _pool = await asyncpg.create_pool(
        dsn=dsn_norm,
        min_size=min_size,
        max_size=max_size,
        command_timeout=command_timeout,
    )
    logger.info("asyncpg pool ready (min_size=%s max_size=%s)", min_size, max_size)


async def close_pool() -> None:
    """Close the global pool (no-op if none)."""
    global _pool
    if _pool is None:
        return
    await _pool.close()
    _pool = None
    logger.info("asyncpg pool closed")


def get_pool() -> asyncpg.Pool | None:
    """Return the active pool, or ``None`` if ``create_pool`` did not run or was skipped."""
    return _pool


async def get_db() -> AsyncGenerator[asyncpg.Connection, None]:
    """
    FastAPI dependency: yield one connection for the request, then return it to the pool.

    Raises:
        RuntimeError: if the pool was never created or ``create_pool`` was skipped.
    """
    pool = get_pool()
    if pool is None:
        raise RuntimeError(
            "asyncpg pool is not initialized; set SYNTRAK_DATABASE_URL (or pass dsn to "
            "create_pool) before using Depends(get_db)"
        )
    async with pool.acquire() as connection:
        yield connection


async def require_pool_conn() -> AsyncGenerator[asyncpg.Connection, None]:
    """FastAPI dependency: one pooled connection; HTTP 503 if the pool was never configured."""
    pool = get_pool()
    if pool is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Postgres pool not configured (set SYNTRAK_DATABASE_URL)",
        )
    async with pool.acquire() as conn:
        yield conn
