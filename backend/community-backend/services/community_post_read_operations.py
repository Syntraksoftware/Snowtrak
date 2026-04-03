"""Read-oriented post Supabase operations for community service."""

import logging
from collections import defaultdict
from typing import Any

from services.mappers.community_row_mappers import flatten_user_info

logger = logging.getLogger(__name__)


class CommunityPostReadOperations:
    """Mixin containing read and count operations for posts."""

    def _attach_engagement_fields(
        self,
        posts: list[dict[str, Any]],
        current_user_id: str | None = None,
    ) -> list[dict[str, Any]]:
        """Hydrate feed payload with like/repost counts and current-user flags."""
        if not posts:
            return posts

        post_ids = [str(post.get("post_id", "")).strip() for post in posts]
        post_ids = [post_id for post_id in post_ids if post_id]
        if not post_ids:
            return posts

        like_counts: dict[str, int] = defaultdict(int)
        liked_by_current_user: dict[str, bool] = defaultdict(bool)
        repost_counts: dict[str, int] = defaultdict(int)
        reposted_by_current_user: dict[str, bool] = defaultdict(bool)

        try:
            vote_response = (
                self._client.table("post_votes")
                .select("post_id, user_id, vote_value")
                .in_("post_id", post_ids)
                .execute()
            )
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
            repost_response = (
                self._client.table("post_reposts")
                .select("post_id, user_id")
                .in_("post_id", post_ids)
                .execute()
            )
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

        duplicate_repost_counts: dict[str, int] = defaultdict(int)
        try:
            dup_response = (
                self._client.table("posts")
                .select("repost_of_post_id")
                .in_("repost_of_post_id", post_ids)
                .execute()
            )
            dup_rows = getattr(dup_response, "data", None)
            if isinstance(dup_rows, list):
                for row in dup_rows:
                    pid = str(row.get("repost_of_post_id", "")).strip()
                    if pid:
                        duplicate_repost_counts[pid] += 1
        except Exception as exception:
            logger.warning("Failed to hydrate post duplicate repost counts: %s", exception)

        try:
            if current_user_id:
                dup_user = (
                    self._client.table("posts")
                    .select("repost_of_post_id")
                    .in_("repost_of_post_id", post_ids)
                    .eq("user_id", current_user_id)
                    .execute()
                )
                dup_user_rows = getattr(dup_user, "data", None)
                if isinstance(dup_user_rows, list):
                    for row in dup_user_rows:
                        pid = str(row.get("repost_of_post_id", "")).strip()
                        if pid:
                            reposted_by_current_user[pid] = True
        except Exception as exception:
            logger.warning("Failed to hydrate user duplicate repost flags: %s", exception)

        for post in posts:
            post_id = str(post.get("post_id", ""))
            post["like_count"] = int(like_counts.get(post_id, 0))
            post["liked_by_current_user"] = bool(liked_by_current_user.get(post_id, False))
            post["repost_count"] = int(repost_counts.get(post_id, 0)) + int(
                duplicate_repost_counts.get(post_id, 0)
            )
            post["reposted_by_current_user"] = bool(reposted_by_current_user.get(post_id, False))
            # Persisted share counts can be wired later; keep key stable for clients.
            post["share_count"] = int(post.get("share_count", 0) or 0)
        return posts

    def _hydrate_quoted_posts(self, posts: list[dict[str, Any]]) -> list[dict[str, Any]]:
        """Attach nested quoted_post preview for rows with quoted_post_id."""
        if not posts:
            return posts

        quoted_ids: list[str] = []
        for post in posts:
            raw = post.get("quoted_post_id")
            if raw is None:
                continue
            key = str(raw).strip()
            if key:
                quoted_ids.append(key)

        unique_ids = list(dict.fromkeys(quoted_ids))
        by_id: dict[str, dict[str, Any]] = {}

        if unique_ids:
            try:
                response = (
                    self._client.table("posts")
                    .select(
                        "post_id, user_id, title, content, created_at, "
                        "user_info!posts_user_id_fkey(email, first_name, last_name)"
                    )
                    .in_("post_id", unique_ids)
                    .execute()
                )
                rows = getattr(response, "data", None)
                if isinstance(rows, list):
                    for row in rows:
                        if not isinstance(row, dict):
                            continue
                        preview = dict(row)
                        pid = str(preview.get("post_id", "")).strip()
                        if not pid:
                            continue
                        flatten_user_info(preview)
                        by_id[pid] = preview
            except Exception as exception:
                logger.warning("Failed to hydrate quoted_post previews: %s", exception)

        for post in posts:
            raw = post.get("quoted_post_id")
            key = str(raw).strip() if raw is not None else ""
            if key and key in by_id:
                post["quoted_post"] = by_id[key]
            else:
                post["quoted_post"] = None
        return posts

    def _hydrate_quoted_comments(self, posts: list[dict[str, Any]]) -> list[dict[str, Any]]:
        """Attach nested quoted_comment preview for rows with quoted_comment_id."""
        if not posts:
            return posts

        qc_ids: list[str] = []
        for post in posts:
            raw = post.get("quoted_comment_id")
            if raw is None:
                continue
            key = str(raw).strip()
            if key:
                qc_ids.append(key)

        unique_ids = list(dict.fromkeys(qc_ids))
        by_id: dict[str, dict[str, Any]] = {}

        if unique_ids:
            try:
                response = (
                    self._client.table("comments")
                    .select(
                        "id, user_id, content, created_at, "
                        "user_info!comments_user_id_fkey(email, first_name, last_name)"
                    )
                    .in_("id", unique_ids)
                    .execute()
                )
                rows = getattr(response, "data", None)
                if isinstance(rows, list):
                    for row in rows:
                        if not isinstance(row, dict):
                            continue
                        preview = dict(row)
                        cid = str(preview.get("id", "")).strip()
                        if not cid:
                            continue
                        flatten_user_info(preview)
                        by_id[cid] = preview
            except Exception as exception:
                logger.warning("Failed to hydrate quoted_comment previews: %s", exception)

        for post in posts:
            raw = post.get("quoted_comment_id")
            key = str(raw).strip() if raw is not None else ""
            if key and key in by_id:
                post["quoted_comment"] = by_id[key]
            else:
                post["quoted_comment"] = None
        return posts

    def get_post_by_id(
        self,
        post_id: str,
        current_user_id: str | None = None,
    ) -> dict[str, Any] | None:
        """Get post by identifier with author information."""
        try:
            response = (
                self._client.table("posts")
                .select("*, user_info!posts_user_id_fkey(email, first_name, last_name)")
                .eq("post_id", post_id)
                .limit(1)
                .execute()
            )
            response_data = getattr(response, "data", None)
            if isinstance(response_data, list) and response_data:
                post = response_data[0]
                flatten_user_info(post)
                enriched = self._attach_engagement_fields([post], current_user_id=current_user_id)
                return self._hydrate_quoted_comments(self._hydrate_quoted_posts(enriched))[0]
            return None
        except Exception as exception:
            logger.exception("Failed to get post %s: %s", post_id, exception)
            return None

    def list_posts_by_subthread(
        self,
        subthread_id: str,
        limit: int = 20,
        offset: int = 0,
        current_user_id: str | None = None,
    ) -> list[dict[str, Any]]:
        """List posts in a subthread with author information."""
        try:
            response = (
                self._client.table("posts")
                .select("*, user_info!posts_user_id_fkey(email, first_name, last_name)")
                .eq("subthread_id", subthread_id)
                .order("created_at", desc=True)
                .range(offset, offset + limit - 1)
                .execute()
            )
            response_data = getattr(response, "data", None)
            if isinstance(response_data, list):
                for post in response_data:
                    flatten_user_info(post)
                return self._hydrate_quoted_comments(
                    self._hydrate_quoted_posts(
                        self._attach_engagement_fields(
                            response_data,
                            current_user_id=current_user_id,
                        )
                    )
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
        current_user_id: str | None = None,
    ) -> list[dict[str, Any]]:
        """List posts authored by a user with author information."""
        try:
            response = (
                self._client.table("posts")
                .select("*, user_info!posts_user_id_fkey(email, first_name, last_name)")
                .eq("user_id", user_id)
                .order("created_at", desc=True)
                .range(offset, offset + limit - 1)
                .execute()
            )
            response_data = getattr(response, "data", None)
            if isinstance(response_data, list):
                for post in response_data:
                    if "user_info" in post and post["user_info"]:
                        author = post.pop("user_info")
                        post["author_email"] = author.get("email")
                        post["author_first_name"] = author.get("first_name")
                        post["author_last_name"] = author.get("last_name")
                return self._hydrate_quoted_comments(
                    self._hydrate_quoted_posts(
                        self._attach_engagement_fields(
                            response_data,
                            current_user_id=current_user_id,
                        )
                    )
                )
            return []
        except Exception as exception:
            logger.exception("Failed to list posts for user %s: %s", user_id, exception)
            return []

    def count_posts_by_subthread(self, subthread_id: str) -> int:
        """Count total posts in a subthread."""
        try:
            from postgrest import CountMethod

            response = (
                self._client.table("posts")
                .select("post_id", count=CountMethod.exact)
                .eq("subthread_id", subthread_id)
                .execute()
            )
            return getattr(response, "count", 0) or 0
        except Exception as exception:
            logger.exception("Failed to count posts for subthread %s: %s", subthread_id, exception)
            return 0

    def list_recent_posts(
        self,
        limit: int = 20,
        offset: int = 0,
        current_user_id: str | None = None,
    ) -> list[dict[str, Any]]:
        """All posts across subthreads, newest first (global feed)."""
        try:
            response = (
                self._client.table("posts")
                .select("*, user_info!posts_user_id_fkey(email, first_name, last_name)")
                .order("created_at", desc=True)
                .range(offset, offset + limit - 1)
                .execute()
            )
            response_data = getattr(response, "data", None)
            if isinstance(response_data, list):
                for post in response_data:
                    if "user_info" in post and post["user_info"]:
                        author = post.pop("user_info")
                        post["author_email"] = author.get("email")
                        post["author_first_name"] = author.get("first_name")
                        post["author_last_name"] = author.get("last_name")
                return self._hydrate_quoted_comments(
                    self._hydrate_quoted_posts(
                        self._attach_engagement_fields(
                            response_data,
                            current_user_id=current_user_id,
                        )
                    )
                )
            return []
        except Exception as exception:
            logger.exception("Failed to list recent posts: %s", exception)
            return []

    def count_all_posts(self) -> int:
        """Total posts (for feed pagination)."""
        try:
            from postgrest import CountMethod

            response = (
                self._client.table("posts").select("post_id", count=CountMethod.exact).execute()
            )
            return getattr(response, "count", 0) or 0
        except Exception as exception:
            logger.exception("Failed to count all posts: %s", exception)
            return 0
