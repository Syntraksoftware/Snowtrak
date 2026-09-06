# Snowtrak — Visual & Interaction Design Review

**Prepared:** 2026-08-17
**Companion to:** `SNOWTRAK_PRODUCT_REPORT.md` (strategy) · `FRONTEND_BUGS.md` (defects)
**Basis:** design tokens in `lib/core/theme.dart` + `lib/ui/liquid/`, and 26 live screen captures

> This document is about **craft**, not strategy. It asks whether Snowtrak looks
> and feels like a product people would pay attention to — separately from
> whether it does the right things.

---

## Verdict

The build is **competent but anonymous**. Nothing is ugly; almost nothing is
distinctive. It reads as a well-organised default Flutter app rather than a
skiing product with a point of view.

Three root causes, in order of impact:

| # | Problem | Why it matters |
|---|---|---|
| 1 | **The palette is stock Material Design 2**, near-verbatim | Zero brand recall. Looks like a utility, not a mountain product |
| 2 | **Everything is the same card**, so nothing has hierarchy | The eye has nowhere to land; content and chrome are indistinguishable |
| 3 | **Two competing brand blues** across the first two screens a user sees | Brand incoherence at the exact moment of first impression |

There is one screen that shows what the team can actually do — the Trails cards.
That level should be the floor, not the ceiling.

---

## 1. Colour

### 1.1 The palette is Material 2, almost verbatim

Nearly every token in `SnowtrakColors` is a stock Material Design 2 swatch:

| Token | Hex | Actually is |
|---|---|---|
| `primary` | `#1E88E5` | Material **Blue 600** |
| `primaryDark` | `#1565C0` | Blue 800 |
| `primaryLight` | `#64B5F6` | Blue 300 |
| `secondary` | `#00ACC1` | Cyan 600 |
| `success` | `#4CAF50` | Green 500 |
| `warning` | `#FF9800` | Orange 500 |
| `error` | `#E53935` | Red 600 |
| `snowboard` | `#9C27B0` | Purple 500 |
| `backcountry` | `#795548` | Brown 500 |
| `textPrimary/Secondary/Tertiary` | `#212121` / `#757575` / `#9E9E9E` | Material greys 900/600/500 |
| `background` / `surfaceVariant` | `#FAFAFA` / `#F5F5F5` | Grey 50 / 100 |
| `darkBackground` / `darkSurface` | `#121212` / `#1E1E1E` | M2 dark spec |
| `SnowtrakAuthTheme.brand` | `#0D47A1` | Blue 900 |

**Exactly one colour in the system is not off-the-shelf**: `accent` `#FF6B35`.

The file's own comment says *"Skiing-focused color palette with cool tones and
winter sports energy."* It isn't — it's the Android default palette with ski
names attached. A user cannot tell Snowtrak from any other Material app by colour.

**Recommendation.** Commission or derive a real palette. Snow is not `#FAFAFA`
white — it is blue-shadowed, and mountain light is warm at the edges. A palette
built from actual alpine reference (bluebird sky, shadowed snow, granite, larch
gold, avalanche-warning orange) would cost days and change the product's entire
perceived quality.

### 1.2 Two brand blues fight each other

| Where | Token | Hex |
|---|---|---|
| Auth screens | `SnowtrakAuthTheme.brand` | `#0D47A1` — dark navy |
| Everywhere else | `SnowtrakColors.primary` | `#1E88E5` — bright blue |

Visible across the *first two screens*: the Login button is deep navy
(`25-login.png`), then the Home tab icon and links are bright blue
(`01-home-top.png`). Same product, two identities, ten seconds apart.

Worse, `IntroductionCard` and `TrendingCard` — Home-screen components — import
`SnowtrakAuthTheme.brand`. The *auth* theme is leaking into the main app.

**Recommendation.** Pick one. Retire the other token or formally define it as a
"deep" step in a single blue ramp.

### 1.3 The accent colour only ever appears in failure

`accent` `#FF6B35` is the palette's designated "energy and excitement" colour.
In the live build, essentially the only place a user sees orange is the **GPS
warning banner** (`01-home-top.png`).

The colour meant to convey excitement has been trained to mean "something is
wrong." Use it for PRs, streaks, podium positions, powder alerts — the moments
that deserve it.

### 1.4 Token naming bug

```dart
static const Color accentDark = Color(0xFFE53935);   // this is RED, not dark orange
```

`accentDark` is identical to `error`. Any component reaching for a "darker
accent" gets an error colour instead.

### 1.5 A fifth, undocumented colour system

`11-notifications.png` renders pink / blue / teal / yellow / peach circular icon
badges. These map to neither the brand ramp nor the activity-type colours
(`alpine`, `crossCountry`, `freestyle`, `backcountry`, `snowboard`). It is a
parallel palette invented in one screen.

---

## 2. Typography

### 2.1 The scale is complete and sensible

Genuinely good: a full display → headline → body → label ramp, plus dedicated
`metricLarge` (28/bold/-0.5) and `metricMedium` for stats. Line heights and
optical letter-spacing are set deliberately. This is more rigour than most apps
at this stage.

### 2.2 …but the metric styles are not used where they matter

`metricLarge` exists precisely for activity stats. Yet on the feed card
(`02-home-scrolled.png`), **all four stats render at the same size and weight**:

```
501 m      1h 10m     55m         0.4 km/h
Distance   Time       Elevation   Speed
```

Four equal numbers = no primary metric = no glanceable meaning. Compare Strava,
where distance dominates and the rest recede. Pick the hero metric per activity
type (vertical descent for alpine, distance for cross-country), render it at
`metricLarge`, and drop the rest to `metricMedium` or `bodySmall`.

### 2.3 No typeface of its own

The app uses the platform default. It's safe and it renders cleanly, but it
contributes nothing to identity. A single distinctive display face — used *only*
for numerals and screen titles, with the system face for body — is the cheapest
available upgrade to perceived quality. Numerals matter here: this is a stats
product, and tabular figures would also fix stat columns jittering as values change.

### 2.4 Body letter-spacing is loose for iOS

`bodyLarge` carries `letterSpacing: 0.5` at 16px — a Material 2 default tuned for
Roboto. On SF Pro it reads slightly airy and un-native.

---

## 3. Layout, hierarchy and rhythm

### 3.1 The dominant problem: everything is the same card

Home stacks four visually identical containers — white surface, 1px border,
rounded corner, icon chip + title + subtitle:

| Block | Actually is |
|---|---|
| "Today's conditions" | Ambient context |
| "New to Snowtrak?" | Onboarding nudge |
| "Trending now" | Discovery |
| "Your activities" | **The actual content** |

All four carry equal visual weight. The user's own activity feed — the reason
the screen exists — is styled identically to a dismissible tutorial card.

This is why the screen feels flat despite decent individual components. **Cards
are a grouping device, not a layout.** When everything is carded, the card stops
communicating.

**Recommendation.** Establish three tiers: full-bleed content (feed items), a
carded secondary tier (context/discovery), and lightweight inline elements
(nudges, banners). Weather in particular should be a compact header strip, not a
card competing with content.

### 3.2 Content starts 1.5 screens down

On a 874pt viewport, "Your activities" begins below three full cards. A user
must scroll past ~1.5 screens of chrome to reach anything they came for. Worse,
`IntroductionCard` never dismisses, so this cost is permanent.

### 3.3 The spacing system is good and mostly respected

`SnowtrakSpacing` is a clean 8px scale (4/8/16/24/32/48), and the screens do use
it. Vertical rhythm on Home and Settings is consistent. Keep it.

### 3.4 Elevation is defined but barely used

Four shadow steps exist; the UI is almost entirely flat with 1px borders, with
`SnowtrakElevation.md` appearing on the bottom nav. That's a defensible choice —
but then the four unused tokens should go, or elevation should be adopted
deliberately to separate the content tier from the chrome tier (see 3.1).

---

## 4. Component-level notes

| Component | Assessment | Fix |
|---|---|---|
| **Bottom nav** (`01-home-top.png`) | 5 equal items at 11px. The core action — Record — is visually indistinguishable, and mislabelled "Map" with a browse-implying map icon | Centre FAB treatment; rename to "Record" |
| **Activity feed card** (`02-home-scrolled.png`) | Four equal-weight stats; no action bar; author is a bare initial avatar | Hero metric; wire in `FeedActionBar` |
| **Route thumbnail** | Pale blue box with a thin diagonal line. Low contrast, reads as a chart, and is synthetic (BUG-07) | Real route on a terrain tile, high-contrast stroke |
| **GPS banner** | Full-bleed square-cornered orange block, white text, no icon, no dismiss — violates the rounded-card language used everywhere else | Inline dismissible card, or remove |
| **Empty state** (`activities_feed_sliver.dart`) | 80px grey icon + two lines of `textTertiary` — the lowest-contrast text in the system, at the moment of highest need | Illustration + primary CTA button |
| **Trails card** (`09-groups-trails.png`) | ⭐ **The best design in the app.** Difficulty badge as a real piste marker (blue square / black diamond), rating chip, icon-led stat row, tag chips. Confident and ski-native | Use as the reference for all other cards |
| **Groups paywall** (`05-groups-active.png`) | Uses an entirely different language — huge display type, full-width pill, no card — from the tab it lives in | Remove (BUG-03); if kept, conform |
| **Notification rows** (`11-notifications.png`) | Well-structured — colour-coded circular icon, title, body, relative time, unread dot. Solid pattern | Reconcile the colours with the system palette |
| **Auth screens** (`25-login.png`) | Clean, generous, correct hierarchy, proper legal footer. The most polished screens in the app | Fix the brand-blue conflict; add `textCapitalization: none` (BUG-01) |
| **Progress chart** (`10-profile-progress.png`) | Line chart with **no y-axis, no values, no units** — the spike is unreadable | Axis labels, or replace with a bar chart with values |

---

## 5. Accessibility

This is the one area with hard failures rather than taste calls.

### 5.1 Text contrast fails WCAG AA

Measured against the `#FAFAFA` background:

| Token | Hex | Contrast | WCAG AA (4.5:1) |
|---|---|---|---|
| `textPrimary` | `#212121` | ~15.9 : 1 | ✅ Pass |
| `textSecondary` | `#757575` | **~4.4 : 1** | ❌ **Fail** (marginal) |
| `textTertiary` | `#9E9E9E` | **~2.6 : 1** | ❌ **Fail badly** |

`textTertiary` fails even the 3:1 large-text threshold. It is used for empty-state
copy, card subtitles and metadata — including *"Start recording your first
skiing activity!"*, the single most important sentence a new user reads.

**Fix:** darken to roughly `#6B6B6B` (secondary) and `#8A8A8A`→`#767676`
(tertiary). This is a two-line change with outsized impact, and it matters more
than usual here: **this app is used outdoors, in glare, on snow**, by users
wearing goggles. Contrast is not a compliance checkbox for a ski product — it is
a core usability requirement.

### 5.2 Dark mode is fully built and switched off

`darkTheme` is complete, with a proper dark token ramp. `main.dart:93` hardcodes
`themeMode: ThemeMode.light`.

Skiers check this app in lodges, in the evening, and on dark chairlift rides. The
work is already paid for.

### 5.3 Custom painters are invisible to screen readers

`activity_route_preview_painter.dart` and `progress_weekly_graph_painter.dart`
render via `CustomPainter` with no `Semantics` wrapper — confirmed during the
live audit, where `idb ui describe-all` could not see them. Wrap with a semantic
label summarising the data.

### 5.4 Tap targets

Bottom-nav labels at 11px are acceptable per iOS HIG, but several icon-only
controls (the `⋮` overflow on `20-activity-detail.png`, chart controls) should be
verified against the 44×44pt minimum — this needs a device check I have not run.

---

## 6. What is genuinely good

Worth saying plainly, because the list above is long.

| Area | Why it's good |
|---|---|
| **Token architecture** | Colour, type, spacing, radius and elevation are all centralised and consistently imported. Re-theming this app is a small job precisely because the structure is right |
| **Type scale** | Complete, deliberate, with purpose-built metric styles. Better than most pre-launch apps |
| **8px spacing discipline** | Actually followed across screens |
| **Auth flow visual design** | Clean, confident, well-proportioned |
| **Trails cards** | Genuinely ski-native design thinking — the difficulty badges show someone who understands the domain |
| **Threads UI** | Reply trees, quote embeds, media galleries and the action bar are all properly built |
| **Icon discipline** | Consistent outlined/filled pairs for nav states |

**The craft ceiling is not the problem.** The Trails cards and auth screens prove
the team can design well. The problem is that this quality was applied
inconsistently, and the foundation underneath it is borrowed rather than authored.

---

## 7. Recommended design work, in order

| # | Work | Effort | Impact |
|---|---|---|---|
| 1 | Fix contrast tokens (`textSecondary`, `textTertiary`) | Hours | Compliance + real outdoor usability |
| 2 | Resolve the two-blue conflict; stop importing auth theme into Home | Hours | Brand coherence at first impression |
| 3 | Enable dark mode | Hours | Already built |
| 4 | Introduce the three-tier hierarchy on Home; demote weather to a header strip | Days | Fixes the flatness |
| 5 | Hero-metric treatment on activity cards using `metricLarge` | Days | Glanceability of the core content |
| 6 | Author a real alpine palette to replace Material defaults | Days | The single biggest change to perceived quality |
| 7 | Adopt a display typeface for titles + tabular numerals for stats | Days | Identity + stat legibility |
| 8 | Bring every card up to the Trails-card standard | Weeks | Consistency at the good level |

Items 1–3 are effectively free and should ship with the Phase 0 defect fixes in
`SNOWTRAK_PRODUCT_REPORT.md`. Items 6–7 are where a designer earns their keep.
