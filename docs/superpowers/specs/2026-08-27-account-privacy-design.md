# Private accounts, and what a follow has to earn

Supersedes the "accounts are public; following is instant" decision in
[2026-08-26-follower-mechanism-design.md](2026-08-26-follower-mechanism-design.md).
Everything else in that spec still stands.

## The problem

Post visibility shipped with three tiers, and the middle one does not yet
mean anything. `followers` currently resolves to *anyone who bothered to
tap Follow*, because following is instant and unconditional. Nobody has
been hurt by that, only because no UI writes a non-public post: all 87
rows in `posts` are `public`. That window closes the moment the composer
picker ships.

So the account axis goes in first. A private account is the thing that
makes "followers" a guarantee instead of a label.

## Two things found while tracing, not requested

**`GET /api/v1/activities/` returns every activity to anyone.** The route
takes no authentication and applies no filter — `list_activities` in
`backend/activity-backend/services/supabase_client.py:159` is a bare
`select("*")` with a range. Its docstring says "List public activities".
It does not do that. The app calls it from
`frontend/lib/services/apis/activities_api.dart:17`, so every private
GPS track in the database is readable, unauthenticated, today.

`GET /api/v1/activities/{id}/comments` has the same shape: no auth, no
check against the parent activity.

This is a live privacy issue, independent of the feature. It is fixed
here because the predicate that fixes it is the one this work builds
anyway, but it should not wait on anything else in this spec.

**`activities.is_public` is a column that lies.** It is
`not null default true` and no write path has ever updated it — the API's
`is_public` field is derived from `visibility` at
`routes/activity_transformers.py:175`. Every private activity in the
database currently has `is_public = true` stored next to
`visibility = 'private'`. It is dropped here.

## Decisions

### The two axes are independent

An account is public or private. A post or an activity is `public`,
`followers`, or `private`. Neither constrains the other.

A private account can publish a genuinely public post. Instagram would
not allow that — there the account is a ceiling and a "public" post from
a private account is still followers-only. We are taking Strava's shape
instead: the account flag governs **who gets into the follower set**, and
the content tier governs **what that set sees**. One knob, one job.

The practical consequence, which is the whole point: `followers` on a
private account means *approved* followers. On a public account it still
means anyone who tapped Follow, and that is a truthful thing for a public
account to mean.

| | Public account | Private account |
|---|---|---|
| `public` post | everyone | everyone |
| `followers` post | anyone who tapped Follow | approved followers only |
| `private` post | author | author |
| Follower list | everyone | approved followers and self |
| Follow | instant | request, then approval |

### A private account gates two things

1. Following requires approval.
2. The follower and following lists are visible only to approved
   followers and to the account itself.

The lists are gated even though the axes are independent, because a
follower list is not a post — it is the social graph itself, and it is
the one thing on the profile that reveals who the private account's
approved circle is. Public posts stay public throughout.

### Pending follows live in their own table

`follow_requests`, not `follows.status`.

A `status` column is one `ALTER` and looks cheaper. It is not. Five read
paths already ship against `follows` and every one of them would need to
grow `status = 'accepted'`, forever, including paths written months from
now by someone who never read this document. Forgetting that filter fails
*open* — a pending stranger silently gains access to followers-only
content — and that failure is invisible in review and hard to write a
test for, because the test has to be written by the same person who
forgot.

A separate table removes the failure mode instead of guarding it.
`follows` keeps meaning exactly one thing: an accepted edge. Nothing
already shipped changes. `follow_counts` and its trigger are untouched,
and pending requests are not counted because they are not in `follows`.

The cost is that approving is two statements instead of one. That is paid
once, in a Postgres function, atomically.

### Turning private keeps existing followers

Instagram's behaviour. The alternative — demoting every existing follower
to pending — is defensible on paper and useless in practice: nobody with
500 followers will re-approve 500 people, so the real effect is that
nobody ever turns their account private.

The consequence has to be said plainly, because it will surprise someone:
flipping to private does **not** retroactively hide followers-only
content from people who already follow you. The escape hatch is the
"remove a follower" endpoint that already ships.

### `is_private` lives on `user_info`

Not on `profiles`. Many users have no `profiles` row at all — that is why
`app/api/v1/users_profile_routes.py` needs a `user_info` fallback. A
privacy flag that is absent for some users is not a privacy flag.

## Data model

Four migrations, in order. Database first, code after, per
[database_changes.md](../../database_changes.md).

### `014_follow_requests.sql`

```sql
create table if not exists follow_requests (
  requester_id uuid not null references user_info(id) on delete cascade,
  target_id    uuid not null references user_info(id) on delete cascade,
  created_at   timestamptz not null default now(),
  primary key (requester_id, target_id),
  check (requester_id <> target_id)
);

create index if not exists follow_requests_target_idx
  on follow_requests (target_id, created_at desc);

alter table follow_requests enable row level security;
```

Same shape as `follows`: composite primary key, so a duplicate request is
an upsert rather than an error, and cascade on both sides so a deleted
account leaves nothing behind. The index serves the one list query —
"my incoming requests, newest first".

### `015_account_privacy.sql`

```sql
alter table user_info
  add column if not exists is_private boolean not null default false;
```

Additive, and `false` is what every existing account already behaves as.
No backfill.

### `016_activity_visibility.sql`

```sql
alter table activities alter column visibility set default 'private';

alter table activities drop constraint if exists activities_visibility_check;
alter table activities add constraint activities_visibility_check
  check (visibility in ('public', 'followers', 'private'));

create index if not exists activities_visibility_user_idx
  on activities (visibility, user_id);

alter table activities drop column if exists is_public;
```

The default is `private`, where `posts` defaults to `public`. That
asymmetry is deliberate and not an oversight to be tidied later: a post is
written for an audience, and a GPS track starts at somebody's front door.
The application already agrees — `ActivityCreate` defaults to `"private"`
and `activities_upload_routes.py:46` writes `"private"` — the column
simply never carried the same default.

Dropping `is_public` is the only irreversible step in this spec. See
**Deploy order** for the pre-flight that has to pass first.

### `017_follow_requests_function.sql`

```sql
create or replace function public.approve_follow_request(
  target uuid, requester uuid
) returns boolean
language plpgsql
as $$
declare moved boolean;
begin
  delete from follow_requests
   where target_id = target and requester_id = requester
  returning true into moved;

  if moved is null then
    return false;
  end if;

  insert into follows (follower_id, followee_id)
  values (requester, target)
  on conflict do nothing;

  return true;
end;
$$;
```

Atomic, and one round trip instead of two to a database 440ms away. The
insert fires the existing `follows_apply_counts` trigger, so the stored
counts stay correct with no change to the trigger — the payoff for
keeping pending out of `follows`.

The same migration redefines `follow_stats` to carry two more fields, so
the profile header still costs one call:

```sql
create or replace function public.follow_stats(target uuid, viewer uuid)
returns json language sql stable as $$
  select json_build_object(
    'follower_count',  coalesce((select follower_count  from follow_counts where user_id = target), 0),
    'following_count', coalesce((select following_count from follow_counts where user_id = target), 0),
    'is_following',    (viewer is not null and exists (
        select 1 from follows where follower_id = viewer and followee_id = target)),
    'is_followed_by',  (viewer is not null and exists (
        select 1 from follows where follower_id = target and followee_id = viewer)),
    'is_private',      coalesce((select is_private from user_info where id = target), false),
    'has_requested',   (viewer is not null and exists (
        select 1 from follow_requests where requester_id = viewer and target_id = target))
  );
$$;
```

## One predicate, two services

`services/visibility.py` moves to `backend/shared/visibility.py`, because
activity-backend now needs the identical rule and a privacy rule that
exists twice will eventually be two rules. The community-backend module
is deleted and its six call sites re-point; the functions do not change.

`following_ids` moves alongside it, taking a Supabase client as an
argument.

This means **activity-backend reads the `follows` table directly**, which
is community-backend's domain. That is a deliberate exception, recorded
in `docs/service-ownership.md`: an HTTP hop to community-backend would add
two round trips — roughly 880ms — to every activity list, for one indexed
read of a two-column table whose shape is settled. Writes to `follows`
stay in community-backend, without exception.

## What changes, by read path

**Posts: nothing.** `visible_posts_expression` is already correct.
`followers` starts meaning "approved followers" the moment `follows` can
only be entered by approval, and `follows` is exactly the table it already
reads. Zero edits to the five post read paths is the return on the
`follow_requests` table decision, and it is the strongest evidence that
the decision was right.

**Activities: all of it.**

| Route | Today | After |
|---|---|---|
| `GET /activities/` | no auth, no filter | `get_optional_user` + the shared `or_` predicate |
| `GET /activities/{id}` | `public or owner` | shared `can_view` |
| `GET /activities/{id}/comments` | no auth, no check | parent must be viewable |
| `POST /activities/{id}/kudos` | auth, no check | parent must be viewable |
| `POST /activities/{id}/share` | auth, no check | parent must be viewable |

**Follower lists.** `GET /follows/{id}/followers` and `/following` take no
authentication today. Both gain `get_optional_user` and return 403 when
the target is private and the viewer is neither the target nor an approved
follower.

## Backend API

New, community-backend:

```
GET    /api/v1/follows/me/requests                  incoming, paginated
POST   /api/v1/follows/me/requests/{user_id}/approve
DELETE /api/v1/follows/me/requests/{user_id}        deny
DELETE /api/v1/follows/{user_id}/request            withdraw my own
```

All four are registered before `/{user_id}` in `follows_routes.py`, for the
reason that file already documents: a `/{user_id}` route registered first
swallows any sibling path with the same segment count.

New, main-backend:

```
PUT    /api/v1/users/me/privacy   {"is_private": bool}
```

Main-backend owns `user_info`, so it owns this write. The profile
response gains `is_private` so the settings screen renders without a
second call.

Changed:

- **`POST /api/v1/follows/{user_id}` no longer returns 204.** It returns
  200 with `{"state": "following"}` or `{"state": "requested"}`. The
  client cannot guess which happened, and a status code is a worse place
  to put that than a body. This is a breaking change to an endpoint
  shipped four commits ago and used by one caller.
- `GET /api/v1/follows/{user_id}/stats` gains `is_private` and
  `has_requested`.

### The cache window

`follow_stats` is cached for 120 seconds per (target, viewer). Flipping
your account to private is a write in main-backend against a key
community-backend owns, and wiring cross-service invalidation for this
one field is not worth the coupling.

It is safe to skip because **the follow endpoint reads `is_private`
fresh, uncached, on every call**. The security decision is never made
from cache. What can lag is the button's label — another viewer may see
"Follow" for up to two minutes after you go private — and tapping it
creates a request, not a follow, which is the correct outcome with the
wrong caption.

```
# ponytail: 120s of stale is_private in another viewer's cached stats.
# The POST re-reads it fresh, so only the label lags. If that becomes
# visible, bump the follow-stats cache version from main-backend.
```

## Frontend

The smallest surface that makes the feature usable, and no more:

1. `FollowStats` gains `isPrivate` and `hasRequested`.
2. `FollowButton` grows a third state — Follow / Requested / Following —
   driven by the `state` in the POST response. Tapping "Requested"
   withdraws.
3. Settings → Privacy: a "Private account" switch.
4. A follow-requests screen: list, Approve, Deny, reached from a count
   badge on the profile.

There is no push notification. `device_tokens` exists as a table and no
backend code has ever read it; sending is a subsystem, not a field. The
badge is the whole notification surface for now.

Not in this pass, and unchanged from the previous spec's deferral: the
composer's visibility picker, the non-public badge on post cards, and the
followers/following list screens.

## Testing

The fake PostgREST harness in `tests/test_operations_units.py` already
evaluates `.or_()` expressions. It gains a `follow_requests` table and an
`is_private` field on its `user_info` rows.

The tests that must exist, each of which fails if a specific mistake is
made rather than testing the happy path twice:

- Following a public account writes `follows`, returns `following`.
- Following a private account writes `follow_requests`, returns
  `requested`, writes **no** `follows` row, and leaves `follow_counts`
  unchanged.
- Approving moves the row and increments the count exactly once.
- Denying and withdrawing both leave no `follows` row.
- A pending requester cannot read the target's `followers`-tier posts.
- **A private account's `public` post is still visible to a stranger.**
  This is the test that catches someone later "fixing" the model into
  Instagram's ceiling.
- A private account's follower list: 403 for a stranger, 200 for an
  approved follower and for the account itself.
- Flipping to private leaves existing followers in place.
- `GET /activities/` returns only public rows to an anonymous caller, and
  additionally the followers-tier rows of people the viewer follows.
- `GET /activities/{id}/comments` on an activity the viewer cannot see is
  refused.

## Deploy order

1. **Pre-flight, before anything else.** Confirm nothing outside this
   repo reads `activities.is_public`:
   `select polname, tablename from pg_policies where qual::text like '%is_public%';`
   and a repo-wide grep. `016` drops the column and that step is the only
   one in this spec that cannot be undone.
2. Apply `014` and `015`. Both additive, safe at any time, no code
   depends on them yet.
3. Apply `016`.
4. Apply `017`.
5. Re-dump `docs/database_schema.md`.
6. Deploy community-backend, activity-backend and main-backend together —
   the `POST /follows/{id}` response shape changes.
7. Deploy the app.

Rolling back `014`, `015` and `017` is a drop and a `create or replace`.
`016` is not reversible in the strict sense, but the column it drops has
never held a true value, so re-adding it with `default true` restores the
exact state that existed before.

## Out of scope

- Feed ranking and relevance. Still deferred, deliberately.
- Push notifications for follow requests.
- Blocking and muting. A private account plus "remove a follower" covers
  the case that matters today; blocking is a different feature with its
  own table.
- The composer visibility picker and post badges.
- Rate-limiting repeated follow requests after a denial. Worth doing
  before this reaches a real userbase; not worth doing before the feature
  has users.
