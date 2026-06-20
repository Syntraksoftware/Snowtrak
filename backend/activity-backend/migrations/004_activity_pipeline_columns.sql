-- Activity Backend — pipeline bridge columns on public.activities
-- Run in Supabase SQL Editor (or psql) after existing SUPABASE_SETUP.sql.
--
-- Links social feed records (public.activities) to map_trail geometry rows
-- and supports async upload / queue processing status.

-- 1. Processing status (text + check; portable across Supabase migrations)
ALTER TABLE public.activities
  ADD COLUMN IF NOT EXISTS map_activity_id UUID,
  ADD COLUMN IF NOT EXISTS storage_key TEXT,
  ADD COLUMN IF NOT EXISTS processing_status TEXT NOT NULL DEFAULT 'ready';

ALTER TABLE public.activities
  DROP CONSTRAINT IF EXISTS activities_processing_status_check;

ALTER TABLE public.activities
  ADD CONSTRAINT activities_processing_status_check
  CHECK (
    processing_status IN ('pending', 'uploading', 'processing', 'ready', 'failed')
  );

-- 2. Indexes for cross-schema joins and feed filtering
CREATE INDEX IF NOT EXISTS idx_activities_map_activity_id
  ON public.activities (map_activity_id)
  WHERE map_activity_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_activities_processing_status
  ON public.activities (processing_status);

CREATE INDEX IF NOT EXISTS idx_activities_user_processing
  ON public.activities (user_id, processing_status, created_at DESC);

-- Optional soft reference (no FK enforcement across services):
-- map_activity_id points at map_trail.activities.id when pipeline persistence succeeds.
