# iOS release pipeline

Nothing reaches TestFlight on its own. The build is dispatched by hand:
**Actions -> iOS Staging -> Run workflow**, pick a branch, go. It used to fire
on every push to `develop`, which spent a build slot and pushed a new binary at
testers for every merged PR, including the ones no tester needed to see.

`main` still releases through `v*` tags; see
[branch_policy.md](branch_policy.md).

## What runs

`.github/workflows/ios-testflight.yml` on a `macos-latest` runner:

1. Enforce Xcode 26 (the app does not build on 15).
2. Decode the App Store Connect API key and the distribution certificate.
3. `bundle exec fastlane staging`, which runs the quality gate
   (`flutter pub get`, `dart analyze`, `flutter test`), builds the IPA, and
   uploads it.

## Signing

This is the part that took three months to get right, so it is written down.

**Manual, not automatic.** Automatic signing asks Xcode for a profile, and
Xcode asks the logged-in Apple account. A CI runner has no account, which is
the whole content of the `No Accounts: Add a new account in Accounts settings`
error every CI run produced until 2026-09-06. Manual signing removes the
account from the path, so the same commands work on a runner and on a laptop.

Three files have to agree, and there is no way to make them share one value:

| File | Setting |
|---|---|
| `frontend/ios/Runner.xcodeproj/project.pbxproj` | `PROVISIONING_PROFILE_SPECIFIER`, Runner target, **Release only** |
| `frontend/ios/ExportOptions.plist` | `provisioningProfiles`, and `signingCertificate` by SHA-1 |
| App Store Connect | the profile itself |

`Fastfile` reads the name out of `ExportOptions.plist` rather than keeping a
fourth copy, so only the first two are hand-maintained.

Debug and Profile configurations stay on automatic signing — day-to-day
`flutter run` on a device is unaffected. `flutter run --release` on a physical
device no longer works, because an App Store profile cannot install on a
device. Use `--profile` for that.

`signingCertificate` is pinned by SHA-1 because two identities named
`iPhone Distribution: SYNTRAK LIMITED (AZ44KR5D43)` are in circulation and
`xcodebuild` picks by name. It kept picking the one the profile does not
contain.

## Secrets

| Secret | What it is |
|---|---|
| `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_BASE64` | App Store Connect API key (`.p8`, base64) |
| `APP_IDENTIFIER` | `com.syntrak.snowtrak.app` |
| `IOS_DIST_CERT_BASE64` | the distribution certificate **and private key**, as a base64 `.p12` |
| `IOS_DIST_CERT_PASSWORD` | the password set when exporting that `.p12` |
| `MAPTILER_API_KEY` | baked in via `--dart-define`; without it the build falls back to keyless tiles |
| `FASTLANE_APPLE_ID` | read by `Appfile`, kept out of this public repo |

The provisioning profile is **not** a secret. `fastlane` downloads it at build
time through the API key, so it cannot go stale in a secret nobody looks at.
The private key is the one thing Apple's API will never hand back, which is
why the certificate is a secret and the profile is not.

## Rotating the certificate

Needed when it expires (the current one: 2027-05-17) or when the team changes.

```bash
# 1. Export from Keychain Access, or:
security export -k ~/Library/Keychains/login.keychain-db \
  -t identities -f pkcs12 \
  -P '<a password you choose>' \
  -o ~/Desktop/dist.p12
# macOS will prompt for keychain access; this cannot be scripted headlessly.

# 2. Upload both halves.
base64 -i ~/Desktop/dist.p12 | gh secret set IOS_DIST_CERT_BASE64
gh secret set IOS_DIST_CERT_PASSWORD --body '<the same password>'

# 3. Delete the file. It holds a private key.
rm ~/Desktop/dist.p12
```

If the new certificate has a different SHA-1, update `signingCertificate` in
`ExportOptions.plist` — `security find-identity -v -p codesigning` prints it.

## Build numbers

`Fastfile` asks App Store Connect for the highest build number already uploaded
for the current marketing version and adds one, so `CFBundleVersion` never
collides. The marketing version (`CFBundleShortVersionString`) still comes from
`pubspec.yaml` and is bumped by hand.

## Running it locally

Same lane, same result, no runner:

```bash
cd frontend/ios && bundle exec fastlane staging
```

`frontend/ios/fastlane/.env` holds the local values (`ASC_KEY_ID`,
`ASC_ISSUER_ID`, `ASC_KEY_PATH`, `APP_IDENTIFIER`). It is gitignored. fastlane
loads it automatically. The CI-only signing bootstrap is skipped when `CI` is
unset, so the lane uses your own keychain and installed profile.

## What changed on 2026-09-06, and what you have to do differently

Two habits are now wrong.

**A merge to `develop` no longer ships to testers.** It publishes the Docker
images and nothing else. If you want a build on TestFlight, ask for one:
`gh workflow run ios-testflight.yml --ref <branch>`. This is not a temporary
state while something is repaired — it is the point. Every merged PR used to
spend a TestFlight processing slot and push a new binary at testers, most of
which no tester needed to see, and a routine merge could not be done without
also publishing.

**`flutter run --release` on a physical device no longer works.** The Release
configuration signs against an App Store profile, and an App Store profile
cannot install on a device. Use `--profile`, which is what you wanted for a
timing or performance check anyway. Debug and Profile still sign
automatically, so `flutter run` and `flutter run --profile` are unchanged.

Nothing else about day-to-day work changes. `bundle exec fastlane staging`
still works from a laptop and now runs the same code path CI does.

### Why the workflow had never once succeeded

Twenty-one runs between 2026-06-01 and 2026-09-05, zero successes, always the
same error:

```
Error (Xcode): No Accounts: Add a new account in Accounts settings.
```

The Runner target archived with `CODE_SIGN_STYLE = Automatic`, which resolves
the profile by asking Xcode, which asks the signed-in Apple account. A runner
has no account.

It worked on a laptop only because Xcode there is signed in. That difference
does not appear anywhere in the repository, which is why "it works locally"
was worthless as evidence for three months, and why the Release configuration
is now manual: a runner and a laptop run identical commands, or the next
difference will hide just as well.

## When it breaks

`flutter build ipa` **exits 0 even when `exportArchive` fails**, leaving the
previous run's IPA on disk. That once shipped a three-month-old binary to
Apple. `Fastfile` now compares the IPA's mtime against the start of the build
and fails loudly instead. If you see `Stale IPA at ...`, the real error is
further up the log — it is an export failure, not a packaging one.
