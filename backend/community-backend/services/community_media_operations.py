"""Upload binaries to Supabase Storage (community-media bucket)."""
from __future__ import annotations

import logging
import time
import uuid
from dataclasses import dataclass
from typing import Literal, Optional

from services.constants.media_constants import MEDIA_BUCKET, MEDIA_MAX_BYTES

logger = logging.getLogger(__name__)

_BUCKET = MEDIA_BUCKET
_MAX_BYTES = MEDIA_MAX_BYTES

# Canonical MIME types we accept after normalization.
_ALLOWED_MIMES = frozenset(
    {
        "image/png",
        "image/jpeg",
        "image/gif",
        "image/webp",
        "image/heic",
        "image/heif",
        "video/mp4",
        "video/quicktime",
    }
)

# Filename extension (no dot) -> MIME when client sends wrong/missing Content-Type.
_EXT_TO_MIME = {
    "png": "image/png",
    "jpg": "image/jpeg",
    "jpeg": "image/jpeg",
    "gif": "image/gif",
    "webp": "image/webp",
    "heic": "image/heic",
    "heif": "image/heif",
    "mp4": "video/mp4",
    "mov": "video/quicktime",
}

_MIME_TO_EXT = {
    "image/png": "png",
    "image/jpeg": "jpeg",
    "image/gif": "gif",
    "image/webp": "webp",
    "image/heic": "heic",
    "image/heif": "heif",
    "video/mp4": "mp4",
    "video/quicktime": "mov",
}

# Aliases from clients / older stacks.
_CT_ALIASES = {
    "image/jpg": "image/jpeg",
    "image/pjpeg": "image/jpeg",
    "image/x-png": "image/png",
}

UploadErrorCode = Literal[
    "too_large",
    "unsupported_type",
    "storage_error",
    "bucket_not_found",
]


@dataclass(frozen=True)
class CommunityMediaUploadResult:
    url: Optional[str] = None
    error: Optional[UploadErrorCode] = None


def normalize_upload_mime_and_extension(
    content_type: Optional[str],
    extension: Optional[str],
) -> Optional[tuple[str, str]]:
    """
    Resolve (content-type for storage, storage file extension) or None if unsupported.

    Handles application/octet-stream and missing types by inferring from the filename
    extension (common for mobile multipart uploads).
    """
    raw = (content_type or "").split(";")[0].strip().lower()
    raw = _CT_ALIASES.get(raw, raw)
    ext = (extension or "bin").lower().lstrip(".")
    if ext == "jpg":
        ext = "jpeg"

    def from_mime(mime: str) -> tuple[str, str]:
        storage_ext = _MIME_TO_EXT.get(mime, ext if ext != "bin" else "bin")
        return mime, storage_ext

    if raw in _ALLOWED_MIMES:
        mime = raw
        storage_ext = _MIME_TO_EXT.get(mime, ext)
        if storage_ext == "bin" and ext in _EXT_TO_MIME and _EXT_TO_MIME[ext] == mime:
            storage_ext = ext
        return mime, storage_ext

    if raw in ("", "application/octet-stream", "binary/octet-stream"):
        inferred = _EXT_TO_MIME.get(ext)
        if inferred and inferred in _ALLOWED_MIMES:
            return from_mime(inferred)
        return None

    inferred = _EXT_TO_MIME.get(ext)
    if inferred and inferred in _ALLOWED_MIMES:
        return from_mime(inferred)

    return None


class CommunityMediaOperations:
    """Mixin: requires self._client (Supabase)."""

    def upload_community_media(
        self,
        user_id: str,
        file_bytes: bytes,
        content_type: str,
        extension: str,
    ) -> CommunityMediaUploadResult:
        """Store file under user_id/… and return public object URL or error code."""
        if len(file_bytes) > _MAX_BYTES:
            logger.warning("Reject upload: size %s exceeds cap", len(file_bytes))
            return CommunityMediaUploadResult(error="too_large")

        normalized = normalize_upload_mime_and_extension(content_type, extension)
        if not normalized:
            logger.warning(
                "Reject upload: unsupported type ct=%r ext=%r",
                content_type,
                extension,
            )
            return CommunityMediaUploadResult(error="unsupported_type")

        ct, ext = normalized
        if ext == "jpg":
            ext = "jpeg"
        safe_user = (
            "".join(c for c in user_id if c.isalnum() or c in "-_")[:128] or "anon"
        )
        object_name = f"{safe_user}/{int(time.time() * 1000)}-{uuid.uuid4().hex[:10]}.{ext}"

        try:
            self._client.storage.from_(_BUCKET).upload(
                path=object_name,
                file=file_bytes,
                file_options={
                    "content-type": ct,
                    "upsert": "true",
                },
            )
            url = self._client.storage.from_(_BUCKET).get_public_url(object_name)
            return CommunityMediaUploadResult(url=url)
        except Exception as exc:
            logger.exception("community-media upload failed: %s", exc)
            err_text = str(exc).lower()
            if "bucket not found" in err_text:
                logger.error(
                    "Supabase Storage bucket %r is missing. Apply "
                    "backend/community-backend/SUPABASE_STORAGE_SETUP.sql in the Supabase SQL editor.",
                    _BUCKET,
                )
                return CommunityMediaUploadResult(error="bucket_not_found")
            return CommunityMediaUploadResult(error="storage_error")
