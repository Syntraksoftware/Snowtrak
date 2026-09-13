"""Turning recorded speed into the `activities.max_pace` column.

The column is seconds per kilometre and the speed leaderboard inverts it to
km/h (`db/migrations/020_leaderboard_functions.sql`), so whatever is written
here decides a board. Two things follow from that, and both live here rather
than at the two call sites:

* A raw per-point maximum is the wrong statistic. One bad fix on a chairlift
  outranks a season of real skiing, and the board keeps it for the week.
* Zero is a missing reading, not an infinite speed. The SQL says so with
  `nullif(a.max_pace, 0)` and `domain.competition.metrics.score` agrees, so
  an unreadable activity has to come back as `None` and leave the column
  alone.
"""

from __future__ import annotations

from collections.abc import Iterable

#: Which sample counts as the run's top speed. High enough to be the fast
#: part of a descent, low enough that a single GPS dropout cannot set it.
TOP_SPEED_PERCENTILE = 0.95

_SECONDS_PER_HOUR = 3600.0
_KMH_PER_MS = 3.6


def pace_from_speed_kmh(speed_kmh: float | None) -> float | None:
    """Converts a speed to seconds per kilometre.

    Args:
        speed_kmh: Kilometres per hour, or None/0 for no reading.

    Returns:
        Seconds per kilometre, or None when there is no usable reading.
    """
    if not speed_kmh or speed_kmh <= 0:
        return None
    return _SECONDS_PER_HOUR / speed_kmh


def top_speed_kmh_from_samples(speeds_ms: Iterable[float | None]) -> float | None:
    """Picks an activity's top speed out of per-point GPS samples.

    Takes `TOP_SPEED_PERCENTILE` of the positive samples rather than the
    largest one, because the largest one is routinely a dropout.

    Args:
        speeds_ms: Per-point speeds in metres per second, in any order;
            None, zero and negative entries are ignored.

    Returns:
        Kilometres per hour, or None when nothing was recorded.
    """
    samples = sorted(speed for speed in speeds_ms if speed is not None and speed > 0)
    if not samples:
        return None
    # ponytail: nearest-rank percentile, no interpolation. A track has
    # hundreds of points, so the neighbouring sample is within noise of the
    # interpolated one; swap in statistics.quantiles if that stops holding.
    return samples[int(TOP_SPEED_PERCENTILE * (len(samples) - 1))] * _KMH_PER_MS
