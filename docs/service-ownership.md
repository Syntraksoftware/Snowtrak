# Service Ownership Boundaries

This document defines single-owner domains for backend services.
One specific backend for each service (activity-related, main-backend handling user profiles/date etc, map-backend for geographical locations)

## Ownership Matrix

- auth/users: main-backend
- notifications: main-backend
- weather: main-backend
- activities: activity-backend
- community (subthreads/posts/comments): community-backend
- follows (social graph): community-backend

## Rules

- A domain is exposed by exactly one service.
- No duplicate route ownership across services.
- Frontend routes by domain, not by implementation details.

## Canonical Base Paths

- main-backend: /api/v1/auth, /api/v1/users, /api/v1/notifications, /api/v1/weather
  - notification is not yet being implemented
- activity-backend: /api/v1/activities
- community-backend: /api/subthreads, /api/posts, /api/comments, /api/v1/follows

## Migration Decision (2026-03-20)

- Activity APIs were removed from main-backend routing, to avoid coupling with activity backend
- Activity ownership is hard-cut over to activity-backend.
- Notifications remain in main-backend as cross-domain infrastructure.

**Finished 2026-08-27.** The 2026-03-20 cut unmounted the router but left the
implementation in the tree: routes, an `ActivityOperations` mixin on the shared
Supabase client, Pydantic schemas, and an in-memory store — about 700 lines,
reachable from nothing.

It was not inert. It used `activities.is_public` as its access-control column,
while activity-backend uses `visibility`. Neither writer knew about the other,
so the two disagreed in production: one activity was stored `visibility =
'private'` alongside `is_public = true`. Had that router ever been mounted,
`list_public_activities` — which filters on `.eq("is_public", True)` — would
have served it.

A hard cut that leaves the old implementation behind is not a cut; it is a
second implementation waiting for someone to plug it back in.

## Follows Decision (2026-08-27)

The follow graph is exposed at `/api/v1/follows`, not under `/api/v1/users`.

`/api/v1/users` belongs to main-backend, and the rule above allows one owner
per domain. Follows went to community-backend instead of main-backend because
the only reader that cannot afford a network hop is the feed's visibility
filter, which runs inside community-backend on every request. main-backend has
no reader for this data, so the table sits next to its hot reader.

### activity-backend reads `follows` (2026-08-27)

community-backend owns the follow graph and is the only service that writes
it. activity-backend reads it directly, through
`backend/shared/follow_graph.py`, to build the visibility filter for the
activity list.

An HTTP hop would put two more round trips — roughly 880ms — in front of
every activity list, for one indexed read of a two-column table whose shape
is settled. The read is allowed; a write from activity-backend is not.

## Future Direction

If notification throughput or channel complexity grows, split notifications
into a dedicated service. Until then, keep it centralized in main-backend.
