"""Pending follows, for accounts that approve their followers.

These rows are deliberately not in `follows`. That table means one thing --
an accepted edge -- and every visibility read already shipped depends on it
meaning only that. See backend/db/migrations/014_follow_requests.sql.
"""

import logging
from typing import Any

from services.constants.community_tables import FOLLOW_REQUESTS, USER_INFO

logger = logging.getLogger(__name__)


class CommunityFollowRequestOperations:
    """Mixin containing follow-request operations."""

    def is_private_account(self, user_id: str) -> bool:
        """Whether this account approves its followers.

        Fails closed: an unreadable flag is treated as private, so the worst
        case is a request that needed no approval, not a follow that skipped
        one.
        """
        try:
            response = (
                self._client.table(USER_INFO)
                .select("is_private")
                .eq("id", user_id)
                .limit(1)
                .execute()
            )
            data = getattr(response, "data", None)
            if isinstance(data, list) and data:
                return bool(data[0].get("is_private"))
            return False
        except Exception as exception:
            logger.exception("Failed to read privacy for %s: %s", user_id, exception)
            return True

    def request_follow(self, requester_id: str, target_id: str) -> bool:
        """Ask to follow. Idempotent: requesting twice leaves one row."""
        if requester_id == target_id:
            return False
        try:
            (
                self._client.table(FOLLOW_REQUESTS)
                .upsert(
                    {"requester_id": requester_id, "target_id": target_id},
                    on_conflict="requester_id,target_id",
                    ignore_duplicates=True,
                )
                .execute()
            )
            return True
        except Exception as exception:
            logger.exception(
                "Failed to request follow of %s as %s: %s", target_id, requester_id, exception
            )
            return False

    def withdraw_request(self, requester_id: str, target_id: str) -> bool:
        """Take back your own request. Succeeds when there was none."""
        return self._delete_request(requester_id=requester_id, target_id=target_id)

    def deny_request(self, target_id: str, requester_id: str) -> bool:
        """Refuse somebody's request. The same delete, from the other side."""
        return self._delete_request(requester_id=requester_id, target_id=target_id)

    def _delete_request(self, *, requester_id: str, target_id: str) -> bool:
        try:
            (
                self._client.table(FOLLOW_REQUESTS)
                .delete()
                .eq("requester_id", requester_id)
                .eq("target_id", target_id)
                .execute()
            )
            return True
        except Exception as exception:
            logger.exception("Failed to drop follow request: %s", exception)
            return False

    def approve_request(self, target_id: str, requester_id: str) -> bool:
        """Turn a request into a follow, atomically.

        The delete and the insert must not be separable: a crash between
        them either loses the request or duplicates the edge. The function
        also makes it one round trip to a database ~440ms away instead of
        two. See backend/db/migrations/017_follow_requests_function.sql.

        Returns:
            False when there was no request to approve.
        """
        try:
            response = self._client.rpc(
                "approve_follow_request",
                {"target": target_id, "requester": requester_id},
            ).execute()
            return bool(getattr(response, "data", False))
        except Exception as exception:
            logger.exception("Failed to approve %s for %s: %s", requester_id, target_id, exception)
            return False

    def count_requests(self, target_id: str) -> int:
        try:
            from postgrest import CountMethod

            response = (
                self._client.table(FOLLOW_REQUESTS)
                .select("requester_id", count=CountMethod.exact)
                .eq("target_id", target_id)
                .execute()
            )
            return getattr(response, "count", 0) or 0
        except Exception as exception:
            logger.exception("Failed to count requests for %s: %s", target_id, exception)
            return 0

    def list_requests(
        self, target_id: str, limit: int = 20, offset: int = 0
    ) -> list[dict[str, Any]]:
        """One page of incoming requests, newest first, joined for names."""
        try:
            response = (
                self._client.table(FOLLOW_REQUESTS)
                .select(
                    "requester_id, created_at, "
                    "user_info!follow_requests_requester_id_fkey"
                    "(email, first_name, last_name, username)"
                )
                .eq("target_id", target_id)
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
                        "user_id": row.get("requester_id"),
                        "email": info.get("email"),
                        "first_name": info.get("first_name"),
                        "last_name": info.get("last_name"),
                        "username": info.get("username"),
                        "created_at": row.get("created_at"),
                    }
                )
            return rows
        except Exception as exception:
            logger.exception("Failed to list requests for %s: %s", target_id, exception)
            return []
