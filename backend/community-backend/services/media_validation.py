"""Shared rules for community media URLs attached to posts/comments."""

from __future__ import annotations

from services.constants.media_constants import MEDIA_BUCKET

# Must match Supabase public object URL path for our bucket.
MEDIA_PUBLIC_PATH_MARK = f"/storage/v1/object/public/{MEDIA_BUCKET}/"
MAX_MEDIA_ATTACHMENTS = 4
MAX_MEDIA_URL_LENGTH = 2048


def is_valid_community_media_url(url: str) -> bool:
    """Return true when url points at the public community media bucket."""
    value = (url or "").strip()
    return (
        bool(value)
        and len(value) <= MAX_MEDIA_URL_LENGTH
        and MEDIA_PUBLIC_PATH_MARK in value
        and (value.startswith("https://") or value.startswith("http://"))
    )


def normalize_media_urls(raw: list[str] | None) -> list[str]:
    """Return up to four validated URLs pointing at community-media bucket."""
    if not raw:
        return []
    out: list[str] = []
    for item in raw[:MAX_MEDIA_ATTACHMENTS]:
        url = (item or "").strip()
        if not is_valid_community_media_url(url):
            continue
        out.append(url)
    return out
