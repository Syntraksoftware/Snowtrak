import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Google Maps API Key
    // TODO: Replace YOUR_API_KEY_HERE with your actual Google Maps API key
    // Get your key from: https://console.cloud.google.com/
    // For development, you can use a test key, but for production,
    // restrict the key to your app's bundle ID
    GMSServices.provideAPIKey("YOUR_API_KEY_HERE")
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
