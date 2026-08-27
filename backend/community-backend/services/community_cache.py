"""Redis-backed response cache for community read endpoints."""

from __future__ import annotations

import json
import logging
from typing import Any

import redis.asyncio as redis

from config import get_config

logger = logging.getLogger(__name__)

_cache_client: redis.Redis | None = None
_cache_initialized: bool = False


def initialize_community_cache() -> None:
    """Initialize the community Redis cache client once at startup."""
    global _cache_client, _cache_initialized

    if _cache_initialized:
        return

    _cache_initialized = True

    config = get_config()
    if not config.CACHE_ENABLED:
        logger.info("Community response cache disabled via CACHE_ENABLED=false")
        _cache_client = None
        return

    try:
        _cache_client = redis.from_url(config.CACHE_REDIS_URL, decode_responses=True)
        logger.info(
            "Community response cache initialized (namespace=%s, redis=%s)",
            config.CACHE_NAMESPACE,
            config.CACHE_REDIS_URL,
        )
    except Exception as exception:
        _cache_client = None
        logger.warning("Failed to initialize community response cache: %s", exception)


async def close_community_cache() -> None:
    """Close the community Redis cache client if it was initialized."""
    global _cache_client, _cache_initialized

    if _cache_client is None:
        _cache_initialized = False
        return

    try:
        await _cache_client.aclose()
    finally:
        _cache_client = None
        _cache_initialized = False


def _namespace() -> str:
    return get_config().CACHE_NAMESPACE


def _version_key(scope: str) -> str:
    return f"{_namespace()}:version:{scope}"


def _user_scope(current_user_id: str | None) -> str:
    return current_user_id.strip() if current_user_id else "anon"


def feed_cache_key(limit: int, offset: int, current_user_id: str | None, version: int) -> str:
    return (
        f"{_namespace()}:feed:limit:{limit}:offset:{offset}:user:{_user_scope(current_user_id)}"
        f":v:{version}"
    )


def post_comments_cache_key(post_id: str, current_user_id: str | None, version: int) -> str:
    return (
        f"{_namespace()}:post-comments:post:{post_id}:user:{_user_scope(current_user_id)}"
        f":v:{version}"
    )


def user_posts_cache_key(
    user_id: str, limit: int, offset: int, current_user_id: str | None, version: int
) -> str:
    return (
        f"{_namespace()}:user-posts:user:{user_id}:limit:{limit}:offset:{offset}"
        f":viewer:{_user_scope(current_user_id)}:v:{version}"
    )


def follow_stats_cache_key(user_id: str, current_user_id: str | None, version: int) -> str:
    return (
        f"{_namespace()}:follow-stats:user:{user_id}"
        f":viewer:{_user_scope(current_user_id)}:v:{version}"
    )


async def _get_client() -> redis.Redis | None:
    if not _cache_initialized:
        initialize_community_cache()
    return _cache_client


async def get_cached_json(key: str) -> Any | None:
    client = await _get_client()
    if client is None:
        return None

    try:
        raw = await client.get(key)
        if raw is None:
            return None
        return json.loads(raw)
    except Exception as exception:
        logger.warning("Failed to read cache key %s: %s", key, exception)
        return None


async def set_cached_json(key: str, value: Any, ttl_seconds: int) -> None:
    client = await _get_client()
    if client is None:
        return

    try:
        payload = json.dumps(value, default=str)
        await client.set(key, payload, ex=max(1, int(ttl_seconds)))
    except Exception as exception:
        logger.warning("Failed to write cache key %s: %s", key, exception)


async def get_cache_version(scope: str) -> int:
    client = await _get_client()
    if client is None:
        return 1

    try:
        raw = await client.get(_version_key(scope))
        # Absent means 0, not 1. bump_cache_version INCRs a missing key to 1,
        # so a default of 1 made the very first invalidation a no-op: keys
        # written at v:1 stayed readable after the bump. The feed hid this
        # behind a 15s TTL; anything with a longer one served stale data.
        return int(raw) if raw is not None else 0
    except Exception as exception:
        logger.warning("Failed to read cache version for %s: %s", scope, exception)
        return 0


async def bump_cache_version(scope: str) -> int:
    client = await _get_client()
    if client is None:
        return 1

    try:
        return int(await client.incr(_version_key(scope)))
    except Exception as exception:
        logger.warning("Failed to bump cache version for %s: %s", scope, exception)
        return 1


async def invalidate_post_caches() -> None:
    """Drop both views of the same posts.

    Every write that changes the feed also changes some author's profile list
    -- a repost or a delete can even change a different author's. Keeping them
    in one call is what stops the two from drifting apart the next time
    somebody adds a write path and remembers only one of them.
    """
    await bump_cache_version("feed")
    await bump_cache_version("user-posts")


async def invalidate_post_comments_cache(post_id: str) -> None:
    await bump_cache_version(f"post-comments:{post_id}")


async def invalidate_follow_stats_cache() -> None:
    """One global version for the whole follow graph.

    A follow changes the numbers on both profiles involved, and whether the
    other person sees a "Follows you" badge. Bumping one counter drops every
    cached snapshot, which costs a re-fetch on profiles nobody was looking at
    and keeps the invalidation impossible to get subtly wrong. Follows are
    rare compared to profile views.
    """
    await bump_cache_version("follow-stats")
