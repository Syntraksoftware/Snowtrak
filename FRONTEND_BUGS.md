# Snowtrak — Live Defect Log

**Date:** 2026-08-16
**Method:** iPhone 17 Pro simulator (iOS 26.5), `main_dev.dart` against local Docker backends, driven with `idb`
**Test account:** `claude.audit@example.com` — created via API, **zero** real activity
**Screenshots:** `screenshots/` (26 captures)

> Everything below was observed on a running build, not inferred from source.
> The account was minutes old, which is exactly why so much of what it displays
> should not exist.

**Backend state during capture**

| Service | Port | Status |
|---|---|---|
| main-backend | 8080 | ✅ 200 |
| community-backend | 5001 | ✅ 200 |
| activity-backend | 5100 | ✅ 200 |
| map-backend | 5200 | ❌ crash-loop — see BUG-04 |

---

## Severity summary

| Sev | Count | Theme |
|---|---|---|
| 🔴 P0 | 4 | Account lockout, fabricated social proof, fake paywall, service down |
| 🟠 P1 | 9 | Broken data rendering, missing engagement loop, stale content |
| 🟡 P2 | 5 | Polish, dead code, wrong base map |

---

## 🔴 P0 — Critical

### BUG-01 · iOS autocapitalisation can permanently lock users out of their account

| | |
|---|---|
| **Screen** | Register / Login |
| **Evidence** | Live capture — typed email rendered as `Claude.audit@example.com` |
| **Files** | `ui/liquid/` → `AuthLabeledField`; `screens/auth/register_screen.dart:41`; `services/apis/auth_api.dart:36` |

iOS capitalises the first character of the email field because `AuthLabeledField`
never sets `textCapitalization: TextCapitalization.none` (nor
`autocorrect: false`). `keyboardType: TextInputType.emailAddress` alone does not
suppress it.

The two auth paths then disagree:

| Path | Normalisation | Result |
|---|---|---|
| `auth_api.dart:36` login | `.trim().toLowerCase()` | sends `claude.audit@…` |
| `register_screen.dart:41` register | `.trim()` only | stores `Claude.audit@…` |

**Failure:** user signs up on a real iPhone → account stored capitalised → user
later logs in → lookup runs lowercased → no match → **cannot ever log in**, and
"forgot password" on the lowercased address won't find them either. Affects
every organic iOS signup.

**Fix:** set `textCapitalization: none` + `autocorrect: false` on the field, and
lowercase in `register_screen.dart` to match login. Verify backend lookup
case-sensitivity, and audit existing rows for capitalised emails.

---

### BUG-02 · App fabricates social proof that does not exist

| | |
|---|---|
| **Screen** | Notifications |
| **Evidence** | `screenshots/11-notifications.png` |
| **File** | `providers/notification_provider.dart:207-209` |

An account **created minutes earlier, with no activities and no social graph**,
displays a full notification history:

| Notification | Why it is impossible |
|---|---|
| "Sarah gave kudos to your morning ski run" | User has never recorded a run |
| "Mike commented: 'Amazing run! What trail was that?'" | No activity to comment on |
| "Alex started following you" | **No follow system exists anywhere in the app** |
| "You're 75% done with the January Challenge!" | It is August; challenge never joined |
| "You unlocked 'Early Bird' — 10 runs before 9 AM" | Zero runs recorded |
| "Emma completed a 15km cross-country ski" | No friends, no follow graph |

Also renders an unread badge of **3** on a new account.

This is the single most damaging screen in the build. It manufactures the exact
engagement the product does not yet have, and a user discovers the deception the
moment they tap anything. Fabricated engagement metrics are also an App Store
review risk.

**Fix:** delete the seeded notifications. Ship a real empty state.

---

### BUG-03 · Non-existent subscription advertised on a primary nav tab

| | |
|---|---|
| **Screen** | Groups → Activity |
| **Evidence** | `screenshots/05-groups-active.png` |
| **File** | `screens/groups/active_tab.dart:90` |

Above the fold on a bottom-nav destination:

> **SYNTRAK SUBSCRIPTION**
> **Design Your Own Challenge**
> Rally your crew with a custom Group Challenge. Your game, your rules.
> **[ Start Your Free Trial ]**

Tapping the CTA shows a snackbar: *"Start free trial coming soon!"*

Advertising a paid tier that cannot be purchased, as the most prominent element
of a nav tab. Remove until billing is real.

---

### BUG-04 · map-backend crash-loops; one bad credential kills the whole service

| | |
|---|---|
| **Screen** | — (backend) |
| **Evidence** | `docker logs snowtrak-map-backend` |
| **Files** | `backend/map-backend/application.py:119-125`; `backend/db/connection.py:48` |

```
asyncpg.exceptions.InvalidPasswordError: password authentication failed for user "postgres"
ERROR:    Application startup failed. Exiting.
```

Verified independently of the app with `psql` from a clean container: DNS
resolves, TCP :6543 reachable, **auth rejected**. The Supabase credential in
`backend/map-backend/.env` is stale.

The design flaw is worse than the credential. `create_pool()` already degrades
gracefully when the DSN is *absent* (`connection.py:48` logs "pool disabled" and
continues — its docstring says *"map-backend can run without a local DB"*), and
`trails_service/infra.py:17` already returns a clean `503` for exactly this
state. But a **bad** DSN throws inside `lifespan`, so startup aborts and the
whole service dies — static maps, elevation, every endpoint — then crash-loops
silently under `restart: unless-stopped`.

**Fix:** rotate the credential; wrap `create_pool` in try/except so a credential
failure degrades to 503 on trail endpoints instead of killing the service.

> ⚠️ This password was exposed in plaintext during the audit session (a faulty
> redaction). It is not in git and not in any tracked file, but **rotate it**.

---

## 🟠 P1 — High

### BUG-05 · Every activity author renders as the literal string "Athlete"

| | |
|---|---|
| **Screen** | Home feed |
| **Evidence** | `screenshots/02-home-scrolled.png` |
| **File** | `screens/activities/widgets/activities_feed_sliver.dart:135` |

Every card shows author **"Athlete"** with an "A" avatar. There is no name
resolution for other users. A social feed where nobody has a name.

---

### BUG-06 · Mock activities render as degenerate, impossible data

| | |
|---|---|
| **Screen** | Home feed, Activity detail |
| **Evidence** | `screenshots/02-home-scrolled.png`, `screenshots/20-activity-detail.png` |
| **File** | `screens/activities/activities_screen_controller.dart:17` — `loadMockActivities()` |

| Field | "Updated name" | "Untitled Activity" | "Evening Alpine" (detail) |
|---|---|---|---|
| Distance | 501 m | **0 m** | **0 m** |
| Time | 1h 10m | **0m** | **0s** |
| Elevation | 55 m | **0m** | **+0 m** |
| Speed | **0.4 km/h** | `--` | `--` |
| Start / End | — | — | **identical timestamp** |

`0.4 km/h` is slower than walking. Activity names are `"Updated name"` and
`"Untitled Activity"` — clearly test fixtures. The detail screen's map is
centred on **Hong Kong** with no route drawn: a ski activity where there is no
snow. These appear on a brand-new account with dates in January and March.

---

### BUG-07 · Route thumbnails are synthetic, not real GPS tracks

| | |
|---|---|
| **Screen** | Home feed |
| **Evidence** | `screenshots/02-home-scrolled.png` |
| **File** | `screens/activities/widgets/activity_route_preview_painter.dart` |

The map thumbnail draws a smooth diagonal blue line across a blank placeholder
tile — the same shape regardless of the activity. It looks like a route but
represents nothing. For a tracking app, a fake route line is worse than no map.

---

### BUG-08 · No kudos, comment or share on activity cards

| | |
|---|---|
| **Screen** | Home feed, Activity detail |
| **Evidence** | `screenshots/02-home-scrolled.png`, `screenshots/20-activity-detail.png` |

Cards end after the map thumbnail. No engagement affordance anywhere on the
Strava half of the product — while `widgets/feed_action_bar.dart` already
implements like / comment / repost / share and is used by Community threads.
The component exists; it is simply not wired to activities.

---

### BUG-09 · Expired challenges presented as "Available challenges"

| | |
|---|---|
| **Screen** | Groups → Activity |
| **Evidence** | `screenshots/05-groups-active.png` |

Today is **Aug 16 2026**. Listed under "Available challenges":

| Challenge | Window | State |
|---|---|---|
| January Vertical Challenge | Jan 1 – Jan 31 2026 | **ended 7 months ago** |
| Winter Explorer Challenge | Dec 1 2025 – Mar 31 2026 | **ended 4 months ago** |

No date filtering, no empty state for the off-season.

---

### BUG-10 · Progress tab contradicts itself

| | |
|---|---|
| **Screen** | Profile → Progress |
| **Evidence** | `screenshots/10-profile-progress.png` |

Simultaneously on one screen:

- "No active streak"
- "This week — **0.0 km / 0m / 0 m**"
- "No best efforts yet"
- …and a **"Past 12 weeks" chart with a large spike in June/July**

Either the user has history or they don't. The chart also has **no y-axis, no
values and no units** — the spike is unreadable. On a brand-new account, 12
weeks of history should not exist at all.

---

### BUG-11 · Location permission flow leaves a permanent banner and a dead weather card

| | |
|---|---|
| **Screen** | Home |
| **Evidence** | `screenshots/01-home-top.png` |
| **File** | `screens/home/home_screen.dart:56` |

The permission sheet fires 500 ms after Home first renders — cold, before the
user has seen anything worth granting for. Choosing "Not Now" leaves a
**full-width orange banner** — *"We need your GPS service to record activities…"*
— parked above the tab bar with **no dismiss control**, permanently eating
content space.

Separately: after granting location at OS level via `simctl privacy grant`, the
weather card stayed stuck at *"Enable location or pull to refresh."* It does not
re-check permission state.

---

### BUG-12 · Profile shows hardcoded clubs and sports for a new user

| | |
|---|---|
| **Screen** | Profile → Overview |
| **Evidence** | `screenshots/06-profile-overview.png` |
| **File** | `screens/profile/widgets/profile_home_content.dart:67, 90` |

A user who has set nothing sees **"Alpine" pre-selected** and club chips
**"Alpine Club"** and **"Corp Team"** — neither of which they joined, and for
which no club system exists. Alongside a "Virtual gear locker" placeholder for
an unbuilt feature.

---

### BUG-13 · Community feed shows skeletons for several seconds

| | |
|---|---|
| **Screen** | Community |
| **Evidence** | `screenshots/04-community-threads.png` (skeleton) vs `22-community-retry.png` (loaded) |

First capture after tab switch showed four skeleton rows; content only appeared
on a later capture. No cache-then-revalidate on the main social surface, so every
tab switch is a cold load.

---

## 🟡 P2 — Lower priority

| ID | Screen | Issue | Evidence |
|---|---|---|---|
| BUG-14 | Record | Base map is a generic **city street map** (Cupertino, "Junipero Serra Freeway", bus stops, transit lines) — no terrain, no pistes, no resort context on a skiing app | `03-record-map.png` |
| BUG-15 | Groups → Trails | 8 hardcoded trails with invented ratings (Peak to Creek 4.8, Corbet's Couloir 4.9); tapping any → "coming soon" snackbar; search + filters non-functional | `09-groups-trails.png` |
| BUG-16 | Global | `ThemeMode.light` hardcoded despite a complete `darkTheme` being defined | `main.dart:93` |
| BUG-17 | Maps | `MapsScreen` — 585 LOC, **zero references**, unreachable dead code | grep |
| BUG-18 | Settings | 8 screens / ~2,900 LOC; toggles are local `setState` and do not persist | `13-set-notifications.png` |

---

## Screenshot index

| File | Screen |
|---|---|
| `01-home-top.png` | Home — top of feed, GPS banner |
| `02-home-scrolled.png` | Home — "Your activities", BUG-05/06/07/08 |
| `03-record-map.png` | Record tab |
| `04-community-threads.png` | Community — skeleton state |
| `05-groups-active.png` | Groups → Activity — BUG-03, BUG-09 |
| `06-profile-overview.png` | Profile → Overview |
| `07-groups-challenges.png` | Groups → Challenges |
| `08-groups-clubs.png` | Groups → Clubs |
| `09-groups-trails.png` | Groups → Trails |
| `10-profile-progress.png` | Profile → Progress — BUG-10 |
| `11-notifications.png` | Notifications — BUG-02 |
| `12-settings.png` | Settings root |
| `13`–`19` | Settings sub-screens ×7 |
| `20-activity-detail.png` | Activity detail — BUG-06 |
| `21-edit-profile.png` | Edit profile |
| `22-community-retry.png` | Community — loaded |
| `23-new-thread-composer.png` | New thread composer |
| `24-record-activity-select.png` | Record — activity type sheet |
| `25-login.png` | Login (logged out) |
| `26-register.png` | Register |

## Reproducing

```bash
cd backend && docker compose up -d
brew services stop redis                     # frees :6379 for the compose redis
cd frontend && flutter build ios --simulator --debug \
  -t lib/main_dev.dart --dart-define-from-file=.env.local.json
xcrun simctl boot 7FEE8D75-DFBC-4935-B6D2-A1FA90DF0AED
xcrun simctl install booted build/ios/iphonesimulator/Runner.app
xcrun simctl launch  booted com.syntrak.snowtrak.app
idb ui tap --udid <UDID> <x> <y>             # points, not pixels
xcrun simctl io booted screenshot out.png
```
