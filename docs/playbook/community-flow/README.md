# Community Flow: End-to-End Architecture Guide

## Purpose

This document explains how community data is fetched in frontend and mounted in community-backend.

For the full beta implementation strategy (architecture, API contracts, sync engine, conflict policy, rollout, and testing), see:

- `docs/playbook/community-flow/community-v2-beta-implementation.md`

## Flow scope

- Frontend community API client pathing
- Backend route mount strategy (`/api/v1` and legacy `/api`)
- Response format expectations and migration details

## Start here: file reading order

1. `frontend/lib/core/config/app_config.dart`
2. `frontend/lib/core/di/service_locator.dart`
3. `frontend/lib/services/apis/community_api.dart`
4. `frontend/lib/features/community/data/community_repository.dart`
5. `frontend/lib/services/api_service.dart`
6. `backend/community-backend/main.py`
7. `backend/community-backend/routes/posts.py`
8. `backend/community-backend/routes/subthreads.py`
9. `backend/shared/deprecation.py`

## Runtime sequence

1. Frontend DI builds community Dio client with base URL `communityApiBaseUrl`.
2. `CommunityApi.getPostsByUserId` requests `/posts/user/{userId}` with pagination params.
3. Since base URL includes `/api/v1`, effective endpoint is `/api/v1/posts/user/{userId}`.
4. Backend `main.py` mounts routers on both:
   - canonical `/api/v1/subthreads`, `/api/v1/posts`, `/api/v1/comments`
   - deprecated `/api/subthreads`, `/api/posts`, `/api/comments`
5. Deprecation middleware adds sunset headers for legacy routes.

## Key design decisions in current code

- Community service supports versioned API plus temporary legacy compatibility.
- Request ID and standardized error/list contracts are shared across services.
- Optional auth is supported for some read paths.

## Data contracts to know

Frontend currently expects `getPostsByUserId` response map containing `posts`.
Backend default for `list_posts_by_user` is standardized list response:
- `{ items: [...], meta: { ... } }`
Legacy format is available only when `format=legacy`:
- `{ posts: [...], page, page_size }`

## Important compatibility note

- Frontend `CommunityApi` currently returns empty list unless response has `posts` key.
- Backend default response uses `items` key.
- This mismatch can hide valid backend data unless client is updated or legacy format is requested.

## What to verify when debugging community

1. Confirm community base URL targets `/api/v1`.
2. Confirm endpoint path is `/posts/user/{userId}` at client call site.
3. Confirm backend response format aligns with frontend parser logic.
4. Check deprecation headers only when calling legacy `/api/*` routes.
5. Confirm JWT secret consistency for authenticated community actions.

## Ownership

- Domain owner: community-backend
- Canonical base paths: `/api/v1/subthreads`, `/api/v1/posts`, `/api/v1/comments`
- Legacy path sunset target: 2026-06-21
