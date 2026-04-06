"""Subthread-related Supabase operations for community service."""

import logging
from typing import Any

logger = logging.getLogger(__name__)


class CommunitySubthreadOperations:
    """Mixin containing subthread operations."""

    def create_subthread(
        self,
        name: str,
        description: str | None = None,
    ) -> dict[str, Any] | None:
        """Create a new subthread."""
        try:
            payload = {
                "name": name,
                "description": description,
            }
            response = self._client.table("subthreads").insert(payload).execute()
            response_data = getattr(response, "data", None)
            if isinstance(response_data, list) and response_data:
                logger.info("Created subthread: %s", name)
                return response_data[0]
            return None
        except Exception as exception:
            logger.exception("Failed to create subthread %s: %s", name, exception)
            return None

    def get_subthread_by_id(self, subthread_id: str) -> dict[str, Any] | None:
        """Get subthread by identifier."""
        try:
            response = (
                self._client.table("subthreads")
                .select("*")
                .eq("id", subthread_id)
                .limit(1)
                .execute()
            )
            response_data = getattr(response, "data", None)
            if isinstance(response_data, list) and response_data:
                return response_data[0]
            return None
        except Exception as exception:
            logger.exception("Failed to get subthread %s: %s", subthread_id, exception)
            return None

    def get_subthread_by_name(self, name: str) -> dict[str, Any] | None:
        """Get subthread by name."""
        try:
            response = (
                self._client.table("subthreads").select("*").eq("name", name).limit(1).execute()
            )
            response_data = getattr(response, "data", None)
            if isinstance(response_data, list) and response_data:
                return response_data[0]
            return None
        except Exception as exception:
            logger.exception("Failed to get subthread by name %s: %s", name, exception)
            return None

    def list_subthreads(self, limit: int = 50) -> list[dict[str, Any]]:
        """List all subthreads ordered by newest first."""
        try:
            response = (
                self._client.table("subthreads")
                .select("*")
                .order("created_at", desc=True)
                .limit(limit)
                .execute()
            )
            response_data = getattr(response, "data", None)
            return response_data if isinstance(response_data, list) else []
        except Exception as exception:
            logger.exception("Failed to list subthreads: %s", exception)
            return []

    def delete_subthread(self, subthread_id: str) -> bool:
        """Delete a subthread and all related posts/comments via CASCADE."""
        try:
            subthread = self.get_subthread_by_id(subthread_id)
            if not subthread:
                logger.warning("Subthread %s not found", subthread_id)
                return False

            response = self._client.table("subthreads").delete().eq("id", subthread_id).execute()
            response_data = getattr(response, "data", None)

            if isinstance(response_data, list) and response_data:
                logger.info("Deleted subthread %s and all associated posts/comments", subthread_id)
                return True

            return False
        except Exception as exception:
            logger.exception("Failed to delete subthread %s: %s", subthread_id, exception)
            return False
