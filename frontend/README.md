# Syntrak Flutter App

Flutter frontend for the Syntrak fitness tracking application.

## Features

- User authentication (login/register)
- GPS activity tracking
- Real-time activity recording with map visualization
- Activity history and details
- Profile with statistics

## Setup

1. Install Flutter dependencies:
```bash
flutter pub get
```

2. Backend endpoint configuration (flavors + runtime overrides):

- Default environment is `dev`.
- Flavor entrypoints:
	- `lib/main_dev.dart`
	- `lib/main_staging.dart`
	- `lib/main_prod.dart`
- Environment defaults and runtime override keys are defined in
	`lib/core/config/app_config.dart`.

Examples:

```bash
# Dev (default localhost microservices)
flutter run -t lib/main_dev.dart

# Staging flavor
flutter run -t lib/main_staging.dart

# Prod flavor
flutter run -t lib/main_prod.dart

# Override any endpoint without changing code
flutter run -t lib/main_dev.dart \
	--dart-define=MAIN_API_BASE_URL=https://example-main/api/v1 \
	--dart-define=ACTIVITY_API_BASE_URL=https://example-activity/api/v1 \
	--dart-define=COMMUNITY_API_BASE_URL=https://example-community/api/v1
```

3. For Android, add permissions in `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

4. For iOS, add location permissions in `ios/Runner/Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to track your activities</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>We need your location to track your activities</string>
```

5. Run the app:
```bash
flutter run -t lib/main_dev.dart
```

## Project Structure

- `lib/core/` - Configuration, dependency injection, network client factory
- `lib/features/` - Feature repositories (auth, profile, activities, community, notifications)
- `lib/models/` - Data models (User, Activity, Location)
- `lib/services/` - API adapters and utility services
- `lib/providers/` - State management (Auth, Activity, Notification)
- `lib/screens/` - UI screens (Auth, Home, Record, Activities, Profile)

## Dependencies

- **provider** - State management
- **get_it** - Dependency injection container
- **dio** - HTTP client
- **geolocator** - GPS location tracking
- **google_maps_flutter** - Map visualization
- **permission_handler** - Location permissions

