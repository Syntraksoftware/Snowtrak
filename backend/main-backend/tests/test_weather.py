"""Tests for the weather snapshot API."""

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

        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


def test_weather_snapshot_integration_call_real_api():
    """Integration test: call Open-Meteo real API (no API key required).

    This will run during CI but relies on network access; it exercises the
    live provider since Open-Meteo is free to use.
    """
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