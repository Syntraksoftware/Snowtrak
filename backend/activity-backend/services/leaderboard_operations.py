"""Reading and settling the global leaderboard.

Orchestration only. Every rule this module relies on -- which column a
metric reads, where a week starts, why speed is inverted -- lives in
`domain/competition/metrics.py` or in the SQL functions that mirror it.

Design: docs/superpowers/specs/2026-09-02-duel-and-leaderboard-design.md
"""

from __future__ import annotations

import logging
from datetime import UTC, date, datetime
from typing import Any

from domain.competition.metrics import Metric, week_bounds, week_start

logger = logging.getLogger(__name__)

GLOBAL_SCOPE = "global"

#: A board page. Deep paging into a leaderboard is not a use anyone has;
#: someone looking for their own row uses `placing` instead.
DEFAULT_LIMIT = 50
MAX_LIMIT = 100

#: How far down each weekly snapshot is kept. Past this, a placing is not
#: something anyone displays, and the table grows for nothing.
SNAPSHOT_DEPTH = 100

_operations: LeaderboardOperations | None = None


def initialize_leaderboard_operations(client) -> LeaderboardOperations:
    """Binds the module singleton to a configured Supabase client."""
    global _operations
    _operations = LeaderboardOperations(client)
    return _operations


def get_leaderboard_operations() -> LeaderboardOperations:
    """The initialized singleton.

    Raises:
        RuntimeError: If startup did not initialize it.
    """
    if _operations is None:
        raise RuntimeError(
            "Leaderboard operations not initialized. "
            "Call initialize_leaderboard_operations() at startup."
        )
    return _operations


class LeaderboardOperations:
    """Board reads and the weekly snapshot write."""

    _PROFILE_COLUMNS = "id,full_name,username,avatar_url,country_code"

    def __init__(self, client) -> None:
        self._client = client

    def top(
        self,
        metric: Metric,
        scope: str,
        moment: datetime | None = None,
        limit: int = DEFAULT_LIMIT,
    ) -> list[dict[str, Any]]:
        """The live board for the week containing `moment`.

        Args:
            metric: What the board measures.
            scope: `GLOBAL_SCOPE` or an ISO-2 country code.
            moment: Any instant in the week to read. Defaults to now.
            limit: Rows to return, capped at `MAX_LIMIT`.

        Returns:
            Rows of `{rank, user_id, value, display_name, avatar_url}`,
            already ordered. Empty when nobody has opted in this week, and
            empty on a failed read -- a board that shows stale or partial
            standings is worse than one that shows none.
        """
        start, end = week_bounds(moment or datetime.now(UTC))
        rows = self._rank(metric, scope, start, end, min(limit, MAX_LIMIT))
        return self._with_profiles(rows)

    def placing(
        self,
        user_id: str,
        metric: Metric,
        scope: str,
        moment: datetime | None = None,
    ) -> dict[str, Any] | None:
        """Where one user stands, however deep in the board they are.

        Returns:
            `{rank, value}`, or `None` when they have not placed -- no
            opted-in activity in the window, or nothing the metric can read.
        """
        start, end = week_bounds(moment or datetime.now(UTC))
        try:
            response = self._client.rpc(
                "leaderboard_placing",
                {
                    "p_user": user_id,
                    "p_metric": str(metric),
                    "p_scope": scope,
                    "p_start": start.isoformat(),
                    "p_end": end.isoformat(),
                },
            ).execute()
        except Exception as exception:
            logger.exception("leaderboard_placing failed: %s", exception)
            return None
        data = getattr(response, "data", None)
        return data[0] if isinstance(data, list) and data else None

    def week(
        self,
        week: date,
        metric: Metric,
        scope: str,
        limit: int = DEFAULT_LIMIT,
    ) -> list[dict[str, Any]]:
        """A settled week, read back from the snapshot.

        Returns:
            The same row shape as `top`. Empty when that week was never
            settled -- before this feature shipped, or a week with nobody in
            it.
        """
        try:
            response = (
                self._client.table("leaderboard_weeks")
                .select("rank,user_id,value")
                .eq("week_start", week.isoformat())
                .eq("metric", str(metric))
                .eq("scope", scope)
                .order("rank")
                .limit(min(limit, MAX_LIMIT))
                .execute()
            )
        except Exception as exception:
            logger.exception("Failed to read week %s: %s", week, exception)
            return []
        rows = getattr(response, "data", None)
        return self._with_profiles(rows if isinstance(rows, list) else [])

    def settle_week(self, moment: datetime) -> int:
        """Writes the snapshot for the week containing `moment`.

        Idempotent: the rows are upserted on the snapshot's primary key, so
        a second run -- another replica, a restart mid-sweep -- overwrites
        rather than duplicates.

        Args:
            moment: Any instant in the week being settled.

        Returns:
            How many rows were written, across every metric and scope.
        """
        start, end = week_bounds(moment)
        week = week_start(moment)
        written = 0
        for scope in [GLOBAL_SCOPE, *self._scopes(start, end)]:
            for metric in Metric:
                rows = self._rank(metric, scope, start, end, SNAPSHOT_DEPTH)
                if rows:
                    written += self._upsert_snapshot(week, metric, scope, rows)
        logger.info("Settled week %s: %d rows", week, written)
        return written

    def _rank(
        self,
        metric: Metric,
        scope: str,
        start: datetime,
        end: datetime,
        limit: int,
    ) -> list[dict[str, Any]]:
        try:
            response = self._client.rpc(
                "leaderboard_top",
                {
                    "p_metric": str(metric),
                    "p_scope": scope,
                    "p_start": start.isoformat(),
                    "p_end": end.isoformat(),
                    "p_limit": limit,
                },
            ).execute()
        except Exception as exception:
            logger.exception("leaderboard_top failed: %s", exception)
            return []
        data = getattr(response, "data", None)
        return data if isinstance(data, list) else []

    def _scopes(self, start: datetime, end: datetime) -> list[str]:
        try:
            response = self._client.rpc(
                "leaderboard_scopes",
                {"p_start": start.isoformat(), "p_end": end.isoformat()},
            ).execute()
        except Exception as exception:
            logger.exception("leaderboard_scopes failed: %s", exception)
            return []
        data = getattr(response, "data", None)
        if not isinstance(data, list):
            return []
        return [row["scope"] for row in data if row.get("scope")]

    def _upsert_snapshot(
        self,
        week: date,
        metric: Metric,
        scope: str,
        rows: list[dict[str, Any]],
    ) -> int:
        payload = [
            {
                "week_start": week.isoformat(),
                "metric": str(metric),
                "scope": scope,
                "rank": row["rank"],
                "user_id": row["user_id"],
                "value": row["value"],
            }
            for row in rows
        ]
        try:
            self._client.table("leaderboard_weeks").upsert(payload).execute()
        except Exception as exception:
            logger.exception("Failed to snapshot %s/%s: %s", metric, scope, exception)
            return 0
        return len(payload)

    def _with_profiles(self, rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
        """Attaches display fields in one round trip, not one per row."""
        if not rows:
            return []
        ids = [row["user_id"] for row in rows if row.get("user_id")]
        profiles = self._profiles(ids)
        return [
            {
                "rank": row["rank"],
                "user_id": row["user_id"],
                "value": row["value"],
                **_display(profiles.get(row["user_id"], {})),
            }
            for row in rows
        ]

    def _profiles(self, ids: list[str]) -> dict[str, dict[str, Any]]:
        if not ids:
            return {}
        try:
            response = (
                self._client.table("profiles")
                .select(self._PROFILE_COLUMNS)
                .in_("id", ids)
                .execute()
            )
        except Exception as exception:
            logger.exception("Failed to read board profiles: %s", exception)
            return {}
        data = getattr(response, "data", None)
        if not isinstance(data, list):
            return {}
        return {str(row["id"]): row for row in data if row.get("id")}


def _display(profile: dict[str, Any]) -> dict[str, Any]:
    """The public half of a profile, for a board row.

    A board shows a name, a picture and a country. It never shows an
    activity, which is what lets a private activity count towards a total
    without leaking anything about itself.
    """
    return {
        "display_name": profile.get("full_name") or profile.get("username") or "Skier",
        "username": profile.get("username"),
        "avatar_url": profile.get("avatar_url"),
        "country_code": profile.get("country_code"),
    }
