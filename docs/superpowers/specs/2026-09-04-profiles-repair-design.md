# Profiles Repair and Username Identity Design

Status: approved, not yet implemented.
Date: 2026-09-04.
Issue: [#43](https://github.com/Syntraksoftware/Snowtrak/issues/43).

## Summary

`profiles` can be written again, and a user's chosen username becomes the
name everyone sees.

Two problems that look separate share a cause. `profiles` is unwritable, so
profile edits fail and avatars are lost. And a username, once it can be
saved, would still not appear anywhere, because every feed reads
`user_info`. Fixing the first without the second ships a setting that
visibly does nothing.

## The starting position

Confirmed against the live database on 2026-09-04, by inserting a real
`user_info` id into `profiles`:

```text
insert or update on table "profiles" violates foreign key constraint
"profiles_id_fkey"
Key (id)=(1b85344b-...) is not present in table "users".
```

`profiles.id` references Supabase auth's `users`. Registration writes
`user_info`. So `create_profile` fails with 23503 every time and the table
has never held a row:

```text
user_info    41 rows
profiles      0 rows
```

`main-backend` already works around this on the read path, rendering a
profile from `user_info` in `_profile_from_user_info`. Only writes are
broken — and they are broken for everyone.

## Who reads what today

This is the fact that shapes the design.

| Table | Read by |
|---|---|
| `profiles` | one file, `main-backend/app/core/supabase/profiles.py`, four call sites, all serving the profile screen |
| `user_info` | ten files across all three services — every feed, author line, leaderboard row and duel card |

Every displayed name in the app already comes from `user_info`. Repairing
`profiles` as it stands would put `full_name` back in play and create a
second source for the same fact, which drifts silently: the profile screen
would show one name and the feed another.

## Decisions

**One rule decides where a column lives.**

> `user_info` holds what other services read. `profiles` holds what only the
> profile screen reads.

`is_private` and `country_code` already follow it. Applying it:

| Column | Lives in | Why |
|---|---|---|
| `first_name`, `last_name` | `user_info` | feeds, leaderboards and duels read them |
| `username` | **moves to `user_info`** | it becomes the displayed identity, and it is what an `@mention` resolves to |
| `bio`, `avatar_url`, `ski_level`, `home` | `profiles` | only the profile screen reads them |
| `full_name` | **dropped** | derived from `first_name` and `last_name`; storing it is the second source |

**A chosen username is the identity, everywhere.** If a user sets
`snowking`, every surface shows `@snowking` — feed, thread, reply mention,
leaderboard row, duel card. The real name stays on their own settings
screen. This is also the privacy-safer reading: somebody who picks a handle
does not leak their real name anywhere.

**One display ladder, in one place.**

```text
@username        when the user has set one
First Last       when they have not
email handle     when they have neither
Skier            when the author is gone entirely
```

The `@` appears only on the first rung. A user with no username shows
`Matthew Ng`, not `@Matthew Ng`.

**Usernames are not generated.** The backfill writes ids and nothing else,
leaving `username` null for all 41 users. Deriving handles from email
addresses would mint a handle nobody chose, collide across domains, and leak
real names into a field whose purpose is to hide them. The ladder already
handles null.

**`profiles.id` is re-pointed rather than the table being dissolved.** The
alternative — folding all six columns into `user_info` and dropping
`profiles` — ends with one table and no ambiguity, but moves five columns
that nothing outside the profile screen wants and rewrites the profile
route. Re-pointing keeps the split, and the split is defensible once the
rule above decides it: `user_info` is identity, `profiles` is presentation.

## Migration 022

```sql
-- profiles.id references Supabase auth's users; registration writes
-- user_info. Re-point it at the table that actually holds the rows.
alter table profiles drop constraint profiles_id_fkey;
alter table profiles add constraint profiles_id_fkey
  foreign key (id) references user_info(id) on delete cascade;

-- One profile per existing user. Ids only: see "Usernames are not
-- generated" above.
insert into profiles (id)
select id from user_info
on conflict (id) do nothing;

-- The second source for a name, removed before it can be written to.
alter table profiles drop column full_name;

-- The displayed identity moves to where every service already reads.
alter table user_info add column if not exists username text;
create unique index if not exists user_info_username_key
  on user_info (lower(username)) where username is not null;
alter table profiles drop column username;
```

The unique index is on `lower(username)` so `SnowKing` and `snowking` cannot
both exist, and partial so the 41 null usernames do not collide with each
other.

**Numbering.** The account deletion plan
(`docs/superpowers/plans/2026-09-04-account-deletion.md`) also claims 022.
That change lands second, so its migration becomes **023**, and it gains one
line: `profiles` now holds rows and must cascade with its user, which the
re-pointed foreign key above already does.

## Backend

**Reads.** Every place that selects a name adds `username` to its select and
resolves the ladder. The selects are already in one place per service:

- `community-backend`: the embedded `user_info!<fk>(email, first_name,
  last_name)` selects in `community_post_read_operations.py` and
  `community_comment_read_operations.py`
- `activity-backend`: `_USER_COLUMNS` in `leaderboard_operations.py` and the
  select in `DuelOperations.players`
- `main-backend`: `posts.py` and `comments.py`

**The ladder is resolved twice, once per language, and that is deliberate.**
The two halves of the app already split this way and unifying them would be
a bigger change than this one:

- **Server-side**, for surfaces that already send a finished name:
  `leaderboard_operations.display_fields` and `DuelOperations.players`. The
  ladder becomes one function in `backend/shared/`, since both call it and a
  second copy would drift.
- **Client-side**, for the community feed, which sends raw author fields
  (`author_first_name`, `author_last_name`, `author_email`) and resolves them
  in `CommunityAuthorMapper.authorDisplayName`. It gains `author_username`
  alongside the others. Changing that payload to send a finished name instead
  is a two-sided break for every post, comment and quote, and it is not what
  this change is about.

Two implementations of one rule is a real cost, so both are tested against
the same four cases, and the rule is stated once — here — rather than in
either of them.

**Writes.** `update_profile` stops accepting `full_name` and `username`.
Username moves to its own route, `PUT /api/v1/users/me/username`, next to
`/me/privacy` and `/me/country` — the two settings that already live on
`user_info`. It returns 409 on a taken handle, and `username_exists` moves
to query `user_info`.

**Validation.** A username is 3 to 20 characters, `[a-z0-9_]` after
lower-casing, and is stored lower-cased. Rejecting mixed case at the edge
rather than preserving it keeps the mention parser simple: `@snowking` has
exactly one spelling.

## Frontend

`CommunityAuthorMapper.authorDisplayName` gains the top rung and keeps the
rest. Every community author name already resolves through it.

`usernameFromEmailOrId` is deleted. It invents a handle from an email or a
uuid, which is the behaviour this change exists to remove; `PostAuthor.
username` comes from the API or is empty.

`thread_detail_screen.dart:62` builds a reply mention as
`'@${target.author.username} '`. With a real username that becomes correct;
with none it must not produce `@user`, so the reply prefills with no mention
rather than a wrong one.

The Edit Profile screen keeps its username field and points it at the new
route, showing the 409 as "That username is taken".

Avatars: repairing `profiles` makes `upload_avatar` persist its URL, so the
profile screen shows a real avatar for the first time. The feed still shows
initials — the community API does not return an avatar at all, and adding
one is a separate change, not a consequence of this one.

## Testing

Backend:

- The shared ladder: username wins; then first and last name; then the email
  handle; then the placeholder. A null username does not render `@`.
- `PUT /me/username` returns 409 for a handle taken by another user,
  case-insensitively, and 200 when the same user re-submits their own.
- Rejected shapes: two characters, twenty-one characters, a space, a dot.
- A profile update no longer accepts `full_name` and does not silently drop
  it — the field is gone from the schema, so an unknown key is ignored by
  Pydantic as it is everywhere else.

Frontend:

- `authorDisplayName` with a username returns `@snowking`; with a name and
  no username returns `Matthew Ng` with no `@`.
- A reply to an author with no username prefills empty rather than `@user`.

Verification against the running stack, which the stubbed suites cannot
reach: set a username, then read a post by that user from the community feed
and confirm the author line changed.

## Out of scope

- Avatars in the feed. The community API returns none today.
- `profiles.push_token`, which duplicates the `device_tokens` table and is
  read by nothing. Removing it belongs with the push work in #41.
- Backfilling or suggesting usernames for the 41 existing users.
- Any change to how `first_name` and `last_name` are collected.
