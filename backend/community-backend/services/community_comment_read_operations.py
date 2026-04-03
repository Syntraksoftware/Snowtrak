"""Read-oriented comment Supabase operations for community service."""

import logging
from collections import defaultdict
from typing import Any

from services.mappers.community_row_mappers import flatten_user_info

logger = logging.getLogger(__name__)


class CommunityCommentReadOperations:
    """Mixin containing read and count operations for comments."""

    def get_comment_by_id(self, comment_id: str) -> dict[str, Any] | None:
        """Get comment by identifier with author information."""
        try:
            response = (
                self._client.table("comments")
                .select("*, user_info!comments_user_id_fkey(email, first_name, last_name)")
                .eq("id", comment_id)
                .limit(1)
                .execute()
            )
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
    def _flatten_comment_row(comment: dict[str, Any]) -> None:
        """Inline nested user_info onto the comment dict (mutates)."""
        flatten_user_info(comment)

    def _attach_comment_engagement_fields(
        self,
        comments: list[dict[str, Any]],
        current_user_id: str | None = None,
    ) -> list[dict[str, Any]]:
        """Count feed posts that duplicate-repost each comment; set current-user flag."""
        if not comments:
            return comments

        comment_ids = [
            str(c.get("id", "")).strip() for c in comments if str(c.get("id", "")).strip()
        ]
        if not comment_ids:
            return comments

        duplicate_repost_counts: dict[str, int] = defaultdict(int)
        reposted_by_current_user: dict[str, bool] = defaultdict(bool)

        try:
            dup_response = (
                self._client.table("posts")
                .select("repost_of_comment_id")
                .in_("repost_of_comment_id", comment_ids)
                .execute()
            )
            dup_rows = getattr(dup_response, "data", None)
            if isinstance(dup_rows, list):
                for row in dup_rows:
                    cid = str(row.get("repost_of_comment_id", "")).strip()
                    if cid:
                        duplicate_repost_counts[cid] += 1
        except Exception as exception:
            logger.warning(
                "Failed to hydrate comment duplicate repost counts: %s",
                exception,
            )

        try:
            if current_user_id:
                dup_user = (
                    self._client.table("posts")
                    .select("repost_of_comment_id")
                    .in_("repost_of_comment_id", comment_ids)
                    .eq("user_id", current_user_id)
                    .execute()
                )
                dup_user_rows = getattr(dup_user, "data", None)
                if isinstance(dup_user_rows, list):
                    for row in dup_user_rows:
                        cid = str(row.get("repost_of_comment_id", "")).strip()
                        if cid:
                            reposted_by_current_user[cid] = True
        except Exception as exception:
            logger.warning(
                "Failed to hydrate user duplicate repost flags on comments: %s",
                exception,
            )

        for comment in comments:
            cid = str(comment.get("id", ""))
            comment["repost_count"] = int(duplicate_repost_counts.get(cid, 0))
            comment["reposted_by_current_user"] = bool(reposted_by_current_user.get(cid, False))
        return comments

    def list_comments_by_post(
        self,
        post_id: str,
        current_user_id: str | None = None,
    ) -> list[dict[str, Any]]:
        """List all comments for a post with author information."""
        try:
            response = (
                self._client.table("comments")
                .select("*, user_info!comments_user_id_fkey(email, first_name, last_name)")
                .eq("post_id", post_id)
                .order("created_at", desc=False)
                .execute()
            )
            response_data = getattr(response, "data", None)
            if isinstance(response_data, list):
                for comment in response_data:
                    self._flatten_comment_row(comment)
                return self._attach_comment_engagement_fields(
                    response_data,
                    current_user_id=current_user_id,
                )
            return []
        except Exception as exception:
            logger.exception("Failed to list comments for post %s: %s", post_id, exception)
            return []

    def list_comments_by_post_ids(
        self,
        post_ids: list[str],
        current_user_id: str | None = None,
    ) -> dict[str, list[dict[str, Any]]]:
        """
        List comments for many posts in a single Supabase query, grouped by post_id.

        Expects caller to dedupe IDs and enforce a maximum length. Preserves
        `post_ids` order. Posts with no comments map to an empty list.
        """
        ordered_ids = [p for p in post_ids if p]
        if not ordered_ids:
            return {}

        empty: dict[str, list[dict[str, Any]]] = {pid: [] for pid in ordered_ids}

        try:
            response = (
                self._client.table("comments")
                .select("*, user_info!comments_user_id_fkey(email, first_name, last_name)")
                .in_("post_id", ordered_ids)
                .execute()
            )
            response_data = getattr(response, "data", None)
            if not isinstance(response_data, list):
                return empty

            buckets: dict[str, list[dict[str, Any]]] = {pid: [] for pid in ordered_ids}
            for comment in response_data:
                pid = comment.get("post_id")
                if pid not in buckets:
                    continue
                self._flatten_comment_row(comment)
                buckets[pid].append(comment)

            for _pid, rows in buckets.items():
                rows.sort(key=lambda row: row.get("created_at") or "")

            all_rows: list[dict[str, Any]] = []
            for rows in buckets.values():
                all_rows.extend(rows)
            self._attach_comment_engagement_fields(all_rows, current_user_id=current_user_id)
            return buckets
        except Exception as exception:
            logger.exception("Failed batch list comments: %s", exception)
            return empty

    def count_comments_by_post(self, post_id: str) -> int:
        """Count total comments for a post."""
        try:
            from postgrest import CountMethod

            response = (
                self._client.table("comments")
                .select("id", count=CountMethod.exact)
                .eq("post_id", post_id)
                .execute()
            )
            return getattr(response, "count", 0) or 0
        except Exception as exception:
            logger.exception("Failed to count comments for post %s: %s", post_id, exception)
            return 0
