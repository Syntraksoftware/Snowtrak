"""
Match GPS samples to resort **ski runs** in ``map_trail.ski_runs`` (PostGIS).

Uses **geography** casts so ``radius_m`` and distances are true **metres** on the spheroid.
``map_trail.ski_runs`` stores ``name``, ``difficulty``, and ``geom`` only (OpenSkiMap ingest);
**``piste_type``** is not a DB column yet — the API returns ``None`` until a source column exists.

Placed under ``map-backend/services/`` (not ``backend/services/``) so imports stay
``from services.trail_matcher import ...`` when the app cwd is ``map-backend``, without
clashing with a separate top-level ``services`` package.

Playbook: ``docs/playbook/map-flow/trail-matcher.md``.
"""

from __future__ import annotations

import logging
from collections.abc import Iterable, Sequence
from dataclasses import dataclass

import asyncpg
from shared.track_pipeline_schemas import SegmentOut, SegmentType

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class TrailMatch:
    """Closest ski run within the search radius."""

    trail_name: str
    difficulty: str | None
    piste_type: str | None
    distance_m: float
    source_id: str | None = None


@dataclass
class DescentSegmentInput:
    """One descent polyline; a **representative** point (centroid) is used for matching."""

    points: Sequence[tuple[float, float]]

    def representative_lat_lon(self) -> tuple[float, float]:
        if not self.points:
            raise ValueError("DescentSegmentInput.points must not be empty")
        n = len(self.points)
        lat = sum(p[0] for p in self.points) / n
        lon = sum(p[1] for p in self.points) / n
        return lat, lon


_MATCH_SEGMENT_SQL = """
SELECT
    r.name AS name,
    r.difficulty AS difficulty,
    r.source_id AS source_id,
    ST_Distance(
        r.geom::geography,
        ST_SetSRID(ST_MakePoint($1::float8, $2::float8), 4326)::geography
    ) AS dist_m
FROM map_trail.ski_runs AS r
WHERE ST_DWithin(
    r.geom::geography,
    ST_SetSRID(ST_MakePoint($1::float8, $2::float8), 4326)::geography,
    $3::float8
)
ORDER BY dist_m ASC
LIMIT 1
"""

_MATCH_BATCH_SQL = """
SELECT
    s.ord::int AS ord,
    r.name AS name,
    r.difficulty AS difficulty,
    r.source_id AS source_id,
    r.dist_m AS dist_m
FROM unnest($1::float8[], $2::float8[]) WITH ORDINALITY AS s(lat, lon, ord)
LEFT JOIN LATERAL (
    SELECT
        gr.name,
        gr.difficulty,
        gr.source_id,
        ST_Distance(
            gr.geom::geography,
            ST_SetSRID(ST_MakePoint(s.lon::float8, s.lat::float8), 4326)::geography
        ) AS dist_m
    FROM map_trail.ski_runs AS gr
    WHERE ST_DWithin(
        gr.geom::geography,
        ST_SetSRID(ST_MakePoint(s.lon::float8, s.lat::float8), 4326)::geography,
        $3::float8
    )
    ORDER BY dist_m ASC
    LIMIT 1
) AS r ON TRUE
ORDER BY s.ord
"""


def _row_to_match(row: asyncpg.Record | None) -> TrailMatch | None:
    if row is None:
        return None
    if row["name"] is None:
        return None
    return TrailMatch(
        trail_name=str(row["name"]),
        difficulty=row["difficulty"],
        piste_type=None,
        distance_m=float(row["dist_m"]),
        source_id=row["source_id"],
    )


async def match_segment(
    conn: asyncpg.Connection,
    lat: float,
    lon: float,
    radius_m: float,
) -> TrailMatch | None:
    """
    Closest ``map_trail.ski_runs`` row whose line is within ``radius_m`` metres of ``(lat, lon)``.

    ``lon`` / ``lat`` order in SQL follows PostGIS ``ST_MakePoint(lon, lat)``.
    """
    if radius_m < 0:
        raise ValueError("radius_m must be non-negative")
    row = await conn.fetchrow(_MATCH_SEGMENT_SQL, lon, lat, radius_m)
    return _row_to_match(row)


async def match_all_descents(
    conn: asyncpg.Connection,
    segments: Sequence[DescentSegmentInput],
    radius_m: float,
) -> list[TrailMatch | None]:
    """
    Batch match: one representative point per descent segment (centroid of its ``points``).

    Preserves input order. Empty ``segments`` yields ``[]``.
    """
    if radius_m < 0:
        raise ValueError("radius_m must be non-negative")
    if not segments:
        return []

    lats: list[float] = []
    lons: list[float] = []
    for seg in segments:
        la, lo = seg.representative_lat_lon()
        lats.append(la)
        lons.append(lo)

    rows = await conn.fetch(_MATCH_BATCH_SQL, lats, lons, radius_m)
    by_ord: dict[int, TrailMatch | None] = {}
    for row in rows:
        by_ord[int(row["ord"])] = _row_to_match(row)

    out: list[TrailMatch | None] = []
    for i in range(1, len(segments) + 1):
        out.append(by_ord.get(i))
    return out


def descent_segments_from_engine2(segments: Iterable[SegmentOut]) -> list[DescentSegmentInput]:
    """Filter Engine-2 ``SegmentOut`` list to descents with at least one point."""
    out: list[DescentSegmentInput] = []
    for s in segments:
        if s.type != SegmentType.descent or not s.points:
            continue
        out.append(DescentSegmentInput(points=[(p.lat, p.lon) for p in s.points]))
    return out
