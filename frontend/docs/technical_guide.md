# frontend technical guide

## 1. purpose and scope
This document covers the Flutter client under `frontend/`, including app architecture, state flow, integrations, testing, and operations.

## 2. architecture overview
### high-level design
The frontend is a layered Flutter application:

1. Presentation layer: screens/widgets in `lib/screens` and shared UI in `lib/widgets`.
2. State/application layer: providers and feature services coordinate user workflows.
3. Data/integration layer: API repositories/adapters and network configuration in `lib/services`, `lib/features`, and `lib/core/network`.

Typical interaction flow:
1. User action in screen/widget.
2. Provider/controller dispatches feature operation.
3. Repository/service calls backend API.
4. Response is mapped into UI model and rendered.

### key design patterns
- Repository pattern for feature data access: keeps API details isolated from UI.
- Dependency injection with service locator: central registration and testability.
- Coordinator/helper extraction in complex screens: reduces monolithic widget files and supports maintainability.
- Mapper pattern for backend-to-UI model shaping.

### data contracts/models
- Domain models live under `lib/models` and feature-specific model files.
- API payload contracts are represented in `lib/services/apis` and mapper modules.
- Config contracts for environment/base URLs are defined in `lib/core/config`.

### external integrations
- Backend APIs: main, community, activity, map services.
- Google Maps Flutter plugin for map rendering.
- Device location and permissions plugins for tracking workflows.
- iOS/Android native configuration for runtime permissions and networking.

## 3. code structure and key components
### file map
- `frontend/lib/main.dart`: default app bootstrap.
- `frontend/lib/main_dev.dart`: development flavor entry point.
- `frontend/lib/main_staging.dart`: staging flavor entry point.
- `frontend/lib/main_prod.dart`: production flavor entry point.
- `frontend/lib/core/config/app_config.dart`: environment-driven endpoint configuration.
- `frontend/lib/core/di/service_locator.dart`: dependency registration.
- `frontend/lib/features/`: feature repositories and feature-layer data orchestration.
- `frontend/lib/screens/`: route-level screens and UI flow logic.
- `frontend/lib/services/apis/`: API clients and endpoint wrappers.

### entry points
- `flutter run -t lib/main_dev.dart`
- `flutter run -t lib/main_staging.dart`
- `flutter run -t lib/main_prod.dart`

### critical logic
- Authenticated session bootstrapping and token handling.
- Community thread feed mapping and action coordination.
- Activity recording and location updates in record workflows.

Pseudo flow for screen action:
```text
onTapAction():
  state = loading
  result = repository.performAction(payload)
  if result.ok:
    state = success(mapped_result)
  else:
    state = error(result.error)
```

### configuration
- `pubspec.yaml` for package/dependency configuration.
- `analysis_options.yaml` for lint/static analysis rules.
- `--dart-define` runtime overrides for API base URLs.
- Platform permission/network settings in `ios/Runner/Info.plist` and Android manifest files.

## 4. development and maintenance guidelines
### setup instructions
1. `cd frontend`
2. `flutter pub get`
3. `flutter run -t lib/main_dev.dart`

### testing strategy
- Unit/widget tests live in `frontend/test`.
- Run tests with `flutter test`.
- Prefer mapper/service unit tests and targeted widget tests for critical flows.

### code standards
- Follow Effective Dart style and project lint rules.
- Keep widgets focused; move reusable or complex logic into helpers/coordinators.
- Keep API calls in service/repository layers, not in widget build methods.

### common pitfalls
- Misconfigured base URLs can cause cross-service API failures.
- Missing location permissions break activity record flows.
- Overly large widget files become hard to maintain; split by responsibility.

### logging and monitoring
- Use debug logs in development with structured context.
- Surface actionable error states in UI and report API failures clearly.
- Track crash/error trends via chosen monitoring stack (if enabled in environment).

## 5. deployment and operations
### build/deployment steps
- Local run: `flutter run -t lib/main_dev.dart`
- Test build validation: `flutter test`
- Platform-specific production packaging should be performed per iOS/Android release process.

### runtime requirements
- Flutter SDK and Dart SDK compatible with `pubspec.yaml` constraints.
- iOS/Android emulator or physical device for runtime validation.
- Network access to backend APIs.

### health checks
- Validate app startup and login flow.
- Validate API connectivity for feed/activity/map screens.
- Validate location permission prompt and map render on supported device.

### backward compatibility
- Preserve model and mapper compatibility when backend responses evolve.
- Introduce additive fields first and gate removals with coordinated backend rollout.

## 6. examples and usage
### code snippets
Run with explicit API overrides:
```bash
flutter run -t lib/main_dev.dart \
  --dart-define=MAIN_API_BASE_URL=https://example-main/api/v1 \
  --dart-define=ACTIVITY_API_BASE_URL=https://example-activity/api/v1 \
  --dart-define=COMMUNITY_API_BASE_URL=https://example-community/api/v1
```

### integration scenarios
- Login flow calls main backend auth endpoints, stores token, and reuses token for subsequent service calls.
- Community screen triggers repository actions that call community backend and map responses into display models.
- Activity record screen uses device location APIs and sends activity payloads to activity backend.

### cli commands
- `flutter pub get`
- `flutter run -t lib/main_dev.dart`
- `flutter test`

## 7. troubleshooting and faqs
### common errors
- `SocketException` or request timeout
  - Cause: backend unavailable or wrong base URL.
  - Resolution: verify backend health endpoints and `--dart-define` values.
- Google map not displayed
  - Cause: missing API key or platform setup issue.
  - Resolution: verify iOS/Android key configuration and SDK settings.
- Location tracking not starting
  - Cause: permission denied or missing manifest/plist entries.
  - Resolution: verify permission entries and runtime grant status.

### debugging tips
- Use flavor entry points to isolate environment-specific issues.
- Validate API requests with logs and compare payload/response mapping.
- Run focused widget tests when iterating on UI state behavior.

### performance tuning
- Minimize unnecessary rebuilds by narrowing state updates.
- Paginate large feed queries and avoid excessive map redraws.
- Cache stable view data where consistency rules permit.

## 8. change log and versioning
### recent updates
- Community thread UI responsibilities were split into coordinator/helper modules.
- API mapper and service structure was expanded for clearer data boundaries.
- Frontend networking configuration and environment entry points were refined.

### version compatibility
- Flutter and Dart versions follow constraints in `pubspec.yaml`.
- Plugin compatibility should be validated for iOS and Android targets before release.
