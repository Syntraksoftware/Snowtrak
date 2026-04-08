-- Trail matcher: sample SQL for Supabase SQL editor (PostGIS + map_trail.ski_runs).
-- Narrative doc: docs/playbook/map-flow/trail-matcher.md
-- Prerequisites: extension postgis; schema map_trail; table map_trail.ski_runs populated (e.g. OpenSkiMap sync).

-- 1) Sanity: row count
SELECT COUNT(*) AS ski_runs_n FROM map_trail.ski_runs;

-- 2) Single point — runs within 80 m of a coordinate (replace lat/lon with your resort)
--    ST_MakePoint(lon, lat) — x = longitude, y = latitude
SELECT
    r.name,
    r.difficulty,
    r.source_id,
    ST_Distance(
        r.geom::geography,
        ST_SetSRID(ST_MakePoint(8.5::float8, 47.5::float8), 4326)::geography
    ) AS dist_m
FROM map_trail.ski_runs AS r
WHERE ST_DWithin(
    r.geom::geography,
    ST_SetSRID(ST_MakePoint(8.5::float8, 47.5::float8), 4326)::geography,
    80.0::float8
)
ORDER BY dist_m ASC
LIMIT 5;

-- 3) Closest run only (matches services/trail_matcher.py match_segment logic)
SELECT
    r.name,
    r.difficulty,
    r.source_id,
    ST_Distance(
        r.geom::geography,
        ST_SetSRID(ST_MakePoint(8.5::float8, 47.5::float8), 4326)::geography
    ) AS dist_m
FROM map_trail.ski_runs AS r
WHERE ST_DWithin(
    r.geom::geography,
    ST_SetSRID(ST_MakePoint(8.5::float8, 47.5::float8), 4326)::geography,
    80.0::float8
)
ORDER BY dist_m ASC
LIMIT 1;

-- 4) Batch pattern — two representative points (centroids you computed in app), same radius
SELECT
    s.ord::int AS ord,
    r.name,
    r.difficulty,
    r.source_id,
    r.dist_m
FROM unnest(
    ARRAY[47.51::float8, 47.52::float8],
    ARRAY[8.51::float8, 8.52::float8]
) WITH ORDINALITY AS s(lat, lon, ord)
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
        80.0::float8
    )
    ORDER BY dist_m ASC
    LIMIT 1
) AS r ON TRUE
ORDER BY s.ord;

-- 5) Optional: GiST-friendly geography index (run once if EXPLAIN shows seq scans on heavy traffic)
-- CREATE INDEX IF NOT EXISTS idx_map_trail_ski_runs_geog
--   ON map_trail.ski_runs USING gist ((geom::geography));
