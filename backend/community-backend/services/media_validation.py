"""Shared rules for community media URLs attached to posts/comments."""

from __future__ import annotations

from services.constants.media_constants import MEDIA_BUCKET

# Must match Supabase public object URL path for our bucket.
MEDIA_PUBLIC_PATH_MARK = f"/storage/v1/object/public/{MEDIA_BUCKET}/"
MAX_MEDIA_ATTACHMENTS = 4
MAX_MEDIA_URL_LENGTH = 2048


def normalize_media_urls(raw: list[str] | None) -> list[str]:
    """Return up to four validated URLs pointing at community-media bucket."""
    if not raw:
        return []
    out: list[str] = []
    for item in raw[:MAX_MEDIA_ATTACHMENTS]:
        url = (item or "").strip()
        if not url or len(url) > MAX_MEDIA_URL_LENGTH:
            continue
        if MEDIA_PUBLIC_PATH_MARK not in url:
            continue
        if not (url.startswith("https://") or url.startswith("http://")):
            continue
        out.append(url)
    return out
