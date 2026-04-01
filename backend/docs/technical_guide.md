# backend technical guide

## 1. purpose and scope
This guide defines architecture, data contracts, and operations for all backend services in `backend/`.

## 2. architecture overview
### high-level design
Backend is organized as service-oriented FastAPI apps:
- main-backend for auth and user core APIs.
- community-backend for feed and interaction APIs.
- activity-backend for activity record/read APIs.
- map-backend for geo/map APIs.
- shared for cross-service utilities.

### key design patterns
- route/service separation.
- shared utility package for auth/contracts/middleware.
- explicit validators and mappers for stable contracts.

### data contracts/models
- pydantic request/response contracts per service routes.
- standardized auth and list envelope patterns via shared code.

### external integrations
- Supabase/PostgREST.
- Docker and CI image scanning.

## 3. code structure and key components
### file map
- `backend/run.py`
- `backend/shared/`
- `backend/*-backend/main.py`
- `backend/*-backend/routes/`
- `backend/*-backend/services/`

### entry points
- `python backend/run.py`
- `python backend/run.py --service main|community|activity|map`

### critical logic
- request auth and validation.
- service-layer business operations.
- response normalization for frontend consumers.

### configuration
- per-service `config.py` and `.env`.

## 4. development and maintenance guidelines
### setup instructions
1. `cd backend`
2. `python3.11 -m venv .venv`
3. `./.venv/bin/pip install -r requirements.txt`
4. `python run.py`

### testing strategy
- run `pytest` per service.

### code standards
- keep route handlers thin.
- place business rules in service modules.

### common pitfalls
- missing shared imports due incorrect docker context.
- missing runtime dependencies for form/media endpoints.

### logging and monitoring
- uvicorn logs and `/health` checks.

## 5. deployment and operations
### build/deployment steps
- `docker compose -f backend/docker-compose.yml up --build`

### runtime requirements
- python 3.11+, network access to Supabase.

### health checks
- ports: 8080, 5001, 5100, 5200 with `/health`.

### backward compatibility
- prefer additive contract changes.

## 6. examples and usage
### code snippets
```bash
python backend/run.py --service community
```

### integration scenarios
- frontend authenticates via main-backend and then calls domain services.

### cli commands
- `pytest`
- `curl http://127.0.0.1:5001/health`

## 7. troubleshooting and faqs
### common errors
- `ModuleNotFoundError: shared`
- `401/403` auth errors

### debugging tips
- isolate one service and replay curl requests.

### performance tuning
- batch list reads and paginate large responses.

## 8. change log and versioning
### recent updates
- unified documentation format applied.

### version compatibility
- aligned with backend requirements.
