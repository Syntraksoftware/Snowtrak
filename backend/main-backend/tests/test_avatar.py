"""POST /api/v1/users/me/profile/avatar.

Finding A: a brand-new user has no `profiles` row, and `update_profile` is an
UPDATE that returns None when it matches zero rows -- the route 500ed before
ever creating one, after the upload to storage had already succeeded.

Finding B: the route returned the bare `profiles` row handed back by the
write, and `full_name`/`username` are not columns there since migration 022
-- every successful upload nulled the name in the response.
"""

import io
from datetime import UTC, datetime

import pytest
from fastapi import status

from app.core.supabase import supabase_client


@pytest.fixture
def stub_avatar_storage(monkeypatch, stub_supabase):
    """Add the `profiles` slice and a fake `avatars` storage bucket.

    Mirrors `stub_profiles` in test_profile.py, duplicated rather than
    shared -- a fixture defined in a sibling test module is not visible
    across files without moving it to conftest.py, and this one also needs
    the storage-side stubs the profile tests don't.
    """
    rows: dict[str, dict[str, object]] = {}
    stored_objects: set[str] = set()

    def get_profile_by_id(user_id: str) -> dict[str, object] | None:
        return rows.get(user_id)

    def create_profile(user_id: str, **_: object) -> dict[str, object]:
        # A real insert always carries created_at -- the column defaults to
        # now() -- so the stub does too, to isolate the identity-overlay
        # assertions in the tests below from an unrelated missing field.
        rows[user_id] = {"id": user_id, "created_at": datetime.now(UTC).isoformat()}
        return rows[user_id]

    def update_profile(user_id: str, **fields: object) -> dict[str, object] | None:
        # Real Supabase UPDATE: zero matched rows comes back as None.
        row = rows.get(user_id)
        if row is None:
            return None
        row.update({k: v for k, v in fields.items() if v is not None})
        return row

    def upload_avatar(user_id: str, file_content: bytes, file_extension: str) -> str:
        url = f"https://stub.local/storage/v1/object/public/avatars/{user_id}/1.{file_extension}"
        stored_objects.add(url)
        return url

    def delete_avatar(user_id: str, avatar_url: str) -> bool:
        stored_objects.discard(avatar_url)
        return True

    monkeypatch.setattr(supabase_client, "get_profile_by_id", get_profile_by_id)
    monkeypatch.setattr(supabase_client, "create_profile", create_profile)
    monkeypatch.setattr(supabase_client, "update_profile", update_profile)
    monkeypatch.setattr(supabase_client, "upload_avatar", upload_avatar)
    monkeypatch.setattr(supabase_client, "delete_avatar", delete_avatar)

    stub_supabase.profiles = rows
    stub_supabase.stored_objects = stored_objects
    return stub_supabase


def _upload(client):
    return client.post(
        "/api/v1/users/me/profile/avatar",
        files={"file": ("avatar.png", io.BytesIO(b"fake-image-bytes"), "image/png")},
    )


class TestAvatarUpload:
    def test_upload_with_no_profiles_row_succeeds(self, client, stub_avatar_storage):
        # The post-registration shape: no `profiles` row exists yet.
        assert stub_avatar_storage.profiles == {}

        response = _upload(client)

        assert response.status_code == status.HTTP_200_OK
        assert response.json()["avatar_url"] is not None

    def test_upload_response_carries_identity_from_user_info(self, client, stub_avatar_storage):
        stub_avatar_storage.profiles["user-1"] = {
            "id": "user-1",
            "created_at": datetime.now(UTC).isoformat(),
        }
        stub_avatar_storage.user_info["user-1"]["username"] = "snowking"

        response = _upload(client)

        assert response.status_code == status.HTTP_200_OK
        body = response.json()
        assert body["username"] == "snowking"
        assert body["full_name"] == "Stub User"
