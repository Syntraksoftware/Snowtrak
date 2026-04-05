"""PostGIS extension, public cache tables, and map_trail schema (pipeline + resort lines).

Pipeline tables live in schema ``map_trail`` so they do not collide with an existing
``public.activities`` (or other) table from Supabase / activity-backend.

Revision ID: 001_initial
Revises:
Create Date: 2026-04-05

"""

from __future__ import annotations

from alembic import op
from sqlalchemy import text

revision = "001_initial"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute(text("CREATE EXTENSION IF NOT EXISTS postgis"))
    op.execute(text("CREATE SCHEMA IF NOT EXISTS map_trail"))

    # --- public: map-backend cache (same as engine/geometry/001_init_postgis_storage.sql) ---
    op.execute(
        text("""
        CREATE TABLE IF NOT EXISTS map_cache_entries (
            id BIGSERIAL PRIMARY KEY,
            cache_key TEXT NOT NULL UNIQUE,
            center GEOGRAPHY(POINT, 4326) NOT NULL,
            zoom INTEGER NOT NULL,
            width INTEGER NOT NULL,
            height INTEGER NOT NULL,
            provider TEXT NOT NULL DEFAULT 'google_static_maps',
            static_url TEXT NOT NULL,
            expires_at TIMESTAMPTZ,
            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        )
        """)
    )
    op.execute(
        text(
            "CREATE INDEX IF NOT EXISTS idx_map_cache_entries_center "
            "ON map_cache_entries USING GIST (center)"
        )
    )
    op.execute(
        text(
            "CREATE INDEX IF NOT EXISTS idx_map_cache_entries_created_at "
            "ON map_cache_entries (created_at DESC)"
        )
    )

    op.execute(
        text("""
        CREATE TABLE IF NOT EXISTS elevation_samples (
            id BIGSERIAL PRIMARY KEY,
            location GEOGRAPHY(POINT, 4326) NOT NULL,
            elevation_meters DOUBLE PRECISION NOT NULL,
            source TEXT NOT NULL DEFAULT 'google_elevation',
            sampled_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            UNIQUE (location, source)
        )
        """)
    )
    op.execute(
        text(
            "CREATE INDEX IF NOT EXISTS idx_elevation_samples_location "
            "ON elevation_samples USING GIST (location)"
        )
    )

    # --- map_trail: resort + recorded tracks (GiST for ST_DWithin / spatial filters) ---
    op.execute(
        text("""
        CREATE TABLE IF NOT EXISTS map_trail.ski_runs (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            name VARCHAR(512) NOT NULL,
            difficulty VARCHAR(64),
            geom geometry(LINESTRING, 4326) NOT NULL
        )
        """)
    )
    op.execute(
        text(
            "CREATE INDEX IF NOT EXISTS idx_map_trail_ski_runs_geom "
            "ON map_trail.ski_runs USING GIST (geom)"
        )
    )

    op.execute(
        text("""
        CREATE TABLE IF NOT EXISTS map_trail.ski_lifts (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            name VARCHAR(512) NOT NULL,
            geom geometry(LINESTRING, 4326) NOT NULL
        )
        """)
    )
    op.execute(
        text(
            "CREATE INDEX IF NOT EXISTS idx_map_trail_ski_lifts_geom "
            "ON map_trail.ski_lifts USING GIST (geom)"
        )
    )

    op.execute(
        text("""
        CREATE TABLE IF NOT EXISTS map_trail.activities (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id UUID NOT NULL,
            recorded_at TIMESTAMPTZ NOT NULL,
            stats JSONB
        )
        """)
    )
    op.execute(
        text(
            "CREATE INDEX IF NOT EXISTS idx_map_trail_activities_user_recorded "
            "ON map_trail.activities (user_id, recorded_at DESC)"
        )
    )

    op.execute(
        text("""
        CREATE TABLE IF NOT EXISTS map_trail.track_points (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            activity_id UUID NOT NULL REFERENCES map_trail.activities (id) ON DELETE CASCADE,
            geom geometry(POINTZ, 4326) NOT NULL,
            speed_kmh DOUBLE PRECISION NOT NULL,
            segment_type VARCHAR(32)
        )
        """)
    )
    op.execute(
        text(
            "CREATE INDEX IF NOT EXISTS idx_map_trail_track_points_activity "
            "ON map_trail.track_points (activity_id)"
        )
    )
    op.execute(
        text(
            "CREATE INDEX IF NOT EXISTS idx_map_trail_track_points_geom "
            "ON map_trail.track_points USING GIST (geom)"
        )
    )

    op.execute(
        text("""
        CREATE TABLE IF NOT EXISTS map_trail.segments (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            activity_id UUID NOT NULL REFERENCES map_trail.activities (id) ON DELETE CASCADE,
            type VARCHAR(32) NOT NULL,
            start_idx INTEGER NOT NULL,
            end_idx INTEGER NOT NULL,
            trail_name TEXT,
            CONSTRAINT map_trail_segments_idx_order CHECK (start_idx >= 0 AND end_idx >= start_idx)
        )
        """)
    )
    op.execute(
        text(
            "CREATE INDEX IF NOT EXISTS idx_map_trail_segments_activity "
            "ON map_trail.segments (activity_id)"
        )
    )


def downgrade() -> None:
    op.execute(text("DROP SCHEMA IF EXISTS map_trail CASCADE"))
    op.execute(text("DROP TABLE IF EXISTS elevation_samples"))
    op.execute(text("DROP TABLE IF EXISTS map_cache_entries"))
    # Leave postgis extension installed — other objects may depend on it.
