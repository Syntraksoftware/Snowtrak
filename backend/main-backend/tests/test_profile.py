"""GET and PUT /api/v1/users/me/profile, and GET /api/v1/users/{id}/profile.

Migration 022 gives every user a `profiles` row and takes `full_name` and
`username` off that table. The identity fields therefore have to be overlaid
from `user_info` on every response -- a row that exists is not a reason to
skip the overlay, it is the case that used to lose the name.
"""

import pytest
from fastapi import status

from app.api.v1 import users_profile_routes
from app.core.supabase import supabase_client


@pytest.fixture
def stub_profiles(monkeypatch, stub_supabase):
    """Add the `profiles` slice to the shared `user_info` stub.

    Also bypasses the Redis-backed profile cache, so a test sees what the
    route built rather than what a previous test left behind.
    """
    rows: dict[str, dict[str, object]] = {}

    def get_profile_by_id(user_id: str) -> dict[str, object] | None:
        return rows.get(user_id)

    def create_profile(user_id: str, **_: object) -> dict[str, object]:
        rows[user_id] = {"id": user_id}
        return rows[user_id]

    def update_profile(user_id: str, **fields: object) -> dict[str, object]:
        row = rows.setdefault(user_id, {"id": user_id})
        row.update({k: v for k, v in fields.items() if v is not None})
        return row

    monkeypatch.setattr(supabase_client, "get_profile_by_id", get_profile_by_id)
    monkeypatch.setattr(supabase_client, "create_profile", create_profile)
    monkeypatch.setattr(supabase_client, "update_profile", update_profile)
    monkeypatch.setattr(users_profile_routes, "get_profile", lambda user_id: None)
    monkeypatch.setattr(users_profile_routes, "set_profile", lambda user_id, profile: None)

    stub_supabase.profiles = rows
    return stub_supabase


class TestProfileIdentityOverlay:
    def test_a_user_with_a_profiles_row_still_gets_their_name(self, client, stub_profiles):
        # The post-022 shape: a real row, carrying none of the identity.
        stub_profiles.profiles["user-1"] = {"id": "user-1", "bio": "Powder only"}
        stub_profiles.user_info["user-1"]["username"] = "snowking"

        response = client.get("/api/v1/users/me/profile")

        assert response.status_code == status.HTTP_200_OK
        body = response.json()
        assert body["username"] == "snowking"
        assert body["full_name"] == "Stub User"
        assert body["bio"] == "Powder only"

    def test_a_user_with_no_profiles_row_gets_their_name_too(self, client, stub_profiles):
        stub_profiles.user_info["user-1"]["username"] = "snowking"

        response = client.get("/api/v1/users/me/profile")

        assert response.status_code == status.HTTP_200_OK
        assert response.json()["username"] == "snowking"
        assert response.json()["full_name"] == "Stub User"

    def test_the_country_setting_reads_back(self, client, stub_profiles):
        # country_code moved to user_info in 021 and is never on the row.
        stub_profiles.profiles["user-1"] = {"id": "user-1"}
        stub_profiles.user_info["user-1"]["country_code"] = "CH"

        assert client.get("/api/v1/users/me/profile").json()["country_code"] == "CH"

    def test_a_save_returns_the_name_it_did_not_write(self, client, stub_profiles):
        stub_profiles.profiles["user-1"] = {"id": "user-1"}
        stub_profiles.user_info["user-1"]["username"] = "snowking"

        response = client.put("/api/v1/users/me/profile", json={"bio": "Powder only"})

        assert response.status_code == status.HTTP_200_OK
        body = response.json()
        assert body["username"] == "snowking"
        assert body["full_name"] == "Stub User"
        assert body["bio"] == "Powder only"

    def test_another_users_profile_carries_their_handle(self, client, stub_profiles):
        stub_profiles.user_info["user-2"] = {
            "id": "user-2",
            "email": "user-2@example.com",
            "first_name": "Other",
            "last_name": "Skier",
            "username": "carver",
        }
        stub_profiles.profiles["user-2"] = {"id": "user-2"}

        response = client.get("/api/v1/users/user-2/profile")

        assert response.status_code == status.HTTP_200_OK
        assert response.json()["username"] == "carver"

    def test_an_unknown_user_is_not_found(self, client, stub_profiles):
        response = client.get("/api/v1/users/nobody/profile")

        assert response.status_code == status.HTTP_404_NOT_FOUND

    def test_full_name_is_not_settable_here(self, client, stub_profiles):
        # It lives on user_info now; PUT /users/me is where it is written.
        response = client.put(
            "/api/v1/users/me/profile",
            json={"bio": "x", "full_name": "Someone Else"},
        )

        assert response.status_code == status.HTTP_200_OK
        assert response.json()["full_name"] == "Stub User"
