# Activity Backend Curl Tests

Base URL: `http://127.0.0.1:8080/api/v1`

Auth: endpoints require `Authorization: Bearer <JWT>` from the main-backend auth service.

## Setup
```bash
# Optional: verify the activity-backend service is up
curl -s http://127.0.0.1:8080/health | jq .
```

## Create User + Login (main-backend)
Ensure the main-backend (Auth API) is running on the same host/port. These endpoints issue JWTs used by activity-backend.

```bash
# 1) Register a new user
EMAIL="demo.user@example.com"
PASSWORD="StrongPass123!"

curl -sS -X POST \
  "http://127.0.0.1:8080/api/v1/auth/register" \
  -H "Content-Type: application/json" \
  --data @- <<JSON | jq .
{ "email": "${EMAIL}", "password": "${PASSWORD}", "first_name": "Demo", "last_name": "User" }
JSON

# 2) Login and export access token for subsequent calls
TOKEN=$(curl -sS -X POST \
  "http://127.0.0.1:8080/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  --data @- <<JSON | jq -r '.access_token'
{ "email": "${EMAIL}", "password": "${PASSWORD}" }
JSON
)
echo "TOKEN set: ${TOKEN:0:16}..."
```

## POST /activities (create)
Aligned to the frontend payload. Server computes distance/elevation/duration and responds in the frontend shape.

```bash
curl -sS -X POST \
  "http://127.0.0.1:5100/api/v1/activities" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  --data @- <<'JSON' | jq .
{
  "type": "alpine",
  "name": "Morning Ski Session",
  "description": "Testing aligned create endpoint",
  "start_time": "2026-01-17T08:00:00Z",
  "end_time": "2026-01-17T09:10:30Z",
  "is_public": true,
  "locations": [
    {
      "latitude": 46.8201,
      "longitude": 9.2870,
      "altitude": 1500.0,
      "timestamp": "2026-01-17T08:00:10Z"
    },
    {
      "latitude": 46.8210,
      "longitude": 9.2890,
      "altitude": 1520.0,
      "timestamp": "2026-01-17T08:15:10Z"
    },
    {
      "latitude": 46.8230,
      "longitude": 9.2920,
      "altitude": 1555.0,
      "timestamp": "2026-01-17T08:30:10Z"
    }
  ]
}
JSON
```

Expected response (shape):
- `id`, `user_id`, `type`, `name`, `description`
- `distance` (meters), `duration` (seconds), `elevation_gain` (meters)
- `start_time`, `end_time`, `average_pace` (sec/km), `is_public`, `created_at`
- `locations` (array: latitude/longitude/altitude/timestamp)

## Placeholders for future tests
- GET /activities (feed): will add page/limit examples after alignment
- GET /activities/{id}
- PUT /activities/{id}
- DELETE /activities/{id}
- POST /activities/{id}/kudos
- GET/POST /activities/{id}/comments
- POST /activities/{id}/share
