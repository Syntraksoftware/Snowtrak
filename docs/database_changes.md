# Changing the database

Read this before you write a migration, add a column, or change what a model
reads. It is short, and the rule at the end of it is the reason the deploy
workflow can roll itself back.

## Where the tables actually live

Three mechanisms, and only one of them is under version control. Knowing which
one owns a table is the first question for any change.

| Owner | What it covers | How a change is applied |
|---|---|---|
| **Alembic** — `backend/db/migrations/versions/` | PostGIS only: `map_cache_entries`, `elevation_samples`, and everything in the `map_trail` schema | `alembic upgrade head` from `backend/`, by hand |
| **Supabase dashboard** — nothing in this repo | Every application table: `profiles`, `user_info`, `user_stats`, `activities`, `posts`, `comments` and eleven more — full list in [database_schema.md](database_schema.md) | Typed into the Supabase SQL editor, by hand |
| **Loose SQL** — `backend/db/migrations/004_activities_thumbnail_url.sql` | One column on `activities` | Pasted into the Supabase SQL editor, by hand |

Two things follow from that table, and both are worth saying plainly.

**The seventeen tables the app is built on are not defined anywhere in this
repo.** They were created by hand in the Supabase dashboard, so nothing here can
recreate them and no test asserts their shape.
[database_schema.md](database_schema.md) records what they currently look like,
but it is a record rather than a script: a second environment still cannot be
stood up from this repository alone.

**`004_activities_thumbnail_url.sql` is not an Alembic revision.** The number
makes it look like it follows `003`, but it is not in the chain, Alembic has
never heard of it, and nothing records whether a given database has run it. It
is a note-to-self that happens to be valid SQL.

Neither of these is fixed by this document. They are the context for the rule
below, which holds regardless.

## The rule

> At every moment, the database must work with **both** the code that is
> deployed **and** the code you could roll back to.

The deploy workflow puts the previous image digests back when a rollout fails
its health check. That restores *code*. It does not restore the database —
nothing does, because migrations are applied by hand and are not reverted. So a
rollback runs yesterday's code against today's schema, and that only works if
you planned for it.

Two consequences, in opposite directions:

| Change | Order | Why |
|---|---|---|
| **Adding** a column or table | Database first, code after | Old code ignores a column it does not know about |
| **Removing** a column or table | Code first, database after | The column can only go once nothing reads it |

**Never both in the same release.**

## Removing something, step by step

Dropping `photo_url` from `activities`:

**v1.2.0 — where you start.** Code reads and writes `photo_url`. The column
exists.

**v1.3.0 — the compatible release.** Code stops touching `photo_url`
completely: not read, not written, removed from every model and query. The
column *stays in the database*, unused. Roll back to v1.2.0 from here and it
still works, because the column is still there.

**v1.4.0 — the drop.** Now run `ALTER TABLE activities DROP COLUMN photo_url`.
The code needs no change; it stopped caring a release ago. Roll back to v1.3.0
from here and it still works, because v1.3.0 never touched the column.

Deploy v1.3.0 and leave it alone long enough to trust it. The gap is the whole
point — shrink it to an afternoon and you have written the same bug slowly.

## What this costs you: the rollback horizon

Once v1.4.0 drops the column, **v1.2.0 is gone as a rollback target forever**.
Its code selects a column that no longer exists.

```
v1.2.0   ← unreachable after the drop
v1.3.0   ← the furthest back you can go
v1.4.0   ← current
```

In practice you can roll back one release. Plan releases knowing that.

## Renaming

There is no rename. A rename is an add and a remove, so it is both sequences
end to end: add the new column, write both, read the new one, stop writing the
old one, then drop it. That is three releases, not one.

`004_activities_thumbnail_url.sql` is the additive half of exactly this: it
added `thumbnail_url` to `activities`. No older column sits beside it, so
nothing is waiting to be dropped.

## Practical notes

- **Alembic changes** go in `backend/db/migrations/versions/`, chained off the
  current head. `SYNTRAK_DATABASE_URL` must point at Supabase in the
  `postgresql+psycopg://` form; see `backend/db/migrations/README.md`.
- **Supabase changes**: write the SQL into a file next to
  `004_activities_thumbnail_url.sql`, numbered, committed in the same PR as the
  code that needs it, before you paste it into the dashboard. It is not
  automation, but it means the change is reviewable and the next person can see
  what was run. Afterwards run `python scripts/dump_supabase_schema.py` and
  commit the refreshed [database_schema.md](database_schema.md), so the record
  in git matches the database again.
- **Always `IF NOT EXISTS` / `IF EXISTS`.** Applying by hand means applying
  twice eventually.
- **Additive columns must be nullable or have a default.** A `NOT NULL` column
  with no default breaks every insert from the code that is still running.
- **Migrations run before the deploy, not during it.** Apply the schema change,
  confirm it, then run the deploy workflow. Nothing enforces this ordering yet.
