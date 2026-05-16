"""Write-oriented comment Supabase operations for community service."""

import logging
from typing import Any

from services.constants.community_tables import COMMENT_VOTES, COMMENTS
from services.helpers.engagement_ops import set_vote

logger = logging.getLogger(__name__)


class CommunityCommentWriteOperations:
    """Mixin containing create, update, vote, and delete operations for comments."""

    def create_comment(
        self,
        user_id: str,
        post_id: str,
        content: str,
        parent_id: str | None = None,
        media_urls: list[str] | None = None,
    ) -> dict[str, Any] | None:
        """Create a new comment."""
        try:
            payload = {
                "user_id": user_id,
                "post_id": post_id,
                "content": content,
                "parent_id": parent_id,
                "has_parent": parent_id is not None,
                "media_urls": list(media_urls or []),
            }
            response = self._client.table(COMMENTS).insert(payload).execute()
            response_data = getattr(response, "data", None)
            if isinstance(response_data, list) and response_data:
                logger.info("Created comment by user %s on post %s", user_id, post_id)
                return response_data[0]
            return None
        except Exception as exception:
            logger.exception("Failed to create comment: %s", exception)
            return None

    def update_comment(
        self,
        comment_id: str,
        user_id: str,
        content: str,
    ) -> dict[str, Any] | None:
        """Update a comment if it belongs to the requesting user."""
        try:
            current_comment = self.get_comment_by_id(comment_id)
            if not current_comment:
                return None
            if current_comment.get("user_id") != user_id:
                return None

            response = (
                self._client.table(COMMENTS)
                .update({"content": content})
                .eq("id", comment_id)
                .execute()
            )
            response_data = getattr(response, "data", None)
            if isinstance(response_data, list) and response_data:
                return self.get_comment_by_id(comment_id)
            return None
        except Exception as exception:
            logger.exception("Failed to update comment %s: %s", comment_id, exception)
            return None

    def set_comment_vote(
        self,
        comment_id: str,
        user_id: str,
        vote_type: int,
    ) -> dict[str, Any] | None:
        """Set or remove a comment vote for a user."""
        try:
            if vote_type not in (-1, 0, 1):
                return None

            comment = self.get_comment_by_id(comment_id)
            if not comment:
                return None

            score = set_vote(
                self._client,
                table_name=COMMENT_VOTES,
                entity_field="comment_id",
                entity_id=comment_id,
                user_id=user_id,
                vote_type=vote_type,
            )

            return {
                "comment_id": comment_id,
                "user_id": user_id,
                "vote_value": vote_type,
                "score": score,
            }
        except Exception as exception:
            logger.exception("Failed to set vote for comment %s: %s", comment_id, exception)
            return None

    def delete_comment(self, comment_id: str, user_id: str) -> bool:
        """Delete a comment and nested replies when owned by requesting user."""
        try:
            comment = self.get_comment_by_id(comment_id)
            if not comment:
                logger.warning("Comment %s not found", comment_id)
                return False

            if comment["user_id"] != user_id:
                logger.warning(
                    "User %s attempted to delete comment %s owned by %s",
                    user_id,
                    comment_id,
                    comment["user_id"],
                )
                return False

            response = self._client.table(COMMENTS).delete().eq("id", comment_id).execute()
            response_data = getattr(response, "data", None)

            if isinstance(response_data, list) and response_data:
                logger.info("Deleted comment %s and all nested replies", comment_id)
                return True

            return False
        except Exception as exception:
            logger.exception("Failed to delete comment %s: %s", comment_id, exception)
            return False
