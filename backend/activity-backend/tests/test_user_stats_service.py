"""`_fetch_all_activities` now runs on a request path (see test_stats_routes.py),
not only from a background job, so an unbounded `SELECT` here would violate
CLAUDE.md Rule 3. It must carry an explicit ordering and a cap.

The fake below applies `.eq`, `.not_.in_`, `.order` and `.limit` the way
PostgREST does, so a missing `.order()` or `.limit()` shows up as the wrong
rows coming back -- not an un-asserted call on a mock.

`_FakeClient` also backs a `user_stats` table with a plain dict, so
`recompute_and_upsert` and `get_stats` can be exercised end to end: a
zero-activity user must come back from a recompute with a persisted row,
not a deleted one, or every request for that account re-runs the full
recompute forever.
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


class _UserStatsTable:
    """The slice of PostgREST that `get_stats`/`_upsert`/`_upsert` use.

    Backed by a plain dict keyed on `user_id`, shared with whoever
    constructed this table, so a row written by one call is visible to the
    next -- the thing a real Postgres table gives you for free and a
    stateless fake would hide.
    """

    def __init__(self, store: dict[str, Any]):
        self._store = store
        self._eq_user_id: str | None = None
        self._pending_upsert: dict[str, Any] | None = None

    def select(self, *_args, **_kwargs):
        self._pending_upsert = None
        return self

    def eq(self, column, value):
        assert column == "user_id"
        self._eq_user_id = value
        return self

    def upsert(self, stats, on_conflict="user_id"):
        assert on_conflict == "user_id"
        self._pending_upsert = stats
        return self

    def execute(self):
        if self._pending_upsert is not None:
            self._store[self._pending_upsert["user_id"]] = self._pending_upsert
            return _Response([self._pending_upsert])
        row = self._store.get(self._eq_user_id)
        return _Response([row] if row else [])


class _FakeClient:
    def __init__(self, rows, user_stats_store: dict[str, Any] | None = None):
        self._rows = rows
        self._user_stats_store: dict[str, Any] = (
            user_stats_store if user_stats_store is not None else {}
        )

    def table(self, name):
        if name == "user_stats":
            return _UserStatsTable(self._user_stats_store)
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


def test_zero_activities_persists_a_zeros_row_instead_of_deleting():
    """A recompute that finds nothing must leave a row behind to hit.

    Before the fix, this branch deleted the row and returned `None`, so
    there was never anything for the next `get_stats` call to find -- a
    zero-activity account (overwhelmingly new signups, since the route now
    recomputes on every cache miss) re-ran the full recompute on every
    single request, forever.
    """
    store: dict[str, Any] = {}
    service = UserStatsService(_FakeClient([], user_stats_store=store))

    result = service.recompute_and_upsert("user-1")

    assert result is not None
    assert result["all_time_session_count"] == 0
    assert result["all_time_distance_km"] == 0


def test_second_get_stats_after_a_zero_activity_recompute_is_a_cache_hit():
    """Pins the point of the fix: the row a zero-activity recompute writes
    is the same row the very next `get_stats` call reads back -- so a
    caller (the route) never needs to recompute twice in a row.
    """
    store: dict[str, Any] = {}
    service = UserStatsService(_FakeClient([], user_stats_store=store))

    recomputed = service.recompute_and_upsert("user-1")
    cached = service.get_stats("user-1")

    assert cached == recomputed


def test_logs_a_warning_when_the_fetch_lands_exactly_on_the_cap(monkeypatch, caplog):
    """Truncation at the cap must be greppable, not silent.

    A wrong lifetime total for a heavy user should not ship unnoticed --
    the `ponytail:` comment on `_MAX_ACTIVITIES_FOR_RECOMPUTE` names the
    ceiling, and this is what makes hitting it detectable in production.
    """
    import logging

    monkeypatch.setattr(UserStatsService, "_MAX_ACTIVITIES_FOR_RECOMPUTE", 3)
    store: dict[str, Any] = {}
    service = UserStatsService(_FakeClient(ROWS, user_stats_store=store))

    with caplog.at_level(logging.WARNING, logger="services.user_stats_service"):
        service.recompute_and_upsert("user-1")

    assert any("user-1" in record.message and "3" in record.message for record in caplog.records)
