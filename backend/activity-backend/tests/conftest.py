import os

# Placeholder configuration, set before the service is imported. These services
# declare SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY and JWT_SECRET as required
# fields, so importing them constructs a Config that fails without values. The
# tests stub every outbound call, so the values only need to exist.
#
# setdefault writes into os.environ, which pydantic-settings ranks above the
# .env file. That makes the suite hermetic in both directions: it runs on a
# fresh clone with no .env, and it stops running against a developer's real
# Supabase credentials by accident.
os.environ.setdefault("SUPABASE_URL", "https://placeholder.supabase.co")
os.environ.setdefault("SUPABASE_SERVICE_ROLE_KEY", "placeholder-service-role-key")
os.environ.setdefault("JWT_SECRET", "placeholder-jwt-secret-for-tests-only")

import importlib.util
import sys
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

_ACTIVITY_BACKEND_ROOT = Path(__file__).resolve().parents[1]
_BACKEND_ROOT = _ACTIVITY_BACKEND_ROOT.parent
for path_entry in (str(_ACTIVITY_BACKEND_ROOT), str(_BACKEND_ROOT)):
    if path_entry not in sys.path:
        sys.path.insert(0, path_entry)

_main_spec = importlib.util.spec_from_file_location(
    "activity_backend_main",
    _ACTIVITY_BACKEND_ROOT / "main.py",
)
assert _main_spec and _main_spec.loader
activity_main = importlib.util.module_from_spec(_main_spec)
_main_spec.loader.exec_module(activity_main)
from shared.visibility import visible_rows_expression

from middleware.auth import get_current_user, get_optional_user
from routes import activities_list_routes, activities_management_routes, activities_social_routes


def _split_top_level(expression):
    """Split on commas that are not inside parentheses."""
    parts, depth, current = [], 0, ""
    for char in expression:
        if char == "(":
            depth += 1
        elif char == ")":
            depth -= 1
        if char == "," and depth == 0:
            parts.append(current)
            current = ""
        else:
            current += char
    if current:
        parts.append(current)
    return parts


def _matches_clause(row, clause):
    clause = clause.strip()
    if clause.startswith("and("):
        inner = clause[len("and(") : -1]
        return all(_matches_clause(row, part) for part in _split_top_level(inner))
    field, operator, value = clause.split(".", 2)
    actual = row.get(field)
    if operator == "eq":
        return str(actual) == value
    if operator == "in":
        allowed = value.strip("()").split(",") if value.strip("()") else []
        return str(actual) in allowed
    raise AssertionError(f"fake does not implement PostgREST operator {operator!r}")


def _matches_or(row, expression):
    """Evaluate a PostgREST `or` expression against one row.

    Copied from backend/community-backend/tests/test_operations_units.py --
    service directories are hyphenated and not importable packages, so this
    can't be shared by import. The visibility filter is the one place where a
    wrong predicate leaks somebody's activity instead of raising, so getting
    this evaluator subtly wrong would make the new tests pass against a
    broken predicate. Keep it byte-for-byte identical to the original.
    """
    return any(_matches_clause(row, clause) for clause in _split_top_level(expression))


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
            "processing_status": "ready",
            "map_activity_id": None,
            "storage_key": None,
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
        # Backs list_activities: a list of raw rows, filtered per-viewer via
        # the real shared.visibility.visible_rows_expression + the copied
        # PostgREST evaluator above, not through self._activity.
        self.activities = [self._activity]
        # (follower_id, followee_id) pairs, mirroring the `follows` table.
        self.follows: set[tuple[str, str]] = set()

    def create_activity(self, **kwargs):
        activity = dict(self._activity)
        activity.update(
            {
                "name": kwargs.get("name", activity["name"]),
                "description": kwargs.get("description"),
                "user_id": kwargs.get("user_id", "user-1"),
                "visibility": kwargs.get("visibility", "public"),
                "map_activity_id": kwargs.get("map_activity_id"),
                "processing_status": kwargs.get("processing_status", "ready"),
                "storage_key": kwargs.get("storage_key"),
                "max_pace": kwargs.get("max_pace"),
            }
        )
        if kwargs.get("activity_id"):
            activity["id"] = kwargs["activity_id"]
        self._activity = activity
        return activity

    def update_activity_pipeline_fields(self, activity_id, user_id, **kwargs):
        if activity_id != self._activity.get("id"):
            return None
        updated = dict(self._activity)
        for key, value in kwargs.items():
            if value is not None:
                updated[key] = value
        self._activity = updated
        return updated

    def create_signed_upload_url(self, bucket, storage_key, expires_in):
        return {
            "signed_url": f"https://storage.example/{bucket}/{storage_key}",
            "token": "upload-token",
        }

    def download_storage_object(self, bucket, storage_key):
        return b"<gpx></gpx>"

    def list_activities(self, viewer_id=None, following=None, limit=20, offset=0):
        expression = visible_rows_expression(viewer_id, following)
        visible = [row for row in self.activities if _matches_or(row, expression)]
        visible.sort(key=lambda row: row.get("created_at", ""), reverse=True)
        page = visible[offset : offset + limit]
        return {"items": page, "total": len(visible)}

    def following_ids(self, user_id):
        return [followee for follower, followee in self.follows if follower == user_id]

    def list_user_activities(self, **kwargs):
        return {"items": [self._activity], "total": 1}

    def get_activity_by_id(self, activity_id):
        # Checks self.activities first so tests that replace the list (as the
        # visibility tests do) are honored; falls back to the two fixed rows
        # so the pre-existing activity-1 / activity-private tests keep working
        # without every test having to repopulate self.activities.
        for row in self.activities:
            if row["id"] == activity_id:
                return row
        if activity_id == "activity-1":
            return self._activity
        if activity_id == "activity-private":
            return self._private_activity
        return None

    def update_activity(
        self,
        activity_id,
        user_id,
        name=None,
        description=None,
        visibility=None,
        on_leaderboard=None,
    ):
        if activity_id != "activity-1":
            return None
        updated = dict(self._activity)
        if name is not None:
            updated["name"] = name
        if description is not None:
            updated["description"] = description
        if visibility is not None:
            updated["visibility"] = visibility
        if on_leaderboard is not None:
            updated["on_leaderboard"] = on_leaderboard
        return updated

    def delete_activity(self, activity_id, user_id):
        if activity_id == "activity-1" and user_id == "user-1":
            self._activity = dict(self._activity)
            return True
        return False

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

    import routes.activities_upload_routes as upload_routes

    monkeypatch.setattr(upload_routes, "get_activity_client", lambda: stub_client)

    activity_main.app.dependency_overrides[get_current_user] = lambda: "user-1"
    activity_main.app.dependency_overrides[get_optional_user] = lambda: "user-1"

    yield activity_main.app

    activity_main.app.dependency_overrides.clear()


@pytest.fixture
def client(app):
    with TestClient(app) as test_client:
        yield test_client


@pytest.fixture
def as_user(app):
    """Override both auth dependencies to a given user id for one test."""

    def _set(user_id):
        app.dependency_overrides[get_current_user] = lambda: user_id
        app.dependency_overrides[get_optional_user] = lambda: user_id

    return _set
