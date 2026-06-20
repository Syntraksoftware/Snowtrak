"""Build GeoJSON FeatureCollections from PostGIS query rows."""

from __future__ import annotations

import json
from typing import Any


def rows_to_feature_collection(rows: list[Any]) -> dict[str, Any]:
    features: list[dict[str, Any]] = []
    for row in rows:
        geom_raw = row["geom_json"]
        geometry = json.loads(geom_raw) if isinstance(geom_raw, str) else geom_raw
        features.append(
            {
                "type": "Feature",
                "id": row["id"],
                "properties": {
                    "name": row["name"],
                    "difficulty": row["difficulty"],
                    "source_id": row["source_id"],
                },
                "geometry": geometry,
            }
        )
    return {"type": "FeatureCollection", "features": features}
