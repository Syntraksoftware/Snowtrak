-- Run this in the Supabase SQL editor (or via psql against the Supabase Postgres).
-- Adds the thumbnail_url column to the Supabase activities table.
ALTER TABLE activities ADD COLUMN IF NOT EXISTS thumbnail_url text;
