"""Duel state: what a duel is, and which transitions are legal.

The rules live here so that "can this person accept this challenge" is a
question about values rather than a question about the database. Persistence
enforces the same rules a second time with a conditional update; this module
is what makes them readable.

Design: docs/superpowers/specs/2026-09-02-duel-and-leaderboard-design.md
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timedelta
from enum import StrEnum
from typing import Any

from domain.competition.metrics import Duration, Metric

#: How long an unanswered challenge stands before the settlement sweep
#: expires it. Long enough to survive a day off the app, short enough that a
#: forgotten invitation does not block the pair's next duel indefinitely.
INVITE_TTL = timedelta(hours=48)


class DuelStatus(StrEnum):
    """Where a duel is in its life."""

    PENDING = "pending"
    ACTIVE = "active"
    FINISHED = "finished"
    DECLINED = "declined"
    CANCELLED = "cancelled"
    EXPIRED = "expired"


#: Every legal move. Anything absent is terminal, which is most of them: a
#: declined duel is not re-opened, it is superseded by a new challenge.
_TRANSITIONS: dict[DuelStatus, frozenset[DuelStatus]] = {
    DuelStatus.PENDING: frozenset(
        {
            DuelStatus.ACTIVE,
            DuelStatus.DECLINED,
            DuelStatus.CANCELLED,
            DuelStatus.EXPIRED,
        }
    ),
    DuelStatus.ACTIVE: frozenset({DuelStatus.FINISHED}),
}

LIVE_STATUSES = frozenset({DuelStatus.PENDING, DuelStatus.ACTIVE})


def can_transition(current: DuelStatus, target: DuelStatus) -> bool:
    """Whether `current` is allowed to become `target`."""
    return target in _TRANSITIONS.get(current, frozenset())


@dataclass(frozen=True)
class Duel:
    """One head-to-head, as read from the `duels` table."""

    id: str
    challenger_id: str
    opponent_id: str
    metric: Metric
    duration: Duration
    status: DuelStatus
    created_at: datetime
    starts_at: datetime | None = None
    ends_at: datetime | None = None
    challenger_value: float | None = None
    opponent_value: float | None = None
    winner_id: str | None = None
    settled_at: datetime | None = None

    @classmethod
    def from_row(cls, row: dict[str, Any]) -> Duel:
        """Builds a duel from a `duels` row.

        Raises:
            ValueError: If the row carries a metric, duration or status this
                version does not know. Failing here beats scoring a duel by
                a rule we cannot name.
        """
        return cls(
            id=str(row["id"]),
            challenger_id=str(row["challenger_id"]),
            opponent_id=str(row["opponent_id"]),
            metric=Metric(row["metric"]),
            duration=Duration(row["duration"]),
            status=DuelStatus(row["status"]),
            created_at=_moment(row["created_at"]),
            starts_at=_optional_moment(row.get("starts_at")),
            ends_at=_optional_moment(row.get("ends_at")),
            challenger_value=row.get("challenger_value"),
            opponent_value=row.get("opponent_value"),
            winner_id=_optional_str(row.get("winner_id")),
            settled_at=_optional_moment(row.get("settled_at")),
        )

    def involves(self, user_id: str) -> bool:
        """Whether `user_id` is one of the two players."""
        return user_id in (self.challenger_id, self.opponent_id)

    def opponent_of(self, user_id: str) -> str:
        """The other player.

        Raises:
            ValueError: If `user_id` is not in this duel.
        """
        if user_id == self.challenger_id:
            return self.opponent_id
        if user_id == self.opponent_id:
            return self.challenger_id
        raise ValueError("user is not a player in this duel")

    def is_expired_at(self, now: datetime) -> bool:
        """Whether an unanswered challenge has outlived `INVITE_TTL`."""
        return self.status is DuelStatus.PENDING and self.created_at + INVITE_TTL <= now

    def is_decidable_at(self, now: datetime) -> bool:
        """Whether the window has closed and a winner can be written."""
        return self.status is DuelStatus.ACTIVE and self.ends_at is not None and self.ends_at <= now

    def may_accept(self, viewer_id: str, now: datetime) -> bool:
        """Only the challenged player, only while the invitation stands."""
        return (
            viewer_id == self.opponent_id
            and self.status is DuelStatus.PENDING
            and not self.is_expired_at(now)
        )

    def may_decline(self, viewer_id: str, now: datetime) -> bool:
        """Declining and accepting are open to the same person at the same
        times."""
        return self.may_accept(viewer_id, now)

    def may_cancel(self, viewer_id: str) -> bool:
        """Withdrawing is the challenger's, and only before it is accepted."""
        return viewer_id == self.challenger_id and self.status is DuelStatus.PENDING


def resolve_winner(duel: Duel, challenger_value: float, opponent_value: float) -> str | None:
    """Decides a finished duel.

    Args:
        duel: The duel being settled.
        challenger_value: The challenger's score, already comparable -- see
            `metrics.score`, where every metric is normalised so that higher
            wins.
        opponent_value: The opponent's score.

    Returns:
        The winner's user id, or `None` for a draw. Two players who both
        recorded nothing draw at zero; that is a draw, not a loss for both.
    """
    if challenger_value > opponent_value:
        return duel.challenger_id
    if opponent_value > challenger_value:
        return duel.opponent_id
    return None


def _moment(value: Any) -> datetime:
    return value if isinstance(value, datetime) else datetime.fromisoformat(value)


def _optional_moment(value: Any) -> datetime | None:
    return None if value is None else _moment(value)


def _optional_str(value: Any) -> str | None:
    return None if value is None else str(value)
