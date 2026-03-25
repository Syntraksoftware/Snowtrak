# Activity Backend (Minimal)

Minimal FastAPI service for skiing activity records using Supabase.

## Setup

### 1. Create Supabase Tables

Copy the SQL from `SUPABASE_SETUP.sql` and run it in your Supabase project's SQL editor:
```bash
# Go to: Supabase Dashboard → Your Project → SQL Editor
# Create New Query → Paste contents of SUPABASE_SETUP.sql → Run
```

This creates:
- `activities` — user activities with GPS path, metrics, visibility
- `activity_comments` — activity comments (cascade deleted with activity)
- `activity_kudos` — likes/kudos (one per user per activity)
- `activity_shares` — shareable links with tokens
- Indexes for performance on common queries
- `activity_stats` view for quick stats queries

### 2. Install & Run

```bash
cd backend/activity-backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp ../community-backend/.env.example .env  # or create your own
# Update .env: set SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, JWT_SECRET
export HOST=127.0.0.1
export PORT=5100
python main.py
```

## Project Structure

```
backend/activity-backend/
  config.py                    # Environment & settings
  main.py                      # FastAPI app + lifespan
  models.py                    # Pydantic schemas
  middleware/
    auth.py                    # JWT dependencies
  services/
    supabase_client.py         # Supabase operations
  routes/
    activities.py              # API endpoints
  SUPABASE_SETUP.sql          # Database table creation
  requirements.txt
  README.md
```

## Environment Variables
- `SUPABASE_URL` (required)
- `SUPABASE_SERVICE_ROLE_KEY` (required)
- `JWT_SECRET` (required)
- `JWT_ALGORITHM` (default `HS256`)
- `FASTAPI_ENV` (`development`|`production`, default `development`)
- `PORT` (default `5100`)
- `HOST` (default `127.0.0.1`, set `0.0.0.0` to listen on all interfaces)

## API Endpoints
Base path: `/api/v1/activities`

### Activity Management
- `POST /` Create activity (auth)
- `GET /` List activities (pagination)
- `GET /me` List my activities with filters (auth)
- `GET /{id}` Get activity details
- `PUT /{id}` Update activity (name, description, visibility) (auth/owner)
- `DELETE /{id}` Delete activity (auth/owner)

### Social
- `POST /{id}/kudos` Like/unlike (auth)
- `GET /{id}/comments` List comments
- `POST /{id}/comments` Add comment (auth)
- `POST /{id}/share` Create shareable link (auth)

## Request/Response Shapes

### ActivityCreate (POST /)
```json
{
  "name": "Morning ski run",
  "activity_type": "ski",
  "gps_path": [
    {"lat": 40.7128, "lng": -74.0060, "elevation": 100, "timestamp": "2026-01-10T10:00:00Z"},
    {"lat": 40.7130, "lng": -74.0061, "elevation": 120, "timestamp": "2026-01-10T10:01:00Z"}
  ],
  "duration_seconds": 3600,
  "distance_meters": 5000,
  "elevation_gain_meters": 500,
  "visibility": "private",
  "description": "Great powder conditions"
}
```

### ActivityResponse
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "user_id": "user-123",
  "name": "Morning ski run",
  "activity_type": "ski",
  "gps_path": [...],
  "duration_seconds": 3600,
  "distance_meters": 5000,
  "elevation_gain_meters": 500,
  "visibility": "private",
  "description": "Great powder conditions",
  "created_at": "2026-01-10T10:00:00Z"
}
```

### CommentCreate (POST /{id}/comments)
```json
{
  "content": "Awesome run!"
}
```

## Database Schema

**activities**
- `id` UUID (PK)
- `user_id` UUID
- `name` VARCHAR(255)
- `activity_type` VARCHAR(50)
- `gps_path` JSONB (array of GPS points)
- `duration_seconds` INTEGER
- `distance_meters` FLOAT
- `elevation_gain_meters` FLOAT
- `visibility` VARCHAR(20) (private|followers|public)
- `description` TEXT
- `created_at` TIMESTAMP
- Indexes on: user_id, created_at, visibility, activity_type

**activity_comments**
- `id` UUID (PK)
- `activity_id` UUID (FK → activities, cascade delete)
- `user_id` UUID
- `content` TEXT
- `created_at` TIMESTAMP
- Indexes on: activity_id, user_id, created_at

**activity_kudos**
- `id` UUID (PK)
- `activity_id` UUID (FK → activities, cascade delete)
- `user_id` UUID
- `created_at` TIMESTAMP
- UNIQUE(activity_id, user_id) — one like per user per activity
- Indexes on: activity_id, user_id, created_at

**activity_shares**
- `id` UUID (PK)
- `activity_id` UUID (FK → activities, cascade delete)
- `user_id` UUID
- `token` VARCHAR(255) UNIQUE
- `created_at` TIMESTAMP
- `expires_at` TIMESTAMP (optional)
- Indexes on: activity_id, user_id, token
- `activity_kudos` (id, activity_id, user_id, created_at)
- `activity_shares` (id, activity_id, user_id, token, created_at)

## Auth
- JWT bearer expected in `Authorization: Bearer <token>`
- `sub` claim is treated as `user_id`

## Structure
```
backend/activity-backend/
  config.py              # env + settings
  main.py                # FastAPI app + lifespan
  middleware/auth.py     # JWT dependencies
  services/supabase_client.py  # Supabase operations
  routes/activities.py   # API routes
  requirements.txt
  README.md
```
