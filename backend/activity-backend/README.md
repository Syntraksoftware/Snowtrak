# Activity Backend

FastAPI microservice for activity record management, GPS path storage, and activity metrics for the Syntrak skiing application.

## 1. Purpose and scope

The Activity Backend exposes REST APIs for creating, retrieving, updating, and deleting skiing activity records. Activities include GPS tracks, elevation metrics, and user-generated content (comments, kudos). This service manages the activity domain on behalf of the Flutter frontend and integrates with Supabase as the data store.

**Key responsibilities:**
- Activity CRUD operations (`/api/v1/activities/*`)
- GPS path and metrics persistence
- Visibility (public/private) and sharing controls
- Activity comment and kudos management

## 2. Architecture overview

### High-level design

Activity Backend is a self-contained FastAPI microservice exposing a REST JSON API. It does not call other backend services; instead, it coordinates directly with Supabase PostgREST for data storage and retrieval.

```
Flutter Frontend (ActivitiesApi) 
  ↓ HTTP POST/GET/PUT/DELETE
Activity Backend (/api/v1/activities)
  ↓ SQL
Supabase (activities, activity_comments, activity_kudos, activity_shares tables)
```

### Key design patterns

- **Schema-first integration**: Frontend and backend coordinate on Activity JSON contract defined in `FRONTEND_ACTIVITY_API_SCHEMA.md`
- **Model mapping**: Pydantic schemas (`models.py`) translate Supabase rows to API responses
- **JWT authentication**: All routes protected by bearer token validation via `middleware/auth.py`
- **Supabase client**: Direct SQL integration (no ORM); service layer handles queries

### Data contracts/models

**Activity model (request/response):**
- `id`: UUID (backend-generated)
- `user_id`: UUID (from JWT token)
- `activity_type`: Enum (ski, snowboard, hike)
- `start_time`: ISO8601 timestamp
- `end_time`: ISO8601 timestamp
- `locations`: List of GPS points (lat, lng, elevation, timestamp)
- `distance_meters`: Calculated from GPS path
- `elevation_gain_meters`: Calculated from locations
- `visibility`: 'public' or 'private' (default: private)
- `featured_photo_url`: Optional image URL
- `description`: Optional user text

** Related entities:**
- **Activity Comments**: User-generated text responses; cascade delete with parent activity
- **Activity Kudos**: Like/upvote one per user per activity
- **Activity Shares**: Time-limited shareable links with token-based access

### External integrations

- **Supabase**: PostgreSQL database with REST API (no direct client library; uses HTTP POST to Supabase PostgREST)
- **Frontend**: Receives activity list/detail/mutation responses in standardized JSON format
- **Shared utilities**: `backend/shared/auth.py` for JWT token validation; `backend/shared/exception_handlers.py` for error responses

## 3. Code structure and key components

### File map

```
backend/activity-backend/
├── main.py                             # FastAPI app setup, lifespan, startup hooks
├── config.py                           # Environment variables & settings
├── models.py                           # Pydantic Activity schema
├── routes/
│   └── activities.py                   # CRUD endpoints (/api/v1/activities*)
├── services/
│   └── supabase_client.py             # Query builder and SQL execution
├── middleware/
│   └── auth.py                        # JWT extraction and validation
├── SUPABASE_SETUP.sql                 # Database schema creation script
├── FRONTEND_ACTIVITY_API_SCHEMA.md    # Activity payload contract with frontend
└── requirements.txt                    # Python dependencies (fastapi, supabase-py, etc.)
```

### Entry points

- **main.py**: Initializes FastAPI app, registers routes, starts ASGI server on port 5100
- **routes/activities.py**: Defines endpoints; each route extracts JWT token and delegates to service layer
- **services/supabase_client.py**: Database adapter; handles query construction and error handling

### Critical logic

1. **JWT extraction** (`middleware/auth.py`): Extracts bearer token from Authorization header; validates expiration and signature using shared `JWT_SECRET`
2. **Activity creation**: Receives GPS locations; computes metrics (distance, elevation gain); UUID-generates activity ID; inserts record into Supabase
3. **Activity retrieval**: Filters by ownership; returns activity with human-readable timestamps; omits sensitive fields (e.g., service metadata)
4. **Model mapping**: Pydantic `Activity` schema transforms Supabase JSON rows (snake_case) into camelCase for frontend

### Configuration

Environment variables (set via `.env` or deployment config):
- `SUPABASE_URL`: Supabase project base URL
- `SUPABASE_SERVICE_ROLE_KEY`: Service role authentication key (full database access)
- `JWT_SECRET`: Shared secret for token validation across all backends
- `HOST`, `PORT`: Server bind address (default: 127.0.0.1:5100)

## 4. Development and maintenance guidelines

### Setup instructions

1. **Create database tables:**
   ```bash
   # Go to Supabase Dashboard → SQL Editor → Create New Query
   # Paste contents of SUPABASE_SETUP.sql and run
   # Creates: activities, activity_comments, activity_kudos, activity_shares tables and indexes
   ```

2. **Install and run:**
   ```bash
   cd backend/activity-backend
   python -m venv venv
   source venv/bin/activate  # Windows: venv\Scripts\activate
   pip install -r requirements.txt
   cp .env.example .env
   # Edit .env: set SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, JWT_SECRET
   python main.py
   ```

### Testing strategy

- Unit tests in `tests/` for model validation and service layer functions
- Integration tests against live Supabase (use separate test database for isolation)
- Manual curl tests in `CURL_TESTS.md` for endpoint verification

**Run tests:**
```bash
pytest tests/
pytest tests/ -v --tb=short  # Verbose output with short traceback
```

### Code standards

- Pydantic models for all request/response schemas (type safety, auto-validation)
- Service layer for Supabase queries (separate concerns: route handling vs. data access)
- Shared auth middleware via `backend/shared/auth.py` (consistent token validation)
- Error responses use `backend/shared/exception_handlers.py` (standardized error format)

### Common pitfalls

- **Forgotten JWT secret alignment**: `JWT_SECRET` must match value in `main-backend` and shared deployment config
- **Supabase ServiceRole key leakage**: Never commit `.env` file; use `.env.example` as template
- **Model mismatch**: When adding fields to Activity, update both Pydantic schema and `SUPABASE_SETUP.sql` together
- **GPS location edge cases**: Handle empty location arrays and zero-distance activities

### Logging and monitoring

- Logs: Standard Python logging to stdout (captured by Docker/container orchestrator)
- Key log points: Service startup, successful authentications, query errors
- Monitor: HTTP response times, Supabase query latency, token validation failures

## 5. Deployment and operations

### Build and deployment

```bash
# Local Docker build
docker build -t syntrak-activity-backend:latest .

# Via docker-compose from backend root
cd backend
docker-compose up -d syntrak-activity-backend
```

Service runs on port 5100 and connects to Supabase via SUPABASE_URL.

### Runtime requirements

- Python 3.11+ (FastAPI, Pydantic)
- Network access to Supabase PostgreSQL (typically port 5432 + PostgREST)
- Environment variables: `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `JWT_SECRET`
- Shared backend/shared/ directory for auth utilities and exception handlers

### Health checks

- **Liveness**: HTTP GET `/health` (if added; currently no dedicated health endpoint)
- **Readiness**: Successful Supabase query response indicates database connectivity

### Backward compatibility

- API contract changes (adding/removing Activity fields) must be coordinated with frontend
- New fields should be optional with sensible defaults to avoid breaking existing clients
- Deprecation notice: When removing a field, plan at least one release cycle of warning

## 6. Examples and usage

### Create activity

```bash
curl -X POST http://localhost:5100/api/v1/activities \
  -H "Authorization: Bearer <JWT_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "activity_type": "ski",
    "start_time": "2024-01-15T09:00:00Z",
    "end_time": "2024-01-15T13:30:00Z",
    "locations": [
      {"lat": 39.2847, "lng": -106.5007, "elevation": 3200, "timestamp": "2024-01-15T09:00:00Z"},
      {"lat": 39.2848, "lng": -106.5006, "elevation": 3195, "timestamp": "2024-01-15T09:05:00Z"}
    ],
    "description": "Great run on Dora Bowl"
  }'
```

### Retrieve activity

```bash
curl -X GET http://localhost:5100/api/v1/activities/{id} \
  -H "Authorization: Bearer <JWT_TOKEN>"
```

### List activities (user's own)

```bash
curl -X GET http://localhost:5100/api/v1/activities \
  -H "Authorization: Bearer <JWT_TOKEN>"
```

### Update activity

```bash
curl -X PUT http://localhost:5100/api/v1/activities/{id} \
  -H "Authorization: Bearer <JWT_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"description": "Updated description"}'
```

### Delete activity

```bash
curl -X DELETE http://localhost:5100/api/v1/activities/{id} \
  -H "Authorization: Bearer <JWT_TOKEN>"
```

## 7. Troubleshooting and FAQs

### Common errors

**401 Unauthorized**: Token validation failed
- Check: JWT_SECRET matches between activity-backend and main-backend
- Check: Bearer token format in Authorization header
- Check: Token expiration (main-backend determines TTL)

**500 Database error**: Supabase connection failure
- Check: SUPABASE_URL is reachable and correct
- Check: SUPABASE_SERVICE_ROLE_KEY has proper permissions
- Check: Database tables exist (run SUPABASE_SETUP.sql if missing)

**GPS metrics incorrect**: Distance or elevation gain is wrong
- Verify: Locations are ordered by timestamp
- Verify: Coordinates are valid (lat -90..90, lng -180..180)
- Check: Elevation field is populated (not null)

### Debugging tips

- Enable request/response logging in FastAPI: Add logging middleware to `main.py`
- Track Supabase queries via Supabase dashboard logs (SQL Editor → Logs)
- Test endpoints independently with curl (see Examples section above)
- Verify token payload: Decode JWT at jwt.io to inspect claims

### Performance tuning

- Index activities by user_id for fast filtering (included in SUPABASE_SETUP.sql)
- Avoid N+1 queries: Use Supabase views (e.g., activity_stats) for aggregations
- Cache frequent queries (e.g., user's activity count) in Redis if response time critical

## 8. Change log and versioning

### Recent updates

- **2024-01**: Initial FastAPI service with CRUD endpoints and Supabase integration
- **2024-02**: Added activity kudos and commenting features
- **2024-03**: Activity shares with token-based link generation

### Version compatibility

- Activity Backend v1 expects Activity model with: id, user_id, activity_type, start_time, end_time, locations, distance_meters, elevation_gain_meters, visibility, description
- Frontend expects activity-backend running on port 5100 via app configuration (app_config.dart)
- Shared backend services (auth, exception handling) imported from `backend/shared`
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
