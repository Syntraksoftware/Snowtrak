# Activity Flow: End-to-End Architecture Guide

## Purpose

This document traces activity operations from Flutter client calls to activity-backend routes.

## Flow scope

- Frontend activity API client behavior
- Backend activity route ownership and payload mapping
- Contract compatibility notes

## Start here: file reading order

1. `frontend/lib/core/config/app_config.dart`
2. `frontend/lib/core/di/service_locator.dart`
3. `frontend/lib/services/apis/activities_api.dart`
4. `frontend/lib/features/activities/data/activities_repository.dart`
5. `frontend/lib/services/api_service.dart`
6. `frontend/lib/models/activity.dart`
7. `backend/activity-backend/routes/activities.py`
8. `backend/activity-backend/models.py`
9. `backend/activity-backend/main.py`

- Activities are owned by activity-backend under `/api/v1/activitues`
- The flutter app uses a dedicated Dio client whose base URL is `activityApiBaseUrl`(already ending in /api/v1), so http path are relative paths like `/activities`

## Full data path:

UI (ActivitiesScreen / RecordScreen / ActivityDetailScreen) → ActivityProvider → ApiService → ActivitiesRepository → ActivitiesApi (Dio) → activity-backend routes/activities.py.

- ActivityProvider
  - State management layer (ChangeNotifier/provider pattern).
  - Handles activity-related actions requested by UI widgets (fetching, creating, updating, deleting activities).
  - Exposes methods to UI; coordinates with ApiService to make requests and stores activity UI state/results.
  - Transforms API data into app models and notifies listeners (widgets) on data/state changes. (usually in json format)
- ApiService
  - Facade layer that simplifies interaction with underlying repositories for the provider.
  - listner to activityprovider
  - Aggregates and organizes methods for all API domains (auth, activity, etc.) and delegates activity calls to ActivitiesRepository.
- ActivitiesRepository
  - Data abstraction layer dedicated to activity domain.
  - Implements business/data logic, calls ActivitiesApi for real backend operations.
  - Translates model objects to/from API/DTO shape.
  - May coordinate/merge multiple API/service results.
- ActivitiesApi (Dio)
  - Low-level direct HTTP (Dio) client implementation.
  - Handles HTTP methods, endpoint path construction, parameter serialization, and error handling.
  - Sends requests over network to activity-backend endpoints (`/activities`) and returns JSON/payloads to repository.

> Startup and wiring (same as main-backend): 

> | Responsibility                                                                    | Where                                                                           |
> | --------------------------------------------------------------------------------- | ------------------------------------------------------------------------------- |
> | Dev/staging/prod base URLs (including activity API)                               | `frontend/lib/core/config/app_config.dart`                                      |
> | Register AppConfig, activity Dio, ActivitiesApi, ActivitiesRepository, ApiService | `frontend/lib/core/di/service_locator.dart`                                     |
> | Attach Authorization: Bearer when a token exists                                  | `frontend/lib/core/network/dio_factory.dart` + `AuthTokenStore`                 |
> | After login, token is set so activity calls are authenticated                     | `frontend/lib/providers/auth_provider.dart` (calls `_apiService.setToken`)      |
> | Expose activity list/create/delete/detail to the widget tree                      | `frontend/lib/main.dart` — `ChangeNotifierProxyProvider<..., ActivityProvider>` |

- All activity HTTP traffic goes through the named DIO instance `activity`, not the main-backend client 


> Domain model and json shape: 
| Responsibility                               | Where                                                         |
|----------------------------------------------|---------------------------------------------------------------|
| Activity, ActivityType, toJson/fromJson for API | `frontend/lib/models/activity.dart`                            |
| GPS points while recording (this should be in backend, one of todo)                   | `LocationService` (used from RecordScreen) + `frontend/lib/models/location.dart` |


> Network layer (client -> HTTP): 
| Responsibility                                        | Where                                                                                       |
|-------------------------------------------------------|---------------------------------------------------------------------------------------------|
| Thin HTTP: POST/GET/PUT/DELETE on /activities…        | `frontend/lib/services/apis/activities_api.dart`                                            |
| Pass-through to the API (no extra business logic)      | `frontend/lib/features/activities/data/activities_repository.dart`                           |
| Facade used by providers                              | `frontend/lib/services/api_service.dart` — `createActivity`, `getActivities`, `getActivity`, `updateActivity`, `deleteActivity` |

> Notes: effective URLS (base + path): 
- `POST /api/v1/activities`, `GET /api/v1/activities`, `GET /api/v1/activities/{id}`



## Runtime sequence

1. Frontend DI builds activity Dio client with base URL `activityApiBaseUrl`.
2. `ActivitiesApi` sends calls to `/activities` paths.
3. Because base URL already includes `/api/v1`, effective backend endpoints are:
  - `POST /api/v1/activities`
  - `GET /api/v1/activities`
  - `GET /api/v1/activities/{id}`
  - `PUT /api/v1/activities/{id}`
  - `DELETE /api/v1/activities/{id}`
4. Backend router in `activities.py` is mounted with prefix `/api/v1/activities`.
5. Backend maps frontend schema to backend storage model and computes metrics from locations.
6. Backend response is transformed to frontend-friendly shape in `_activity_to_frontend`.

## Key design decisions in current code

- Activity ownership is hard-cut to activity-backend.
- Backend has both internal and frontend-oriented models.
- Route handler computes derived metrics from location points server-side.
- Auth is required for create, my-activities, update, delete, and social mutations.

## Data contracts to know

Frontend `Activity.toJson` sends:

- `type`, `name`, `description`, `start_time`, `end_time`, `locations`, `is_public`

Backend create endpoint expects `FrontendActivityCreate` with:

- `type`, `start_time`, `end_time`, `locations`, optional metadata

Frontend parse model expects on read:

- `id`, `user_id`, `type`, `distance`, `duration`, `elevation_gain`, `start_time`, `end_time`, `locations`

## Important compatibility note

- `GET /api/v1/activities` in backend defaults to standardized `{ items, meta }` response.
- `ActivitiesApi.getActivities` currently parses response as raw list.
- This mismatch can break list parsing unless client requests legacy format or parser supports standardized envelope.

## What to verify when debugging activity

1. Confirm activity backend is running on configured host and port.
2. Confirm activity base URL in frontend points to `/api/v1` root of activity-backend.
3. Confirm bearer token exists for protected routes.
4. Confirm list endpoint response format matches frontend parser expectations.
5. Confirm location payload fields (`latitude/longitude/altitude`) are present for metric computation.

## Ownership

- Domain owner: activity-backend
- Canonical base path: `/api/v1/activities`

