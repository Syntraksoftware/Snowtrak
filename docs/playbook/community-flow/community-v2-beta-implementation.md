# Community V2 Beta Implementation Strategy (Single Source of Truth)

## Document Status

- Owner: Community platform team
- Last updated: 2026-03-27
- Scope: Beta launch readiness for community feed, posts, replies, votes, and sync
- Purpose: Single technical reference for architecture, API contracts, rollout, and QA

## Problem Statement

Current community experience is not production-ready for beta:

- Feed content is still local/mock in key UI flows.
- Post/reply write paths are not fully wired from frontend to backend.
- Offline experience is not deterministic for queued writes.
- Cross-device consistency is not guaranteed when reconnecting.

Target outcome:

- Users see immediate UI feedback for writes.
- Backend remains the final authority.
- Offline drafts and queued operations survive app restarts.
- Data converges across devices with conflict-safe synchronization.

## Decisions Confirmed

1. Vote model: Reddit-style upvote/downvote.
2. Feed ordering: Latest first for initial beta, with Hot tab introduced later in beta.
3. Pagination: Cursor pagination.
4. Reply depth: Max two levels (post -> comment -> reply).
5. Reputation v1:
   - Create post: +2
   - Create reply: +1
   - Post receives vote: +0.5, daily cap +10
   - Reply receives vote: +0.2
   - Post deleted: -5
6. Moderation v1: Manual moderation via report queue (no auto enforcement).
7. Failed write UX: Edit + retry + resend controls.
8. Feature flag authority: Backend-controlled flags.

## Architecture Principles

1. Hybrid UX model:
   - Optimistic UI for responsiveness.
   - Backend as final source of truth.
2. Offline-first authoring:
   - Draft post/comment composition works offline.
   - Cached thread reading works offline.
3. Deterministic sync:
   - Persistent outbox queue.
   - Idempotent backend write APIs.
4. Observability first:
   - Every mutation has request_id + client_operation_id.

## Target End-to-End Data Flow

1. User submits post/comment/vote/edit/delete in UI.
2. Frontend writes a local optimistic state update immediately.
3. Frontend enqueues mutation in persistent outbox.
4. Sync worker sends mutation with idempotency token.
5. Backend applies mutation (or rejects with clear reason).
6. Frontend reconciles local entity with authoritative backend response.
7. Feed/thread caches update and notify UI.

## Frontend Implementation Plan

## 1) State and Data Layer Refactor

Create a dedicated community domain state layer:

- CommunityFeedController (or Provider)
- CommunityThreadController
- CommunityOutboxService
- CommunityCacheStore

Required capabilities:

- Load latest feed by cursor.
- Load thread comments and nested replies (max depth 2).
- Apply optimistic updates for create/edit/delete/vote.
- Store operation status: pending, syncing, failed, confirmed.

## 2) Persistent Outbox Contract

Outbox operation schema:

- operation_id (UUID, client-generated)
- operation_type: create_post | create_comment | vote_post | edit_post | delete_post | edit_comment | delete_comment
- entity_type: post | comment | vote
- entity_local_id
- entity_server_id (nullable)
- payload_json
- created_at
- retry_count
- next_retry_at
- status: pending | syncing | failed | dead_letter | done
- last_error_code
- last_error_message

Storage recommendation:

- Use a local persistent store (SQLite/Isar/similar).
- SharedPreferences is insufficient for robust outbox behavior.

## 3) Offline UX Rules

- Draft creation is always allowed.
- Publish while offline:
  - Create pending local item in feed/thread.
  - Mark with "Syncing" badge.
- Permanent failure:
  - Show inline failure card.
  - Actions: Edit and Retry, Resend, Discard.

## 4) Reconciliation Rules

- Backend response wins for server-managed fields:
  - ids, created_at, updated_at, vote_score, reply_count, reputation effects
- Client keeps local content only until first successful server ack.
- Duplicate prevention via client_operation_id.

## 5) Feature Flag Integration

On feed bootstrap, backend returns features block:

- community_v2
- nested_replies
- hot_ranking
- moderation_report

Frontend behavior:

- If community_v2 = false -> fallback to legacy flow (internal only).
- If true -> use new feed + outbox + sync path.

## Backend Implementation Plan

## 1) API Completion

Add or finalize endpoints under /api/v1:

- GET /subthreads/{id}/posts?cursor=...&limit=...
- GET /posts/{id}/comments?cursor=...&limit=...
- POST /posts
- PATCH /posts/{id}
- DELETE /posts/{id}
- POST /comments
- PATCH /comments/{id}
- DELETE /comments/{id}
- POST /posts/{id}/vote
- POST /comments/{id}/vote
- POST /reports

All write endpoints must accept:

- Authorization bearer token
- client_operation_id (header or body)

## 2) Cursor Pagination Contract

Response shape:

- items: [...]
- meta:
  - next_cursor
  - has_next
  - request_id

Cursor options:

- Latest feed: (created_at, id) composite cursor
- Hot feed: (hot_score, created_at, id) composite cursor

## 3) Vote Semantics

Vote value set:

- +1 (upvote)
- -1 (downvote)
- 0 (remove vote)

Server computes:

- vote_score
- user_vote_state for requesting user

Conflict example:

- If post/comment deleted before queued vote sync:
  - return 404 with structured error code ENTITY_NOT_FOUND
  - frontend marks operation failed and removes local pending vote state

## 4) Edit/Delete Semantics

- Ownership required for edit/delete.
- Return updated entity snapshot for PATCH.
- Soft delete preferred for moderation auditability.

Conflict policy:

- version field or updated_at precondition recommended.
- If stale edit detected, return 409 CONFLICT with latest snapshot.

## 5) Reputation Engine v1

Rules:

- Event-driven updates only (post_created, comment_created, vote_applied, post_deleted).
- Daily cap for post-vote gains: +10.

Implementation guidance:

- Maintain write-time counters in dedicated table.
- Cache computed reputation in user profile table.
- Rebuild job for reconciliation if drift detected.

## 6) Moderation v1

Report endpoint:

- POST /reports with target_type, target_id, reason_code, note

Behavior:

- Persist report record.
- No automatic hide in beta.
- Manual moderation queue in admin tooling.

## Sync Engine and Conflict Strategy

## 1) Retry Policy

- Backoff: 1s, 2s, 4s, 8s, 16s, then capped interval.
- Max retries before dead-letter: configurable (for example 8).
- Manual retry allowed from UI.

## 2) Conflict Matrix

1. Offline vote on deleted post/comment:
   - Backend: 404 ENTITY_NOT_FOUND
   - Frontend: clear pending vote, show one-time toast
2. Offline edit on deleted entity:
   - Backend: 404 ENTITY_NOT_FOUND
   - Frontend: show failed state with discard option
3. Concurrent edit from two devices:
   - Backend: 409 CONFLICT + latest entity
   - Frontend: prompt user to merge/retry
4. Duplicate retry of create:
   - Backend idempotency dedup by client_operation_id
   - Frontend receives original successful entity

## API Error Contract (Required)

Standard error fields:

- code
- message
- request_id
- details (optional)

Required codes:

- ENTITY_NOT_FOUND
- PERMISSION_DENIED
- VALIDATION_ERROR
- CONFLICT
- RATE_LIMITED
- IDEMPOTENCY_REPLAY

## Rollout Plan

## Phase 0: Internal Hardening

- Complete backend endpoint parity.
- Frontend outbox + optimistic write path.
- End-to-end tests for create/reply/vote/edit/delete.

## Phase 1: Internal Testers

- community_v2 enabled for internal cohort.
- Monitor duplicate writes, failed sync rates, and latency.

## Phase 2: Flagged Beta Ramp

- 10% users -> 50% users -> 100% users.
- Keep kill-switch to disable v2 quickly.

## Phase 3: Full Cutover

- Remove mock feed path from production runtime.
- Keep migration adapters only for rollback window.

## Kill Switch Design

Backend-controlled kill switch:

- community_v2_enabled = false
- Return 503 for v2 mutation routes if emergency shutdown is needed.

## Monitoring and SLOs

Primary success metrics:

- P95 time to local visible post <= 2s
- Reply visibility reliability >= 99%
- Duplicate write rate = 0 (idempotency enforced)
- Lost writes after app restart = 0
- Write API error rate < 1%
- Concurrent connections tracked and alert thresholds configured

Required dashboards:

- mutation_success_rate by operation_type
- outbox_depth and dead_letter_count
- conflict_rate by endpoint
- reputation_update_latency

Alerts:

- error_rate > 1%
- dead_letter growth spike
- sync backlog older than threshold

## Testing Matrix

## Backend

- Unit tests for vote, edit, delete, report, reputation rules.
- Contract tests for cursor pagination and error codes.
- Idempotency replay tests.

## Frontend

- Unit tests for outbox reducer and reconciliation logic.
- Integration tests for offline->online publish sync.
- UI tests for failed operation retry/edit flows.

## End-to-End

- Multi-device consistency scenario.
- Airplane mode authoring and later reconciliation.
- Feature flag disabled/enabled transitions.

## Work Breakdown Estimate

- Frontend state-layer refactor: 35%
- Backend API completion: 25%
- Sync engine implementation: 20%
- Conflict logic and reconciliation: 15%
- Monitoring and alerting: 5%

## Ownership and Deliverables

1. Backend community team:
- API completion
- idempotency and conflict semantics
- reputation and moderation endpoints
2. Frontend team:
- feed state refactor
- outbox/sync engine
- optimistic UI and failure UX
3. Platform/DevOps:
- feature flags
- observability dashboards and alerts

## Definition of Done (Beta Community V2)

1. No mock/local-only feed path for flagged users.
2. All write operations persist to backend and survive restart.
3. Idempotency prevents duplicates under retries.
4. Cursor pagination is live for feed and thread reads.
5. Conflict/error handling is user-visible and recoverable.
6. Metrics and alerts are active with runbook links.

## Immediate Next Tasks (Execution Order)

1. Expand CommunityApi and CommunityRepository with full CRUD + vote + cursor.
2. Introduce persistent outbox data model and sync worker.
3. Implement optimistic post/comment/vote in ThreadsTab flow.
4. Add backend PATCH/vote/report endpoints and idempotency support.
5. Wire backend feature flags into feed bootstrap response.
6. Add contract and integration tests, then start internal rollout.

## Implementation Progress Log

- 2026-03-27 (Wave 1):
   - Frontend `CommunityApi` expanded with:
      - subthread feed read
      - post list by subthread
      - comment list by post
      - create post
      - create comment
   - Frontend `CommunityRepository` and `ApiService` expanded to expose the above methods.
   - Community feed UI (`ThreadsTab`) migrated from mock-only flow to backend-backed loading.
   - Optimistic create-post and create-reply behavior implemented in `ThreadsTab`.
   - Persistent outbox skeleton added (`community_outbox_service.dart`) with load/save/enqueue/retry support.
   - Startup retry pass added to re-attempt queued operations and reconcile feed.

- Remaining in Wave 2+:
   - vote APIs and backend persistence
   - edit/delete flows with conflict handling
   - cursor pagination contract rollout
   - feature-flag handshake from backend response
