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
    """Stands in for `UserStatsService`: no DB, calls recorded.

    `persist_recompute=True` mimics the real service's fix for a
    zero-activity user: a recompute now persists a row (see
    `UserStatsService.recompute_and_upsert`), so the *next* `get_stats` call
    is a hit rather than another miss.
    """

    def __init__(self, cached=None, recomputed=None, persist_recompute=False):
        self._cached = cached
        self._recomputed = recomputed
        self._persist_recompute = persist_recompute
        self.recompute_calls: list[str] = []

    def get_stats(self, user_id):
        return self._cached

    def recompute_and_upsert(self, user_id):
        self.recompute_calls.append(user_id)
        if self._persist_recompute:
            self._cached = self._recomputed
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


def test_cache_miss_with_a_failed_recompute_still_returns_zeros(client, app, monkeypatch):
    """If the recompute itself can't run (e.g. DB unreachable), fall back to zero.

    A genuinely zero-activity user does *not* hit this path any more -- the
    real service persists a zeros row instead of returning None (see
    `test_user_stats_service.py`), so `None` here now stands for "the
    recompute failed", not "the user has no activities".
    """
    fake_service = FakeStatsService(cached=None, recomputed=None)
    monkeypatch.setattr(stats_routes, "get_stats_service", lambda: fake_service)

    response = client.get("/api/v1/activities/me/stats")

    assert response.status_code == status.HTTP_200_OK
    body = response.json()
    assert body["all_time_session_count"] == 0
    assert body["all_time_distance_km"] == 0
    assert fake_service.recompute_calls == ["user-1"]


def test_second_request_for_a_zero_activity_user_is_not_a_second_recompute(
    client, app, monkeypatch
):
    """A zero-activity user must not re-run the full recompute on every request.

    Before the fix, a recompute that found no activities deleted the row
    instead of persisting one, so there was never a row for the next
    request to hit -- every single `/me/stats` call for that account
    re-ran `_fetch_all_activities` (and re-issued a `DELETE`) forever. This
    pins the route-level contract: once a recompute has run, a second
    consecutive request must not trigger another one.
    """
    zeros = _stats_row(all_time_session_count=0, all_time_distance_km=0)
    fake_service = FakeStatsService(cached=None, recomputed=zeros, persist_recompute=True)
    monkeypatch.setattr(stats_routes, "get_stats_service", lambda: fake_service)

    first = client.get("/api/v1/activities/me/stats")
    second = client.get("/api/v1/activities/me/stats")

    assert first.status_code == status.HTTP_200_OK
    assert second.status_code == status.HTTP_200_OK
    assert first.json()["all_time_session_count"] == 0
    assert second.json()["all_time_session_count"] == 0
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
