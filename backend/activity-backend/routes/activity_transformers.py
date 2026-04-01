"""Transformers and response builders for activity routes."""
from datetime import datetime
import math
from typing import Any, Dict, List, Optional

from fastapi import Request

from models import FrontendActivityResponse, LocationPoint
from shared import ListMeta, ListResponse, PaginationMeta, get_request_id


def parse_iso_timestamp(timestamp_value: str) -> datetime:
    """Parse ISO timestamps, supporting a trailing Z suffix."""
    return datetime.fromisoformat(timestamp_value.replace("Z", "+00:00"))


def calculate_haversine_distance_meters(
    latitude_one: float,
    longitude_one: float,
    latitude_two: float,
    longitude_two: float,
) -> float:
    """Calculate distance between two coordinates in meters."""
    earth_radius_meters = 6371000.0
    latitude_one_radians = math.radians(latitude_one)
    latitude_two_radians = math.radians(latitude_two)
    delta_latitude = latitude_two_radians - latitude_one_radians
    longitude_one_radians = math.radians(longitude_one)
    longitude_two_radians = math.radians(longitude_two)
    delta_longitude = longitude_two_radians - longitude_one_radians

    haversine_value = (
        math.sin(delta_latitude / 2) ** 2
        + math.cos(latitude_one_radians)
        * math.cos(latitude_two_radians)
        * math.sin(delta_longitude / 2) ** 2
    )
    central_angle = 2 * math.atan2(math.sqrt(haversine_value), math.sqrt(1 - haversine_value))
    return earth_radius_meters * central_angle


def compute_metrics_from_locations(location_records: List[Dict[str, Any]]) -> Dict[str, float]:
    """Compute distance and elevation gain from ordered location records."""
    total_distance_meters = 0.0
    total_elevation_gain_meters = 0.0

    for index in range(1, len(location_records)):
        previous_location = location_records[index - 1]
        current_location = location_records[index]
        total_distance_meters += calculate_haversine_distance_meters(
            previous_location["latitude"],
            previous_location["longitude"],
            current_location["latitude"],
            current_location["longitude"],
        )

        previous_altitude = previous_location.get("altitude")
        current_altitude = current_location.get("altitude")
        if previous_altitude is not None and current_altitude is not None:
            altitude_change = float(current_altitude) - float(previous_altitude)
            if altitude_change > 0:
                total_elevation_gain_meters += altitude_change

    return {
        "distance_meters": total_distance_meters,
        "elevation_gain_meters": total_elevation_gain_meters,
    }


def convert_to_location_points(location_records: List[Dict[str, Any]]) -> List[LocationPoint]:
    """Convert frontend location records to storage location points."""
    return [
        LocationPoint(
            lat=location_record["latitude"],
            lng=location_record["longitude"],
            elevation=location_record.get("altitude"),
            timestamp=location_record.get("timestamp"),
        )
        for location_record in location_records
    ]


def convert_to_frontend_locations(
    activity_identifier: str,
    gps_path_records: List[Dict[str, Any]],
) -> List[Dict[str, Any]]:
    """Convert storage GPS points to frontend location payload."""
    frontend_location_records: List[Dict[str, Any]] = []
    for gps_path_record in gps_path_records:
        latitude_value = gps_path_record.get("lat") if isinstance(gps_path_record, dict) else None
        longitude_value = gps_path_record.get("lng") if isinstance(gps_path_record, dict) else None
        if latitude_value is None or longitude_value is None:
            continue

        frontend_location_records.append(
            {
                "id": None,
                "activity_id": activity_identifier,
                "latitude": latitude_value,
                "longitude": longitude_value,
                "altitude": gps_path_record.get("elevation") if isinstance(gps_path_record, dict) else None,
                "accuracy": None,
                "speed": None,
                "timestamp": gps_path_record.get("timestamp") if isinstance(gps_path_record, dict) else None,
            }
        )

    return frontend_location_records


def map_activity_to_frontend_payload(
    activity_record: Dict[str, Any],
    fallback_start_time: Optional[str] = None,
    fallback_end_time: Optional[str] = None,
) -> Dict[str, Any]:
    """Map backend activity records into frontend response payload shape."""
    distance_meters = activity_record.get("distance_meters") or activity_record.get("distance") or 0
    duration_seconds = activity_record.get("duration_seconds") or activity_record.get("duration") or 0
    elevation_gain_meters = activity_record.get("elevation_gain_meters") or activity_record.get("elevation_gain") or 0

    start_time = (
        activity_record.get("start_time")
        or fallback_start_time
        or activity_record.get("created_at")
        or datetime.utcnow().isoformat()
    )
    end_time = (
        activity_record.get("end_time")
        or fallback_end_time
        or activity_record.get("created_at")
        or datetime.utcnow().isoformat()
    )

    if isinstance(start_time, datetime):
        start_time = start_time.isoformat()
    if isinstance(end_time, datetime):
        end_time = end_time.isoformat()

    average_pace = None
    if distance_meters and distance_meters > 0:
        try:
            average_pace = duration_seconds / (distance_meters / 1000)
        except Exception:
            average_pace = None

    created_at_value = activity_record.get("created_at")
    if isinstance(created_at_value, datetime):
        created_at_value = created_at_value.isoformat()

    gps_path_records = activity_record.get("gps_path", []) or []

    return {
        "id": activity_record.get("id"),
        "user_id": activity_record.get("user_id"),
        "type": activity_record.get("activity_type") or activity_record.get("type") or "other",
        "name": activity_record.get("name"),
        "description": activity_record.get("description"),
        "distance": distance_meters,
        "duration": duration_seconds,
        "elevation_gain": elevation_gain_meters,
        "start_time": start_time,
        "end_time": end_time,
        "average_pace": average_pace,
        "max_pace": activity_record.get("max_pace"),
        "calories": activity_record.get("calories"),
        "is_public": activity_record.get("visibility") == "public",
        "created_at": created_at_value,
        "locations": convert_to_frontend_locations(activity_record.get("id"), gps_path_records),
    }


def build_activity_list_response(
    request: Request,
    frontend_items: List[FrontendActivityResponse],
    limit: int,
    offset: int,
    total: int,
    deprecated_parameters: Optional[List[str]] = None,
    deprecation_information: Optional[str] = None,
) -> ListResponse:
    """Build a standardized list response with pagination metadata."""
    request_id = get_request_id(request)
    pagination_metadata = PaginationMeta(
        limit=limit,
        offset=offset,
        total=total,
        next_cursor=None,
        has_next=offset + limit < total,
    )
    response_metadata = ListMeta(
        request_id=request_id,
        pagination=pagination_metadata,
        deprecated_params=deprecated_parameters if deprecated_parameters else None,
        deprecation_info=deprecation_information,
    )
    return ListResponse(items=frontend_items, meta=response_metadata)
