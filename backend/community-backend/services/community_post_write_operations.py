"""Write-oriented post Supabase operations for community service."""

import logging
from typing import Any

from services.constants.community_tables import POST_REPOSTS, POST_VOTES, POSTS
from services.helpers.engagement_ops import set_vote

logger = logging.getLogger(__name__)


class CommunityPostWriteOperations:
    """Mixin containing create, update, vote, and delete operations for posts."""

    def create_post(
        self,
        user_id: str,
        subthread_id: str,
        title: str,
        content: str,
        quoted_post_id: str | None = None,
        repost_of_post_id: str | None = None,
        quoted_comment_id: str | None = None,
        repost_of_comment_id: str | None = None,
        media_urls: list[str] | None = None,
    ) -> dict[str, Any] | None:
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

            payload: dict[str, Any] = {
                "user_id": user_id,
                "subthread_id": subthread_id,
                "title": title,
                "content": content,
                "media_urls": list(media_urls or []),
            }
            if quoted_post_id:
                payload["quoted_post_id"] = quoted_post_id
            if repost_of_post_id:
                payload["repost_of_post_id"] = repost_of_post_id
            if quoted_comment_id:
                payload["quoted_comment_id"] = quoted_comment_id
            if repost_of_comment_id:
                payload["repost_of_comment_id"] = repost_of_comment_id
            response = self._client.table(POSTS).insert(payload).execute()
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
        title: str | None = None,
        content: str | None = None,
    ) -> dict[str, Any] | None:
        """Update a post when it belongs to the requesting user."""
        try:
            current_post = self.get_post_by_id(post_id)
            if not current_post:
                return None
            if current_post.get("user_id") != user_id:
                return None

            update_payload: dict[str, Any] = {}
            if title is not None:
                update_payload["title"] = title
            if content is not None:
                update_payload["content"] = content

            if not update_payload:
                return current_post

            response = (
                self._client.table(POSTS).update(update_payload).eq("post_id", post_id).execute()
            )
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
    ) -> dict[str, Any] | None:
        """Set or remove a post vote for a user."""
        try:
            if vote_type not in (-1, 0, 1):
                return None

            post = self.get_post_by_id(post_id)
            if not post:
                return None

            score = set_vote(
                self._client,
                table_name=POST_VOTES,
                entity_field="post_id",
                entity_id=post_id,
                user_id=user_id,
                vote_type=vote_type,
            )

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

            response = self._client.table(POSTS).delete().eq("post_id", post_id).execute()
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
    ) -> dict[str, Any] | None:
        """Create or remove repost marker for a post."""
        try:
            post = self.get_post_by_id(post_id)
            if not post:
                return None

            if reposted:
                existing_response = (
                    self._client.table(POST_REPOSTS)
                    .select("id")
                    .eq(
                        "post_id",
                        post_id,
                    )
                    .eq("user_id", user_id)
                    .limit(1)
                    .execute()
                )
                existing_data = getattr(existing_response, "data", None)
                if not (isinstance(existing_data, list) and existing_data):
                    self._client.table(POST_REPOSTS).insert(
                        {
                            "post_id": post_id,
                            "user_id": user_id,
                        }
                    ).execute()
            else:
                self._client.table(POST_REPOSTS).delete().eq("post_id", post_id).eq(
                    "user_id",
                    user_id,
                ).execute()

            count_response = (
                self._client.table(POST_REPOSTS)
                .select("id")
                .eq(
                    "post_id",
                    post_id,
                )
                .execute()
            )
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
