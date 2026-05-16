"""
Unit tests for in-memory storage.
"""

from app.core.security import hash_password
from app.core.storage import User, UserStore


class TestUserStore:
    """Test UserStore functionality."""

    def test_create_user(self):
        """Test creating a new user."""
        store = UserStore()
        user = User(email="test@example.com", hashed_password=hash_password("password123"))

        created_user = store.create(user)

        assert created_user.id is not None
        assert created_user.email == "test@example.com"
        assert created_user.id in store._users

    def test_get_by_id(self):
        """Test retrieving user by ID."""
        store = UserStore()
        user = User(email="test@example.com", hashed_password=hash_password("password123"))
        created_user = store.create(user)

        retrieved = store.get_by_id(created_user.id)

        assert retrieved is not None
        assert retrieved.id == created_user.id
        assert retrieved.email == "test@example.com"

    def test_get_by_id_not_found(self):
        """Test retrieving non-existent user returns None."""
        store = UserStore()
        result = store.get_by_id("nonexistent")
        assert result is None

    def test_get_by_email(self):
        """Test retrieving user by email."""
        store = UserStore()
        user = User(email="test@example.com", hashed_password=hash_password("password123"))
        store.create(user)

        retrieved = store.get_by_email("test@example.com")

        assert retrieved is not None
        assert retrieved.email == "test@example.com"

    def test_get_by_email_case_insensitive(self):
        """Test that email lookup is case-insensitive."""
        store = UserStore()
        user = User(email="Test@Example.com", hashed_password=hash_password("password123"))
        store.create(user)

        retrieved = store.get_by_email("test@example.com")
        assert retrieved is not None
        assert retrieved.email == "Test@Example.com"

    def test_get_by_email_not_found(self):
        """Test retrieving non-existent email returns None."""
        store = UserStore()
        result = store.get_by_email("nonexistent@example.com")
        assert result is None

    def test_exists_by_email(self):
        """Test checking if email exists."""
        store = UserStore()
        user = User(email="test@example.com", hashed_password=hash_password("password123"))
        store.create(user)

        assert store.exists_by_email("test@example.com") is True
        assert store.exists_by_email("nonexistent@example.com") is False

    def test_exists_by_email_case_insensitive(self):
        """Test that email existence check is case-insensitive."""
        store = UserStore()
        user = User(email="Test@Example.com", hashed_password=hash_password("password123"))
        store.create(user)

        assert store.exists_by_email("test@example.com") is True
        assert store.exists_by_email("TEST@EXAMPLE.COM") is True
