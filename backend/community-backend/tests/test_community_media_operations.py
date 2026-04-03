"""Unit tests for community media upload normalization."""

from services.community_media_operations import normalize_upload_mime_and_extension


def test_normalize_octet_stream_heic():
    assert normalize_upload_mime_and_extension("application/octet-stream", "heic") == (
        "image/heic",
        "heic",
    )


def test_normalize_explicit_heic():
    assert normalize_upload_mime_and_extension("image/heic", "heic") == (
        "image/heic",
        "heic",
    )


def test_normalize_jpg_alias():
    assert normalize_upload_mime_and_extension("image/jpg", "jpg") == (
        "image/jpeg",
        "jpeg",
    )


def test_normalize_rejects_unknown():
    assert normalize_upload_mime_and_extension("application/octet-stream", "exe") is None
