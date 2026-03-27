# Auth Flow: End-to-End Architecture Guide

This document explains how authentication moves through the frontend and backend in the current codebase.

## Flow scope

- Frontend bootstrap and provider wiring
- Auth API client and repository chain
- Backend auth routes and token/session behavior

## Start here: file reading order

1. `frontend/lib/main.dart`
2. `frontend/lib/core/di/service_locator.dart`
3. `frontend/lib/core/config/app_config.dart`
4. `frontend/lib/providers/auth_provider.dart`
5. `frontend/lib/services/api_service.dart`
6. `frontend/lib/features/auth/data/auth_repository.dart`
7. `frontend/lib/services/apis/auth_api.dart`
8. `backend/main-backend/app/api/v1/auth.py`


- By service locator, it is used to reduce coupling between a class and its dependencies by using a central registry (the "locator") to find and provide services at runtime.
-  It acts as a factory or registry that returns instances of services, enabling loose coupling and dynamic runtime linking. 

In service locator, we have multiple methods including: 
```dart
registersingleton//: the entire app use one object/ service (configs, diary, app_states)

registerlazysingleton//: create one object in advance and will be share later (services that consume tons of resources)

registeryfactory//: temporary object (DTO)
```

> In ../config/app_config.dart: 
```dart
...
final env = environementOverride ?? obtain from env()
...
//check if we have change the address temporarily/ at run time 
final prefs = await sharedpreference.getInstance()
final runtimeMain = [refs.getString('override_main_api_base_url')]

```

- set run time overrides
- At runtime: 
   - used sharepreferences: dynamically changing the api base url when the app is operating
- At compile time: 
   - dart-define: in compilation is fixed, need to repack 
- Default: use global, fix, all rounded address
   - _defaultsFor(), setup using env config, fixed by hardcode

- changing address: 
```dart
// in estruntimeoverrides function in app_config 
static Future<void> setRuntimeOverrides({
  String? mainApiBaseUrl,
}) async {
  final prefs = await SharedPreferences.getInstance();
  if (mainApiBaseUrl != null) {
    await prefs.setString('override_main_api_base_url', mainApiBaseUrl);
  }
  ...
}

//application: 
await AppConfig.setRuntimeOverrides(
   mainApiBaseUrl:'http://192.168.1.100:8080'
);
```
use scenario: 
- when test wanna switch to QA pipeline
- production error, switch to standby/ backeup backend 

> Address selector(_firstNonEmpty)
```dart
static String _firstNonEmpty(String? v1, String? v2, String fallback) {
  if (v1 != null && v1.trim().isNotEmpty) return v1.trim();
  if (v2 != null && v2.trim().isNotEmpty) return v2.trim();
  return fallback;
}
```
- v1 here is assumed to be a temp/ dev url
- no suddenc changes 
- if we have setup nothing, use default: https://main.syntrak.app

## Runtime sequence

1. App starts in `frontend/lib/main.dart` via `bootstrapAndRun`.
2. `setupServiceLocatorWithEnvironment` registers AppConfig, token store, Dio clients, APIs, and repositories.
3. `AuthProvider` is created in `main.dart` and `checkAuth` runs after storage init.
4. `AuthProvider` restores session from storage and decides:
   - validate access token with backend user endpoint if still valid
   - refresh token if expired
   - clear local session if invalid
5. Login/Register actions call `ApiService` -> `AuthRepository` -> `AuthApi`.
6. `AuthApi` sends requests to:
   - `POST /auth/register`
   - `POST /auth/login`
   - `POST /auth/refresh`
   under main base URL `/api/v1`.
7. Backend `auth.py` normalizes email, validates credentials, reads/writes Supabase (or fallback store), and returns `AuthSession`.

## Key design decisions in current code

- Environment-aware API base URLs are centralized in `AppConfig`.
- Dio injects Authorization header from shared token store.
- Auth state is controlled by `AuthProvider`, not by UI widgets.
- Session includes both access and refresh token and a user payload.
- Backend supports Supabase-first with in-memory fallback.

## Data contracts to know

Frontend auth payloads:
- register: `email`, `password`, optional `first_name`, `last_name`
- login: `email`, `password`
- refresh: `refresh_token`

Backend auth response model:
- `access_token`
- `refresh_token`
- `expires_at`
- `user`

## Implementation details and caveats

- `AuthProvider` stores full session JSON through `StorageService` token field.
- During startup, auth validation includes a backend call to current-user endpoint.
- Failed refresh clears session and forces login screen.

## What to verify when debugging auth

1. Confirm frontend main base URL points to main-backend.
2. Confirm token is present in Dio Authorization header.
3. Confirm backend main service is running and `/api/v1/auth/login` responds.
4. Confirm JWT secret consistency if multiple services validate tokens.
5. Confirm session restore JSON is parseable.

## Ownership

- Domain owner: main-backend
- Canonical base paths: `/api/v1/auth`, `/api/v1/users`, `/api/v1/notifications`

## Standard curl commands