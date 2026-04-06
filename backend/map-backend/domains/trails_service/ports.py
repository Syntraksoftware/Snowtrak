"""Port contracts for trails_service."""

from collections.abc import Sequence
from dataclasses import dataclass
from typing import Protocol

import asyncpg


@dataclass
class DescentSegmentInput:
    """One descent polyline; a representative point is used for matching."""

    points: Sequence[tuple[float, float]]

    def representative_lat_lon(self) -> tuple[float, float]:
        if not self.points:
            raise ValueError("DescentSegmentInput.points must not be empty")
        n = len(self.points)
        lat = sum(p[0] for p in self.points) / n
        lon = sum(p[1] for p in self.points) / n
        return lat, lon


_trails_conn_provider = None
_descent_matcher_provider = None


class DescentMatcher(Protocol):
    """Match descent segments to nearest trail metadata."""

    async def __call__(
        self,
        conn: asyncpg.Connection,
        segments: Sequence[DescentSegmentInput],
        radius_m: float,
    ) -> list: ...


def set_trails_conn_provider(provider) -> None:
    """Register the runtime implementation for trails DB connections."""
    global _trails_conn_provider
    _trails_conn_provider = provider


def set_descent_matcher_provider(provider: DescentMatcher) -> None:
    """Register the runtime implementation for trail matching."""
    global _descent_matcher_provider
    _descent_matcher_provider = provider


async def get_trails_conn():
    """Yield one trails connection through the configured provider."""
    if _trails_conn_provider is None:
        raise RuntimeError("trails connection provider is not configured")
    async for conn in _trails_conn_provider():
        yield conn


async def match_descents(
    conn: asyncpg.Connection,
    segments: Sequence[DescentSegmentInput],
    radius_m: float,
):
    """Match descents through the configured provider."""
    if _descent_matcher_provider is None:
        raise RuntimeError("descent matcher provider is not configured")
    return await _descent_matcher_provider(conn, segments, radius_m)
