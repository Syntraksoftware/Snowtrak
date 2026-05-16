"""Infrastructure implementations for sync_worker_service ports."""

import asyncpg

from services.openskimap_sync import sync_ski_runs_from_openskimap


async def run_sync(conn: asyncpg.Connection, url: str | None = None) -> int:
    """Run the default OpenSkiMap sync implementation."""
    return await sync_ski_runs_from_openskimap(conn, url=url)
