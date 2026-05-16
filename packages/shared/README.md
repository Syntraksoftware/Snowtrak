# Shared package (initial)

This directory is the starting point for shared code used across backend and frontend services.

Purpose
- Provide common models, utilities, and authentication helpers.

Initial guidance
- Keep this folder minimal and language-agnostic where possible.
- For Python backend: create a `shared/` installable package or use relative imports from `backend/shared`.
- For Flutter frontend: expose small DTOs or config helpers only if necessary; prefer API contracts (OpenAPI) instead of sharing runtime code.

Suggested contents (MVP)
- `models/` — canonical data contracts (OpenAPI fragments or JSON schema)
- `auth/` — auth helpers, token handling interfaces
- `utils/` — small pure helpers
- `README.md` — this file

Workflow
- Add code incrementally.
- Write tests for shared modules and run them in CI.
