## 1. Overview & Purpose

### Folder name & path


| Area                               | Path                                                                                                                                                     |
| ---------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Community API (FastAPI + Supabase) | `/backend/community-backend/`                                                                                                                            |
| Community feature (Flutter client) | `/frontend/lib/features/community/`, `/frontend/lib/screens/community/`, `/frontend/lib/services/` (`community_service.dart`, `apis/community_api.dart`) |
| Error / result primitives          | `/frontend/lib/core/errors/` (`app_error.dart`, `app_result.dart`)                                                                                       |
| This document                      | `/docs/community/community_threads_implementation.md`                                                                                                    |


### Technical purpose

The community stack implements a **Threads-like** social feed: **subthreads** (topics), **posts**, and **nested comments**, backed by **Supabase (Postgres + PostgREST)** via the official Supabase Python client—not GraphQL. The goals of this implementation are:

- **Feed loading:** `**GET /api/v1/feed`** returns a **global** feed (all subthreads, newest first). The app uses this path so it is never mistaken for `**GET /api/v1/posts/{post_id}`**. Comments load via **batch** (no N+1). Posting still targets a **default subthread** (prefers **“Chat”** or **“Main”** depending on client seeding, else the first listed).
- **Engagement fields:** feed items include `like_count`, `liked_by_current_user`, `repost_count`, and `reposted_by_current_user` (post repost markers + **duplicate repost** rows counted toward `repost_count`).
- **Repost (persisted toggle):** `POST /api/v1/posts/{post_id}/repost` and `DELETE /api/v1/posts/{post_id}/repost` write to `post_reposts`; counts hydrate in read paths.
- **Repost (duplicate to feed) & Quote:** Creating a post can set `repost_of_post_id` (verbatim duplicate of a post’s body into the feed) and/or `quoted_post_id` (new post with embedded quoted preview). **Comments** support the same ideas via `repost_of_comment_id` and `quoted_comment_id` (see §2.1).
- **Thread detail:** Tapping a feed post opens `**ThreadDetailScreen`**, which loads `**GET /api/v1/posts/{post_id}/conversation**` (same payload as comments), renders the OP plus flat/nested comment rows, bottom reply bar, and wires **like / repost / share** on the OP and **reply / repost** on comments (comment like/share remain stubs unless extended).
- **New-thread draft:** `**NewThreadDraftScreen`** supports optional topic line and **quote** flow (post or comment); result drives `createPost` with the correct FK field.
- **Correct failures:** Surface **typed errors** and **retryability** to the UI instead of empty lists when the API or parsing fails.

### Subthreads vs “Threads” UX (important)

The **product** can feel like a single Threads-style feed, but the **data model** still has a `**subthreads` row** as the parent for posts (`posts.subthread_id`). That is unrelated to JWT correctness: a valid token only proves **who** is posting, not **where**. Reads that work after manual SQL edits usually mean you already have consistent `**subthreads` + `posts`** rows (or you edited data the client loads). **Creating a post** still calls `POST /posts` with `subthread_id`, and the backend checks that the subthread exists—so if `GET /subthreads` returned **empty**, the app previously had **no** `_activeSubthreadId` and compose could not succeed.

The Flutter **Threads** tab now **auto-creates** a default subthread named `**Main`** when the list is empty (once per session path), so you do not have to seed `subthreads` by hand for local testing—unless your DB forbids duplicate names or creation fails.

### Ownership

Maintain this document and the listed paths with the team that owns **Syntrak community + mobile**. Update the table below when ownership changes.


| Role                        | Owner (fill in) |
| --------------------------- | --------------- |
| Primary                     | *TBD*           |
| Backend (community-backend) | *TBD*           |
| Flutter client              | *TBD*           |


### Dependencies

**Backend**

- FastAPI, Pydantic, `supabase-py` (PostgREST).
- Supabase project: URL + service role key via `community-backend` config.
- Shared middleware / list envelopes under repo `shared` (request id, `ListResponse`, exception handlers).

**Frontend**

- `dio` (community base URL from app config / service locator).
- `CommunityRepository` → `CommunityApi` → REST paths under `/api/v1` (prefix configured on Dio).
- `AppResult` / `AppError` for service boundaries.

**Database**

- Supabase tables: `subthreads`, `posts`, `comments` (comments support `parent_id` for nesting), `user_info` join for author fields.
- Engagement tables / columns (see `backend/community-backend/supabase_post_engagement.sql`): `post_votes`, `post_reposts`, `posts.quoted_post_id`, `posts.repost_of_post_id`, `posts.quoted_comment_id`, `posts.repost_of_comment_id`.

### 2.1 How repost & quote work (implementation summary)


| Mechanism                                                | Posts                                                                                 | Comments                                                                                                                                                                     |
| -------------------------------------------------------- | ------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **“Repost” toggle** (bookmark-style)                     | `post_reposts` + hydrate on post reads                                                | *Not implemented* (comments use duplicate repost only today).                                                                                                                |
| **Duplicate repost** (new row in `posts`, shows in feed) | `POST /posts/` body: `repost_of_post_id`, copy `content`/`title` pattern from client  | Same endpoint with `**repost_of_comment_id`**; new post’s text is the comment body; `**subthread_id**` comes from the thread’s post (`Post.subthreadId` on mapped comments). |
| **Quote**                                                | `quoted_post_id` + optional commentary; read path hydrates `quoted_post` from `posts` | `**quoted_comment_id`**; read path hydrates `quoted_comment` from `**comments**` (+ author join).                                                                            |


**Backend hydration**

- `**CommunityPostReadOperations._attach_engagement_fields`:** merges `post_votes` (likes), `post_reposts`, and **counts of posts** with `repost_of_post_id` (duplicate reposts), plus per-user flags.
- `**CommunityPostReadOperations._hydrate_quoted_posts` / `_hydrate_quoted_comments`:** batch-fetch targets and attach nested previews for list/get responses.
- `**CommunityCommentReadOperations._attach_comment_engagement_fields`:** counts **posts** where `repost_of_comment_id` ∈ comment ids; optional user flag for “current user already duplicate-reposted this comment.”

**Authenticated comment lists**

- `GET .../comments`, `GET .../conversation`, and `**POST .../comments/batch`** accept `**get_optional_user**` so comment payloads include accurate `**reposted_by_current_user**` when a JWT is present.

**Flutter mapping**

- `**Post`** carries `**isComment**`, `**parentPostId**`, `**subthreadId**` on comments (for choosing subthread on repost), `**quotedComment` / `quotedCommentId**`, plus existing quote/repost fields for posts.
- `**CommunityPostMapper.mapCommentToPost**` receives `**threadSubthreadId**` and `**parentPostId**` from the thread root when building replies from API JSON.
- `**threads_tab`:** `_showRepostOptions` → **Repost** calls `_duplicateRepostPost` (post vs comment branch) → **Quote** opens `**NewThreadDraftScreen`**; `**NewThreadDraftResult**` sets `**quotedPostId**` or `**quotedCommentId**` from `**quotedPost.isComment**`.
- `**thread_detail_screen`:** comment rows use the same `**onRepost`** callback as the OP so the bottom sheet and create flow match the feed.

---

## 2. Architecture & Design

### High-level design

```text
Flutter UI (Threads tab, profile)
        │
        ▼
CommunityService  ──▶  CommunityRepository  ──▶  CommunityApi (Dio)
        │                         │
 AppResult<T>                  REST JSON
 AppError (Dio / parse)

        HTTP
        ▼
community-backend (FastAPI)
        │
        ▼
CommunitySupabaseClient  ──▶  Supabase / PostgREST
 (post / comment / subthread operations)
```

**Feed path (batched comments)**

1. `GET /api/v1/subthreads` → pick active subthread.
2. `GET /api/v1/subthreads/{id}/posts` → list of posts.
3. `POST /api/v1/posts/comments/batch` with `{ "post_ids": [...] }` → **one** DB round trip (`.in_("post_id", ids)`), grouped and sorted per post in Python.

**Single-post comments (legacy / detail)**

- `GET /api/v1/posts/{post_id}/comments` — paginated `ListResponse` envelope (`items` + `meta`).
- `GET /api/v1/posts/{post_id}/conversation` — **same payload** as comments; naming parity with Threads public API docs (`/conversation`).

### Key design patterns


| Pattern                      | Where                                                              | Why                                                                                                                |
| ---------------------------- | ------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------ |
| **Repository**               | `CommunityRepository`                                              | Hides HTTP from the rest of the app; single place to swap API or add caching.                                      |
| **Result type**              | `AppResult` / `AppSuccess                                          | AppFailure`                                                                                                        |
| **Thin API adapter**         | `CommunityApi`                                                     | Strict JSON parsing; throws `FormatException` on bad shapes so failures become `AppFailure`, not fake empty lists. |
| **Mixin-style Supabase ops** | `Community*ReadOperations` composed into `CommunitySupabaseClient` | Splits read/write concerns without inheritance explosion.                                                          |


### Data contracts / models

**Batch comments**

- **Request:** `CommentsBatchRequest`: `{ "post_ids": string[] }`
  - Server **dedupes** preserves first-seen order.
  - Max **50** distinct IDs per request (`422` if exceeded).
- **Response:** `CommentsBatchResponse`: `{ "items": [ { "post_id": string, "comments": CommunityCommentResponse[] } ] }`
  - Order of `items` matches deduped request order.
  - Missing posts still appear with `comments: []`.

**Comment row (API)**

- `CommunityCommentResponse`: `id`, `user_id`, `post_id`, `parent_id`, `content`, `has_parent`, `created_at`, optional author fields, plus `**repost_count`** and `**reposted_by_current_user**` (derived from **posts** whose `repost_of_comment_id` points at this comment).

**Post row (API) — quotes & duplicate reposts**

- `CommunityPostResponse` includes optional `**quoted_post_id`** + hydrated `**quoted_post**` (preview), `**repost_of_post_id**`, `**quoted_comment_id**` + hydrated `**quoted_comment**` (preview), `**repost_of_comment_id**`.
- `**PostCreate**` accepts the same FK fields; validation enforces **at most one quote target** (`quoted_post_id` XOR `quoted_comment_id`) and **at most one duplicate-repost target** (`repost_of_post_id` XOR `repost_of_comment_id`), with `404` if the referenced row is missing.

**List envelope (Graph-style lists)**

- Many list endpoints use `ListResponse`: `items` + `meta` (`request_id`, `pagination` with `limit`, `offset`, `total`, `has_next`).

**Flutter batch map**

- `getCommentsForPosts` returns `Map<String, List<Map<String, dynamic>>>` keyed by `post_id`.

### External integrations


| System             | Usage                                                                                                                  |
| ------------------ | ---------------------------------------------------------------------------------------------------------------------- |
| **Supabase**       | Primary store for community data; accessed only from `community-backend` with service role for server-side operations. |
| **Community REST** | Flutter talks only to `community-backend`, not directly to Supabase.                                                   |


---

## 3. Code structure & key components

### Backend file map


| File                                            | Role                                                                                                                                                         |
| ----------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `main.py`                                       | FastAPI app, router mount `/api/v1`, lifespan Supabase init.                                                                                                 |
| `services/supabase_client.py`                   | `CommunitySupabaseClient` composition.                                                                                                                       |
| `services/community_comment_read_operations.py` | `list_comments_by_post`, `list_comments_by_post_ids` (batch), author flattening, `**_attach_comment_engagement_fields`** (duplicate repost of comments).     |
| `services/community_post_read_operations.py`    | Post listing by subthread / user / global feed, `get_post_by_id`, engagement hydrate, `**_hydrate_quoted_posts**`, `**_hydrate_quoted_comments**`.           |
| `services/community_post_write_operations.py`   | `create_post` (including quote / duplicate-repost FKs), votes, repost toggle, update/delete.                                                                 |
| `supabase_post_engagement.sql`                  | DDL for votes, reposts, quote / repost FK columns on `posts` (run in Supabase SQL editor).                                                                   |
| `routes/posts_read_routes.py`                   | `POST /comments/batch`, `GET /{post_id}/comments`, `GET /{post_id}/conversation`, user post list, get post (optional user on comment routes for engagement). |
| `routes/posts_write_routes.py`                  | `POST /posts/` create with validation for quote / duplicate-repost targets; `**POST/DELETE .../repost**`.                                                    |
| `routes/community_models.py`                    | Pydantic: batch types, comment/post DTOs.                                                                                                                    |
| `routes/list_response_builder.py`               | Builds `ListResponse` for paginated endpoints.                                                                                                               |
| `tests/conftest.py`                             | `StubCommunityClient` for API tests.                                                                                                                         |
| `tests/test_community_api.py`                   | HTTP-level tests including batch + conversation.                                                                                                             |


### Frontend file map


| File                             | Role                                                                                                                             |
| -------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| `community_api.dart`             | `getCommentsForPosts`, strict list parsing, other REST methods.                                                                  |
| `community_repository.dart`      | Pass-through to API.                                                                                                             |
| `community_service.dart`         | Wraps repository in `AppResult` via `_run`.                                                                                      |
| `threads_tab.dart`               | Feed load, compose, **repost sheet**, duplicate/quote create, optimistic + outbox retry, navigation to `**ThreadDetailScreen`**. |
| `threads_tab_action_coordinator.dart` | Write-action application coordinator for post/repost/reply + outbox enqueue payload construction. |
| `threads_tab_sync_coordinator.dart` | Outbox retry coordinator using operation handler registry (strategy map) instead of long branch chains. |
| `threads_tab_feedback.dart`      | Centralized user-facing error/wait SnackBar messaging for feed actions. |
| `threads_tab_post_state.dart`    | Stateless list mutation helpers for optimistic/confirmed post and reply transitions. |
| `thread_detail_screen.dart`      | Conversation reload, OP + comment list, bottom reply bar, **repost on comments**.                                                |
| `new_thread_draft_screen.dart`   | New thread / **quote** composer; `**NewThreadDraftResult`** (topic + quoted post/comment ids).                                   |
| `widgets/quoted_post_embed.dart` | Bordered embed for **quoted post or quoted comment** (same `Post` UI shape).                                                     |
| `widgets/message_card.dart`      | Feed card; shows `**quotedPost` or `quotedComment`** embed.                                                                      |
| `widgets/message_actions.dart`   | Like / repost / reply / share strip (call sites pass handlers).                                                                  |
| `models/post.dart`               | `**Post**` / `**PostAuthor**` including `**isComment**`, parent/subthread ids, quote fields.                                     |
| `community_post_mapper.dart`     | JSON → `Post`, `**mapRepliesFromComments**` (thread context), `**mapQuotedCommentPreview**`.                                     |
| `app_error.dart`                 | `AppError.from`, Dio + `FormatException`, `**retryable**`.                                                                       |


### Entry points

**Backend**

- `POST /api/v1/posts/comments/batch` — batch comments for feed.
- `GET /api/v1/posts/{post_id}/conversation` — alias for full comment list on one thread.
- `GET /health` — service liveness.

**Flutter**

- `CommunityService.getCommentsForPosts(postIds)` — preferred for feed pages.
- `CommunityService.getPostConversation(postId)` — **thread detail** (same API shape as comments list).
- `CommunityService.createPost(...)` — supports `**quotedPostId`**, `**repostOfPostId**`, `**quotedCommentId**`, `**repostOfCommentId**`.

### Critical logic

### Maintainability refactor (April 2026)

- `ThreadsTab` was reduced in responsibility by moving write orchestration into `threads_tab_action_coordinator.dart`.
- Outbox retry logic now uses a handler registry in `threads_tab_sync_coordinator.dart` (`operation type -> handler`) for easier extension.
- Repeated user feedback code moved to `threads_tab_feedback.dart`.
- Repeated post/reply transition code moved to small helper methods and `threads_tab_post_state.dart` operations.
- Community backend runtime dependency now pins `python-multipart==0.0.22` in `backend/community-backend/requirements.txt` to avoid startup failures when form endpoints are mounted.

These changes target SRP/OCP/KISS:

- SRP: UI widget focuses on state orchestration and rendering; action coordinators own write-side side effects.
- OCP: add outbox operation types by registering a new handler, not modifying long `if/else` chains.
- KISS: shared helper functions remove duplicated state mutation and repeated message-building logic.

**Batch grouping (Supabase)**

```text
ordered_post_ids = dedupe(request.post_ids)   # cap 50
rows = SELECT * FROM comments WHERE post_id IN ordered_post_ids  -- joined with user_info
group rows by post_id in memory
sort each group by created_at ascending
return one bundle per post_id in ordered_post_ids (empty list if no rows)
```

**Flutter feed**

```text
posts = getPostsBySubthread(...)
ids = post_ids from posts
byPost = getCommentsForPosts(ids)   // single HTTP POST
for each rawPost in posts:
  map Post with byPost[post_id] ?? []
```

### Configuration

**Backend (`community-backend/config.py` environment)**

- `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`
- `HOST`, `PORT`, `CORS_ORIGINS`, `FASTAPI_ENV`

**Frontend**

- `COMMUNITY_API_BASE_URL` (dart-define / `AppConfig`) — must end at `/api/v1` or match Dio `baseUrl` + path conventions.

---

## 4. Development & maintenance guidelines

### Setup (backend)

From repo root (adjust for your venv/tooling):

```bash
cd backend/community-backend
# install deps per project README / requirements
python -m pytest tests/test_community_api.py -q
```

Ensure `pydantic-settings`, `fastapi`, `pytest`, and `supabase` are installed in the active environment.

### Setup (frontend)

```bash
cd frontend
dart pub get
dart analyze lib/
```

### Testing strategy


| Layer      | What to test                                                                                                                                                                                                                                             |
| ---------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| API        | `tests/test_community_api.py`: batch shape, 422 on >50 IDs, conversation equals comments for same post; **create post** with `**repost_of_comment_id`** / `**quoted_comment_id**`; **422** when quoting post and comment together; repost toggle routes. |
| Operations | `test_operations_units.py`: fake `**FakeQuery.in_`** supports comment engagement queries on `posts`.                                                                                                                                                     |
| Flutter    | Widget/integration tests for error vs empty feed (recommended); repost sheet + thread detail (recommended); unit test `CommunityApi` parsing with fake Dio if added later.                                                                               |


### Code standards

- **Python:** Match existing FastAPI + Pydantic style; log exceptions in service layer.
- **Dart:** Match existing `syntrak` lints; services return `AppResult`, not raw throws.

### Common pitfalls


| Issue                         | Mitigation                                                                                                              |
| ----------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| **N+1 revived**               | Always use `POST .../comments/batch` for multi-post screens; avoid looping `getCommentsByPost` in the client for feeds. |
| **Empty feed on bad JSON**    | `CommunityApi` must not default unknown shapes to `[]`; parsers throw `FormatException`.                                |
| **PostgREST `in` URL length** | Cap batch size (50); paginate feeds if needed.                                                                          |
| **Author join**               | Batch query must use the same `user_info` foreign-key join as single-post comment list for consistent DTOs.             |


### Logging & monitoring

- Backend: Python `logging` on exceptions in routes and `logger.exception` in read operations.
- Optional: correlate with `X-Request-ID` from shared middleware.
- Client: rely on `AppError` for user copy; log `cause` / stack in debug builds as needed.

---

## 5. Deployment & operations

### Build / deployment

- Deploy `community-backend` as an independent service with Supabase credentials injected via env (never commit secrets).
- Flutter app points Dio `baseUrl` at the deployed community API.

### Runtime requirements

- Network egress to Supabase REST endpoint.
- Typical small instance suffices; load is bounded by feed page size and batch cap.

### Health checks

- `GET /health` on community-backend returns `{ "status": "healthy", "service": "community-backend" }`.

### Backward compatibility

- **Additive:** `POST /posts/comments/batch` and `GET /posts/{id}/conversation` are newer paths; existing `GET .../comments` unchanged in spirit (response gains optional `**repost_count`** / `**reposted_by_current_user**` on comments—clients that ignore unknown keys stay safe).
- **Additive:** `PostCreate` / post JSON may include `**quoted_comment_id`**, `**repost_of_comment_id**`, and nested `**quoted_comment**`; older clients never send them.
- **Clients:** Older apps can keep per-post comment GETs; new app versions should prefer batch for feeds.

---

## 6. Examples & usage

### cURL: batch comments

```bash
curl -s -X POST "$COMMUNITY_API/api/v1/posts/comments/batch" \
  -H "Content-Type: application/json" \
  -d '{"post_ids":["<uuid-1>","<uuid-2>"]}'
```

Example success shape:

```json
{
  "items": [
    { "post_id": "<uuid-1>", "comments": [ /* ... */ ] },
    { "post_id": "<uuid-2>", "comments": [] }
  ]
}
```

### cURL: conversation (same as comments list)

```bash
curl -s "$COMMUNITY_API/api/v1/posts/<post_id>/conversation"
```

### Flutter: load feed with batch

```dart
final posts = await communityService.getPostsBySubthread(subthreadId, limit: 20);
// posts fold...
final ids = postsData.map((p) => p['post_id'].toString()).where((s) => s.isNotEmpty).toList();
final batch = await communityService.getCommentsForPosts(ids);
// batch fold: map each post with comments = byPost[id] ?? [];
```

### Integration scenario

**Threads tab:** `ThreadsTab._loadFeed` loads subthreads, then posts for the active subthread, then `**getCommentsForPosts`** once, then `CommunityPostMapper.mapBackendPost` per row. On failure, `**_feedError**` shows message and **Retry** when `AppError.retryable` is true.

---

## 7. Verification checklist (local & simulator)

Use this in order when feed load or posting fails with generic messages (“Unable to load data”, “Could not send post: …”).

For **step-by-step curl** (health, subthreads, POST with token, Docker vs host, port conflicts), see `[community_debug_curl.md](./community_debug_curl.md)`.

### A. Community service is reachable


| Step | Action                                                     | Pass criteria                                                                 |
| ---- | ---------------------------------------------------------- | ----------------------------------------------------------------------------- |
| A1   | From your Mac: `curl -s http://127.0.0.1:5001/health`      | JSON includes `"status":"healthy"` (adjust host/port if your `.env` differs). |
| A2   | Same for `curl -s http://127.0.0.1:5001/api/v1/subthreads` | `200` and JSON with `items` (may be empty array).                             |


If A1 fails, fix **process not running**, **wrong port**, or **firewall** before debugging the app.

### B. Flutter points at the same host the simulator can use


| Runtime              | Typical `communityApiBaseUrl`          | Notes                                                                                                                                            |
| -------------------- | -------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| **iOS Simulator**    | `http://127.0.0.1:5001/api/v1`         | Matches dev default in `AppConfig` (`_defaultsFor` dev).                                                                                         |
| **Android Emulator** | `http://10.0.2.2:5001/api/v1`          | `**127.0.0.1` is the emulator itself**, not your Mac—override via `AppConfig.setRuntimeOverrides` or `--dart-define=COMMUNITY_API_BASE_URL=...`. |
| **Physical device**  | `http://<your-mac-lan-ip>:5001/api/v1` | Same Wi‑Fi; not `localhost`.                                                                                                                     |


Where it is set: `frontend/lib/core/config/app_config.dart` (defaults + overrides). Dio uses it in `DioFactory.buildCommunityClient()`.

Verify in app: ensure no stale **SharedPreferences** override points at an old URL (`override_community_api_base_url`).

### C. Auth token matches community-backend


| Step | Action                                                                                                                                                                         | Pass criteria                                                                        |
| ---- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------ |
| C1   | `**JWT_SECRET`** in **community-backend** `.env` equals `**SECRET_KEY`** in **main-backend** `.env` (same string). Tokens are minted by main-backend; community only verifies. | Posting returns `201` with a real `post_id`, not `401 Invalid token`.                |
| C2   | Token is sent on community calls                                                                                                                                               | `DioFactory` adds `Authorization: Bearer <token>` when `AuthTokenStore` has a token. |


Quick API test (replace `TOKEN` and ids):

```bash
curl -s -o /dev/stderr -w "%{http_code}" -X POST "http://127.0.0.1:5001/api/v1/posts/" \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"subthread_id":"<uuid>","title":"t","content":"c"}'
```

Expect `**201**` if subthread exists and JWT is valid.

### D. Subthreads and posts data model


| Step | Action                                                                                                              | Pass criteria                                                                                       |
| ---- | ------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| D1   | At least one row in Supabase `**subthreads**`, or rely on app **auto-create** of `**Main`** when the list is empty. | `GET /api/v1/subthreads` returns at least one item after first load, or after auto-create succeeds. |
| D2   | New posts use a `**subthread_id` that exists** in `subthreads`.                                                     | `create_post` does not return `404` “Subthread not found”.                                          |


### E. Feed and batch endpoints


| Step | Action                                                                  | Pass criteria                              |
| ---- | ----------------------------------------------------------------------- | ------------------------------------------ |
| E1   | `GET /api/v1/subthreads/{id}/posts`                                     | `200`, `items` array (may be empty).       |
| E2   | `POST /api/v1/posts/comments/batch` with `{"post_ids":[]}` or a few ids | `200`, `items` array aligned with request. |


### F. Supabase and RLS


| Step | Action                                                                       | Pass criteria                                                                                                   |
| ---- | ---------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| F1   | Service uses **service role** on the server for inserts (community-backend). | Inserts succeed from API; if RLS blocks the **anon** client, that should not apply to server-side service role. |
| F2   | After a successful post, row appears in `**posts`** in Supabase dashboard.   | Confirms DB path, not only UI cache.                                                                            |


### G. Interpreting generic app errors

- `**Unable to load data**` with **no** clearer text often means **no HTTP status** (connection refused, wrong URL, TLS). Check **B** and **A**.
- `**AppError` now also surfaces `DioException.message` and FastAPI `detail` lists** (422) where possible—if you still see a generic line, capture logs or run the same request with **curl**.

### H. iOS-specific (only if using plain HTTP)

If you ever use **http** (not https) to a non-localhost host, **App Transport Security** may block; localhost on simulator is normally fine for dev.

### I. Quote / comment-repost schema (Supabase)


| Step | Action                                                                                                                                             | Pass criteria                                                                                   |
| ---- | -------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| I1   | Run `**supabase_post_engagement.sql`** updates so `**posts**` has `**quoted_comment_id**` and `**repost_of_comment_id**` (FK → `**comments.id**`). | Inserts from the app with those fields succeed; missing columns cause insert or hydrate errors. |
| I2   | `POST /api/v1/posts/` with `repost_of_comment_id` or `quoted_comment_id` referencing a real comment                                                | `201` and response JSON includes the FK fields.                                                 |


Example (auth + valid ids):

```bash
curl -s -X POST "$COMMUNITY_API/api/v1/posts/" \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"subthread_id":"<uuid>","title":"Comment repost","content":"Original text…","repost_of_comment_id":"<comment-uuid>"}'
```

---

## 8. Feature implementation notes & refactor directions

This section summarizes **how** the Threads-like features were built (for onboarding and code review) and **where** the design could evolve.

### 8.1 Thread detail screen

**What:** Full-screen view for one thread: original post, divider, “conversation” comments, bottom composer that submits a **top-level comment** on the thread post via existing `**createComment`** APIs.

**How:** `ThreadsTab._openThreadDetail` pushes `**ThreadDetailScreen`** with callbacks into the tab (`onSubmitReply`, `onLike`, `onRepost`, `onShare`). Conversation refresh uses `**CommunityService.getPostConversation**`, then `**CommunityPostMapper.mapRepliesFromComments**` with `**threadSubthreadId**` and `**parentPostId**` so each mapped comment `Post` knows which **subthread** and **thread post id** to use for duplicate reposts.

**Refactor:** Extract a small `**ThreadDetailCubit` / `ChangeNotifier`** so the screen does not depend on `ThreadsTab` closures; share `**MessageCard**` or a slimmer `**ThreadEntryRow**` between feed and detail to reduce duplication with `**_ThreadOriginalPostCard**`.

### 8.2 Repost sheet (Repost vs Quote)

**What:** Bottom sheet offers **duplicate repost** (new `posts` row with `repost_of_post_id` or `repost_of_comment_id`) or **quote** (navigate to draft, then `createPost` with `quoted_post_id` or `quoted_comment_id`).

**How:** `**_duplicateRepostPost`** branches on `**source.isComment**`: posts keep prior behavior (copy `quotedPostId` when duplicating a quote post); comments build a short **title** from trimmed body and call `**createPost`** with `**repostOfCommentId**`. `**_handlePost**` accepts both quote id types and builds optimistic `**Post**` with `**quotedPost` vs `quotedComment**` previews; outbox payload stores `**quoted_comment_id**` when offline.

**Refactor:** Move repost/quote orchestration into `**CommunityService`** or a dedicated `**RepostCoordinator**` with unit tests; unify title generation (`**composeServerTitle**` vs comment truncation) behind one helper.

### 8.3 Backend engagement and hydration

**What:** Feed and detail feel “live”: likes, repost toggle, duplicate-repost counts, quoted embeds for posts and comments.

**How:** Read mixins batch-query related tables (`post_votes`, `post_reposts`, `posts` filtered by `repost_of_post_id` / `repost_of_comment_id`), then attach fields. Quoted previews use `**_hydrate_quoted_posts`** (from `posts`) and `**_hydrate_quoted_comments**` (from `comments` + `user_info`). Comment list endpoints pass `**get_optional_user**` into `**list_comments_by_post**` / `**list_comments_by_post_ids**` so `**reposted_by_current_user**` is correct for comments.

**Refactor:** Single `**enrich_posts_for_feed(rows, user_id)`** entry point to avoid forgetting a hydrate step when adding new list endpoints; consider **materialized counts** or triggers if duplicate-repost counting becomes hot; **comment repost toggle** (parallel to `post_reposts`) if product wants symmetry with posts.

### 8.4 Flutter `Post` as union (post vs comment)

**What:** One `**Post`** model represents both feed rows and thread comments so `**MessageActions**`, quote preview, and repost flows stay shared.

**How:** `**isComment`**, `**parentPostId**`, `**quotedComment**`, `**quotedCommentId**` extend the model; mapper sets flags and context from API JSON.

**Refactor:** Split into `**ThreadPost`** vs `**ThreadComment**` with a shared `**EngagementMixin**` or sealed union when the types diverge further (e.g. comment-only votes API); until then, `**isComment**` keeps churn low.

### 8.5 New thread draft & compose

**What:** `**NewThreadDraftScreen`** for quote composition; optional topic field; `**threads_tab**` composer for quick posts.

**How:** Draft result carries `**quotedPostId`** or `**quotedCommentId**` exclusively based on `**quotedPost.isComment**`; embed uses `**QuotedPostEmbed**` for both.

**Refactor:** Merge draft and inline composer behind one `**ComposeScope`** (topic, quote target, character limits); centralize `**CommunityOutboxOperation**` payload schema (version field) when retry rules multiply.

### 8.6 Testing and docs

**How:** API tests in `**test_community_api.py`** cover create with `**repost_of_comment_id**`, `**quoted_comment_id**`, and mutual exclusion of dual quote targets; `**test_operations_units.py**` fake Supabase query supports `**.in_()**` for comment engagement queries.

**Refactor:** Add integration tests against a real Supabase test project for FK migrations; Flutter widget tests for repost sheet and thread detail navigation.

---

## Appendix: Why Supabase instead of GraphQL

Meta’s consumer Threads clients use internal GraphQL (Relay-style). Syntrak uses **Supabase + REST** for simpler ops and RLS-friendly access patterns. The **batch comments** endpoint reproduces the main benefit of a batched GraphQL query—**one server round trip for many children**—without introducing a GraphQL gateway.