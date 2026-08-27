# Changelog

## [0.0.3] - 2026-08-27

_Following is public and instant: no requests, no approval queue. Post
visibility (`public` / `followers` / `private`) is the other half of the
[design](docs/superpowers/specs/2026-08-26-follower-mechanism-design.md) and is
not in this release, so every post is still visible to everyone._

### Changed

- Store follower counts in `follow_counts`, maintained by a database trigger rather than by application code ([`8a24183`](https://github.com/Syntraksoftware/Snowtrak/commit/8a24183))
- Move blocking Supabase calls off the event loop, so one slow read no longer stalls every request in flight ([`5d71da3`](https://github.com/Syntraksoftware/Snowtrak/commit/5d71da3))
- Run the post hydration reads together instead of one after another, cutting a cold profile open from 4.07s to 1.19s ([`5d71da3`](https://github.com/Syntraksoftware/Snowtrak/commit/5d71da3))
- Cache follow stats, user post lists and profiles in Redis, alongside the feed ([`5d71da3`](https://github.com/Syntraksoftware/Snowtrak/commit/5d71da3))
- Answer `/follows/{id}/stats` in one round trip instead of four ([`8a24183`](https://github.com/Syntraksoftware/Snowtrak/commit/8a24183))
- Render other people's stat cards as unknown rather than as the signed-in user's numbers ([`d8fa466`](https://github.com/Syntraksoftware/Snowtrak/commit/d8fa466))
- Give `onAvatarTap` its own post, so an expanded reply opens its own author ([`d8fa466`](https://github.com/Syntraksoftware/Snowtrak/commit/d8fa466))

### Added

- Follow and unfollow people, from a toggle on any profile that is not your own ([`8a24183`](https://github.com/Syntraksoftware/Snowtrak/commit/8a24183))
- Remove a follower, the escape hatch that open following needs ([`8a24183`](https://github.com/Syntraksoftware/Snowtrak/commit/8a24183))
- Add `/api/v1/follows` to community-backend: follow, unfollow, remove-a-follower, followers, following, stats ([`8a24183`](https://github.com/Syntraksoftware/Snowtrak/commit/8a24183))
- Open another person's profile by tapping their avatar in the feed or a thread ([`d8fa466`](https://github.com/Syntraksoftware/Snowtrak/commit/d8fa466))
- Document why the follow graph is owned by community-backend and not main-backend ([`8a24183`](https://github.com/Syntraksoftware/Snowtrak/commit/8a24183))
- Document the measured read latency of the community endpoints and what still costs a round trip ([`5d71da3`](https://github.com/Syntraksoftware/Snowtrak/commit/5d71da3))

### Removed

- Drop the privacy toggles from other people's profiles, where they showed your own settings ([`d8fa466`](https://github.com/Syntraksoftware/Snowtrak/commit/d8fa466))

### Fixed

- Build a profile from `user_info` instead of returning 404, for the many users who have no `profiles` row ([`d8fa466`](https://github.com/Syntraksoftware/Snowtrak/commit/d8fa466))
- Render the profile header while loading and after a failure, instead of collapsing it to nothing ([`d8fa466`](https://github.com/Syntraksoftware/Snowtrak/commit/d8fa466))
- Reserve the follow button's height while its counts load, so it stops shoving the profile down when they arrive ([`8a24183`](https://github.com/Syntraksoftware/Snowtrak/commit/8a24183))
- Make the first cache invalidation of a scope take effect ([`5d71da3`](https://github.com/Syntraksoftware/Snowtrak/commit/5d71da3))
- Let `ProfilePlaceholderBlock` grow with a wrapped label instead of clipping it ([`d8fa466`](https://github.com/Syntraksoftware/Snowtrak/commit/d8fa466))
- Stop the maps activity strip and the follower count row overflowing on a narrow screen ([`5d71da3`](https://github.com/Syntraksoftware/Snowtrak/commit/5d71da3), [`8a24183`](https://github.com/Syntraksoftware/Snowtrak/commit/8a24183))
- Skip a map trails request when the camera reports a bbox the backend rejects ([`5d71da3`](https://github.com/Syntraksoftware/Snowtrak/commit/5d71da3))
- Guard the `MapsScreen` callbacks that ran after the tab was left, calling `setState` on a disposed state ([`5d71da3`](https://github.com/Syntraksoftware/Snowtrak/commit/5d71da3))

[0.0.3]: https://github.com/Syntraksoftware/Snowtrak/releases/tag/v0.0.3
