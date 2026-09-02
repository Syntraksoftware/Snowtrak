# Service Ownership Boundaries

This document defines single-owner domains for backend services.
One specific backend for each service (activity-related, main-backend handling user profiles/date etc, map-backend for geographical locations)

## Ownership Matrix

- auth/users: main-backend
- notifications: main-backend
- weather: main-backend
- activities: activity-backend
- competition (duels, leaderboard): activity-backend
- community (subthreads/posts/comments): community-backend
- follows (social graph): community-backend

## Rules

- A domain is exposed by exactly one service.
- No duplicate route ownership across services.
- Frontend routes by domain, not by implementation details.

## Canonical Base Paths

- main-backend: /api/v1/auth, /api/v1/users, /api/v1/notifications, /api/v1/weather
  - notification is not yet being implemented
- activity-backend: /api/v1/activities, /api/v1/leaderboard, /api/v1/duels
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

### activity-backend reads `follows` for duels (2026-09-02)

The same exception, extended by one caller. A duel is offered on a mutual
follow, so `DuelOperations.create` asks `shared.follow_graph` whether both
edges exist before it writes anything.

The alternative was to put duels in community-backend, which owns the graph.
That service does not own `activities`, so every settlement — two players per
duel — would become an HTTP call to activity-backend for a score. Scoring is
the expensive half and the graph read is the cheap half, so the feature sits
with the scores. Still read-only; the writes stay in community-backend.

### activity-backend reads `user_info` (2026-09-02)

main-backend owns users. activity-backend reads `user_info` to put a name on
a leaderboard row and on a duel card.

The obvious place for a display name is `profiles`, and it is the wrong one:
that table is empty and stays empty, because `profiles.id` references
Supabase auth's `users` while registration writes `user_info`. main-backend
renders profiles from `user_info` at read time for exactly this reason.
`user_info.country_code`, which decides the country boards, lives there for
the same reason and is written only by `PUT /api/v1/users/me/country`.

One `in_` read per page, never one per row. Read-only; the writes stay in
main-backend.

Repairing `profiles` is tracked in issue #43. If it lands, this read can move
back to `profiles`; until then `user_info` is the only table with a name in
it.

## Future Direction

If notification throughput or channel complexity grows, split notifications
into a dedicated service. Until then, keep it centralized in main-backend.
