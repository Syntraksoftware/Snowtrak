"""Write-oriented post Supabase operations for community service."""
import logging
from typing import Any, Dict, Optional

logger = logging.getLogger(__name__)


class CommunityPostWriteOperations:
    """Mixin containing create, update, vote, and delete operations for posts."""

    def create_post(
        self,
        user_id: str,
        subthread_id: str,
        title: str,
        content: str,
        quoted_post_id: Optional[str] = None,
        repost_of_post_id: Optional[str] = None,
        quoted_comment_id: Optional[str] = None,
        repost_of_comment_id: Optional[str] = None,
    ) -> Optional[Dict[str, Any]]:
        """Create a new post."""
        try:
            if quoted_post_id and not self.get_post_by_id(quoted_post_id):
                return None
            if repost_of_post_id and not self.get_post_by_id(repost_of_post_id):
                return None
            if quoted_comment_id and not self.get_comment_by_id(quoted_comment_id):
                return None
            if repost_of_comment_id and not self.get_comment_by_id(repost_of_comment_id):
                return None

            payload: Dict[str, Any] = {
                "user_id": user_id,
                "subthread_id": subthread_id,
                "title": title,
                "content": content,
            }
            if quoted_post_id:
                payload["quoted_post_id"] = quoted_post_id
            if repost_of_post_id:
                payload["repost_of_post_id"] = repost_of_post_id
            if quoted_comment_id:
                payload["quoted_comment_id"] = quoted_comment_id
            if repost_of_comment_id:
                payload["repost_of_comment_id"] = repost_of_comment_id
            response = self._client.table("posts").insert(payload).execute()
            response_data = getattr(response, "data", None)
            if isinstance(response_data, list) and response_data:
                logger.info("Created post by user %s", user_id)
                row = response_data[0]
                post_id = row.get("post_id")
                if post_id:
                    hydrated = self.get_post_by_id(post_id)
                    if hydrated:
                        return hydrated
                return row
            return None
        except Exception as exception:
            logger.exception("Failed to create post: %s", exception)
            return None

    def update_post(
        self,
        post_id: str,
        user_id: str,
        title: Optional[str] = None,
        content: Optional[str] = None,
    ) -> Optional[Dict[str, Any]]:
        """Update a post when it belongs to the requesting user."""
        try:
            current_post = self.get_post_by_id(post_id)
            if not current_post:
                return None
            if current_post.get("user_id") != user_id:
                return None

            update_payload: Dict[str, Any] = {}
            if title is not None:
                update_payload["title"] = title
            if content is not None:
                update_payload["content"] = content

            if not update_payload:
                return current_post

            response = self._client.table("posts").update(update_payload).eq("post_id", post_id).execute()
            response_data = getattr(response, "data", None)
            if isinstance(response_data, list) and response_data:
                return self.get_post_by_id(post_id)
            return None
        except Exception as exception:
            logger.exception("Failed to update post %s: %s", post_id, exception)
            return None

    def set_post_vote(
        self,
        post_id: str,
        user_id: str,
        vote_type: int,
    ) -> Optional[Dict[str, Any]]:
        """Set or remove a post vote for a user."""
        try:
            if vote_type not in (-1, 0, 1):
                return None

            post = self.get_post_by_id(post_id)
            if not post:
                return None

            if vote_type == 0:
                self._client.table("post_votes").delete().eq("post_id", post_id).eq("user_id", user_id).execute()
            else:
                existing_vote_response = self._client.table("post_votes").select("id").eq("post_id", post_id).eq("user_id", user_id).limit(1).execute()
                existing_vote_data = getattr(existing_vote_response, "data", None)
                vote_payload = {
                    "post_id": post_id,
                    "user_id": user_id,
                    "vote_value": vote_type,
                }
                if isinstance(existing_vote_data, list) and existing_vote_data:
                    self._client.table("post_votes").update({"vote_value": vote_type}).eq("post_id", post_id).eq("user_id", user_id).execute()
                else:
                    self._client.table("post_votes").insert(vote_payload).execute()

            score_response = self._client.table("post_votes").select("vote_value").eq("post_id", post_id).execute()
            score_rows = getattr(score_response, "data", None)
            score = 0
            if isinstance(score_rows, list):
                score = sum(int(row.get("vote_value", 0)) for row in score_rows)

            return {
                "post_id": post_id,
                "user_id": user_id,
                "vote_value": vote_type,
                "score": score,
            }
        except Exception as exception:
            logger.exception("Failed to set vote for post %s: %s", post_id, exception)
            return None

    def delete_post(self, post_id: str, user_id: str) -> bool:
        """Delete a post and related comments when owned by requesting user."""
        try:
            post = self.get_post_by_id(post_id)
            if not post:
                logger.warning("Post %s not found", post_id)
                return False

            if post["user_id"] != user_id:
                logger.warning(
                    "User %s attempted to delete post %s owned by %s",
                    user_id,
                    post_id,
                    post["user_id"],
                )
                return False

            response = self._client.table("posts").delete().eq("post_id", post_id).execute()
            response_data = getattr(response, "data", None)

            if isinstance(response_data, list) and response_data:
                logger.info("Deleted post %s and all comments", post_id)
                return True

            return False
        except Exception as exception:
            logger.exception("Failed to delete post %s: %s", post_id, exception)
            return False

    def set_post_repost(
        self,
        post_id: str,
        user_id: str,
        reposted: bool,
    ) -> Optional[Dict[str, Any]]:
        """Create or remove repost marker for a post."""
        try:
            post = self.get_post_by_id(post_id)
            if not post:
                return None

            if reposted:
                existing_response = self._client.table("post_reposts").select("id").eq(
                    "post_id",
                    post_id,
                ).eq("user_id", user_id).limit(1).execute()
                existing_data = getattr(existing_response, "data", None)
                if not (isinstance(existing_data, list) and existing_data):
                    self._client.table("post_reposts").insert(
                        {
                            "post_id": post_id,
                            "user_id": user_id,
                        }
                    ).execute()
            else:
                self._client.table("post_reposts").delete().eq("post_id", post_id).eq(
                    "user_id",
                    user_id,
                ).execute()

            count_response = self._client.table("post_reposts").select("id").eq(
                "post_id",
                post_id,
            ).execute()
            count_rows = getattr(count_response, "data", None)
            repost_count = len(count_rows) if isinstance(count_rows, list) else 0

            return {
                "post_id": post_id,
                "user_id": user_id,
                "reposted": reposted,
                "repost_count": repost_count,
            }
        except Exception as exception:
            logger.exception("Failed to set repost for post %s: %s", post_id, exception)
            return None
