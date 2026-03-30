"""Read-oriented post Supabase operations for community service."""
import logging
from typing import Any, Dict, List, Optional

logger = logging.getLogger(__name__)


class CommunityPostReadOperations:
    """Mixin containing read and count operations for posts."""

    def get_post_by_id(self, post_id: str) -> Optional[Dict[str, Any]]:
        """Get post by identifier with author information."""
        try:
            response = self._client.table("posts").select(
                "*, user_info!posts_user_id_fkey(email, first_name, last_name)"
            ).eq("post_id", post_id).limit(1).execute()
            response_data = getattr(response, "data", None)
            if isinstance(response_data, list) and response_data:
                post = response_data[0]
                if "user_info" in post and post["user_info"]:
                    author = post.pop("user_info")
                    post["author_email"] = author.get("email")
                    post["author_first_name"] = author.get("first_name")
                    post["author_last_name"] = author.get("last_name")
                return post
            return None
        except Exception as exception:
            logger.exception("Failed to get post %s: %s", post_id, exception)
            return None

    def list_posts_by_subthread(
        self,
        subthread_id: str,
        limit: int = 20,
        offset: int = 0,
    ) -> List[Dict[str, Any]]:
        """List posts in a subthread with author information."""
        try:
            response = self._client.table("posts").select(
                "*, user_info!posts_user_id_fkey(email, first_name, last_name)"
            ).eq("subthread_id", subthread_id).order("created_at", desc=True).range(offset, offset + limit - 1).execute()
            response_data = getattr(response, "data", None)
            if isinstance(response_data, list):
                for post in response_data:
                    if "user_info" in post and post["user_info"]:
                        author = post.pop("user_info")
                        post["author_email"] = author.get("email")
                        post["author_first_name"] = author.get("first_name")
                        post["author_last_name"] = author.get("last_name")
                return response_data
            return []
        except Exception as exception:
            logger.exception("Failed to list posts for subthread %s: %s", subthread_id, exception)
            return []

    def list_posts_by_user_id(
        self,
        user_id: str,
        limit: int = 20,
        offset: int = 0,
    ) -> List[Dict[str, Any]]:
        """List posts authored by a user with author information."""
        try:
            response = self._client.table("posts").select(
                "*, user_info!posts_user_id_fkey(email, first_name, last_name)"
            ).eq("user_id", user_id).order("created_at", desc=True).range(offset, offset + limit - 1).execute()
            response_data = getattr(response, "data", None)
            if isinstance(response_data, list):
                for post in response_data:
                    if "user_info" in post and post["user_info"]:
                        author = post.pop("user_info")
                        post["author_email"] = author.get("email")
                        post["author_first_name"] = author.get("first_name")
                        post["author_last_name"] = author.get("last_name")
                return response_data
            return []
        except Exception as exception:
            logger.exception("Failed to list posts for user %s: %s", user_id, exception)
            return []

    def count_posts_by_subthread(self, subthread_id: str) -> int:
        """Count total posts in a subthread."""
        try:
            from postgrest import CountMethod

            response = self._client.table("posts").select("post_id", count=CountMethod.exact).eq("subthread_id", subthread_id).execute()
            return getattr(response, "count", 0) or 0
        except Exception as exception:
            logger.exception("Failed to count posts for subthread %s: %s", subthread_id, exception)
            return 0
