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
  // Note: API keys are configured in native files:
  // - Android: android/app/src/main/AndroidManifest.xml
  // - iOS: ios/Runner/AppDelegate.swift
  // This class is kept for potential future use with environment variables

  // For now, we assume the keys are configured in native files
  // The Google Maps SDK will handle validation
  static bool get isConfigured =>
      true; // Always return true - let native SDK handle validation
}
