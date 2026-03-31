# Community API debugging with curl

## Investigation summary (what a healthy vs broken stack looks like)

| curl | Typical HTTP | Meaning |
|------|----------------|--------|
| `GET /health` | 200 | Service up (Docker or local). |
| `GET /api/v1/subthreads` | 200 | Public read OK. |
| `GET /api/v1/feed` | 200 | **Global community posts feed** (use this URL; see below). |
| `GET /api/v1/feed` | **404** + `{"detail":"Not Found"}` | **Stale process or image** — nothing registered that path (restart/rebuild so **`main.py`** includes `GET /api/v1/feed`). See **Rebuild community** below. |
| `GET http://127.0.0.1:8080/api/v1/posts/feed` | **404** | **Wrong service** — main-backend has **no** `/api/v1/posts/*` routes. |
| `GET …/api/v1/posts/feed` returns **422** | — | Route removed as feed endpoint. Path is interpreted as `/{post_id}` and fails UUID validation. Use **`GET /api/v1/feed`**. |
| `POST /api/v1/posts` **no** `Authorization` | 401, **Token is missing** | Expected. |
| `POST /api/v1/posts` **bad** `Bearer` | 401, **Invalid token** | JWT not signed with this service’s secret, malformed, or expired. |
| App fails while `GET` works | — | Wrong simulator base URL **or** Bearer rejected → **align JWT secrets** (below). |

### Fix for `401` + `Invalid token` when the Flutter app is logged in

Access tokens are created by **main-backend** using **`SECRET_KEY`**. **community-backend** verifies them using **`JWT_SECRET`**. Those two values **must be identical** (restart the community container/process after changing `.env`).

1. Copy **`SECRET_KEY`** from `backend/main-backend/.env` into **`JWT_SECRET`** in `backend/community-backend/.env` (same string).
2. Restart community:

```bash
cd backend && docker compose restart community-backend
```

(or restart local `python run.py` for community-backend).

3. **Log in again** in the app so you get a token signed with the current secret (if you changed it).

---

Use the commands below when the app shows “Unable to load data”, 401s, or you suspect Docker vs local process confusion.

Base URL (set `BASE`):

- Host hitting Docker: `http://127.0.0.1:5001`
- Android emulator from app: `http://10.0.2.2:5001` (not `127.0.0.1`)

```bash
export BASE='http://127.0.0.1:5001'
```

### Rebuild community (Docker) — run from **`backend/`**, not from **`community-backend/`**

If `curl "$BASE/api/v1/feed"` returns **`404`** with **`{"detail":"Not Found"}`**, the container is still an **old image** without the `/api/v1/feed` route. **`docker compose` must be run from the directory that contains `docker-compose.yml`** (the **`backend`** folder at the repo root), e.g.:

```bash
cd /path/to/syntrak-application/backend
docker compose build community-backend && docker compose up -d community-backend
```

If your shell is already inside **`community-backend`**, use **`cd ..`** (parent is **`backend`**) instead of **`cd backend`** (that subdirectory does not exist there and the command fails).

**Or** stop Docker on port **5001** and run the app locally so the current tree is loaded:

```bash
cd /path/to/syntrak-application/backend/community-backend
python run.py
```

Confirm the route exists (optional):

```bash
curl -sS "$BASE/openapi.json" | python3 -c "import sys,json; p=json.load(sys.stdin).get('paths',{}); print([k for k in p if 'feed' in k])"
```

You should see **`/api/v1/feed`** only.

### 1) Health, subthreads, and **global posts feed** (no auth)

**Use community-backend** (`BASE=http://127.0.0.1:5001`). The **only canonical feed path** is **`GET /api/v1/feed`**.

```bash
curl -sS -w "\nHTTP_CODE:%{http_code}\n" "$BASE/health"
curl -sS -w "\nHTTP_CODE:%{http_code}\n" "$BASE/api/v1/subthreads?limit=2"
curl -sS -w "\nHTTP_CODE:%{http_code}\n" "$BASE/api/v1/feed?limit=5"
```

Expect **200** and JSON with `items` and `meta` (empty `items` is fine if there are no posts in Supabase).

### 2) POST without token (expect 401 Token is missing)

```bash
curl -sS -w "\nHTTP_CODE:%{http_code}\n" \
  -X POST "$BASE/api/v1/posts/" \
  -H "Content-Type: application/json" \
  -d '{"subthread_id":"<uuid>","title":"t","content":"c"}'
```

### 3) POST with invalid Bearer (expect 401 Invalid token)

```bash
curl -sS -w "\nHTTP_CODE:%{http_code}\n" \
  -X POST "$BASE/api/v1/posts/" \
  -H "Authorization: Bearer invalid" \
  -H "Content-Type: application/json" \
  -d '{"subthread_id":"<uuid>","title":"t","content":"c"}'
```

### 4) POST with real token (expect 401 if you skip this)

**Do not** leave the placeholder text in the command. The shell will send the **literal characters** `paste_access_token_from_login` (or `<paste access_token from login>`) as the token — the API will always return **401 Invalid token**.

Get a real access token from main-backend login, then export **only** the JWT string (three dot-separated segments, no quotes inside the value except what the shell needs):

```bash
export MAIN='http://127.0.0.1:8080/api/v1'
# Replace with your test user email/password:
TOKEN=$(curl -sS -X POST "$MAIN/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"YOUR_EMAIL","password":"YOUR_PASSWORD"}' \
  | python3 -c "import sys,json; print(json.load(sys.stdin).get('access_token',''))")

echo "Token length (expect hundreds of chars): ${#TOKEN}"
```

If `TOKEN` is empty, login failed (wrong credentials or main-backend not on 8080).

Then:

```bash
curl -sS -w "\nHTTP_CODE:%{http_code}\n" \
  -X POST "$BASE/api/v1/posts/" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"subthread_id":"e0190e23-b30c-4425-aa73-4b5ecc4670d0","title":"curl","content":"hello"}'
```

Expect **201** if `JWT_SECRET` in community matches main-backend `SECRET_KEY` and the subthread exists.

**Trailing slash on create post:** `POST /api/v1/posts` (no slash) returns **307** to `/api/v1/posts/`. Flutter’s Dio can mishandle **POST** redirects and the request fails (“Unable to load data”). The app uses **`/posts/`** directly. Use the same in curl tests.

### 5) Docker: port and exec

```bash
docker ps --filter name=syntrak-community-backend
docker exec syntrak-community-backend curl -sS http://127.0.0.1:5001/health
```

### 6) Pretty JSON

```bash
curl -sS "$BASE/api/v1/subthreads?limit=2" | python3 -m json.tool
```
