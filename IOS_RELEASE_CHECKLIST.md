# iOS Release & TestFlight Checklist

A single-source checklist for preparing and releasing the iOS app (com.syntrak.snowtrak.app) to TestFlight / App Store. Use this document for coordinating work, tracking credentials, and recording actions.

---

## Summary

- App ID: com.syntrak.snowtrak.app
- Team ID: AZ44KR5D43
- Repository: Syntraksoftware/syntrak-application

---

## Required files & credentials (do NOT commit to git)

- App Store Connect API Key (.p8)
  - File: AuthKey_<KEY_ID>.p8 (example: AuthKey_G5S7HHQ55Y.p8)
  - Values needed: KEY_ID, ISSUER_ID
- Distribution certificate
  - Public: ios_distribution.cer (downloaded from Apple Dev Portal)
  - Private: .p12 (export from Keychain containing private key) OR private key in Keychain if CSR created locally
- Provisioning profile
  - .mobileprovision (App Store / TestFlight profile tied to App ID and Distribution cert)
- GitHub Actions secrets (store in repository secrets, never in code):
  - ASC_KEY_BASE64 (base64 of .p8)
  - ASC_KEY_ID
  - ASC_ISSUER_ID
  - APP_IDENTIFIER (optional: com.syntrak.snowtrak.app)
  - PROV_PROFILE_NAME (optional: name used when generating profile)
- Apple Developer / App Store Connect access credentials (developer account with Team access)

---

## Security & storage rules

- Never commit `.p8`, `.p12`, `.cer`, `.mobileprovision`, or plaintext secrets.
- Use GitHub Secrets (or private secret manager) with least privilege.
- Rotate ASC keys and distribution certificates when a developer leaves or after a release if concerned.
- Limit who can view repo secrets (use org/team permissions).

---

## Step-by-step checklist

1. Verify private key

   - Open Keychain Access → login → My Certificates.
   - Find the installed distribution certificate. If it expands to show a private key, good. If not, import the `.p12` or recreate the cert (see below).
2. Install distribution certificate (if not installed)

   - Double-click `ios_distribution.cer` or use Keychain Access → File → Import Items... (.cer or .p12).
   - If you have a `.p12`, import it to include the private key.
3. If private key is missing: recreate certificate

   - In Keychain Access: Certificate Assistant → Request a Certificate From a Certificate Authority → save CSR to disk.
   - Apple Developer Portal → Certificates → + → choose "Apple Distribution (App Store and Ad Hoc)" → upload CSR → Download and install.
4. Create App Store provisioning profile (.mobileprovision)

   - [X] Visit: https://developer.apple.com/account → Certificates, Identifiers & Profiles → Profiles → +
   - [X] Choose **App Store** (for TestFlight/App Store distribution)
   - [X] Select App ID: `com.syntrak.snowtrak.app`
   - [X] Select the Distribution certificate you installed
   - [X] Name the profile (e.g., "Snowtrak App Store Profile") → Generate → Download `.mobileprovision`
5. Install the `.mobileprovision`

   - Double-click to install, or open Xcode → Signing & Capabilities and select the profile when using Manual signing.
6. Configure Xcode project

   - Open `frontend/ios/Runner.xcodeproj` in Xcode.
   - Ensure the **Bundle Identifier** is `com.syntrak.snowtrak.app` and the **Team** is set to your organization.
   - Set Signing to Manual or Automatic as preferred. If Manual, select the downloaded provisioning profile.
   - Verify entitlements (Push, Background Modes, Location, etc.) match App ID capabilities.
7. Upload secrets to GitHub (if not already)

   - Use `scripts/set_asc_secrets.sh` (comes with repo). Example:

```bash
./scripts/set_asc_secrets.sh \
  -k "$HOME/Downloads/AuthKey_G5S7HHQ55Y.p8" \
  -K G5S7HHQ55Y \
  -I e667b27b-f347-48b3-94de-39f7149d196d \
  -R Syntraksoftware/syntrak-application \
  -a com.syntrak.snowtrak.app \
  -p "Snowtrak App Store Profile"
```

- Or set manually with `gh`:

```bash
gh secret set ASC_KEY_BASE64 --repo Syntraksoftware/syntrak-application --body "<base64>"
gh secret set ASC_KEY_ID --repo Syntraksoftware/syntrak-application --body "G5S7HHQ55Y"
gh secret set ASC_ISSUER_ID --repo Syntraksoftware/syntrak-application --body "e667b27b-..."
gh secret set APP_IDENTIFIER --repo Syntraksoftware/syntrak-application --body "com.syntrak.snowtrak.app"
gh secret set PROV_PROFILE_NAME --repo Syntraksoftware/syntrak-application --body "Snowtrak App Store Profile"
```

8. Confirm GitHub Actions / Fastlane config

   - Open `frontend/ios/fastlane/Fastfile` and confirm the three lanes are present:
     - `dev` for local validation and non-signed iOS builds
     - `staging` for TestFlight uploads from `develop`
     - `production` for App Store Connect uploads from tagged releases
   - Confirm the lanes use `ASC_KEY_ID`, `ASC_ISSUER_ID`, and `ASC_KEY_PATH` from Actions secrets.
    - Confirm the staging lane disables map features so beta testing stays isolated from the unstable map backend.
   - Confirm `.github/workflows/ios-dev.yml`, `.github/workflows/ios-testflight.yml`, and `.github/workflows/flutter-release.yml` point at the correct lane for each environment.
9. Build, archive & upload

   - Option A: Xcode
     - Product → Archive → Distribute App → App Store Connect → Upload
   - Option B: Fastlane (lane names in `Fastfile`):

```bash
cd frontend/ios
bundle install
bundle exec fastlane dev
bundle exec fastlane staging
bundle exec fastlane production
```

10. Add TestFlight testers & release notes

    App Store Connect → TestFlight → Add internal/external testers and release notes.
11. Post-release security

    - Rotate any temporary keys if used.
    - Revoke old certificates if needed.

---

## Useful commands & tips

- Export `.p12` from Keychain (if you need to move private key):
  - Keychain Access → right-click certificate with private key → Export → choose `.p12` and set a secure password.
- Convert `.p8` to base64 (script does this), or manually:

```bash
base64 < AuthKey_G5S7HHQ55Y.p8 | tr -d '\n' > asc_key_base64.txt
```

- Check installed certificates (macOS):

```bash
security find-identity -v -p codesigning
```

- Check installed provisioning profiles (macOS):

```bash
ls ~/Library/MobileDevice/Provisioning\ Profiles
```

---

## Contacts & notes

- Apple Developer account owner: (fill in name/email)
- Person who created CSR / has private key: (fill in name/email)
- Date created: 2026-05-17

---

## Communication

- Use this document as the single source of truth; add comments / updates below with timestamps when you perform an action.

---

_Last updated: 2026-05-17_
