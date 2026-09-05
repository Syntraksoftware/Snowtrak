# Profiles Repair and Username Identity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** `profiles` can be written again, and a user's chosen username is
the name every surface shows.

**Architecture:** `profiles.id` is re-pointed from Supabase auth's `users` to
`user_info(id)` and backfilled. `username` moves to `user_info`, where every
service already reads, and `full_name` is dropped because it duplicates
`first_name` and `last_name`. One display ladder — username, then name, then
email handle, then placeholder — implemented once in Python for surfaces
that send a finished name and once in Dart for the community feed, which
sends raw fields.

**Tech Stack:** Postgres via Supabase, FastAPI (main-, community-,
activity-backend), Flutter/Dart.

**Spec:** `docs/superpowers/specs/2026-09-04-profiles-repair-design.md`

## Global Constraints

- Python 3.11. `ruff check .` and `ruff format --check .` from `backend/`
  must pass; line length 100, double quotes.
- Backend tests run from the service directory with `PYTHONPATH=.:..`.
  main-backend also needs `-o addopts=""`.
- Dart: single quotes, return types declared. Colours from `context.colors`.
- snake_case on the wire. A response-shape change is a two-sided break.
- No new runtime dependency, Python or pub, without asking.
- Migration 022 is hand-applied in the Supabase SQL editor. Do **not** run
  it; hand it over and wait.
- Never touch `.env`, `postgres.env`, or anything `check_secrets.sh` guards.
- The display ladder, verbatim, and the only place it is stated:

  ```text
  @username      when the user has set one
  First Last     when they have not
  email handle   when they have neither
  Skier          when the author is gone entirely
  ```

  The `@` appears on the first rung only.
- Usernames are stored lower-cased, 3-20 characters, `[a-z0-9_]`.

## File Structure

| File | Responsibility |
|---|---|
| `backend/db/migrations/022_profiles_repair.sql` | Re-point the FK, backfill, move `username`, drop `full_name` |
| `backend/shared/display_name.py` | The ladder, as one pure function |
| `backend/main-backend/app/core/supabase/users.py` | `set_username`, `username_exists` against `user_info` |
| `backend/main-backend/app/api/v1/users_profile_routes.py` | `PUT /me/username` |
| `backend/*/services/*.py` | Carry `username` through every author read |
| `frontend/lib/screens/community/mappers/community_author_mapper.dart` | The ladder in Dart |

---

### Task 1: Migration 022

**Files:**
- Create: `backend/db/migrations/022_profiles_repair.sql`

**Interfaces:**
- Consumes: nothing.
- Produces: `profiles` holds one row per user and cascades with them;
  `user_info.username` exists and is uniquely indexed on `lower(username)`;
  `profiles.full_name` and `profiles.username` are gone.

- [ ] **Step 1: Write the migration**

Create `backend/db/migrations/022_profiles_repair.sql`:

```sql
-- Run this in the Supabase SQL editor after 021.
--
-- profiles.id references Supabase auth's `users`, but registration writes
-- `user_info`, so every insert fails with 23503 and the table has never held
-- a row: 41 users, 0 profiles. Every profile edit returns 500 and every
-- uploaded avatar URL is discarded.
--
-- Repairing it as-is would be worse. profiles is read by one file;
-- user_info is read by ten across three services, and every displayed name
-- already comes from it. Keeping full_name creates a second source for one
-- fact, and the profile screen and the feed would disagree silently.
--
-- One rule decides where a column lives: user_info holds what other services
-- read, profiles holds what only the profile screen reads.
--
-- Design: docs/superpowers/specs/2026-09-04-profiles-repair-design.md

begin;

alter table profiles drop constraint profiles_id_fkey;
alter table profiles add constraint profiles_id_fkey
  foreign key (id) references user_info(id) on delete cascade;

-- One profile per existing user. Ids only: usernames are chosen, never
-- generated. Deriving them from email addresses would mint handles nobody
-- picked, collide across domains, and leak the real names the field exists
-- to hide.
insert into profiles (id)
select id from user_info
on conflict (id) do nothing;

-- The second source for a name, removed before anything can write to it.
alter table profiles drop column full_name;

-- The displayed identity moves to where every service already reads. Unique
-- on lower(username) so SnowKing and snowking cannot both exist, and partial
-- so the null usernames do not collide with each other.
alter table user_info add column if not exists username text;
create unique index if not exists user_info_username_key
  on user_info (lower(username)) where username is not null;

alter table profiles drop column username;

commit;
```

- [ ] **Step 2: Renumber the account deletion migration**

`docs/superpowers/plans/2026-09-04-account-deletion.md`, on branch
`feat/account-deletion`, also claims 022. This change lands first, so that
one becomes **023**. It also gains a line, because `profiles` now holds rows
and has to go with its user — the re-pointed foreign key above already does
that, so the note is only to stop somebody adding a second rule for it.

If that branch is not checked out, do not switch to it. Say so in the
summary and leave it: renumbering a file on another branch from here is how
two people end up editing the same line.

- [ ] **Step 3: Commit**

```bash
git add backend/db/migrations/022_profiles_repair.sql
git commit -m "feat(profiles): re-point profiles at user_info in migration 022"
```

- [ ] **Step 4: Hand it over and stop**

Say: "Migration 022 is ready at
`backend/db/migrations/022_profiles_repair.sql`. Run it in the Supabase SQL
editor, then tell me — nothing after this can be verified until it is
applied."

Do **not** run it. Do not start Task 2 until the user confirms.

- [ ] **Step 5: Verify after the user confirms**

From `backend/activity-backend`:

```bash
PYTHONPATH=.:.. ../../.venv/bin/python - <<'PY'
from config import get_config
from supabase import create_client

c = get_config()
client = create_client(c.SUPABASE_URL, c.SUPABASE_SERVICE_ROLE_KEY)

users = client.table("user_info").select("id", count="exact").limit(1).execute()
profs = client.table("profiles").select("id", count="exact").limit(1).execute()
print("user_info:", users.count, "profiles:", profs.count)

row = client.table("user_info").select("id,username").limit(1).execute().data[0]
print("user_info has username column:", "username" in row)

cols = client.table("profiles").select("*").limit(1).execute().data[0]
print("profiles dropped full_name:", "full_name" not in cols)
print("profiles dropped username:", "username" not in cols)
PY
```

Expected:

```
user_info: 41 profiles: 41
user_info has username column: True
profiles dropped full_name: True
profiles dropped username: True
```

Any mismatch means the migration did not fully apply. Stop and report it.

---

### Task 2: The display ladder, in Python

**Files:**
- Create: `backend/shared/display_name.py`
- Test: `backend/shared/tests/test_display_name.py`
- Modify: `backend/activity-backend/services/leaderboard_operations.py`
  (`display_fields` delegates to it)

**Interfaces:**
- Consumes: nothing.
- Produces: `shared.display_name.display_name(*, username, first_name,
  last_name, email, deleted=False) -> str`, and the constant
  `shared.display_name.UNKNOWN_PLAYER`.

- [ ] **Step 1: Write the failing test**

Create `backend/shared/tests/test_display_name.py`:

```python
"""The display ladder.

One rule, four rungs, and the `@` belongs to the first rung only. This is
the Python half; `CommunityAuthorMapper.authorDisplayName` is the Dart half
and is tested against the same four cases.
"""

from shared.display_name import UNKNOWN_PLAYER, display_name


def test_a_chosen_username_wins_and_carries_the_at_sign():
    assert (
        display_name(
            username="snowking",
            first_name="Matthew",
            last_name="Ng",
            email="matthew@example.com",
        )
        == "@snowking"
    )


def test_without_a_username_the_name_shows_with_no_at_sign():
    # "@Matthew Ng" would be wrong: the @ marks a handle, not a person.
    assert (
        display_name(
            username=None,
            first_name="Matthew",
            last_name="Ng",
            email="matthew@example.com",
        )
        == "Matthew Ng"
    )


def test_with_neither_it_falls_back_to_the_email_handle():
    assert (
        display_name(
            username=None, first_name=None, last_name=None,
            email="skier@example.com",
        )
        == "skier"
    )


def test_a_deleted_author_outranks_everything_it_still_carries():
    # A cached row can still hold the old name. None of it may be shown.
    assert (
        display_name(
            username="snowking",
            first_name="Matthew",
            last_name="Ng",
            email="matthew@example.com",
            deleted=True,
        )
        == UNKNOWN_PLAYER
    )


def test_blank_strings_count_as_absent():
    # Supabase returns "" rather than null for a cleared text field often
    # enough that treating them differently is a bug waiting to happen.
    assert (
        display_name(username="  ", first_name="", last_name="", email="a@b.co")
        == "a"
    )


def test_nothing_at_all_still_returns_something_printable():
    assert (
        display_name(username=None, first_name=None, last_name=None, email=None)
        == UNKNOWN_PLAYER
    )
```

- [ ] **Step 2: Run it to verify it fails**

```bash
cd backend/shared
PYTHONPATH=.:.. ../../.venv/bin/python -m pytest tests/test_display_name.py -q
```

Expected: FAIL — `ModuleNotFoundError: No module named 'shared.display_name'`.
If `backend/shared/tests/` does not exist, create it with an empty
`__init__.py` first.

- [ ] **Step 3: Write the ladder**

Create `backend/shared/display_name.py`:

```python
"""How a person is named on screen.

One rule, stated in
docs/superpowers/specs/2026-09-04-profiles-repair-design.md and implemented
here for every surface that sends a finished name. The community feed sends
raw fields instead and resolves the same rule in Dart; the two are tested
against the same cases.
"""

#: Shown for an author who is gone, or who has nothing to be named by.
UNKNOWN_PLAYER = "Skier"


def display_name(
    *,
    username: str | None,
    first_name: str | None,
    last_name: str | None,
    email: str | None,
    deleted: bool = False,
) -> str:
    """The name to show for one person.

    Args:
        username: The handle they chose, if any.
        first_name: Their given name.
        last_name: Their family name.
        email: Their address, used only for its handle.
        deleted: Whether the account is gone. Outranks everything else --
            a cached row can still carry the old name, and none of it may
            be shown.

    Returns:
        `@handle` when a username is set, their name when it is not, the
        email handle when there is neither, and `UNKNOWN_PLAYER` when there
        is nothing at all. The `@` marks a handle and never a person, so it
        appears on the first rung only.
    """
    if deleted:
        return UNKNOWN_PLAYER

    handle = (username or "").strip()
    if handle:
        return f"@{handle}"

    first = (first_name or "").strip()
    last = (last_name or "").strip()
    full = " ".join(part for part in (first, last) if part)
    if full:
        return full

    address = (email or "").strip()
    if "@" in address:
        return address.split("@")[0]

    return UNKNOWN_PLAYER
```

- [ ] **Step 4: Run it to verify it passes**

```bash
cd backend/shared
PYTHONPATH=.:.. ../../.venv/bin/python -m pytest tests/test_display_name.py -q
```

Expected: 6 passed.

- [ ] **Step 5: Delegate the leaderboard's copy to it**

In `backend/activity-backend/services/leaderboard_operations.py`, replace the
body of `display_fields` and drop the local `UNKNOWN_PLAYER`:

```python
from shared.display_name import UNKNOWN_PLAYER, display_name
```

```python
def display_fields(user: dict[str, Any]) -> dict[str, Any]:
    """The public half of a user, for a board row or a duel card.

    A board shows a name and a country. It never shows an activity, which is
    what lets a private activity count towards a total without leaking
    anything about itself.

    ponytail: avatar_url is always null. Uploaded avatars are written to
    `profiles.avatar_url`, and until migration 022 that row never existed --
    issue #43. Fill it in when the community payload carries an avatar; do
    not invent a second place to keep it.
    """
    username = (user.get("username") or "").strip() or None
    return {
        "display_name": display_name(
            username=username,
            first_name=user.get("first_name"),
            last_name=user.get("last_name"),
            email=user.get("email"),
        ),
        "username": username,
        "avatar_url": None,
        "country_code": user.get("country_code"),
    }
```

`display_fields` no longer references `UNKNOWN_PLAYER` directly, so leaving
it imported here would trip ruff's F401. Import only `display_name` in this
file, and point the one other user at the source:

```bash
grep -rn UNKNOWN_PLAYER backend/activity-backend
```

`routes/duel_routes.py` imports it from `services.leaderboard_operations`.
Change that line to `from shared.display_name import UNKNOWN_PLAYER`. A
re-export would work and would also be a second place to look when somebody
asks where the placeholder is defined.

- [ ] **Step 6: Update the two board tests that assert on names**

`backend/activity-backend/tests/test_competition_operations.py` has
`test_a_board_row_names_a_user_from_user_info` and
`test_a_nameless_user_falls_back_to_their_email_handle`. Add a third and
leave the two alone — they still pass, because neither fixture sets a
username:

```python
    def test_a_chosen_username_is_what_the_board_shows(self):
        client = _FakeClient()
        client.rpc_results["leaderboard_top"] = [
            {"rank": 1, "user_id": ALEX, "value": 900.0}
        ]
        client.rows["user_info"] = [
            {
                "id": ALEX,
                "username": "snowking",
                "first_name": "Alpha",
                "last_name": "Tester",
                "email": "alpha@example.com",
            }
        ]

        entry = LeaderboardOperations(client).top(
            Metric.VERTICAL, GLOBAL_SCOPE, NOW
        )[0]

        assert entry["display_name"] == "@snowking"
        assert entry["username"] == "snowking"
```

Add `username` to `_USER_COLUMNS` in `leaderboard_operations.py`:

```python
    _USER_COLUMNS = "id,username,first_name,last_name,email,country_code"
```

And to the select in `DuelOperations.players`:

```python
                .select("id,username,first_name,last_name,email")
```

- [ ] **Step 7: Run both suites**

```bash
cd backend/shared && PYTHONPATH=.:.. ../../.venv/bin/python -m pytest -q
cd ../activity-backend && PYTHONPATH=.:.. ../../.venv/bin/python -m pytest -q
```

Expected: all pass.

- [ ] **Step 8: Commit**

```bash
git add backend/shared/ backend/activity-backend/
git commit -m "feat(shared): put the display ladder in one function"
```

---

### Task 3: `PUT /api/v1/users/me/username`

**Files:**
- Modify: `backend/main-backend/app/core/supabase/users.py`
- Modify: `backend/main-backend/app/core/supabase/profiles.py`
  (`update_profile` drops `full_name` and `username`; delete
  `username_exists` from here)
- Modify: `backend/main-backend/app/api/v1/users_profile_routes.py`
- Modify: `backend/main-backend/app/schemas/__init__.py`
- Test: `backend/main-backend/tests/test_username.py`

**Interfaces:**
- Consumes: Task 1's `user_info.username` column and unique index.
- Produces: `supabase_client.set_username(id, username) -> bool`,
  `supabase_client.username_exists(username, exclude_user_id=None) -> bool`
  reading `user_info`, and `PUT /api/v1/users/me/username` taking
  `{"username": str | null}`.

- [ ] **Step 1: Write the failing tests**

Create `backend/main-backend/tests/test_username.py`:

```python
"""PUT /api/v1/users/me/username.

The username is the identity every surface shows, so it is unique, lower
case, and its own route -- next to /me/privacy and /me/country, the two
other settings that live on user_info.
"""

from fastapi import status


class TestSetUsername:
    def test_sets_a_username(self, client, stub_supabase):
        response = client.put(
            "/api/v1/users/me/username", json={"username": "snowking"}
        )

        assert response.status_code == status.HTTP_200_OK
        assert response.json()["username"] == "snowking"

    def test_stores_it_lower_cased(self, client, stub_supabase):
        # One spelling, so the mention parser has one thing to match.
        response = client.put(
            "/api/v1/users/me/username", json={"username": "SnowKing"}
        )

        assert response.json()["username"] == "snowking"

    def test_a_taken_handle_is_a_conflict(self, client, stub_supabase):
        stub_supabase.taken_usernames.add("snowking")

        response = client.put(
            "/api/v1/users/me/username", json={"username": "snowking"}
        )

        assert response.status_code == status.HTTP_409_CONFLICT

    def test_null_clears_it(self, client, stub_supabase):
        response = client.put("/api/v1/users/me/username", json={"username": None})

        assert response.status_code == status.HTTP_200_OK
        assert response.json()["username"] is None

    def test_rejects_shapes_that_would_break_a_mention(self, client, stub_supabase):
        for bad in ("ab", "a" * 21, "snow king", "snow.king", "snow-king"):
            response = client.put(
                "/api/v1/users/me/username", json={"username": bad}
            )
            assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY, bad
```

Extend `_StubSupabase` in `backend/main-backend/tests/conftest.py`:

```python
        self.taken_usernames: set[str] = set()
```

```python
    def username_exists(self, username: str, exclude_user_id: str | None = None) -> bool:
        return username in self.taken_usernames

    def set_username(self, id: str, username: str | None) -> bool:
        row = self.user_info.get(id)
        if row is None:
            return False
        row["username"] = username
        return True
```

And register both in the `stub_supabase` fixture:

```python
    monkeypatch.setattr(supabase_client, "username_exists", stub.username_exists)
    monkeypatch.setattr(supabase_client, "set_username", stub.set_username)
```

- [ ] **Step 2: Run to verify it fails**

```bash
cd backend/main-backend
PYTHONPATH=.:.. ../../.venv/bin/python -m pytest tests/test_username.py -q -o addopts=""
```

Expected: FAIL — 405, the route does not exist.

- [ ] **Step 3: Add the schema**

In `backend/main-backend/app/schemas/__init__.py`, after `ProfileUpdate`:

```python
class UsernameSetting(BaseModel):
    """The handle this account is known by.

    Lower case only, so `@snowking` has exactly one spelling and the mention
    parser has one thing to match. Null clears it; the display falls back to
    the user's name.
    """

    username: str | None = Field(
        None,
        min_length=3,
        max_length=20,
        pattern=r"^[a-zA-Z0-9_]+$",
    )
```

Then remove `username` and `full_name` from `ProfileUpdate`, leaving
`bio`, `avatar_url`, `push_token`, `ski_level` and `home`. Leave
`ProfileResponse` alone: it still returns `full_name` and `username`, both
now derived from `user_info`, so the Dart `Profile` model does not change.

- [ ] **Step 4: Move the uniqueness check and add the write**

In `backend/main-backend/app/core/supabase/users.py`, after
`set_user_country`:

```python
    def username_exists(self, username: str, exclude_user_id: str | None = None) -> bool:
        """Whether a handle is already taken, case-insensitively.

        Lives here, not on profiles: `username` moved to `user_info` in
        migration 022 because every service reads names from there.

        Args:
            username: The handle to check.
            exclude_user_id: A user to ignore, so re-submitting your own
                handle is not a conflict with yourself.

        Returns:
            True when taken. True on a failed read as well -- refusing a
            free handle is recoverable, handing out a duplicate is not.
        """
        if not self.is_configured():
            return False
        client = self._client
        if client is None:
            return False
        try:
            query = client.table("user_info").select("id").ilike("username", username)
            if exclude_user_id:
                query = query.neq("id", exclude_user_id)
            resp = query.limit(1).execute()
            data = getattr(resp, "data", None)
            return isinstance(data, list) and len(data) > 0
        except Exception as exc:
            logger.exception(f"Error checking username existence: {exc}")
            return True

    def set_username(self, id: str, username: str | None) -> bool:
        """Set or clear the handle this account is known by.

        Args:
            id: The user.
            username: The handle, already lower-cased and validated, or None
                to clear it.

        Returns:
            True when a row was updated.
        """
        if not self.is_configured():
            logger.warning("Supabase not configured; skipping set_username.")
            return False
        client = self._client
        if client is None:
            return False
        try:
            resp = (
                client.table("user_info").update({"username": username}).eq("id", id).execute()
            )
            return bool(getattr(resp, "data", None))
        except Exception as exc:
            logger.exception(f"Failed to set username for user {id}: {exc}")
            return False
```

Then delete `username_exists` from
`backend/main-backend/app/core/supabase/profiles.py`, and remove `full_name`
and `username` from `update_profile`'s signature, its docstring and its
`update_data` block.

- [ ] **Step 5: Add the route**

In `users_profile_routes.py`, after `set_my_country`:

```python
@router.put("/me/username", response_model=UsernameSetting)
def set_my_username(
    setting: UsernameSetting,
    current_user: User = Depends(get_current_user),
) -> UsernameSetting:
    """Choose the handle this account is known by.

    Its own route rather than a field on PUT /me/profile, for the same
    reason /me/privacy and /me/country are: those write `user_info`, and
    that is where a name has to live for a feed to read it.

    Stored lower-cased so `@snowking` has one spelling. Null clears it and
    the display falls back to the user's name.

    Raises:
        HTTPException: 409 if another account already has the handle, 404 if
            the user is gone.
    """
    _ensure_database_configured()

    handle = setting.username.lower() if setting.username else None

    if handle and supabase_client.username_exists(handle, exclude_user_id=current_user.id):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="That username is taken",
        ) from None

    if not supabase_client.set_username(current_user.id, handle):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        ) from None

    invalidate_profile(current_user.id)
    return UsernameSetting(username=handle)
```

Add `UsernameSetting` to the `from app.schemas import ...` line.

Also update `_profile_from_user_info` in the same file so the fallback
profile carries the real handle:

```python
        "username": user.get("username"),
```

replacing the line that derives it from the email.

- [ ] **Step 6: Run to verify it passes**

```bash
cd backend/main-backend
PYTHONPATH=.:.. ../../.venv/bin/python -m pytest tests/test_username.py -q -o addopts=""
```

Expected: 5 passed.

- [ ] **Step 7: Run the whole suite and lint**

```bash
cd backend/main-backend
PYTHONPATH=.:.. ../../.venv/bin/python -m pytest -q -o addopts=""
.venv/bin/ruff check backend/
```

Expected: all pass. If a test asserted on `ProfileUpdate.full_name`, it now
fails; delete that assertion — the field is gone on purpose.

- [ ] **Step 8: Commit**

```bash
git add backend/main-backend/
git commit -m "feat(profiles): move username to user_info behind its own route"
```

---

### Task 4: Carry the username through every author read

**Files:**
- Modify: `backend/community-backend/services/community_post_read_operations.py`
- Modify:
  `backend/community-backend/services/community_comment_read_operations.py`
- Modify: `backend/main-backend/app/core/supabase/posts.py`
- Modify: `backend/main-backend/app/core/supabase/comments.py`
- Modify: `backend/community-backend/services/mappers/community_row_mappers.py`
- Test: `backend/community-backend/tests/test_operations_units.py` (append)

**Interfaces:**
- Consumes: Task 1's `user_info.username`.
- Produces: every post and comment payload carries `author_username`
  alongside `author_email`, `author_first_name` and `author_last_name`.
  Task 5 reads it.

- [ ] **Step 1: Write the failing test**

Append to `backend/community-backend/tests/test_operations_units.py`:

```python
def test_the_author_username_reaches_the_client():
    # The feed resolves the display ladder in Dart, so the handle has to be
    # on the row. Without it a user who set @snowking still shows as their
    # real name in every post.
    from services.mappers.community_row_mappers import flatten_user_info

    row = {
        "post_id": "p1",
        "user_info": {
            "email": "matthew@example.com",
            "first_name": "Matthew",
            "last_name": "Ng",
            "username": "snowking",
        },
    }

    flatten_user_info(row)

    assert row["author_username"] == "snowking"
    assert row["author_first_name"] == "Matthew"
```

- [ ] **Step 2: Run to verify it fails**

```bash
cd backend/community-backend
PYTHONPATH=.:.. ../../.venv/bin/python -m pytest tests/test_operations_units.py -k author_username -q
```

Expected: FAIL — `KeyError: 'author_username'`.

- [ ] **Step 3: Flatten the new field**

In `backend/community-backend/services/mappers/community_row_mappers.py`:

```python
    row["author_email"] = author.get("email")
    row["author_first_name"] = author.get("first_name")
    row["author_last_name"] = author.get("last_name")
    row["author_username"] = author.get("username")
```

- [ ] **Step 4: Add `username` to all fourteen embeds**

There are exactly two distinct strings, eight and six occurrences:

```bash
cd /Users/matthewng/Desktop/Snowtrak
grep -rl 'user_info!posts_user_id_fkey(email, first_name, last_name)' backend --include=*.py \
  | xargs sed -i '' 's/user_info!posts_user_id_fkey(email, first_name, last_name)/user_info!posts_user_id_fkey(email, first_name, last_name, username)/g'
grep -rl 'user_info!comments_user_id_fkey(email, first_name, last_name)' backend --include=*.py \
  | xargs sed -i '' 's/user_info!comments_user_id_fkey(email, first_name, last_name)/user_info!comments_user_id_fkey(email, first_name, last_name, username)/g'
```

Verify the count, which must be 14 and 0:

```bash
grep -rc 'first_name, last_name, username)' backend --include=*.py | grep -v ':0'
grep -rn 'first_name, last_name)' backend --include=*.py | grep user_info
```

The second command must print nothing.

- [ ] **Step 5: Run both suites**

```bash
cd backend/community-backend && PYTHONPATH=.:.. ../../.venv/bin/python -m pytest -q
cd ../main-backend && PYTHONPATH=.:.. ../../.venv/bin/python -m pytest -q -o addopts=""
```

Expected: all pass.

- [ ] **Step 6: Commit**

```bash
git add backend/community-backend/ backend/main-backend/
git commit -m "feat(community): carry the author username to the client"
```

---

### Task 5: The ladder in Dart

**Files:**
- Modify: `frontend/lib/screens/community/mappers/community_author_mapper.dart`
- Modify: `frontend/lib/screens/community/community_post_mapper.dart`
- Modify:
  `frontend/lib/screens/community/mappers/community_comment_tree_mapper.dart`
- Modify: `frontend/lib/screens/community/mappers/community_quote_mapper.dart`
- Modify: `frontend/lib/screens/community/thread_detail_screen.dart:62`
- Modify: `frontend/lib/screens/profile/edit_profile_screen.dart`
- Modify: `frontend/lib/services/apis/users_api.dart`
- Test: `frontend/test/screens/community/community_author_mapper_test.dart`

**Interfaces:**
- Consumes: Task 4's `author_username`, Task 3's `PUT /me/username`.
- Produces: `CommunityAuthorMapper.authorDisplayName({String? username,
  String? firstName, String? lastName, required String fallback}) -> String`.

- [ ] **Step 1: Write the failing tests**

Create `frontend/test/screens/community/community_author_mapper_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:snowtrak/screens/community/mappers/community_author_mapper.dart';

void main() {
  // The same four cases the Python half is tested against. Two
  // implementations of one rule is the cost of the community feed sending
  // raw fields; testing them identically is what keeps them honest.
  test('a chosen username wins and carries the at sign', () {
    expect(
      CommunityAuthorMapper.authorDisplayName(
        username: 'snowking',
        firstName: 'Matthew',
        lastName: 'Ng',
        fallback: 'matthew@example.com',
      ),
      '@snowking',
    );
  });

  test('without a username the name shows with no at sign', () {
    expect(
      CommunityAuthorMapper.authorDisplayName(
        username: null,
        firstName: 'Matthew',
        lastName: 'Ng',
        fallback: 'matthew@example.com',
      ),
      'Matthew Ng',
    );
  });

  test('with neither it falls back to the email handle', () {
    expect(
      CommunityAuthorMapper.authorDisplayName(
        username: null,
        firstName: null,
        lastName: null,
        fallback: 'skier@example.com',
      ),
      'skier',
    );
  });

  test('a blank username counts as absent', () {
    expect(
      CommunityAuthorMapper.authorDisplayName(
        username: '   ',
        firstName: 'Matthew',
        lastName: 'Ng',
        fallback: 'matthew@example.com',
      ),
      'Matthew Ng',
    );
  });
}
```

- [ ] **Step 2: Run to verify it fails**

```bash
cd frontend
/Users/matthewng/Desktop/flutter/bin/flutter test test/screens/community/community_author_mapper_test.dart
```

Expected: FAIL to compile — `username` is not a parameter.

- [ ] **Step 3: Add the top rung**

In `community_author_mapper.dart`, add the parameter and the first branch,
leaving the rest of the function as it is:

```dart
  static String authorDisplayName({
    String? username,
    String? firstName,
    String? lastName,
    required String fallback,
  }) {
    // The @ marks a handle, never a person, so it appears here and nowhere
    // further down the ladder.
    final handle = (username ?? '').trim();
    if (handle.isNotEmpty) {
      return '@$handle';
    }
    final first = (firstName ?? '').trim();
```

- [ ] **Step 4: Run to verify it passes**

```bash
cd frontend
/Users/matthewng/Desktop/flutter/bin/flutter test test/screens/community/community_author_mapper_test.dart
```

Expected: 4 passed.

- [ ] **Step 5: Pass the handle from all four call sites**

Each caller adds one argument. In `community_post_mapper.dart` around line
23:

```dart
    final authorName = authorDisplayName(
      username: rawPost['author_username']?.toString(),
      firstName: rawPost['author_first_name']?.toString(),
      lastName: rawPost['author_last_name']?.toString(),
      fallback: rawPost['author_email']?.toString() ??
          rawPost['user_id']?.toString() ??
          'unknown',
    );
```

In `mappers/community_comment_tree_mapper.dart` around line 53, the same
addition with `comment[...]` in place of `rawPost[...]`. In
`mappers/community_quote_mapper.dart`, both call sites take
`username: m['author_username']?.toString(),`.

Then make `PostAuthor.username` the real handle rather than an invented one.
In `community_post_mapper.dart`:

```dart
      author: PostAuthor(
        id: (rawPost['user_id'] ?? '').toString(),
        displayName: authorName,
        username: (rawPost['author_username'] ?? '').toString(),
      ),
```

- [ ] **Step 6: Delete the invented handle**

`usernameFromEmailOrId` mints a handle from an email or a uuid, which is the
behaviour this change removes. Delete it from
`community_author_mapper.dart` and fix whatever stops compiling. Every
caller either has a real `author_username` now, or should pass an empty
string.

```bash
cd frontend
grep -rn usernameFromEmailOrId lib/ test/
```

Work through that list; the file compiles clean when it is empty.

- [ ] **Step 7: Stop the reply prefill inventing a mention**

`thread_detail_screen.dart:62` builds `'@${target.author.username} '`. With
no handle that produced `@user`. Prefill nothing instead:

```dart
    final handle = target.author.username.trim();
    final mention = handle.isEmpty ? '' : '@$handle ';
```

- [ ] **Step 8: Point the Edit Profile username field at its own route**

`users_api.dart` sends `username` inside the profile update; that field no
longer exists there. Add a method beside it:

```dart
  Future<String?> setUsername(String? username) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/users/me/username',
      data: {'username': username},
    );
    return response.data?['username'] as String?;
  }
```

Remove `username` from the profile-update payload in the same file, and in
`edit_profile_screen.dart` call `setUsername` when that field changed,
showing a 409 as "That username is taken".

- [ ] **Step 9: Run everything**

```bash
cd frontend
/Users/matthewng/Desktop/flutter/bin/flutter test
/Users/matthewng/Desktop/flutter/bin/dart analyze lib/ test/
```

Expected: all pass, "No issues found!". `flutter analyze` exits 64 on this
machine — a pre-existing toolchain fault; use `dart analyze` and say so.

- [ ] **Step 10: Commit**

```bash
git add frontend/
git commit -m "feat(community): show a chosen username everywhere"
```

---

### Task 6: Verify against the running stack, then document

**Files:**
- Modify: `docs/service-ownership.md`
- Modify: `docs/database_schema.md` (regenerate)

**Interfaces:**
- Consumes: Tasks 1-5.
- Produces: nothing code depends on.

- [ ] **Step 1: Set a username and read it back from the feed**

The stubbed suites cannot prove the handle travels from the settings screen
to a post. Start the services (`.venv/bin/python backend/run.py --all`),
then:

```bash
MAIN=http://localhost:8080/api/v1
COM=http://localhost:5001/api/v1
EMAIL="username-probe@example.com"

TOK=$(curl -s -m 15 -X POST "$MAIN/auth/register" -H 'Content-Type: application/json' \
  -d "{\"email\":\"$EMAIL\",\"password\":\"ProbePass123\",\"first_name\":\"Probe\",\"last_name\":\"User\"}" \
  | python3 -c "import sys,json;print(json.load(sys.stdin).get('access_token',''))")

echo "set:      $(curl -s -m 15 -X PUT "$MAIN/users/me/username" \
  -H "Authorization: Bearer $TOK" -H 'Content-Type: application/json' \
  -d '{"username":"SnowKing"}')"

echo "profile:  $(curl -s -m 15 -H "Authorization: Bearer $TOK" "$MAIN/users/me/profile" \
  | python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('username'))")"

echo "taken:    $(curl -s -m 15 -o /dev/null -w '%{http_code}' -X PUT "$MAIN/users/me/username" \
  -H "Authorization: Bearer $TOK" -H 'Content-Type: application/json' \
  -d '{"username":"snowking"}')"
```

Expected:

```
set:      {"username":"snowking"}
profile:  snowking
taken:    200
```

`taken: 409` would mean the uniqueness check does not exclude the caller,
so nobody could ever re-save their own handle. Delete the probe account
afterwards.

- [ ] **Step 2: Record the rule**

In `docs/service-ownership.md`, under the ownership matrix:

```markdown
- display identity: `user_info`. A user's chosen `username` is what every
  surface shows, so it lives beside `is_private` and `country_code` rather
  than in `profiles`. The rule: `user_info` holds what other services read,
  `profiles` holds what only the profile screen reads.
```

- [ ] **Step 3: Regenerate the schema dump**

```bash
cd /Users/matthewng/Desktop/Snowtrak
.venv/bin/python scripts/dump_supabase_schema.py
git diff --stat docs/database_schema.md
```

Expect `user_info.username` added and `profiles.full_name` /
`profiles.username` gone, alongside the 019-021 changes the dump still
predates. Read anything else in that diff before committing.

- [ ] **Step 4: Commit**

```bash
git add docs/
git commit -m "docs(profiles): record where the display identity lives"
```

---

## What this plan deliberately leaves out

Avatars in the feed. Migration 022 makes `upload_avatar` persist its URL, so
the profile screen shows a real avatar for the first time, but the community
API returns no avatar field at all and adding one is its own change.

`profiles.push_token`, which duplicates the `device_tokens` table and is read
by nothing. It belongs with the push work in #41.
