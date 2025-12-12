"""
Supabase client for interacting with `user_info` table.

Schema (user_info):
- id (uuid, primary key)
- email (text, unique)
- first_name (text, nullable)
- last_name (text, nullable)
- is_active (bool)
- created_at (timestamptz, default now())
- updated_at (timestamptz, default now(), updated via trigger)

This module initializes a Supabase client from environment settings and
exposes convenience methods for insert and select operations.
"""
from __future__ import annotations

from typing import Optional, Dict, Any
import logging

from supabase import create_client, Client

from app.core.config import settings


logger = logging.getLogger(__name__)


class SupabaseClient:
    """Wrapper around Supabase Python SDK for the `user_info` table."""

    def __init__(self, url: Optional[str] = None, service_key: Optional[str] = None) -> None:
        # Access settings attributes defensively to satisfy type checkers
        cfg_url = getattr(settings, "supabase_url", None)
        cfg_key = getattr(settings, "supabase_service_role_key", None)
        self._url = url or cfg_url
        self._key = service_key or cfg_key
        self._client: Optional[Client] = None

        if self._url and self._key:
            try:
                self._client = create_client(self._url, self._key)
            except Exception as exc:
                logger.exception("Failed to initialize Supabase client: %s", exc)
                self._client = None
        else:
            logger.warning("Supabase URL/key not configured; client disabled.")

    def is_configured(self) -> bool:
        """Return True if the client is ready to use."""
        if self._client is None and self._url and self._key:
            # Lazy re-initialization if credentials are now available
            try:
                self._client = create_client(self._url, self._key)
            except Exception as exc:
                logger.exception("Failed to re-init Supabase client: %s", exc)
        return self._client is not None    # ---------- Insert ----------
    def insert_user_info(
        self,
        *,
        id: str,
        email: str,
        first_name: Optional[str] = None,
        last_name: Optional[str] = None,
        is_active: bool = True,
        extra: Optional[Dict[str, Any]] = None,
    ) -> Optional[Dict[str, Any]]:
        """
        Insert a user profile row into `user_info`.

        Notes:
        - `created_at`/`updated_at` should be defaulted/managed by DB.
        - If RLS is enabled, ensure service role key is used server-side.

        Returns the inserted row dict on success, or None on failure.
        """
        if not self.is_configured():
            logger.warning("Supabase not configured; skipping insert.")
            return None

        payload: Dict[str, Any] = {
            "id": id,
            "email": email,
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

    # ---------- Select ----------
    def get_user_info_by_id(self, id: str) -> Optional[Dict[str, Any]]:
        """Fetch single row from `user_info` by id (uuid)."""
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
        """Fetch single row from `user_info` by email (text)."""
        if not self.is_configured():
            logger.warning("Supabase not configured; skipping select by email.")
            return None
        client = self._client
        if client is None:
            return None
        try:
            resp = client.table("user_info").select("*").eq("email", email).limit(1).execute()
            data = getattr(resp, "data", None)
            if isinstance(data, list) and data:
                return data[0]
            return None
        except Exception as exc:
            logger.exception("Supabase select by email failed: %s", exc)
            return None


# Singleton instance for app-wide use
supabase_client = SupabaseClient()

