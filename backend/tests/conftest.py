"""
Pytest configuration and shared fixtures.
"""
import pytest
from fastapi.testclient import TestClient
from app.main import create_application
from app.core.storage import user_store, User
from app.core.security import hash_password


@pytest.fixture(scope="function")
def app():
    """Create a fresh FastAPI app instance for each test."""
    return create_application()


@pytest.fixture(scope="function")
def client(app):
    """Create a test client for the app."""
    return TestClient(app)


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
        last_name="User"
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
        "last_name": "User"
    }


@pytest.fixture
def login_credentials():
    """Sample login credentials."""
    return {
        "email": "test@example.com",
        "password": "testpassword123"
    }


