"""Bounding-box parsing for resort GeoJSON queries."""

from __future__ import annotations


def parse_bbox(bbox: str) -> tuple[float, float, float, float]:
    """Parse ``min_lon,min_lat,max_lon,max_lat`` WGS84 envelope."""
    parts = [p.strip() for p in bbox.split(",")]
    if len(parts) != 4:
        raise ValueError(
            "bbox must be four comma-separated numbers: min_lon,min_lat,max_lon,max_lat"
        )
    try:
        min_lon, min_lat, max_lon, max_lat = (float(x) for x in parts)
    except ValueError as e:
        raise ValueError("bbox values must be numeric") from e
    if min_lon >= max_lon or min_lat >= max_lat:
        raise ValueError("bbox must satisfy min_lon < max_lon and min_lat < max_lat")
    if not (-180.0 <= min_lon <= 180.0 and -180.0 <= max_lon <= 180.0):
        raise ValueError("longitude out of range")
    if not (-90.0 <= min_lat <= 90.0 and -90.0 <= max_lat <= 90.0):
        raise ValueError("latitude out of range")
    return min_lon, min_lat, max_lon, max_lat
