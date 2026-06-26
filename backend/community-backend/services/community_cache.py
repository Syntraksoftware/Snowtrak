"""Redis-backed response cache for community read endpoints."""

from __future__ import annotations

import json
import logging
from hashlib import sha256
from typing import Any

import redis.asyncio as redis

from config import get_config

logger = logging.getLogger(__name__)

_cache_client: redis.Redis | None = None
_media_cache_client: redis.Redis | None = None
_cache_initialized: bool = False


def initialize_community_cache() -> None:
    """Initialize the community Redis cache client once at startup."""
    global _cache_client, _media_cache_client, _cache_initialized

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
        _media_cache_client = redis.from_url(config.CACHE_REDIS_URL, decode_responses=False)
        logger.info(
            "Community response cache initialized (namespace=%s, redis=%s)",
            config.CACHE_NAMESPACE,
            config.CACHE_REDIS_URL,
        )
    except Exception as exception:
        _cache_client = None
        _media_cache_client = None
        logger.warning("Failed to initialize community response cache: %s", exception)


async def close_community_cache() -> None:
    """Close the community Redis cache client if it was initialized."""
    global _cache_client, _media_cache_client, _cache_initialized

    if _cache_client is None and _media_cache_client is None:
        _cache_initialized = False
        return

    try:
        if _cache_client is not None:
            await _cache_client.aclose()
        if _media_cache_client is not None:
            await _media_cache_client.aclose()
    finally:
        _cache_client = None
        _media_cache_client = None
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


async def _get_client() -> redis.Redis | None:
    if not _cache_initialized:
        initialize_community_cache()
    return _cache_client


async def _get_media_client() -> redis.Redis | None:
    if not _cache_initialized:
        initialize_community_cache()
    return _media_cache_client


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
        return int(raw) if raw is not None else 1
    except Exception as exception:
        logger.warning("Failed to read cache version for %s: %s", scope, exception)
        return 1


async def bump_cache_version(scope: str) -> int:
    client = await _get_client()
    if client is None:
        return 1

    try:
        return int(await client.incr(_version_key(scope)))
    except Exception as exception:
        logger.warning("Failed to bump cache version for %s: %s", scope, exception)
        return 1


async def invalidate_feed_cache() -> None:
    await bump_cache_version("feed")


async def invalidate_post_comments_cache(post_id: str) -> None:
    await bump_cache_version(f"post-comments:{post_id}")


def image_cache_key(url: str) -> str:
    digest = sha256(url.encode("utf-8")).hexdigest()
    return f"{_namespace()}:image:{digest}"


async def get_cached_image(url: str) -> tuple[bytes, str] | None:
    client = await _get_media_client()
    if client is None:
        return None

    base_key = image_cache_key(url)
    try:
        body, content_type = await client.mget(
            f"{base_key}:body",
            f"{base_key}:content-type",
        )
        if not body or not content_type:
            return None
        if isinstance(content_type, bytes):
            content_type = content_type.decode("utf-8")
        return body, str(content_type)
    except Exception as exception:
        logger.warning("Failed to read image cache key %s: %s", base_key, exception)
        return None


async def set_cached_image(
    url: str,
    body: bytes,
    content_type: str,
    ttl_seconds: int,
) -> None:
    client = await _get_media_client()
    if client is None:
        return

    base_key = image_cache_key(url)
    ttl = max(1, int(ttl_seconds))
    try:
        async with client.pipeline(transaction=True) as pipe:
            pipe.set(f"{base_key}:body", body, ex=ttl)
            pipe.set(f"{base_key}:content-type", content_type, ex=ttl)
            await pipe.execute()
    except Exception as exception:
        logger.warning("Failed to write image cache key %s: %s", base_key, exception)
