# Changelog

## [0.0.5] - 2026-09-01

_Notifications are now pending follow requests and nothing else. The
`/api/v1/notifications/*` routes still exist and still share one queue between
all users; the app no longer reads them._

### Changed

- Build the notification list from pending follow requests, so tapping one opens the requester's profile ([`5b244bc`](https://github.com/Syntraksoftware/Snowtrak/commit/5b244bc))

### Removed

- Delete the nine placeholder notifications the list fell back to whenever the backend returned nothing ([`5b244bc`](https://github.com/Syntraksoftware/Snowtrak/commit/5b244bc))
- Stop polling `/api/v1/notifications/pending` every two seconds, a request per user per two seconds that carried no notification anyone had sent ([`5b244bc`](https://github.com/Syntraksoftware/Snowtrak/commit/5b244bc))

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
