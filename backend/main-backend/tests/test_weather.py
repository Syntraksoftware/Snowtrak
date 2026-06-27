"""Tests for the weather snapshot API."""

import os
from typing import Any

import pytest
from fastapi import status


class TestWeatherSnapshotEndpoint:
    """Weather API contract tests."""

    def test_weather_snapshot_success(self, client, monkeypatch):
        from app.api.v1 import weather as weather_module
        from app.schemas.weather import (
            WeatherLocation,
            WeatherSnapshot,
            WeatherSnapshotAtmosphere,
            WeatherSnapshotPrecipitation,
            WeatherSnapshotResponse,
            WeatherSnapshotTemperatures,
            WeatherSnapshotWind,
        )

        class FakeWeatherService:
            def build_snapshot(self, request):
                return WeatherSnapshotResponse(
                    activity_id=request.activity_id,
                    athlete_id=request.athlete_id,
                    source="Open-Meteo",
                    location=WeatherLocation(
                        latitude=request.location.latitude,
                        longitude=request.location.longitude,
                        city_hint=request.location.city_hint or "Coventry, UK",
                    ),
                    weather_snapshot=WeatherSnapshot(
                        timestamp="2026-06-09T06:30:00Z",
                        condition="Partly cloudy",
                        condition_code="2",
                        icon_url="https://cdn.weatherapi.com/weather/64x64/day/116.png",
                        temperatures=WeatherSnapshotTemperatures(
                            ambient_celsius=16.0,
                            feels_like_celsius=15.4,
                            strava_reported_celsius=16,
                        ),
                        atmosphere=WeatherSnapshotAtmosphere(
                            humidity_percent=68,
                            pressure_hpa=1014,
                            uv_index=3.2,
                        ),
                        wind=WeatherSnapshotWind(
                            speed_meters_per_second=4.1,
                            bearing_degrees=210,
                            cardinal_direction="SSW",
                            gust_meters_per_second=6.5,
                        ),
                        precipitation=WeatherSnapshotPrecipitation(
                            probability_percent=10,
                            type="none",
                        ),
                    ),
                )

        monkeypatch.setattr(weather_module, "weather_service", FakeWeatherService())

        response = client.post(
            "/api/v1/weather/snapshot",
            json={
                "activity_id": 8529483012,
                "athlete_id": 1234567,
                "location": {
                    "latitude": 52.4068,
                    "longitude": -1.5197,
                    "city_hint": "Coventry, UK",
                },
                "strava_reported_celsius": 16,
            },
        )

        assert response.status_code == status.HTTP_200_OK
        payload = response.json()
        assert payload["activity_id"] == 8529483012
        assert payload["athlete_id"] == 1234567
        assert payload["source"] == "Open-Meteo"
        assert payload["location"]["city_hint"] == "Coventry, UK"
        assert payload["weather_snapshot"]["temperatures"]["ambient_celsius"] == 16.0
        assert payload["weather_snapshot"]["atmosphere"]["uv_index"] == 3.2

    def test_weather_snapshot_validation_error(self, client):
        response = client.post(
            "/api/v1/weather/snapshot",
            json={
                "activity_id": 8529483012,
                "location": {
                    "latitude": 52.4068,
                    "longitude": -1.5197,
                },
            },
        )

        assert response.status_code == 422


@pytest.mark.skipif(
    not os.getenv("RUN_INTEGRATION_TESTS"),
    reason="set RUN_INTEGRATION_TESTS=1 to run live provider tests",
)
def test_weather_snapshot_integration_call_real_api():
    """Integration test: call Open-Meteo real API (no API key required)."""
    from app.services.weather import weather_service
    from app.schemas.weather import WeatherLocation, WeatherSnapshotRequest

    req = WeatherSnapshotRequest(
        activity_id=1,
        athlete_id=1,
        location=WeatherLocation(latitude=52.4068, longitude=-1.5197),
    )

    resp = weather_service.build_snapshot(req)
    print(resp.model_dump_json(indent=2))
    assert resp.source == "Open-Meteo"
    assert resp.location.latitude == 52.4068
    assert isinstance(resp.weather_snapshot.condition, str) and resp.weather_snapshot.condition


def _provider_payload() -> dict:
    return {
        "current_weather": {
            "time": "2026-06-10T10:00",
            "temperature": 16.3,
            "weathercode": 2,
            "windspeed": 12.0,
            "winddirection": 210,
        },
        "hourly": {
            "time": ["2026-06-10T10:00"],
            "temperature_2m": [16.3],
            "relative_humidity_2m": [68],
            "apparent_temperature": [15.9],
            "precipitation_probability": [12],
            "precipitation": [0.0],
            "rain": [0.0],
            "showers": [0.0],
            "snowfall": [0.0],
            "snow_depth": [0.0],
            "weather_code": [2],
            "pressure_msl": [1014.0],
            "visibility": [10000.0],
            "wind_speed_10m": [12.0],
            "wind_direction_10m": [210],
            "wind_gusts_10m": [18.0],
            "uv_index": [3.2],
        },
    }


class FakeRedis:
    def __init__(self) -> None:
        self.values: dict[str, str] = {}
        self.ttls: dict[str, int] = {}

    def get(self, name: str) -> str | None:
        return self.values.get(name)

    def setex(self, name: str, time: int, value: str) -> Any:
        self.values[name] = value
        self.ttls[name] = time

    def delete(self, *names: str) -> Any:
        for name in names:
            self.values.pop(name, None)
            self.ttls.pop(name, None)

    def close(self) -> Any:
        return None


def test_weather_service_uses_cache_for_same_athlete_nearby_location(monkeypatch):
    from app.schemas.weather import WeatherLocation, WeatherSnapshotRequest
    from app.services.weather_cache import RedisWeatherCache
    from app.services.weather import WeatherService

    fake_redis = FakeRedis()
    weather_cache = RedisWeatherCache(
        enabled=True,
        redis_url="redis://localhost:6379/0",
        namespace="main-backend",
        ttl_seconds=600,
        distance_threshold=0.02,
        redis_client=fake_redis,
    )
    service = WeatherService(weather_cache=weather_cache)

    call_count = {"fetch": 0}

    def fake_fetch(_lat, _lon):
        call_count["fetch"] += 1
        return _provider_payload()

    monkeypatch.setattr(service, "_fetch_provider_data", fake_fetch)

    req1 = WeatherSnapshotRequest(
        activity_id=101,
        athlete_id=555,
        location=WeatherLocation(latitude=52.4068, longitude=-1.5197),
    )
    req2 = WeatherSnapshotRequest(
        activity_id=102,
        athlete_id=555,
        location=WeatherLocation(latitude=52.4070, longitude=-1.5195),
    )

    resp1 = service.build_snapshot(req1)
    resp2 = service.build_snapshot(req2)

    assert call_count["fetch"] == 1
    assert resp1.weather_snapshot == resp2.weather_snapshot
    assert resp2.activity_id == 102
    assert resp2.athlete_id == 555
    assert fake_redis.ttls[weather_cache.cache_key(555)] == 600


def test_weather_service_refreshes_cache_for_far_location(monkeypatch):
    from app.schemas.weather import WeatherLocation, WeatherSnapshotRequest
    from app.services.weather_cache import RedisWeatherCache
    from app.services.weather import WeatherService

    fake_redis = FakeRedis()
    weather_cache = RedisWeatherCache(
        enabled=True,
        redis_url="redis://localhost:6379/0",
        namespace="main-backend",
        ttl_seconds=600,
        distance_threshold=0.02,
        redis_client=fake_redis,
    )
    service = WeatherService(weather_cache=weather_cache)

    call_count = {"fetch": 0}

    def fake_fetch(_lat, _lon):
        call_count["fetch"] += 1
        return _provider_payload()

    monkeypatch.setattr(service, "_fetch_provider_data", fake_fetch)

    req1 = WeatherSnapshotRequest(
        activity_id=201,
        athlete_id=777,
        location=WeatherLocation(latitude=52.4068, longitude=-1.5197),
    )
    req2 = WeatherSnapshotRequest(
        activity_id=202,
        athlete_id=777,
        location=WeatherLocation(latitude=52.4500, longitude=-1.4500),
    )

    service.build_snapshot(req1)
    service.build_snapshot(req2)

    assert call_count["fetch"] == 2
