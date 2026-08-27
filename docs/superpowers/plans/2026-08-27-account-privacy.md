# Private Accounts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make a follow something a private account grants rather than
something a stranger takes, and stop `GET /api/v1/activities/` handing every
private GPS track to anyone who asks.

**Architecture:** Two independent axes. `user_info.is_private` decides who
joins the follower set; `visibility` on `posts` and `activities` decides what
that set sees. Pending follows live in their own table, so `follows` keeps
meaning "accepted edge" and the five shipped post read paths need no change.
The visibility predicate moves to `backend/shared/` because activity-backend
now needs the identical rule.

**Tech Stack:** Python 3.11 / FastAPI / supabase-py (synchronous) / Postgres
via Supabase / Redis / Flutter / Dart / GetIt.

**Spec:**
[docs/superpowers/specs/2026-08-27-account-privacy-design.md](../specs/2026-08-27-account-privacy-design.md)

## Global Constraints

- Repo style rules in `CLAUDE.md` win over every upstream guide. Read it.
- **Database first, code after.** Migrations are applied by hand against the
  real Supabase instance before the code that reads them merges. See
  `docs/database_changes.md`.
- **Do not change the Supabase region.** Standing instruction from the user.
  Every latency decision in this plan assumes ~440ms per round trip.
- Backend checks, from `backend/`: `../.venv/bin/ruff check .` and
  `../.venv/bin/ruff format --check .`. Tests run per service, and two of
  them need a workaround in this checkout:

  ```bash
  # community-backend and activity-backend: the console script does not put
  # cwd on sys.path, so conftest cannot import `main`. Use -m.
  (cd community-backend && ../../.venv/bin/python -m pytest -q)
  (cd activity-backend  && ../../.venv/bin/python -m pytest -q)

  # main-backend: pytest.ini passes --cov flags and pytest-cov is not
  # installed in .venv. Override addopts, or install pytest-cov and drop
  # the flag.
  (cd main-backend && ../../.venv/bin/python -m pytest -q -o addopts="")
  ```
- Frontend checks, from `frontend/`: `dart analyze lib test` and
  `flutter test`. Do **not** run `flutter analyze` with multiple paths — it
  crashes the analysis server with exit 64 in this repo.
- `supabase-py` is synchronous. Any call to it from an `async def` handler
  goes through `offload()`, or it stalls the event loop for every concurrent
  request. This is not optional; it was measured at 8.1s for five concurrent
  reads before the fix.
- Colours, spacing and type in Dart come from `context.colors` and
  `SnowtrakTypography`. A literal `Color(0xFF…)` or `Colors.grey` outside
  `core/theme.dart` is a bug.
- Conventional Commits, scoped: `feat(follows):`, `fix(activity):`, etc.
- **Never commit or push unless the user asks.** Each task below ends with a
  commit step because the user has asked for batched commits on this branch.
- `CHANGELOG.md` is written last, from the commits, per
  `docs/changelog_style.md`.

## Branch state (updated 2026-08-27)

The design-system work that was dirtying the tree has landed: PR #39 merged
into `develop`, and `feat/follower-mechansim` was fast-forwarded onto it at
`909125e`. The tree is clean and all three backend suites plus 33 Flutter
tests pass.

Two consequences for this plan:

- `frontend/lib/screens/settings/privacy_settings_screen.dart` (Task 10) and
  every other screen now read colours through `context.colors`. There is a
  test, `frontend/test/core/design_system_guard_test.dart`, that **fails the
  build when UI code names a colour**. Task 10 and Task 11 must not
  introduce a literal `Color(0xFF…)` or a Material `Colors.*`.
- The `home preview` golden no longer fails; it was un-gated in `3e3517f`.

---

## File Structure

**Created:**

| Path | Responsibility |
|---|---|
| `backend/db/migrations/014_follow_requests.sql` | the pending-follow table |
| `backend/db/migrations/015_account_privacy.sql` | `user_info.is_private` |
| `backend/db/migrations/016_activity_visibility.sql` | activity tiers, drop `is_public` |
| `backend/db/migrations/017_follow_requests_function.sql` | atomic approve, richer `follow_stats` |
| `backend/shared/visibility.py` | the one visibility predicate, both services |
| `backend/shared/follow_graph.py` | `following_ids` against a Supabase client |
| `backend/community-backend/services/follow_request_operations.py` | pending-follow reads and writes |
| `backend/activity-backend/services/offload.py` | thread hand-off, copied from community |
| `frontend/lib/screens/profile/follow_requests_screen.dart` | approve / deny list |

**Deleted:**

| Path | Why |
|---|---|
| `backend/community-backend/services/visibility.py` | moved to `shared/` |

**Modified:** `follow_operations.py`, `follows_routes.py`, `community_models.py`,
`supabase_client.py` (community and activity), `activities_list_routes.py`,
`activities_management_routes.py`, `activities_social_routes.py`,
`users_profile_routes.py`, `follow_stats.dart`, `follow_api.dart`,
`follow_service.dart`, `follow_button.dart`, `privacy_settings_screen.dart`,
`profile_header.dart`, plus tests and docs.

---

## Task 1: Apply the migrations

Nothing else in this plan can be tested until the database has the columns.

**Files:**
- Create: `backend/db/migrations/014_follow_requests.sql`
- Create: `backend/db/migrations/015_account_privacy.sql`
- Create: `backend/db/migrations/016_activity_visibility.sql`
- Create: `backend/db/migrations/017_follow_requests_function.sql`

**Interfaces:**
- Produces: tables `follow_requests`; column `user_info.is_private`;
  function `approve_follow_request(target uuid, requester uuid) returns
  boolean`; function `follow_stats(target uuid, viewer uuid) returns json`
  with the added keys `is_private` and `has_requested`.

The connection string lives in `backend/map-backend/.env` as
`SYNTRAK_DATABASE_URL`. It carries a `+psycopg` suffix that `psql` does not
understand — strip it:

```bash
cd /Users/matthewng/Desktop/Snowtrak
DB_URL="$(grep '^SYNTRAK_DATABASE_URL=' backend/map-backend/.env \
  | cut -d= -f2- | sed 's/+psycopg//')"
```

- [ ] **Step 1: Pre-flight — prove `activities.is_public` is dead**

`016` drops it and that cannot be undone. Both of these must come back empty:

```bash
psql "$DB_URL" -c "select policyname, tablename from pg_policies
                    where qual::text like '%is_public%'
                       or with_check::text like '%is_public%';"

grep -rn "is_public" backend --include=*.py | grep -v "/tests/" \
  | grep -v "models.py" | grep -v "activity_transformers.py" \
  | grep -v "activities_management_routes.py"
```

The three excluded files are the request/response mapping, which reads the
Pydantic field, never the column. If anything else appears, **stop and report
it** — do not run `016`.

**This was run on 2026-08-27 and it failed.** main-backend held a second,
unmounted activities implementation — ~700 lines — that used
`activities.is_public` as its access-control column while activity-backend
used `visibility`. Production still shows the disagreement: one activity is
stored `visibility = 'private'` with `is_public = true`. It was deleted in
`1501b69`; see the "Migration Decision" section of `docs/service-ownership.md`.

After that deletion the grep returns only three lines, all of which are the
API-level boolean and none of which name the column:

```
backend/shared/track_pipeline_schemas.py:247   is_public: bool = True     # contract schema
backend/shared/track_pipeline_schemas.py:275   is_public: bool            # contract schema
backend/scripts/test_delete_orchestration.py:92  "is_public": True,       # an HTTP request body
```

Re-run it anyway before `016`. The point of a pre-flight is that it is run,
not that somebody once ran it.

- [ ] **Step 2: Write `014_follow_requests.sql`**

```sql
-- Run this in the Supabase SQL editor BEFORE deploying the release that
-- reads it. Additive: a new table nothing yet queries.
--
-- Pending follows live here rather than as a status column on `follows`,
-- so that `follows` keeps meaning exactly one thing: an accepted edge.
-- Five read paths already ship against that table. A status column would
-- need every one of them, forever, to remember `status = 'accepted'` --
-- and forgetting it fails open, handing a pending stranger somebody's
-- followers-only posts. A separate table deletes the failure mode rather
-- than guarding it, and leaves follow_counts and its trigger untouched.

begin;

create table if not exists follow_requests (
  requester_id uuid not null references user_info(id) on delete cascade,
  target_id    uuid not null references user_info(id) on delete cascade,
  created_at   timestamptz not null default now(),
  primary key (requester_id, target_id),
  check (requester_id <> target_id)
);

-- The one list query: "my incoming requests, newest first".
create index if not exists follow_requests_target_idx
  on follow_requests (target_id, created_at desc);

alter table follow_requests enable row level security;

commit;

-- Verify:
--   insert into follow_requests (requester_id, target_id)
--     select id, id from user_info limit 1;
--     -- expected: violates check constraint "follow_requests_check"
```

- [ ] **Step 3: Write `015_account_privacy.sql`**

```sql
-- Run this in the Supabase SQL editor BEFORE deploying the release that
-- reads it. Additive with a default that matches how every existing
-- account already behaves, so no backfill and no behaviour change.
--
-- On user_info, not profiles. Most users have no profiles row at all --
-- that is why users_profile_routes.py carries a user_info fallback -- and
-- a privacy flag that is absent for some users is not a privacy flag.

begin;

alter table user_info
  add column if not exists is_private boolean not null default false;

commit;

-- Verify: every existing account is public.
--   select is_private, count(*) from user_info group by is_private;
```

- [ ] **Step 4: Write `016_activity_visibility.sql`**

```sql
-- Run this in the Supabase SQL editor AFTER the pre-flight in
-- docs/superpowers/plans/2026-08-27-account-privacy.md passes. This is the
-- only irreversible step in that plan.
--
-- Three things activities never got and posts did: a real default, a check
-- constraint, and an index the visibility filter can use.
--
-- The default is 'private' where posts defaults to 'public'. That
-- asymmetry is deliberate. A post is written for an audience; a GPS track
-- starts at somebody's front door. The application already agrees --
-- ActivityCreate defaults to "private" and activities_upload_routes.py
-- writes "private" -- the column simply never carried the same default.
--
-- is_public is dropped because two services disagreed about it. The API's
-- is_public is derived from visibility at
-- routes/activity_transformers.py:175 and is unaffected by this; the
-- column is a different thing wearing the same name.
--
-- activity-backend has never written the column, so it kept its `not null
-- default true` on every row -- including the one activity stored
-- visibility = 'private', which reads is_public = true to this day.
--
-- main-backend meanwhile had a whole unmounted activities implementation
-- that did write it, filter on it, and use it for access control. That was
-- deleted first; see docs/service-ownership.md, "Migration Decision".
--
-- One table, one privacy column. Left in place, somebody believes the
-- wrong one.

begin;

alter table activities alter column visibility set default 'private';

alter table activities drop constraint if exists activities_visibility_check;
alter table activities add constraint activities_visibility_check
  check (visibility in ('public', 'followers', 'private'));

create index if not exists activities_visibility_user_idx
  on activities (visibility, user_id);

alter table activities drop column if exists is_public;

commit;

-- Verify:
--   select visibility, count(*) from activities group by visibility;
--   select column_name from information_schema.columns
--     where table_name = 'activities' and column_name = 'is_public';
--     -- expected: no rows
```

- [ ] **Step 5: Write `017_follow_requests_function.sql`**

```sql
-- Run this in the Supabase SQL editor after 014 and 015. Additive: a new
-- function plus a create-or-replace of an existing one whose signature
-- does not change.

begin;

-- Approving is a delete and an insert, and they must not be separable: a
-- crash between them either drops the request or duplicates the edge.
-- Doing it here also makes it one round trip to a database ~440ms away
-- instead of two.
--
-- The insert fires the existing follows_apply_counts trigger, so the
-- stored counts stay correct with no change to the trigger. That is the
-- payoff for keeping pending requests out of `follows`.
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

-- Same signature as 012, two more keys. The follow button has three states
-- now and they all come out of the one call the profile header already
-- makes.
create or replace function public.follow_stats(target uuid, viewer uuid)
returns json
language sql
stable
as $$
  select json_build_object(
    'follower_count',
      coalesce((select follower_count from follow_counts where user_id = target), 0),
    'following_count',
      coalesce((select following_count from follow_counts where user_id = target), 0),
    'is_following',
      (viewer is not null and exists (
        select 1 from follows where follower_id = viewer and followee_id = target
      )),
    'is_followed_by',
      (viewer is not null and exists (
        select 1 from follows where follower_id = target and followee_id = viewer
      )),
    'is_private',
      coalesce((select is_private from user_info where id = target), false),
    'has_requested',
      (viewer is not null and exists (
        select 1 from follow_requests where requester_id = viewer and target_id = target
      ))
  );
$$;

commit;
```

- [ ] **Step 6: Apply all four, in order**

```bash
for m in 014_follow_requests 015_account_privacy \
         016_activity_visibility 017_follow_requests_function; do
  psql "$DB_URL" -v ON_ERROR_STOP=1 -f "backend/db/migrations/$m.sql" || break
done
```

- [ ] **Step 7: Verify against the real database**

```bash
psql "$DB_URL" -c "select is_private, count(*) from user_info group by is_private;"
psql "$DB_URL" -c "select visibility, count(*) from activities group by visibility;"
psql "$DB_URL" -c "select column_name from information_schema.columns
                    where table_name='activities' and column_name='is_public';"
psql "$DB_URL" -c "select public.follow_stats(
                     (select id from user_info limit 1), null);"
```

Expected: every `user_info` row `is_private = f`; no `is_public` row; the
`follow_stats` JSON now carries `is_private` and `has_requested`.

- [ ] **Step 8: Re-dump the schema and commit**

```bash
cd /Users/matthewng/Desktop/Snowtrak
SYNTRAK_DATABASE_URL="$DB_URL" .venv/bin/python scripts/dump_supabase_schema.py
git add backend/db/migrations/01[4-7]_*.sql docs/database_schema.md
git commit -m "feat(follows): add follow requests, account privacy and activity tiers

Four additive migrations plus one column drop. follow_requests keeps
pending follows out of `follows`, so the table keeps meaning 'accepted
edge' and the five shipped post read paths need no change.

activities.is_public is dropped. It was not null default true and no write
path ever updated it -- every private activity stored is_public = true
beside visibility = 'private'. The API field of the same name is derived
from visibility and is unaffected."
```

---

## Task 2: Move the visibility predicate into `shared/`

activity-backend needs the identical rule. A privacy rule that exists twice
becomes two rules.

**Files:**
- Create: `backend/shared/visibility.py`
- Create: `backend/shared/follow_graph.py`
- Delete: `backend/community-backend/services/visibility.py`
- Modify: `backend/community-backend/routes/community_models.py:8`
- Modify: `backend/community-backend/services/community_post_write_operations.py:8`
- Modify: `backend/community-backend/services/community_post_read_operations.py:10`
- Modify: `backend/community-backend/services/follow_operations.py`
- Test: `backend/community-backend/tests/test_operations_units.py`

**Interfaces:**
- Produces: `shared.visibility.PUBLIC | FOLLOWERS | PRIVATE | TIERS |
  DEFAULT_TIER`, `visible_rows_expression(viewer_id, following_ids) -> str`,
  `can_view(row, viewer_id, following_ids) -> bool`;
  `shared.follow_graph.following_ids(client, user_id) -> list[str]` and
  `MAX_FOLLOW_IDS = 1000`.
- Consumes: nothing from earlier tasks.

The function is renamed from `visible_posts_expression` to
`visible_rows_expression` because it now filters activities too. Both tables
name the column `visibility` and the author column `user_id`, so one
expression serves both.

- [ ] **Step 1: Write the failing test**

Append to `backend/community-backend/tests/test_operations_units.py`:

```python
def test_shared_visibility_expression_covers_all_three_tiers():
    from shared.visibility import visible_rows_expression

    anonymous = visible_rows_expression(None, [])
    assert anonymous == "visibility.eq.public"

    viewer = visible_rows_expression("user-1", ["user-2"])
    assert "visibility.eq.public" in viewer
    assert "user_id.eq.user-1" in viewer
    assert "and(visibility.eq.followers,user_id.in.(user-2))" in viewer

    # PostgREST rejects an empty in.(), so the clause must not be built.
    alone = visible_rows_expression("user-1", [])
    assert "in.()" not in alone
```

- [ ] **Step 2: Run it and watch it fail**

```bash
cd backend/community-backend && \
  ../../.venv/bin/pytest tests/test_operations_units.py -k shared_visibility -v
```

Expected: `ModuleNotFoundError: No module named 'shared.visibility'`.

- [ ] **Step 3: Move the module**

```bash
cd /Users/matthewng/Desktop/Snowtrak
git mv backend/community-backend/services/visibility.py backend/shared/visibility.py
```

Then rename the function inside it, leaving the docstrings intact:

```bash
sed -i '' 's/def visible_posts_expression(/def visible_rows_expression(/' \
  backend/shared/visibility.py
```

Update its module docstring to say it serves both tables:

```python
"""Who is allowed to see which row.

One predicate, built in one place, so that every read path in every service
enforces the same rule. Filtering only the community feed leaves five other
doors open: a shared post link, a profile's post list, a subthread listing,
the preview of a quoted post, and the entire activity list.

`posts` and `activities` both name the column `visibility` and the author
`user_id`, so one expression serves both.
"""
```

- [ ] **Step 4: Write `backend/shared/follow_graph.py`**

```python
"""Reading the follow graph.

The graph is owned by community-backend, which is the only service allowed
to write it. activity-backend reads it here rather than over HTTP: a hop to
community-backend would put two more round trips -- roughly 880ms -- in
front of every activity list, for one indexed read of a two-column table
whose shape is settled. Recorded as an exception in docs/service-ownership.md.
"""

import logging

logger = logging.getLogger(__name__)

# A read that walks the whole graph would be unbounded; nobody follows this
# many people, and past it the predicate belongs in a Postgres view.
# ponytail: cap the in-memory follow list, move to a DB-side join if it bites.
MAX_FOLLOW_IDS = 1000


def following_ids(client, user_id: str) -> list[str]:
    """Ids `user_id` follows, for a visibility filter.

    Only accepted edges: pending follows live in `follow_requests` and are
    not in this table at all.

    Args:
        client: A configured `supabase.Client`.
        user_id: The viewer.

    Returns:
        Up to `MAX_FOLLOW_IDS` ids, newest follow first. Empty on failure,
        which fails closed -- the caller sees only public rows.
    """
    if not user_id:
        return []
    try:
        response = (
            client.table("follows")
            .select("followee_id")
            .eq("follower_id", user_id)
            .order("created_at", desc=True)
            .limit(MAX_FOLLOW_IDS)
            .execute()
        )
        data = getattr(response, "data", None)
        if not isinstance(data, list):
            return []
        return [row["followee_id"] for row in data if row.get("followee_id")]
    except Exception as exception:
        logger.exception("Failed to list follows for %s: %s", user_id, exception)
        return []
```

- [ ] **Step 5: Re-point the three community imports**

```bash
cd /Users/matthewng/Desktop/Snowtrak/backend/community-backend
sed -i '' 's/^from services.visibility import PUBLIC$/from shared.visibility import PUBLIC/' \
  routes/community_models.py
sed -i '' 's/^from services.visibility import PUBLIC, TIERS$/from shared.visibility import PUBLIC, TIERS/' \
  services/community_post_write_operations.py
sed -i '' 's/^from services.visibility import visible_posts_expression$/from shared.visibility import visible_rows_expression/' \
  services/community_post_read_operations.py
sed -i '' 's/visible_posts_expression(/visible_rows_expression(/' \
  services/community_post_read_operations.py
```

`ruff` will move each import into the right group; run
`../../.venv/bin/ruff check --fix .` from `backend/`.

- [ ] **Step 6: Make the mixin delegate instead of duplicating**

In `backend/community-backend/services/follow_operations.py`, delete the
local `MAX_FOLLOW_IDS` constant and replace the body of `following_ids`:

```python
from shared.follow_graph import MAX_FOLLOW_IDS, following_ids as _following_ids


class CommunityFollowOperations:
    ...

    def following_ids(self, user_id: str) -> list[str]:
        """Ids `user_id` follows, for the feed's visibility filter."""
        return _following_ids(self._client, user_id)
```

`follower_ids` and `_edge_ids` stay exactly as they are — only the following
direction is shared.

- [ ] **Step 7: Run the whole community suite**

```bash
cd backend/community-backend && ../../.venv/bin/pytest -q
```

Expected: 85 passed (84 existing plus the new one). If any test fails with
`ImportError: services.visibility`, a call site was missed — grep for it.

- [ ] **Step 8: Commit**

```bash
cd /Users/matthewng/Desktop/Snowtrak
git add backend/shared/visibility.py backend/shared/follow_graph.py \
        backend/community-backend/
git commit -m "refactor(follows): move the visibility predicate into shared

activity-backend needs the identical rule and a privacy rule that exists
twice eventually becomes two rules. Renamed to visible_rows_expression
because it now filters activities as well as posts -- both tables name the
column visibility and the author user_id, so one expression serves both.

following_ids moves alongside it, taking a client rather than self, so
activity-backend can read the graph without importing community-backend."
```

---

## Task 3: Pending-follow operations

**Files:**
- Create: `backend/community-backend/services/follow_request_operations.py`
- Modify: `backend/community-backend/services/constants/community_tables.py`
- Modify: `backend/community-backend/services/supabase_client.py:69-77`
- Test: `backend/community-backend/tests/test_operations_units.py`

**Interfaces:**
- Consumes: `shared.follow_graph` from Task 2.
- Produces, all on `CommunitySupabaseClient`:
  `is_private_account(user_id) -> bool`,
  `request_follow(requester_id, target_id) -> bool`,
  `withdraw_request(requester_id, target_id) -> bool`,
  `approve_request(target_id, requester_id) -> bool`,
  `list_requests(target_id, limit, offset) -> list[dict]`,
  `count_requests(target_id) -> int`.

The route decides between follow and request; the mixin stays dumb.

- [ ] **Step 1: Teach the fake client `upsert` and `rpc`**

The harness in `tests/test_operations_units.py` has neither, so nothing that
uses them can be tested today. Add to `FakeQuery`:

```python
    def upsert(self, payload, on_conflict=None, ignore_duplicates=False):
        self.operation = "upsert"
        self.payload = payload
        self.on_conflict = [f.strip() for f in (on_conflict or "").split(",") if f.strip()]
        self.ignore_duplicates = ignore_duplicates
        return self
```

and in `FakeQuery.execute`, before the select branch:

```python
        if self.operation == "upsert":
            rows = self.client.tables.setdefault(self.table_name, [])
            payloads = self.payload if isinstance(self.payload, list) else [self.payload]
            for item in payloads:
                match = next(
                    (
                        row
                        for row in rows
                        if all(row.get(k) == item.get(k) for k in self.on_conflict)
                    ),
                    None,
                )
                if match is None:
                    rows.append(dict(item))
                elif not self.ignore_duplicates:
                    match.update(item)
            return FakeResponse(data=payloads, count=None)
```

and on `FakeSupabaseClient`:

```python
    def rpc(self, name, params):
        return FakeRpc(self, name, params)


class FakeRpc:
    """Just enough of the two functions the code calls.

    The real ones live in backend/db/migrations/. Reimplementing them here
    is a deliberate duplication: without it, approve and follow_stats have
    no unit coverage at all, and both are load-bearing for privacy.
    """

    def __init__(self, client, name, params):
        self.client = client
        self.name = name
        self.params = params

    def execute(self):
        if self.name == "approve_follow_request":
            return FakeResponse(data=self._approve(), count=None)
        if self.name == "follow_stats":
            return FakeResponse(data=self._stats(), count=None)
        raise AssertionError(f"fake does not implement rpc {self.name!r}")

    def _approve(self):
        target = self.params["target"]
        requester = self.params["requester"]
        requests = self.client.tables.setdefault("follow_requests", [])
        before = len(requests)
        requests[:] = [
            r
            for r in requests
            if not (r["target_id"] == target and r["requester_id"] == requester)
        ]
        if len(requests) == before:
            return False
        follows = self.client.tables.setdefault("follows", [])
        if not any(
            f["follower_id"] == requester and f["followee_id"] == target for f in follows
        ):
            follows.append({"follower_id": requester, "followee_id": target})
        return True

    def _stats(self):
        target = self.params["target"]
        viewer = self.params["viewer"]
        follows = self.client.tables.get("follows", [])
        requests = self.client.tables.get("follow_requests", [])
        users = self.client.tables.get("user_info", [])
        row = next((u for u in users if u["id"] == target), None)
        return {
            "follower_count": sum(1 for f in follows if f["followee_id"] == target),
            "following_count": sum(1 for f in follows if f["follower_id"] == target),
            "is_following": any(
                f["follower_id"] == viewer and f["followee_id"] == target for f in follows
            ),
            "is_followed_by": any(
                f["follower_id"] == target and f["followee_id"] == viewer for f in follows
            ),
            "is_private": bool(row and row.get("is_private")),
            "has_requested": any(
                r["requester_id"] == viewer and r["target_id"] == target for r in requests
            ),
        }
```

Add the two new tables and a `user_info` table to `FakeSupabaseClient.tables`:

```python
            "follow_requests": [],
            "user_info": [
                {"id": "user-1", "is_private": False},
                {"id": "user-2", "is_private": True},
            ],
```

- [ ] **Step 2: Write the failing tests**

```python
def test_following_a_private_account_creates_a_request_not_an_edge(harness):
    assert harness.is_private_account("user-2") is True
    assert harness.request_follow("user-1", "user-2") is True

    assert harness._client.tables["follow_requests"] == [
        {"requester_id": "user-1", "target_id": "user-2"}
    ]
    # The point of the separate table: no edge, so follow_counts and every
    # visibility read stay correct without knowing requests exist.
    assert harness._client.tables["follows"] == []


def test_requesting_twice_leaves_one_row(harness):
    harness.request_follow("user-1", "user-2")
    harness.request_follow("user-1", "user-2")
    assert len(harness._client.tables["follow_requests"]) == 1


def test_approving_moves_the_row_into_follows(harness):
    harness.request_follow("user-1", "user-2")
    assert harness.approve_request("user-2", "user-1") is True

    assert harness._client.tables["follow_requests"] == []
    assert harness._client.tables["follows"] == [
        {"follower_id": "user-1", "followee_id": "user-2"}
    ]


def test_approving_something_never_requested_is_false(harness):
    assert harness.approve_request("user-2", "user-1") is False
    assert harness._client.tables["follows"] == []


def test_withdrawing_leaves_no_edge(harness):
    harness.request_follow("user-1", "user-2")
    assert harness.withdraw_request("user-1", "user-2") is True
    assert harness._client.tables["follow_requests"] == []
    assert harness._client.tables["follows"] == []


def test_a_pending_requester_cannot_read_followers_tier_posts(harness):
    harness._client.tables["posts"].append(
        {
            "post_id": "post-private",
            "user_id": "user-2",
            "subthread_id": "sub-1",
            "title": "Members only",
            "content": "Secret line",
            "created_at": "2026-01-02T00:00:00Z",
            "visibility": "followers",
        }
    )
    harness.request_follow("user-1", "user-2")

    ids = {p["post_id"] for p in harness.list_recent_posts(current_user_id="user-1")}
    assert "post-private" not in ids


def test_a_private_accounts_public_post_stays_public(harness):
    """The two axes are independent. This is the test that catches somebody
    later 'fixing' the model into Instagram's ceiling, where a private
    account's public post silently becomes followers-only."""
    harness._client.tables["posts"].append(
        {
            "post_id": "post-open",
            "user_id": "user-2",  # a private account
            "subthread_id": "sub-1",
            "title": "Open to all",
            "content": "Anyone can read this",
            "created_at": "2026-01-03T00:00:00Z",
            "visibility": "public",
        }
    )

    anonymous = {p["post_id"] for p in harness.list_recent_posts(current_user_id=None)}
    assert "post-open" in anonymous


def test_turning_private_keeps_existing_followers(harness):
    harness.follow("user-1", "user-2")
    harness._client.tables["user_info"][1]["is_private"] = True

    # No demotion path exists, and that is the decision: Instagram keeps
    # them. The escape hatch is remove-a-follower, which already ships.
    assert harness.following_ids("user-1") == ["user-2"]
```

Add the `harness` fixture if the file does not already have one:

```python
@pytest.fixture
def harness():
    return OperationHarness()
```

- [ ] **Step 3: Run and watch them fail**

```bash
cd backend/community-backend && \
  ../../.venv/bin/pytest tests/test_operations_units.py -k "request or private_account" -v
```

Expected: `AttributeError: 'OperationHarness' object has no attribute
'is_private_account'`.

- [ ] **Step 4: Add the table constants**

In `services/constants/community_tables.py`:

```python
# Pending follows. Kept out of `follows` on purpose -- see
# backend/db/migrations/014_follow_requests.sql.
FOLLOW_REQUESTS = "follow_requests"
# Read-only here: main-backend owns this table.
USER_INFO = "user_info"
```

- [ ] **Step 5: Write the mixin**

`backend/community-backend/services/follow_request_operations.py`:

```python
"""Pending follows, for accounts that approve their followers.

These rows are deliberately not in `follows`. That table means one thing --
an accepted edge -- and every visibility read already shipped depends on it
meaning only that. See backend/db/migrations/014_follow_requests.sql.
"""

import logging
from typing import Any

from services.constants.community_tables import FOLLOW_REQUESTS, USER_INFO

logger = logging.getLogger(__name__)


class CommunityFollowRequestOperations:
    """Mixin containing follow-request operations."""

    def is_private_account(self, user_id: str) -> bool:
        """Whether this account approves its followers.

        Fails closed: an unreadable flag is treated as private, so the worst
        case is a request that needed no approval, not a follow that skipped
        one.
        """
        try:
            response = (
                self._client.table(USER_INFO)
                .select("is_private")
                .eq("id", user_id)
                .limit(1)
                .execute()
            )
            data = getattr(response, "data", None)
            if isinstance(data, list) and data:
                return bool(data[0].get("is_private"))
            return False
        except Exception as exception:
            logger.exception("Failed to read privacy for %s: %s", user_id, exception)
            return True

    def request_follow(self, requester_id: str, target_id: str) -> bool:
        """Ask to follow. Idempotent: requesting twice leaves one row."""
        if requester_id == target_id:
            return False
        try:
            (
                self._client.table(FOLLOW_REQUESTS)
                .upsert(
                    {"requester_id": requester_id, "target_id": target_id},
                    on_conflict="requester_id,target_id",
                    ignore_duplicates=True,
                )
                .execute()
            )
            return True
        except Exception as exception:
            logger.exception(
                "Failed to request follow of %s as %s: %s", target_id, requester_id, exception
            )
            return False

    def withdraw_request(self, requester_id: str, target_id: str) -> bool:
        """Take back your own request. Succeeds when there was none."""
        return self._delete_request(requester_id=requester_id, target_id=target_id)

    def deny_request(self, target_id: str, requester_id: str) -> bool:
        """Refuse somebody's request. The same delete, from the other side."""
        return self._delete_request(requester_id=requester_id, target_id=target_id)

    def _delete_request(self, *, requester_id: str, target_id: str) -> bool:
        try:
            (
                self._client.table(FOLLOW_REQUESTS)
                .delete()
                .eq("requester_id", requester_id)
                .eq("target_id", target_id)
                .execute()
            )
            return True
        except Exception as exception:
            logger.exception("Failed to drop follow request: %s", exception)
            return False

    def approve_request(self, target_id: str, requester_id: str) -> bool:
        """Turn a request into a follow, atomically.

        The delete and the insert must not be separable: a crash between
        them either loses the request or duplicates the edge. The function
        also makes it one round trip to a database ~440ms away instead of
        two. See backend/db/migrations/017_follow_requests_function.sql.

        Returns:
            False when there was no request to approve.
        """
        try:
            response = self._client.rpc(
                "approve_follow_request",
                {"target": target_id, "requester": requester_id},
            ).execute()
            return bool(getattr(response, "data", False))
        except Exception as exception:
            logger.exception(
                "Failed to approve %s for %s: %s", requester_id, target_id, exception
            )
            return False

    def count_requests(self, target_id: str) -> int:
        try:
            from postgrest import CountMethod

            response = (
                self._client.table(FOLLOW_REQUESTS)
                .select("requester_id", count=CountMethod.exact)
                .eq("target_id", target_id)
                .execute()
            )
            return getattr(response, "count", 0) or 0
        except Exception as exception:
            logger.exception("Failed to count requests for %s: %s", target_id, exception)
            return 0

    def list_requests(
        self, target_id: str, limit: int = 20, offset: int = 0
    ) -> list[dict[str, Any]]:
        """One page of incoming requests, newest first, joined for names."""
        try:
            response = (
                self._client.table(FOLLOW_REQUESTS)
                .select(
                    "requester_id, created_at, "
                    "user_info!follow_requests_requester_id_fkey"
                    "(email, first_name, last_name)"
                )
                .eq("target_id", target_id)
                .order("created_at", desc=True)
                .range(offset, offset + limit - 1)
                .execute()
            )
            data = getattr(response, "data", None)
            if not isinstance(data, list):
                return []

            rows: list[dict[str, Any]] = []
            for row in data:
                info = row.get("user_info") or {}
                rows.append(
                    {
                        "user_id": row.get("requester_id"),
                        "email": info.get("email"),
                        "first_name": info.get("first_name"),
                        "last_name": info.get("last_name"),
                        "created_at": row.get("created_at"),
                    }
                )
            return rows
        except Exception as exception:
            logger.exception("Failed to list requests for %s: %s", target_id, exception)
            return []
```

- [ ] **Step 6: Mount it on the client and the harness**

In `services/supabase_client.py`, add the import and put
`CommunityFollowRequestOperations` in the base list right after
`CommunityFollowOperations`. Do the same for `OperationHarness` in
`tests/test_operations_units.py`.

- [ ] **Step 7: Run the tests**

```bash
cd backend/community-backend && ../../.venv/bin/pytest -q
```

Expected: all pass. If
`test_a_pending_requester_cannot_read_followers_tier_posts` fails, the
request leaked into `follows` — that is the bug this whole design exists to
prevent, so stop and read the upsert branch of the fake.

- [ ] **Step 8: Commit**

```bash
cd /Users/matthewng/Desktop/Snowtrak
git add backend/community-backend/
git commit -m "feat(follows): add pending follow requests

Requests live in their own table so \`follows\` keeps meaning an accepted
edge. Approving goes through a Postgres function because the delete and the
insert must not be separable, and because two statements to a database
440ms away is a round trip nobody needs to pay.

is_private_account fails closed: an unreadable flag is treated as private,
so the worst case is a request that needed no approval rather than a follow
that skipped one.

The fake PostgREST harness gains upsert and rpc. Without them approve and
follow_stats had no unit coverage at all, and both are load-bearing."
```

---

## Task 4: Follow becomes a request when the target is private

**Files:**
- Modify: `backend/community-backend/routes/follows_routes.py`
- Modify: `backend/community-backend/routes/community_models.py:110-117`
- Test: `backend/community-backend/tests/test_follows_routes.py` (create if absent)

**Interfaces:**
- Consumes: Task 3's `is_private_account`, `request_follow`,
  `withdraw_request`, `deny_request`, `approve_request`, `list_requests`,
  `count_requests`.
- Produces: `POST /api/v1/follows/{user_id}` now returns **200** with
  `{"state": "following" | "requested"}`; `FollowStatsResponse` gains
  `is_private: bool` and `has_requested: bool`; four new routes.

- [ ] **Step 1: Write the failing test**

In `backend/community-backend/tests/test_follows_routes.py`:

```python
def test_following_a_public_account_returns_following(client, stub):
    stub.private_accounts = set()
    response = client.post("/api/v1/follows/user-2")
    assert response.status_code == 200
    assert response.json() == {"state": "following"}
    assert ("user-1", "user-2") in stub.follows


def test_following_a_private_account_returns_requested(client, stub):
    stub.private_accounts = {"user-2"}
    response = client.post("/api/v1/follows/user-2")
    assert response.status_code == 200
    assert response.json() == {"state": "requested"}
    assert ("user-1", "user-2") in stub.requests
    assert ("user-1", "user-2") not in stub.follows
```

Follow the stub pattern already in `tests/conftest.py` — `StubCommunityClient`
with the dependency overridden — rather than inventing a second one.

- [ ] **Step 2: Run and watch it fail**

```bash
cd backend/community-backend && ../../.venv/bin/pytest tests/test_follows_routes.py -v
```

Expected: 204, not 200 — the route does not yet report which happened.

- [ ] **Step 3: Extend the response models**

In `routes/community_models.py`:

```python
class FollowStatsResponse(BaseModel):
    """Counts plus the viewing user's relationship to this profile."""

    follower_count: int = 0
    following_count: int = 0
    is_following: bool = False
    is_followed_by: bool = False
    is_private: bool = False
    has_requested: bool = False


class FollowResultResponse(BaseModel):
    """What tapping Follow actually did.

    A private account turns a follow into a request, and the client cannot
    guess which happened. A status code is a worse place to put that than a
    body, which is why this endpoint no longer answers 204.
    """

    state: str  # "following" | "requested"
```

- [ ] **Step 4: Rewrite the follow route**

In `routes/follows_routes.py`, replace `follow_user`:

```python
@router.post("/{user_id}", response_model=FollowResultResponse)
async def follow_user(
    user_id: UUID,
    current_user: str = Depends(get_current_user),
):
    """Follow somebody, or ask to. Idempotent either way.

    The privacy flag is read fresh on every call, never from cache. The
    cached follow_stats can be up to CACHE_FOLLOW_STATS_TTL_SECONDS stale,
    but that only mislabels the button -- the decision made here is not
    allowed to come from a cache.
    """
    target = str(user_id)
    if target == current_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You cannot follow yourself",
        ) from None

    client = get_community_client()

    if await offload(client.is_private_account, target):
        if not await offload(client.request_follow, current_user, target):
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Could not request to follow this user",
            ) from None
        await invalidate_follow_stats_cache()
        return FollowResultResponse(state="requested")

    if not await offload(client.follow, current_user, target):
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Could not follow this user",
        ) from None
    await invalidate_follow_stats_cache()
    return FollowResultResponse(state="following")
```

- [ ] **Step 5: Add the four request routes**

Put them immediately after `remove_follower`, above `POST /{user_id}`, under
the existing registration-order comment — a `/{user_id}` route registered
first swallows any sibling with the same segment count.

```python
@router.get("/me/requests", response_model=ListResponse)
async def list_my_requests(
    request: Request,
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    current_user: str = Depends(get_current_user),
):
    """People asking to follow you, newest first."""
    client = get_community_client()
    rows = await offload(client.list_requests, current_user, limit, offset)
    total = await offload(client.count_requests, current_user)
    return build_paginated_list_response(
        request=request,
        items=[FollowUserResponse(**row) for row in rows],
        limit=limit,
        offset=offset,
        total=total,
    )


@router.post("/me/requests/{user_id}/approve", status_code=status.HTTP_204_NO_CONTENT)
async def approve_request(
    user_id: UUID,
    current_user: str = Depends(get_current_user),
):
    """Let somebody in. 404 when there was no request to approve."""
    if not await offload(get_community_client().approve_request, current_user, str(user_id)):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No such follow request",
        ) from None
    await invalidate_follow_stats_cache()


@router.delete("/me/requests/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def deny_request(
    user_id: UUID,
    current_user: str = Depends(get_current_user),
):
    """Refuse a request. Succeeds even if there was none."""
    await offload(get_community_client().deny_request, current_user, str(user_id))
    await invalidate_follow_stats_cache()


@router.delete("/{user_id}/request", status_code=status.HTTP_204_NO_CONTENT)
async def withdraw_request(
    user_id: UUID,
    current_user: str = Depends(get_current_user),
):
    """Take back a request you sent. Succeeds even if there was none."""
    await offload(get_community_client().withdraw_request, current_user, str(user_id))
    await invalidate_follow_stats_cache()
```

- [ ] **Step 6: Run the tests**

```bash
cd backend/community-backend && ../../.venv/bin/pytest -q
```

- [ ] **Step 7: Commit**

```bash
cd /Users/matthewng/Desktop/Snowtrak
git add backend/community-backend/
git commit -m "feat(follows): turn a follow into a request for private accounts

POST /api/v1/follows/{id} no longer answers 204. It returns the state it
reached -- following or requested -- because the client cannot guess which
happened and a status code is a worse place to put that than a body. This
breaks one caller, shipped four commits ago.

The privacy flag is read fresh on every call. follow_stats is cached for
two minutes, but that cache is only allowed to mislabel the button, never
to make the decision."
```

---

## Task 5: A private account's follower list is not public

**Files:**
- Modify: `backend/community-backend/routes/follows_routes.py:107-168`
- Test: `backend/community-backend/tests/test_follows_routes.py`

**Interfaces:**
- Consumes: Task 3's `is_private_account`, Task 2's unchanged
  `is_following`.
- Produces: no new symbols; `GET /follows/{id}/followers` and `/following`
  gain `get_optional_user` and a 403.

Both endpoints currently take no authentication at all. A follower list is
not a post — it is the social graph itself, and it is the one thing on a
private profile that reveals who is inside the circle.

`_edge_page` is also synchronous and is called without `offload`, which
stalls the event loop the same way the read paths did before `5d71da3`.
Fixed here because this task rewrites the function anyway.

- [ ] **Step 1: Write the failing test**

```python
def test_a_strangers_view_of_a_private_follower_list_is_refused(client, stub):
    stub.private_accounts = {"user-2"}
    assert client.get("/api/v1/follows/user-2/followers").status_code == 403


def test_an_approved_follower_sees_the_list(client, stub):
    stub.private_accounts = {"user-2"}
    stub.follows.add(("user-1", "user-2"))
    assert client.get("/api/v1/follows/user-2/followers").status_code == 200


def test_a_public_accounts_list_stays_open(client, stub):
    stub.private_accounts = set()
    assert client.get("/api/v1/follows/user-2/followers").status_code == 200
```

- [ ] **Step 2: Run and watch it fail**

```bash
cd backend/community-backend && \
  ../../.venv/bin/pytest tests/test_follows_routes.py -k follower_list -v
```

Expected: 200 where 403 is wanted.

- [ ] **Step 3: Add the gate and make `_edge_page` async**

```python
async def _may_see_edges(client, target: str, viewer: str | None) -> bool:
    """Whether `viewer` may see who `target` follows, and who follows them.

    A public account's lists stay public -- the two axes are independent and
    a post tier does not govern this. A private account's do not: the list
    is the social graph itself.
    """
    if not await offload(client.is_private_account, target):
        return True
    if viewer is None:
        return False
    if viewer == target:
        return True
    return await offload(client.is_following, viewer, target)


async def _edge_page(
    *,
    request: Request,
    user_id: str,
    viewer: str | None,
    direction: str,
    limit: int,
    offset: int,
) -> ListResponse:
    client = get_community_client()

    if not await _may_see_edges(client, user_id, viewer):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This account is private",
        ) from None

    rows = await offload(
        client.list_follow_edges,
        user_id=user_id,
        direction=direction,
        limit=limit,
        offset=offset,
    )
    total = await offload(
        client.count_followers if direction == "followers" else client.count_following,
        user_id,
    )
    return build_paginated_list_response(
        request=request,
        items=[FollowUserResponse(**row) for row in rows],
        limit=limit,
        offset=offset,
        total=total,
    )
```

- [ ] **Step 4: Thread the viewer through both routes**

Add `current_user: str | None = Depends(get_optional_user)` to
`list_followers` and `list_following`, pass it as `viewer=current_user`, and
`await` the `_edge_page` call in both.

- [ ] **Step 5: Run the tests**

```bash
cd backend/community-backend && ../../.venv/bin/pytest -q
```

- [ ] **Step 6: Commit**

```bash
cd /Users/matthewng/Desktop/Snowtrak
git add backend/community-backend/
git commit -m "feat(follows): hide a private account's follower lists

Both list endpoints took no authentication at all. A follower list is not a
post -- the two axes stay independent and a public account's lists stay
public -- but it is the social graph itself, and on a private account it is
the one thing that shows who is inside the circle.

_edge_page also stops blocking the event loop, the same fix 5d71da3 applied
to the read paths. It is rewritten here anyway."
```

---

## Task 6: The switch that sets the flag

**Files:**
- Modify: `backend/main-backend/app/api/v1/users_profile_routes.py`
- Modify: `backend/main-backend/app/core/supabase/` (the `user_info` module)
- Test: `backend/main-backend/tests/` — follow the existing route-test pattern

**Interfaces:**
- Produces: `PUT /api/v1/users/me/privacy`, body
  `{"is_private": bool}`, response `{"is_private": bool}`.

The flag is **not** added to `ProfileResponse`. It already reaches the client
through `follow_stats`, which the profile header calls anyway, so putting it
in the profile payload would buy a second copy of the same truth and a second
place for it to go stale.

- [ ] **Step 1: Write the failing test**

```python
def test_setting_privacy_persists_and_echoes(client, stub_supabase):
    response = client.put("/api/v1/users/me/privacy", json={"is_private": True})
    assert response.status_code == 200
    assert response.json() == {"is_private": True}
    assert stub_supabase.user_info["user-1"]["is_private"] is True


def test_clearing_privacy_persists(client, stub_supabase):
    client.put("/api/v1/users/me/privacy", json={"is_private": True})
    response = client.put("/api/v1/users/me/privacy", json={"is_private": False})
    assert response.json() == {"is_private": False}
    assert stub_supabase.user_info["user-1"]["is_private"] is False
```

- [ ] **Step 2: Run and watch it fail**

```bash
cd backend/main-backend && ../../.venv/bin/pytest -k privacy -v
```

Expected: 404 — the route does not exist.

- [ ] **Step 3: Add the write to the Supabase layer**

Alongside the existing `get_user_info_by_id`, in the same module:

```python
    def set_user_privacy(self, user_id: str, is_private: bool) -> bool:
        """Set whether this account approves its followers.

        On user_info rather than profiles: most users have no profiles row,
        and a privacy flag that is absent for some users is not a privacy
        flag. See backend/db/migrations/015_account_privacy.sql.
        """
        response = (
            self._client.table("user_info")
            .update({"is_private": is_private})
            .eq("id", user_id)
            .execute()
        )
        return bool(getattr(response, "data", None))
```

- [ ] **Step 4: Add the route**

In `users_profile_routes.py`:

```python
class PrivacySetting(BaseModel):
    """Whether this account approves its followers."""

    is_private: bool


@router.put("/me/privacy", response_model=PrivacySetting)
async def set_my_privacy(
    setting: PrivacySetting,
    current_user: User = Depends(get_current_user),
):
    """Turn follower approval on or off.

    Existing followers are kept. Turning private does not retroactively hide
    followers-only content from people who already follow you -- the escape
    hatch for that is DELETE /api/v1/follows/me/followers/{id}.

    community-backend caches follow_stats, which carries this flag, for
    CACHE_FOLLOW_STATS_TTL_SECONDS. No invalidation is wired across the
    service boundary for one field.

    # ponytail: up to 120s of stale is_private in another viewer's cached
    # stats. POST /follows/{id} re-reads it fresh, so only the button's
    # label lags, never the gate. If that becomes visible, bump the
    # follow-stats cache version from here.
    """
    _ensure_database_configured()

    if not supabase_client.set_user_privacy(current_user.id, setting.is_private):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        ) from None

    invalidate_profile(current_user.id)
    return setting
```

- [ ] **Step 5: Run the tests**

```bash
cd backend/main-backend && ../../.venv/bin/pytest -q
```

- [ ] **Step 6: Commit**

```bash
cd /Users/matthewng/Desktop/Snowtrak
git add backend/main-backend/
git commit -m "feat(auth): let an account require approval for followers

One endpoint, one column. The flag is not added to ProfileResponse: it
already reaches the client through follow_stats, which the profile header
calls anyway, and a second copy is a second place for it to go stale.

Existing followers are kept when the flag goes on. Turning private does not
retroactively hide anything from people who already follow you; removing a
follower is the endpoint for that, and it already ships."
```

---

## Task 7: Stop `GET /activities/` returning everything

This is the live leak. It is independent of the rest of the feature and
should not wait for it.

**Files:**
- Create: `backend/activity-backend/services/offload.py`
- Modify: `backend/activity-backend/services/supabase_client.py:159-201`
- Modify: `backend/activity-backend/routes/activities_list_routes.py:28-62`
- Modify: `backend/activity-backend/routes/activities_management_routes.py:108-143`
- Test: `backend/activity-backend/tests/test_activities_api.py`

**Interfaces:**
- Consumes: `shared.visibility.visible_rows_expression`,
  `shared.visibility.can_view`, `shared.follow_graph.following_ids` from
  Task 2.
- Produces: `ActivitySupabaseClient.list_activities(viewer_id, following,
  limit, offset)` and `ActivitySupabaseClient.following_ids(user_id)`.

- [ ] **Step 1: Write the failing test**

```python
def test_anonymous_activity_list_returns_only_public(client, stub_client):
    stub_client.activities = [
        {**BASE, "id": "a-public", "user_id": "u-1", "visibility": "public"},
        {**BASE, "id": "a-private", "user_id": "u-1", "visibility": "private"},
        {**BASE, "id": "a-followers", "user_id": "u-1", "visibility": "followers"},
    ]
    ids = {i["id"] for i in client.get("/api/v1/activities/").json()["items"]}
    assert ids == {"a-public"}


def test_a_follower_sees_the_followers_tier(client, stub_client, as_user):
    as_user("u-2")
    stub_client.follows = {("u-2", "u-1")}
    stub_client.activities = [
        {**BASE, "id": "a-public", "user_id": "u-1", "visibility": "public"},
        {**BASE, "id": "a-followers", "user_id": "u-1", "visibility": "followers"},
        {**BASE, "id": "a-private", "user_id": "u-1", "visibility": "private"},
    ]
    ids = {i["id"] for i in client.get("/api/v1/activities/").json()["items"]}
    assert ids == {"a-public", "a-followers"}


def test_the_owner_sees_their_own_private_activity(client, stub_client, as_user):
    as_user("u-1")
    stub_client.activities = [
        {**BASE, "id": "a-private", "user_id": "u-1", "visibility": "private"},
    ]
    ids = {i["id"] for i in client.get("/api/v1/activities/").json()["items"]}
    assert ids == {"a-private"}
```

`StubActivityClient` in `tests/conftest.py` needs to grow an `activities`
list, a `follows` set, and an `.or_()`-aware `list_activities`. Reuse the
`_matches_or` evaluator from
`backend/community-backend/tests/test_operations_units.py` — copy it into
`backend/activity-backend/tests/conftest.py` rather than importing across
service directories, which are hyphenated and not importable packages.

- [ ] **Step 2: Run and watch it fail**

```bash
cd backend/activity-backend && ../../.venv/bin/pytest -k activity_list -v
```

Expected: all three activities come back for the anonymous caller. That
failure is the bug, reproduced.

- [ ] **Step 3: Copy `offload` into activity-backend**

`backend/activity-backend/services/offload.py`:

```python
"""Run a blocking Supabase call without stalling the event loop.

supabase-py is synchronous. Called directly from an `async def` handler it
holds the loop for the whole round trip -- ~440ms to ap-south-1 -- and every
other request in flight waits behind it. Adding the visibility filter puts a
second query in front of every activity list, which makes that worse, so it
is fixed here rather than left.

Identical to backend/community-backend/services/offload.py. Four lines
duplicated across two services beats a shared module that exists to hold
four lines.
"""

import asyncio
from functools import partial


async def offload(fn, *args, **kwargs):
    return await asyncio.to_thread(partial(fn, *args, **kwargs))
```

- [ ] **Step 4: Filter in the client**

In `services/supabase_client.py`:

```python
from shared.follow_graph import following_ids as _following_ids
from shared.visibility import visible_rows_expression


    def following_ids(self, user_id: str) -> list[str]:
        """Ids `user_id` follows, for the visibility filter.

        Reads community-backend's table directly. An HTTP hop would put two
        more round trips in front of every activity list; see
        backend/shared/follow_graph.py. Reads only -- writes stay there.
        """
        return _following_ids(self._client, user_id)

    def list_activities(
        self,
        viewer_id: str | None = None,
        following: list[str] | None = None,
        limit: int = 20,
        offset: int = 0,
    ) -> dict[str, Any]:
        """Activities this viewer may see, newest first.

        This used to be an unfiltered select. It returned every private GPS
        track in the database to an unauthenticated caller.
        """
        resp = (
            self._client.table("activities")
            .select("*", count=CountMethod.exact)
            .or_(visible_rows_expression(viewer_id, following))
            .order("created_at", desc=True)
            .range(offset, offset + limit - 1)
            .execute()
        )
        data = getattr(resp, "data", []) or []
        total = getattr(resp, "count", 0) or 0
        return {"items": data, "total": total}
```

The `order` is new: `docs/client_feed_cache_and_rate_limiting.md` requires an
explicit ordering on every paginated query against a growing table, and this
one never had one.

- [ ] **Step 5: Thread the viewer through the list route**

In `routes/activities_list_routes.py`:

```python
@router.get("/", response_model=ListResponse)
async def list_activities(
    request: Request,
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    viewer_id: str | None = Depends(get_optional_user),
):
    """List the activities this viewer is allowed to see."""
    activity_client = get_activity_client()
    try:
        following = await offload(activity_client.following_ids, viewer_id) if viewer_id else []
        activity_list_response = await offload(
            activity_client.list_activities,
            viewer_id=viewer_id,
            following=following,
            limit=limit,
            offset=offset,
        )
        ...
```

The rest of the body is unchanged.

- [ ] **Step 6: Use the shared rule on the detail route**

In `routes/activities_management_routes.py`, replace the hand-rolled check at
line 123-125:

```python
        following = await offload(
            get_activity_client().following_ids, user_id
        ) if user_id else []
        if not can_view(activity_record, user_id, following):
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Activity not found",
            ) from None
```

404, not 403: a private activity's existence is itself private, and this
matches what the post detail route already does.

- [ ] **Step 7: Run the tests**

```bash
cd backend/activity-backend && ../../.venv/bin/pytest -q
```

- [ ] **Step 8: Commit**

```bash
cd /Users/matthewng/Desktop/Snowtrak
git add backend/activity-backend/
git commit -m "fix(activity): stop the activity list returning everything to everyone

GET /api/v1/activities/ took no authentication and applied no filter. Its
docstring said 'List public activities'; it was a bare select(*) with a
range, so every private GPS track in the database was readable by anyone,
and the app calls it.

It now takes the same visibility predicate the community read paths use,
and the detail route stops hand-rolling its own two-thirds of that rule.

The query also gains an explicit ordering, which a paginated read of a
growing table is supposed to have and this one never did. Blocking calls
move off the event loop, because adding the follow lookup puts a second
round trip in front of every list."
```

---

## Task 8: A private activity's comments are private too

**Files:**
- Modify: `backend/activity-backend/routes/activities_social_routes.py`
- Test: `backend/activity-backend/tests/test_activities_api.py`

**Interfaces:**
- Consumes: Task 7's `following_ids` and `offload`, `shared.visibility.can_view`.
- Produces: a module-level `_require_visible(activity_id, viewer_id)` used by
  the comments, kudos and share routes.

`GET /{id}/comments` has no authentication and no check against its parent.
A comment list on a private activity leaks the activity's existence and the
names of everyone who engaged with it. Kudos and share require a login but
never check that the caller may see what they are reacting to.

- [ ] **Step 1: Write the failing test**

```python
def test_comments_on_an_invisible_activity_are_refused(client, stub_client):
    stub_client.activities = [
        {**BASE, "id": "a-1", "user_id": "u-1", "visibility": "private"},
    ]
    assert client.get("/api/v1/activities/a-1/comments").status_code == 404


def test_comments_on_a_public_activity_are_open(client, stub_client):
    stub_client.activities = [
        {**BASE, "id": "a-1", "user_id": "u-1", "visibility": "public"},
    ]
    assert client.get("/api/v1/activities/a-1/comments").status_code == 200


def test_kudos_on_an_invisible_activity_are_refused(client, stub_client, as_user):
    as_user("u-2")
    stub_client.activities = [
        {**BASE, "id": "a-1", "user_id": "u-1", "visibility": "private"},
    ]
    assert client.post("/api/v1/activities/a-1/kudos").status_code == 404
```

- [ ] **Step 2: Run and watch it fail**

```bash
cd backend/activity-backend && ../../.venv/bin/pytest -k invisible -v
```

Expected: 200 where 404 is wanted.

- [ ] **Step 3: Add the shared guard**

```python
async def _require_visible(activity_id: str, viewer_id: str | None) -> dict:
    """Fetch an activity, or 404 if this viewer may not see it.

    404 rather than 403: a private activity's existence is itself private.
    """
    client = get_activity_client()
    record = await offload(client.get_activity_by_id, activity_id)
    following = await offload(client.following_ids, viewer_id) if viewer_id else []
    if record is None or not can_view(record, viewer_id, following):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Activity not found",
        ) from None
    return record
```

- [ ] **Step 4: Call it from all four routes**

`list_comments` and `add_comment` gain
`viewer_id: str | None = Depends(get_optional_user)` and
`viewer_id: str = Depends(get_current_user)` respectively; `toggle_kudos` and
`create_share_link` already have `user_id`. Each begins with:

```python
    await _require_visible(str(activity_id), viewer_id)
```

- [ ] **Step 5: Run the tests**

```bash
cd backend/activity-backend && ../../.venv/bin/pytest -q
```

- [ ] **Step 6: Commit**

```bash
cd /Users/matthewng/Desktop/Snowtrak
git add backend/activity-backend/
git commit -m "fix(activity): gate comments, kudos and shares on the parent

GET /{id}/comments took no authentication and never looked at the activity
it belonged to, so a comment list leaked a private activity's existence and
the names of everyone who engaged with it. Kudos and share required a login
but never checked that the caller could see what they were reacting to.

404 rather than 403 throughout: a private activity's existence is itself
private, and that is what the post detail route already does."
```

---

## Task 9: Three states on the follow button

**Files:**
- Modify: `frontend/lib/models/follow_stats.dart`
- Modify: `frontend/lib/services/apis/follow_api.dart`
- Modify: `frontend/lib/services/follow_service.dart`
- Modify: `frontend/lib/widgets/follow_button.dart`
- Test: `frontend/test/follow_stats_test.dart`
- Test: `frontend/test/widgets/follow_button_layout_test.dart`

**Interfaces:**
- Consumes: Task 4's `{"state": "following" | "requested"}` and the two new
  `follow_stats` keys.
- Produces: `FollowStats.isPrivate`, `FollowStats.hasRequested`,
  `FollowStats.requested()`, `FollowApi.follow(String) -> Future<String>`,
  `FollowApi.withdrawRequest(String) -> Future<void>`,
  `FollowService.withdrawRequest(String) -> Future<AppResult<void>>`.

- [ ] **Step 1: Write the failing test**

Append to `frontend/test/follow_stats_test.dart`:

```dart
test('parses the privacy fields', () {
  final stats = FollowStats.fromJson(const {
    'follower_count': 3,
    'following_count': 1,
    'is_following': false,
    'is_followed_by': false,
    'is_private': true,
    'has_requested': true,
  });
  expect(stats.isPrivate, isTrue);
  expect(stats.hasRequested, isTrue);
});

test('an older payload without the privacy fields still parses', () {
  final stats = FollowStats.fromJson(const {
    'follower_count': 3,
    'following_count': 1,
    'is_following': true,
    'is_followed_by': false,
  });
  expect(stats.isPrivate, isFalse);
  expect(stats.hasRequested, isFalse);
});

test('requesting flips only the request flag, never the count', () {
  const stats = FollowStats(followerCount: 7, isPrivate: true);
  final after = stats.requested();
  expect(after.hasRequested, isTrue);
  expect(after.isFollowing, isFalse);
  // A request is not a follower. The count must not move.
  expect(after.followerCount, 7);
});

test('withdrawing clears the flag', () {
  const stats = FollowStats(isPrivate: true, hasRequested: true);
  expect(stats.requested().hasRequested, isFalse);
});
```

- [ ] **Step 2: Run and watch it fail**

```bash
cd frontend && flutter test test/follow_stats_test.dart
```

Expected: `No named parameter with the name 'isPrivate'`.

- [ ] **Step 3: Extend the model**

```dart
class FollowStats {
  const FollowStats({
    this.followerCount = 0,
    this.followingCount = 0,
    this.isFollowing = false,
    this.isFollowedBy = false,
    this.isPrivate = false,
    this.hasRequested = false,
  });

  final int followerCount;
  final int followingCount;

  /// The viewer follows this profile.
  final bool isFollowing;

  /// This profile follows the viewer — what makes a "Follows you" badge.
  final bool isFollowedBy;

  /// This account approves its followers, so Follow sends a request.
  final bool isPrivate;

  /// The viewer has a request pending on this account.
  final bool hasRequested;

  factory FollowStats.fromJson(Map<String, dynamic> json) {
    return FollowStats(
      followerCount: (json['follower_count'] as num?)?.toInt() ?? 0,
      followingCount: (json['following_count'] as num?)?.toInt() ?? 0,
      isFollowing: json['is_following'] as bool? ?? false,
      isFollowedBy: json['is_followed_by'] as bool? ?? false,
      isPrivate: json['is_private'] as bool? ?? false,
      hasRequested: json['has_requested'] as bool? ?? false,
    );
  }

  /// The optimistic result of tapping Follow / Following on a public
  /// account, before the request lands. Reverted by re-fetching on failure.
  FollowStats toggled() {
    return FollowStats(
      followerCount: isFollowing
          ? (followerCount > 0 ? followerCount - 1 : 0)
          : followerCount + 1,
      followingCount: followingCount,
      isFollowing: !isFollowing,
      isFollowedBy: isFollowedBy,
      isPrivate: isPrivate,
      hasRequested: hasRequested,
    );
  }

  /// The optimistic result of asking, or of taking the ask back.
  ///
  /// The follower count does not move: a request is not a follower, and
  /// showing it as one would be a lie the server corrects a second later.
  FollowStats requested() {
    return FollowStats(
      followerCount: followerCount,
      followingCount: followingCount,
      isFollowing: isFollowing,
      isFollowedBy: isFollowedBy,
      isPrivate: isPrivate,
      hasRequested: !hasRequested,
    );
  }
}
```

- [ ] **Step 4: Return the state from the API**

In `follow_api.dart`:

```dart
  /// Follow, or ask to. Returns `following` or `requested` — a private
  /// account turns the first into the second and the client cannot guess.
  Future<String> follow(String userId) async {
    final response = await _dio.post<Map<String, dynamic>>('/follows/$userId');
    return response.data?['state'] as String? ?? 'following';
  }

  /// Take back a request you sent.
  Future<void> withdrawRequest(String userId) =>
      _dio.delete<void>('/follows/$userId/request');
```

And in `follow_service.dart`:

```dart
  Future<AppResult<String>> follow(String userId) =>
      _run(() => _followApi.follow(userId));

  Future<AppResult<void>> withdrawRequest(String userId) =>
      _run(() => _followApi.withdrawRequest(userId));
```

- [ ] **Step 5: Write the failing widget test**

```dart
testWidgets('a private account shows Follow, then Requested', (tester) async {
  fakeService.stats = const FollowStats(isPrivate: true);
  fakeService.followState = 'requested';

  await tester.pumpWidget(_host(const FollowButton(userId: 'user-2')));
  await tester.pumpAndSettle();
  expect(find.text('Follow'), findsOneWidget);

  await tester.tap(find.text('Follow'));
  await tester.pumpAndSettle();
  expect(find.text('Requested'), findsOneWidget);
  expect(find.text('Following'), findsNothing);
});

testWidgets('tapping Requested withdraws', (tester) async {
  fakeService.stats = const FollowStats(isPrivate: true, hasRequested: true);

  await tester.pumpWidget(_host(const FollowButton(userId: 'user-2')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Requested'));
  await tester.pumpAndSettle();

  expect(fakeService.withdrawn, contains('user-2'));
  expect(find.text('Follow'), findsOneWidget);
});
```

- [ ] **Step 6: Add the third state to the button**

Replace `_toggle` and the `_action` tail:

```dart
  Future<void> _toggle() async {
    final current = _stats;
    if (current == null || _busy) return;

    // Flip first: a follow that takes a round trip to acknowledge feels
    // broken. The server's answer replaces the guess a moment later.
    setState(() {
      _stats = current.hasRequested || (current.isPrivate && !current.isFollowing)
          ? current.requested()
          : current.toggled();
      _busy = true;
    });

    final AppResult<void> result;
    if (current.isFollowing) {
      result = await _followService.unfollow(widget.userId);
    } else if (current.hasRequested) {
      result = await _followService.withdrawRequest(widget.userId);
    } else {
      final followed = await _followService.follow(widget.userId);
      // The server decides which of the two happened; a private account we
      // did not know about turns a follow into a request.
      if (followed case AppSuccess(:final value) when mounted) {
        setState(() {
          _stats = value == 'requested'
              ? current.requested()
              : current.toggled();
        });
      }
      result = switch (followed) {
        AppSuccess() => const AppSuccess(null),
        AppFailure(:final error) => AppFailure(error),
      };
    }

    if (!mounted) return;

    switch (result) {
      case AppSuccess():
        setState(() => _busy = false);
        widget.onChanged?.call(_stats!);
      case AppFailure(:final error):
        setState(() {
          _stats = current;
          _busy = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.userMessage)),
        );
    }
  }
```

and, in `_action`, before the `isFollowing` branch:

```dart
    if (stats.hasRequested) {
      return OutlinedButton(
        onPressed: _busy ? null : _toggle,
        style: _outlinedStyle,
        child: const Text('Requested'),
      );
    }
```

- [ ] **Step 7: Run analyze and the tests**

```bash
cd frontend && dart analyze lib test && flutter test
```

Expected: 0 errors, 0 warnings, 33 tests passing. The `home preview` golden
that used to fail was un-gated in `3e3517f`; if it fails again, that is a
regression worth reporting rather than the known-bad it used to be.

- [ ] **Step 8: Commit**

```bash
cd /Users/matthewng/Desktop/Snowtrak
git add frontend/lib/models/follow_stats.dart frontend/lib/services/ \
        frontend/lib/widgets/follow_button.dart frontend/test/
git commit -m "feat(follows): give the follow button a Requested state

The server decides whether a tap became a follow or a request, so the
button reads the state out of the response rather than guessing from what
it knew when it mounted -- a private account it had stale stats for still
lands on the right label.

requested() deliberately leaves the follower count alone. A request is not
a follower, and moving the number would be a lie the server corrects a
second later."
```

---

## Task 10: The privacy switch

**Files:**
- Modify: `frontend/lib/screens/settings/privacy_settings_screen.dart`
- Create: `frontend/lib/services/apis/privacy_api.dart`
- Test: `frontend/test/widgets/privacy_switch_test.dart`

**Interfaces:**
- Consumes: Task 6's `PUT /api/v1/users/me/privacy`, Task 9's
  `FollowStats.isPrivate`.
- Produces: `PrivacyApi.setPrivate(bool) -> Future<bool>`.

**Run `git status` first.** This file is modified in the working tree by
someone else's in-flight design work. If it is dirty, coordinate before
editing rather than overwriting.

The current value is read from `FollowStats.isPrivate` via
`FollowService.getStats(myUserId)` — the same call the profile header makes,
so no second source of truth and no new endpoint on the read side.

- [ ] **Step 1: Write the failing test**

```dart
testWidgets('the switch reflects the account and writes on change',
    (tester) async {
  fakeFollowService.stats = const FollowStats(isPrivate: false);

  await tester.pumpWidget(_host(const PrivacySettingsScreen()));
  await tester.pumpAndSettle();

  final toggle = find.byKey(const Key('private-account-switch'));
  expect(tester.widget<SwitchListTile>(toggle).value, isFalse);

  await tester.tap(toggle);
  await tester.pumpAndSettle();

  expect(fakePrivacyApi.lastWritten, isTrue);
  expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
});
```

- [ ] **Step 2: Run and watch it fail**

```bash
cd frontend && flutter test test/widgets/privacy_switch_test.dart
```

Expected: no widget with that key.

- [ ] **Step 3: Write the API client**

`frontend/lib/services/apis/privacy_api.dart`:

```dart
import 'package:dio/dio.dart';

/// The account privacy flag, on main-backend.
///
/// The read side is [FollowStats.isPrivate], which the profile header
/// already fetches — this is the write half only.
class PrivacyApi {
  PrivacyApi({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<bool> setPrivate(bool isPrivate) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/users/me/privacy',
      data: {'is_private': isPrivate},
    );
    return response.data?['is_private'] as bool? ?? isPrivate;
  }
}
```

Register it in `lib/core/di/service_locator.dart` beside `FollowApi`, using
the same `Dio` instance that `FollowApi` gets.

- [ ] **Step 4: Add the switch**

In `privacy_settings_screen.dart`, as the first item in the existing list:

```dart
SwitchListTile(
  key: const Key('private-account-switch'),
  value: _isPrivate,
  onChanged: _busy ? null : _setPrivate,
  title: Text(
    'Private account',
    style: SnowtrakTypography.bodyLarge.copyWith(
      color: context.colors.textPrimary,
    ),
  ),
  subtitle: Text(
    'People have to ask before they can follow you. '
    'Anyone already following you stays.',
    style: SnowtrakTypography.bodySmall.copyWith(
      color: context.colors.textSecondary,
    ),
  ),
),
```

The subtitle says the second sentence out loud on purpose: turning private
does not retroactively remove existing followers, and that will surprise
somebody who is not told.

```dart
  Future<void> _setPrivate(bool value) async {
    final previous = _isPrivate;
    setState(() {
      _isPrivate = value;
      _busy = true;
    });
    try {
      final settled = await sl<PrivacyApi>().setPrivate(value);
      if (!mounted) return;
      setState(() {
        _isPrivate = settled;
        _busy = false;
      });
    } catch (_) {
      if (!mounted) return;
      // Fall back to what the server last told us rather than leaving the
      // switch showing a change that did not happen.
      setState(() {
        _isPrivate = previous;
        _busy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not change your privacy setting')),
      );
    }
  }
```

- [ ] **Step 5: Run analyze and the tests**

```bash
cd frontend && dart analyze lib test && flutter test
```

- [ ] **Step 6: Commit**

```bash
cd /Users/matthewng/Desktop/Snowtrak
git add frontend/lib/services/apis/privacy_api.dart \
        frontend/lib/screens/settings/privacy_settings_screen.dart \
        frontend/lib/core/di/service_locator.dart frontend/test/
git commit -m "feat(follows): add the private account switch

The current value comes from FollowStats, which the profile header already
fetches, so there is one source of truth and no new read endpoint.

The subtitle says that existing followers stay, because that is the part of
turning private that surprises people and it is better said in the UI than
discovered later."
```

---

## Task 11: The requests screen

**Files:**
- Create: `frontend/lib/screens/profile/follow_requests_screen.dart`
- Modify: `frontend/lib/services/apis/follow_api.dart`
- Modify: `frontend/lib/services/follow_service.dart`
- Modify: `frontend/lib/widgets/profile_header.dart`
- Test: `frontend/test/widgets/follow_requests_screen_test.dart`

**Interfaces:**
- Consumes: Task 4's `GET /follows/me/requests`,
  `POST /follows/me/requests/{id}/approve`,
  `DELETE /follows/me/requests/{id}`.
- Produces: `FollowApi.getRequests({limit, offset})`,
  `FollowApi.approveRequest(String)`, `FollowApi.denyRequest(String)`, the
  matching `FollowService` wrappers, and
  `FollowRequestsScreen` plus `openFollowRequests(BuildContext)`.

This is the whole notification surface. There is no push: `device_tokens`
exists as a table and no backend code has ever read it, and sending is a
subsystem rather than a field.

- [ ] **Step 1: Write the failing test**

```dart
testWidgets('approving removes the row and calls the service', (tester) async {
  fakeService.requests = [
    {'user_id': 'u-9', 'first_name': 'Pow', 'last_name': 'Fan'},
  ];

  await tester.pumpWidget(_host(const FollowRequestsScreen()));
  await tester.pumpAndSettle();
  expect(find.text('Pow Fan'), findsOneWidget);

  await tester.tap(find.text('Approve'));
  await tester.pumpAndSettle();

  expect(fakeService.approved, contains('u-9'));
  expect(find.text('Pow Fan'), findsNothing);
});

testWidgets('an empty list says so rather than showing nothing',
    (tester) async {
  fakeService.requests = [];
  await tester.pumpWidget(_host(const FollowRequestsScreen()));
  await tester.pumpAndSettle();
  expect(find.text('No follow requests'), findsOneWidget);
});
```

- [ ] **Step 2: Run and watch it fail**

```bash
cd frontend && flutter test test/widgets/follow_requests_screen_test.dart
```

Expected: `FollowRequestsScreen` is not defined.

- [ ] **Step 3: Add the three API calls**

In `follow_api.dart`:

```dart
  /// People asking to follow you, newest first.
  Future<List<Map<String, dynamic>>> getRequests({
    int limit = 20,
    int offset = 0,
  }) =>
      _list('/follows/me/requests', limit: limit, offset: offset);

  Future<void> approveRequest(String userId) =>
      _dio.post<void>('/follows/me/requests/$userId/approve');

  Future<void> denyRequest(String userId) =>
      _dio.delete<void>('/follows/me/requests/$userId');
```

and the matching `_run(...)` wrappers in `follow_service.dart`.

- [ ] **Step 4: Write the screen**

Follow `user_profile_screen.dart`'s shape exactly: `SafeArea` wrapping the
content with `StPageHeader(title: 'Follow requests', leading: BackButton())`
inside it. **`StPageHeader` is a plain `Container`, not an `AppBar`** —
passing it as `appBar:` draws it under the notch, which is a bug already
fixed once in this repo.

Each row: name, `@handle`, an `Approve` `FilledButton` and a `Deny`
`OutlinedButton`, both using `context.colors`. Remove the row optimistically
on tap and restore it with a `SnackBar` on failure, the same pattern
`FollowButton` uses. Reuse `ProfilePlaceholderBlock` for the empty state.

Export a top-level `openFollowRequests(BuildContext context)` beside the
screen, mirroring `openUserProfile`.

- [ ] **Step 5: Add the badge**

In `profile_header.dart`, on your own profile only, when
`countRequests > 0`, render a tappable pill showing the count that calls
`openFollowRequests`. Take the count from the length of the first page of
`getRequests` — a dedicated count endpoint is not worth a round trip for a
number that is almost always 0.

```dart
// ponytail: the badge counts the first page, so it stops at 20. Add a count
// endpoint if anybody ever has more pending requests than that.
```

- [ ] **Step 6: Run analyze and the tests**

```bash
cd frontend && dart analyze lib test && flutter test
```

- [ ] **Step 7: Commit**

```bash
cd /Users/matthewng/Desktop/Snowtrak
git add frontend/lib/screens/profile/follow_requests_screen.dart \
        frontend/lib/services/ frontend/lib/widgets/profile_header.dart \
        frontend/test/
git commit -m "feat(follows): add the follow requests screen

This is the whole notification surface. device_tokens exists as a table and
no backend code has ever read it; sending push is a subsystem, not a field,
and it is not what this change is for.

The badge counts the first page and stops at 20, which is marked. A count
endpoint is a round trip for a number that is almost always zero."
```

---

## Task 12: Documentation and the changelog

**Files:**
- Modify: `docs/service-ownership.md`
- Modify: `docs/superpowers/specs/2026-08-26-follower-mechanism-design.md`
- Modify: `packages/shared/openapi/*.json`
- Modify: `CHANGELOG.md`

**Interfaces:** none.

- [ ] **Step 1: Record the cross-service read in service-ownership.md**

Add under the follows section:

```markdown
### activity-backend reads `follows` (2026-08-27)

community-backend owns the follow graph and is the only service that
writes it. activity-backend reads it directly, through
`backend/shared/follow_graph.py`, to build the visibility filter for the
activity list.

An HTTP hop would put two more round trips — roughly 880ms — in front of
every activity list, for one indexed read of a two-column table whose shape
is settled. The read is allowed; a write from activity-backend is not.
```

- [ ] **Step 2: Mark the old spec superseded**

At the top of `2026-08-26-follower-mechanism-design.md`:

```markdown
> **Superseded in part.** The "accounts are public; following is instant"
> decision was reversed on 2026-08-27. See
> [2026-08-27-account-privacy-design.md](2026-08-27-account-privacy-design.md).
> Everything else in this document still stands.
```

- [ ] **Step 3: Regenerate the OpenAPI documents**

```bash
cd /Users/matthewng/Desktop/Snowtrak
PYTHON="$PWD/.venv/bin/python" bash backend/scripts/export_openapi.sh
```

- [ ] **Step 4: Run every check, one last time**

```bash
cd backend && ../.venv/bin/ruff check . && ../.venv/bin/ruff format --check .
(cd community-backend && ../../.venv/bin/pytest -q)
(cd activity-backend  && ../../.venv/bin/pytest -q)
(cd main-backend      && ../../.venv/bin/pytest -q)
cd ../frontend && dart analyze lib test && flutter test
```

Report every failure in the summary, including the pre-existing
`home preview` golden. A green claim on an unrun check is worse than a red
one.

- [ ] **Step 5: Write the changelog entries**

Per `docs/changelog_style.md`: a new release heading, four groups in the
order `Changed`, `Added`, `Removed`, `Fixed`, imperative mood, one line
each, **every line ending in a link to a real commit hash** — which means
this step happens after the commits exist, and the hashes come from
`git log --oneline`.

The lines, with hashes to be filled from the log:

```markdown
## [0.0.4] - 2026-08-27

_Following a private account is now a request. Existing followers are kept
when an account turns private; use "remove a follower" to drop them._

### Changed

- **Breaking:** answer `POST /api/v1/follows/{id}` with the state it reached, `following` or `requested`, instead of 204
- Require approval before somebody can follow a private account
- Filter the activity list, its detail route, and its comments by who is allowed to see them
- Show a private account's follower and following lists only to its approved followers
- Order the activity list explicitly, as a paginated read of a growing table should be
- Default a new activity's visibility to private in the database, matching what the application already writes

### Added

- Turn follower approval on and off from Settings → Privacy
- Approve or deny follow requests from a screen reached off your profile
- Add a Requested state to the follow button, which withdraws when tapped
- Report `is_private` and `has_requested` from `/follows/{id}/stats`, so one call still fills the profile header

### Removed

- Drop `activities.is_public`, a column no write path ever updated

### Fixed

- Stop `GET /api/v1/activities/` returning every private activity in the database to unauthenticated callers
- Stop an activity's comments, kudos and shares being reachable without being able to see the activity
- Move the follower and following list reads off the event loop

[0.0.4]: https://github.com/Syntraksoftware/Snowtrak/releases/tag/v0.0.4
```

- [ ] **Step 6: Commit**

```bash
cd /Users/matthewng/Desktop/Snowtrak
git add docs/ packages/shared/openapi/ CHANGELOG.md
git commit -m "docs: record private accounts and the activity visibility fix"
```

---

## Self-review notes

Checked against the spec, section by section:

- Two independent axes — Task 1 (`015`), Task 4, Task 6. Both directions are
  asserted in Task 3, Step 2:
  `test_a_pending_requester_cannot_read_followers_tier_posts` for the gate,
  and `test_a_private_accounts_public_post_stays_public` for the
  independence — the one that catches somebody later "fixing" the model into
  Instagram's ceiling.
- Private account gates two things — Task 4 (approval), Task 5 (lists).
- Pending in its own table — Task 1 (`014`), Task 3.
- Turning private keeps followers — `test_turning_private_keeps_existing_followers`
  in Task 3, and said out loud in Task 10's subtitle copy.
- `is_private` on `user_info` — Task 1 (`015`), Task 6.
- Four migrations — Task 1.
- Shared predicate — Task 2.
- Posts unchanged — verified by Task 2, Step 7 passing with no edits to the
  five read paths.
- Activities all of it — Tasks 7 and 8.
- Follower lists — Task 5.
- New API surface — Tasks 4, 5, 6.
- Cache window — Task 6's `ponytail:` comment and Task 4's docstring.
- Frontend, four items — Tasks 9, 10, 11.
- Testing list — distributed across Tasks 3, 5, 7, 8, 9, 10, 11.
- Deploy order — Task 1 runs the migrations; steps 6 and 7 of the spec's
  deploy order are the user's to run, not this plan's.
- Out of scope — no task touches feed ranking, push, blocking, the composer
  picker, or request rate limiting.
