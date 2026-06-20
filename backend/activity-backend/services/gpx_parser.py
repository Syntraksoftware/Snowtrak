"""Minimal GPX 1.x track-point parser for pipeline workers (no extra dependencies)."""

from __future__ import annotations

import xml.etree.ElementTree as ET
from datetime import datetime
from typing import Any


_GPX_NS = {"gpx": "http://www.topografix.com/GPX/1/1"}


def parse_gpx_bytes(data: bytes) -> list[dict[str, Any]]:
    """Return raw points: lat, lon, elevation_m?, timestamp (ISO), speed_kmh=0."""
    root = ET.fromstring(data)
    points: list[dict[str, Any]] = []

    for trkpt in root.findall(".//gpx:trkpt", _GPX_NS) + root.findall(".//trkpt"):
        lat = trkpt.get("lat")
        lon = trkpt.get("lon")
        if lat is None or lon is None:
            continue

        ele_el = trkpt.find("gpx:ele", _GPX_NS) or trkpt.find("ele")
        time_el = trkpt.find("gpx:time", _GPX_NS) or trkpt.find("time")

        elevation_m = float(ele_el.text) if ele_el is not None and ele_el.text else None
        timestamp = time_el.text if time_el is not None and time_el.text else None
        if timestamp:
            timestamp = datetime.fromisoformat(timestamp.replace("Z", "+00:00")).isoformat()

        point: dict[str, Any] = {
            "lat": float(lat),
            "lon": float(lon),
            "speed_kmh": 0.0,
        }
        if elevation_m is not None:
            point["elevation_m"] = elevation_m
        if timestamp:
            point["timestamp"] = timestamp
        points.append(point)

    if not points:
        raise ValueError("GPX file contains no track points")
    return points
