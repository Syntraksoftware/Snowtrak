"""`_fetch_all_activities` now runs on a request path (see test_stats_routes.py),
not only from a background job, so an unbounded `SELECT` here would violate
CLAUDE.md Rule 3. It must carry an explicit ordering and a cap.

The fake below applies `.eq`, `.not_.in_`, `.order` and `.limit` the way
PostgREST does, so a missing `.order()` or `.limit()` shows up as the wrong
rows coming back -- not an un-asserted call on a mock.
"""

from typing import Any

from services.user_stats_service import UserStatsService


def _activity(activity_id: str, start_time: str, status: str = "ready") -> dict[str, Any]:
    return {
        "id": activity_id,
        "user_id": "user-1",
        "start_time": start_time,
        "duration_seconds": 600,
        "distance_meters": 1000.0,
        "elevation_gain_meters": 50.0,
        "processing_status": status,
    }


class _Response:
    def __init__(self, data):
        self.data = data


class _NotFilter:
    def __init__(self, query):
        self._query = query

    def in_(self, column, values):
        self._query._rows = [r for r in self._query._rows if r.get(column) not in values]
        return self._query


class _Query:
    def __init__(self, rows):
        self._rows = list(rows)
        self._order: tuple[str, bool] | None = None
        self._limit_n: int | None = None

    def select(self, *_args, **_kwargs):
        return self

    def eq(self, column, value):
        self._rows = [r for r in self._rows if r.get(column) == value]
        return self

    @property
    def not_(self):
        return _NotFilter(self)

    def order(self, column, desc=False):
        self._order = (column, desc)
        return self

    def limit(self, n):
        self._limit_n = n
        return self

    def execute(self):
        rows = self._rows
        if self._order is not None:
            column, desc = self._order
            rows = sorted(rows, key=lambda r: r[column], reverse=desc)
        if self._limit_n is not None:
            rows = rows[: self._limit_n]
        return _Response(rows)


class _FakeClient:
    def __init__(self, rows):
        self._rows = rows

    def table(self, _name):
        return _Query(self._rows)


#: Deliberately unordered on input -- the fake hands rows back exactly as
#: given unless the service asks for an order, which is the wrong order for
#: "newest first, capped".
ROWS = [
    _activity("mid", "2026-08-29T09:00:00Z"),
    _activity("oldest", "2026-08-28T09:00:00Z"),
    _activity("newest", "2026-08-30T09:00:00Z"),
    _activity("pending", "2026-08-31T09:00:00Z", status="pending"),
]


def test_orders_newest_first():
    service = UserStatsService(_FakeClient(ROWS))

    result = service._fetch_all_activities("user-1")

    assert [row["id"] for row in result] == ["newest", "mid", "oldest"]


def test_excludes_in_flight_activities():
    service = UserStatsService(_FakeClient(ROWS))

    result = service._fetch_all_activities("user-1")

    assert "pending" not in {row["id"] for row in result}


def test_caps_at_the_configured_ceiling(monkeypatch):
    monkeypatch.setattr(UserStatsService, "_MAX_ACTIVITIES_FOR_RECOMPUTE", 2)
    service = UserStatsService(_FakeClient(ROWS))

    result = service._fetch_all_activities("user-1")

    assert len(result) == 2
    # Capped *after* ordering newest-first, so a user over the ceiling loses
    # their oldest activities, not an arbitrary slice.
    assert [row["id"] for row in result] == ["newest", "mid"]
