"""Port contracts for sync_worker_service."""

from typing import Protocol

import asyncpg


class SkiRunsSyncRunner(Protocol):
    """Run one sync cycle and return written row count."""

    async def __call__(self, conn: asyncpg.Connection, url: str | None = None) -> int: ...


_sync_runner_provider: SkiRunsSyncRunner | None = None


def set_sync_runner_provider(provider: SkiRunsSyncRunner) -> None:
    """Register the runtime implementation for OpenSkiMap sync jobs."""
    global _sync_runner_provider
    _sync_runner_provider = provider


async def run_sync(conn: asyncpg.Connection, url: str | None = None) -> int:
    """Run sync through the configured provider."""
    if _sync_runner_provider is None:
        raise RuntimeError("sync runner provider is not configured")
    return await _sync_runner_provider(conn, url=url)
