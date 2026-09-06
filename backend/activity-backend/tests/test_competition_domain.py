"""Rules for scoring, windows and duel state.

These construct values and call functions. No client, no fixture, no
network -- which is the point of keeping the rules in `domain/`.
"""

from datetime import UTC, datetime, timedelta

import pytest

from domain.competition.duel import (
    INVITE_TTL,
    Duel,
    DuelStatus,
    can_transition,
    resolve_winner,
)
from domain.competition.metrics import (
    METRIC_COLUMNS,
    Duration,
    Metric,
    duel_window,
    score,
    week_bounds,
)

# A Wednesday, so weekday arithmetic has somewhere to go in both directions.
WEDNESDAY = datetime(2026, 9, 2, 14, 30, tzinfo=UTC)


def _duel(**overrides) -> Duel:
    base = {
        "id": "duel-1",
        "challenger_id": "alex",
        "opponent_id": "jordan",
        "metric": Metric.VERTICAL,
        "duration": Duration.WEEK,
        "status": DuelStatus.PENDING,
        "created_at": WEDNESDAY,
    }
    return Duel(**{**base, **overrides})


class TestScore:
    def test_a_zero_pace_is_no_reading_not_infinite_speed(self):
        # max_pace defaults to 0 in the schema. Treating that as the fastest
        # run puts everyone who never recorded a speed at the top of the
        # board.
        assert score(Metric.SPEED, [0, 0, 0]) == 0.0

    def test_top_speed_takes_the_smallest_positive_pace(self):
        # 60 s/km is 60 km/h; 120 s/km is 30. Faster is the smaller pace.
        assert score(Metric.SPEED, [120.0, 60.0, 0, None]) == pytest.approx(60.0)

    def test_summed_metrics_ignore_missing_readings(self):
        assert score(Metric.VERTICAL, [100.0, None, 250.5]) == pytest.approx(350.5)

    def test_an_empty_window_scores_zero_for_every_metric(self):
        assert all(score(metric, []) == 0.0 for metric in Metric)

    def test_every_metric_names_a_column(self):
        assert set(METRIC_COLUMNS) == set(Metric)


class TestWindows:
    def test_week_bounds_are_half_open_so_no_activity_lands_in_two_weeks(self):
        start, end = week_bounds(WEDNESDAY)
        next_start, _ = week_bounds(end)
        assert end == next_start
        assert start.weekday() == 0 and start.hour == 0

    def test_today_ends_at_the_next_midnight_and_starts_now(self):
        start, end = duel_window(Duration.TODAY, WEDNESDAY)
        assert start == WEDNESDAY
        assert end == datetime(2026, 9, 3, tzinfo=UTC)

    def test_a_weekend_accepted_midweek_still_opens_on_friday(self):
        # Otherwise "This Weekend" would quietly count Wednesday.
        start, end = duel_window(Duration.WEEKEND, WEDNESDAY)
        assert start == datetime(2026, 9, 4, tzinfo=UTC)
        assert end == datetime(2026, 9, 7, tzinfo=UTC)

    def test_a_weekend_accepted_on_saturday_opens_then_not_in_the_past(self):
        saturday = datetime(2026, 9, 5, 9, 0, tzinfo=UTC)
        start, _ = duel_window(Duration.WEEKEND, saturday)
        assert start == saturday

    def test_a_week_runs_seven_days_from_acceptance(self):
        start, end = duel_window(Duration.WEEK, WEDNESDAY)
        assert (start, end) == (WEDNESDAY, WEDNESDAY + timedelta(days=7))


class TestDuelState:
    def test_a_declined_duel_is_terminal(self):
        assert not can_transition(DuelStatus.DECLINED, DuelStatus.ACTIVE)
        assert not can_transition(DuelStatus.FINISHED, DuelStatus.ACTIVE)

    def test_only_the_challenged_player_may_accept(self):
        duel = _duel()
        assert duel.may_accept("jordan", WEDNESDAY)
        assert not duel.may_accept("alex", WEDNESDAY)
        assert not duel.may_accept("stranger", WEDNESDAY)

    def test_only_the_challenger_may_withdraw(self):
        duel = _duel()
        assert duel.may_cancel("alex")
        assert not duel.may_cancel("jordan")

    def test_a_lapsed_invitation_cannot_be_accepted(self):
        duel = _duel()
        assert not duel.may_accept("jordan", WEDNESDAY + INVITE_TTL)
        assert duel.is_expired_at(WEDNESDAY + INVITE_TTL)

    def test_an_active_duel_is_decidable_only_once_the_window_closes(self):
        duel = _duel(
            status=DuelStatus.ACTIVE,
            starts_at=WEDNESDAY,
            ends_at=WEDNESDAY + timedelta(days=7),
        )
        assert not duel.is_decidable_at(WEDNESDAY + timedelta(days=6))
        assert duel.is_decidable_at(WEDNESDAY + timedelta(days=7))

    def test_from_row_rejects_a_metric_this_version_cannot_score(self):
        # A duel written by a newer deploy must not be settled by an older
        # one guessing at the rule.
        with pytest.raises(ValueError):
            Duel.from_row(
                {
                    "id": "d",
                    "challenger_id": "alex",
                    "opponent_id": "jordan",
                    "metric": "most_runs",
                    "duration": "week",
                    "status": "active",
                    "created_at": WEDNESDAY.isoformat(),
                }
            )


class TestWinner:
    def test_the_higher_score_wins_for_every_metric(self):
        duel = _duel()
        assert resolve_winner(duel, 900.0, 120.0) == "alex"
        assert resolve_winner(duel, 120.0, 900.0) == "jordan"

    def test_two_players_who_recorded_nothing_draw(self):
        # Not a loss for both: a draw writes no winner and no W and no L.
        assert resolve_winner(_duel(), 0.0, 0.0) is None
