"""
Sync ski run LineStrings from a GeoJSON source into ``map_trail.ski_runs``.

OpenSkiMap (https://openskimap.org/) uses vector tiles from ``tiles.openskimap.org``
(see the front-end repo https://github.com/russellporter/openskimap.org and tile
metadata at https://tiles.openskimap.org/openskimap-internal.json). There is no
stable public bulk GeoJSON URL; the OpenSkiData processor
(https://github.com/russellporter/openskidata-processor) emits GeoJSON under
``npm run prepare-geojson``. Point ``OPENSKIMAP_RUNS_GEOJSON_URL`` at that file
(or any FeatureCollection of run LineStrings).
"""

from __future__ import annotations

import json
import logging
import os
from dataclasses import dataclass
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

import asyncpg
import httpx
from shapely.geometry import LineString, MultiLineString, mapping, shape

logger = logging.getLogger(__name__)

DEFAULT_REQUEST_TIMEOUT_S = 600.0

# GeoJSON property keys (OSM / OpenSkiMap-style dumps vary)
_NAME_KEYS = ("name", "piste:name", "piste_name")
_DIFFICULTY_KEYS = ("piste:difficulty", "piste_difficulty", "difficulty")
_ID_KEYS = ("id", "@id", "osm_id", "osm_way_id", "osm_rel_id", "@id")


@dataclass(frozen=True)
class ParsedSkiRun:
    source_id: str
    name: str
    difficulty: str | None
    geom_geojson: str


def _geojson_cache_buster(url: str) -> str:
    """Append a daily query param so CDNs can return fresh data when they honor ``?v=``."""
    day = datetime.now(UTC).strftime("%Y%m%d")
    sep = "&" if "?" in url else "?"
    return f"{url}{sep}v={day}"


async def download_geojson(url: str | None = None, *, bust_cache: bool = True) -> dict[str, Any]:
    """
    Fetch a GeoJSON document (FeatureCollection or single Feature) over HTTPS.

    ``url`` defaults to ``OPENSKIMAP_RUNS_GEOJSON_URL``. A date-based ``v=`` query
    parameter is added by default for cache-friendly daily runs.
    """
    resolved = (url or os.environ.get("OPENSKIMAP_RUNS_GEOJSON_URL") or "").strip()
    if not resolved:
        msg = "Set OPENSKIMAP_RUNS_GEOJSON_URL or pass url= to download_geojson()"
        raise ValueError(msg)

    fetch_url = _geojson_cache_buster(resolved) if bust_cache else resolved
    async with httpx.AsyncClient(
        timeout=httpx.Timeout(DEFAULT_REQUEST_TIMEOUT_S),
        follow_redirects=True,
        headers={"User-Agent": "syntrak-map-backend/openskimap-sync"},
    ) as client:
        response = await client.get(fetch_url)
        response.raise_for_status()
        data = response.json()

    if not isinstance(data, dict):
        raise ValueError("GeoJSON root must be an object")
    return data


def load_geojson_path(path: str | os.PathLike[str]) -> dict[str, Any]:
    """Load a GeoJSON object from a local file (UTF-8)."""
    p = Path(path).expanduser().resolve()
    text = p.read_text(encoding="utf-8")
    data = json.loads(text)
    if not isinstance(data, dict):
        raise ValueError("GeoJSON root must be an object")
    return data


def _prop(props: dict[str, Any], keys: tuple[str, ...]) -> str | None:
    for k in keys:
        if k in props and props[k] is not None:
            v = props[k]
            if isinstance(v, (list, dict)):
                continue
            s = str(v).strip()
            if s:
                return s
    return None


def _feature_source_id(props: dict[str, Any], fallback_index: int) -> str:
    raw = _prop(props, _ID_KEYS)
    if raw:
        return raw if raw.startswith("openskimap:") else f"openskimap:{raw}"
    return f"openskimap:idx:{fallback_index}"


def _geometry_to_linestring_geojson(geom_obj: dict[str, Any]) -> str | None:
    g = shape(geom_obj)
    if isinstance(g, LineString):
        if g.is_empty:
            return None
        return json.dumps(mapping(g))
    if isinstance(g, MultiLineString):
        parts = [ls for ls in g.geoms if not ls.is_empty]
        if not parts:
            return None
        longest = max(parts, key=lambda ls: ls.length)
        return json.dumps(mapping(longest))
    return None


def parse_runs(geojson_root: dict[str, Any]) -> list[ParsedSkiRun]:
    """Extract LineString (or longest MultiLineString) features with name + difficulty."""
    features: list[dict[str, Any]]
    t = geojson_root.get("type")
    if t == "FeatureCollection":
        raw = geojson_root.get("features")
        features = raw if isinstance(raw, list) else []
    elif t == "Feature":
        features = [geojson_root]
    else:
        logger.warning("GeoJSON type %r is not FeatureCollection/Feature", t)
        return []

    out: list[ParsedSkiRun] = []
    for i, feat in enumerate(features):
        if not isinstance(feat, dict) or feat.get("type") != "Feature":
            continue
        geom = feat.get("geometry")
        props = feat.get("properties")
        if not isinstance(geom, dict) or not isinstance(props, dict):
            continue

        line_json = _geometry_to_linestring_geojson(geom)
        if line_json is None:
            continue

        name = _prop(props, _NAME_KEYS) or "Unnamed run"
        difficulty = _prop(props, _DIFFICULTY_KEYS)
        source_id = _feature_source_id(props, i)
        out.append(
            ParsedSkiRun(
                source_id=source_id,
                name=name[:512],
                difficulty=difficulty[:64] if difficulty else None,
                geom_geojson=line_json,
            )
        )

    return out


UPSERT_SQL = """
INSERT INTO map_trail.ski_runs (source_id, name, difficulty, geom)
VALUES (
    $1, $2, $3,
    ST_SetSRID(ST_Force2D(ST_GeomFromGeoJSON($4::text)), 4326)
)
ON CONFLICT (source_id) DO UPDATE SET
    name = EXCLUDED.name,
    difficulty = EXCLUDED.difficulty,
    geom = EXCLUDED.geom
"""


async def upsert_to_postgis(conn: asyncpg.Connection, runs: list[ParsedSkiRun]) -> int:
    """``INSERT ... ON CONFLICT (source_id) DO UPDATE`` for each parsed run."""
    if not runs:
        return 0
    # executemany keeps round-trips low for large extracts
    await conn.executemany(
        UPSERT_SQL,
        [
            (
                r.source_id,
                r.name,
                r.difficulty,
                r.geom_geojson,
            )
            for r in runs
        ],
    )
    return len(runs)


async def sync_ski_runs_from_openskimap(
    conn: asyncpg.Connection,
    *,
    url: str | None = None,
    bust_cache: bool = True,
) -> int:
    """Download GeoJSON, parse runs, upsert. Returns number of rows written."""
    root = await download_geojson(url, bust_cache=bust_cache)
    runs = parse_runs(root)
    logger.info("OpenSkiMap sync: parsed %d ski run features", len(runs))
    return await upsert_to_postgis(conn, runs)


async def sync_ski_runs_from_geojson_file(
    conn: asyncpg.Connection,
    path: str | os.PathLike[str],
) -> int:
    """Parse runs from a local GeoJSON file and upsert (no HTTP)."""
    root = load_geojson_path(path)
    runs = parse_runs(root)
    logger.info(
        "OpenSkiMap sync: parsed %d ski run features from %s",
        len(runs),
        path,
    )
    return await upsert_to_postgis(conn, runs)
