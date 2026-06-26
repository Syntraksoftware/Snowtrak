"""Inline media hydration for community post read responses."""

from __future__ import annotations

import asyncio
import base64
import logging
from typing import Any
from urllib.parse import urlparse

import httpx

from config import get_config
from services.community_cache import get_cached_image, set_cached_image
from services.media_validation import is_valid_community_media_url

logger = logging.getLogger(__name__)


def _is_allowed_image_url(url: str) -> bool:
    parsed = urlparse(url)
    supabase_host = urlparse(get_config().SUPABASE_URL).hostname
    return (
        is_valid_community_media_url(url)
        and parsed.scheme == "https"
        and parsed.hostname is not None
        and parsed.hostname == supabase_host
    )


def _inline_asset(
    url: str,
    body: bytes,
    content_type: str,
    cache_status: str,
) -> dict[str, Any]:
    return {
        "url": url,
        "content_type": content_type,
        "encoding": "base64",
        "data": base64.b64encode(body).decode("ascii"),
        "size_bytes": len(body),
        "cache_status": cache_status,
    }


async def _load_image_asset(url: str, client: httpx.AsyncClient) -> dict[str, Any] | None:
    if not _is_allowed_image_url(url):
        return None

    cached = await get_cached_image(url)
    if cached is not None:
        body, content_type = cached
        return _inline_asset(url, body, content_type, "HIT")

    try:
        response = await client.get(url)
    except httpx.RequestError as exc:
        logger.warning("Failed to fetch community media url %s: %s", url, exc)
        return None

    if response.status_code >= 400:
        logger.warning(
            "Community media url %s returned status %s",
            url,
            response.status_code,
        )
        return None

    content_type = response.headers.get("content-type", "application/octet-stream").split(
        ";"
    )[0]
    if not content_type.startswith("image/"):
        return None

    body = response.content
    config = get_config()
    if len(body) > max(0, int(config.MEDIA_INLINE_MAX_BYTES)):
        return None

    await set_cached_image(
        url,
        body,
        content_type,
        config.MEDIA_INLINE_CACHE_TTL_SECONDS,
    )
    return _inline_asset(url, body, content_type, "MISS")


async def attach_inline_media_assets_to_posts(
    post_records: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    """Return post records with image bytes attached from each record's media_urls."""
    if not post_records:
        return []

    hydrated = [dict(record) for record in post_records]
    image_urls = [
        url
        for record in hydrated
        for url in record.get("media_urls", [])
        if isinstance(url, str)
    ]
    if not image_urls:
        return hydrated

    async with httpx.AsyncClient(timeout=15.0, follow_redirects=True) as client:
        loaded = await asyncio.gather(
            *[_load_image_asset(url, client) for url in image_urls],
            return_exceptions=True,
        )

    assets_by_url: dict[str, dict[str, Any]] = {}
    for url, result in zip(image_urls, loaded):
        if isinstance(result, Exception):
            logger.warning("Failed to hydrate community media url %s: %s", url, result)
            continue
        if result is not None:
            assets_by_url[url] = result

    for record in hydrated:
        record["media_assets"] = [
            assets_by_url[url]
            for url in record.get("media_urls", [])
            if isinstance(url, str) and url in assets_by_url
        ]

    return hydrated


async def attach_inline_media_assets_to_post(
    post_record: dict[str, Any],
) -> dict[str, Any]:
    hydrated = await attach_inline_media_assets_to_posts([post_record])
    return hydrated[0] if hydrated else dict(post_record)
