# Frontend ↔ Activity Backend API Schemas

Source files: frontend calls are implemented in [frontend/lib/services/api_service.dart](frontend/lib/services/api_service.dart) and rely on models in [frontend/lib/models/activity.dart](frontend/lib/models/activity.dart) and [frontend/lib/models/location.dart](frontend/lib/models/location.dart). Backend contracts are defined in [backend/activity-backend/models.py](backend/activity-backend/models.py) and routes in [backend/activity-backend/routes/activities.py](backend/activity-backend/routes/activities.py).

Base URL configured in the frontend: `http://127.0.0.1:8080/api/v1`.

## POST /activities (create)
- What the frontend sends (from `Activity.toJson()`):
  - `type` (string enum: alpine | cross_country | freestyle | backcountry | snowboard | other)
  - `name` (string, optional)
  - `description` (string, optional)
  - `start_time` (ISO 8601 string)
  - `end_time` (ISO 8601 string)
  - `locations` (array of objects: latitude, longitude, altitude?, accuracy?, speed?, timestamp)
  - `is_public` (bool)
- What the backend accepts (`FrontendActivityCreate`):
  - Payload shape is the **same** as the frontend payload above (`type`, `name`, `description`, `start_time`, `end_time`, `locations`, `is_public`).
  - The backend maps these fields to its internal models and computes server-side metrics such as distance, duration, and elevation gain before persisting and returning them.
- What the frontend expects back (`Activity.fromJson`):
  - `id`, `user_id`, `type`, `name`, `description`, `distance`, `duration`, `elevation_gain`, `start_time`, `end_time`, `average_pace`, `max_pace`, `calories`, `is_public`, `created_at`, `locations` (array of location objects)
- Data provenance (frontend): activity objects are assembled in the record/create flow; location points come from device GPS; visibility flag from UI; timing fields come from the recording session. The frontend does **not** compute or send distance/duration/elevation—those must be inferred or calculated server-side before echoing them back.
  - `id`, `user_id`, `type`, `name`, `description`, `distance`, `duration`, `elevation_gain`, `start_time`, `end_time`, `average_pace`, `max_pace`, `calories`, `is_public`, `created_at`, `locations` (array of location objects)
- Data provenance (frontend): activity objects are assembled in the record/create flow; location points come from device GPS; visibility flag from UI; timing fields come from the recording session. The frontend does **not** compute or send distance/duration/elevation—those must be inferred or calculated server-side before echoing them back.

## GET /activities (feed)
- Frontend query params: `page` (default 1), `limit` (default 20).
- Backend expects: `limit` (default 20), `offset` (default 0).
- Frontend expects response: an **array** of activities shaped like `Activity.fromJson` (see above).
- Backend returns: an object `{ items: [ActivityResponse], total: int }`.
- Data provenance: list comes from backend store; pagination mismatch means frontend currently ignores `total` and expects bare array.

## GET /activities/{id}
- Frontend expects response shaped like `Activity.fromJson` (includes type, distance, duration, start_time, end_time, pace metrics, locations, etc.).
- Backend returns `ActivityResponse` (fields: id, user_id, name, activity_type, gps_path, duration_seconds, distance_meters, elevation_gain_meters, visibility, description, created_at).
- Data provenance: backend fetches by id (Supabase client); frontend just displays returned fields.

## PUT /activities/{id}
- Frontend sends: optional `name`, `description`, `is_public`.
- Backend expects (`FrontendActivityUpdate`): optional `name`, `description`, `is_public`.
- Frontend expects response shaped like `Activity.fromJson`.
- Data provenance: update payload assembled from edit UI; backend enforces ownership via auth dependency.

## DELETE /activities/{id}
- Frontend sends: no body.
- Backend returns: `{ message, deleted_activity_id }`.
- Frontend does not read the body; it removes the item locally on success.

## Unused activity-backend endpoints (currently not called by the frontend)
- `GET /activities/me`
- `POST /activities/{id}/kudos`
- `GET /activities/{id}/comments`
- `POST /activities/{id}/comments`
- `POST /activities/{id}/share`

## Key gaps to reconcile
- Field names and shapes differ between frontend and backend (e.g., `type` vs `activity_type`, `is_public` vs `visibility`).
- Backend requires distance/duration/elevation metrics; frontend does not send them and expects them back.
- Pagination params differ (`page` vs `offset`), and frontend expects a list instead of `{items, total}`.
- Location paths: frontend sends `locations` with latitude/longitude keys; backend expects `gps_path` with lat/lng keys.
