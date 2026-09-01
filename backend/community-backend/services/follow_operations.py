"""Follow-graph Supabase operations for the community service.

The graph lives here rather than in main-backend because the only reader that
cannot afford a network hop is the feed, which runs in this service. See
docs/service-ownership.md.
"""

import logging
from typing import Any

from shared.follow_graph import MAX_FOLLOW_IDS
from shared.follow_graph import following_ids as _following_ids

from services.constants.community_tables import FOLLOWS

logger = logging.getLogger(__name__)


class CommunityFollowOperations:
    """Mixin containing follow-graph operations."""

    def follow(self, follower_id: str, followee_id: str) -> bool:
        """Record that `follower_id` follows `followee_id`.

        Idempotent: following twice leaves one row. Clients retry, and a retry
        should not be an error.
        """
        if follower_id == followee_id:
            return False
        try:
            (
                self._client.table(FOLLOWS)
                .upsert(
                    {"follower_id": follower_id, "followee_id": followee_id},
                    on_conflict="follower_id,followee_id",
                    ignore_duplicates=True,
                )
                .execute()
            )
            return True
        except Exception as exception:
            logger.exception(
                "Failed to follow %s as %s: %s", followee_id, follower_id, exception
            )
            return False

    def unfollow(self, follower_id: str, followee_id: str) -> bool:
        """Remove one follow edge. Succeeds when there was nothing to remove."""
        try:
            (
                self._client.table(FOLLOWS)
                .delete()
                .eq("follower_id", follower_id)
                .eq("followee_id", followee_id)
                .execute()
            )
            return True
        except Exception as exception:
            logger.exception(
                "Failed to unfollow %s as %s: %s", followee_id, follower_id, exception
            )
            return False

    def is_following(self, follower_id: str, followee_id: str) -> bool:
        try:
            response = (
                self._client.table(FOLLOWS)
                .select("follower_id")
                .eq("follower_id", follower_id)
                .eq("followee_id", followee_id)
                .limit(1)
                .execute()
            )
            data = getattr(response, "data", None)
            return bool(isinstance(data, list) and data)
        except Exception as exception:
            logger.exception("Failed to read follow edge: %s", exception)
            return False

    def follow_snapshot(self, user_id: str, viewer_id: str | None) -> tuple[dict[str, Any], bool]:
        """Counts and the viewer's relationship, in one round trip.

        The database is a continent away -- one trip measures ~440ms of pure
        distance -- so the four obvious queries cost about a second before
        Postgres does any work. `follow_stats` does all four server-side; see
        backend/db/migrations/017_follow_requests_function.sql.

        Returns:
            A `(snapshot, ok)` pair. `ok` is `False` whenever `snapshot` is the
            fail-closed fallback rather than a real read, so the route can
            tell the two apart -- a caller that caches `snapshot` regardless
            of `ok` would pin the fallback's `0 followers / is_private: True`
            for a viewer for `CACHE_FOLLOW_STATS_TTL_SECONDS`.
        """
        # Fail closed: an RPC error makes the account look private rather
        # than public. This dict only ever labels a button (POST
        # /follows/{id} makes its own independent fresh check before it acts),
        # but every other privacy decision in this feature fails closed, and
        # a mislabeled "Follow" button is a smaller cost than momentarily
        # advertising a private account's list as public.
        empty = {
            "follower_count": 0,
            "following_count": 0,
            "is_following": False,
            "is_followed_by": False,
            "is_private": True,
            "has_requested": False,
            "requests_you": False,
        }
        try:
            response = self._client.rpc(
                "follow_stats",
                {"target": user_id, "viewer": viewer_id},
            ).execute()
            data = getattr(response, "data", None)
            if isinstance(data, dict):
                return data, True
            return empty, False
        except Exception as exception:
            logger.exception("Failed to read follow stats for %s: %s", user_id, exception)
            return empty, False

    def count_followers(self, user_id: str) -> int:
        return self._count(field="followee_id", user_id=user_id)

    def count_following(self, user_id: str) -> int:
        return self._count(field="follower_id", user_id=user_id)

    def _count(self, *, field: str, user_id: str) -> int:
        try:
            from postgrest import CountMethod

            response = (
                self._client.table(FOLLOWS)
                .select(field, count=CountMethod.exact)
                .eq(field, user_id)
                .execute()
            )
            return getattr(response, "count", 0) or 0
        except Exception as exception:
            logger.exception("Failed to count %s for %s: %s", field, user_id, exception)
            return 0

    def following_ids(self, user_id: str) -> list[str]:
        """Ids `user_id` follows, for the feed's visibility filter."""
        return _following_ids(self._client, user_id)

    def can_read_account(self, user_id: str, viewer_id: str | None) -> bool:
        """Whether `viewer_id` may read anything `user_id` authored.

        A private account is closed as a whole, not post by post: a public post
        by a private account is still that account's, and per-post visibility
        alone would hand it to a stranger. Approving a follower is what opens
        it, which is the point of approving one.

        Fails closed, because `follow_snapshot` does -- an RPC error reports
        `is_private` and no follow edge, so the caller sees nothing rather than
        everything.

        Args:
            user_id: The account being read.
            viewer_id: Who is reading, or None when signed out.

        Returns:
            True for a public account, for the owner, and for an approved
            follower. False otherwise.
        """
        if viewer_id and viewer_id == user_id:
            return True
        snapshot, _ = self.follow_snapshot(user_id, viewer_id)
        if not snapshot.get("is_private"):
            return True
        return bool(snapshot.get("is_following"))

    def follower_ids(self, user_id: str) -> list[str]:
        return self._edge_ids(
            select_field="follower_id", match_field="followee_id", user_id=user_id
        )

    def _edge_ids(self, *, select_field: str, match_field: str, user_id: str) -> list[str]:
        try:
            response = (
                self._client.table(FOLLOWS)
                .select(select_field)
                .eq(match_field, user_id)
                .order("created_at", desc=True)
                .limit(MAX_FOLLOW_IDS)
                .execute()
            )
            data = getattr(response, "data", None)
            if not isinstance(data, list):
                return []
            return [row[select_field] for row in data if row.get(select_field)]
        except Exception as exception:
            logger.exception("Failed to list %s for %s: %s", select_field, user_id, exception)
            return []

    def list_follow_edges(
        self,
        *,
        user_id: str,
        direction: str,
        limit: int = 20,
        offset: int = 0,
    ) -> list[dict[str, Any]]:
        """One page of followers or following, joined to `user_info` for names.

        `direction` is "followers" (people who follow `user_id`) or "following".
        """
        if direction == "followers":
            match_field, join = "followee_id", "user_info!follows_follower_id_fkey"
            id_field = "follower_id"
        else:
            match_field, join = "follower_id", "user_info!follows_followee_id_fkey"
            id_field = "followee_id"

        try:
            response = (
                self._client.table(FOLLOWS)
                .select(f"{id_field}, created_at, {join}(email, first_name, last_name)")
                .eq(match_field, user_id)
                .order("created_at", desc=True)
                .range(offset, offset + limit - 1)
                .execute()
            )
            data = getattr(response, "data", None)
            if not isinstance(data, list):
                return []

            rows: list[dict[str, Any]] = []
            for row in data:
                info = row.get("user_info") or {}
                rows.append(
                    {
                        "user_id": row.get(id_field),
                        "email": info.get("email"),
                        "first_name": info.get("first_name"),
                        "last_name": info.get("last_name"),
                        "created_at": row.get("created_at"),
                    }
                )
            return rows
        except Exception as exception:
            logger.exception("Failed to list %s for %s: %s", direction, user_id, exception)
            return []
