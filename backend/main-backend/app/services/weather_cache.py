"""Redis-backed cache for weather snapshots."""

from __future__ import annotations

import logging
import math
from typing import Any, Protocol, cast

import redis
from pydantic import BaseModel, ConfigDict

from app.core.config import Settings, settings
from app.schemas.weather import WeatherSnapshotRequest, WeatherSnapshotResponse

logger = logging.getLogger(__name__)


class WeatherCache(Protocol):
    """Weather cache interface used by WeatherService."""

    def get(self, request: WeatherSnapshotRequest) -> WeatherSnapshotResponse | None:
        ...

    def set(self, request: WeatherSnapshotRequest, response: WeatherSnapshotResponse) -> None:
        ...

    def close(self) -> None:
        ...


class RedisWeatherCacheClient(Protocol):
    """Minimal Redis command surface used by RedisWeatherCache."""

    def get(self, name: str) -> str | None:
        ...

    def setex(self, name: str, time: int, value: str) -> Any:
        ...

    def delete(self, *names: str) -> Any:
        ...

    def close(self) -> Any:
        ...


class WeatherCacheEntry(BaseModel):
    """Serialized Redis cache value for one athlete weather snapshot."""

    model_config = ConfigDict(from_attributes=True)

    latitude: float
    longitude: float
    response: WeatherSnapshotResponse


class RedisWeatherCache:
    """Redis implementation of weather snapshot caching."""

    def __init__(
        self,
        *,
        enabled: bool,
        redis_url: str,
        namespace: str,
        ttl_seconds: int,
        distance_threshold: float,
        redis_client: RedisWeatherCacheClient | None = None,
    ) -> None:
        self._enabled = enabled
        self._redis_url = redis_url
        self._namespace = namespace
        self._ttl_seconds = ttl_seconds
        self._distance_threshold = distance_threshold
        self._redis_client: RedisWeatherCacheClient | None = redis_client

    @classmethod
    def from_settings(cls, app_settings: Settings = settings) -> "RedisWeatherCache":
        return cls(
            enabled=app_settings.weather_cache_enabled,
            redis_url=app_settings.weather_cache_redis_url,
            namespace=app_settings.weather_cache_namespace,
            ttl_seconds=app_settings.weather_cache_ttl_seconds,
            distance_threshold=app_settings.weather_cache_distance_threshold,
        )

    def get(self, request: WeatherSnapshotRequest) -> WeatherSnapshotResponse | None:
        if not self._is_usable():
            return None

        cache_key = self.cache_key(request.athlete_id)
        try:
            raw_entry = self._get_redis_client().get(cache_key)
        except Exception as exc:
            logger.warning("Weather cache read failed for athlete %s: %s", request.athlete_id, exc)
            return None

        if raw_entry is None:
            return None

        cached = self._deserialize_entry(cache_key, request.athlete_id, raw_entry)
        if cached is None:
            return None

        distance = self._euclidean_distance(
            request.location.latitude,
            request.location.longitude,
            cached.latitude,
            cached.longitude,
        )
        if distance > self._distance_threshold:
            return None

        return WeatherSnapshotResponse(
            activity_id=request.activity_id,
            athlete_id=request.athlete_id,
            source=cached.response.source,
            location=request.location,
            weather_snapshot=cached.response.weather_snapshot,
        )

    def set(self, request: WeatherSnapshotRequest, response: WeatherSnapshotResponse) -> None:
        if not self._is_usable():
            return

        entry = WeatherCacheEntry(
            latitude=request.location.latitude,
            longitude=request.location.longitude,
            response=response,
        )
        try:
            self._get_redis_client().setex(
                self.cache_key(request.athlete_id),
                max(1, int(self._ttl_seconds)),
                entry.model_dump_json(),
            )
        except Exception as exc:
            logger.warning("Weather cache write failed for athlete %s: %s", request.athlete_id, exc)

    def close(self) -> None:
        if self._redis_client is None:
            return

        try:
            self._redis_client.close()
        finally:
            self._redis_client = None

    def cache_key(self, athlete_id: int) -> str:
        return f"weather:{self._namespace}:athlete:{athlete_id}"

    def _is_usable(self) -> bool:
        return self._enabled and self._ttl_seconds > 0 and self._distance_threshold >= 0

    def _deserialize_entry(
        self,
        cache_key: str,
        athlete_id: int,
        raw_entry: str,
    ) -> WeatherCacheEntry | None:
        try:
            return WeatherCacheEntry.model_validate_json(raw_entry)
        except ValueError:
            logger.warning("Weather cache entry is invalid for athlete %s", athlete_id)
            try:
                self._get_redis_client().delete(cache_key)
            except redis.RedisError:
                pass
            return None

    def _get_redis_client(self) -> RedisWeatherCacheClient:
        client = self._redis_client
        if client is None:
            client = cast(
                RedisWeatherCacheClient,
                redis.from_url(
                    self._redis_url,
                    decode_responses=True,
                    socket_connect_timeout=1,
                    socket_timeout=1,
                ),
            )
            self._redis_client = client
        return client

    def _euclidean_distance(self, lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        return math.sqrt(((lat1 - lat2) ** 2) + ((lon1 - lon2) ** 2))
