"""
In-memory user storage (replaces database).
For development/demo only - data lost on restart.
"""
from typing import Dict, Optional
from datetime import datetime
import uuid


class User:
    """Simple user data class."""
    def __init__(
        self,
        email: str,
        hashed_password: str,
        first_name: Optional[str] = None,
        last_name: Optional[str] = None
    ):
        # Generate a real UUID for Supabase compatibility
        self.id = str(uuid.uuid4())
        # Keep a backend-specific ID if needed for internal use
        self.backend_id = f"usr_{uuid.uuid4().hex[:16]}"
        self.email = email
        self.hashed_password = hashed_password
        self.first_name = first_name
        self.last_name = last_name
        self.is_active = True
        self.created_at = datetime.utcnow()
        self.last_login_at: Optional[datetime] = None


class UserStore:
    """In-memory user storage."""
    
    def __init__(self):
        self._users: Dict[str, User] = {}  # id -> User
        self._email_index: Dict[str, str] = {}  # email -> id
    
    def get_by_id(self, user_id: str) -> Optional[User]:
        """Get user by ID."""
        return self._users.get(user_id)
    
    def get_by_email(self, email: str) -> Optional[User]:
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
