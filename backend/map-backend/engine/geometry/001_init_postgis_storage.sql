CREATE EXTENSION IF NOT EXISTS postgis;

-- Stores generated static-map URLs and request fingerprints.
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
);

CREATE INDEX IF NOT EXISTS idx_map_cache_entries_center
    ON map_cache_entries USING GIST (center);

CREATE INDEX IF NOT EXISTS idx_map_cache_entries_created_at
    ON map_cache_entries (created_at DESC);

-- Stores sampled elevation points resolved by map-backend.
CREATE TABLE IF NOT EXISTS elevation_samples (
    id BIGSERIAL PRIMARY KEY,
    location GEOGRAPHY(POINT, 4326) NOT NULL,
    elevation_meters DOUBLE PRECISION NOT NULL,
    source TEXT NOT NULL DEFAULT 'google_elevation',
    sampled_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (location, source)
);

CREATE INDEX IF NOT EXISTS idx_elevation_samples_location
    ON elevation_samples USING GIST (location);
