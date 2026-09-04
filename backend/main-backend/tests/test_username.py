"""PUT /api/v1/users/me/username.

The username is the identity every surface shows, so it is unique, lower
case, and its own route -- next to /me/privacy and /me/country, the two
other settings that live on user_info.
"""

from fastapi import status


class TestSetUsername:
    def test_sets_a_username(self, client, stub_supabase):
        response = client.put("/api/v1/users/me/username", json={"username": "snowking"})

        assert response.status_code == status.HTTP_200_OK
        assert response.json()["username"] == "snowking"

    def test_stores_it_lower_cased(self, client, stub_supabase):
        # One spelling, so the mention parser has one thing to match.
        response = client.put("/api/v1/users/me/username", json={"username": "SnowKing"})

        assert response.json()["username"] == "snowking"

    def test_a_taken_handle_is_a_conflict(self, client, stub_supabase):
        stub_supabase.taken_usernames.add("snowking")

        response = client.put("/api/v1/users/me/username", json={"username": "snowking"})

        assert response.status_code == status.HTTP_409_CONFLICT

    def test_resubmitting_your_own_handle_is_not_a_conflict(self, client, stub_supabase):
        stub_supabase.user_info["user-1"]["username"] = "snowking"

        response = client.put("/api/v1/users/me/username", json={"username": "snowking"})

        assert response.status_code == status.HTTP_200_OK
        assert response.json()["username"] == "snowking"

    def test_null_clears_it(self, client, stub_supabase):
        response = client.put("/api/v1/users/me/username", json={"username": None})

        assert response.status_code == status.HTTP_200_OK
        assert response.json()["username"] is None

    def test_rejects_shapes_that_would_break_a_mention(self, client, stub_supabase):
        for bad in ("ab", "a" * 21, "snow king", "snow.king", "snow-king"):
            response = client.put("/api/v1/users/me/username", json={"username": bad})
            assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY, bad
