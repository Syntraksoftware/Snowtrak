"""OpenSkiMap sync worker entrypoints for domain-owned scheduling."""

import asyncpg

from services.openskimap_sync import sync_ski_runs_from_openskimap


async def run_openskimap_sync(conn: asyncpg.Connection, url: str | None = None) -> int:
    """Run one OpenSkiMap ingest cycle and return written row count."""
    return await sync_ski_runs_from_openskimap(conn, url=url)
