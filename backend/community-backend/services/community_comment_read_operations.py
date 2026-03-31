"""Read-oriented comment Supabase operations for community service."""
import logging
from typing import Any, Dict, List, Optional

logger = logging.getLogger(__name__)


class CommunityCommentReadOperations:
    """Mixin containing read and count operations for comments."""

    def get_comment_by_id(self, comment_id: str) -> Optional[Dict[str, Any]]:
        """Get comment by identifier with author information."""
        try:
            response = self._client.table("comments").select(
                "*, user_info!comments_user_id_fkey(email, first_name, last_name)"
            ).eq("id", comment_id).limit(1).execute()
            response_data = getattr(response, "data", None)
            if isinstance(response_data, list) and response_data:
                comment = response_data[0]
                self._flatten_comment_row(comment)
                return comment
            return None
        except Exception as exception:
            logger.exception("Failed to get comment %s: %s", comment_id, exception)
            return None

    @staticmethod
    def _flatten_comment_row(comment: Dict[str, Any]) -> None:
        """Inline nested user_info onto the comment dict (mutates)."""
        if "user_info" in comment and comment["user_info"]:
            author = comment.pop("user_info")
            comment["author_email"] = author.get("email")
            comment["author_first_name"] = author.get("first_name")
            comment["author_last_name"] = author.get("last_name")

    def list_comments_by_post(self, post_id: str) -> List[Dict[str, Any]]:
        """List all comments for a post with author information."""
        try:
            response = self._client.table("comments").select(
                "*, user_info!comments_user_id_fkey(email, first_name, last_name)"
            ).eq("post_id", post_id).order("created_at", desc=False).execute()
            response_data = getattr(response, "data", None)
            if isinstance(response_data, list):
                for comment in response_data:
                    self._flatten_comment_row(comment)
                return response_data
            return []
        except Exception as exception:
            logger.exception("Failed to list comments for post %s: %s", post_id, exception)
            return []

    def list_comments_by_post_ids(self, post_ids: List[str]) -> Dict[str, List[Dict[str, Any]]]:
        """
        List comments for many posts in a single Supabase query, grouped by post_id.

        Expects caller to dedupe IDs and enforce a maximum length. Preserves
        `post_ids` order. Posts with no comments map to an empty list.
        """
        ordered_ids = [p for p in post_ids if p]
        if not ordered_ids:
            return {}

        empty: Dict[str, List[Dict[str, Any]]] = {pid: [] for pid in ordered_ids}

        try:
            response = self._client.table("comments").select(
                "*, user_info!comments_user_id_fkey(email, first_name, last_name)"
            ).in_("post_id", ordered_ids).execute()
            response_data = getattr(response, "data", None)
            if not isinstance(response_data, list):
                return empty

            buckets: Dict[str, List[Dict[str, Any]]] = {pid: [] for pid in ordered_ids}
            for comment in response_data:
                pid = comment.get("post_id")
                if pid not in buckets:
                    continue
                self._flatten_comment_row(comment)
                buckets[pid].append(comment)

            for pid, rows in buckets.items():
                rows.sort(key=lambda row: (row.get("created_at") or ""))

            return buckets
        except Exception as exception:
            logger.exception("Failed batch list comments: %s", exception)
            return empty

    def count_comments_by_post(self, post_id: str) -> int:
        """Count total comments for a post."""
        try:
            from postgrest import CountMethod

            response = self._client.table("comments").select("id", count=CountMethod.exact).eq("post_id", post_id).execute()
            return getattr(response, "count", 0) or 0
        except Exception as exception:
            logger.exception("Failed to count comments for post %s: %s", post_id, exception)
            return 0
