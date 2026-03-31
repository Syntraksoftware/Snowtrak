import pytest
from fastapi.testclient import TestClient

import main as activity_main
from middleware.auth import get_current_user, get_optional_user
from routes import activities_list_routes, activities_management_routes, activities_social_routes


class StubActivityClient:
    def __init__(self):
        self._activity = {
            "id": "activity-1",
            "user_id": "user-1",
            "activity_type": "ski",
            "name": "Morning Run",
            "description": "Fresh powder",
            "distance_meters": 1200.0,
            "duration_seconds": 600,
            "elevation_gain_meters": 100.0,
            "visibility": "public",
            "created_at": "2026-01-01T00:00:00Z",
            "start_time": "2026-01-01T00:00:00Z",
            "end_time": "2026-01-01T00:10:00Z",
            "gps_path": [
                {
                    "lat": 45.0,
                    "lng": -73.0,
                    "elevation": 100.0,
                    "timestamp": "2026-01-01T00:00:00Z",
                },
                {
                    "lat": 45.001,
                    "lng": -73.001,
                    "elevation": 120.0,
                    "timestamp": "2026-01-01T00:05:00Z",
                },
            ],
        }
        self._private_activity = {
            **self._activity,
            "id": "activity-private",
            "visibility": "private",
        }

    def create_activity(self, **kwargs):
        activity = dict(self._activity)
        activity.update(
            {
                "name": kwargs.get("name", activity["name"]),
                "description": kwargs.get("description"),
                "user_id": kwargs.get("user_id", "user-1"),
                "visibility": kwargs.get("visibility", "public"),
            }
        )
        return activity

    def list_activities(self, limit=20, offset=0):
        return {"items": [self._activity], "total": 1}

    def list_user_activities(self, **kwargs):
        return {"items": [self._activity], "total": 1}

    def get_activity_by_id(self, activity_id):
        if activity_id == "activity-1":
            return self._activity
        if activity_id == "activity-private":
            return self._private_activity
        return None

    def update_activity(self, activity_id, user_id, name=None, description=None, visibility=None):
        if activity_id != "activity-1":
            return None
        updated = dict(self._activity)
        if name is not None:
            updated["name"] = name
        if description is not None:
            updated["description"] = description
        if visibility is not None:
            updated["visibility"] = visibility
        return updated

    def delete_activity(self, activity_id, user_id):
        return activity_id == "activity-1" and user_id == "user-1"

    def toggle_kudos(self, activity_id, user_id):
        return {"liked": True}

    def list_comments(self, activity_id, limit=50, offset=0):
        return {
            "items": [
                {
                    "id": "comment-1",
                    "activity_id": activity_id,
                    "user_id": "user-2",
                    "content": "Great run",
                    "created_at": "2026-01-01T00:20:00Z",
                }
            ],
            "total": 1,
        }

    def add_comment(self, activity_id, user_id, content):
        if not content.strip():
            return None
        return {
            "id": "comment-2",
            "activity_id": activity_id,
            "user_id": user_id,
            "content": content,
            "created_at": "2026-01-01T00:21:00Z",
        }

    def create_share_link(self, activity_id, user_id):
        return {
            "share_token": "share-1",
            "share_url": "/activities/share/share-1",
        }


@pytest.fixture
def stub_client():
    return StubActivityClient()


@pytest.fixture
def app(monkeypatch, stub_client):
    monkeypatch.setattr(activity_main, "initialize_activity_client", lambda: stub_client)
    monkeypatch.setattr(activities_management_routes, "get_activity_client", lambda: stub_client)
    monkeypatch.setattr(activities_list_routes, "get_activity_client", lambda: stub_client)
    monkeypatch.setattr(activities_social_routes, "get_activity_client", lambda: stub_client)

    activity_main.app.dependency_overrides[get_current_user] = lambda: "user-1"
    activity_main.app.dependency_overrides[get_optional_user] = lambda: "user-1"

    yield activity_main.app

    activity_main.app.dependency_overrides.clear()


@pytest.fixture
def client(app):
    with TestClient(app) as test_client:
        yield test_client
