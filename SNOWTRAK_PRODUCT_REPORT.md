# Snowtrak — Product & UX Assessment

**Prepared:** 2026-08-17
**Build:** branch `fix/ci-and-secrets`, `main_dev.dart` on iPhone 17 Pro (iOS 26.5)
**Scope:** 23 screens / 18,150 LOC of Flutter UI, plus the backend services they depend on

---

## TL;DR

Snowtrak has a **credible technical foundation and a real Threads-style social
engine**, wrapped in a product that a new user cannot onboard into, cannot get
value from, and — in several places — is actively misled by.

Three findings drive everything else:

1. **There is no onboarding.** The app opens on a bare login form. Two of your
   three business goals have no supporting UI whatsoever.
2. **A signup bug can permanently lock iOS users out of their own accounts.**
   This is live, affects every organic iPhone signup, and outranks all design work.
3. **The app fabricates social activity that does not exist** — kudos, followers,
   challenge progress — on accounts minutes old. This is a trust and App Store risk.

The redesign is worth doing. It should not start until the first two are fixed.

---

## Method

| | |
|---|---|
| Static audit | Full read of `frontend/lib/screens/**` and supporting providers/services |
| Live audit | App built and run on simulator against local Docker backends, driven with `idb`, 26 screens captured |
| Test account | Created via API with **zero** activity — deliberately, to see the true new-user experience |
| Evidence | `screenshots/` (local, gitignored) |

Running it live mattered. Six of the eighteen defects were invisible in source —
including the account-lockout bug, the undismissable GPS banner, and the
self-contradicting Progress tab.

---

## The core diagnosis

Snowtrak is positioned as **Strava × Threads for skiing**. In the current build,
those are two apps sharing a binary.

The Threads half is genuinely built: real like / comment / repost / share, media
upload, optimistic outbox. The Strava half has **no engagement affordance at
all** — activity cards have no kudos, no comments, no share, even though the
component that does exactly that already exists and is wired into Community.

Between them sits nothing. `Post` has no reference to an activity, so **you
cannot post a run**. And there is **no follow system anywhere in the app** — no
button, no lists, no backing — so neither half has a social graph.

The result is an app with neither Strava's proof-of-effort nor Threads' network
effect, where the default landing tab shows a user only their own data with no
way to react to anyone else's.

---

## Part 1 — Ship blockers

These are defects, not design debt. Full detail in `FRONTEND_BUGS.md`.

| ID | Defect | Impact |
|---|---|---|
| **BUG-01** | Email autocapitalisation → permanent account lockout | Every organic iOS signup |
| **BUG-02** | Fabricated kudos / followers / challenge progress on new accounts | Trust; App Store review risk |
| **BUG-03** | Non-existent subscription advertised on a nav tab | Trust; store compliance |
| **BUG-04** | `map-backend` crash-loops on one stale credential | Entire map service down |

### BUG-01 in detail — the one to fix today

`AuthLabeledField` never sets `textCapitalization: none`, so iOS capitalises the
email field. The two auth paths then disagree:

| Path | Normalisation |
|---|---|
| `auth_api.dart:36` — login | `.trim().toLowerCase()` |
| `register_screen.dart:41` — register | `.trim()` only |

A user signs up on an iPhone, the account is stored capitalised, they log in, the
lookup runs lowercased, and **they never get back in**. Password reset on the
lowercased address won't find them either.

Fix is three lines. Existing rows should be audited for capitalised emails.

### BUG-04 in detail — a design flaw, not just a bad password

The credential in `backend/map-backend/.env` is stale (verified independently
with `psql`: DNS and TCP fine, auth rejected). But `create_pool()` already
degrades gracefully when the DSN is *absent*, and `trails_service/infra.py:17`
already returns a clean `503` for exactly this state. A **bad** DSN throws inside
`lifespan`, so startup aborts and the whole service dies — static maps,
elevation, every endpoint — then crash-loops silently.

One rotated password should not take a service offline. Wrap `create_pool` in
try/except.

> ⚠️ That password was exposed in plaintext during the audit session. It is not
> in git and not in any tracked file, but rotate it.

---

## Part 2 — Screen redesign priority

Sorted by business value. Full diagnosis per screen in `FRONTEND_AUDIT.md`.

| Rank | Screen | Route | Priority | Core problem | Optimise for |
|---|---|---|---|---|---|
| 1 | **Onboarding** | *does not exist* | P0 | Cold install lands on a login form; ski level and home resort never collected | Signup completion; % profiles with segmentation data |
| 2 | **Home feed** | `ActivitiesScreen` (tab 2) | P0 | Solo logbook, not a feed; every author is the literal string `"Athlete"`; no kudos; content starts 1.5 screens down | Sessions/week; kudos per DAU; D1/D7 |
| 3 | **Record** | `RecordScreen` (tab 0) | P0 | Core action buried leftmost, labelled "Map"; swipeable away mid-recording; no post-save share moment | % DAU recording; run → post rate |
| 4 | **Groups** | `GroupsScreen` (tab 3) | P1 | All four tabs mock; join/create/search are `TODO`; fake paywall; expired challenges | Cut it — free the nav slot |
| 5 | **Community** | `ThreadsTab` (tab 1) | P1 | Best-built surface, fully severed from ski data; no follow, no topics | Posts/week; follows per new user in wk 1 |
| 6 | **Profile** | `ProfileScreen` (tab 4) | P1 | Placeholder blocks promise unbuilt features; running metrics (5K/10K PRs) on a ski app | Profile completion; view → follow |

### The two structural changes that matter most

Everything above reduces to two moves:

1. **Wire `FeedActionBar` into `ActivityFeedCard`.** The component is built and
   proven in Community. This single change gives the tracking half of the product
   an engagement loop.
2. **Add `Post.activityId` and a route/stats embed.** This is the change that
   makes Snowtrak neither a Strava clone nor a Threads clone — and the only one
   that makes the two halves one product.

---

## Part 3 — Business goals vs. reality

| Goal | Supporting UI today | Gap |
|---|---|---|
| **Onboarding completion** | None. Login form on cold launch; Apple/Google buttons are `_showComingSoon()` stubs | Whole flow missing, plus the two highest-converting auth paths are decorative |
| **Daily active retention** | Home tab shows only the user's own activities, with no way to react to anything | No feed, no graph, no engagement affordance |
| **Skier performance stats** | `Profile.skiLevel` and `Profile.home` exist in the model but are only editable as free text buried in Edit Profile | **No collection surface at all.** Nothing segments your dataset |

All three are blocked on the same thing: a proper onboarding flow that collects
identity and gets the user to their first recording.

---

## Part 4 — Recommended sequence

| Phase | Work | Why here |
|---|---|---|
| **0** | BUG-01 lockout fix · BUG-02 remove fabricated notifications · BUG-03 remove fake paywall · BUG-04 rotate credential + graceful degradation | Days of work. Shipping a redesign on top of a signup flow that locks users out is backwards |
| **1** | Onboarding: value-prop carousel → real Apple/Google auth → ski level + home resort → suggested follows → permission primer | Unblocks goals 1 and 3 |
| **2** | Record tab promotion (rename, centre FAB, lock swipe) + post-save summary with one-tap share | Drives the data volume goal 3 depends on |
| **3** | Home → real social feed; wire `FeedActionBar` into activity cards; resolve real author names | Goal 2 |
| **4** | Follow system end-to-end; `Post.activityId` + activity embeds | Goal 2, compounding |
| **5** | Cut Groups to one real challenge; strip profile placeholders | Trust |
| **6** | Delete `MapsScreen` (585 LOC, unreachable); collapse 8 settings screens; enable dark mode | Maintenance |

---

## Part 5 — What is working

Worth stating plainly, because the defect list above is not the whole picture.

| Area | Assessment |
|---|---|
| **Threads engine** | `threads_tab.dart` and friends are genuinely well built — optimistic outbox, media upload, repost/quote, reply trees. This is the strongest asset in the codebase |
| **Design system** | `ui/liquid/` + `core/theme.dart` are consistent and coherent. The auth screens and trail cards look like a real product |
| **Architecture** | Clean separation — service locator, environment config, per-domain API clients, freezed models. Adding features will not be painful |
| **Defensive backend code** | `normalize_asyncpg_dsn()`, `statement_cache_size=0` for Supavisor, the 503 path in `infra.py` — written by someone who knew the failure modes |
| **Trails UI** | The best-looking screen in the app. The design is ready; only the data is fake |

The problem is not build quality. It is that the built parts are not connected to
each other, and the unbuilt parts are represented as if they were finished.

---

## Appendix — companion documents

| Document | Contents |
|---|---|
| `FRONTEND_AUDIT.md` | Full screen inventory (23 screens, 8 tables) + per-screen redesign diagnosis with `file:line` evidence |
| `FRONTEND_BUGS.md` | 18 live defects, severity-ranked, each with screenshot evidence and reproduction |
| `docs/EMULATOR_ACCESS.md` | How to reproduce the live audit: simulator, backends, `idb` navigation |
| `screenshots/` | 26 captures (local only — gitignored) |
