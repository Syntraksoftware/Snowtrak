"""GET /me/stats must not answer a cache miss with zeros when activities exist.

`user_stats` is a cache: rows are only written when `recompute_and_upsert`
runs, and 25 seed activities were inserted straight into `activities`,
bypassing every path that triggers it. A missing row means nobody has
written one -- not that the user has no activities -- so the route needs to
recompute on a miss rather than assert zeros.
"""

from fastapi import status

import routes.stats_routes as stats_routes


class FakeStatsService:
    """Stands in for `UserStatsService`: no DB, calls recorded."""

    def __init__(self, cached=None, recomputed=None):
        self._cached = cached
        self._recomputed = recomputed
        self.recompute_calls: list[str] = []

    def get_stats(self, user_id):
        return self._cached

    def recompute_and_upsert(self, user_id):
        self.recompute_calls.append(user_id)
        return self._recomputed


def _stats_row(user_id="user-1", **overrides):
    row = {
        "user_id": user_id,
        "week_start": "2026-08-31",
        "weekly_distance_km": 12.5,
        "weekly_time_min": 90,
        "weekly_elev_gain_m": 400.0,
        "weekly_session_count": 2,
        "last_week_session_count": 1,
        "yearly_distance_km": 300.0,
        "yearly_time_min": 1800,
        "yearly_elev_gain_m": 9000.0,
        "yearly_session_count": 40,
        "all_time_distance_km": 987.6,
        "all_time_time_min": 5400,
        "all_time_elev_gain_m": 45000.0,
        "all_time_session_count": 123,
        "current_streak_weeks": 3,
        "longest_streak_weeks": 5,
        "activity_days": ["2026-08-30"],
        "best_efforts": [],
    }
    row.update(overrides)
    return row


def test_cache_miss_with_real_activities_recomputes_instead_of_zeros(client, app, monkeypatch):
    """A missing row for an account that has activities must not read as zero."""
    recomputed = _stats_row(all_time_session_count=123, all_time_distance_km=987.6)
    fake_service = FakeStatsService(cached=None, recomputed=recomputed)
    monkeypatch.setattr(stats_routes, "get_stats_service", lambda: fake_service)

    response = client.get("/api/v1/activities/me/stats")

    assert response.status_code == status.HTTP_200_OK
    body = response.json()
    assert body["all_time_session_count"] == 123
    assert body["all_time_distance_km"] == 987.6
    assert fake_service.recompute_calls == ["user-1"]


def test_cache_miss_with_no_activities_still_returns_zeros(client, app, monkeypatch):
    """A genuinely activity-less account still reads as zero, not an error."""
    fake_service = FakeStatsService(cached=None, recomputed=None)
    monkeypatch.setattr(stats_routes, "get_stats_service", lambda: fake_service)

    response = client.get("/api/v1/activities/me/stats")

    assert response.status_code == status.HTTP_200_OK
    body = response.json()
    assert body["all_time_session_count"] == 0
    assert body["all_time_distance_km"] == 0
    assert fake_service.recompute_calls == ["user-1"]


def test_cache_hit_never_recomputes(client, app, monkeypatch):
    """A cached row is trusted as-is -- no request-path recompute on a hit."""
    cached = _stats_row(all_time_session_count=7)
    fake_service = FakeStatsService(cached=cached, recomputed=None)
    monkeypatch.setattr(stats_routes, "get_stats_service", lambda: fake_service)

    response = client.get("/api/v1/activities/me/stats")

    assert response.status_code == status.HTTP_200_OK
    assert response.json()["all_time_session_count"] == 7
    assert fake_service.recompute_calls == []
