# Map Service Implementation Plan

## Executive Summary

This document outlines the implementation plan for building a robust, Strava-style GPS tracking and map visualization system for Syntrak. The implementation will transform the existing basic recording functionality into a production-ready MVP with proper architecture, state management, and local persistence.

---

## Current State Analysis

### ✅ What Already Exists

1. **Basic Infrastructure:**
   - `google_maps_flutter` dependency installed
   - `geolocator` for GPS tracking
   - `LocationService` with basic tracking
   - `RecordScreen` with map integration
   - `Activity` model with locations support
   - `ActivityDetailScreen` showing routes

2. **Current Limitations:**
   - No GPS filtering/smoothing (raw points collected)
   - No proper state machine for recording (basic boolean flags)
   - No local persistence (only API-based storage)
   - No reusable map widget
   - Limited error handling and recovery
   - No route planning support
   - Stats computed on-the-fly, not optimized

---

## Task Requirements

### Core MVP Features

1. **Location Layer:**
   - Periodic GPS sampling (5 second intervals)
   - GPS point filtering (discard bad points)
   - Optional smoothing algorithm
   - Accuracy validation

2. **Activity Recording Domain:**
   - State machine: `idle → recording → paused → resumed → finished → saved`
   - Activity model with computed metrics
   - Real-time stats calculation
   - Background recording support (future)

3. **Map Presentation:**
   - Reusable map widget (`WorkoutMap`)
   - Live polyline during recording
   - Planned route polyline (for navigation)
   - Markers (start, end, key splits)
   - Auto-centering on current location

4. **Storage & Sync:**
   - Local persistence (Hive/Drift/Isar)
   - Offline activity viewing
   - Sync with backend API
   - Export to GPX/FIT (future)

5. **Activity Detail View:**
   - Static route display
   - Summary metrics overlay
   - Elevation profile (future)

---

## Architecture Design

### Layer Structure

```
┌─────────────────────────────────────────┐
│         UI Layer (Screens)              │
│  - RecordScreen                         │
│  - ActivityDetailScreen                 │
│  - MapsScreen                           │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│      Presentation Layer (Widgets)       │
│  - WorkoutMap (reusable)               │
│  - StatsOverlay                         │
│  - RoutePolyline                        │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│      State Management (Providers)       │
│  - ActivityRecorderProvider             │
│    (State machine + GPS tracking)       │
│  - ActivityProvider (existing)           │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│      Service Layer                      │
│  - LocationService (enhanced)           │
│  - MapService                           │
│  - ActivityStorageService (new)         │
│  - RouteCalculationService (new)        │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│      Data Layer                         │
│  - Activity Model                       │
│  - Location Model                       │
│  - Local Database (Hive)                │
└─────────────────────────────────────────┘
```

### State Machine Design

```
┌─────────┐
│  IDLE   │ ← Initial state, no recording
└────┬────┘
     │ start()
     ▼
┌─────────────┐
│  RECORDING  │ ← Actively collecting GPS points
└────┬────┬───┘
     │    │ pause()
     │    ▼
     │ ┌─────────┐
     │ │ PAUSED  │ ← Recording paused, timer stopped
     │ └────┬────┘
     │      │ resume()
     │      ▼
     │ ┌─────────────┐
     │ │  RESUMED    │ ← Back to recording
     │ └─────────────┘
     │
     │ stop()
     ▼
┌─────────────┐
│  FINISHED   │ ← Recording stopped, ready to save
└────┬────────┘
     │ save()
     ▼
┌─────────────┐
│   SAVED     │ → Navigate to detail screen
└─────────────┘
```

---

## Implementation Plan

### Phase 1: Enhanced Location Layer

**Files to Create/Modify:**
- `lib/services/location_service.dart` (enhance existing)
- `lib/services/gps_filter_service.dart` (new)

**Features:**
1. Configurable sampling interval (1-5 seconds)
2. GPS point filtering:
   - Accuracy threshold (discard if > 50m)
   - Speed sanity check (discard if > 200 km/h)
   - Distance jump detection (discard if > 500m from last point)
3. Optional smoothing (moving average for last 3 points)
4. Background location updates

**Key Methods:**
```dart
class LocationService {
  Stream<Position> getPositionStream({
    Duration interval = const Duration(seconds: 3),
    double accuracyThreshold = 50.0,
    bool enableFiltering = true,
    bool enableSmoothing = false,
  });
  
  bool shouldAcceptPoint(Position newPoint, Position? lastPoint);
  Position smoothPoint(Position point, List<Position> recentPoints);
}
```

---

### Phase 2: Activity Recording State Machine

**Files to Create:**
- `lib/providers/activity_recorder_provider.dart` (new)
- `lib/models/recording_state.dart` (new)

**Features:**
1. Proper state machine with enum states
2. Real-time stats calculation:
   - Distance (cumulative haversine)
   - Duration (elapsed time)
   - Average pace/speed
   - Elevation gain
   - Current speed
3. Pause/resume functionality
4. Auto-save on app background (future)

**Key Structure:**
```dart
enum RecordingState { idle, recording, paused, finished, saved }

class ActivityRecorderProvider extends ChangeNotifier {
  RecordingState _state = RecordingState.idle;
  List<Location> _locations = [];
  DateTime? _startTime;
  Duration _elapsedTime = Duration.zero;
  Duration _pausedTime = Duration.zero;
  
  // State transitions
  Future<void> start(ActivityType type);
  void pause();
  void resume();
  Future<void> stop();
  Future<Activity?> save();
  
  // Computed properties
  double get distance;
  Duration get duration;
  double get averageSpeed;
  double get currentSpeed;
  double get elevationGain;
}
```

---

### Phase 3: Reusable Map Widget

**Files to Create:**
- `lib/widgets/workout_map.dart` (new)
- `lib/widgets/map_overlay.dart` (new)

**Features:**
1. Reusable `WorkoutMap` widget
2. Support for:
   - Live route polyline
   - Planned route polyline
   - Start/end markers
   - Current position marker
   - Auto-centering option
3. Performance optimization (throttle camera updates)

**Key Structure:**
```dart
class WorkoutMap extends StatefulWidget {
  final List<LatLng> routePoints;
  final List<LatLng>? plannedRoute;
  final LatLng? currentPosition;
  final bool autoCenter;
  final bool showMarkers;
  
  const WorkoutMap({...});
}

class _WorkoutMapState extends State<WorkoutMap> {
  GoogleMapController? _controller;
  // Camera update throttling
  // Marker management
  // Polyline management
}
```

---

### Phase 4: Local Storage

**Files to Create:**
- `lib/services/activity_storage_service.dart` (new)
- `lib/models/activity_storage.dart` (new)

**Dependencies to Add:**
- `hive: ^2.2.3`
- `hive_flutter: ^1.1.0`
- `path_provider: ^2.1.1`

**Features:**
1. Hive database setup
2. Activity CRUD operations
3. Query by date range, type, etc.
4. Sync queue for offline activities
5. Export to JSON/GPX (future)

**Key Structure:**
```dart
class ActivityStorageService {
  static const String _boxName = 'activities';
  Box<Activity>? _box;
  
  Future<void> init();
  Future<void> saveActivity(Activity activity);
  Future<List<Activity>> getActivities({...});
  Future<Activity?> getActivity(String id);
  Future<void> deleteActivity(String id);
  Future<void> syncWithBackend();
}
```

---

### Phase 5: Route Calculation Service

**Files to Create:**
- `lib/services/route_calculation_service.dart` (new)

**Features:**
1. Distance calculation (haversine)
2. Elevation gain/loss
3. Pace/speed calculations
4. Route statistics (max speed, avg speed, etc.)
5. Elevation profile data (future)

**Key Methods:**
```dart
class RouteCalculationService {
  static double calculateDistance(List<Location> locations);
  static double calculateElevationGain(List<Location> locations);
  static double calculateAverageSpeed(List<Location> locations, Duration duration);
  static double calculateMaxSpeed(List<Location> locations);
  static Map<String, dynamic> calculateAllMetrics(List<Location> locations, Duration duration);
}
```

---

### Phase 6: Integration & Refactoring

**Files to Modify:**
- `lib/screens/record/record_screen.dart` (refactor)
- `lib/screens/activities/activity_detail_screen.dart` (enhance)
- `lib/providers/activity_provider.dart` (integrate storage)

**Changes:**
1. Replace `RecordScreen` logic with `ActivityRecorderProvider`
2. Use `WorkoutMap` widget
3. Integrate local storage
4. Add offline support
5. Improve error handling

---

## File Structure

```
lib/
├── models/
│   ├── activity.dart (existing)
│   ├── location.dart (existing)
│   ├── recording_state.dart (new)
│   └── activity_storage.dart (new)
│
├── services/
│   ├── location_service.dart (enhance)
│   ├── gps_filter_service.dart (new)
│   ├── map_service.dart (new)
│   ├── activity_storage_service.dart (new)
│   └── route_calculation_service.dart (new)
│
├── providers/
│   ├── activity_provider.dart (existing, enhance)
│   └── activity_recorder_provider.dart (new)
│
├── widgets/
│   ├── workout_map.dart (new)
│   ├── map_overlay.dart (new)
│   └── stats_overlay.dart (new)
│
└── screens/
    ├── record/
    │   └── record_screen.dart (refactor)
    └── activities/
        └── activity_detail_screen.dart (enhance)
```

---

## Dependencies to Add

```yaml
dependencies:
  # Existing...
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  path_provider: ^2.1.1
  
  # Optional for future features
  # gpx: ^1.0.0  # For GPX export
  # fit_parser: ^1.0.0  # For FIT export
```

---

## Implementation Order

### Step 1: Foundation (Location & Filtering)
1. Create `gps_filter_service.dart`
2. Enhance `location_service.dart` with filtering
3. Test GPS filtering with mock data

### Step 2: State Management
1. Create `recording_state.dart` enum
2. Create `activity_recorder_provider.dart`
3. Implement state machine transitions
4. Add real-time stats calculation

### Step 3: Map Widget
1. Create `workout_map.dart`
2. Create `map_overlay.dart` for stats
3. Test with mock route data

### Step 4: Storage
1. Add Hive dependencies
2. Create `activity_storage_service.dart`
3. Set up Hive adapters for models
4. Test CRUD operations

### Step 5: Route Calculations
1. Create `route_calculation_service.dart`
2. Implement all metric calculations
3. Add unit tests

### Step 6: Integration
1. Refactor `RecordScreen` to use new provider
2. Update `ActivityDetailScreen` to use `WorkoutMap`
3. Integrate storage in `ActivityProvider`
4. Add sync logic

### Step 7: Polish
1. Error handling improvements
2. Performance optimization
3. UI/UX refinements
4. Documentation

---

## Testing Strategy

### Unit Tests
- GPS filtering logic
- Route calculations
- State machine transitions
- Storage operations

### Integration Tests
- End-to-end recording flow
- Save and retrieve activities
- Map rendering with routes

### Manual Testing
- Real GPS tracking on device
- Background/foreground transitions
- Low GPS accuracy scenarios
- Battery consumption

---

## Future Enhancements (Post-MVP)

1. **Route Planning:**
   - Load GPX routes
   - Display planned route on map
   - Navigation guidance

2. **Advanced Map Features:**
   - Heatmaps
   - 3D terrain
   - Segment overlays
   - Custom map styles

3. **Performance:**
   - Route simplification (Douglas-Peucker)
   - Tile caching
   - Offline maps

4. **Analytics:**
   - Elevation profile chart
   - Speed/pace graphs
   - Segment analysis
   - Performance trends

---

## Success Criteria

✅ **MVP Complete When:**
1. Can record activity with live map and stats
2. GPS points are filtered and smoothed
3. State machine handles all transitions correctly
4. Activities saved locally and viewable offline
5. Activity detail shows route with metrics
6. No crashes or memory leaks
7. Battery usage is reasonable (< 10% per hour)

---

## Risk Mitigation

1. **GPS Accuracy Issues:**
   - Implement aggressive filtering
   - Add user feedback for poor GPS
   - Fallback to last known good position

2. **Battery Drain:**
   - Optimize sampling interval
   - Use distance-based filtering
   - Background mode optimization

3. **Storage Performance:**
   - Limit stored locations (max 10,000 points)
   - Implement route simplification
   - Periodic cleanup of old activities

4. **State Management Complexity:**
   - Clear state machine documentation
   - Comprehensive error handling
   - State recovery mechanisms

---

## Next Steps

1. Review and approve this plan
2. Set up development environment
3. Begin Phase 1 implementation
4. Iterate based on testing feedback

---

**Ready to proceed with implementation?** 🚀

