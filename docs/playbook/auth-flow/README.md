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

> App startup and wiring: 
`frontend/lib/main.dart`
- `bootstrapAndRun()` calls `setupServiceLocatorWithEnvironment()` so config, HTTP clients, APIs, and repositories exist before the UI runs. -> Initialize everything before the UI start

- MultiProvider builds StorageService, then AuthProvider (with ApiService + StorageService).
- After storage initializes, auth.checkAuth() runs so the app can restore or invalidate a previous session to check whether the user stays signed in or not. 

- By service locator, it is used to reduce coupling between a class and its dependencies by using a central registry (the "locator") to find and provide services at runtime.

-  It acts as a factory or registry that returns instances of services, enabling loose coupling and dynamic runtime linking. 


`frontend/lib/core/di/service_locator.dart`
In service locator, we have multiple methods including: 
```dart
registersingleton//: the entire app use one object/ service (configs, diary, app_states)

registerlazysingleton//: create one object in advance and will be share later (services that consume tons of resources)

registeryfactory//: temporary object (DTO)
```
- Registers `AppConfig`, `AuthTokenStore` (places to store user token), three Dio (network communication protocol) instances (main / activity / community base URLs).
- Registers `AuthApi` with the main Dio client (auth lives on main-backend).
- Registers AuthRepository → ApiService (facade used by AuthProvider). 

> App startup and wiring: 
In `../config/app_config.dart`: 
```dart
...
final env = environementOverride ?? obtain from env()
...
//check if we have change the address temporarily/ at run time 
final prefs = await sharedpreference.getInstance()
final runtimeMain = [refs.getString('override_main_api_base_url')]

```
- picks dev/ staging/ prod defaults and allows overrides
- config system uses default settings for each environment (dev, staging, prod)
- "override" lets you temporarily replace these with custom values (like API URLs) at runtime or via compilation flags without changing the source code.

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

- on every request, if `authtokenstore` has a token, sets `authorization: bearer<access_token>`

```dart
final runtimeMain = prefs.getString('override_main_api_base_url');
```

- application checks if there is a value saved under the key `override_main_api_base_url` in device storage, used to temporarily override the API endpoint without recompiling the app.
- If it exists and is not empty, this address will take precedence over the default or compile-time configured API URL. 


- When `AuthProvider` calls `_apiService.setToken(...)`, it updates the API service client with the current authentication token.
- After this call, every subsequent HTTP/API request made by that client will automatically include the `Authorization` header with the set bearer token (e.g., `Authorization: Bearer <access_token>`).
- No need to manually add the authentication header to each request—the API client handles it internally.

- If the token is changed or cleared (such as on logout, or deactivated due to long time inactivity), the API service will use the new token or remove the header accordingly.

> Session Model(What gets stored and parsed): 
- `frontend/lib/models/auth_session.dart`
- mirrors the backend: access_token, refresh_token, expires_at, nested `user`
- the auth session will return something like: 
```json
// Sample AuthSession JSON returned by the backend and stored on the client:

{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.signature",
  "refresh_token": "def50200d26c04ea...",
  "expires_at": "2024-07-01T12:34:56.789Z",
  "user": {
    "id": "user-abc123",
    "email": "user@example.com",
    "first_name": "Alice",
    "last_name": "Skiier",
    "created_at": "2024-05-30T14:22:00.000Z",
    // ...other user fields...
  }
}
```
- check expire date, check if it expires now and so on

> Cold start: "Am i still logged in": 
- `frontend/lib/providers/auth_provider.dart — _checkAuth() / checkAuth()`
1. Load persisted session from StorageService:
- On app start, the app checks device storage for any previously saved authentication session.
- The full session JSON (including access_token, refresh_token, expires_at, and user) is stored in the storage location used for the "token" (not just the token string).
- app  try to restore both the tokens and user details on app launch, enabling automatic re-authentication if the session is still valid.
- If no session is found, or it is invalid/expired, the app continues to the login flow as needed.


2. if no session -> not authenticated -> UI shows login
3. if session exists and access token is expired ->: 
   - call `_refreshSession` -> `ApiService.refreshToken` -> save new session -> `setToken` -> authenticated 
   - if acces token is not expired -> setToken, then `_apiService.getCurrentUser()` to validate with the server; on failure, clear session
> Persistece + optional refresh + server valdiation is all in authprovider


> Login and register(user action): 
- UI: `../lib/screens/auth/login_screen.dart` -> form calls (authProvider.login(email, password))
- `register_screen.dart` -> sme pattern but for register

> State
`frontend/lib/providers/auth_provider.dart — login() / register():`
- Call `ApiService`
- Parse response with `AuthSession.fromJson`
- `_apiService.setToken(accessToken)`
- `_saveSession` to storage
- `notifyListeners()` so MaterialApp rebuilds.

> http layer: 
- `frontend/lib/services/api_service.dart — login / register / refreshToken` delegate to AuthRepository and map DioException to user-facing errors (e.g. 401, connection errors).

> MaterialApp rebuilds:
Flutter's main application widget (`MaterialApp`) and its child widgets are triggered to re-render. 

- When `notifyListeners()` is called on a `ChangeNotifier` (like `AuthProvider`), any widget that is listening (using a `Consumer`, `Provider.of`, or similar) will rebuild.
- If your app's widget tree is structured so that showing "Login" vs. "Main app" depends on auth state (`isAuthenticated`), a "rebuild" will cause the whole UI to switch between authenticated and unauthenticated views.
- UI updates and responds to auth state changes, ensuring the correct screens are shown to the user.

> Thin/ middleware repostiory: 
- `../auth/data/auth_repository.dart`: forwards to `auth_api`
- thin data layer abstraction, responsible for handling user authentication operations such as register, login and refresh token
- delegates all the logic to the underlying [authapi] service
- <app-logic> - <thin-layer> - <network-api>
- `auth_repository` expose methods to: 
   - `register`: Register a new user with email, password, and optional first/last names.
   - `login`: Authenticate a user with email and password.
   - `refreshToken`: Refresh the user's session using a refresh token.
- All methods return a `Map<String, dynamic>` representing the parsed API response.

> Raw endpoints: 
- `../apis/auth_api.dart`: 
- POST /auth/register
- POST /auth/login 
- pOST /auth/refresh
(paths are relatibe to the main DIO baseURl, which already includes /api/v1)

> Issue tokens: 
- `backend/main-backend/app/api/v1/auth.py`
- `POST``
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


> Who issue tokens: 
- `backend/main-backend/app/api/v1/auth.py`
- POST /auth/register: normalize email, ensure unique user (Supabase or in-memory user_store), hash password, create user, return AuthSession via `_create_session(user)`.
- POST /auth/login: load user(supabase or fallback store), verifiy password, check active, return authsession 
- POST /auth/refresh - validate refresh JWT, load user, return a new authsession 
- JWT creation/ validation is in app.core.jwt (imported in that file); storage abstraction is `app.core.stroage`. `app.core.supabase
   - Storage abstraction: encapsulates how and where authentication session data (such as tokens and user info) is persisted and retrieved on the device. 

   - In the backend (`main-backend/app/core/storage.py`), the storage abstraction manages reading and writing user and session data to different storage backends
   - On the frontend, the `StorageService` is the abstraction layer for saving, reading, and clearing the authentication session JSON from local device storage (e.g. SharedPreferences on Android/iOS, localStorage on web). `AuthProvider` doesn't deal directly with the storage APIs; instead, it calls methods on `StorageService`.

- By abstracting storage, the rest of the codebase (like `AuthProvider` or the backend's authentication logic) can store and retrieve session data without needing to know or care about the underlying storage mechanism. 

- The router is mounted under the app's `/api/v1` prefix, so full paths are like `/api/v1/auth/logins`

> How the UI chooses login vs home: 
- `frontend/lib/main.dart — _AppWrapper + Consumer<AuthProvider>`
- "storage abstraction" in both the backend and frontend. 
- reading/writing of user/session data is handled via an interface that hides the details of where/how the data is stored (e.g. Supabase, in-memory store, local device storage).
- On the backend, this abstraction is implemented in `main-backend/app/core/storage.py`, allowing the auth logic to store and load user/session data from different places (like Supabase or a fallback dictionary), without changing the rest of the code.

- On the frontend, the `StorageService` abstracts over device storage mechanisms (e.g. it knows how to read/write to SharedPreferences or localStorage). The `AuthProvider` interacts only with the `StorageService` and doesn't care *how* storage is done.
- Because of this abstraction, components like `AuthProvider` (frontend) or the backend's authentication routes can always call standard read/write methods to persist or retrieve session data, without being aware of the specific storage backend. 
- While `isLoading = true` -> loading UI (with timeout fallback)
- if `isauthenticated` -> homescreen
   - else: loginscreen 
- no screen decides `business auth`; it only calls `authprovider` and reacts to isauthenticated/ isloading 

> Refresh when needed/expired 
- `frontend/lib/providers/auth_provider.dart`
- Used when other features need a valid access token (e.g. before long API flows). If refresh fails, session is cleared and user must log in again


## Key design decisions in current code

- Environment-aware API base URLs are centralized in `AppConfig`.
- Dio injects Authorization header from shared token store.
- Auth state is controlled by `AuthProvider`, not by UI widgets.
   - Instead of hardcoding where and how session or user data is stored (for example, directly reading/writing files, local storage, or connecting to a specific backend), both the frontend and backend use a "storage abstraction": a layer of code that defines how to save, load, and clear authentication/session data in a generic way withou the need of understanding the underlying mechanism.

- Session includes both access and refresh token and a user payload.
- The following things should be included: 
   - `access_token`: The JWT that should be attached to future API requests.
   - `refresh_token`: The token to obtain new access tokens when the current one expires.
   - `expires_at`: The expiration timestamp for the access token.
   - `user`: The user object.

The refresh token is stored alongside the access token and user data in the session payload. 
```json
{
  "access_token": "<JWT string>",
  "refresh_token": "<refresh token string>",
  "expires_at": 1717267648,
  "user": {
    "id": "12345",
    "email": "user@example.com",
    "first_name": "Alice"
    // ...other user fields
  } //payload
}
```

When refreshing, only the `refresh_token` is sent:

```json
{
  "refresh_token": "<refresh token string>"
}
```

After a successful refresh, a new session payload is returned with updated `access_token`, new expiry, and the latest user data.

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
