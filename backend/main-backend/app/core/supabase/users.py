"""User info database operations."""
from __future__ import annotations

from typing import Optional, Dict, Any
from datetime import datetime, timezone
import logging

from .base import SupabaseBase

logger = logging.getLogger(__name__)


class UserOperations(SupabaseBase):
    """
    User info table operations.
    
    Handles CRUD operations for the user_info table:
    - id (uuid, primary key)
    - email (text, unique)
    - first_name (text, nullable)
    - last_name (text, nullable)
    - hashed_password (text) - bcrypt hashed password
    - is_active (bool)
    - last_login_at (timestamptz, nullable)
    - created_at (timestamptz, default now())
    - updated_at (timestamptz, default now(), updated via trigger)
    """

    def insert_user_info(
        self,
        *,
        id: str,
        email: str,
        hashed_password: str,
        first_name: Optional[str] = None,
        last_name: Optional[str] = None,
        is_active: bool = True,
        extra: Optional[Dict[str, Any]] = None,
    ) -> Optional[Dict[str, Any]]:
        """
        Insert a user profile row into user_info.

        Notes:
        - created_at/updated_at should be defaulted/managed by DB.
        - If RLS is enabled, ensure service role key is used server-side.

        Returns the inserted row dict on success, or None on failure.
        """
        if not self.is_configured():
            logger.warning("Supabase not configured; skipping insert.")
            return None

        payload: Dict[str, Any] = {
            "id": id,
            "email": email,
            "hashed_password": hashed_password,
            "first_name": first_name,
            "last_name": last_name,
            "is_active": is_active,
        }
        if extra:
            payload.update(extra)

        client = self._client
        if client is None:
            return None
        try:
            resp = client.table("user_info").insert(payload).execute()
            data = getattr(resp, "data", None)
            if isinstance(data, list) and data:
                return data[0]
            if isinstance(data, dict):
                return data
            logger.error("Supabase insert returned no data: %s", data)
            return None
        except Exception as exc:
            logger.exception("Supabase insert failed: %s", exc)
            return None

    def get_user_info_by_id(self, id: str) -> Optional[Dict[str, Any]]:
        """Fetch single row from user_info by id (uuid)."""
        if not self.is_configured():
            logger.warning("Supabase not configured; skipping select by id.")
            return None
        client = self._client
        if client is None:
            return None
        try:
            resp = client.table("user_info").select("*").eq("id", id).limit(1).execute()
            data = getattr(resp, "data", None)
            if isinstance(data, list) and data:
                return data[0]
            return None
        except Exception as exc:
            logger.exception("Supabase select by id failed: %s", exc)
            return None

    def get_user_info_by_email(self, email: str) -> Optional[Dict[str, Any]]:
        """Fetch single row from user_info by email (text)."""
        if not self.is_configured():
            logger.warning("Supabase not configured; skipping select by email.")
            return None
        client = self._client
        if client is None:
            return None
        try:
            normalized_email = email.strip().lower()
            resp = (
                client.table("user_info")
                .select("*")
                .ilike("email", normalized_email)
                .limit(1)
                .execute()
            )
            data = getattr(resp, "data", None)
            if isinstance(data, list) and data:
                return data[0]
            return None
        except Exception as exc:
            logger.exception("Supabase select by email failed: %s", exc)
            return None

    def update_user_last_login(self, id: str) -> bool:
        """Update last_login_at timestamp for a user. Returns True on success."""
        if not self.is_configured():
            logger.warning("Supabase not configured; skipping update.")
            return False
        client = self._client
        if client is None:
            return False
        try:
            resp = client.table("user_info").update(
                {"last_login_at": datetime.now(timezone.utc).isoformat()}
            ).eq("id", id).execute()
            logger.info(f"Updated last_login_at for user {id}")
            return True
        except Exception as exc:
            logger.exception(f"Failed to update last_login_at for user {id}: {exc}")
            return False

    def email_exists(self, email: str) -> bool:
        """Check if email already exists in user_info table."""
        if not self.is_configured():
            return False
        try:
            user = self.get_user_info_by_email(email)
            return user is not None
        except Exception as exc:
            logger.exception(f"Error checking email existence: {exc}")
            return False

    def update_user_info(
        self,
        id: str,
        *,
        first_name: Optional[str] = None,
        last_name: Optional[str] = None,
        is_active: Optional[bool] = None,
    ) -> Optional[Dict[str, Any]]:
        """
        Update user profile fields in user_info table.
        
        Only updates provided fields (partial update).
        Returns updated row dict on success, or None on failure.
        """
        if not self.is_configured():
            logger.warning("Supabase not configured; skipping update.")
            return None
        
        client = self._client
        if client is None:
            return None
        
        # Build update payload with only provided fields
        update_data: Dict[str, Any] = {}
        if first_name is not None:
            update_data["first_name"] = first_name
        if last_name is not None:
            update_data["last_name"] = last_name
        if is_active is not None:
            update_data["is_active"] = is_active
        
        if not update_data:
            logger.warning("No fields to update provided")
            return None
        
        try:
            resp = client.table("user_info").update(update_data).eq("id", id).execute()
            data = getattr(resp, "data", None)
            if isinstance(data, list) and data:
                return data[0]
            if isinstance(data, dict):
                return data
            logger.error("Supabase update returned no data: %s", data)
            return None
        except Exception as exc:
            logger.exception("Supabase update failed: %s", exc)
            return None
