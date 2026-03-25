-- Activity Backend - Supabase SQL Setup
-- Run these SQL commands in Supabase SQL Editor to create all required tables

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Activities table
CREATE TABLE IF NOT EXISTS activities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  name VARCHAR(255) NOT NULL,
  activity_type VARCHAR(50) NOT NULL,
  gps_path JSONB DEFAULT '[]'::JSONB,
  duration_seconds INTEGER NOT NULL,
  distance_meters FLOAT NOT NULL,
  elevation_gain_meters FLOAT NOT NULL,
  visibility VARCHAR(20) DEFAULT 'private',
  description TEXT,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_activities_user_id ON activities(user_id);
CREATE INDEX IF NOT EXISTS idx_activities_created_at ON activities(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_activities_visibility ON activities(visibility);
CREATE INDEX IF NOT EXISTS idx_activities_activity_type ON activities(activity_type);

-- 2. Activity Comments table
CREATE TABLE IF NOT EXISTS activity_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  activity_id UUID NOT NULL REFERENCES activities(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_activity_comments_activity_id ON activity_comments(activity_id);
CREATE INDEX IF NOT EXISTS idx_activity_comments_user_id ON activity_comments(user_id);
CREATE INDEX IF NOT EXISTS idx_activity_comments_created_at ON activity_comments(created_at DESC);

-- 3. Activity Kudos (Likes) table
CREATE TABLE IF NOT EXISTS activity_kudos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  activity_id UUID NOT NULL REFERENCES activities(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,
  created_at TIMESTAMP DEFAULT now(),
  UNIQUE(activity_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_activity_kudos_activity_id ON activity_kudos(activity_id);
CREATE INDEX IF NOT EXISTS idx_activity_kudos_user_id ON activity_kudos(user_id);
CREATE INDEX IF NOT EXISTS idx_activity_kudos_created_at ON activity_kudos(created_at DESC);

-- 4. Activity Shares table (for shareable links)
CREATE TABLE IF NOT EXISTS activity_shares (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  activity_id UUID NOT NULL REFERENCES activities(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,
  token VARCHAR(255) UNIQUE NOT NULL,
  created_at TIMESTAMP DEFAULT now(),
  expires_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_activity_shares_activity_id ON activity_shares(activity_id);
CREATE INDEX IF NOT EXISTS idx_activity_shares_user_id ON activity_shares(user_id);
CREATE INDEX IF NOT EXISTS idx_activity_shares_token ON activity_shares(token);

-- Optional: Create a views for common queries
CREATE OR REPLACE VIEW activity_stats AS
SELECT 
  a.id,
  a.user_id,
  a.name,
  COUNT(DISTINCT c.id) as comment_count,
  COUNT(DISTINCT k.id) as kudos_count,
  a.created_at
FROM activities a
LEFT JOIN activity_comments c ON a.id = c.activity_id
LEFT JOIN activity_kudos k ON a.id = k.activity_id
GROUP BY a.id, a.user_id, a.name, a.created_at;

-- Grant permissions (if using service role)
-- Uncomment if needed:
-- GRANT ALL ON activities TO authenticated;
-- GRANT ALL ON activity_comments TO authenticated;
-- GRANT ALL ON activity_kudos TO authenticated;
-- GRANT ALL ON activity_shares TO authenticated;
