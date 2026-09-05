# Changelog

## [0.0.7] - 2026-09-06

_A merge no longer reaches testers. Ask for a TestFlight build with
`gh workflow run ios-testflight.yml --ref <branch>`, or from Actions -> iOS
Staging. `flutter run --release` on a device stops working; use `--profile`._

### Changed

- **Breaking:** upload to TestFlight only when asked, where every push to `develop` published a build to testers ([#72](https://github.com/Syntraksoftware/Snowtrak/pull/72))
- **Breaking:** sign release builds against a named App Store profile, so a build needs no Apple account and `flutter run --release` no longer installs on a device ([#72](https://github.com/Syntraksoftware/Snowtrak/pull/72))

### Fixed

- Produce a TestFlight build from CI at all — the archive asked Xcode for a provisioning profile, and a runner has no account to ask ([#72](https://github.com/Syntraksoftware/Snowtrak/pull/72))

[0.0.7]: https://github.com/Syntraksoftware/Snowtrak/releases/tag/v0.0.7

## [0.0.6] - 2026-09-05

_Apply `019` through `022` before deploying. Without `022` every author read
fails and follower lists render empty, with no error anywhere. A chosen
username now lives on `user_info`; `profiles.full_name` and
`profiles.username` are gone, and `full_name` is no longer accepted by
`PUT /api/v1/users/me/profile` — send `first_name` and `last_name` to
`PUT /api/v1/users/me` instead._

### Changed

- **Breaking:** stop accepting `full_name` and `username` on `PUT /api/v1/users/me/profile`, which now writes only the fields `profiles` still holds ([`66bd7eb`](https://github.com/Syntraksoftware/Snowtrak/commit/66bd7eb))
- Point `profiles.id` at `user_info` and cascade with it, so a profile row can exist at all ([`0328087`](https://github.com/Syntraksoftware/Snowtrak/commit/0328087))
- Keep a chosen username on `user_info`, unique on `lower(username)`, where every service already reads ([`08b0f0b`](https://github.com/Syntraksoftware/Snowtrak/commit/08b0f0b))
- Resolve a displayed name through one ladder — chosen handle, then real name, then email handle, then a placeholder ([`3a128f1`](https://github.com/Syntraksoftware/Snowtrak/commit/3a128f1))
- Show a chosen username on every community surface, so the name on a post matches the name on its author's profile ([`9bfa994`](https://github.com/Syntraksoftware/Snowtrak/commit/9bfa994))
- Read `full_name`, `username` and `country_code` from `user_info` on every profile response, since those columns no longer live on `profiles` ([`d9dfd98`](https://github.com/Syntraksoftware/Snowtrak/commit/d9dfd98))
- Serve the leaderboard and duels from activity-backend, beside the activities they score ([`f4c9db1`](https://github.com/Syntraksoftware/Snowtrak/commit/f4c9db1))
- Read competitor names and countries from `user_info` rather than from the empty `profiles` table ([`9bbe9ba`](https://github.com/Syntraksoftware/Snowtrak/commit/9bbe9ba))
- Drop the banner callback that the deleted notification poller used to feed ([`061af9b`](https://github.com/Syntraksoftware/Snowtrak/commit/061af9b))

### Added

- Set your username from Edit Profile through `PUT /api/v1/users/me/username`, which answers 409 when somebody else holds it ([`08b0f0b`](https://github.com/Syntraksoftware/Snowtrak/commit/08b0f0b))
- Carry `author_username` on every post and comment, so a client can render a handle without a second read ([`dce94c4`](https://github.com/Syntraksoftware/Snowtrak/commit/dce94c4))
- Add the duel and leaderboard schema, the weekly snapshot, and the rule that inverts pace into speed ([`7824ef1`](https://github.com/Syntraksoftware/Snowtrak/commit/7824ef1))
- Challenge someone who follows you back, and rank against the world, your country or your friends ([`4b27512`](https://github.com/Syntraksoftware/Snowtrak/commit/4b27512))

### Removed

- Delete `usernameFromEmailOrId` and the four hand-rolled fallbacks beside it, which minted an `@handle` from an email address and leaked the real name of anyone who chose a handle to hide it ([`9bfa994`](https://github.com/Syntraksoftware/Snowtrak/commit/9bfa994))
- Drop `profiles.full_name`, a second source for a name the feed already read from `user_info` ([`0328087`](https://github.com/Syntraksoftware/Snowtrak/commit/0328087))

### Fixed

- Write to `profiles` at all — its foreign key pointed at a table registration never populates, so every insert failed with 23503 and the table held no rows for 41 users ([`0328087`](https://github.com/Syntraksoftware/Snowtrak/commit/0328087))
- Create a profile row before an avatar upload writes to it, instead of answering 500 and leaving the uploaded image orphaned in storage ([`c8870f8`](https://github.com/Syntraksoftware/Snowtrak/commit/c8870f8))
- Return the uploader's name from a successful avatar upload, which answered with a null name and blanked it in the client ([`c8870f8`](https://github.com/Syntraksoftware/Snowtrak/commit/c8870f8))
- Match a login address exactly, where `ilike` read `_` and `%` in an email as wildcards and could match an unrelated account ([`66bd7eb`](https://github.com/Syntraksoftware/Snowtrak/commit/66bd7eb))
- Name the author of an optimistic draft with the same ladder the server uses, so a post no longer changes its name on refresh ([`e35b40a`](https://github.com/Syntraksoftware/Snowtrak/commit/e35b40a))
- Anchor the duel-accept test to the real clock, where a hardcoded date meant it only passed within 48 hours of being written ([`2ede917`](https://github.com/Syntraksoftware/Snowtrak/commit/2ede917))

[0.0.6]: https://github.com/Syntraksoftware/Snowtrak/releases/tag/v0.0.6

## [0.0.5] - 2026-09-01

_Apply `018_follow_stats_requests_you.sql` before deploying; without it
`requests_you` is absent and Accept/Decline never appears. Notifications are
pending follow requests and nothing else — the `/api/v1/notifications/*` routes
are gone, and `send_notification.sh` with them._

### Changed

- **Breaking:** answer `GET /api/v1/posts/user/{id}` with nothing at all for a private account the viewer does not follow, where it used to serve that account's public posts ([`e964a25`](https://github.com/Syntraksoftware/Snowtrak/commit/e964a25))
- Report `requests_you` from `/follows/{id}/stats`, the mirror of `has_requested` ([`e964a25`](https://github.com/Syntraksoftware/Snowtrak/commit/e964a25))
- Build the notification list from pending follow requests, so tapping one opens the requester's profile ([`5b244bc`](https://github.com/Syntraksoftware/Snowtrak/commit/5b244bc))

### Added

- Approve or deny a follow request from the requester's own profile, instead of only from the requests screen ([`e964a25`](https://github.com/Syntraksoftware/Snowtrak/commit/e964a25))
- Tell a viewer a profile is private, rather than showing them an account that appears to have posted nothing ([`e964a25`](https://github.com/Syntraksoftware/Snowtrak/commit/e964a25))

### Removed

- Delete `/api/v1/notifications/*`, a global in-memory queue with no user id and no auth that delivered any notification written to whoever polled next ([`76ec2ce`](https://github.com/Syntraksoftware/Snowtrak/commit/76ec2ce))
- Delete the nine placeholder notifications the list fell back to whenever the backend returned nothing ([`5b244bc`](https://github.com/Syntraksoftware/Snowtrak/commit/5b244bc))
- Stop polling `/api/v1/notifications/pending` every two seconds, a request per user per two seconds that carried no notification anyone had sent ([`5b244bc`](https://github.com/Syntraksoftware/Snowtrak/commit/5b244bc))
- Delete `scripts/send_notification.sh` and `scripts/notification_demo.sh`, which existed only to write into that queue ([`76ec2ce`](https://github.com/Syntraksoftware/Snowtrak/commit/76ec2ce))

### Fixed

- Land on the home screen after registering, instead of on the submitted sign-up form ([`ac66ab1`](https://github.com/Syntraksoftware/Snowtrak/commit/ac66ab1))

[0.0.5]: https://github.com/Syntraksoftware/Snowtrak/releases/tag/v0.0.5

## [0.0.4] - 2026-08-27

_Following a private account is now a request. Existing followers are kept
when an account turns private; use "remove a follower" to drop them._

### Changed

- **Breaking:** answer `POST /api/v1/follows/{id}` with the state it reached, `following` or `requested`, instead of 204 ([`a0a0931`](https://github.com/Syntraksoftware/Snowtrak/commit/a0a0931))
- Require approval before somebody can follow a private account ([`a0a0931`](https://github.com/Syntraksoftware/Snowtrak/commit/a0a0931))
- Show a private account's follower and following lists only to its approved followers ([`d4e7301`](https://github.com/Syntraksoftware/Snowtrak/commit/d4e7301))
- Order the activity list explicitly, as a paginated read of a growing table should be ([`515d52d`](https://github.com/Syntraksoftware/Snowtrak/commit/515d52d))
- Default a new activity's visibility to private in the database, matching what the application already writes ([`9ea6009`](https://github.com/Syntraksoftware/Snowtrak/commit/9ea6009))
- Run an activity's own read alongside the follow visibility lookup instead of one after the other ([`90038e4`](https://github.com/Syntraksoftware/Snowtrak/commit/90038e4))

### Added

- Turn follower approval on and off from Settings → Privacy ([`87443c7`](https://github.com/Syntraksoftware/Snowtrak/commit/87443c7), [`3e24c56`](https://github.com/Syntraksoftware/Snowtrak/commit/3e24c56))
- Approve or deny follow requests from a screen reached off your profile ([`ccde8c8`](https://github.com/Syntraksoftware/Snowtrak/commit/ccde8c8), [`79239df`](https://github.com/Syntraksoftware/Snowtrak/commit/79239df))
- Add a Requested state to the follow button, which withdraws when tapped ([`2deccdd`](https://github.com/Syntraksoftware/Snowtrak/commit/2deccdd))
- Report `is_private` and `has_requested` from `/follows/{id}/stats`, so one call still fills the profile header ([`9ea6009`](https://github.com/Syntraksoftware/Snowtrak/commit/9ea6009))

### Removed

- Delete main-backend's unmounted duplicate implementation of activities, which used `is_public` while activity-backend used `visibility` and the two disagreed in production ([`1501b69`](https://github.com/Syntraksoftware/Snowtrak/commit/1501b69))
- Drop `activities.is_public`, a column no write path ever updated ([`9ea6009`](https://github.com/Syntraksoftware/Snowtrak/commit/9ea6009))

### Fixed

- Stop `GET /api/v1/activities/` returning every private activity in the database to unauthenticated callers ([`515d52d`](https://github.com/Syntraksoftware/Snowtrak/commit/515d52d))
- Stop an activity's comments, kudos and shares being reachable without being able to see the activity ([`f7437e5`](https://github.com/Syntraksoftware/Snowtrak/commit/f7437e5))
- Move the follower and following list reads off the event loop ([`d4e7301`](https://github.com/Syntraksoftware/Snowtrak/commit/d4e7301), [`d46daad`](https://github.com/Syntraksoftware/Snowtrak/commit/d46daad))

[0.0.4]: https://github.com/Syntraksoftware/Snowtrak/releases/tag/v0.0.4

## [0.0.3] - 2026-08-27

_Following is public and instant: no requests, no approval queue. Posts can be
public, followers-only or private, but nothing in the app writes anything but
public yet -- the composer picker is not built._

### Changed

- Re-skin the app onto the design system in `Snowtrak_DesignSystem.fig`: a neutral ramp carries the interface, ink is the one action colour, and cards are separated by a hairline instead of a shadow ([`e46c371`](https://github.com/Syntraksoftware/Snowtrak/commit/e46c371), [`8cd189b`](https://github.com/Syntraksoftware/Snowtrak/commit/8cd189b))
- Read every colour through the active theme rather than from a constant, so the interface can answer a theme change at all ([`44100e2`](https://github.com/Syntraksoftware/Snowtrak/commit/44100e2), [`f1c6cdb`](https://github.com/Syntraksoftware/Snowtrak/commit/f1c6cdb))
- Filter every read path that can return a post by who is allowed to see it ([`db18561`](https://github.com/Syntraksoftware/Snowtrak/commit/db18561))
- Store follower counts in `follow_counts`, maintained by a database trigger rather than by application code ([`8a24183`](https://github.com/Syntraksoftware/Snowtrak/commit/8a24183))
- Move blocking Supabase calls off the event loop, so one slow read no longer stalls every request in flight ([`5d71da3`](https://github.com/Syntraksoftware/Snowtrak/commit/5d71da3))
- Run the post hydration reads together instead of one after another, cutting a cold profile open from 4.07s to 1.19s ([`5d71da3`](https://github.com/Syntraksoftware/Snowtrak/commit/5d71da3))
- Cache follow stats, user post lists and profiles in Redis, alongside the feed ([`5d71da3`](https://github.com/Syntraksoftware/Snowtrak/commit/5d71da3))
- Answer `/follows/{id}/stats` in one round trip instead of four ([`8a24183`](https://github.com/Syntraksoftware/Snowtrak/commit/8a24183))
- Render other people's stat cards as unknown rather than as the signed-in user's numbers ([`d8fa466`](https://github.com/Syntraksoftware/Snowtrak/commit/d8fa466))
- Give `onAvatarTap` its own post, so an expanded reply opens its own author ([`d8fa466`](https://github.com/Syntraksoftware/Snowtrak/commit/d8fa466))

### Added

- Add a `visibility` tier to posts: public, followers-only, or private ([`db18561`](https://github.com/Syntraksoftware/Snowtrak/commit/db18561))
- Send and read a post's visibility from the client ([`db18561`](https://github.com/Syntraksoftware/Snowtrak/commit/db18561))
- Read a user's followers and following lists from the client ([`db18561`](https://github.com/Syntraksoftware/Snowtrak/commit/db18561))
- Follow and unfollow people, from a toggle on any profile that is not your own ([`8a24183`](https://github.com/Syntraksoftware/Snowtrak/commit/8a24183))
- Remove a follower, the escape hatch that open following needs ([`8a24183`](https://github.com/Syntraksoftware/Snowtrak/commit/8a24183))
- Add `/api/v1/follows` to community-backend: follow, unfollow, remove-a-follower, followers, following, stats ([`8a24183`](https://github.com/Syntraksoftware/Snowtrak/commit/8a24183))
- Open another person's profile by tapping their avatar in the feed or a thread ([`d8fa466`](https://github.com/Syntraksoftware/Snowtrak/commit/d8fa466))
- Document why the follow graph is owned by community-backend and not main-backend ([`8a24183`](https://github.com/Syntraksoftware/Snowtrak/commit/8a24183))
- Document the measured read latency of the community endpoints and what still costs a round trip ([`5d71da3`](https://github.com/Syntraksoftware/Snowtrak/commit/5d71da3))

### Removed

- Drop the privacy toggles from other people's profiles, where they showed your own settings ([`d8fa466`](https://github.com/Syntraksoftware/Snowtrak/commit/d8fa466))

### Fixed

- Show only Light under Display & Appearance. The picker offered Dark and System, and selecting either changed nothing but the toast ([`d31f262`](https://github.com/Syntraksoftware/Snowtrak/commit/d31f262))
- Build a profile from `user_info` instead of returning 404, for the many users who have no `profiles` row ([`d8fa466`](https://github.com/Syntraksoftware/Snowtrak/commit/d8fa466))
- Render the profile header while loading and after a failure, instead of collapsing it to nothing ([`d8fa466`](https://github.com/Syntraksoftware/Snowtrak/commit/d8fa466))
- Reserve the follow button's height while its counts load, so it stops shoving the profile down when they arrive ([`8a24183`](https://github.com/Syntraksoftware/Snowtrak/commit/8a24183))
- Make the first cache invalidation of a scope take effect ([`5d71da3`](https://github.com/Syntraksoftware/Snowtrak/commit/5d71da3))
- Let `ProfilePlaceholderBlock` grow with a wrapped label instead of clipping it ([`d8fa466`](https://github.com/Syntraksoftware/Snowtrak/commit/d8fa466))
- Stop the maps activity strip and the follower count row overflowing on a narrow screen ([`5d71da3`](https://github.com/Syntraksoftware/Snowtrak/commit/5d71da3), [`8a24183`](https://github.com/Syntraksoftware/Snowtrak/commit/8a24183))
- Skip a map trails request when the camera reports a bbox the backend rejects ([`5d71da3`](https://github.com/Syntraksoftware/Snowtrak/commit/5d71da3))
- Guard the `MapsScreen` callbacks that ran after the tab was left, calling `setState` on a disposed state ([`5d71da3`](https://github.com/Syntraksoftware/Snowtrak/commit/5d71da3))

[0.0.3]: https://github.com/Syntraksoftware/Snowtrak/releases/tag/v0.0.3
