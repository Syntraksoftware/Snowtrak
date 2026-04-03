"""Subthread database operations."""

from __future__ import annotations

import logging
from typing import Any

from .base import SupabaseBase

logger = logging.getLogger(__name__)


class SubthreadOperations(SupabaseBase):
    """
    Subthread table operations.

    Handles CRUD operations for community subthreads (topics/categories).
    """

    def create_subthread(
        self,
        name: str,
        description: str | None = None,
    ) -> dict[str, Any] | None:
        """
        Create a new subthread.

        Args:
            name: Unique name for the subthread
            description: Optional description

        Returns:
            Created subthread data or None on failure
        """
        if not self.is_configured():
            logger.warning("Supabase not configured; skipping create_subthread.")
            return None

        client = self._client
        if client is None:
            return None

        try:
            payload = {
                "name": name,
                "description": description,
            }
            resp = client.table("subthreads").insert(payload).execute()
            data = getattr(resp, "data", None)
            if isinstance(data, list) and data:
                logger.info(f"Created subthread: {name}")
                return data[0]
            return None
        except Exception as exc:
            logger.exception(f"Failed to create subthread {name}: {exc}")
            return None

    def get_subthread_by_id(self, subthread_id: str) -> dict[str, Any] | None:
        """Get subthread by ID."""
        if not self.is_configured():
            logger.warning("Supabase not configured; skipping get_subthread_by_id.")
            return None

        client = self._client
        if client is None:
            return None

        try:
            resp = client.table("subthreads").select("*").eq("id", subthread_id).limit(1).execute()
            data = getattr(resp, "data", None)
            if isinstance(data, list) and data:
                return data[0]
            return None
        except Exception as exc:
            logger.exception(f"Failed to get subthread {subthread_id}: {exc}")
            return None

    def get_subthread_by_name(self, name: str) -> dict[str, Any] | None:
        """Get subthread by name."""
        if not self.is_configured():
            logger.warning("Supabase not configured; skipping get_subthread_by_name.")
            return None

        client = self._client
        if client is None:
            return None

        try:
            resp = client.table("subthreads").select("*").eq("name", name).limit(1).execute()
            data = getattr(resp, "data", None)
            if isinstance(data, list) and data:
                return data[0]
            return None
        except Exception as exc:
            logger.exception(f"Failed to get subthread by name {name}: {exc}")
            return None

    def list_subthreads(self, limit: int = 50) -> list[dict[str, Any]]:
        """List all subthreads."""
        if not self.is_configured():
            logger.warning("Supabase not configured; skipping list_subthreads.")
            return []

        client = self._client
        if client is None:
            return []

        try:
            resp = (
                client.table("subthreads")
                .select("*")
                .order("created_at", desc=True)
                .limit(limit)
                .execute()
            )
            data = getattr(resp, "data", None)
            return data if isinstance(data, list) else []
        except Exception as exc:
            logger.exception(f"Failed to list subthreads: {exc}")
            return []

    def delete_subthread(self, subthread_id: str) -> bool:
        """
        Delete a subthread and all its posts (and comments via CASCADE).

        Args:
            subthread_id: UUID of the subthread to delete

        Returns:
            True if deleted successfully, False otherwise
        """
        if not self.is_configured():
            logger.warning("Supabase not configured; skipping delete_subthread.")
            return False

        client = self._client
        if client is None:
            return False

        try:
            # Verify the subthread exists
            subthread = self.get_subthread_by_id(subthread_id)
            if not subthread:
                logger.warning(f"Subthread {subthread_id} not found")
                return False

            # Delete the subthread (CASCADE will handle posts and their comments)
            resp = client.table("subthreads").delete().eq("id", subthread_id).execute()
            data = getattr(resp, "data", None)

            if isinstance(data, list) and data:
                logger.info(f"Deleted subthread {subthread_id} and all associated posts/comments")
                return True

            return False
        except Exception as exc:
            logger.exception(f"Failed to delete subthread {subthread_id}: {exc}")
            return False
