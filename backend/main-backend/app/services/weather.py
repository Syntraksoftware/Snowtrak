"""Weather snapshot service backed by Open-Meteo (free, no API key)."""

from __future__ import annotations

import logging
from datetime import UTC, datetime
from typing import Any

import httpx

from app.core.config import settings
from app.schemas.weather import (
    WeatherLocation,
    WeatherSnapshot,
    WeatherSnapshotAtmosphere,
    WeatherSnapshotPrecipitation,
    WeatherSnapshotRequest,
    WeatherSnapshotResponse,
    WeatherSnapshotTemperatures,
    WeatherSnapshotWind,
)
from app.services.weather_cache import RedisWeatherCache, WeatherCache

logger = logging.getLogger(__name__)


class WeatherServiceError(RuntimeError):
    """Raised when the weather provider cannot satisfy a request."""


class WeatherService:
    """Builds a normalized weather snapshot from Open-Meteo data."""

    def __init__(self, weather_cache: WeatherCache | None = None) -> None:
        self._base_url = settings.open_meteo_base_url.rstrip("/")
        self._timeout_seconds = settings.open_meteo_timeout_seconds
        self._weather_cache = weather_cache or RedisWeatherCache.from_settings()

    def build_snapshot(self, request: WeatherSnapshotRequest) -> WeatherSnapshotResponse:
        cached_response = self._weather_cache.get(request)
        if cached_response is not None:
            return cached_response

        provider_data = self._fetch_provider_data(request.location.latitude, request.location.longitude)
        location = self._build_location(request.location, provider_data)
        snapshot = self._build_snapshot(request, provider_data)

        response = WeatherSnapshotResponse(
            activity_id=request.activity_id,
            athlete_id=request.athlete_id,
            source="Open-Meteo",
            location=location,
            weather_snapshot=snapshot,
        )
        self._weather_cache.set(request, response)
        return response

    def close(self) -> None:
        self._weather_cache.close()

    def _fetch_provider_data(self, latitude: float, longitude: float) -> dict[str, Any]:
        url = f"{self._base_url}/forecast"
        params = {
            "latitude": latitude,
            "longitude": longitude,
            "hourly": ",".join(
                [
                    "temperature_2m",
                    "relative_humidity_2m",
                    "apparent_temperature",
                    "precipitation_probability",
                    "precipitation",
                    "rain",
                    "showers",
                    "snowfall",
                    "snow_depth",
                    "weather_code",
                    "pressure_msl",
                    "visibility",
                    "wind_speed_10m",
                    "wind_direction_10m",
                    "wind_gusts_10m",
                    "uv_index",
                ]
            ),
            "current_weather": "true",
            "timezone": "UTC",
        }

        try:
            response = httpx.get(url, params=params, timeout=self._timeout_seconds)
            response.raise_for_status()
            payload = response.json()
        except httpx.HTTPStatusError as exc:
            logger.exception("Open-Meteo returned an error response")
            raise WeatherServiceError("Weather provider rejected the request") from exc
        except httpx.HTTPError as exc:
            logger.exception("Open-Meteo request failed")
            raise WeatherServiceError("Weather provider is unavailable") from exc

        if not isinstance(payload, dict):
            raise WeatherServiceError("Unexpected weather provider response")

        return payload

    def _build_location(
        self,
        request_location: WeatherLocation,
        provider_data: dict[str, Any],
    ) -> WeatherLocation:
        return request_location

    def _build_snapshot(
        self,
        request: WeatherSnapshotRequest,
        provider_data: dict[str, Any],
    ) -> WeatherSnapshot:
        current = provider_data.get("current_weather")
        if not isinstance(current, dict):
            raise WeatherServiceError("Weather provider response is missing current conditions")

        hourly = provider_data.get("hourly")
        if not isinstance(hourly, dict):
            raise WeatherServiceError("Weather provider response is missing hourly conditions")

        hour_index = self._select_hour_index(hourly, current)

        weather_code = self._hourly_int(hourly, "weather_code", hour_index, default=self._as_int(current.get("weathercode")))
        condition_text = self._weathercode_to_text(weather_code)
        current_time = self._as_str(current.get("time"))
        timestamp = self._epoch_or_iso_to_utc(current_time)

        current_temp = self._hourly_float(hourly, "temperature_2m", hour_index, default=self._as_float(current.get("temperature")))
        feels_like = self._hourly_float(hourly, "apparent_temperature", hour_index, default=current_temp)
        humidity = self._hourly_int(hourly, "relative_humidity_2m", hour_index, default=0)
        pressure = self._hourly_float(hourly, "pressure_msl", hour_index, default=0.0)
        uv_index = self._hourly_float(hourly, "uv_index", hour_index, default=0.0)
        wind_speed_kmh = self._hourly_float(hourly, "wind_speed_10m", hour_index, default=self._as_float(current.get("windspeed")))
        wind_direction = self._hourly_int(hourly, "wind_direction_10m", hour_index, default=self._as_int(current.get("winddirection")))
        gust_speed_kmh = self._hourly_float(hourly, "wind_gusts_10m", hour_index, default=0.0)
        precipitation_probability = self._hourly_int(hourly, "precipitation_probability", hour_index, default=0)
        precipitation_amount = self._hourly_float(hourly, "precipitation", hour_index, default=0.0)
        snowfall_amount = self._hourly_float(hourly, "snowfall", hour_index, default=0.0)

        precipitation_type = self._classify_precipitation(
            condition_text=condition_text,
            weather_code=weather_code,
            precipitation_amount=precipitation_amount,
            snowfall_amount=snowfall_amount,
        )

        return WeatherSnapshot(
            timestamp=timestamp,
            condition=condition_text,
            condition_code=str(weather_code),
            icon_url="",
            temperatures=WeatherSnapshotTemperatures(
                ambient_celsius=current_temp,
                feels_like_celsius=feels_like,
                strava_reported_celsius=request.strava_reported_celsius,
            ),
            atmosphere=WeatherSnapshotAtmosphere(
                humidity_percent=humidity,
                pressure_hpa=pressure,
                uv_index=uv_index,
            ),
            wind=WeatherSnapshotWind(
                speed_meters_per_second=self._kmh_to_ms(wind_speed_kmh),
                bearing_degrees=wind_direction,
                cardinal_direction=self._degrees_to_cardinal(wind_direction),
                gust_meters_per_second=self._kmh_to_ms(gust_speed_kmh) if gust_speed_kmh else None,
            ),
            precipitation=WeatherSnapshotPrecipitation(
                probability_percent=precipitation_probability,
                type=precipitation_type,
            ),
        )

    def _select_hour_index(self, hourly: dict[str, Any], current: dict[str, Any]) -> int:
        times = hourly.get("time")
        if not isinstance(times, list) or not times:
            return 0

        current_time = self._as_str(current.get("time"))
        if not current_time:
            return 0

        if current_time in times:
            return times.index(current_time)

        try:
            current_dt = datetime.fromisoformat(current_time.replace("Z", "+00:00"))
            parsed = [datetime.fromisoformat(self._as_str(value).replace("Z", "+00:00")) for value in times]
            return min(range(len(parsed)), key=lambda idx: abs((parsed[idx] - current_dt).total_seconds()))
        except Exception:
            return 0

    def _hourly_value(self, hourly: dict[str, Any], key: str, index: int) -> Any:
        values = hourly.get(key)
        if isinstance(values, list) and 0 <= index < len(values):
            return values[index]
        return None

    def _hourly_int(self, hourly: dict[str, Any], key: str, index: int, default: int = 0) -> int:
        value = self._hourly_value(hourly, key, index)
        return self._as_int(value) if value is not None else default

    def _hourly_float(self, hourly: dict[str, Any], key: str, index: int, default: float = 0.0) -> float:
        value = self._hourly_value(hourly, key, index)
        return self._as_float(value) if value is not None else default

    def _classify_precipitation(
        self,
        *,
        condition_text: str,
        weather_code: int,
        precipitation_amount: float,
        snowfall_amount: float,
    ) -> str:
        text = condition_text.lower()
        if snowfall_amount > 0 or any(token in text for token in ("snow", "sleet", "ice")):
            return "snow"
        if precipitation_amount > 0 or any(token in text for token in ("rain", "drizzle", "shower")):
            return "rain"
        if weather_code in {51, 53, 55, 56, 57, 61, 63, 65, 80, 81, 82}:
            return "rain"
        if weather_code in {71, 73, 75, 77, 85, 86}:
            return "snow"
        return "none"

    def _weathercode_to_text(self, code: int) -> str:
        mapping = {
            0: "Clear",
            1: "Mainly clear",
            2: "Partly cloudy",
            3: "Overcast",
            45: "Fog",
            48: "Depositing rime fog",
            51: "Light drizzle",
            53: "Moderate drizzle",
            55: "Dense drizzle",
            56: "Light freezing drizzle",
            57: "Dense freezing drizzle",
            61: "Slight rain",
            63: "Moderate rain",
            65: "Heavy rain",
            66: "Light freezing rain",
            67: "Heavy freezing rain",
            71: "Slight snow",
            73: "Moderate snow",
            75: "Heavy snow",
            77: "Snow grains",
            80: "Slight rain showers",
            81: "Moderate rain showers",
            82: "Violent rain showers",
            85: "Slight snow showers",
            86: "Heavy snow showers",
            95: "Thunderstorm",
            96: "Thunderstorm with slight hail",
            99: "Thunderstorm with heavy hail",
        }
        return mapping.get(code, "Unknown")

    def _degrees_to_cardinal(self, degrees: int) -> str:
        directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        if degrees < 0:
            degrees = 0
        index = int((degrees + 11.25) / 22.5) % 16
        return directions[index]

    def _kmh_to_ms(self, value: float) -> float:
        return round(value / 3.6, 1)

    def _epoch_or_iso_to_utc(self, value: str) -> str:
        if not value:
            return datetime.now(tz=UTC).isoformat().replace("+00:00", "Z")
        try:
            if value.isdigit():
                return datetime.fromtimestamp(int(value), tz=UTC).isoformat().replace("+00:00", "Z")
            dt = datetime.fromisoformat(value.replace("Z", "+00:00"))
            return dt.astimezone(UTC).isoformat().replace("+00:00", "Z")
        except Exception:
            return datetime.now(tz=UTC).isoformat().replace("+00:00", "Z")

    def _as_str(self, value: Any) -> str:
        if isinstance(value, str):
            return value
        if value is None:
            return ""
        return str(value)

    def _as_int(self, value: Any) -> int:
        if isinstance(value, bool):
            return int(value)
        if isinstance(value, int):
            return value
        if isinstance(value, float):
            return int(round(value))
        if isinstance(value, str) and value.strip():
            try:
                return int(float(value))
            except ValueError:
                return 0
        return 0

    def _as_float(self, value: Any) -> float:
        if isinstance(value, bool):
            return float(int(value))
        if isinstance(value, (int, float)):
            return float(value)
        if isinstance(value, str) and value.strip():
            try:
                return float(value)
            except ValueError:
                return 0.0
        return 0.0


weather_service = WeatherService()
