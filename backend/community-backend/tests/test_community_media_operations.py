"""Unit tests for community media upload behavior."""

import services.community_media_operations as media_ops
from services.community_media_operations import (
    CommunityMediaOperations,
    normalize_upload_mime_and_extension,
)


class _FakeStorageBucket:
    def __init__(self):
        self.upload_calls = []

    def upload(self, *, path, file, file_options):
        self.upload_calls.append(
            {
                "path": path,
                "file": file,
                "file_options": file_options,
            }
        )

    def get_public_url(self, object_name):
        return f"https://stub.supabase.co/storage/v1/object/public/community-media/{object_name}"


class _FakeStorage:
    def __init__(self):
        self.bucket = _FakeStorageBucket()

    def from_(self, bucket):
        assert bucket == "community-media"
        return self.bucket


class _FakeSupabaseClient:
    def __init__(self):
        self.storage = _FakeStorage()


class _FakeCommunityMediaClient(CommunityMediaOperations):
    def __init__(self):
        self._client = _FakeSupabaseClient()


class _FakeConfig:
    MEDIA_CACHE_CONTROL_SECONDS = 31536000


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


def test_upload_sets_cache_control_header(monkeypatch):
    monkeypatch.setattr(media_ops, "get_config", lambda: _FakeConfig())
    client = _FakeCommunityMediaClient()

    result = client.upload_community_media(
        user_id="user-1",
        file_bytes=b"\x89PNG\r\n\x1a\n\x00",
        content_type="image/png",
        extension="png",
    )

    assert result.url is not None
    upload_call = client._client.storage.bucket.upload_calls[0]
    assert upload_call["file_options"]["content-type"] == "image/png"
    assert upload_call["file_options"]["cache-control"] == "31536000"
