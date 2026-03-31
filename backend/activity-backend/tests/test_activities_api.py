from fastapi import status

from middleware.auth import get_current_user, get_optional_user


def _activity_payload():
    return {
        "type": "ski",
        "name": "Morning Run",
        "description": "Fresh powder",
        "start_time": "2026-01-01T00:00:00Z",
        "end_time": "2026-01-01T00:10:00Z",
        "is_public": True,
        "locations": [
            {
                "latitude": 45.0,
                "longitude": -73.0,
                "altitude": 100.0,
                "timestamp": "2026-01-01T00:00:00Z",
            },
            {
                "latitude": 45.001,
                "longitude": -73.001,
                "altitude": 120.0,
                "timestamp": "2026-01-01T00:05:00Z",
            },
        ],
    }


class TestActivityEndpoints:
    def test_create_activity_success(self, client):
        response = client.post("/api/v1/activities", json=_activity_payload())

        assert response.status_code == status.HTTP_201_CREATED
        body = response.json()
        assert body["id"] == "activity-1"
        assert body["type"] == "ski"
        assert body["is_public"] is True

    def test_create_activity_invalid_payload(self, client):
        payload = _activity_payload()
        payload.pop("type")

        response = client.post("/api/v1/activities", json=payload)

        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY

    def test_create_activity_invalid_time_returns_server_error(self, client):
        payload = _activity_payload()
        payload["start_time"] = "not-a-time"

        response = client.post("/api/v1/activities", json=payload)

        assert response.status_code == status.HTTP_500_INTERNAL_SERVER_ERROR

    def test_list_activities_standard_format(self, client):
        response = client.get("/api/v1/activities")

        assert response.status_code == status.HTTP_200_OK
        body = response.json()
        assert "items" in body
        assert "meta" in body
        assert body["meta"]["pagination"]["limit"] == 20

    def test_list_activities_invalid_limit(self, client):
        response = client.get("/api/v1/activities?limit=101")

        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY

    def test_get_activity_not_found(self, client):
        response = client.get("/api/v1/activities/missing")

        assert response.status_code == status.HTTP_404_NOT_FOUND

    def test_get_private_activity_visible_to_owner(self, client):
        response = client.get("/api/v1/activities/activity-private")

        assert response.status_code == status.HTTP_200_OK
        assert response.json()["id"] == "activity-private"

    def test_get_private_activity_hidden_for_non_owner(self, client, app):
        app.dependency_overrides[get_optional_user] = lambda: "user-2"

        response = client.get("/api/v1/activities/activity-private")

        assert response.status_code == status.HTTP_404_NOT_FOUND

    def test_get_private_activity_hidden_for_anonymous(self, client, app):
        app.dependency_overrides[get_optional_user] = lambda: None

        response = client.get("/api/v1/activities/activity-private")

        assert response.status_code == status.HTTP_404_NOT_FOUND

    def test_update_activity_not_found(self, client):
        response = client.put(
            "/api/v1/activities/missing",
            json={"name": "Updated"},
        )

        assert response.status_code == status.HTTP_404_NOT_FOUND

    def test_delete_activity_not_found(self, client):
        response = client.delete("/api/v1/activities/missing")

        assert response.status_code == status.HTTP_404_NOT_FOUND

    def test_toggle_kudos_success(self, client):
        response = client.post("/api/v1/activities/activity-1/kudos")

        assert response.status_code == status.HTTP_200_OK
        assert response.json()["liked"] is True

    def test_list_comments_success(self, client):
        response = client.get("/api/v1/activities/activity-1/comments")

        assert response.status_code == status.HTTP_200_OK
        body = response.json()
        assert body["total"] == 1
        assert body["items"][0]["id"] == "comment-1"

    def test_add_comment_success(self, client):
        response = client.post(
            "/api/v1/activities/activity-1/comments",
            json={"content": "Great line selection"},
        )

        assert response.status_code == status.HTTP_201_CREATED
        assert response.json()["content"] == "Great line selection"

    def test_add_comment_empty_content_rejected(self, client):
        response = client.post(
            "/api/v1/activities/activity-1/comments",
            json={"content": "   "},
        )

        assert response.status_code == status.HTTP_500_INTERNAL_SERVER_ERROR

    def test_share_link_success(self, client):
        response = client.post("/api/v1/activities/activity-1/share")

        assert response.status_code == status.HTTP_200_OK
        assert response.json()["share_token"] == "share-1"

    def test_requires_auth_when_override_removed(self, client, app):
        app.dependency_overrides.pop(get_current_user, None)

        response = client.post("/api/v1/activities", json=_activity_payload())

        assert response.status_code == status.HTTP_401_UNAUTHORIZED
