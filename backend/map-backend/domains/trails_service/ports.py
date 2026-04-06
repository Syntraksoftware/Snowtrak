"""Port contracts for trails_service."""

from collections.abc import Sequence
from typing import Protocol

import asyncpg


class DescentMatcher(Protocol):
    """Match descent segments to nearest trail metadata."""

    async def __call__(
        self,
        conn: asyncpg.Connection,
        segments: Sequence,
        radius_m: float,
    ) -> list: ...
