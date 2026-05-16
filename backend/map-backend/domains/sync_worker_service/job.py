"""OpenSkiMap sync worker entrypoints for domain-owned scheduling."""

import asyncpg

from domains.sync_worker_service.ports import run_sync


async def run_openskimap_sync(conn: asyncpg.Connection, url: str | None = None) -> int:
    """Run one OpenSkiMap ingest cycle and return written row count."""
    return await run_sync(conn, url=url)
