"""Profile database operations."""
from __future__ import annotations

from typing import Optional, Dict, Any
import logging

from .base import SupabaseBase

logger = logging.getLogger(__name__)


class ProfileOperations(SupabaseBase):
    """
    Profile table operations.
    
    Handles CRUD operations for the profiles table (Create, Read, Update, Delete):
    - id (uuid, primary key, foreign key to auth.users)
    - full_name (text, nullable)
    - username (text, unique, nullable)
    - bio (text, nullable)
    - avatar_url (text, nullable)
    - push_token (text, nullable)
    - ski_level (text, nullable)
    - home (text, nullable) - nationality/home location
    - created_at (timestamptz, default now())
    - updated_at (timestamptz, default now(), updated via trigger)
    
    The id serves as both primary key and foreign key reference to auth.users.
    This one-to-one relationship ensures each authenticated user has exactly one profile.
    """

    def get_profile_by_id(self, user_id: str) -> Optional[Dict[str, Any]]:
        """Fetch profile by user ID."""
        if not self.is_configured():
            # check if conenction is valid pu
            logger.warning("Supabase not configured; skipping get_profile_by_id.")
            return None
        
        client = self._client
        if client is None:
            return None
        
        try:
            resp = client.table("profiles").select("*").eq("id", user_id).limit(1).execute()
            data = getattr(resp, "data", None)
            if isinstance(data, list) and data:
                return data[0]
            return None
        except Exception as exc:
            logger.exception(f"Failed to get profile for user {user_id}: {exc}")
            return None

    def create_profile(
        self,
        user_id: str,
        *,
        full_name: Optional[str] = None,
        username: Optional[str] = None,
        bio: Optional[str] = None,
        avatar_url: Optional[str] = None,
        push_token: Optional[str] = None,
        ski_level: Optional[str] = None,
        home: Optional[str] = None,
    ) -> Optional[Dict[str, Any]]:
        """
        Create a new profile for a user.
        
        Returns the created profile dict on success, or None on failure.
        """
        if not self.is_configured():
            logger.warning("Supabase not configured; skipping create_profile.")
            return None
        
        client = self._client
        if client is None:
            return None
        
        try:
            payload: Dict[str, Any] = {
                "id": user_id,
            }
            if full_name is not None:
                payload["full_name"] = full_name
            if username is not None:
                payload["username"] = username
            if bio is not None:
                payload["bio"] = bio
            if avatar_url is not None:
                payload["avatar_url"] = avatar_url
            if push_token is not None:
                payload["push_token"] = push_token
            if ski_level is not None:
                payload["ski_level"] = ski_level
            if home is not None:
                payload["home"] = home
            
            resp = client.table("profiles").insert(payload).execute()
            data = getattr(resp, "data", None)
            if isinstance(data, list) and data:
                logger.info(f"Created profile for user {user_id}")
                return data[0]
            if isinstance(data, dict):
                return data
            logger.error("Supabase insert returned no data: %s", data)
            return None
        except Exception as exc:
            logger.exception(f"Failed to create profile for user {user_id}: {exc}")
            return None

    def update_profile(
        self,
        user_id: str,
        *,
        full_name: Optional[str] = None,
        username: Optional[str] = None,
        bio: Optional[str] = None,
        avatar_url: Optional[str] = None,
        push_token: Optional[str] = None,
        ski_level: Optional[str] = None,
        home: Optional[str] = None,
    ) -> Optional[Dict[str, Any]]:
        """
        Update profile fields.
        
        Only updates provided fields (partial update).
        Returns updated profile dict on success, or None on failure.
        """
        if not self.is_configured():
            logger.warning("Supabase not configured; skipping update_profile.")
            return None
        
        client = self._client
        if client is None:
            return None
        
        # Build update payload with only provided fields
        update_data: Dict[str, Any] = {}
        if full_name is not None:
            update_data["full_name"] = full_name
        if username is not None:
            update_data["username"] = username
        if bio is not None:
            update_data["bio"] = bio
        if avatar_url is not None:
            update_data["avatar_url"] = avatar_url
        if push_token is not None:
            update_data["push_token"] = push_token
        if ski_level is not None:
            update_data["ski_level"] = ski_level
        if home is not None:
            update_data["home"] = home
        
        if not update_data:
            logger.warning("No fields to update provided")
            return None
        
        try:
            resp = client.table("profiles").update(update_data).eq("id", user_id).execute()
            data = getattr(resp, "data", None)
            if isinstance(data, list) and data:
                logger.info(f"Updated profile for user {user_id}")
                return data[0]
            if isinstance(data, dict):
                return data
            logger.error("Supabase update returned no data: %s", data)
            return None
        except Exception as exc:
            logger.exception(f"Failed to update profile for user {user_id}: {exc}")
            return None

    def username_exists(self, username: str, exclude_user_id: Optional[str] = None) -> bool:
        """Check if username already exists (excluding a specific user if provided)."""
        if not self.is_configured():
            return False
        
        client = self._client
        if client is None:
            return False
        
        try:
            query = client.table("profiles").select("id").eq("username", username)
            if exclude_user_id:
                query = query.neq("id", exclude_user_id)
            resp = query.limit(1).execute()
            data = getattr(resp, "data", None)
            return isinstance(data, list) and len(data) > 0
        except Exception as exc:
            logger.exception(f"Error checking username existence: {exc}")
            return False
