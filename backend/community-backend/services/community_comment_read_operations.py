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
                if "user_info" in comment and comment["user_info"]:
                    author = comment.pop("user_info")
                    comment["author_email"] = author.get("email")
                    comment["author_first_name"] = author.get("first_name")
                    comment["author_last_name"] = author.get("last_name")
                return comment
            return None
        except Exception as exception:
            logger.exception("Failed to get comment %s: %s", comment_id, exception)
            return None

    def list_comments_by_post(self, post_id: str) -> List[Dict[str, Any]]:
        """List all comments for a post with author information."""
        try:
            response = self._client.table("comments").select(
                "*, user_info!comments_user_id_fkey(email, first_name, last_name)"
            ).eq("post_id", post_id).order("created_at", desc=False).execute()
            response_data = getattr(response, "data", None)
            if isinstance(response_data, list):
                for comment in response_data:
                    if "user_info" in comment and comment["user_info"]:
                        author = comment.pop("user_info")
                        comment["author_email"] = author.get("email")
                        comment["author_first_name"] = author.get("first_name")
                        comment["author_last_name"] = author.get("last_name")
                return response_data
            return []
        except Exception as exception:
            logger.exception("Failed to list comments for post %s: %s", post_id, exception)
            return []

    def count_comments_by_post(self, post_id: str) -> int:
        """Count total comments for a post."""
        try:
            from postgrest import CountMethod

            response = self._client.table("comments").select("id", count=CountMethod.exact).eq("post_id", post_id).execute()
            return getattr(response, "count", 0) or 0
        except Exception as exception:
            logger.exception("Failed to count comments for post %s: %s", post_id, exception)
            return 0
