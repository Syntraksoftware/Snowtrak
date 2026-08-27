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
