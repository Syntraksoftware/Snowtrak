"""
In-memory user storage (fallback when Supabase not configured).
For development/demo only - data lost on restart.
"""

import uuid
from datetime import UTC, datetime


class User:
    """Simple user data class."""

    def __init__(
        self,
        email: str,
        hashed_password: str,
        first_name: str | None = None,
        last_name: str | None = None,
        id: str | None = None,
        is_active: bool = True,
    ):
        # Use provided id or generate a real UUID for Supabase compatibility
        self.id = id or str(uuid.uuid4())
        self.email = email
        self.hashed_password = hashed_password
        self.first_name = first_name
        self.last_name = last_name
        self.is_active = is_active
        self.created_at = datetime.now(UTC)
        self.last_login_at: datetime | None = None


class UserStore:
    """In-memory user storage."""

    def __init__(self):
        self._users: dict[str, User] = {}  # id -> User
        self._email_index: dict[str, str] = {}  # email -> id

    def get_by_id(self, user_id: str) -> User | None:
        """Get user by ID."""
        return self._users.get(user_id)

    def get_by_email(self, email: str) -> User | None:
        """Get user by email."""
        user_id = self._email_index.get(email.lower())
        return self._users.get(user_id) if user_id else None

    def create(self, user: User) -> User:
        """Create new user."""
        self._users[user.id] = user
        self._email_index[user.email.lower()] = user.id
        return user

    def exists_by_email(self, email: str) -> bool:
        """Check if email is already registered."""
        return email.lower() in self._email_index


# Global instance
user_store = UserStore()
