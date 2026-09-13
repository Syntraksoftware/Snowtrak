"""`activities.max_pace` is what the speed leaderboard ranks on.

Nothing wrote the column before #48, so the board was empty for everyone in
every scope. These tests cover the two things that made wiring it up more
than plumbing: which sample counts as the top speed, and what an activity
with no reading has to write instead of a number.
"""

from domain.pace import pace_from_speed_kmh, top_speed_kmh_from_samples
from routes.activity_transformers import compute_metrics_from_locations
from services.supabase_client import ActivitySupabaseClient


def _point(latitude: float, speed: float | None) -> dict:
    return {"latitude": latitude, "longitude": 6.86, "altitude": 2000.0, "speed": speed}


class TestPaceFromSpeed:
    def test_converts_kmh_to_seconds_per_km(self):
        # 60 km/h is a kilometre a minute.
        assert pace_from_speed_kmh(60.0) == 60.0
        assert pace_from_speed_kmh(120.0) == 30.0

    def test_no_reading_stays_no_reading(self):
        # Writing 0 would be a claim that a measurement was taken, and the
        # SQL reads it back as missing anyway -- but a 0 written on purpose
        # is indistinguishable from the column default, so return None and
        # let the caller omit the field.
        assert pace_from_speed_kmh(0) is None
        assert pace_from_speed_kmh(None) is None
        assert pace_from_speed_kmh(-1.0) is None


class TestTopSpeedFromSamples:
    def test_a_single_dropout_does_not_set_the_top_speed(self):
        # One 400 km/h fix in an otherwise ordinary run. A raw max would put
        # this skier at the top of the board for the week.
        samples = [10.0] * 99 + [111.0]

        top_speed = top_speed_kmh_from_samples(samples)

        assert top_speed is not None and top_speed < 40.0

    def test_reads_the_fast_part_of_the_run_not_the_average(self):
        # Half the track at 5 m/s, half at 20 m/s: the top speed is the fast
        # half, not the mean of the two.
        samples = [5.0] * 50 + [20.0] * 50

        assert top_speed_kmh_from_samples(samples) == 72.0

    def test_ignores_missing_and_stationary_samples(self):
        assert top_speed_kmh_from_samples([None, 0.0, -3.0, 10.0]) == 36.0

    def test_nothing_recorded_is_none_not_zero(self):
        assert top_speed_kmh_from_samples([]) is None
        assert top_speed_kmh_from_samples([None, 0.0]) is None

    def test_order_does_not_matter(self):
        rising = [float(speed) for speed in range(1, 101)]

        assert top_speed_kmh_from_samples(rising) == top_speed_kmh_from_samples(rising[::-1])


class TestComputeMetricsFromLocations:
    def test_the_create_path_produces_a_pace_the_board_can_rank(self):
        locations = [_point(45.9 + index / 10000, 20.0) for index in range(100)]

        metrics = compute_metrics_from_locations(locations)

        # 20 m/s is 72 km/h is 50 s/km.
        assert metrics["max_pace"] == 50.0

    def test_a_track_without_speeds_writes_no_pace(self):
        locations = [_point(45.9 + index / 10000, None) for index in range(10)]

        assert compute_metrics_from_locations(locations)["max_pace"] is None

    def test_distance_and_elevation_are_unchanged(self):
        locations = [
            {"latitude": 45.9, "longitude": 6.86, "altitude": 2000.0, "speed": 10.0},
            {"latitude": 45.9, "longitude": 6.86, "altitude": 2100.0, "speed": 10.0},
        ]

        metrics = compute_metrics_from_locations(locations)

        assert metrics["distance_meters"] == 0.0
        assert metrics["elevation_gain_meters"] == 100.0


class _Table:
    """Records what would reach Postgres, and nothing else."""

    def __init__(self, log: dict):
        self._log = log

    def insert(self, payload):
        self._log["insert"] = payload
        return self

    def update(self, payload):
        self._log["update"] = payload
        return self

    def eq(self, _column, _value):
        return self

    def execute(self):
        return type("Response", (), {"data": [{"id": "activity-1"}]})()


class _FakeSupabase:
    def __init__(self):
        self.log: dict = {}

    def table(self, _name):
        return _Table(self.log)


class TestTheColumnActuallyGetsWritten:
    """#48 was four readers and no writer; these are the two writers."""

    def test_create_puts_the_pace_in_the_insert(self):
        supabase = _FakeSupabase()
        ActivitySupabaseClient(supabase).create_activity(
            user_id="user-1",
            name="Morning Run",
            start_time="2026-01-01T00:00:00Z",
            end_time="2026-01-01T00:10:00Z",
            activity_type="alpine",
            gps_path=[],
            duration_seconds=600,
            distance_meters=1200.0,
            elevation_gain_meters=100.0,
            max_pace=50.0,
        )

        assert supabase.log["insert"]["max_pace"] == 50.0

    def test_create_omits_the_column_when_there_is_no_reading(self):
        supabase = _FakeSupabase()
        ActivitySupabaseClient(supabase).create_activity(
            user_id="user-1",
            name="Morning Run",
            start_time="2026-01-01T00:00:00Z",
            end_time="2026-01-01T00:10:00Z",
            activity_type="alpine",
            gps_path=[],
            duration_seconds=600,
            distance_meters=1200.0,
            elevation_gain_meters=100.0,
        )

        assert "max_pace" not in supabase.log["insert"]

    def test_the_pipeline_write_back_carries_it(self):
        supabase = _FakeSupabase()
        ActivitySupabaseClient(supabase).update_activity_pipeline_fields(
            "activity-1",
            "user-1",
            max_pace=50.0,
        )

        assert supabase.log["update"]["max_pace"] == 50.0
