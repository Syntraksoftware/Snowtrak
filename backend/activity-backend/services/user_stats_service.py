"""Cached user stats: compute from all activities and persist to user_stats table."""

from __future__ import annotations

import logging
from datetime import UTC, date, datetime, timedelta
from typing import Any

from supabase import create_client

logger = logging.getLogger(__name__)

_stats_service: UserStatsService | None = None


def initialize_stats_service() -> UserStatsService:
    global _stats_service
    from config import get_config
    config = get_config()
    client = create_client(config.SUPABASE_URL, config.SUPABASE_SERVICE_ROLE_KEY)
    _stats_service = UserStatsService(client)
    logger.info("✅ User stats service initialized")
    return _stats_service


def get_stats_service() -> UserStatsService:
    if _stats_service is None:
        raise RuntimeError("Stats service not initialized. Call initialize_stats_service() at startup.")
    return _stats_service


class UserStatsService:

    _STATS_COLUMNS = "start_time,duration_seconds,distance_meters,elevation_gain_meters"
    # ponytail: a full recompute genuinely needs every activity, but
    # GET /me/stats now runs this on a cache miss (a request path), so an
    # unconditional SELECT * is no longer acceptable per CLAUDE.md Rule 3.
    # 5,000 rows ordered newest-first caps memory and query time; an account
    # past that ceiling gets an all-time total missing its oldest activities
    # rather than an unbounded query landing on every profile-open. Revisit
    # with real pagination if this cap is ever hit in practice.
    _MAX_ACTIVITIES_FOR_RECOMPUTE = 5000

    def __init__(self, client) -> None:
        self._client = client

    def get_stats(self, user_id: str) -> dict[str, Any] | None:
        resp = (
            self._client.table("user_stats")
            .select("*")
            .eq("user_id", user_id)
            .execute()
        )
        data = getattr(resp, "data", None)
        return data[0] if data else None

    def recompute_and_upsert(self, user_id: str) -> dict[str, Any] | None:
        """Recompute stats from all activities and persist.

        If no activities remain (e.g. user deleted their last one), removes the
        stale row so the route returns zeros without a spurious DB read.
        """
        try:
            activities = self._fetch_all_activities(user_id)
            if not activities:
                self._delete_row(user_id)
                return None
            stats = _compute_stats(user_id, activities)
            return self._upsert(stats)
        except Exception:
            logger.exception("Failed to recompute stats for user %s", user_id)
            return None

    def _fetch_all_activities(self, user_id: str) -> list[dict[str, Any]]:
        resp = (
            self._client.table("activities")
            .select(self._STATS_COLUMNS)
            .eq("user_id", user_id)
            .not_.in_("processing_status", ["pending", "uploading", "processing"])
            .order("start_time", desc=True)
            .limit(self._MAX_ACTIVITIES_FOR_RECOMPUTE)
            .execute()
        )
        return getattr(resp, "data", None) or []

    def _upsert(self, stats: dict[str, Any]) -> dict[str, Any] | None:
        resp = (
            self._client.table("user_stats")
            .upsert(stats, on_conflict="user_id")
            .execute()
        )
        data = getattr(resp, "data", None)
        return data[0] if data else None

    def _delete_row(self, user_id: str) -> None:
        self._client.table("user_stats").delete().eq("user_id", user_id).execute()


def _compute_stats(user_id: str, activities: list[dict[str, Any]]) -> dict[str, Any]:
    today = date.today()
    week_start = today - timedelta(days=today.weekday())
    last_week_start = week_start - timedelta(days=7)
    year_start = date(today.year, 1, 1)

    weekly_dist = weekly_elev = 0.0
    yearly_dist = yearly_elev = 0.0
    all_time_dist = all_time_elev = 0.0
    weekly_time = weekly_count = last_week_count = 0
    yearly_time = yearly_count = 0
    all_time_time = all_time_count = 0
    activity_days: set[date] = set()

    for activity in activities:
        start = _parse_date(activity["start_time"])
        if start is None:
            continue

        dist_km = (activity["distance_meters"] or 0) / 1000
        elev_m = activity["elevation_gain_meters"] or 0
        time_min = (activity["duration_seconds"] or 0) // 60

        activity_days.add(start)
        all_time_dist += dist_km
        all_time_elev += elev_m
        all_time_time += time_min
        all_time_count += 1

        if start >= year_start:
            yearly_dist += dist_km
            yearly_elev += elev_m
            yearly_time += time_min
            yearly_count += 1

        if start >= week_start:
            weekly_dist += dist_km
            weekly_elev += elev_m
            weekly_time += time_min
            weekly_count += 1
        elif start >= last_week_start:
            last_week_count += 1

    current_streak, longest_streak = _compute_streaks(activity_days, week_start)

    return {
        "user_id": user_id,
        "week_start": week_start.isoformat(),
        "weekly_distance_km": round(weekly_dist, 3),
        "weekly_time_min": weekly_time,
        "weekly_elev_gain_m": round(weekly_elev, 1),
        "weekly_session_count": weekly_count,
        "last_week_session_count": last_week_count,
        "yearly_distance_km": round(yearly_dist, 3),
        "yearly_time_min": yearly_time,
        "yearly_elev_gain_m": round(yearly_elev, 1),
        "yearly_session_count": yearly_count,
        "all_time_distance_km": round(all_time_dist, 3),
        "all_time_time_min": all_time_time,
        "all_time_elev_gain_m": round(all_time_elev, 1),
        "all_time_session_count": all_time_count,
        "current_streak_weeks": current_streak,
        "longest_streak_weeks": longest_streak,
        "activity_days": sorted(d.isoformat() for d in activity_days),
        "best_efforts": _compute_best_efforts(activities),
    }


def _compute_best_efforts(activities: list[dict[str, Any]]) -> list[dict[str, Any]]:
    if not activities:
        return []

    efforts: list[dict[str, Any]] = []

    best_dist = max(activities, key=lambda a: a["distance_meters"] or 0)
    efforts.append({
        "type": "Longest Activity",
        "value": f"{(best_dist['distance_meters'] or 0) / 1000:.1f} km",
        "date": best_dist["start_time"],
        "is_pr": True,
    })

    best_elev = max(activities, key=lambda a: a["elevation_gain_meters"] or 0)
    if (best_elev["elevation_gain_meters"] or 0) > 0:
        efforts.append({
            "type": "Most Elevation",
            "value": f"{best_elev['elevation_gain_meters']:.0f} m",
            "date": best_elev["start_time"],
            "is_pr": False,
        })

    with_pace = [
        a for a in activities
        if (a["distance_meters"] or 0) > 0 and (a["duration_seconds"] or 0) > 0
    ]
    if with_pace:
        fastest = min(with_pace, key=lambda a: a["duration_seconds"] / (a["distance_meters"] / 1000))
        pace_sec = int(fastest["duration_seconds"] / (fastest["distance_meters"] / 1000))
        efforts.append({
            "type": "Best Pace",
            "value": f"{pace_sec // 60}:{pace_sec % 60:02d} /km",
            "date": fastest["start_time"],
            "is_pr": False,
        })

    return efforts


def _compute_streaks(activity_days: set[date], week_start: date) -> tuple[int, int]:
    if not activity_days:
        return 0, 0

    active_mondays = sorted({d - timedelta(days=d.weekday()) for d in activity_days})

    current = 0
    expected = week_start
    for monday in reversed(active_mondays):
        if monday == expected:
            current += 1
            expected -= timedelta(days=7)
        elif monday < expected:
            break

    longest = run = 1
    for i in range(1, len(active_mondays)):
        if (active_mondays[i] - active_mondays[i - 1]).days == 7:
            run += 1
            longest = max(longest, run)
        else:
            run = 1

    return current, longest


def _parse_date(value: str) -> date | None:
    if not value:
        return None
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00")).astimezone(UTC).date()
    except ValueError:
        logger.warning("Could not parse activity date: %s", value)
        return None
