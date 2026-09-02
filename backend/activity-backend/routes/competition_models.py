"""Request and response schemas for duels and the leaderboard.

These are the API contract: snake_case keys, ISO 8601 UTC timestamps, and a
Dart model mirroring each one. A shape change here is a two-sided break --
see docs/api_standardization.md.
"""

from pydantic import BaseModel, Field

from domain.competition.duel import DuelStatus
from domain.competition.metrics import Duration, Metric


class LeaderboardEntry(BaseModel):
    """One row of a board."""

    rank: int
    user_id: str
    value: float
    display_name: str
    username: str | None = None
    avatar_url: str | None = None
    country_code: str | None = None


class LeaderboardResponse(BaseModel):
    """A board page, plus the terms it was read under."""

    metric: Metric
    scope: str
    week_start: str = Field(..., description="ISO date of the Monday, UTC")
    settled: bool = Field(
        ...,
        description="True for a snapshot of a finished week, false for the live board",
    )
    entries: list[LeaderboardEntry]


class LeaderboardPlacing(BaseModel):
    """Where the caller stands, however deep in the board."""

    metric: Metric
    scope: str
    week_start: str
    rank: int | None = None
    value: float = 0.0


class DuelCreate(BaseModel):
    """Terms of a challenge. The window is not chosen here -- it opens when
    the opponent accepts."""

    opponent_id: str
    metric: Metric
    duration: Duration


class DuelResponse(BaseModel):
    """One duel, as both players see it."""

    id: str
    challenger_id: str
    opponent_id: str
    metric: Metric
    duration: Duration
    status: DuelStatus
    created_at: str
    starts_at: str | None = None
    ends_at: str | None = None
    challenger_value: float | None = None
    opponent_value: float | None = None
    winner_id: str | None = None
    settled_at: str | None = None
    # Filled from one profiles read per page, so a list of duels never
    # becomes a profile fetch per card. Never null: a player with no
    # profiles row gets the placeholder in duel_routes.
    challenger_name: str | None = None
    challenger_avatar_url: str | None = None
    opponent_name: str | None = None
    opponent_avatar_url: str | None = None


class DuelsListResponse(BaseModel):
    """A page of duels."""

    items: list[DuelResponse]
    total: int


class DuelRecord(BaseModel):
    """A player's head-to-head history."""

    user_id: str
    wins: int
    losses: int
    draws: int
    recent: list[str] = Field(
        default_factory=list,
        description="Most recent results first, each 'W', 'L' or 'D'",
    )
