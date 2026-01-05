/// Google Maps API Configuration
/// 
/// To use Google Maps, you need to:
/// 1. Get a Google Maps API key from: https://console.cloud.google.com/
/// 2. For iOS: Add it in ios/Runner/AppDelegate.swift
/// 3. For Android: Add it in android/app/src/main/AndroidManifest.xml
/// 
/// For development, you can use a test key, but for production,
/// restrict the key to your app's bundle ID/package name.

class MapConfig {
  // You can set this via environment variable or hardcode for development
  // For production, use environment variables or secure storage
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '', // Set your key here for development, or use environment variable
  );

  static bool get isConfigured => googleMapsApiKey.isNotEmpty;
}


