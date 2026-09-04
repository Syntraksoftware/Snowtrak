"""
Pytest configuration and shared fixtures.
"""

import pytest
from fastapi.testclient import TestClient

from app.api.dependencies import get_current_user
from app.core.security import hash_password
from app.core.storage import User, user_store
from app.core.supabase import supabase_client
from app.main import create_application


@pytest.fixture(scope="function")
def app(monkeypatch):
    """Create a fresh FastAPI app instance for each test."""
    # Tests use in-memory fixtures; disable Supabase path for deterministic auth flows.
    monkeypatch.setattr(supabase_client, "is_configured", lambda: False)
    return create_application()


@pytest.fixture(scope="function")
def client(app):
    """Create a test client for the app."""
    return TestClient(app)


class _StubSupabase:
    """Stands in for the `user_info` slice of SupabaseClient.

    Only the methods the privacy route touches are implemented: reading a row
    for `get_current_user` and writing `is_private` for the route itself.
    """

    def __init__(self) -> None:
        self.user_info: dict[str, dict[str, object]] = {
            "user-1": {
                "id": "user-1",
                "email": "user-1@example.com",
                "hashed_password": "stub-hash",
                "first_name": "Stub",
                "last_name": "User",
                "is_active": True,
                "is_private": False,
            }
        }
        self.taken_usernames: set[str] = set()

    def is_configured(self) -> bool:
        return True

    def get_user_info_by_id(self, user_id: str) -> dict[str, object] | None:
        return self.user_info.get(user_id)

    def set_user_privacy(self, user_id: str, is_private: bool) -> bool:
        row = self.user_info.get(user_id)
        if row is None:
            return False
        row["is_private"] = is_private
        return True

    def username_exists(self, username: str, exclude_user_id: str | None = None) -> bool:
        return username in self.taken_usernames

    def set_username(self, id: str, username: str | None) -> bool:
        row = self.user_info.get(id)
        if row is None:
            return False
        row["username"] = username
        return True


@pytest.fixture(scope="function")
def stub_supabase(monkeypatch, app):
    """Stub Supabase and authenticate every request as `user-1`.

    Overrides `get_current_user` directly rather than exercising a real
    login/JWT flow -- the privacy route only cares about `current_user.id`,
    and this keeps the test focused on the route under test.
    """
    stub = _StubSupabase()
    monkeypatch.setattr(supabase_client, "is_configured", stub.is_configured)
    monkeypatch.setattr(supabase_client, "get_user_info_by_id", stub.get_user_info_by_id)
    monkeypatch.setattr(supabase_client, "set_user_privacy", stub.set_user_privacy)
    monkeypatch.setattr(supabase_client, "username_exists", stub.username_exists)
    monkeypatch.setattr(supabase_client, "set_username", stub.set_username)

    def _current_user() -> User:
        # is_private lives on the raw user_info row, not on the User model.
        row = {k: v for k, v in stub.user_info["user-1"].items() if k != "is_private"}
        return User(**row)  # type: ignore[arg-type]

    app.dependency_overrides[get_current_user] = _current_user
    yield stub
    app.dependency_overrides.clear()


@pytest.fixture(scope="function")
def clean_storage():
    """Clear user storage before each test."""
    user_store._users.clear()
    user_store._email_index.clear()
    yield
    # Cleanup after test
    user_store._users.clear()
    user_store._email_index.clear()


@pytest.fixture
def test_user(clean_storage):
    """Create a test user in storage."""
    user = User(
        email="test@example.com",
        hashed_password=hash_password("testpassword123"),
        first_name="Test",
        last_name="User",
    )
    user_store.create(user)
    return user


@pytest.fixture
def test_user_data():
    """Sample user registration data."""
    return {
        "email": "newuser@example.com",
        "password": "securepassword123",
        "first_name": "New",
        "last_name": "User",
    }


@pytest.fixture
def login_credentials():
    """Sample login credentials."""
    return {"email": "test@example.com", "password": "testpassword123"}
