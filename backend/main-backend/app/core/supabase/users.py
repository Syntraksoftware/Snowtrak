"""User info database operations."""

from __future__ import annotations

import logging
from datetime import UTC, datetime
from typing import Any

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
        first_name: str | None = None,
        last_name: str | None = None,
        is_active: bool = True,
        extra: dict[str, Any] | None = None,
    ) -> dict[str, Any] | None:
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

        payload: dict[str, Any] = {
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

    def get_user_info_by_id(self, id: str) -> dict[str, Any] | None:
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

    def get_user_info_by_email(self, email: str) -> dict[str, Any] | None:
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
            (
                client.table("user_info")
                .update({"last_login_at": datetime.now(UTC).isoformat()})
                .eq("id", id)
                .execute()
            )
            logger.info(f"Updated last_login_at for user {id}")
            return True
        except Exception as exc:
            logger.exception(f"Failed to update last_login_at for user {id}: {exc}")
            return False

    def set_user_privacy(self, id: str, is_private: bool) -> bool:
        """Set whether this account approves its followers.

        On user_info rather than profiles: most users have no profiles row,
        and a privacy flag that is absent for some users is not a privacy
        flag. See backend/db/migrations/015_account_privacy.sql.
        """
        if not self.is_configured():
            logger.warning("Supabase not configured; skipping set_user_privacy.")
            return False
        client = self._client
        if client is None:
            return False
        try:
            resp = (
                client.table("user_info").update({"is_private": is_private}).eq("id", id).execute()
            )
            return bool(getattr(resp, "data", None))
        except Exception as exc:
            logger.exception(f"Failed to set is_private for user {id}: {exc}")
            return False

    def set_user_country(self, id: str, country_code: str | None) -> bool:
        """Set or clear which country leaderboard this user appears on.

        Lives on `user_info` rather than `profiles` for the same reason
        `is_private` does: `profiles.id` references Supabase auth's users,
        registration writes `user_info`, so a profiles row is never created
        and a value written there would be lost. See
        backend/db/migrations/021_competition_on_user_info.sql.

        Args:
            id: The user.
            country_code: ISO 3166-1 alpha-2, or None to leave the country
                boards and appear only on the global one.

        Returns:
            True when a row was updated.
        """
        if not self.is_configured():
            logger.warning("Supabase not configured; skipping set_user_country.")
            return False
        client = self._client
        if client is None:
            return False
        # Stored upper-case so the board's scope filter is an equality test
        # rather than a case-insensitive one.
        value = country_code.upper() if country_code else None
        try:
            resp = client.table("user_info").update({"country_code": value}).eq("id", id).execute()
            return bool(getattr(resp, "data", None))
        except Exception as exc:
            logger.exception(f"Failed to set country_code for user {id}: {exc}")
            return False

    def username_exists(self, username: str, exclude_user_id: str | None = None) -> bool:
        """Whether a handle is already taken, case-insensitively.

        Lives here, not on profiles: `username` moved to `user_info` in
        migration 022 because every service reads names from there.

        Args:
            username: The handle to check.
            exclude_user_id: A user to ignore, so re-submitting your own
                handle is not a conflict with yourself.

        Returns:
            True when taken. True on a failed read as well -- refusing a
            free handle is recoverable, handing out a duplicate is not.
        """
        if not self.is_configured():
            return False
        client = self._client
        if client is None:
            return False
        try:
            query = client.table("user_info").select("id").ilike("username", username)
            if exclude_user_id:
                query = query.neq("id", exclude_user_id)
            resp = query.limit(1).execute()
            data = getattr(resp, "data", None)
            return isinstance(data, list) and len(data) > 0
        except Exception as exc:
            logger.exception(f"Error checking username existence: {exc}")
            return True

    def set_username(self, id: str, username: str | None) -> bool:
        """Set or clear the handle this account is known by.

        Args:
            id: The user.
            username: The handle, already lower-cased and validated, or None
                to clear it.

        Returns:
            True when a row was updated.
        """
        if not self.is_configured():
            logger.warning("Supabase not configured; skipping set_username.")
            return False
        client = self._client
        if client is None:
            return False
        try:
            resp = client.table("user_info").update({"username": username}).eq("id", id).execute()
            return bool(getattr(resp, "data", None))
        except Exception as exc:
            logger.exception(f"Failed to set username for user {id}: {exc}")
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
        first_name: str | None = None,
        last_name: str | None = None,
        is_active: bool | None = None,
    ) -> dict[str, Any] | None:
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
        update_data: dict[str, Any] = {}
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
