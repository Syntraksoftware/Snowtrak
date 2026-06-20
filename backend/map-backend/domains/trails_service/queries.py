"""SQL for trails_service (resort vector layer only).

Trail **matching** (PostGIS name lookup) lives in the external theta trail server.
"""

RESORT_BBOX_SQL = """
SELECT
    r.id::text AS id,
    r.name AS name,
    r.difficulty AS difficulty,
    r.source_id AS source_id,
    ST_AsGeoJSON(r.geom)::text AS geom_json
FROM map_trail.ski_runs AS r
WHERE r.geom && ST_MakeEnvelope($1::float8, $2::float8, $3::float8, $4::float8, 4326)
ORDER BY r.name NULLS LAST, r.id::text
"""
