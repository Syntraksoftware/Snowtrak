"""Port contracts for sync_worker_service."""

from typing import Protocol

import asyncpg


class SkiRunsSyncRunner(Protocol):
    """Run one sync cycle and return written row count."""

    async def __call__(self, conn: asyncpg.Connection, url: str | None = None) -> int: ...
