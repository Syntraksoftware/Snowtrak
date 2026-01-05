# Map Features Implementation Guide

## Overview

This document explains the map features implementation in the Syntrak app. The app now includes:

1. **Record Screen Map** - Real-time map view while recording activities
2. **Maps Screen** - Explore all activities on a map with routes and markers
3. **Activity Detail Map** - View individual activity routes (already implemented)

## Setup Instructions

### 1. Get Google Maps API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the **Maps SDK for iOS** and **Maps SDK for Android**
4. Create credentials (API Key)
5. Restrict the API key to your app's bundle ID/package name for security

### 2. Configure iOS

Edit `ios/Runner/AppDelegate.swift`:

```swift
GMSServices.provideAPIKey("YOUR_API_KEY_HERE")
```

Replace `YOUR_API_KEY_HERE` with your actual API key.

### 3. Configure Android

Edit `android/app/src/main/AndroidManifest.xml`:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY_HERE"/>
```

Replace `YOUR_API_KEY_HERE` with your actual API key.

## Features Implemented

### Record Screen Map

- **Real-time tracking**: Map follows your location as you record
- **Route visualization**: Your path is drawn in real-time with a polyline
- **Location permissions**: Handles permission requests gracefully
- **Fallback location**: Uses default location if GPS is unavailable

**Location**: `lib/screens/record/record_screen.dart`

### Maps Screen

- **Activity markers**: Shows start (green) and end (red) markers for each activity
- **Route polylines**: Displays all activity routes with color coding by type:
  - Red: Runs
  - Blue: Rides
  - Green: Walks
  - Brown: Hikes
  - Cyan: Swims
  - Orange: Other
- **Activity cards**: Horizontal scrollable list at the bottom showing all activities
- **My location button**: Centers map on your current location
- **Interactive markers**: Tap markers to view activity details

**Location**: `lib/screens/maps/maps_screen.dart`

### Activity Detail Map

- **Route display**: Shows the complete route of a saved activity
- **Start/End markers**: Green marker for start, red for end
- **Zoom to route**: Automatically fits the route in view

**Location**: `lib/screens/activities/activity_detail_screen.dart` (already implemented)

## Code Structure

### Services

- **LocationService** (`lib/services/location_service.dart`)
  - Handles GPS tracking
  - Manages location permissions
  - Calculates distance and elevation

- **MapConfig** (`lib/services/map_config.dart`)
  - Centralized configuration for Google Maps API key
  - Can be extended for environment-based configuration

### Models

- **Location** (`lib/models/location.dart`)
  - Stores GPS coordinates, altitude, speed, timestamp

- **Activity** (`lib/models/activity.dart`)
  - Contains list of locations for route visualization

## Usage

### Recording an Activity

1. Navigate to Record screen
2. Select activity type
3. Tap "Start Recording"
4. Map will show your location and draw your route in real-time
5. Tap "Stop" when finished
6. Activity is saved with all location data

### Viewing Activities on Map

1. Navigate to Maps screen
2. All activities with location data are displayed
3. Tap any marker or activity card to view details
4. Use "My Location" button to center on current position

### Viewing Activity Details

1. Navigate to Activities screen
2. Tap any activity
3. View the route on the map at the top of the detail screen

## Troubleshooting

### Map Not Showing

1. **Check API Key**: Ensure you've added your Google Maps API key in both iOS and Android configs
2. **Check Permissions**: Make sure location permissions are granted
3. **Check Internet**: Google Maps requires internet connection
4. **Check API Restrictions**: Ensure your API key isn't restricted incorrectly

### Location Not Updating

1. **Check GPS**: Ensure GPS is enabled on your device
2. **Check Permissions**: Verify location permissions in app settings
3. **Check Accuracy**: GPS works best outdoors with clear sky view

### Routes Not Displaying

1. **Check Activity Data**: Ensure activities have location data
2. **Check Map Initialization**: Verify map is properly initialized
3. **Check Polyline Points**: Ensure there are at least 2 location points

## Future Enhancements

Potential improvements:

1. **Map Types**: Toggle between normal, satellite, terrain views
2. **Heat Maps**: Show activity density over time
3. **Route Planning**: Plan routes before starting activities
4. **Offline Maps**: Cache map tiles for offline use
5. **Elevation Profile**: Show elevation graph along route
6. **Segment Analysis**: Highlight fast/slow segments
7. **Social Features**: View friends' activities on map
8. **Search**: Search for locations or points of interest

## Dependencies

- `google_maps_flutter: ^2.5.0` - Google Maps integration
- `geolocator: ^10.1.0` - GPS location tracking
- `permission_handler: ^11.1.0` - Location permissions
- `flutter_polyline_points: ^2.0.0` - Route polyline utilities

## Notes

- For development, you can use a test API key, but it will show a watermark
- For production, always restrict your API key to your app's bundle ID
- Location tracking consumes battery - the app uses efficient distance filtering (5m)
- Map rendering performance is optimized for smooth scrolling and zooming

