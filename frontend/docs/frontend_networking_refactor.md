# Frontend Networking Refactor Log

## Context

This document records the initial architecture problems found in the frontend networking layer and the structural changes implemented to fix them.

## Initial Problems Identified

1. Hardcoded and environment-fragile API base URLs.
- Localhost service URLs were embedded in networking setup.
- Environment switching required code edits.
- Staging and production rollout was error-prone.

2. Tightly coupled networking and service construction.
- API clients were directly coupled to a shared singleton registry.
- UI layers created API service instances ad hoc.
- Dependency boundaries were unclear and difficult to test.

3. Mixed responsibilities in a single facade.
- One service mixed auth, profile, activities, and community responsibilities.
- Service concerns and backend ownership boundaries were blurred.

4. Limited maintainability for module growth.
- Feature code was not fully organized around clear domain boundaries.
- Network dependencies were not centralized through a dependency graph.

## Changes Implemented

### 1. Environment and Flavor Configuration

Implemented explicit environment modeling and flavor entrypoints:

- Added environment enum and parser.
- Added centralized app config with:
  - environment defaults
  - dart-define support
  - runtime endpoint overrides persisted in shared preferences
- Added flavor entrypoints for dev, staging, and prod.

Outcome:
- API endpoint switching no longer requires editing source code.
- Build-time and runtime configuration are both supported.

### 2. Dependency Injection with GetIt

Implemented centralized dependency management:

- Added GetIt service locator bootstrap.
- Registered singleton app configuration and auth token store.
- Registered per-service Dio clients (main, activity, community).
- Registered APIs, repositories, and facade in one graph.

Outcome:
- Service initialization is deterministic and centralized.
- UI and provider layers no longer need to construct clients ad hoc.

### 3. Repository Pattern Adoption

Introduced feature-oriented repositories:

- Auth repository
- Profile repository
- Activities repository
- Community repository
- Notifications repository

Outcome:
- Networking is now grouped by domain responsibility.
- Business-facing service calls are separated from transport-level details.

### 4. API Client Decoupling

Refactored API client constructors:

- Removed default fallback behavior tied to global service registry.
- API classes now require explicit Dio injection.

Outcome:
- Clients are testable and environment-aware through DI wiring.

### 5. Facade and Provider Wiring Cleanup

Refactored app wiring and provider usage:

- Main app startup now bootstraps DI before runApp.
- Providers and profile-related UI now resolve shared dependencies from DI.
- Notification provider now depends on notifications repository.

Outcome:
- Reduced duplication and hidden coupling across screens/providers.

### 6. Compatibility Layer for Existing Code

Retained a compatibility path while moving architecture forward:

- Legacy registry was converted to config-driven behavior (no hardcoded URL constants).
- Token handling now routes through shared auth token store.

Outcome:
- Existing integrations remain stable during migration.
- Future code can progressively avoid legacy access patterns.

## Resulting Architecture Direction

Hybrid feature/layer approach:

- Core layer: configuration, DI, network client factory.
- Feature layer: repositories per domain.
- Service layer: API adapters and utility services.
- Provider/UI layers: consume facade/repositories via DI, not direct construction.

## Validation Performed

1. Static analysis executed after refactor.
2. Changed files were checked for compile errors.
3. Hardcoded localhost URL usage in frontend source was removed from active networking wiring.
4. Ad hoc API service instantiation patterns were replaced in key profile/provider paths.

## Follow-Up Suggestions

1. Continue migrating remaining legacy call sites to direct repository interfaces where appropriate.
2. Add focused unit tests for app config resolution and repository behavior.
3. Add integration tests per flavor entrypoint to validate endpoint routing.
