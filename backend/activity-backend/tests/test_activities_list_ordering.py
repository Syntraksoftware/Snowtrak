"""`/activities/me` paging depends on an explicit ordering.

PostgREST's `range` slices whatever order the planner happened to return, so
a query with no ORDER BY can put one row on two pages and another on none.
That is not hypothetical here: the frontend pages this endpoint into the
list Home, Profile, Progress and the map all read.

The fake below applies the filters, the ordering and the slice the way
Postgres does, and holds its rows oldest-first. A missing `.order()`
therefore shows up as rows in the wrong order or a row seen twice -- a
behaviour, not an un-asserted call on a mock.
"""

from typing import Any

from services.supabase_client import ActivitySupabaseClient

ALEX = "alex"
BLAKE = "blake"


def _row(activity_id: str, created_at: str, user_id: str = ALEX) -> dict[str, Any]:
    return {
        "id": activity_id,
        "user_id": user_id,
        "name": activity_id,
        "activity_type": "alpine",
        "created_at": created_at,
    }


class _Response:
    def __init__(self, data, count):
        self.data = data
        self.count = count


class _Query:
    """The slice of PostgREST that `list_user_activities` uses."""

    def __init__(self, rows):
        self._rows = list(rows)
        self._order: tuple[str, bool] | None = None
        self._range: tuple[int, int] | None = None

    def select(self, *_args, **_kwargs):
        return self

    def eq(self, column, value):
        self._rows = [row for row in self._rows if row.get(column) == value]
        return self

    def ilike(self, column, pattern):
        needle = pattern.strip("%").lower()
        self._rows = [row for row in self._rows if needle in str(row.get(column, "")).lower()]
        return self

    def gte(self, column, value):
        self._rows = [row for row in self._rows if row.get(column) >= value]
        return self

    def lte(self, column, value):
        self._rows = [row for row in self._rows if row.get(column) <= value]
        return self

    def order(self, column, desc=False):
        self._order = (column, desc)
        return self

    def range(self, start, end):
        self._range = (start, end)
        return self

    def execute(self):
        rows = self._rows
        # `count` is exact over the filtered set, before the slice, which is
        # what CountMethod.exact gives.
        total = len(rows)
        if self._order is not None:
            column, desc = self._order
            rows = sorted(rows, key=lambda row: row[column], reverse=desc)
        if self._range is not None:
            start, end = self._range
            rows = rows[start : end + 1]
        return _Response(rows, total)


class _FakeClient:
    def __init__(self, rows):
        self._rows = rows

    def table(self, _name):
        return _Query(self._rows)


#: Deliberately oldest-first. Without an ORDER BY the fake hands them back in
#: this order, which is the wrong one for every caller.
ROWS = [
    _row("oldest", "2026-08-28T09:00:00Z"),
    _row("older", "2026-08-29T09:00:00Z"),
    _row("newer", "2026-08-30T09:00:00Z"),
    _row("newest", "2026-08-31T09:00:00Z"),
    _row("blake-newest", "2026-09-01T09:00:00Z", user_id=BLAKE),
]


def _client() -> ActivitySupabaseClient:
    return ActivitySupabaseClient(_FakeClient(ROWS))


def test_returns_newest_first():
    result = _client().list_user_activities(user_id=ALEX, limit=10)

    assert [row["id"] for row in result["items"]] == [
        "newest",
        "newer",
        "older",
        "oldest",
    ]


def test_pages_neither_repeat_nor_skip_a_row():
    client = _client()
    first = client.list_user_activities(user_id=ALEX, limit=2, offset=0)
    second = client.list_user_activities(user_id=ALEX, limit=2, offset=2)

    seen = [row["id"] for row in first["items"] + second["items"]]
    assert seen == ["newest", "newer", "older", "oldest"]
    assert len(set(seen)) == 4


def test_only_the_owners_rows_and_an_owner_scoped_total():
    result = _client().list_user_activities(user_id=ALEX, limit=10)

    assert {row["user_id"] for row in result["items"]} == {ALEX}
    # The total drives "has more"; counting somebody else's rows would page
    # the client off the end of its own list.
    assert result["total"] == 4


def test_filters_still_narrow_the_ordered_set():
    result = _client().list_user_activities(user_id=ALEX, search="old", limit=10)

    assert [row["id"] for row in result["items"]] == ["older", "oldest"]
    assert result["total"] == 2
