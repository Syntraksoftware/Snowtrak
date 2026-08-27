"""Read-oriented post Supabase operations for community service."""

import logging
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor
from typing import Any

from services.constants.community_tables import POST_LIKES, POSTS
from services.mappers.community_row_mappers import flatten_user_info
from services.visibility import visible_posts_expression

logger = logging.getLogger(__name__)


class CommunityPostReadOperations:
    """Mixin containing read and count operations for posts."""

    def _visible_posts(self, current_user_id: str | None) -> tuple[str, list[str]]:
        """The visibility predicate for this viewer, and the ids behind it.

        The ids come back too because rows that arrive without going through
        the filter -- a quoted post's preview -- have to be checked in Python
        against the same list.
        """
        following = self.following_ids(current_user_id) if current_user_id else []
        return visible_posts_expression(current_user_id, following), following

    def _hydrate(
        self,
        posts: list[dict[str, Any]],
        current_user_id: str | None = None,
        expression: str | None = None,
    ) -> list[dict[str, Any]]:
        """Attach engagement counts and quoted previews to `posts` in place.

        The three stages are independent -- each reads the same post list and
        writes its own keys -- so they run together rather than one after
        another. Chained, they cost three round trips to a database on another
        continent before the first byte reaches the client.
        """
        if not posts:
            return posts

        if expression is None:
            expression, _ = self._visible_posts(current_user_id)

        with ThreadPoolExecutor(max_workers=3) as pool:
            stages = [
                pool.submit(self._attach_engagement_fields, posts, current_user_id),
                pool.submit(self._hydrate_quoted_posts, posts, expression),
                pool.submit(self._hydrate_quoted_comments, posts, expression),
            ]
            for stage in stages:
                stage.result()

        return posts

    def _engagement_rows(
        self,
        table_name: str,
        columns: str,
        match_column: str,
        post_ids: list[str],
    ) -> list[dict[str, Any]]:
        """One engagement read. A failure degrades the counts, never the posts."""
        try:
            response = (
                self._client.table(table_name)
                .select(columns)
                .in_(match_column, post_ids)
                .execute()
            )
            rows = getattr(response, "data", None)
            return rows if isinstance(rows, list) else []
        except Exception as exception:
            logger.warning("Failed to read %s engagement rows: %s", table_name, exception)
            return []

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
        duplicate_repost_counts: dict[str, int] = defaultdict(int)

        # Three independent reads, run together.
        #
        # They used to be four, one after another. Each is a round trip to a
        # database on another continent (~440ms), and none of them depends on
        # another's result, so the sequence was four times the latency for no
        # reason. The fourth was the duplicate-repost query repeated with a
        # user_id filter -- selecting user_id in the first one answers both.
        with ThreadPoolExecutor(max_workers=3) as pool:
            likes = pool.submit(
                self._engagement_rows, POST_LIKES, "post_id, user_id", "post_id", post_ids
            )
            reposts = pool.submit(
                self._engagement_rows, "post_reposts", "post_id, user_id", "post_id", post_ids
            )
            duplicates = pool.submit(
                self._engagement_rows,
                POSTS,
                "repost_of_post_id, user_id",
                "repost_of_post_id",
                post_ids,
            )

            # A row in post_likes is a like; there is no value to weigh. This
            # read used to count post_votes rows with vote_value > 0, which was
            # a second implementation of the same feature over a second table.
            for row in likes.result():
                post_id = str(row.get("post_id", ""))
                if not post_id:
                    continue
                like_counts[post_id] += 1
                if current_user_id and str(row.get("user_id", "")) == current_user_id:
                    liked_by_current_user[post_id] = True

            for row in reposts.result():
                post_id = str(row.get("post_id", ""))
                if not post_id:
                    continue
                repost_counts[post_id] += 1
                if current_user_id and str(row.get("user_id", "")) == current_user_id:
                    reposted_by_current_user[post_id] = True

            for row in duplicates.result():
                post_id = str(row.get("repost_of_post_id", "")).strip()
                if not post_id:
                    continue
                duplicate_repost_counts[post_id] += 1
                if current_user_id and str(row.get("user_id", "")) == current_user_id:
                    reposted_by_current_user[post_id] = True

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

    def _hydrate_quoted_posts(
        self,
        posts: list[dict[str, Any]],
        expression: str,
    ) -> list[dict[str, Any]]:
        """Attach nested quoted_post preview for rows with quoted_post_id.

        The preview is filtered like any other post read. A public post that
        quotes a followers-only one would otherwise hand its text to everybody,
        and the leak would be authored by somebody other than its owner.
        """
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
                    .or_(expression)
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

    def visible_post_ids(self, post_ids: list[str], expression: str) -> set[str]:
        """Which of `post_ids` this viewer may read. One query.

        For rows that are reached by something other than a post read -- a
        comment, a quoted comment -- and therefore have to be gated by their
        parent post rather than by themselves.
        """
        if not post_ids:
            return set()
        try:
            response = (
                self._client.table(POSTS)
                .select("post_id")
                .in_("post_id", list(dict.fromkeys(post_ids)))
                .or_(expression)
                .execute()
            )
            rows = getattr(response, "data", None)
            if not isinstance(rows, list):
                return set()
            return {str(row.get("post_id", "")).strip() for row in rows if row.get("post_id")}
        except Exception as exception:
            logger.warning("Failed to resolve visible post ids: %s", exception)
            # Deny on failure. A visibility check that fails open is not one.
            return set()

    def _hydrate_quoted_comments(
        self,
        posts: list[dict[str, Any]],
        expression: str,
    ) -> list[dict[str, Any]]:
        """Attach nested quoted_comment preview for rows with quoted_comment_id.

        A comment inherits the visibility of the post it sits under, so the
        previews are gated by their parent rather than by themselves.
        """
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
                        "id, user_id, post_id, content, created_at, "
                        "user_info!comments_user_id_fkey(email, first_name, last_name)"
                    )
                    .in_("id", unique_ids)
                    .execute()
                )
                rows = getattr(response, "data", None)
                if isinstance(rows, list):
                    parents = [str(row.get("post_id", "")).strip() for row in rows]
                    allowed = self.visible_post_ids([p for p in parents if p], expression)
                    for row in rows:
                        if not isinstance(row, dict):
                            continue
                        if str(row.get("post_id", "")).strip() not in allowed:
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
            expression, _ = self._visible_posts(current_user_id)
            response = (
                self._client.table("posts")
                .select("*, user_info!posts_user_id_fkey(email, first_name, last_name)")
                .eq("post_id", post_id)
                .or_(expression)
                .limit(1)
                .execute()
            )
            response_data = getattr(response, "data", None)
            if isinstance(response_data, list) and response_data:
                post = response_data[0]
                flatten_user_info(post)
                return self._hydrate([post], current_user_id=current_user_id)[0]
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
                .or_(self._visible_posts(current_user_id)[0])
                .order("created_at", desc=True)
                .range(offset, offset + limit - 1)
                .execute()
            )
            response_data = getattr(response, "data", None)
            if isinstance(response_data, list):
                for post in response_data:
                    flatten_user_info(post)
                return self._hydrate(response_data, current_user_id=current_user_id)
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
                .or_(self._visible_posts(current_user_id)[0])
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
                return self._hydrate(response_data, current_user_id=current_user_id)
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
                .or_(self._visible_posts(current_user_id)[0])
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
                return self._hydrate(response_data, current_user_id=current_user_id)
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
