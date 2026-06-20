"""Server-side pipeline orchestrator (mirror of Flutter TrackPipelineCoordinator)."""

from __future__ import annotations

import logging
from datetime import datetime
from typing import Any
from uuid import uuid4

from config import get_config
from services.gpx_parser import parse_gpx_bytes
from services.map_backend_client import MapBackendClient, get_map_backend_client
from services.nivus_client import NivusClient, get_nivus_client
from services.supabase_client import ActivitySupabaseClient
from shared.pipeline_enums import ProcessingStatus

logger = logging.getLogger(__name__)

_ELEVATION_CHUNK = 500


class PipelineProcessor:
    """Coordinates map-backend + Nivus without coupling those services."""

    def __init__(
        self,
        *,
        activity_client: ActivitySupabaseClient,
        map_client: MapBackendClient | None = None,
        nivus_client: NivusClient | None = None,
    ) -> None:
        self._activity_client = activity_client
        self._map_client = map_client or get_map_backend_client()
        self._nivus_client = nivus_client or get_nivus_client()
        self._config = get_config()

    async def process_uploaded_file(
        self,
        *,
        activity_id: str,
        user_id: str,
        storage_key: str,
        source_type: str = "gpx",
    ) -> None:
        self._activity_client.update_activity_pipeline_fields(
            activity_id,
            user_id,
            processing_status=ProcessingStatus.processing,
        )

        try:
            bucket = self._config.ACTIVITY_UPLOAD_BUCKET
            raw_bytes = self._activity_client.download_storage_object(bucket, storage_key)
            raw_points = self._parse_raw_file(raw_bytes, source_type)
            elevated = await self._correct_elevations(raw_points)

            recorded_at = elevated[0].get("timestamp") or datetime.utcnow().isoformat()
            nivus_body = {
                "id": activity_id,
                "recorded_at": recorded_at,
                "source_type": source_type,
                "match_trails": True,
                "points": elevated,
            }
            pipeline = await self._nivus_client.process_pipeline(nivus_body)

            map_body = {
                "user_id": user_id,
                "processed_track": pipeline["processed_track"],
                "segments": pipeline.get("segments") or [],
                "stats": pipeline.get("stats"),
            }
            map_activity = await self._map_client.persist_pipeline_activity(map_body)
            map_activity_id = map_activity.get("id")

            stats = pipeline.get("stats") or {}
            distance_m = float(stats.get("total_distance_km") or 0) * 1000.0
            elevation_gain = float(stats.get("total_vertical_drop_m") or 0)
            moving_time_s = float(stats.get("moving_time_s") or 0)

            gps_path = [
                {
                    "lat": p["lat"],
                    "lng": p["lon"],
                    "elevation": p.get("elevation_m"),
                    "timestamp": p.get("timestamp"),
                }
                for p in pipeline.get("processed_track", {}).get("points", [])
            ]

            self._activity_client.update_activity_pipeline_fields(
                activity_id,
                user_id,
                map_activity_id=map_activity_id,
                processing_status=ProcessingStatus.ready,
                distance_meters=distance_m,
                duration_seconds=int(moving_time_s),
                elevation_gain_meters=elevation_gain,
                gps_path=gps_path,
                name=None,
            )
            logger.info(
                "pipeline complete activity_id=%s map_activity_id=%s points=%d",
                activity_id,
                map_activity_id,
                len(gps_path),
            )
        except Exception:
            logger.exception("pipeline failed activity_id=%s", activity_id)
            self._activity_client.update_activity_pipeline_fields(
                activity_id,
                user_id,
                processing_status=ProcessingStatus.failed,
            )
            raise

    def _parse_raw_file(self, raw_bytes: bytes, source_type: str) -> list[dict[str, Any]]:
        if source_type == "gpx":
            return parse_gpx_bytes(raw_bytes)
        raise ValueError(f"Unsupported source_type for async upload: {source_type}")

    async def _correct_elevations(self, points: list[dict[str, Any]]) -> list[dict[str, Any]]:
        if not points:
            return points

        corrected: list[dict[str, Any]] = []
        for start in range(0, len(points), _ELEVATION_CHUNK):
            chunk = points[start : start + _ELEVATION_CHUNK]
            batch = await self._map_client.correct_elevations(chunk)
            corrected.extend(batch)
        return corrected


def build_storage_key(user_id: str, activity_id: str, source_type: str) -> str:
    extension = "fit" if source_type == "fit" else "gpx"
    return f"uploads/{user_id}/{activity_id}.{extension}"
