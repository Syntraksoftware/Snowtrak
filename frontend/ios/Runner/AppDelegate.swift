import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Google Maps API Key - loaded from Info.plist
    // rFor production, use a build script to inject from .env file
    if let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
       let plist = NSDictionary(contentsOfFile: path),
       let apiKey = plist["GoogleMapsAPIKey"] as? String {
      GMSServices.provideAPIKey(apiKey)
    } else {
      
      // Fallback: This should not happen in production
      // In production, ensure the key is set in Info.plist or via build script
      print("⚠️ Warning: Google Maps API key not found in Info.plist")
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
