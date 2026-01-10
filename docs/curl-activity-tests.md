# Syntrak Auth + Activity API curl walkthrough (macOS/zsh)

This guide registers/logs in a test user, then exercises all Activity API endpoints using that identity.

- Auth API: http://localhost:8080
- Activity API: http://127.0.0.1:5100
- Requires `jq` (install with `brew install jq` on macOS)

Note on password length: the Auth API requires a minimum of 8 characters. The requested password "test" is too short, so this guide uses "test12345" instead. If you need a different password, adjust the `PASSWORD` variable.

---

## Environment

```bash
# Base URLs (change if your hosts/ports differ)
AUTH_BASE="http://localhost:8080"
ACTIVITY_BASE="http://localhost:5100"

# Test identity
EMAIL="test_jane_doe@example.com"
FIRST_NAME="Jane"
LAST_NAME="Doe"
PASSWORD="test12345"  # "test" is too short; auth requires >= 8 chars
```

---

## 1) Register test user (Auth API)

```bash
REG_JSON=$(curl -sS -X POST "$AUTH_BASE/api/v1/auth/register" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\",\"first_name\":\"$FIRST_NAME\",\"last_name\":\"$LAST_NAME\"}")

echo "$REG_JSON" | jq .

# Extract tokens and user id (from register response)
ACCESS_TOKEN=$(echo "$REG_JSON" | jq -r '.access_token')
REFRESH_TOKEN=$(echo "$REG_JSON" | jq -r '.refresh_token')
USER_ID=$(echo "$REG_JSON" | jq -r '.user.id')

echo "ACCESS_TOKEN=${ACCESS_TOKEN}"
echo "USER_ID=${USER_ID}"
```

If the email is already registered (HTTP 409), login instead:

```bash
LOGIN_JSON=$(curl -sS -X POST "$AUTH_BASE/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")

echo "$LOGIN_JSON" | jq .

ACCESS_TOKEN=$(echo "$LOGIN_JSON" | jq -r '.access_token')
REFRESH_TOKEN=$(echo "$LOGIN_JSON" | jq -r '.refresh_token')
USER_ID=$(echo "$LOGIN_JSON" | jq -r '.user.id')

echo "ACCESS_TOKEN=${ACCESS_TOKEN}"
echo "USER_ID=${USER_ID}"
```

---

## 2) Create an activity (Activity API)

```bash
CREATE_JSON=$(curl -sS -X POST "$ACTIVITY_BASE/api/v1/activities" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Morning Ski Session",
    "activity_type": "ski",
    "gps_path": [
      {"lat": 39.605, "lng": -105.941, "elevation": 3048.0, "timestamp": "2025-12-01T08:00:00Z"},
      {"lat": 39.606, "lng": -105.942, "elevation": 3052.0, "timestamp": "2025-12-01T08:05:00Z"}
    ],
    "duration_seconds": 5400,
    "distance_meters": 12000.5,
    "elevation_gain_meters": 450.0,
    "visibility": "public",
    "description": "Bluebird day on the mountain"
  }')

echo "$CREATE_JSON" | jq .

ACTIVITY_ID=$(echo "$CREATE_JSON" | jq -r '.id')
echo "ACTIVITY_ID=${ACTIVITY_ID}"
```

---

## 3) List public activities

```bash
curl -sS "$ACTIVITY_BASE/api/v1/activities" | jq .
```

---

## 4) List my activities

```bash
curl -sS "$ACTIVITY_BASE/api/v1/activities/me" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq .
```

---

## 5) Get activity by id

```bash
curl -sS "$ACTIVITY_BASE/api/v1/activities/$ACTIVITY_ID" | jq .
```

---

## 6) Update the activity

```bash
UPDATE_JSON=$(curl -sS -X PUT "$ACTIVITY_BASE/api/v1/activities/$ACTIVITY_ID" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Morning Ski Session (Edited)",
    "description": "Added a few tree runs",
    "visibility": "followers"
  }')

echo "$UPDATE_JSON" | jq .
```

---

## 7) Toggle kudos (like/unlike)

```bash
curl -sS -X POST "$ACTIVITY_BASE/api/v1/activities/$ACTIVITY_ID/kudos" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq .
```

---

## 8) List comments

```bash
curl -sS "$ACTIVITY_BASE/api/v1/activities/$ACTIVITY_ID/comments" | jq .
```

---

## 9) Add a comment

```bash
COMMENT_JSON=$(curl -sS -X POST "$ACTIVITY_BASE/api/v1/activities/$ACTIVITY_ID/comments" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"content":"Awesome laps today!"}')

echo "$COMMENT_JSON" | jq .
```

---

## 10) Create a share link

```bash
SHARE_JSON=$(curl -sS -X POST "$ACTIVITY_BASE/api/v1/activities/$ACTIVITY_ID/share" \
  -H "Authorization: Bearer $ACCESS_TOKEN")

echo "$SHARE_JSON" | jq .

SHARE_TOKEN=$(echo "$SHARE_JSON" | jq -r '.share_token')
SHARE_URL=$(echo "$SHARE_JSON" | jq -r '.share_url')
echo "SHARE_TOKEN=${SHARE_TOKEN}"
echo "SHARE_URL=${SHARE_URL}"
```

---

## 11) Delete the activity

```bash
curl -sS -X DELETE "$ACTIVITY_BASE/api/v1/activities/$ACTIVITY_ID" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq .
```

---

## Tips

- If the Activity API returns 401, ensure the Activity service `JWT_SECRET` matches the Auth API’s `SECRET_KEY`.
- If Supabase isn’t configured for the Activity service, configure `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` in its `.env`.
- You can re-run the login step to refresh `ACCESS_TOKEN` at any time.
