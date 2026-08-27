"""Table names used by community Supabase operations."""

POSTS = "posts"
COMMENTS = "comments"
# Likes are rows in post_likes: present means liked. post_votes was a second
# implementation of the same feature and is being retired -- see
# backend/db/migrations/008_backfill_post_likes.sql.
POST_LIKES = "post_likes"
POST_VOTES = "post_votes"
COMMENT_VOTES = "comment_votes"
POST_REPOSTS = "post_reposts"
# The follow graph. See backend/db/migrations/010_follows.sql.
FOLLOWS = "follows"
# Pending follows. Kept out of `follows` on purpose -- see
# backend/db/migrations/014_follow_requests.sql.
FOLLOW_REQUESTS = "follow_requests"
# Read-only here: main-backend owns this table.
USER_INFO = "user_info"
