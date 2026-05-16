# iOS App Transport Security (ATS) Configuration

## Current Policy

By default, Syntrak enforces Apple's App Transport Security (ATS):
- **HTTPS only** for remote API calls
- **No local network** access allowed by default
- Secure, production-ready settings

## Development Setup

If you need to call local backend servers during development:

### Option 1: XCConfig (Recommended)
Create `ios/Config/LocalDevelopment.xcconfig`:
```xcconfig
SWIFT_ACTIVE_COMPILATION_CONDITIONS = LOCAL_DEVELOPMENT
```

Then in `ios/Runner/Info.plist`, conditionally include:
```xml
#if LOCAL_DEVELOPMENT
  <key>NSAppTransportSecurity</key>
  <dict>
    <key>NSAllowLocalNetworking</key>
    <true/>
    <key>NSExceptionDomains</key>
    <dict>
      <key>localhost</key>
      <dict>
        <key>NSIncludesSubdomains</key>
        <false/>
        <key>NSTemporaryExceptionAllowsInsecureHTTP</key>
        <true/>
      </dict>
    </dict>
  </dict>
#endif
```

### Option 2: Manual Xcode Configuration
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select the "Runner" target
3. Go to Build Settings → Search for "ATS"
4. For Debug scheme: Allow settings as needed
5. For Release scheme: Ensure ATS stays strict

## Release Checklist

Before building a release (staging or production):

- [ ] Verify `Info.plist` has **no** NSAppTransportSecurity exceptions
- [ ] Verify all API endpoints use **HTTPS**
- [ ] Confirm backend URLs in `app_config.dart` use HTTPS URLs (staging & prod)
- [ ] Run `flutter analyze` and resolve any warnings
- [ ] Test with `flutter build ios --release` to ensure no ATS violations
- [ ] Check Xcode console for ATS rejection logs

## Testing ATS Violations

To catch ATS violations before release:
```bash
# Build with release config
flutter build ios --release

# In Xcode, run and monitor console for:
# "App Transport Security has blocked a cleartext HTTP resource"
```

## References
- [Apple ATS Documentation](https://developer.apple.com/documentation/bundleresources/information_property_list/nsapptransportsecurity)
- [Firebase & ATS](https://firebase.google.com/docs/ios/setup#firebase-sdks-to-your-app)
