# Activity Backend (Minimal)

Minimal FastAPI service for skiing activity records using Supabase.

## Quick Start

```bash
cd activity-backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp ../community-backend/.env.example .env  # or create your own
# set SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, JWT_SECRET
HOST=127.0.0.1 PORT=5100 uvicorn main:app --reload
```

## Environment Variables
- `SUPABASE_URL` (required)
- `SUPABASE_SERVICE_ROLE_KEY` (required)
- `JWT_SECRET` (required)
- `JWT_ALGORITHM` (default `HS256`)
- `FASTAPI_ENV` (`development`|`production`, default `development`)
- `PORT` (default `5100`)
- `HOST` (default `127.0.0.1`, set `0.0.0.0` to listen on all interfaces)

## API Endpoints (minimal)
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

## Data Shapes
- **ActivityCreate**: `name`, `activity_type`, `gps_path` (array of `{lat,lng,elevation?,timestamp?}`), `duration_seconds`, `distance_meters`, `elevation_gain_meters`, `visibility` (`private|followers|public`), `description?`
- **ActivityResponse**: includes ids, metrics, visibility, description, gps_path, created_at
- **CommentCreate**: `content`

## Supabase Tables (expected)
- `activities` (id, user_id, name, activity_type, gps_path jsonb, duration_seconds, distance_meters, elevation_gain_meters, visibility, description, created_at)
- `activity_comments` (id, activity_id, user_id, content, created_at)
- `activity_kudos` (id, activity_id, user_id, created_at)
- `activity_shares` (id, activity_id, user_id, token, created_at)

## Auth
- JWT bearer expected in `Authorization: Bearer <token>`
- `sub` claim is treated as `user_id`

## Structure
```
activity-backend/
  config.py              # env + settings
  main.py                # FastAPI app + lifespan
  middleware/auth.py     # JWT dependencies
  services/supabase_client.py  # Supabase operations
  routes/activities.py   # API routes
  requirements.txt
  README.md
```
