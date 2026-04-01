# Service Ownership Boundaries

This document defines single-owner domains for backend services.
One specific backend for each service (activity-related, main-backend handling user profiles/date etc, map-backend for geographical locations)

## Ownership Matrix

- auth/users: main-backend
- notifications: main-backend
- activities: activity-backend
- community (subthreads/posts/comments): community-backend

## Rules

- A domain is exposed by exactly one service.
- No duplicate route ownership across services.
- Frontend routes by domain, not by implementation details.

## Canonical Base Paths

- main-backend: /api/v1/auth, /api/v1/users, /api/v1/notifications
  - notification is not yet being implemented
- activity-backend: /api/v1/activities
- community-backend: /api/subthreads, /api/posts, /api/comments

## Migration Decision (2026-03-20)

- Activity APIs were removed from main-backend routing, to avoid coupling with activity backend
- Activity ownership is hard-cut over to activity-backend.
- Notifications remain in main-backend as cross-domain infrastructure.

## Future Direction

If notification throughput or channel complexity grows, split notifications
into a dedicated service. Until then, keep it centralized in main-backend.
