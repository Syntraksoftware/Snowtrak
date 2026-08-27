# Snowtrak — Frontend UX & Product Audit

**Date:** 2026-08-16
**Branch:** `fix/ci-and-secrets`
**Scope:** `frontend/lib/screens/**` — 18,150 LOC across 23 screens
**Method:** static source audit (no emulator run — see `## Appendix A`)

**Product frame**

| | |
|---|---|
| Audience | Skiers, snowboarders, outdoor community |
| Value prop | Strava × Threads for snow — track runs, build a skiing community |
| Business goal 1 | Onboarding completion |
| Business goal 2 | Daily active retention |
| Business goal 3 | Stats collection on average skier performance |

**Headline finding**

> 23 screens, **zero onboarding**. Two of three business goals (onboarding
> completion, skier stats) have no supporting UI at all. The third (daily
> retention) is served by a Home tab that shows a user only their own data,
> with no way to react to anyone else's.

---

## 1. Screen inventory

### 1.1 Navigation architecture

| Aspect | Current state |
|---|---|
| Router | **None.** `MaterialApp.home` + `Navigator.push` |
| Root gate | `main.dart:_AppWrapper` → `isAuthenticated ? HomeScreen : LoginScreen` |
| Shell | `HomeScreen` — `PageView` of 5 tabs, default index `2` |
| Deep links | Not supported |
| Theme mode | `ThemeMode.light` hardcoded despite a full `darkTheme` being defined |

### 1.2 Auth

| # | Screen | File | LOC | Entry point |
|---|---|---|---|---|
| 1 | `LoginScreen` | `screens/auth/login_screen.dart` | 148 | App launch, unauthenticated |
| 2 | `RegisterScreen` | `screens/auth/register_screen.dart` | 152 | Push from Login |

### 1.3 Tab shell

| # | Screen | Tab label | Icon | Index | LOC |
|---|---|---|---|---|---|
| 3 | `RecordScreen` | "Map" | `map_outlined` | 0 | 856 |
| 4 | `CommunityScreen` → `ThreadsTab` | "Community" | `forum_outlined` | 1 | 24 + 854 |
| 5 | `ActivitiesScreen` | "Home" | `home_outlined` | 2 ← **landing** | 141 |
| 6 | `GroupsScreen` | "Groups" | `group_outlined` | 3 | 65 |
| 7 | `ProfileScreen` | "You" | `person_outline` | 4 | 105 |

### 1.4 Sub-tabs

| Parent | Sub-tabs | Data source |
|---|---|---|
| `GroupsScreen` | Active, Challenges, Clubs, Trails | **All mock** |
| `ProfileScreen` | Overview, Progress | Mixed real / placeholder |

### 1.5 Pushed destinations

| # | Screen | File | LOC | Reachable from |
|---|---|---|---|---|
| 8 | `ActivityDetailScreen` | `screens/activities/activity_detail_screen.dart` | 653 | Feed card, post-save |
| 9 | `ThreadDetailScreen` | `screens/community/thread_detail_screen.dart` | 515 | Threads feed |
| 10 | `NewThreadDraftScreen` | `screens/community/new_thread_draft_screen.dart` | 315 | Composer |
| 11 | `UserProfileScreen` | `screens/profile/user_profile_screen.dart` | 273 | Post author tap |
| 12 | `EditProfileScreen` | `screens/profile/edit_profile_screen.dart` | 227 | Profile |
| 13 | `NotificationsScreen` | `screens/notifications/notifications_screen.dart` | 393 | Bell icon |
| 14 | `SettingsScreen` | `screens/settings/settings_screen.dart` | 328 | Profile |
| 15 | `MapsScreen` | `screens/maps/maps_screen.dart` | 585 | ⚠️ **Nothing — 0 references** |

### 1.6 Settings sub-screens

| # | Screen | LOC | Notes |
|---|---|---|---|
| 16 | `NotificationsSettingsScreen` | 305 | Toggles are local `setState`, not persisted |
| 17 | `PrivacySettingsScreen` | 412 | 2 × "coming soon" |
| 18 | `AccountSettingsScreen` | 348 | 5 × "coming soon" |
| 19 | `ActivitySettingsScreen` | 351 | |
| 20 | `DisplaySettingsScreen` | 301 | 1 × "coming soon" |
| 21 | `DataStorageScreen` | 411 | 2 × "coming soon" |
| 22 | `HelpSupportScreen` | 409 | |
| | **Total settings** | **~2,900** | ~16% of all screen code |

### 1.7 Modals & sheets

| Component | Trigger |
|---|---|
| `LocationPermissionDialog` | `HomeScreen.initState`, +500ms after landing |
| `RecordBottomSheet` | Record tab |
| `_GpsDeniedSheet` | GPS permission denied |
| `CommunityRepostSheet` | Repost action |
| `ThreadReplyDialog` / `ThreadExpandedReplySheet` | Reply action |
| `TrailsFilterSheets` | Groups → Trails |

### 1.8 Screens that should exist and do not

| Missing screen | Consequence |
|---|---|
| Welcome / value prop | Cold install lands on a bare login form |
| Profile setup (post-register) | `skiLevel` + `home` never collected → **no stats dataset** |
| Permission primer | OS location prompt fires cold, with no context |
| Post-save activity summary | Peak-pride moment produces zero social content |
| Discover / search people | No way to build a social graph |
| Follow / follower lists | Counters render against nothing |

---

## 2. Redesign matrix — sorted by business value

### 🔴 P0-1 — Onboarding flow

| Field | Detail |
|---|---|
| **Page name** | Onboarding / Welcome / Profile setup |
| **Route** | **Does not exist.** `main.dart:_AppWrapper` → `LoginScreen` |
| **PM priority** | **P0 — revenue-blocking** |

**Diagnosis**

| Problem | Evidence |
|---|---|
| No value prop before the auth wall | `main.dart` — `isAuthenticated ? HomeScreen : LoginScreen` |
| Apple + Google sign-in are decorative stubs | `login_screen.dart:57`, `register_screen.dart:58` — `_showComingSoon()` |
| Sign-up demoted to a text link below an "Or" divider | `login_screen.dart:139` |
| No profile setup after registration | `register_screen.dart` → straight to `HomeScreen` |
| Ski level / home mountain never collected | Fields exist in `models/profile.dart:8-9`, editable only as free-text at `edit_profile_screen.dart:202-209` |
| Location prompt fires cold, uncontextualised | `home_screen.dart:56` — 500ms after landing |

**Strategic objective**

| Metric | Why |
|---|---|
| Install → sign-up start rate | Primary funnel leak |
| Sign-up completion rate | Business goal 1 |
| % new users with ski level + home resort | **Business goal 3's only possible input** |
| D0 first-recording rate | Predicts D7 retention |

**Key changes**

| # | Change | Type |
|---|---|---|
| 1 | 3–4 screen value-prop carousel before auth (track · share · compete) | New flow |
| 2 | **Sign up** as primary CTA, *Log in* demoted to secondary | Structural |
| 3 | Ship real Apple + Google sign-in (Apple is App Store–mandatory once you offer third-party auth) | Functional |
| 4 | Post-register setup: ski level chips → home resort search → units → follow 3–5 skiers | New flow |
| 5 | Move permission request into onboarding, behind an explainer screen | Structural |
| 6 | Allow browse-before-signup; gate at record/post, not at launch | Structural |

---

### 🔴 P0-2 — Home / Activities feed

| Field | Detail |
|---|---|
| **Page name** | Home (Activities feed) |
| **Route** | `ActivitiesScreen` — tab index 2, **default landing screen** |
| **PM priority** | **P0 — revenue-blocking** (this is the retention surface) |

**Diagnosis**

| Problem | Evidence |
|---|---|
| It is a solo logbook, not a social feed — only your own activities | `activities_feed_sliver.dart` |
| Other users render as the literal string `'Athlete'` | `activities_feed_sliver.dart:135` |
| "Trending now" is two hardcoded strings | `trending_card.dart:23-32` — "Powder day at Whistler" |
| "New to Snowtrak?" card is permanent — a 6-month user still sees it | `introduction_card.dart` — no dismiss, no lifecycle gate |
| **No kudos, no comments, no share on activity cards** | grep: 0 matches in `activity_feed_card.dart` |
| …despite the component already existing for threads | `widgets/feed_action_bar.dart` — like / comment / repost / share |
| 4 blocks above the fold before any content | `activities_screen.dart:111-133` — header, weather, intro, trending |
| Empty state is a dead end — no CTA button | `activities_feed_sliver.dart:27-70` |

**Strategic objective**

| Metric | Why |
|---|---|
| Sessions / user / week | Business goal 2 |
| Kudos given per DAU | Cheapest engagement loop in the category |
| Feed scroll depth | Content-density proxy |
| D1 / D7 return rate | Core retention |

**Key changes**

| # | Change | Type |
|---|---|---|
| 1 | Convert to a real social feed: followed athletes + resort-local activity | Structural |
| 2 | Resolve real athlete names and avatars | Functional |
| 3 | **Add kudos + comment to `ActivityFeedCard` — reuse `FeedActionBar`** | Functional (component exists) |
| 4 | Replace static `TrendingCard` with live data (resorts active today, challenge leaderboards) | Functional |
| 5 | Make `IntroductionCard` dismissible + gated (first 3 sessions, or 0 activities) | Structural |
| 6 | Empty state gets a primary "Record your first run" button + suggested-skiers row | Layout |
| 7 | Collapse weather into a compact header strip — it is context, not content | Layout |

---

### 🔴 P0-3 — Record screen

| Field | Detail |
|---|---|
| **Page name** | Record (currently labelled "Map") |
| **Route** | `RecordScreen` — tab index 0 |
| **PM priority** | **P0 — revenue-blocking** (core value action) |

**Diagnosis**

| Problem | Evidence |
|---|---|
| Core action is the leftmost tab, named "Map", with a map icon that reads "browse" | `home_screen.dart:103-107` |
| Tabs are a `PageView` — a horizontal swipe abandons an active recording | `home_screen.dart:88` |
| Post-save drops into `ActivityDetailScreen`: no share, no PR callout, no summary moment | `record_screen.dart:520` |
| Error view tells users "Map functionality is coming soon" on a core path | `record_error_view.dart:47` |

**Strategic objective**

| Metric | Why |
|---|---|
| % DAU who start a recording | **The input to every stat you want to collect** |
| Recording completion rate | Data quality |
| Saved run → community post rate | Bridges the two halves of the product |

**Key changes**

| # | Change | Type |
|---|---|---|
| 1 | Rename tab to **"Record"**; distinguished centre FAB in the nav bar | Structural |
| 2 | Lock swipe navigation while recording (`NeverScrollableScrollPhysics`) | Functional |
| 3 | **Post-save summary screen**: stats + route map + auto-detected PRs + one-tap "Share to Community" | New screen |
| 4 | Rewrite error copy — never ship "coming soon" on a core path | Content |

---

### 🟠 P1-1 — Groups

| Field | Detail |
|---|---|
| **Page name** | Groups (Active / Challenges / Clubs / Trails) |
| **Route** | `GroupsScreen` — tab index 3 |
| **PM priority** | **P1 — high friction / high impact** (credibility risk) |

**Diagnosis**

| Problem | Evidence |
|---|---|
| Trails tab is mock data | `trails_tab.dart:53` — `mockSkiTrails()` |
| Active tab is mock data | `active_tab.dart:18` — `mockGroupChallenges()` |
| Joining a challenge does nothing | `challenges_tab.dart:205` — `// TODO` |
| Creating a club does nothing | `clubs_tab.dart:159` — `// TODO` |
| Search does nothing | `groups_screen.dart:48` — `// TODO` |
| Paywall stub in a shipping build | `active_tab.dart:90` — "Start free trial coming soon!" |
| Tapping a challenge yields a snackbar | `active_tab_widgets.dart:69` |

> **20% of the primary navigation is non-functional.** This is the fastest way
> to lose a user's trust in the entire product.

**Strategic objective**

| Metric | Why |
|---|---|
| — (near term) | **Do not optimise — shrink.** Free the nav slot |
| Challenge join rate → W2 retention (later) | Strongest known retention mechanic in this category |

**Key changes**

| # | Change | Type |
|---|---|---|
| 1 | **Remove Groups from the bottom nav** | Structural |
| 2 | Ship ONE real mechanic — a seasonal vertical-metres challenge with a live leaderboard — surfaced as a Home feed card | Functional |
| 3 | Reuse the freed slot for **Discover** (people / resort search), which currently exists nowhere | Structural |
| 4 | Trails data is real from OpenSkiMap — fold it into the map surface, not a mock list tab | Structural |

---

### 🟠 P1-2 — Community / Threads

| Field | Detail |
|---|---|
| **Page name** | Community (Threads feed) |
| **Route** | `CommunityScreen` → `ThreadsTab` — tab index 1 |
| **PM priority** | **P1 — high friction / high impact** |

**Diagnosis**

| Problem | Evidence |
|---|---|
| Best-built surface in the app — real like / comment / repost / share, media upload, optimistic outbox | `threads_tab.dart` (854 LOC), `feed_action_bar.dart` |
| **…but completely severed from ski data — you cannot post a run** | grep `activity` in `models/post.dart` → 0 matches |
| **No follow system anywhere in the app** | grep — only notification copy + a mock "Alex started following you" (`notification_provider.dart:209`) |
| No topics, resort channels, or discovery | — |
| Result: neither Strava's proof-of-effort nor Threads' network effect | — |

**Strategic objective**

| Metric | Why |
|---|---|
| Posts / user / week | Content supply |
| **Follows per new user in week 1** | Strongest known retention predictor in social products |
| Reply rate | Conversation depth |

**Key changes**

| # | Change | Type |
|---|---|---|
| 1 | **`Post.activityId` + route-map/stats embed card** — the one change that makes Snowtrak neither a Strava clone nor a Threads clone | Functional |
| 2 | Build **follow** end to end: button on `UserProfileScreen`, real follower/following lists | Functional |
| 3 | Resort / mountain channels so an empty global feed still has locally relevant content | Structural |
| 4 | Feed ranking beyond chronological, once volume exists | Functional |

---

### 🟠 P1-3 — Profile Overview

| Field | Detail |
|---|---|
| **Page name** | Profile → Overview |
| **Route** | `ProfileScreen` → Overview tab (`profile_home_content.dart`) |
| **PM priority** | **P1 — high friction / high impact** |

**Diagnosis**

| Problem | Evidence |
|---|---|
| Four placeholder blocks advertise features that do not exist | `profile_home_content.dart:80, 176, 182, 203` |
| "Virtual gear locker" — not built | `profile_home_content.dart:82` |
| **"Personal records — 5K, 10K and segment bests"** — *running* metrics on a *skiing* app | `profile_home_content.dart:178` |
| "Fitness trends — fitness, fatigue, form" — not built | `profile_home_content.dart:184` |
| Followers / Kudos / Comments counters render with no backing system | `profile_home_content.dart:229-250` |
| Sport chips hardcoded `selected: true`, not user state | `profile_home_content.dart:67` |

**Strategic objective**

| Metric | Why |
|---|---|
| Profile completion rate | Feeds your stats dataset (business goal 3) |
| Profile view → follow conversion | Graph density |

**Key changes**

| # | Change | Type |
|---|---|---|
| 1 | Delete every placeholder block — an honest short profile beats a long fake one | Structural |
| 2 | Lead with **season stats**: days on snow, vertical metres, top speed, resorts visited — ski-native, not running metrics | Functional |
| 3 | Inline-editable identity (avatar, level chips, home mountain) instead of a separate `EditProfileScreen` + completion nudge | Structural |
| 4 | Make sport chips real selections that feed segmentation | Functional |

---

### 🟡 P2 — Lower priority

| Screen | Route | Problem | Evidence | Action |
|---|---|---|---|---|
| Activity detail | `ActivityDetailScreen` | No share, no kudos, no comments | grep → 0 matches | Add social actions + shareable run-card image |
| Settings ×8 | `SettingsScreen` + 7 | ~2,900 LOC pre-PMF; toggles are local `setState`, never persisted | `notifications_settings_screen.dart:18` | Collapse to 2 screens; wire persistence or remove the toggles |
| Maps | `MapsScreen` | 585 LOC, **zero references — unreachable** | grep `MapsScreen` → 0 external refs | Delete, or promote as the Discover surface |
| Notifications | `NotificationsScreen` | Mock notification data | `notification_provider.dart:207-209` | Wire real events once follow / kudos ship |
| Theme | `main.dart` | `ThemeMode.light` hardcoded despite a full `darkTheme` | `main.dart:93` | Enable system dark mode — skiers use this at night and on-mountain |

---

## 3. Recommended sequence

| Phase | Work | Unblocks |
|---|---|---|
| 1 | P0-1 onboarding + real social auth + profile setup | Goals 1 and 3 |
| 2 | P0-3 record tab promotion + post-save share moment | Goal 3 data volume |
| 3 | P0-2 social feed + kudos on activity cards | Goal 2 |
| 4 | P1-2 follow system + activity-attached posts | Goal 2 compounding |
| 5 | P1-1 cut Groups → ship one real challenge; P1-3 profile cleanup | Trust |
| 6 | P2 cleanup: delete `MapsScreen`, collapse settings, dark mode | Maintenance |

---

## Appendix A — Why no screenshots

This audit is a **static source read**. Live UI verification requires booting an
iOS simulator; see `docs/EMULATOR_ACCESS.md` for the setup that grants an agent
screenshot and navigation control.

## Appendix B — Tooling notes

| Ask | Verdict |
|---|---|
| Playwright MCP | **Not applicable.** Snowtrak is a Flutter *mobile* app; Playwright drives browsers. Also, `claude mcp add` does not affect an already-running session. |
| "Pencil AI" design canvas | No such integration available. The equivalent is `DesignSync` → a **claude.ai/design** design-system project, which keeps canvas and component code in sync. `lib/ui/liquid/` + the card components are the natural first push. |
