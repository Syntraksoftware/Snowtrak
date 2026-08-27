# Client feed cache and rate limiting
Snowtrak now uses a two-tier caching strategy:

1. Server-side (Redis) — protects APIs and short-caches community read responses (from `rate-limiting`).
2. Client-side (device) — instant feed paint, stale-while-revalidate, optimistic rebase, and background prefetch (this work).

The client approach mirrors the existing weather cache (`WeatherCache` + stale-while-revalidate) but applies it to paginated feeds.

For API path standardization (OpenAPI, map `/api/v1/map/*`), see [api_standardization.md](./api_standardization.md).

---

Backend: manual merge from `rate-limiting`


Redis rate limiting

- Shared middleware: `backend/shared/rate_limiter.py`
- Fixed-window counters in Redis (`INCR` + `EXPIRE`)
- Per-route policies (method + path glob)
- HTTP 429 with `Retry-After` and `X-RateLimit-*` headers
- Fail-open by default (`RATE_LIMIT_FAIL_OPEN=true`) if Redis is down

Wired in:

| Service | Entry point |
|---------|-------------|
| main-backend | `backend/main-backend/app/main.py` |
| community-backend | `backend/community-backend/main.py` |
| activity-backend | `backend/activity-backend/main.py` |
| map-backend | `backend/map-backend/application.py` |

Community response cache (server)

- `backend/community-backend/services/community_cache.py`
- Cache-aside on feed + batched post comments
- Version-bump invalidation on writes (`invalidate_feed_cache`, `invalidate_post_comments_cache`)
- Default TTLs: feed 15s, post comments 20s

Docker

- `backend/docker-compose.yml` adds `redis:7-alpine`
- All four backends receive:
  - `RATE_LIMIT_REDIS_URL=redis://redis:6379/0`
  - `CACHE_REDIS_URL=redis://redis:6379/0`

Environment examples updated in each backend `.env.example`.

Local verification

```bash
cd backend
docker compose up --build -d
curl -sS http://localhost:5001/health
```

Repeated feed requests should hit Redis cache on the server (see `backend/community-backend/CURL_TESTS.md` on the rate-limiting branch for warm/hit patterns).

---

Client-side feed cache

Storage

Flutter mobile uses **SharedPreferences** (JSON payloads), not IndexedDB. IndexedDB applies to web builds; the same cache API can be swapped later via `FeedCacheStore`.

Core modules

| File | Role |
|------|------|
| `frontend/lib/services/feed/feed_cache_store.dart` | Generic paginated page storage |
| `frontend/lib/services/feed/activities_feed_cache.dart` | Home activities feed pages (30 min TTL) |
| `frontend/lib/services/feed/community_feed_cache.dart` | Community threads feed snapshot (15 min TTL) |
| `frontend/lib/services/feed/post_cache_codec.dart` | Post JSON codec for community cache |
| `frontend/lib/services/feed/feed_rebase.dart` | Merge server feed with local optimistic state |

1. Cache-first rendering

On app open:

- **Home (activities):** `ActivityProvider.hydrateFromCache()` paints page 1 from disk before the network returns.
- **Community:** `ThreadsTab._hydrateFeedFromCache()` paints the last saved feed snapshot.

If cache is missing or expired, normal loading spinners appear.

2. Stale-while-revalidate

After showing cached data, the app fetches fresh data in the background:

- **Activities:** `ActivityProvider.loadActivities(refresh: true)` always revalidates page 1; pull-to-refresh uses `forceNetwork: true` to skip cache read.
- **Community:** `_loadFeed()` fetches fresh posts, then **rebases** local optimistic changes (likes, pending posts) via `FeedRebase.mergeCommunityPosts`.

Rebase rules (community):

- Preserve local `likedByCurrentUser`, counts if higher than server
- Prepend optimistic posts not yet visible on server

3. Predictive prefetch

- **Activities:** after page N loads, `_prefetchPage(N+1)` silently fetches and stores the next page. `loadMore()` reads prefetched pages instantly when available.
- **Community:** `_prefetchNextCommunityPage()` downloads the next 15 posts (`CommunityFeedCache.prefetchPageSize`) after each successful refresh/load-more.

Pagination

- Activities: existing infinite scroll in `ActivitiesFeedSliver` + prefetched pages in cache
- Community: scroll listener on `ThreadsTab` triggers `_loadMoreFeed()` near bottom (320px threshold)

TTLs

| Feed | Client TTL | Server TTL (community) |
|------|------------|-------------------------|
| Activities | 30 minutes | n/a |
| Community | 15 minutes | 15 seconds (feed) |
| Weather (existing) | 45 minutes | n/a |

429 handling

The Flutter client already maps HTTP 429 to a retryable error in `AppError`. With Redis rate limiting enabled, clients should back off and can continue showing cached feed data while revalidation fails.

---

Integration points

| Screen | Provider / state | Cache class |
|--------|------------------|-------------|
| Home activities | `ActivityProvider` | `ActivitiesFeedCache` |
| Community threads | `ThreadsTab` local state | `CommunityFeedCache` |
| Weather card | `ActivitiesContextRepository` | `WeatherCache` (existing) |

DI registration: `frontend/lib/core/di/service_locator.dart`

---

Follow-ups (not in this change)

- Web: IndexedDB-backed `FeedCacheStore` implementation
- Video chunk prefetch (when media posts ship)
- Unified offline outbox rebase for failed likes/comments (outbox already exists for writes)
- Integration tests for cache + rebase flows
- Merge `ui` home redesign into `develop` if not already present

---

Change log (this branch)

Backend

- Added `backend/shared/rate_limiter.py`
- Added `backend/community-backend/services/community_cache.py`
- Updated all four backend entrypoints, configs, `.env.example`, `requirements.txt`, `docker-compose.yml`
- Community read/write routes use cache-aside + invalidation

Frontend

- Added `frontend/lib/services/feed/*`
- Extended `Activity` with `toCacheJson` / `fromCacheJson`
- Updated `ActivityProvider`, `ActivitiesScreen`, `ActivitiesScreenController`
- Updated `ThreadsTab`, `ThreadsFeedLoader`
- Registered caches in `service_locator.dart`

---

## Read latency on the community read paths (2026-08-27)

The Supabase project is in `ap-south-1`. From the west coast of the US, one
round trip to it measures **~440ms of pure distance** — before Postgres does
any work at all. Everything below follows from that number, and any future
tuning should start by re-measuring it rather than assuming.

Measured with the cache flushed each time, against the real database:

| Endpoint | Before | Cold | Cached |
|---|---|---|---|
| `GET /api/v1/follows/{id}/stats` | 1.03s every time | 0.46s | 0.008s |
| `GET /api/v1/posts/user/{id}` | 4.07s every time | 1.19s | 0.008s |
| `GET /api/v1/feed` | 3.13s | 1.54s | 0.008s |
| `GET /api/v1/users/{id}/profile` | one round trip every time | one round trip | ~0.2ms |

### The four causes, largest first

**1. Blocking calls on the event loop.** `supabase-py` is synchronous and the
handlers were `async def`, so FastAPI ran them on the event loop and each
440ms call stalled *every other request in flight*. Five concurrent requests
each took 8.1–8.6s when any one alone took 0.5–1.4s.

`backend/community-backend/services/offload.py` moves them to a threadpool.
**Anything that reaches Supabase from an `async def` handler belongs in
`offload()`.** Handlers declared plain `def` do not need it — FastAPI already
runs those in a threadpool, which is why main-backend was unaffected.

**2. Sequential reads with no dependency between them.**
`list_posts_by_user_id` made five round trips one after another. One was
redundant: the duplicate-repost query run twice, the second time only to add a
`user_id` filter that selecting `user_id` in the first one answers. The rest —
likes, reposts, duplicates, and the two quoted-preview hydrations — are
independent and now run together in `_hydrate()`.

**3. Four queries where one would do.** `/follows/{id}/stats` counted
followers, counted following, and checked both edge directions as separate
requests. `follow_stats(target, viewer)` (migration 011, superseded by 012)
answers all four server-side in one trip.

**4. No cache on the profile path.** Follow stats, a user's post list, and
profiles now use the same Redis cache the feed already had. Writes invalidate,
so your own edits and follows appear immediately rather than after a TTL.

### Known and deliberately unfixed

A cold profile open is still **two sequential hops**: the post list, then the
quoted-post previews. Collapsing that to one means a Postgres function that
returns fully hydrated posts, which duplicates the Python row mapping in SQL
and has to be kept in step with it forever.

At 1.19s cold and 8ms warm, that trade is not worth making. Revisit if the
cold path starts mattering — cache hit rates dropping, or the region moving
and changing the arithmetic.

### A cache bug worth remembering

`get_cache_version` returned `1` for an absent key while `bump_cache_version`
INCRs an absent key *to* `1`. The first invalidation of any scope was therefore
a no-op. The feed's 15s TTL hid this for as long as the feed was the only
caller; the first cache with a longer TTL exposed it immediately. The default
is now `0`.
