# Activity-backend SQL migrations

Run scripts in Supabase SQL Editor (or `psql`) against the **public** schema.

| Script | Purpose |
|--------|---------|
| `004_activity_pipeline_columns.sql` | `map_activity_id`, `storage_key`, `processing_status` + indexes |

After migration, create Storage bucket `activity-uploads` (private) in Supabase Dashboard for Phase 3 presigned uploads.

Optional env for async pipeline:

```env
REDIS_URL=redis://localhost:6379/0
MAP_BACKEND_BASE_URL=http://127.0.0.1:5200
NIVUS_BASE_URL=http://127.0.0.1:5201
ACTIVITY_UPLOAD_BUCKET=activity-uploads
```

When `REDIS_URL` is unset, `upload-complete` runs the pipeline inline (dev-friendly).
