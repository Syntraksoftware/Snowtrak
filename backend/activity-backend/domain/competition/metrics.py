"""Scoring rules shared by duels and the leaderboard.

Both features reduce to the same question: given one column of `activities`
over one window, what is the single number that ranks a user? This module is
that question and nothing else -- no client, no query, no I/O.

Design: docs/superpowers/specs/2026-09-02-duel-and-leaderboard-design.md
"""

from __future__ import annotations

from collections.abc import Iterable
from datetime import UTC, date, datetime, time, timedelta
from enum import StrEnum

SECONDS_PER_HOUR = 3600


class Metric(StrEnum):
    """What a board or a duel is measured on."""

    VERTICAL = "vertical"
    SPEED = "speed"
    DISTANCE = "distance"


class Duration(StrEnum):
    """How long a duel window runs."""

    TODAY = "today"
    WEEKEND = "weekend"
    WEEK = "week"


#: The `activities` column each metric reads. Speed reads `max_pace`, which
#: `score` then has to invert -- see there for why it is not a plain sum.
METRIC_COLUMNS: dict[Metric, str] = {
    Metric.VERTICAL: "elevation_gain_meters",
    Metric.DISTANCE: "distance_meters",
    Metric.SPEED: "max_pace",
}


def score(metric: Metric, values: Iterable[float | None]) -> float:
    """Reduces one activity column to a single comparable number.

    Higher always wins, for every metric. Speed is the reason that needs
    saying: `activities.max_pace` is seconds per kilometre, so the fastest
    run is the *smallest* positive value, and the column defaults to 0 when
    there is no reading rather than meaning infinitely fast. Converting to
    km/h here means every caller can order descending and every value on a
    board reads the same direction.

    Args:
        metric: Which rule to apply.
        values: The metric's column, one entry per activity in the window.

    Returns:
        Kilometres per hour for `SPEED`; the column's own unit, summed, for
        the others. Zero when nothing in `values` counts.
    """
    if metric is Metric.SPEED:
        paces = [v for v in values if v is not None and v > 0]
        return SECONDS_PER_HOUR / min(paces) if paces else 0.0
    return float(sum(v for v in values if v is not None))


def week_start(moment: datetime) -> date:
    """Monday of the UTC week containing `moment`.

    Matches the `week_start` convention `user_stats` already uses, so the two
    do not disagree about which week an activity belongs to.
    """
    day = moment.astimezone(UTC).date()
    return day - timedelta(days=day.weekday())


def week_bounds(moment: datetime) -> tuple[datetime, datetime]:
    """Half-open UTC bounds of the week containing `moment`.

    Returns:
        `(start, end)` where an activity counts if `start <= start_time <
        end`. Half-open so no activity lands in two consecutive weeks.
    """
    start = datetime.combine(week_start(moment), time.min, tzinfo=UTC)
    return start, start + timedelta(days=7)


def duel_window(duration: Duration, accepted_at: datetime) -> tuple[datetime, datetime]:
    """Bounds of a duel window, given when the challenge was accepted.

    The window opens at acceptance, never before, so neither player can bank
    a head start by choosing when to send the challenge. Both players get
    the same bounds, so a late acceptance shortens the duel for both rather
    than handicapping one.

    `WEEKEND` is the exception to "opens at acceptance": it opens on Friday
    when accepted earlier in the week, because a Friday-to-Sunday duel that
    silently counted Tuesday would not be the duel the label promised. It
    still never opens in the past.

    Args:
        duration: The chosen window length.
        accepted_at: When the opponent accepted.

    Returns:
        `(starts_at, ends_at)`, half-open, both UTC.
    """
    now = accepted_at.astimezone(UTC)
    midnight = datetime.combine(now.date(), time.min, tzinfo=UTC)

    if duration is Duration.TODAY:
        return now, midnight + timedelta(days=1)

    if duration is Duration.WEEK:
        return now, now + timedelta(days=7)

    monday = datetime.combine(week_start(now), time.min, tzinfo=UTC)
    friday = monday + timedelta(days=4)
    return max(now, friday), monday + timedelta(days=7)
