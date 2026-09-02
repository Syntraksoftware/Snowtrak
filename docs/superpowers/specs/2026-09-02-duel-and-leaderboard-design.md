# Duel and Leaderboard Design

Status: approved, not yet implemented.
Date: 2026-09-02.

## Summary

Two competition modes, one scoring primitive.

1. **Global leaderboard** — an opt-in ranking. A user marks individual
   activities as counting, and those activities are summed into a weekly
   board, ranked globally and by country. The board settles every week and
   the top 100 are kept.
2. **Friend duel** — a 1v1 head-to-head between two users who follow each
   other. They pick a metric and a duration; whoever's total is higher when
   the window closes wins.

Both reduce to the same query: sum one column of `activities` for one user
over one time window. The leaderboard drops the user filter and adds
`GROUP BY`. Everything else is packaging.

## Decisions

Each of these was chosen deliberately; the rejected alternative is named so a
later reader does not re-litigate it.

**Asynchronous, not live.** No WebSocket, no presence, no live GPS stream.
Both players ski normally and upload as they already do. A live head-to-head
would need realtime infrastructure the app does not have, and phone signal on
a mountain makes it unreliable in exactly the moment it matters.

**Leaderboard opt-in is per activity**, not per account. A user decides
activity by activity whether it counts. The consequence is that `user_stats`
cannot be the leaderboard source — it sums everything regardless — so the
board aggregates `activities` directly.

**Duels ignore the leaderboard opt-in.** A duel counts every activity in the
window. The opponent is a friend, not the world; requiring a user to publish
data to the global board in order to play a private match is the wrong trade.

**Duel eligibility is mutual follow.** Both users follow each other. This
reuses the existing `follows` table and the `can_read_account` gate, so it
adds no new privacy surface and no new harassment vector.

**Duel windows are non-retroactive and symmetric.** `starts_at` is written at
the moment the challenge is accepted, for both players. `ends_at` is the
calendar end of the chosen duration. Accepting "This Weekend" on Sunday gives
both players one day — symmetric, and it removes the obvious cheat of
challenging someone to "today only" at 4pm after a big morning.

**Metrics in phase 1: vertical, top speed, distance.** All three come from
columns that already exist.

**Weekly settlement keeps a top-100 snapshot.** `user_stats.week_start` rolls
over and the previous week's numbers are lost, so a snapshot is the only way
past weeks survive. Storing every participant instead would grow at
participants x 52 rows a year and need a retention policy.

**Country is user-selected.** A new `country_code` on `profiles`, chosen in
settings. Inferring it from GPS would reclassify a user who takes one trip
abroad.

**Win/loss record only.** No points, no tiers, no ladder in phase 1.

## Out of scope

Deliberately deferred. Each is a feature in its own right, not a field.

- **LP and ranked tiers** (Black IV, Diamond, +25/-18 LP). The mockups show a
  full ranked ladder. Shipping one needs a rating formula, protection against
  alt-account feeding, a forfeit rule, and season resets. Phase 2, and only
  after the W-L version shows people actually play.
- **Most Runs as a metric.** Nothing in the repo counts runs. It needs GPS
  segmentation that separates descents from lift rides.
- **Resort scope** (per-resort boards, home resort, "any resort" filter).
  `ski_resorts` was dropped in
  [`007_drop_unused_ski_tables.sql`][migration-007];
  resort geometry now lives only in the map-backend PostGIS `map_trail`
  schema. A GPS-to-resort resolver is roughly a week on its own.
- **Sharing a challenge outside the app.**

## Data model

Migration `019_duels_and_leaderboard.sql`.

```sql
-- Per-activity opt-in. Default false: nothing joins the board by accident.
alter table activities
  add column on_leaderboard boolean not null default false;

create index activities_leaderboard_idx
  on activities (start_time desc, user_id)
  where on_leaderboard;

-- ISO 3166-1 alpha-2. Null means the user has not chosen; global board only.
alter table profiles add column country_code char(2);

-- Weekly settlement snapshot: top 100 per metric per scope.
create table leaderboard_weeks (
  week_start date not null,
  metric     text not null,   -- vertical | speed | distance
  scope      text not null,   -- 'global' or an ISO-2 country code
  rank       int  not null,
  user_id    uuid not null references user_info(id),
  value      double precision not null,
  primary key (week_start, metric, scope, rank)
);

create table duels (
  id                uuid primary key default gen_random_uuid(),
  challenger_id     uuid not null references user_info(id),
  opponent_id       uuid not null references user_info(id),
  metric            text not null,
  duration          text not null,   -- today | weekend | week
  status            text not null,   -- pending|active|finished|declined|
                                     -- cancelled|expired
  starts_at         timestamptz,     -- written on accept, never before
  ends_at           timestamptz,
  challenger_value  double precision,
  opponent_value    double precision,
  winner_id         uuid,            -- null when drawn or unfinished
  created_at        timestamptz not null default now(),
  settled_at        timestamptz
);

-- One live duel per pair, in either direction.
create unique index duels_one_live_per_pair
  on duels (least(challenger_id, opponent_id),
            greatest(challenger_id, opponent_id))
  where status in ('pending', 'active');
```

There is no win/loss counter table. The record is counted from `duels`.

```text
ponytail: derive W-L from duels; add a counter table only if the profile
query measurably slows.
```

## Scoring

One module, `activity-backend/services/scoring.py`, with one metric mapping
and two query shapes: a per-user total (duels) and a top-N grouping
(leaderboard).

```python
METRIC_COLUMNS = {
    "vertical": "elevation_gain_meters",
    "distance": "distance_meters",
}
```

`speed` is deliberately absent from that mapping. `activities.max_pace` is
seconds per kilometre, so the fastest run is the *smallest* positive value,
and the column defaults to `0` when there is no reading. Top speed is
therefore `min(max_pace) where max_pace > 0`, not a max and not a sum. Every
other metric is a plain sum.

Window bounds are half-open, `start_time >= starts_at and start_time <
ends_at`, so an activity cannot land in two consecutive weeks.

Week boundaries are Monday 00:00 UTC, matching the existing `week_start`
convention in `user_stats`.

## API

All routes live in `activity-backend`, which already owns `activities` and
`user_stats`. The duel eligibility check reads `follows` — a read-only query
against a table owned by community-backend, on the same database. That
crossing is deliberate: the alternative puts duels in community-backend and
makes every settlement an HTTP call per player.

### Leaderboard

```text
GET /api/v1/leaderboard?metric=&scope=&limit=&cursor=
GET /api/v1/leaderboard/me?metric=&scope=
GET /api/v1/leaderboard/weeks/{week_start}?metric=&scope=
```

`metric` is `vertical | speed | distance`; `scope` is `global` or an ISO-2
code. Every query takes a `LIMIT` and an explicit ordering; the default page
is 50 and the cap is 100.

`/leaderboard/me` exists because a user outside the top 100 still needs to
see their own rank, and paging to find it is not acceptable.

The opt-in toggle is not a new endpoint. `on_leaderboard` is a field on the
existing activity update route.

### Duels

```text
POST   /api/v1/duels                  {opponent_id, metric, duration}
POST   /api/v1/duels/{id}/accept
POST   /api/v1/duels/{id}/decline
DELETE /api/v1/duels/{id}
GET    /api/v1/duels?status=
GET    /api/v1/duels/{id}
GET    /api/v1/users/{id}/duel_record
```

`POST /duels` rejects with 403 unless both users follow each other, and with
409 if a pending or active duel already exists between them. A pending duel
expires 48 hours after creation.

`DELETE` is the challenger withdrawing while the duel is still pending; it is
not available once accepted.

`duel_record` returns `{wins, losses, draws, recent}` where `recent` is the
last five results as `W`/`L`/`D`.

### Profile

`country_code` is added to the existing profile update route in
main-backend, which already owns `profiles`.

## Settlement

A second background worker in activity-backend, alongside the existing
`PipelineWorker` started in
[`main.py`](../../../backend/activity-backend/main.py). Same pattern, same
lifespan, no scheduler dependency and no cron.

`SettlementWorker.run_forever()` wakes every five minutes and does two
things:

1. **Duels.** For every duel with `status = 'active' and ends_at < now()`,
   score both players, write `winner_id` (null on a draw), set
   `status = 'finished'` and `settled_at`.
2. **Weekly boards.** On the first wake after a week boundary, write the top
   100 for each metric and each scope into `leaderboard_weeks`.
3. **Stale invitations.** Any duel still `pending` 48 hours after
   `created_at` becomes `expired`.

`GET /duels/{id}` also settles lazily: if `ends_at` has passed and the duel
is still active, it scores and writes before responding, so a user who opens
the duel gets the result immediately rather than waiting for the worker.

Both paths are safe to run concurrently across replicas. `leaderboard_weeks`
writes are upserts on the primary key, and the duel update is conditional on
`status = 'active'`, so only one writer wins.

```text
ponytail: idempotence comes from the primary key and a conditional update.
No advisory lock until there is evidence one is needed.
```

## Structure

The rules of this feature — which column a metric reads, whether a state
transition is legal, who won — are pure functions with no database import.
Everything that touches Supabase orchestrates those functions; it does not
contain them. That split is what makes the feature testable without a
database and safe to change later.

### Backend

```text
activity-backend/
  domain/competition/
    metrics.py       # metric -> column, the max_pace rule, window bounds
    duel.py          # Duel entity, legal transitions, winner resolution
  services/
    duel_operations.py         # persistence and orchestration
    leaderboard_operations.py
    settlement_worker.py
  routes/
    duel_routes.py
    leaderboard_routes.py
```

`domain/competition/` imports nothing from `services/`. A test for "a draw
produces no winner" or "top speed ignores a zero pace" constructs values and
calls a function; it does not need a client, a fixture or a network.

The `_operations.py` suffix matches the existing convention in
community-backend (`follow_operations.py`,
`community_post_read_operations.py`).

### Frontend

Two conventions exist in `frontend/lib/`: a `features/<domain>/{data,
application}` layout, and a flat `services/` + `providers/` + `models/`
layout. The follow mechanism — the closest analogue and the most recent work
— uses the flat one, so this feature does too. Consistency with the
neighbouring code beats consistency with a diagram.

Domain purity still applies. `models/duel.dart` carries the rules:

```dart
bool get isDecidable;     // has the window closed
bool canAcceptBy(String viewerId);
Duration get remaining;
```

`services/` talks to the network, `providers/` holds state, `screens/`
renders. A screen that computes a duel outcome is in the wrong layer.

Presentation is assembled from the existing atoms in
[`ui/st/`](../../../frontend/lib/ui/st) — `StCard`, `StStat`, `StTabBar`,
`StPageHeader`, `StButtons`. A new atom goes in `ui/st/` only when two
screens need it; one screen's widget stays private to that screen.

## Frontend

The leaderboard replaces the mock `Challenges` tab in
[`community_screen.dart`][community-screen].

```dart
static const _labels = ['Threads', 'Leaderboards'];
```

`active_tab.dart`, `clubs_tab.dart` and `trails_tab.dart` stay on disk and
stop being mounted. They are mock screens with no backend; removing them is a
separate cleanup, not part of this change.

New files:

```text
screens/leaderboard/  leaderboard_tab.dart
                      duel_terms_screen.dart
                      duel_detail_screen.dart
                      incoming_duel_screen.dart
services/             leaderboard_service.dart, duel_service.dart
services/apis/        leaderboard_api.dart, duel_api.dart
providers/            duel_provider.dart
models/               leaderboard_entry.dart, duel.dart, duel_record.dart
```

The `Challenge` button appears only on the **Friends** board, never on
Global, because a duel requires a mutual follow.

Incoming duel invitations are surfaced through the existing
[`NotificationProvider`][notification-provider],
which already derives its list from pending follow requests. Pending duels
become a second source in the same provider — no new polling and no new
infrastructure.

Colours come from `context.colors`. The guard test at
`frontend/test/core/design_system_guard_test.dart` fails the build on a raw
hex, so the mockups' palette is mapped to existing roles rather than copied
as literals.

## Privacy

The board shows aggregates only — display name, total, rank. It never links
to an activity and never exposes an activity's contents, so an activity with
`private` visibility can still count towards a total without leaking. Tapping
a name opens the profile, where the existing `can_read_account` gate applies
unchanged.

Eligibility is resolved server-side in the query, never filtered in the
client. A duel between users who stop following each other mid-window still
finishes: eligibility is checked when the challenge is accepted, not
continuously.

## Testing

Backend, in `activity-backend/tests/`:

- Scoring boundaries: `max_pace = 0` excluded from top speed, half-open
  window edges, a draw, a user with no activities in the window.
- The mutual-follow gate rejects a one-directional follow and a stranger.
- Settlement is idempotent: running it twice leaves one result.
- The leaderboard excludes activities with `on_leaderboard = false`.

Frontend, in `frontend/test/`:

- Duel status to button state, in the shape of
  `test/widgets/follow_button_request_test.dart`.
- `NotificationProvider` surfaces a pending duel with the id needed to open
  it.

A contract test covers the duel and leaderboard response shapes through
`shared/contract_tests.py`.

## Estimate

Backend, roughly two to three days: the migration, the scoring module, eight
routes and the settlement worker. Frontend, roughly three to four days: four
screens, two services, one provider. About a week in total.

[migration-007]: ../../../backend/db/migrations/007_drop_unused_ski_tables.sql
[community-screen]: ../../../frontend/lib/screens/community/community_screen.dart
[notification-provider]: ../../../frontend/lib/providers/notification_provider.dart
