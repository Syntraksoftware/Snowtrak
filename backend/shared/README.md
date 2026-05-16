# backend shared package guide

## 1. purpose and scope
Documents shared backend modules used across all services.

## 2. architecture overview
### high-level design
`backend/shared` centralizes auth, middleware, and contract utilities.

### key design patterns
- shared library pattern.
- common contract and middleware abstraction.

### data contracts/models
- auth claims helpers.
- shared list and error contract helpers.

### external integrations
- FastAPI middleware stack and JWT auth flow.

## 3. code structure and key components
### file map
- `auth.py`
- `contracts.py`
- `exception_handlers.py`
- `middleware.py`

### entry points
- imported by each backend service.

### critical logic
- consistent auth validation and error handling.

### configuration
- relies on service-level auth/env config.

## 4. development and maintenance guidelines
### setup instructions
- no standalone runtime; validate via service imports/tests.

### testing strategy
- verify through service suites that consume shared utilities.

### code standards
- avoid service-specific coupling in shared modules.

### common pitfalls
- changing shared APIs without updating service call sites.

### logging and monitoring
- ensure shared handlers produce structured errors.

## 5. deployment and operations
### build/deployment steps
- include `backend/shared` in service Docker images.

### runtime requirements
- python compatibility with backend baseline.

### health checks
- validated via service startup and import success.

### backward compatibility
- treat shared API changes as platform-impacting.

## 6. examples and usage
### code snippets
```python
from shared.auth import get_current_user
```

### integration scenarios
- all backend services use shared auth and contract helpers.

### cli commands
- not applicable.

## 7. troubleshooting and faqs
### common errors
- import errors from incorrect Docker build context.

### debugging tips
- verify image copy paths and import resolution.

### performance tuning
- keep shared helpers lightweight.

## 8. change log and versioning
### recent updates
- shared docs standardized.

### version compatibility
- aligned with backend service dependency set.
