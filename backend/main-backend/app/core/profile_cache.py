"""Redis-backed cache for profile reads.

A profile read is one round trip to Supabase, which sits in another region --
roughly 440ms of pure distance before Postgres does any work. It is also on
the path of every profile open, so it is worth not paying twice.

Kept deliberately small: get, set, invalidate. The weather cache next door has
a Protocol and an in-memory fallback because it has a service to satisfy; this
has one caller.
"""

from __future__ import annotations

import json
import logging
from typing import Any

import redis

from app.core.config import settings

logger = logging.getLogger(__name__)

_client: redis.Redis | None = None
_initialized = False


def _get_client() -> redis.Redis | None:
    global _client, _initialized

    if _initialized:
        return _client

    _initialized = True
    if not settings.profile_cache_enabled:
        logger.info("Profile cache disabled via PROFILE_CACHE_ENABLED=false")
        return None

    try:
        _client = redis.from_url(settings.profile_cache_redis_url, decode_responses=True)
        logger.info("Profile cache initialized (redis=%s)", settings.profile_cache_redis_url)
    except Exception as exception:
        # A cache that cannot start must not take the endpoint down with it.
        _client = None
        logger.warning("Failed to initialize profile cache: %s", exception)

    return _client


def _key(user_id: str) -> str:
    return f"{settings.profile_cache_namespace}:profile:{user_id}"


def get_profile(user_id: str) -> dict[str, Any] | None:
    client = _get_client()
    if client is None:
        return None

    try:
        raw = client.get(_key(user_id))
        if raw is None:
            return None
        value = json.loads(raw)
        return value if isinstance(value, dict) else None
    except Exception as exception:
        logger.warning("Failed to read cached profile %s: %s", user_id, exception)
        return None


def set_profile(user_id: str, profile: dict[str, Any]) -> None:
    client = _get_client()
    if client is None:
        return

    try:
        client.setex(
            _key(user_id),
            max(1, settings.profile_cache_ttl_seconds),
            json.dumps(profile, default=str),
        )
    except Exception as exception:
        logger.warning("Failed to cache profile %s: %s", user_id, exception)


def invalidate_profile(user_id: str) -> None:
    """Called on every profile write, so an edit shows up immediately."""
    client = _get_client()
    if client is None:
        return

    try:
        client.delete(_key(user_id))
    except Exception as exception:
        logger.warning("Failed to invalidate cached profile %s: %s", user_id, exception)
