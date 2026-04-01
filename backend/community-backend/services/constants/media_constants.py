"""Shared media constants/messages for community uploads."""

MEDIA_BUCKET = "community-media"
MEDIA_MAX_BYTES = 50 * 1024 * 1024

TOO_LARGE_MSG = "File is too large. Maximum size is 50 MB."
UNSUPPORTED_MSG = (
    "That file type is not supported. Try JPEG, PNG, GIF, WebP, HEIC, MP4, or MOV."
)
STORAGE_MSG = "Upload failed due to a storage error. Please try again."
BUCKET_MISSING_MSG = (
    "Media storage is not set up: the Supabase bucket 'community-media' does not exist. "
    "Run backend/community-backend/SUPABASE_STORAGE_SETUP.sql in your project's SQL editor."
)
