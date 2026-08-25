# Supabase schema

What the live database contains, as of 2026-08-25.

**This is a record, not a migration.** It is not runnable and must never
be treated as something to apply. Changing the database means changing it
in Supabase and regenerating this file -- in the order described in
[database_changes.md](database_changes.md).

Regenerate with `python scripts/dump_supabase_schema.py`, which reads the
schema over PostgREST and writes this file. Commit the result.

Two blind spots, both inherent to reading the schema through PostgREST:
the `map_trail` schema is not exposed, so the five tables Alembic keeps
there do not appear below; and check constraints, indexes, triggers and
row-level-security policies are invisible to it.

## Application tables

Created by hand in the Supabase dashboard. Nothing in this repository
defines them and no test asserts their shape.

### `activities`

| Column | Type | Null | Default | Key |
|---|---|---|---|---|
| `id` | uuid | no | `gen_random_uuid()` | PK |
| `user_id` | uuid | no |  | FK → `user_info.id` |
| `activity_type` | text | no |  |  |
| `name` | text | yes |  |  |
| `description` | text | yes |  |  |
| `distance_meters` | numeric | no | `0` |  |
| `duration_seconds` | integer | no | `0` |  |
| `elevation_gain_meters` | numeric | no | `0` |  |
| `start_time` | timestamp with time zone | no |  |  |
| `end_time` | timestamp with time zone | no |  |  |
| `average_pace` | numeric | yes | `0` |  |
| `max_pace` | numeric | yes | `0` |  |
| `calories` | integer | yes |  |  |
| `is_public` | boolean | no | `true` |  |
| `created_at` | timestamp with time zone | no | `now()` |  |
| `updated_at` | timestamp with time zone | no | `now()` |  |
| `gps_path` | json[] | no |  |  |
| `visibility` | text | no |  |  |
| `map_activity_id` | uuid | yes |  |  |
| `storage_key` | text | yes |  |  |
| `processing_status` | text | no | `ready` |  |
| `thumbnail_url` | text | yes |  |  |

### `activity_comments`

| Column | Type | Null | Default | Key |
|---|---|---|---|---|
| `id` | uuid | no | `gen_random_uuid()` | PK |
| `activity_id` | uuid | no |  | FK → `activities.id` |
| `user_id` | uuid | no |  | FK → `user_info.id` |
| `content` | text | no |  |  |
| `created_at` | timestamp with time zone | yes | `now()` |  |
| `updated_at` | timestamp with time zone | yes | `now()` |  |

### `activity_kudos`

| Column | Type | Null | Default | Key |
|---|---|---|---|---|
| `id` | uuid | no | `gen_random_uuid()` | PK |
| `activity_id` | uuid | no |  | FK → `activities.id` |
| `user_id` | uuid | no |  | FK → `user_info.id` |
| `created_at` | timestamp with time zone | yes | `now()` |  |

### `activity_locations`

| Column | Type | Null | Default | Key |
|---|---|---|---|---|
| `id` | uuid | no | `gen_random_uuid()` | PK |
| `activity_id` | uuid | no |  | FK → `activities.id` |
| `latitude` | numeric | no |  |  |
| `longitude` | numeric | no |  |  |
| `altitude` | numeric | yes |  |  |
| `accuracy` | numeric | yes |  |  |
| `speed` | numeric | yes |  |  |
| `timestamp` | timestamp with time zone | no |  |  |
| `sequence_order` | integer | no |  |  |
| `created_at` | timestamp with time zone | no | `now()` |  |

### `activity_shares`

| Column | Type | Null | Default | Key |
|---|---|---|---|---|
| `id` | uuid | no | `gen_random_uuid()` | PK |
| `activity_id` | uuid | no |  | FK → `activities.id` |
| `user_id` | uuid | no |  | FK → `user_info.id` |
| `token` | character varying | no |  |  |
| `created_at` | timestamp with time zone | yes | `now()` |  |
| `expires_at` | timestamp with time zone | yes |  |  |

### `comments`

| Column | Type | Null | Default | Key |
|---|---|---|---|---|
| `id` | uuid | no | `gen_random_uuid()` | PK |
| `created_at` | timestamp with time zone | no | `now()` |  |
| `user_id` | uuid | no | `gen_random_uuid()` | FK → `user_info.id` |
| `post_id` | uuid | no | `gen_random_uuid()` | FK → `posts.post_id` |
| `parent_id` | uuid | yes | `gen_random_uuid()` | FK → `comments.id` |
| `has_parent` | boolean | no | `false` |  |
| `content` | text | no |  |  |
| `media_urls` | jsonb | no |  |  |

### `device_tokens`

**Reserved, not dead.** The push-notification code that uses it exists on branches that were never merged (`feat: build device_token related operations`, `feat: build notification sender service`); the current tree has none of it. `scripts/send_notification.sh` is the surviving piece.

| Column | Type | Null | Default | Key |
|---|---|---|---|---|
| `id` | uuid | no | `gen_random_uuid()` | PK |
| `user_id` | uuid | no |  | FK → `user_info.id` |
| `token` | text | no |  |  |
| `platform` | text | no |  |  |
| `device_id` | text | yes |  |  |
| `app_version` | text | yes |  |  |
| `locale` | text | yes |  |  |
| `timezone` | text | yes |  |  |
| `is_active` | boolean | no | `true` |  |
| `last_seen_at` | timestamp with time zone | no | `now()` |  |
| `created_at` | timestamp with time zone | no | `now()` |  |
| `updated_at` | timestamp with time zone | no | `now()` |  |

### `post_likes`

**Unused.** Nothing in backend/ or frontend/ references it, and nothing ever did -- `git log -S post_likes` is empty. The community backend uses `post_votes` instead. Holds rows anyway, most recent 2026-01-29, so something wrote them outside this repository. Superseded, not reserved.

| Column | Type | Null | Default | Key |
|---|---|---|---|---|
| `id` | uuid | no | `gen_random_uuid()` | PK |
| `post_id` | uuid | no |  | FK → `posts.post_id` |
| `user_id` | uuid | no |  | FK → `user_info.id` |
| `created_at` | timestamp with time zone | yes | `now()` |  |

### `post_reposts`

| Column | Type | Null | Default | Key |
|---|---|---|---|---|
| `id` | uuid | no | `gen_random_uuid()` | PK |
| `post_id` | uuid | no |  | FK → `posts.post_id` |
| `user_id` | text | no |  |  |

### `post_votes`

| Column | Type | Null | Default | Key |
|---|---|---|---|---|
| `id` | uuid | no | `gen_random_uuid()` | PK |
| `post_id` | uuid | no |  | FK → `posts.post_id` |
| `user_id` | text | no |  |  |
| `vote_value` | smallint | no |  |  |

### `posts`

| Column | Type | Null | Default | Key |
|---|---|---|---|---|
| `post_id` | uuid | no | `gen_random_uuid()` | PK |
| `created_at` | timestamp with time zone | no | `now()` |  |
| `user_id` | uuid | no | `gen_random_uuid()` | FK → `user_info.id` |
| `subthread_id` | uuid | no | `gen_random_uuid()` | FK → `subthreads.id` |
| `title` | text | no |  |  |
| `content` | text | no |  |  |
| `reposted_post_id` | uuid | yes |  | FK → `posts.post_id` |
| `like_count` | integer | no | `0` |  |
| `repost_count` | integer | no | `0` |  |
| `quoted_post_id` | uuid | yes |  | FK → `posts.post_id` |
| `repost_of_post_id` | uuid | yes |  | FK → `posts.post_id` |
| `quoted_comment_id` | uuid | yes |  | FK → `comments.id` |
| `repost_of_comment_id` | uuid | yes |  | FK → `comments.id` |
| `media_urls` | jsonb | no |  |  |

### `profiles`

| Column | Type | Null | Default | Key |
|---|---|---|---|---|
| `id` | uuid | no |  | PK |
| `full_name` | text | yes |  |  |
| `username` | text | yes |  |  |
| `bio` | text | yes |  |  |
| `avatar_url` | text | yes |  |  |
| `push_token` | text | yes |  |  |
| `ski_level` | text | yes |  |  |
| `home` | text | yes |  |  |
| `created_at` | timestamp with time zone | yes | `now()` |  |
| `updated_at` | timestamp with time zone | yes | `now()` |  |

### `ski_resorts`

**Unused and empty.** The map pipeline uses the `map_trail` schema that Alembic owns (`ski_runs`, `ski_lifts`), not these. No code, no history, no rows.

| Column | Type | Null | Default | Key |
|---|---|---|---|---|
| `id` | uuid | no | `gen_random_uuid()` | PK |
| `name` | text | no |  |  |
| `country` | text | no |  |  |
| `region` | text | yes |  |  |
| `latitude` | numeric | yes |  |  |
| `longitude` | numeric | yes |  |  |
| `website_url` | text | yes |  |  |
| `total_trails` | integer | yes | `0` |  |
| `total_lifts` | integer | yes | `0` |  |
| `vertical_drop_m` | integer | yes |  |  |
| `base_elevation_m` | integer | yes |  |  |
| `peak_elevation_m` | integer | yes |  |  |
| `image_url` | text | yes |  |  |
| `created_at` | timestamp with time zone | yes | `now()` |  |
| `updated_at` | timestamp with time zone | yes | `now()` |  |

### `ski_trails`

**Unused and empty.** The map pipeline uses the `map_trail` schema that Alembic owns (`ski_runs`, `ski_lifts`), not these. No code, no history, no rows.

| Column | Type | Null | Default | Key |
|---|---|---|---|---|
| `id` | uuid | no | `gen_random_uuid()` | PK |
| `resort_id` | uuid | yes |  | FK → `ski_resorts.id` |
| `name` | text | no |  |  |
| `difficulty` | text | no |  |  |
| `length_km` | numeric | no |  |  |
| `elevation_drop_m` | integer | no |  |  |
| `is_groomed` | boolean | yes | `true` |  |
| `has_snowmaking` | boolean | yes | `false` |  |
| `description` | text | yes |  |  |
| `rating` | numeric | yes |  |  |
| `review_count` | integer | yes | `0` |  |
| `image_url` | text | yes |  |  |
| `features` | text[] | yes |  |  |
| `status` | text | yes | `open` |  |
| `created_at` | timestamp with time zone | yes | `now()` |  |
| `updated_at` | timestamp with time zone | yes | `now()` |  |
| `search_vector` | tsvector | yes |  |  |

### `subthreads`

| Column | Type | Null | Default | Key |
|---|---|---|---|---|
| `id` | uuid | no | `gen_random_uuid()` | PK |
| `created_at` | timestamp with time zone | no | `now()` |  |
| `name` | text | no |  |  |
| `description` | text | yes |  |  |

### `user_info`

| Column | Type | Null | Default | Key |
|---|---|---|---|---|
| `id` | uuid | no | `extensions.uuid_generate_v4()` | PK |
| `email` | text | no |  |  |
| `last_name` | text | yes |  |  |
| `first_name` | text | yes |  |  |
| `created_at` | timestamp with time zone | yes | `now()` |  |
| `updated_at` | timestamp with time zone | yes | `now()` |  |
| `is_active` | boolean | no | `true` |  |
| `last_login_at` | timestamp with time zone | yes |  |  |
| `hashed_password` | text | no |  |  |

### `user_stats`

| Column | Type | Null | Default | Key |
|---|---|---|---|---|
| `user_id` | uuid | no |  | PK |
| `week_start` | date | no |  |  |
| `weekly_distance_km` | double precision | no | `0` |  |
| `weekly_time_min` | integer | no | `0` |  |
| `weekly_elev_gain_m` | double precision | no | `0` |  |
| `weekly_session_count` | integer | no | `0` |  |
| `last_week_session_count` | integer | no | `0` |  |
| `yearly_distance_km` | double precision | no | `0` |  |
| `yearly_time_min` | integer | no | `0` |  |
| `yearly_elev_gain_m` | double precision | no | `0` |  |
| `yearly_session_count` | integer | no | `0` |  |
| `all_time_distance_km` | double precision | no | `0` |  |
| `all_time_time_min` | integer | no | `0` |  |
| `all_time_elev_gain_m` | double precision | no | `0` |  |
| `all_time_session_count` | integer | no | `0` |  |
| `current_streak_weeks` | integer | no | `0` |  |
| `longest_streak_weeks` | integer | no | `0` |  |
| `activity_days` | text[] | no |  |  |
| `best_efforts` | jsonb | no |  |  |
| `updated_at` | timestamp with time zone | no | `now()` |  |

## Map tables

Owned by `backend/db/migrations/versions/`. Change these with an Alembic
revision, not in the dashboard.

### `elevation_samples`

| Column | Type | Null | Default | Key |
|---|---|---|---|---|
| `id` | bigint | no |  | PK |
| `location` | public.geography(Point,4326) | no |  |  |
| `elevation_meters` | double precision | no |  |  |
| `source` | text | no | `google_elevation` |  |
| `sampled_at` | timestamp with time zone | no | `now()` |  |

### `map_cache_entries`

| Column | Type | Null | Default | Key |
|---|---|---|---|---|
| `id` | bigint | no |  | PK |
| `cache_key` | text | no |  |  |
| `center` | public.geography(Point,4326) | no |  |  |
| `zoom` | integer | no |  |  |
| `width` | integer | no |  |  |
| `height` | integer | no |  |  |
| `provider` | text | no | `google_static_maps` |  |
| `static_url` | text | no |  |  |
| `expires_at` | timestamp with time zone | yes |  |  |
| `created_at` | timestamp with time zone | no | `now()` |  |

## Not ours

PostGIS internals and Alembic's own bookkeeping: `alembic_version`, `geography_columns`, `geometry_columns`, `spatial_ref_sys`.
