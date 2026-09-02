"""Operations layer: the reads and writes around the competition rules.

The client is faked rather than mocked per call, so each test can assert on
the *shape* of what was sent -- which filters guard an update, how many round
trips a board page costs -- instead of on a call count.
"""

from datetime import UTC, datetime, timedelta

import pytest

from domain.competition.duel import Duel, DuelStatus
from domain.competition.metrics import Duration, Metric
from services.duel_operations import DuelInProgress, DuelOperations, NotEligible
from services.leaderboard_operations import GLOBAL_SCOPE, LeaderboardOperations

NOW = datetime(2026, 9, 2, 12, 0, tzinfo=UTC)
ALEX = "alex"
JORDAN = "jordan"


class _UniqueViolation(Exception):
    code = "23505"


class _Response:
    def __init__(self, data, count=None):
        self.data = data
        self.count = count


class _Query:
    """Records what was asked, answers from the store."""

    def __init__(self, store, table):
        self._store = store
        self.table = table
        self.op = "select"
        self.payload = None
        self.filters: list[tuple] = []

    def select(self, *_args, **_kwargs):
        return self

    def insert(self, payload):
        self.op, self.payload = "insert", payload
        return self

    def update(self, payload):
        self.op, self.payload = "update", payload
        return self

    def upsert(self, payload):
        self.op, self.payload = "upsert", payload
        return self

    def eq(self, column, value):
        self.filters.append(("eq", column, value))
        return self

    def is_(self, column, value):
        self.filters.append(("is", column, value))
        return self

    def in_(self, column, values):
        self.filters.append(("in", column, values))
        return self

    def or_(self, expression):
        self.filters.append(("or", expression, None))
        return self

    def lte(self, column, value):
        self.filters.append(("lte", column, value))
        return self

    def order(self, *_args, **_kwargs):
        return self

    def limit(self, *_args, **_kwargs):
        return self

    def range(self, *_args, **_kwargs):
        return self

    def execute(self):
        self._store.calls.append(self)
        if self.op == "insert" and self.table in self._store.insert_raises:
            raise self._store.insert_raises[self.table]
        if self.op == "insert":
            return _Response([{**self._store.insert_defaults, **self.payload}])
        if self.op in ("update", "upsert"):
            rows = self._store.rows.get(self.table, [])
            return _Response([{**row, **(self.payload or {})} for row in rows])
        return _Response(
            self._store.rows.get(self.table, []),
            self._store.count_for(self),
        )


class _Deferred:
    """supabase-py returns a builder from `rpc`; the call happens on
    `execute`."""

    def __init__(self, response):
        self._response = response

    def execute(self):
        return self._response


class _FakeClient:
    def __init__(self):
        self.rows: dict[str, list] = {}
        # Answers a count query from its filters, so the three counts behind
        # a W-L record can differ the way they do in Postgres.
        self.count_for = lambda _query: 0
        self.insert_raises: dict[str, Exception] = {}
        self.insert_defaults: dict = {}
        self.rpc_results: dict = {}
        self.calls: list[_Query] = []
        self.rpc_calls: list[tuple[str, dict]] = []

    def table(self, name):
        return _Query(self, name)

    def rpc(self, name, params):
        self.rpc_calls.append((name, params))
        return _Deferred(_Response(self.rpc_results.get(name, [])))

    def queries_on(self, table):
        return [call for call in self.calls if call.table == table]


def _mutual(client):
    client.rows["follows"] = [
        {"follower_id": ALEX, "followee_id": JORDAN},
        {"follower_id": JORDAN, "followee_id": ALEX},
    ]


def _pending_duel(**overrides) -> Duel:
    base = {
        "id": "duel-1",
        "challenger_id": ALEX,
        "opponent_id": JORDAN,
        "metric": Metric.VERTICAL,
        "duration": Duration.WEEK,
        "status": DuelStatus.PENDING,
        "created_at": NOW,
    }
    return Duel(**{**base, **overrides})


class TestEligibility:
    def test_a_one_directional_follow_is_not_a_friendship(self):
        client = _FakeClient()
        client.rows["follows"] = [{"follower_id": ALEX, "followee_id": JORDAN}]

        with pytest.raises(NotEligible):
            DuelOperations(client).create(ALEX, JORDAN, Metric.VERTICAL, Duration.WEEK)

    def test_a_failed_follow_read_refuses_the_challenge(self):
        # Fails closed. An unreadable graph is not permission to duel.
        client = _FakeClient()
        client.rows["follows"] = "not-a-list"

        with pytest.raises(NotEligible):
            DuelOperations(client).create(ALEX, JORDAN, Metric.VERTICAL, Duration.WEEK)

    def test_a_second_live_duel_is_a_conflict_not_a_crash(self):
        client = _FakeClient()
        _mutual(client)
        client.insert_raises["duels"] = _UniqueViolation()

        with pytest.raises(DuelInProgress):
            DuelOperations(client).create(ALEX, JORDAN, Metric.VERTICAL, Duration.WEEK)

    def test_a_challenge_starts_pending_with_no_window(self):
        client = _FakeClient()
        _mutual(client)
        client.insert_defaults = {"id": "duel-1", "created_at": NOW.isoformat()}

        duel = DuelOperations(client).create(ALEX, JORDAN, Metric.SPEED, Duration.TODAY)

        assert duel.status is DuelStatus.PENDING
        assert duel.starts_at is None and duel.ends_at is None


class TestTransitions:
    def test_accepting_is_conditional_on_still_being_pending(self):
        # Two taps, or two replicas, must not open two different windows.
        client = _FakeClient()
        client.rows["duels"] = [_row()]

        DuelOperations(client).accept(_pending_duel(), NOW)

        update = client.queries_on("duels")[-1]
        assert ("eq", "status", "pending") in update.filters
        assert update.payload["status"] == "active"
        assert update.payload["starts_at"] == NOW.isoformat()

    def test_settling_is_conditional_on_still_being_active(self):
        client = _FakeClient()
        client.rows["duels"] = [_row(status="active")]
        client.rpc_results["activity_total"] = 0

        duel = _pending_duel(
            status=DuelStatus.ACTIVE,
            starts_at=NOW,
            ends_at=NOW + timedelta(days=1),
        )
        DuelOperations(client).settle(duel)

        update = client.queries_on("duels")[-1]
        assert ("eq", "status", "active") in update.filters

    def test_two_equal_totals_settle_as_a_draw(self):
        client = _FakeClient()
        client.rows["duels"] = [_row(status="active")]
        # Both players read the same total, which is the case worth pinning:
        # a tie writes no winner rather than defaulting to the challenger.
        client.rpc_results["activity_total"] = 900.0

        duel = _pending_duel(
            status=DuelStatus.ACTIVE,
            starts_at=NOW,
            ends_at=NOW + timedelta(days=1),
        )
        DuelOperations(client).settle(duel)

        payload = client.queries_on("duels")[-1].payload
        assert payload["winner_id"] is None
        assert payload["challenger_value"] == payload["opponent_value"] == 900.0

    def test_a_duel_scores_every_activity_not_only_published_ones(self):
        # activity_total has no on_leaderboard filter, and must not grow one:
        # a private match should not require publishing anything.
        client = _FakeClient()
        client.rpc_results["activity_total"] = 12.5

        DuelOperations(client).score(ALEX, Metric.DISTANCE, NOW, NOW + timedelta(days=1))

        name, params = client.rpc_calls[-1]
        assert name == "activity_total"
        assert params["p_metric"] == "distance"


class TestRecord:
    def test_losses_are_what_is_left_after_wins_and_draws(self):
        # Losses are not counted, they are inferred. Ten finished, four won,
        # one drawn, so five lost.
        client = _FakeClient()

        def counts(query):
            columns = {column for _, column, _ in query.filters}
            if "winner_id" not in columns:
                return 10
            drawn = ("is", "winner_id", "null") in query.filters
            return 1 if drawn else 4

        client.count_for = counts

        record = DuelOperations(client).record(ALEX)

        assert (record["wins"], record["draws"], record["losses"]) == (4, 1, 5)

    def test_a_drawn_duel_reads_as_d_not_as_a_loss(self):
        client = _FakeClient()
        client.rows["duels"] = [
            {"winner_id": None, "settled_at": NOW.isoformat()},
            {"winner_id": ALEX, "settled_at": NOW.isoformat()},
            {"winner_id": JORDAN, "settled_at": NOW.isoformat()},
        ]

        assert DuelOperations(client).record(ALEX)["recent"] == ["D", "W", "L"]


class TestLeaderboard:
    def test_a_board_page_costs_one_name_query_not_one_per_row(self):
        client = _FakeClient()
        client.rpc_results["leaderboard_top"] = [
            {"rank": index, "user_id": f"user-{index}", "value": 100.0 - index}
            for index in range(1, 26)
        ]
        client.rows["user_info"] = []

        entries = LeaderboardOperations(client).top(Metric.VERTICAL, GLOBAL_SCOPE, NOW)

        assert len(entries) == 25
        assert len(client.queries_on("user_info")) == 1
        # `profiles` is empty in this database and always will be; reading it
        # would name every skier "Skier".
        assert client.queries_on("profiles") == []

    def test_a_board_row_names_a_user_from_user_info(self):
        client = _FakeClient()
        client.rpc_results["leaderboard_top"] = [{"rank": 1, "user_id": ALEX, "value": 900.0}]
        client.rows["user_info"] = [
            {
                "id": ALEX,
                "first_name": "Alpha",
                "last_name": "Tester",
                "email": "alpha@example.com",
                "country_code": "CH",
            }
        ]

        entry = LeaderboardOperations(client).top(Metric.VERTICAL, GLOBAL_SCOPE, NOW)[0]

        assert entry["display_name"] == "Alpha Tester"
        assert entry["country_code"] == "CH"

    def test_a_nameless_user_falls_back_to_their_email_handle(self):
        client = _FakeClient()
        client.rpc_results["leaderboard_top"] = [{"rank": 1, "user_id": ALEX, "value": 900.0}]
        client.rows["user_info"] = [{"id": ALEX, "email": "skier@example.com"}]

        entry = LeaderboardOperations(client).top(Metric.VERTICAL, GLOBAL_SCOPE, NOW)[0]

        assert entry["display_name"] == "skier"

    def test_the_board_window_is_the_monday_of_that_week(self):
        client = _FakeClient()
        LeaderboardOperations(client).top(Metric.SPEED, GLOBAL_SCOPE, NOW)

        _, params = client.rpc_calls[-1]
        assert params["p_start"].startswith("2026-08-31")
        assert params["p_end"].startswith("2026-09-07")

    def test_a_snapshot_carries_the_keys_it_is_upserted_on(self):
        client = _FakeClient()
        client.rpc_results["leaderboard_top"] = [{"rank": 1, "user_id": ALEX, "value": 900.0}]
        client.rpc_results["leaderboard_scopes"] = []

        LeaderboardOperations(client).settle_week(NOW)

        upsert = client.queries_on("leaderboard_weeks")[0]
        assert upsert.op == "upsert"
        assert upsert.payload[0]["week_start"] == "2026-08-31"
        assert {"week_start", "metric", "scope", "rank"} <= set(upsert.payload[0])


def _row(status="pending"):
    return {
        "id": "duel-1",
        "challenger_id": ALEX,
        "opponent_id": JORDAN,
        "metric": "vertical",
        "duration": "week",
        "status": status,
        "created_at": NOW.isoformat(),
    }


class TestScopes:
    def test_a_friends_board_is_relative_to_whoever_is_asking(self):
        # Without the viewer the SQL cannot resolve "friends" at all, and a
        # board that silently fell back to global would show strangers a
        # Challenge button they cannot use.
        client = _FakeClient()

        LeaderboardOperations(client).top(Metric.VERTICAL, "friends", NOW, 50, viewer_id=ALEX)

        _, params = client.rpc_calls[-1]
        assert params["p_scope"] == "friends"
        assert params["p_viewer"] == ALEX

    def test_a_friends_board_is_never_snapshotted(self):
        # It is a different board per viewer, so there is no single week to
        # write down.
        client = _FakeClient()
        client.rpc_results["leaderboard_top"] = [{"rank": 1, "user_id": ALEX, "value": 900.0}]
        client.rpc_results["leaderboard_scopes"] = [{"scope": "CH"}]

        LeaderboardOperations(client).settle_week(NOW)

        scopes = {
            params["p_scope"] for name, params in client.rpc_calls if name == "leaderboard_top"
        }
        assert scopes == {GLOBAL_SCOPE, "CH"}
