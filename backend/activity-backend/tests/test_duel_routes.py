"""Duel routes, through the app.

These exist because the unit tests did not catch a real bug: `_response`
took an optional `players` map, two handlers never passed one, and the
duels they returned had null names. Nothing failed -- a null name renders
as a blank. The route is the only layer where that is visible.
"""

from datetime import UTC, datetime, timedelta

import pytest

import services.duel_operations as duel_operations
from domain.competition.duel import Duel, DuelStatus
from domain.competition.metrics import Duration, Metric

# An hour ago, not a literal date: `accept_duel` only allows a PENDING invite
# whose `created_at` is inside `INVITE_TTL` (48h) of the real clock, so a
# fixed calendar date rots the moment the suite runs more than 48h later.
NOW = datetime.now(UTC) - timedelta(hours=1)


def _duel(status=DuelStatus.PENDING, **overrides) -> Duel:
    base = {
        "id": "duel-1",
        "challenger_id": "sam",
        "opponent_id": "user-1",
        "metric": Metric.VERTICAL,
        "duration": Duration.WEEK,
        "status": status,
        "created_at": NOW,
    }
    return Duel(**{**base, **overrides})


class _StubOperations:
    """Enough of DuelOperations to answer a route."""

    def __init__(self, duels, players):
        self._duels = duels
        self._players = players
        self.player_calls = 0

    def list_for(self, user_id, status=None, limit=20, offset=0):
        return self._duels

    def get(self, duel_id):
        return next((d for d in self._duels if d.id == duel_id), None)

    def players(self, duels):
        self.player_calls += 1
        return self._players

    def accept(self, duel, now=None):
        # A week-long window that just opened, not one that already ended --
        # an `ends_at` in the past would make `get_duel` settle this duel on
        # the spot the next time it is fetched.
        return _duel(status=DuelStatus.ACTIVE, starts_at=NOW, ends_at=NOW + timedelta(days=7))


@pytest.fixture
def stub(monkeypatch):
    def install(duels, players):
        operations = _StubOperations(duels, players)
        monkeypatch.setattr(duel_operations, "_operations", operations)
        return operations

    return install


NAMED = {
    "sam": {"display_name": "Sam Park", "avatar_url": None, "username": "sampark"},
    "user-1": {"display_name": "You", "avatar_url": None, "username": "you"},
}


def test_a_listed_duel_names_both_players(client, stub):
    stub([_duel()], NAMED)

    body = client.get("/api/v1/duels").json()

    assert body["items"][0]["challenger_name"] == "Sam Park"
    assert body["items"][0]["opponent_name"] == "You"


def test_a_page_of_duels_reads_profiles_once(client, stub):
    operations = stub([_duel(), _duel(id="duel-2")], NAMED)

    client.get("/api/v1/duels")

    assert operations.player_calls == 1


def test_a_player_with_no_profile_row_still_has_a_name(client, stub):
    # The row is created lazily, so a real player can have none. A blank
    # where the name goes is worse than a placeholder.
    stub([_duel()], {})

    body = client.get("/api/v1/duels").json()

    assert body["items"][0]["challenger_name"] == "Skier"
    assert body["items"][0]["opponent_name"] == "Skier"


def test_answering_a_duel_returns_it_named(client, stub):
    stub([_duel()], NAMED)

    body = client.post("/api/v1/duels/duel-1/accept").json()

    assert body["status"] == "active"
    assert body["challenger_name"] == "Sam Park"


def test_someone_elses_duel_is_not_found_rather_than_forbidden(client, stub):
    stub([_duel(challenger_id="a", opponent_id="b")], NAMED)

    assert client.get("/api/v1/duels/duel-1").status_code == 404
