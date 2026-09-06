# Following, and what a follow unlocks

> **Superseded in part.** The "accounts are public; following is instant"
> decision was reversed on 2026-08-27. See
> [2026-08-27-account-privacy-design.md](2026-08-27-account-privacy-design.md).
> Everything else in this document still stands.

Design for the follow graph and post visibility. Branch `feat/follower-mechansim`.

## The problem

Every post in the app is visible to everyone. There is no way to say "this one
is for the people who follow me", and no way to follow anyone in the first
place. Two consequences:

- The feed cannot be made relevant. `list_recent_posts` orders every post in
  the database by `created_at` and stops at the limit. Nothing tells it which
  posts are worth showing you.
- There is no reason to look at another person twice. `UserProfileScreen`
  already renders someone else's profile and posts — `ProfileHeader` takes a
  `userId` and `getPostsByUserId` is wired — but nothing in the app navigates
  to it. It is reachable only from itself.

A follow graph fixes both: it is the relevance signal the feed is missing, and
it is the reason a profile is worth opening.

## Decisions

### Accounts are public; following is instant

No private accounts, no follow requests, no approval queue.

This is two axes that get confused with each other:

| Axis | Question | Our answer |
|---|---|---|
| Account | who is allowed to follow me? | anyone, instantly |
| Post | who can see this post? | author picks, per post |

Instagram's centre of gravity is the first axis; Strava's is the second. We
take Strava's.

The honest consequence, stated plainly: with no approval on the first axis,
"followers only" on the second means "anyone who bothered to tap Follow". It
keeps a post out of the public feed. It is not confidentiality. That is an
acceptable trade for ski runs and stats, and it would not be for a private
photo album.

Three reasons to skip approval now rather than "later, when we get to it":

1. The content is runs, routes and numbers. The privacy stakes are not
   Instagram's.
2. The graph is nearly empty. Approval friction on an empty graph kills the
   loop it is meant to protect — follow, see something, post something.
3. **It is cheap to add later.** A `status` column on `follows` defaulting to
   `accepted`, and an `is_private` flag on `profiles`. Both are one additive
   `ALTER` with existing rows already correct. Nothing here forecloses it.

Point 3 is why skipping is safe. Not point 1.

### Removing a follower ships day one

Open following only stays tolerable if you can undo someone else's follow.
"Remove this follower" is the same row delete as unfollow with the pair
reversed, so it costs one endpoint and one menu item, and it is the answer to
"someone I don't want is reading my followers-only posts".

Blocking is not in scope. That is a moderation feature; build it when there is
a moderation problem.

### Three visibility tiers, matching activities

`public` | `followers` | `private`.

`backend/activity-backend/models.py:38` already declares exactly these three
words for an activity. It only ever *writes* `public` or `private` — the route
maps a boolean `is_public`, and the read check at
`activities_management_routes.py:125` is `visibility == "public" or owner` —
so the `followers` tier is declared and never honoured. Posts using the same
three words means the app has one privacy vocabulary instead of two, and it
leaves activities' `followers` tier ready to be wired up in its own change.

`private` costs one `user_id = me` comparison. Taking it makes the set
complete; leaving it out invites "why can my run be just-for-me but not my
post?".

## Data model

Both tables live in Supabase and are applied by hand. Per
`docs/database_changes.md`, the SQL goes in
`backend/db/migrations/010_follows_and_post_visibility.sql`, committed in the
same PR as the code, pasted into the dashboard **before** the deploy, with
`scripts/dump_supabase_schema.py` re-run afterwards.

```sql
create table if not exists follows (
  follower_id uuid not null references user_info(id) on delete cascade,
  followee_id uuid not null references user_info(id) on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (follower_id, followee_id),
  constraint follows_no_self check (follower_id <> followee_id)
);

create index if not exists follows_followee_idx on follows (followee_id);

alter table follows enable row level security;

alter table posts
  add column if not exists visibility text not null default 'public';

alter table posts
  add constraint posts_visibility_check
  check (visibility in ('public', 'followers', 'private'));
```

Notes on the shape:

- The composite primary key is the uniqueness constraint and the "who do I
  follow" index in one. `follows_followee_idx` covers the other direction,
  "who follows me".
- `on delete cascade` on both sides: a deleted user takes their edges with
  them. This is what `post_likes` does, and it is why `post_likes` never
  accumulated orphan rows the way `post_votes` did (see migration 008).
- **No `follower_count` / `following_count` columns.** `posts.like_count`
  exists and is already stale relative to `post_likes`; a denormalised count
  is a second source of truth that has to be maintained on every write. At
  this scale `count(*)` is correct and free. Add the columns when a count
  query shows up in a slow log, not before.
- RLS on with no policies, matching migration 006: service_role bypasses it,
  everything else is denied by default.
- `visibility` defaults to `'public'`, so every existing post keeps its
  current behaviour and code that predates this release is unaffected — the
  additive-change rule from `docs/database_changes.md`.

## Service ownership

`docs/service-ownership.md` says a domain is exposed by exactly one service,
and `/api/v1/users` belongs to main-backend. So follow endpoints do **not** go
under `/api/v1/users`.

Instead, **`/api/v1/follows` is a new domain owned by community-backend**, and
`docs/service-ownership.md` is updated in this change to record that.

The reason it is community-backend and not main-backend: the only consumer
that cannot tolerate a network hop is the feed visibility filter, which runs
inside community-backend on every feed request. main-backend has no reader for
this data. Putting the table's owner next to its hot reader is the whole
argument.

## Backend API

New: `community-backend/services/follow_operations.py` and
`community-backend/routes/follows_routes.py`, mounted at `/api/v1/follows`.

| Method | Path | Behaviour |
|---|---|---|
| POST | `/api/v1/follows/{user_id}` | Follow. `204`. Idempotent (`on conflict do nothing`). `400` on self-follow, `404` if the user does not exist. |
| DELETE | `/api/v1/follows/{user_id}` | Unfollow. `204`. Idempotent — unfollowing someone you don't follow succeeds. |
| DELETE | `/api/v1/follows/me/followers/{user_id}` | Remove a follower. `204`. Deletes the reversed pair. Idempotent. |
| GET | `/api/v1/follows/{user_id}/followers` | `ListResponse`, `limit`/`offset`, via `build_paginated_list_response`. |
| GET | `/api/v1/follows/{user_id}/following` | Same. |
| GET | `/api/v1/follows/{user_id}/stats` | `{follower_count, following_count, is_following, is_followed_by}` — one call for a profile header. |

All writes require auth. Reads use `get_optional_user` so an anonymous viewer
gets counts with `is_following: false`.

**Route ordering matters.** `/me/followers/{user_id}` must be registered
before `/{user_id}`. `posts_read_routes.py` carries a comment about being
bitten by exactly this against `/{post_id}`.

The list rows join `user_info` for name and email the same way
`list_recent_posts` does, so the client can render a row without an N+1.

## Visibility enforcement

This is the part that has to be right, and it is bigger than the feed.

The predicate, for a viewer `me`:

```
visibility = 'public'
OR user_id = me
OR (visibility = 'followers' AND user_id IN <people me follows>)
```

Anonymous viewers collapse to `visibility = 'public'`.

In PostgREST terms that is one `.or_()` with a nested `and(...)`. Build the
third clause only when the following list is non-empty — `in.()` with no
values is not valid syntax.

**Every read path that can return a post must apply it**, not just the feed. A
filter on the feed alone leaks through four other doors:

| Path | Leak if unfiltered |
|---|---|
| `list_recent_posts` | the feed itself |
| `get_post_by_id` | a shared link or deep link opens any post |
| `list_posts_by_user_id` | a profile page shows a stranger's followers-only posts |
| `_hydrate_quoted_posts` / `_hydrate_quoted_comments` | a public post quoting a private one leaks the preview text |
| `list_comments_by_post_ids` (`POST /comments/batch`) | takes arbitrary post ids; must reduce to visible posts first |

The quoted-post one is the easiest to miss and the most embarrassing, because
the leak is authored by someone other than the owner.

`count_all_posts` takes the same predicate so pagination totals match what the
viewer can actually see.

Reachability of the following-id list is bounded:

```python
# ponytail: following ids are pulled into an in-list, capped at 1000.
# Past that, move the predicate into a Postgres view or RPC and let the
# database do the join.
```

**Caching needs no change.** `feed_cache_key` already includes
`current_user_id`, so a personalised feed is already keyed per viewer, and
`CACHE_FEED_TTL_SECONDS` is 15. A follow is visible in the feed within 15
seconds. Invalidating on follow is not worth its own bug.

`create_post` gains a `visibility` parameter defaulting to `'public'`;
`CommunityPostResponse` gains a `visibility` field so the client can badge a
non-public post.

## Frontend

Smaller than it looks, because the profile screen already exists.

**Already built, just unreachable:** `lib/screens/profile/user_profile_screen.dart`
takes a `userId`, `ProfileHeader` takes a `userId`, and `MessageCard` already
exposes an `onAvatarTap` hook. `UserProfileScreen` is the only thing in the
app that passes it. Wiring the feed's avatar tap is a two-line change and it
is what makes the whole feature discoverable.

Work items:

1. `lib/services/apis/follow_api.dart` + `lib/services/follow_service.dart`,
   following the `AppResult` shape of `community_service.dart`. Registered in
   `lib/core/di/service_locator.dart`.
2. `ProfileHeader` gains a follower/following count row and, when
   `userId != me`, a Follow / Following button. Optimistic toggle: flip
   immediately, revert on failure. The counts come from one `/stats` call.
3. Wire `onAvatarTap` in `threads_tab.dart` (and `thread_detail_screen.dart`)
   to push `UserProfileScreen(userId: post.author.id)`.
4. `lib/screens/profile/follow_list_screen.dart` — one screen, a `mode` for
   followers vs following, reached by tapping either count. Rows carry their
   own Follow button. On your own followers list, each row gets a "Remove"
   action.
5. Composer (`composer_widget.dart` / `new_thread_draft_screen.dart`) gains a
   visibility picker: Public / Followers / Only me, defaulting to Public.
6. `MessageCard` shows a small badge when `visibility != 'public'`, so an
   author can see at a glance where a post went.
7. `profile_screen.dart` (your own) shows the same counts, same endpoint.

## Testing

Backend, in `community-backend/tests/`:

- Following twice is idempotent and leaves one row.
- Self-follow is rejected with `400`.
- Unfollowing a follow that does not exist succeeds.
- Removing a follower deletes only the reversed pair.
- **Anonymous viewer never receives a `followers` or `private` post** — from
  the feed, from `get_post_by_id`, from `list_posts_by_user_id`, and as a
  quoted-post preview.
- **A follower receives `followers` posts; a non-follower does not**, across
  those same four paths.
- `private` posts are returned to their author and nobody else.
- `POST /comments/batch` with a post id the viewer cannot see returns no
  comments for it.
- Unfollowing removes the posts from the next feed read.

Frontend:

- Follow button optimistic toggle, and rollback on a failed request.
- Composer defaults to Public and round-trips the selected visibility.

## Deploy order

Per `docs/database_changes.md`, this is an additive change: **database first,
code after**, never both in one release.

1. Paste `010_follows_and_post_visibility.sql` into the Supabase SQL editor
   and confirm it. Old code ignores `follows` and ignores `posts.visibility`,
   so this is safe on its own.
2. Run `python scripts/dump_supabase_schema.py`, commit the refreshed
   `docs/database_schema.md`.
3. Deploy the code.
4. Refresh the OpenAPI snapshot: `backend/scripts/export_openapi.sh`.

Rolling back to the previous image after step 3 is safe: the previous code
never reads either object.

## Out of scope

Named so they are decisions rather than oversights:

- **Private accounts and follow requests** — one `ALTER` away, see Decisions.
- **Blocking** — moderation, not social graph.
- **A mutual-only "friends" tier** — a third check on every read and a
  three-way picker, for a tier nobody has asked for yet.
- **Push notifications** — tracked in
  [#41](https://github.com/Syntraksoftware/Snowtrak/issues/41), which carries
  the investigation: FCM is the chosen provider, ~610 lines of sender already
  sit unmerged on `feat/build-notification-service`, and the real obstacle is
  that `frontend/android/` holds two files and does not build. `notifications.py`
  and its `/test/follow` endpoint are gone as of #40; the in-app list is derived
  from pending follow requests instead, which is why `markAsRead` does not
  persist.
- **Follow suggestions / "people you may know"** — needs a graph before it can
  recommend anything.
- **Feed ranking** — this change makes relevance *possible* by capturing the
  signal. The feed stays reverse-chronological. Ranking is the next change,
  and it is the one the graph was built for.
- **Wiring activities' `followers` tier** — now unblocked, but it lives in
  activity-backend and belongs in its own change.
