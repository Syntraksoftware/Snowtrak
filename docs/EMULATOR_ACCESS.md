# Giving an agent access to the Snowtrak simulator

Goal: let Claude **see** the app (screenshots) and **drive** it (taps, swipes,
typing) so UI findings are verified against pixels, not source.

## What is already on this machine

| Tool | Status | Path |
|---|---|---|
| Flutter | ✅ installed | `/Users/matthewng/Desktop/flutter/bin/flutter` |
| Xcode / `xcrun simctl` | ✅ installed | `/usr/bin/xcrun` |
| iOS simulators | ✅ 10+ available (iPhone 16/17 family, shutdown) | — |
| Homebrew | ✅ installed | `/opt/homebrew/bin/brew` |
| `idb` (tap/swipe control) | ❌ not installed | — |
| Android SDK / `adb` | ❌ not installed | — |
| `integration_test` in the Flutter project | ❌ not set up | — |

---

## Tier 1 — Screenshots only (zero install, works today)

Claude boots a simulator, runs the app, and captures the screen. **You** do the
tapping; Claude reads each frame.

```bash
# 1. boot a simulator (iPhone 17 Pro)
xcrun simctl boot 7FEE8D75-DFBC-4935-B6D2-A1FA90DF0AED
open -a Simulator

# 2. build + run the app onto it (first iOS build takes several minutes)
cd frontend && flutter run -d 7FEE8D75-DFBC-4935-B6D2-A1FA90DF0AED

# 3. capture — Claude runs this whenever it needs to look
xcrun simctl io booted screenshot /tmp/snowtrak.png
```

| Pros | Cons |
|---|---|
| Nothing to install | Claude cannot navigate — you drive |
| Works with the tools already present | Slow round-trip for a 23-screen tour |

---

## Tier 2 — Full navigation via `idb` (recommended for a UI audit)

`idb` (Meta's iOS Debug Bridge) adds coordinate taps, swipes and text entry, so
Claude can walk the whole app unattended.

```bash
brew tap facebook/fb
brew install idb-companion
brew install pipx && pipx install fb-idb
```

Then Claude can do:

```bash
idb list-targets
idb ui tap 200 640 --udid <UDID>       # tap
idb ui swipe 200 700 200 200 --udid <UDID>
idb ui text "powder day" --udid <UDID> # type into focused field
idb ui describe-all --udid <UDID>      # accessibility tree — find things to tap
xcrun simctl io booted screenshot /tmp/frame.png
```

| Pros | Cons |
|---|---|
| Claude navigates the whole app on its own | Two brew installs |
| `describe-all` gives an accessibility tree, so taps are targeted rather than guessed | `idb` lags new Xcode releases; may need a version pin |
| General-purpose — works on any iOS app | Coordinate taps are brittle across device sizes |

> ⚠️ Flutter renders to a single canvas. `describe-all` only returns useful
> nodes if widgets carry `Semantics` labels. Most of Snowtrak's do (Material
> widgets add them automatically), but custom painters — e.g.
> `activity_route_preview_painter.dart`, `progress_weekly_graph_painter.dart` —
> will be invisible to it.

---

## Tier 3 — Flutter `integration_test` (most reliable, Flutter-native)

Instead of coordinate taps, Claude writes Dart that finds widgets by key or text
and screenshots each one. Deterministic and immune to layout shifts.

```yaml
# frontend/pubspec.yaml
dev_dependencies:
  integration_test:
    sdk: flutter
```

```dart
// frontend/integration_test/screen_tour_test.dart
testWidgets('tour every screen', (tester) async {
  await tester.pumpWidget(const SnowtrakApp());
  await tester.pumpAndSettle();
  await binding.takeScreenshot('01-login');
  await tester.tap(find.text('Sign up'));
  await tester.pumpAndSettle();
  await binding.takeScreenshot('02-register');
  // ...
});
```

```bash
cd frontend && flutter test integration_test/screen_tour_test.dart -d <UDID>
```

| Pros | Cons |
|---|---|
| Taps by widget, not pixel — never brittle | Requires a seeded auth session or a mock auth provider |
| Reproducible: re-run after every redesign to diff screens | More upfront setup than `idb` |
| Doubles as regression coverage | Only reaches states the test script drives it to |

---

## Not viable

| Option | Why not |
|---|---|
| **Playwright MCP** | Drives browsers. Snowtrak is a Flutter mobile app with no web entry point. Even against a `flutter build web` target it would be near-useless — CanvasKit paints to one `<canvas>`, so there are no DOM locators, only blind coordinate clicks. |
| **Android emulator** | No Android SDK or `adb` on this machine. |

---

## Recommendation

Start at **Tier 1** to confirm the visual read, then add **Tier 2** if you want
an unattended tour of all 23 screens. Add **Tier 3** when the redesign starts —
screenshot diffs per screen become your review artefact.

## Permissions

These commands run through the agent's Bash tool. On first use you will get an
approval prompt per command; approving the `xcrun simctl` and `idb` prefixes
once (or via `/permissions`) lets the tour run without interruption. Simulator
control may also need the Bash sandbox relaxed for those commands.
