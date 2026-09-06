# Frontend design system

How colour, spacing, and type are defined in the Flutter app.

**Status:** the token layer is built and tested, and the conversion is
complete — 963 call sites read `context.colors`, and zero raw hex or Material
colours remain in `lib/` outside the three documented exceptions.
`test/core/design_system_guard_test.dart` enforces that on every run.

Dark mode is built, tested, and **switched off**: `main.dart` pins
`themeMode: ThemeMode.light`. The palette proves light and dark differ and
that `lerp` is correct; nothing proves dark mode looks right, because nobody
has seen it. Expect a round of visual fixes when Phase 4 flips the switch.

## The protocol

### Three layers

`frontend/lib/core/theme.dart` holds all three. Which one you may read depends
on where your code lives.

| Layer | What it is | Who reads it |
|---|---|---|
| `SnowtrakColors` | The raw ramp — `neutral500 = 0xFF6A7282` | `theme.dart` only |
| `SnowtrakPalette` | Semantic roles — `textSecondary`, `surface`, `border` | the theme binding |
| `context.colors` | Those roles, resolved for the active theme mode | **all UI code** |

Values mirror `pencil_assets/Snowtrak_DesignSystem.fig`, page `12 layout now`,
which is the source of truth for the product design. A change there is a change
to layer 1, never to a screen.

### The one rule

**UI code names a role. It never names a value.**

```dart
Colors.grey                     // ✗ names a colour — frozen, ignores theme
SnowtrakColors.textSecondary    // ✗ right role, wrong layer — a const can't change
context.colors.textSecondary    // ✓
```

The middle line is the subtle one. `SnowtrakColors.textSecondary` reads
correctly today and silently wrong the moment dark mode is switched on, because
a `static const` is fixed at compile time and cannot respond to a theme change.
It is not a hex literal, but it is still layer 1 leaking into a widget.

This is also why people reach for `Colors.grey` in the first place: before
`context.colors` existed there was no ergonomic way to ask *"what colour is
secondary text right now?"* Design systems fail on ergonomics, not on rules — a
written standard cannot beat a shorter alternative. `context.colors.x` is now
the shortest thing to type, which is the point.

### Token reference

| You want | Use |
|---|---|
| CTA, FAB, active nav, heading | `context.colors.primary` |
| Text sitting on `primary` | `context.colors.textOnPrimary` |
| The page background | `context.colors.background` |
| A card | `context.colors.surface` |
| A chip or tile | `context.colors.surfaceVariant` |
| Text, most to least prominent | `textPrimary`, `textSecondary`, `textTertiary`, `textQuaternary` |
| A hairline between rows | `context.colors.divider` |
| A container outline | `context.colors.border` |
| Status meaning | `success`, `warning`, `error`, `info`, `live` |
| Overlay, scrim, shadow | `context.colors.scrim`, with alpha at the call site |
| Activity type | `SnowtrakColors.alpine`, `crossCountry`, `freestyle`, `backcountry`, `snowboard` |

Activity-type colours deliberately stay on `SnowtrakColors`. They encode data,
not chrome, so they read identically in both modes — putting them in the
palette would imply a per-mode value that does not exist.

Spacing, radius, and type have no per-mode variance, so they stay static:
`SnowtrakSpacing`, `SnowtrakRadius`, `SnowtrakTypography`, `SnowtrakElevation`.

### Adding a role

Five edits in `SnowtrakPalette`, all in `theme.dart`:

1. The field.
1. Its value in `light`.
1. Its value in `dark`.
1. A line in `copyWith`.
1. A line in `lerp`.

Then add it to the `_roles` map in `frontend/test/core/theme_test.dart`. That
test asserts every role resolves to its own light and dark value at the lerp
endpoints — which is what catches a copy-paste landing on the wrong field
across 17 near-identical lines.

Needing a colour that has no role is a design-system change. Raise it; do not
invent a hex in a screen.

### When colour is allowed to mean something

Colour carries meaning only for **status** and **activity type**. Everything
else — surfaces, text, lines, and any decorative gradient or banner — resolves
to the neutral ramp. A badge coloured because it looked nice is a bug; a badge
coloured `error` because the thing failed is correct.

## Current state

Counted across `lib/screens`, `lib/widgets`, and `lib/ui`:

| Pattern | Count | Verdict |
|---|---|---|
| `Colors.grey` (all shades) | 111 | Convert. Material's grey is a pure neutral; ours is blue-tinted (`neutral400` = `0xFF99A1AF`), so these are visibly off-system in both modes. |
| `Colors.white` | 79 | Convert. Stays white on a dark background. |
| `Colors.black` (incl. `black87`, `black12`, …) | 78 | Convert. `black87` text on a dark surface is invisible. |
| `Colors.transparent` | 35 | **Leave.** Not a colour — the absence of paint. |
| `Color(0xFF…)` in `screens/` | 0 | Clean; keep it that way. |
| `SnowtrakColors.*` in widgets | ~600 | Convert opportunistically. Correct role, wrong layer. |

Dark mode's state is the reason this matters:

```dart
// main.dart
darkTheme: SnowtrakTheme.darkTheme,
themeMode: ThemeMode.light,        // hardcoded
```

```dart
// screens/settings/display_settings_screen.dart
['Light', 'Dark', 'System'],
onChanged: (v) { setState(() => _theme = v); _showToast('Theme changed to $v'); }
```

The picker ships today and does nothing but show a toast. Wiring it before
conversion is done would break roughly 220 places at once.

## Migration strategy

### Why this order

Converting screens before the token layer exists means converting them twice.
Flipping `themeMode` before conversion is done ships a half-broken toggle, which
is worse than one that visibly does nothing. So:

**Phase 1 — build the token layer.** Done. `SnowtrakPalette`, `context.colors`,
`test/core/theme_test.dart`, and the missing dark tokens (`darkTextTertiary`,
`darkTextQuaternary`, `darkDivider`, `darkBorder`, `scrim`/`darkScrim`).

**Phase 2 — stop the bleeding.** Done, and by a test rather than a grep:
`test/core/design_system_guard_test.dart` reads source and fails the build on a
raw hex, a Material colour, or a role read off `SnowtrakColors` outside
`theme.dart`. It scans source rather than rendering widgets because the thing
being prevented is a line of code, not a pixel — a golden passes happily on a
correctly-coloured literal.

**Phase 3 — convert.** Done. `lib/widgets/`, `lib/ui/`, then screens by feature
area, one violation class per commit.

**Phase 4 — wire the picker.** Not started. The display settings screen
currently shows Light and says dark mode is in progress; the selection row
comes back here. Before it does, someone has to look at dark mode — see the
status note at the top of this document — and the five status colours need
their own pass, which `theme.dart` marks with a `ponytail:` comment.

### Converting was one module at a time; keeping it is not

Phase 3 ran one module per change and one violation class per commit, because a
repo-wide find-and-replace produces a diff nobody can review.

That guidance has expired. There is nothing left to convert, and new code has
no grace period: the guard fails the build the first time, so a violation never
becomes a backlog item to schedule.

### Per-file recipe

1. Replace `SnowtrakColors.<role>` with `context.colors.<role>` where the value
   is a UI colour. Leave activity-type colours alone.
1. Replace Material `Colors.*` using the mapping below. Leave
   `Colors.transparent`.
1. `context` is not available in `initState`, in a `static` member, or in a
   `const` constructor. If a colour is needed there, the widget is holding
   state it should be reading at build time — move the lookup into `build`.
1. A `const` widget constructor that took a colour usually stops being `const`.
   That is expected; do not keep `const` by reintroducing a literal.
1. Run `flutter test` and view the screen in both modes before committing.

### Mapping

Map by **role**, not by nearest hex. The old value is not evidence of intent.

| Old | Ask | New |
|---|---|---|
| `Colors.grey` on text | How prominent? | `textSecondary` / `textTertiary` / `textQuaternary` |
| `Colors.grey` on a line | Separator or outline? | `divider` / `border` |
| `Colors.grey` on an icon | Match its label | `textSecondary` / `textTertiary` |
| `Colors.grey` on a disabled control | — | `textQuaternary` |
| `Colors.grey` as a placeholder fill | — | `surfaceVariant` |
| `Colors.white` as a surface | — | `surface` |
| `Colors.white` as text or an icon on a filled control | — | `textOnPrimary` |
| `Colors.black87` as text | — | `textPrimary` |
| `Colors.black12` / `black26` / `black38` | Overlay or shadow? | `scrim` with the same alpha |

The 75 bare `Colors.grey` calls (no shade) are the ones needing judgement —
they were never a deliberate step on any ramp, so read the surrounding widget
and pick the role it wants.

## Known gaps

Tracked here rather than as TODOs, because each is a design decision, not a
missing line of code.

- **`primary` may not read as a CTA in dark mode.** Light mode puts near-black
  ink on off-white, which is emphatic. Dark mode falls back to `primaryLight`
  (`neutral700`) on `neutral950` -- a dark grey button on a darker page. A
  one-colour system has nothing else to reach for on a dark ground, so this is a
  design decision, not a code fix: invert the button, introduce a real accent
  for dark, or switch to an outlined treatment. Deferred with the rest of dark
  mode; settle it before Phase 4, not during.
- **Fifteen reads still sit on `SnowtrakColors` in `screens/`.** They are
  on-system values, not stray hex, but they read layer 1 because the palette
  has no role for what they do: the dark icon tiles behind the iOS-style
  settings rows (`neutral600`), decorative tints (`primaryLight` at 20%
  opacity), a gradient stop, an inactive indicator (`neutral300`), and the
  record screen's deliberately dark map chrome (`darkBackground`). Inventing a
  hex for these would be wrong and so would forcing them onto a role that means
  something else. Each needs a design answer first -- is there a role for an
  icon-tile background, and should decorative tints exist at all.
- **Status colours are shared across modes.** `success`, `warning`, `error`,
  `info`, and `live` use the same value in `light` and `dark`. Saturated hues on
  a dark page usually want lightening. Tune the five in `SnowtrakPalette.dark`
  when Phase 4 approaches.
- **`SnowtrakElevation` shadows are hardcoded to `ink`.** They should read
  `scrim` per mode. It is a `static` class, so this needs a small API change —
  worth doing during Phase 3.
- **The Settings theme picker is inert.** Independent of everything above:
  either wire it or mark it "coming soon". Shipping a control that lies to the
  user is its own bug.
- **`frontend/test/goldens/` is untracked** and stale against the in-progress
  design work. Regenerate with
  `flutter test --update-goldens test/design_preview_test.dart` once the current
  design state is confirmed intentional, then commit it so the golden actually
  guards something.

## Definition of done

Dark mode may be switched on when all of the following hold:

- `Colors.grey`, `Colors.white`, and `Colors.black*` return zero matches in
  `lib/screens`, `lib/widgets`, and `lib/ui`.
- Every screen a user can reach has been viewed in both modes.
- Status colours have per-mode values.
- The Settings picker drives `themeMode`, and the choice persists across a
  restart.
