"""Creating, answering and settling duels.

Orchestration only: which transitions are legal and who won are decided in
`domain/competition/duel.py`. This module does the reads and writes that
follow, and enforces the same rules a second time as conditions on the
update -- the database is what makes them true under concurrency, the
domain is what makes them readable.

Design: docs/superpowers/specs/2026-09-02-duel-and-leaderboard-design.md
"""

from __future__ import annotations

import logging
from datetime import UTC, datetime
from typing import Any

from postgrest import CountMethod
from shared.follow_graph import follows_each_other

from domain.competition.duel import (
    INVITE_TTL,
    Duel,
    DuelStatus,
    resolve_winner,
)
from domain.competition.metrics import Duration, Metric, duel_window

logger = logging.getLogger(__name__)

#: A duel list is a screen, not an archive.
DEFAULT_LIMIT = 20
MAX_LIMIT = 50

#: How many past results the profile badge shows.
RECENT_FORM = 5

_operations: DuelOperations | None = None


class NotEligible(Exception):
    """The two accounts do not follow each other."""


class DuelInProgress(Exception):
    """A pending or active duel already stands between the two."""


def initialize_duel_operations(client) -> DuelOperations:
    """Binds the module singleton to a configured Supabase client."""
    global _operations
    _operations = DuelOperations(client)
    return _operations


def get_duel_operations() -> DuelOperations:
    """The initialized singleton.

    Raises:
        RuntimeError: If startup did not initialize it.
    """
    if _operations is None:
        raise RuntimeError(
            "Duel operations not initialized. Call initialize_duel_operations() at startup."
        )
    return _operations


class DuelOperations:
    """Persistence for duels, plus the scoring read they settle on."""

    _COLUMNS = (
        "id,challenger_id,opponent_id,metric,duration,status,starts_at,"
        "ends_at,challenger_value,opponent_value,winner_id,created_at,settled_at"
    )

    def __init__(self, client) -> None:
        self._client = client

    # ------------------------------------------------------------------
    # Reads
    # ------------------------------------------------------------------
    def get(self, duel_id: str) -> Duel | None:
        """One duel, or `None` if it does not exist."""
        try:
            response = (
                self._client.table("duels")
                .select(self._COLUMNS)
                .eq("id", duel_id)
                .limit(1)
                .execute()
            )
        except Exception as exception:
            logger.exception("Failed to read duel %s: %s", duel_id, exception)
            return None
        rows = getattr(response, "data", None)
        return Duel.from_row(rows[0]) if isinstance(rows, list) and rows else None

    def list_for(
        self,
        user_id: str,
        status: DuelStatus | None = None,
        limit: int = DEFAULT_LIMIT,
        offset: int = 0,
    ) -> list[Duel]:
        """This user's duels, newest first.

        Args:
            user_id: Whose duels to list.
            status: Narrow to one status, or `None` for all of them.
            limit: Rows to return, capped at `MAX_LIMIT`.
            offset: Rows to skip.

        Returns:
            Duels in which `user_id` is a player. Empty on a failed read.
        """
        capped = min(limit, MAX_LIMIT)
        try:
            query = (
                self._client.table("duels")
                .select(self._COLUMNS)
                .or_(f"challenger_id.eq.{user_id},opponent_id.eq.{user_id}")
                .order("created_at", desc=True)
                .range(offset, offset + capped - 1)
            )
            if status is not None:
                query = query.eq("status", str(status))
            response = query.execute()
        except Exception as exception:
            logger.exception("Failed to list duels for %s: %s", user_id, exception)
            return []
        rows = getattr(response, "data", None)
        return [Duel.from_row(row) for row in rows] if isinstance(rows, list) else []

    def record(self, user_id: str) -> dict[str, Any]:
        """Win/loss/draw counts and the last few results.

        Derived rather than stored. A counter table would need a write on
        every settlement and would drift the first time one failed.
        """
        finished = self._count(user_id, extra=None)
        wins = self._count(user_id, extra=("winner_id", user_id))
        draws = self._count(user_id, extra=("winner_id", None))
        return {
            "wins": wins,
            "losses": max(finished - wins - draws, 0),
            "draws": draws,
            "recent": self._recent(user_id),
        }

    def score(self, user_id: str, metric: Metric, start: datetime, end: datetime) -> float:
        """One player's score over one window.

        Reads every activity in the window, not only the ones published to
        the leaderboard: the opponent is a friend, and a private match
        should not require publishing anything.

        Returns:
            The metric's comparable value -- higher wins, for all of them.
            Zero on a failed read, which loses rather than inventing a
            score.
        """
        try:
            response = self._client.rpc(
                "activity_total",
                {
                    "p_user": user_id,
                    "p_metric": str(metric),
                    "p_start": start.isoformat(),
                    "p_end": end.isoformat(),
                },
            ).execute()
        except Exception as exception:
            logger.exception("activity_total failed for %s: %s", user_id, exception)
            return 0.0
        data = getattr(response, "data", None)
        return float(data) if isinstance(data, int | float) else 0.0

    # ------------------------------------------------------------------
    # Writes
    # ------------------------------------------------------------------
    def create(
        self,
        challenger_id: str,
        opponent_id: str,
        metric: Metric,
        duration: Duration,
    ) -> Duel:
        """Offers a challenge.

        Args:
            challenger_id: Who is challenging.
            opponent_id: Who is being challenged.
            metric: What the duel measures.
            duration: How long the window runs once accepted.

        Returns:
            The pending duel. `starts_at` and `ends_at` are null until it is
            accepted -- that is what keeps the window non-retroactive.

        Raises:
            NotEligible: The two do not follow each other.
            DuelInProgress: A pending or active duel already stands.
            RuntimeError: The write failed.
        """
        if not follows_each_other(self._client, challenger_id, opponent_id):
            raise NotEligible

        payload = {
            "challenger_id": challenger_id,
            "opponent_id": opponent_id,
            "metric": str(metric),
            "duration": str(duration),
            "status": str(DuelStatus.PENDING),
        }
        try:
            response = self._client.table("duels").insert(payload).execute()
        except Exception as exception:
            # `duels_one_live_per_pair` is the only unique constraint an
            # insert can hit, and it is the one worth naming for the caller.
            if _is_unique_violation(exception):
                raise DuelInProgress from exception
            raise
        rows = getattr(response, "data", None)
        if not (isinstance(rows, list) and rows):
            raise RuntimeError("Duel insert returned no row")
        return Duel.from_row(rows[0])

    def accept(self, duel: Duel, now: datetime | None = None) -> Duel | None:
        """Starts the window.

        The update is conditional on the duel still being pending, so two
        taps -- or two replicas -- cannot start it twice with two different
        windows.

        Returns:
            The active duel, or `None` if it was no longer pending.
        """
        moment = now or datetime.now(UTC)
        starts_at, ends_at = duel_window(duel.duration, moment)
        return self._transition(
            duel.id,
            DuelStatus.PENDING,
            {
                "status": str(DuelStatus.ACTIVE),
                "starts_at": starts_at.isoformat(),
                "ends_at": ends_at.isoformat(),
            },
        )

    def decline(self, duel: Duel) -> Duel | None:
        """Refuses a challenge. Terminal: it is not re-opened later."""
        return self._transition(duel.id, DuelStatus.PENDING, {"status": str(DuelStatus.DECLINED)})

    def cancel(self, duel: Duel) -> Duel | None:
        """Withdraws a challenge the opponent has not answered."""
        return self._transition(duel.id, DuelStatus.PENDING, {"status": str(DuelStatus.CANCELLED)})

    def settle(self, duel: Duel) -> Duel | None:
        """Scores a closed window and writes the result.

        Conditional on the duel still being active, so a lazy settlement on
        read and the background sweep can race harmlessly: the loser of that
        race writes nothing.

        Returns:
            The finished duel, or `None` if someone else settled it first.
        """
        if duel.starts_at is None or duel.ends_at is None:
            logger.error("Duel %s is active with no window", duel.id)
            return None

        challenger = self.score(duel.challenger_id, duel.metric, duel.starts_at, duel.ends_at)
        opponent = self.score(duel.opponent_id, duel.metric, duel.starts_at, duel.ends_at)
        return self._transition(
            duel.id,
            DuelStatus.ACTIVE,
            {
                "status": str(DuelStatus.FINISHED),
                "challenger_value": challenger,
                "opponent_value": opponent,
                "winner_id": resolve_winner(duel, challenger, opponent),
                "settled_at": datetime.now(UTC).isoformat(),
            },
        )

    def settle_due(self, now: datetime) -> int:
        """Settles every duel whose window has closed.

        Returns:
            How many were settled.
        """
        settled = 0
        for duel in self._due(now):
            if self.settle(duel) is not None:
                settled += 1
        return settled

    def expire_stale(self, now: datetime) -> int:
        """Expires challenges nobody answered inside `INVITE_TTL`.

        An unanswered invitation is not harmless: it holds the pair's one
        live-duel slot, so the two of them cannot start a different duel
        until it clears.

        Returns:
            How many were expired.
        """
        cutoff = (now - INVITE_TTL).isoformat()
        try:
            response = (
                self._client.table("duels")
                .update({"status": str(DuelStatus.EXPIRED)})
                .eq("status", str(DuelStatus.PENDING))
                .lte("created_at", cutoff)
                .execute()
            )
        except Exception as exception:
            logger.exception("Failed to expire stale duels: %s", exception)
            return 0
        rows = getattr(response, "data", None)
        return len(rows) if isinstance(rows, list) else 0

    # ------------------------------------------------------------------
    # Internals
    # ------------------------------------------------------------------
    def _transition(
        self, duel_id: str, expected: DuelStatus, fields: dict[str, Any]
    ) -> Duel | None:
        try:
            response = (
                self._client.table("duels")
                .update(fields)
                .eq("id", duel_id)
                .eq("status", str(expected))
                .execute()
            )
        except Exception as exception:
            logger.exception("Failed to update duel %s: %s", duel_id, exception)
            return None
        rows = getattr(response, "data", None)
        return Duel.from_row(rows[0]) if isinstance(rows, list) and rows else None

    def _due(self, now: datetime) -> list[Duel]:
        try:
            response = (
                self._client.table("duels")
                .select(self._COLUMNS)
                .eq("status", str(DuelStatus.ACTIVE))
                .lte("ends_at", now.isoformat())
                .order("ends_at")
                .limit(MAX_LIMIT)
                .execute()
            )
        except Exception as exception:
            logger.exception("Failed to list due duels: %s", exception)
            return []
        rows = getattr(response, "data", None)
        return [Duel.from_row(row) for row in rows] if isinstance(rows, list) else []

    def _count(self, user_id: str, extra: tuple[str, str | None] | None) -> int:
        try:
            query = (
                self._client.table("duels")
                .select("id", count=CountMethod.exact)
                .eq("status", str(DuelStatus.FINISHED))
                .or_(f"challenger_id.eq.{user_id},opponent_id.eq.{user_id}")
                .limit(1)
            )
            if extra is not None:
                column, value = extra
                query = query.is_(column, "null") if value is None else query.eq(column, value)
            response = query.execute()
        except Exception as exception:
            logger.exception("Failed to count duels for %s: %s", user_id, exception)
            return 0
        return getattr(response, "count", 0) or 0

    def _recent(self, user_id: str) -> list[str]:
        try:
            response = (
                self._client.table("duels")
                .select("winner_id,settled_at")
                .eq("status", str(DuelStatus.FINISHED))
                .or_(f"challenger_id.eq.{user_id},opponent_id.eq.{user_id}")
                .order("settled_at", desc=True)
                .limit(RECENT_FORM)
                .execute()
            )
        except Exception as exception:
            logger.exception("Failed to read recent form for %s: %s", user_id, exception)
            return []
        rows = getattr(response, "data", None)
        if not isinstance(rows, list):
            return []
        return [_outcome(row.get("winner_id"), user_id) for row in rows]


def _outcome(winner_id: str | None, user_id: str) -> str:
    if winner_id is None:
        return "D"
    return "W" if str(winner_id) == user_id else "L"


def _is_unique_violation(exception: Exception) -> bool:
    """Whether a PostgREST error is Postgres' 23505.

    The client wraps the error rather than typing it, so the code is read
    off whichever attribute this version exposes.
    """
    code = getattr(exception, "code", None)
    if code is None:
        details = getattr(exception, "args", None)
        code = details[0].get("code") if details and isinstance(details[0], dict) else None
    return str(code) == "23505"
