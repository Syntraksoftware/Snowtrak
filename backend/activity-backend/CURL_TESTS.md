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
Aligned to the frontend payload. Server computes distance/elevation/duration and responds in the frontend shape. Called from [frontend/lib/services/api_service.dart](frontend/lib/services/api_service.dart#L174-L188).

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
    { "latitude": 46.8201, "longitude": 9.2870, "altitude": 1500.0, "timestamp": "2026-01-17T08:00:10Z" },
    { "latitude": 46.8210, "longitude": 9.2890, "altitude": 1520.0, "timestamp": "2026-01-17T08:15:10Z" },
    { "latitude": 46.8230, "longitude": 9.2920, "altitude": 1555.0, "timestamp": "2026-01-17T08:30:10Z" }
  ]
}
JSON
```

## GET /activities (feed)
Returns an array of frontend-shaped activities. Frontend call: [frontend/lib/services/api_service.dart](frontend/lib/services/api_service.dart#L180-L188).

```bash
curl -sS "http://127.0.0.1:5100/api/v1/activities?limit=20&offset=0" \
  -H "Authorization: Bearer $TOKEN" | jq '.'
```

## GET /activities/{id}
Returns a frontend-shaped activity. Frontend call: [frontend/lib/services/api_service.dart](frontend/lib/services/api_service.dart#L190-L193).

```bash
ACTIVITY_ID="REPLACE_ME"
curl -sS "http://127.0.0.1:5100/api/v1/activities/$ACTIVITY_ID" \
  -H "Authorization: Bearer $TOKEN" | jq '.'
```

## PUT /activities/{id}
Frontend sends `name`, `description`, `is_public`; backend maps to `visibility` and returns frontend shape. Frontend call: [frontend/lib/services/api_service.dart](frontend/lib/services/api_service.dart#L195-L207).

```bash
ACTIVITY_ID="REPLACE_ME"
curl -sS -X PUT \
  "http://127.0.0.1:5100/api/v1/activities/$ACTIVITY_ID" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  --data '{"name":"Updated name","description":"Updated desc","is_public":false}' | jq '.'
```

## DELETE /activities/{id}
Deletes an activity. Frontend call: [frontend/lib/services/api_service.dart](frontend/lib/services/api_service.dart#L209-L211).

```bash
ACTIVITY_ID="REPLACE_ME"
curl -sS -X DELETE \
  "http://127.0.0.1:5100/api/v1/activities/$ACTIVITY_ID" \
  -H "Authorization: Bearer $TOKEN" | jq '.'
```

## Notes on kudos/comments/share
Frontend currently does not call these endpoints. Add curls here if UI starts using:
- POST /activities/{id}/kudos
- GET/POST /activities/{id}/comments
- POST /activities/{id}/share
