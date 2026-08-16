"""Port contracts for activities_service."""

from collections.abc import AsyncGenerator
from typing import Protocol

import asyncpg


class ThumbnailUploader(Protocol):
    """Provider that uploads a route thumbnail PNG and returns its public URL."""

    def __call__(self, activity_id: str, png_bytes: bytes) -> str: ...


class ActivitiesConnectionProvider(Protocol):
    """Dependency provider that yields one activity DB connection."""

    def __call__(self) -> AsyncGenerator[asyncpg.Connection, None]: ...


_activities_conn_provider: ActivitiesConnectionProvider | None = None


def set_activities_conn_provider(provider: ActivitiesConnectionProvider) -> None:
    """Register the runtime implementation for activities DB connections."""
    global _activities_conn_provider
    _activities_conn_provider = provider


async def get_activities_conn() -> AsyncGenerator[asyncpg.Connection, None]:
    """Yield one activity connection through the configured provider."""
    if _activities_conn_provider is None:
        raise RuntimeError("activities connection provider is not configured")
    async for conn in _activities_conn_provider():
        yield conn


_thumbnail_uploader: ThumbnailUploader | None = None


def set_thumbnail_uploader(provider: ThumbnailUploader) -> None:
    """Register the runtime implementation for thumbnail uploads."""
    global _thumbnail_uploader
    _thumbnail_uploader = provider


def upload_thumbnail(activity_id: str, png_bytes: bytes) -> str:
    """Upload a route thumbnail through the configured provider."""
    if _thumbnail_uploader is None:
        raise RuntimeError("thumbnail uploader is not configured")
    return _thumbnail_uploader(activity_id, png_bytes)
