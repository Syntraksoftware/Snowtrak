"""Port contracts for activities_service."""

from collections.abc import AsyncGenerator
from typing import Protocol

import asyncpg


class ActivitiesConnectionProvider(Protocol):
    """Dependency provider that yields one activity DB connection."""

    def __call__(self) -> AsyncGenerator[asyncpg.Connection, None]: ...
