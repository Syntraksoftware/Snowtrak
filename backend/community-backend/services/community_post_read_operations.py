"""Read-oriented post Supabase operations for community service."""
import logging
from collections import defaultdict
from typing import Any, Dict, List, Optional

logger = logging.getLogger(__name__)


class CommunityPostReadOperations:
    """Mixin containing read and count operations for posts."""

    def _attach_engagement_fields(
        self,
        posts: List[Dict[str, Any]],
        current_user_id: Optional[str] = None,
    ) -> List[Dict[str, Any]]:
        """Hydrate feed payload with like/repost counts and current-user flags."""
        if not posts:
            return posts

        post_ids = [str(post.get("post_id", "")).strip() for post in posts]
        post_ids = [post_id for post_id in post_ids if post_id]
        if not post_ids:
            return posts

        like_counts: Dict[str, int] = defaultdict(int)
        liked_by_current_user: Dict[str, bool] = defaultdict(bool)
        repost_counts: Dict[str, int] = defaultdict(int)
        reposted_by_current_user: Dict[str, bool] = defaultdict(bool)

        try:
            vote_response = self._client.table("post_votes").select(
                "post_id, user_id, vote_value"
            ).in_("post_id", post_ids).execute()
            vote_rows = getattr(vote_response, "data", None)
            if isinstance(vote_rows, list):
                for row in vote_rows:
                    post_id = str(row.get("post_id", ""))
                    vote_value = int(row.get("vote_value", 0) or 0)
                    if post_id and vote_value > 0:
                        like_counts[post_id] += 1
                    if (
                        current_user_id
                        and post_id
                        and str(row.get("user_id", "")) == current_user_id
                        and vote_value > 0
                    ):
                        liked_by_current_user[post_id] = True
        except Exception as exception:
            logger.warning("Failed to hydrate post_votes engagement fields: %s", exception)

        try:
            repost_response = self._client.table("post_reposts").select(
                "post_id, user_id"
            ).in_("post_id", post_ids).execute()
            repost_rows = getattr(repost_response, "data", None)
            if isinstance(repost_rows, list):
                for row in repost_rows:
                    post_id = str(row.get("post_id", ""))
                    if not post_id:
                        continue
                    repost_counts[post_id] += 1
                    if current_user_id and str(row.get("user_id", "")) == current_user_id:
                        reposted_by_current_user[post_id] = True
        except Exception as exception:
            logger.warning("Failed to hydrate post_reposts engagement fields: %s", exception)

        for post in posts:
            post_id = str(post.get("post_id", ""))
            post["like_count"] = int(like_counts.get(post_id, 0))
            post["liked_by_current_user"] = bool(liked_by_current_user.get(post_id, False))
            post["repost_count"] = int(repost_counts.get(post_id, 0))
            post["reposted_by_current_user"] = bool(
                reposted_by_current_user.get(post_id, False)
            )
        return posts

    def get_post_by_id(
        self,
        post_id: str,
        current_user_id: Optional[str] = None,
    ) -> Optional[Dict[str, Any]]:
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
                enriched = self._attach_engagement_fields([post], current_user_id=current_user_id)
                return enriched[0]
            return None
        except Exception as exception:
            logger.exception("Failed to get post %s: %s", post_id, exception)
            return None

    def list_posts_by_subthread(
        self,
        subthread_id: str,
        limit: int = 20,
        offset: int = 0,
        current_user_id: Optional[str] = None,
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
                return self._attach_engagement_fields(
                    response_data,
                    current_user_id=current_user_id,
                )
            return []
        except Exception as exception:
            logger.exception("Failed to list posts for subthread %s: %s", subthread_id, exception)
            return []

    def list_posts_by_user_id(
        self,
        user_id: str,
        limit: int = 20,
        offset: int = 0,
        current_user_id: Optional[str] = None,
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
                return self._attach_engagement_fields(
                    response_data,
                    current_user_id=current_user_id,
                )
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

    def list_recent_posts(
        self,
        limit: int = 20,
        offset: int = 0,
        current_user_id: Optional[str] = None,
    ) -> List[Dict[str, Any]]:
        """All posts across subthreads, newest first (global feed)."""
        try:
            response = self._client.table("posts").select(
                "*, user_info!posts_user_id_fkey(email, first_name, last_name)"
            ).order("created_at", desc=True).range(offset, offset + limit - 1).execute()
            response_data = getattr(response, "data", None)
            if isinstance(response_data, list):
                for post in response_data:
                    if "user_info" in post and post["user_info"]:
                        author = post.pop("user_info")
                        post["author_email"] = author.get("email")
                        post["author_first_name"] = author.get("first_name")
                        post["author_last_name"] = author.get("last_name")
                return self._attach_engagement_fields(
                    response_data,
                    current_user_id=current_user_id,
                )
            return []
        except Exception as exception:
            logger.exception("Failed to list recent posts: %s", exception)
            return []

    def count_all_posts(self) -> int:
        """Total posts (for feed pagination)."""
        try:
            from postgrest import CountMethod

            response = self._client.table("posts").select("post_id", count=CountMethod.exact).execute()
            return getattr(response, "count", 0) or 0
        except Exception as exception:
            logger.exception("Failed to count all posts: %s", exception)
            return 0
