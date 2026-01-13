"""
Unified Supabase client for interacting with all database tables.

User Info Schema (user_info):
- id (uuid, primary key)
- email (text, unique)
- first_name (text, nullable)
- last_name (text, nullable)
- hashed_password (text) - bcrypt hashed password
- is_active (bool)
- last_login_at (timestamptz, nullable)
- created_at (timestamptz, default now())
- updated_at (timestamptz, default now(), updated via trigger)

Community Tables:
- subthreads: Community topics/categories
- posts: User posts within subthreads
- comments: Comments on posts (supports nesting)

This module initializes a Supabase client from environment settings and
exposes convenience methods for CRUD operations on all tables.
"""
from __future__ import annotations

from typing import Optional, Dict, Any, List
import logging

from supabase import create_client, Client

from app.core.config import settings


logger = logging.getLogger(__name__)


class SupabaseClient:
    """
    Unified wrapper around Supabase Python SDK.
    
    Handles operations for:
    - user_info table (authentication/user management)
    - subthreads, posts, comments tables (community features)
    """

    def __init__(self, url: Optional[str] = None, service_key: Optional[str] = None) -> None:
        # Access settings attributes defensively to satisfy type checkers
        cfg_url = getattr(settings, "supabase_url", None)
        cfg_key = getattr(settings, "supabase_service_role_key", None)
        self._url = url or cfg_url
        self._key = service_key or cfg_key
        self._client: Optional[Client] = None

        if self._url and self._key:
            try:
                self._client = create_client(self._url, self._key)
            except Exception as exc:
                logger.exception("Failed to initialize Supabase client: %s", exc)
                self._client = None
        else:
            logger.warning("Supabase URL/key not configured; client disabled.")

    def is_configured(self) -> bool:
        """Return True if the client is ready to use."""
        if self._client is None and self._url and self._key:
            # Lazy re-initialization if credentials are now available
            try:
                self._client = create_client(self._url, self._key)
            except Exception as exc:
                logger.exception("Failed to re-init Supabase client: %s", exc)
        return self._client is not None

    # ========== User Info Operations ==========
    
    # ---------- Insert ----------
    def insert_user_info(
        self,
        *,
        id: str,
        email: str,
        hashed_password: str,
        first_name: Optional[str] = None,
        last_name: Optional[str] = None,
        is_active: bool = True,
        extra: Optional[Dict[str, Any]] = None,
    ) -> Optional[Dict[str, Any]]:
        """
        Insert a user profile row into `user_info`.

        Notes:
        - `created_at`/`updated_at` should be defaulted/managed by DB.
        - If RLS is enabled, ensure service role key is used server-side.

        Returns the inserted row dict on success, or None on failure.
        """
        if not self.is_configured():
            logger.warning("Supabase not configured; skipping insert.")
            return None

        payload: Dict[str, Any] = {
            "id": id,
            "email": email,
            "hashed_password": hashed_password,
            "first_name": first_name,
            "last_name": last_name,
            "is_active": is_active,
        }
        if extra:
            payload.update(extra)

        client = self._client
        if client is None:
            return None
        try:
            resp = client.table("user_info").insert(payload).execute()
            data = getattr(resp, "data", None)
            if isinstance(data, list) and data:
                return data[0]
            if isinstance(data, dict):
                return data
            logger.error("Supabase insert returned no data: %s", data)
            return None
        except Exception as exc:
            logger.exception("Supabase insert failed: %s", exc)
            return None

    # ---------- Select ----------
    def get_user_info_by_id(self, id: str) -> Optional[Dict[str, Any]]:
        """Fetch single row from `user_info` by id (uuid)."""
        if not self.is_configured():
            logger.warning("Supabase not configured; skipping select by id.")
            return None
        client = self._client
        if client is None:
            return None
        try:
            resp = client.table("user_info").select("*").eq("id", id).limit(1).execute()
            data = getattr(resp, "data", None)
            if isinstance(data, list) and data:
                return data[0]
            return None
        except Exception as exc:
            logger.exception("Supabase select by id failed: %s", exc)
            return None

    def get_user_info_by_email(self, email: str) -> Optional[Dict[str, Any]]:
        """Fetch single row from `user_info` by email (text)."""
        if not self.is_configured():
            logger.warning("Supabase not configured; skipping select by email.")
            return None
        client = self._client
        if client is None:
            return None
        try:
            resp = client.table("user_info").select("*").eq("email", email).limit(1).execute()
            data = getattr(resp, "data", None)
            if isinstance(data, list) and data:
                return data[0]
            return None
        except Exception as exc:
            logger.exception("Supabase select by email failed: %s", exc)
            return None

    def update_user_last_login(self, id: str) -> bool:
        """Update last_login_at timestamp for a user. Returns True on success."""
        if not self.is_configured():
            logger.warning("Supabase not configured; skipping update.")
            return False
        client = self._client
        if client is None:
            return False
        try:
            from datetime import datetime, timezone
            resp = client.table("user_info").update(
                {"last_login_at": datetime.now(timezone.utc).isoformat()}
            ).eq("id", id).execute()
            logger.info(f"Updated last_login_at for user {id}")
            return True
        except Exception as exc:
            logger.exception(f"Failed to update last_login_at for user {id}: {exc}")
            return False

    def email_exists(self, email: str) -> bool:
        """Check if email already exists in user_info table."""
        if not self.is_configured():
            return False
        try:
            user = self.get_user_info_by_email(email)
            return user is not None
        except Exception as exc:
            logger.exception(f"Error checking email existence: {exc}")
            return False

    # ---------- Update ----------
    def update_user_info(
        self,
        id: str,
        *,
        first_name: Optional[str] = None,
        last_name: Optional[str] = None,
        is_active: Optional[bool] = None,
    ) -> Optional[Dict[str, Any]]:
        """
        Update user profile fields in `user_info` table.
        
        Only updates provided fields (partial update).
        Returns updated row dict on success, or None on failure.
        """
        if not self.is_configured():
            logger.warning("Supabase not configured; skipping update.")
            return None
        
        client = self._client
        if client is None:
            return None
        
        # Build update payload with only provided fields
        update_data: Dict[str, Any] = {}
        if first_name is not None:
            update_data["first_name"] = first_name
        if last_name is not None:
            update_data["last_name"] = last_name
        if is_active is not None:
            update_data["is_active"] = is_active
        
        if not update_data:
            logger.warning("No fields to update provided")
            return None
        
        try:
            resp = client.table("user_info").update(update_data).eq("id", id).execute()
            data = getattr(resp, "data", None)
            if isinstance(data, list) and data:
                return data[0]
            if isinstance(data, dict):
                return data
            logger.error("Supabase update returned no data: %s", data)
            return None
        except Exception as exc:
            logger.exception("Supabase update failed: %s", exc)
            return None

    # ========== Subthread Operations ==========
    
    def create_subthread(
        self,
        name: str,
        description: Optional[str] = None,
    ) -> Optional[Dict[str, Any]]:
        """
        Create a new subthread.
        
        Args:
            name: Unique name for the subthread
            description: Optional description
            
        Returns:
            Created subthread data or None on failure
        """
        if not self.is_configured():
            logger.warning("Supabase not configured; skipping create_subthread.")
            return None
        
        client = self._client
        if client is None:
            return None
        
        try:
            payload = {
                "name": name,
                "description": description,
            }
            resp = client.table("subthreads").insert(payload).execute()
            data = getattr(resp, "data", None)
            if isinstance(data, list) and data:
                logger.info(f"Created subthread: {name}")
                return data[0]
            return None
        except Exception as exc:
            logger.exception(f"Failed to create subthread {name}: {exc}")
            return None
    
    def get_subthread_by_id(self, subthread_id: str) -> Optional[Dict[str, Any]]:
        """Get subthread by ID."""
        if not self.is_configured():
            logger.warning("Supabase not configured; skipping get_subthread_by_id.")
            return None
        
        client = self._client
        if client is None:
            return None
        
        try:
            resp = client.table("subthreads").select("*").eq("id", subthread_id).limit(1).execute()
            data = getattr(resp, "data", None)
            if isinstance(data, list) and data:
                return data[0]
            return None
        except Exception as exc:
            logger.exception(f"Failed to get subthread {subthread_id}: {exc}")
            return None
    
    def get_subthread_by_name(self, name: str) -> Optional[Dict[str, Any]]:
        """Get subthread by name."""
        if not self.is_configured():
            logger.warning("Supabase not configured; skipping get_subthread_by_name.")
            return None
        
        client = self._client
        if client is None:
            return None
        
        try:
            resp = client.table("subthreads").select("*").eq("name", name).limit(1).execute()
            data = getattr(resp, "data", None)
            if isinstance(data, list) and data:
                return data[0]
            return None
        except Exception as exc:
            logger.exception(f"Failed to get subthread by name {name}: {exc}")
            return None
    
    def list_subthreads(self, limit: int = 50) -> List[Dict[str, Any]]:
        """List all subthreads."""
        if not self.is_configured():
            logger.warning("Supabase not configured; skipping list_subthreads.")
            return []
        
        client = self._client
        if client is None:
            return []
        
        try:
            resp = client.table("subthreads").select("*").order("created_at", desc=True).limit(limit).execute()
            data = getattr(resp, "data", None)
            return data if isinstance(data, list) else []
        except Exception as exc:
            logger.exception(f"Failed to list subthreads: {exc}")
            return []
    
    def delete_subthread(self, subthread_id: str) -> bool:
        """
        Delete a subthread and all its posts (and comments via CASCADE).
        
        Args:
            subthread_id: UUID of the subthread to delete
            
        Returns:
            True if deleted successfully, False otherwise
        """
        if not self.is_configured():
            logger.warning("Supabase not configured; skipping delete_subthread.")
            return False
        
        client = self._client
        if client is None:
            return False
        
        try:
            # Verify the subthread exists
            subthread = self.get_subthread_by_id(subthread_id)
            if not subthread:
                logger.warning(f"Subthread {subthread_id} not found")
                return False
            
            # Delete the subthread (CASCADE will handle posts and their comments)
            resp = client.table("subthreads").delete().eq("id", subthread_id).execute()
            data = getattr(resp, "data", None)
            
            if isinstance(data, list) and data:
                logger.info(f"Deleted subthread {subthread_id} and all associated posts/comments")
                return True
            
            return False
        except Exception as exc:
            logger.exception(f"Failed to delete subthread {subthread_id}: {exc}")
            return False
    
    # ========== Post Operations ==========
    
    def create_post(
        self,
        user_id: str,
        subthread_id: str,
        title: str,
        content: str,
    ) -> Optional[Dict[str, Any]]:
        """
        Create a new post.
        
        Args:
            user_id: UUID of the author
            subthread_id: UUID of the subthread
            title: Post title
            content: Post content
            
        Returns:
            Created post data or None on failure
        """
        if not self.is_configured():
            logger.warning("Supabase not configured; skipping create_post.")
            return None
        
        client = self._client
        if client is None:
            return None
        
        try:
            payload = {
                "user_id": user_id,
                "subthread_id": subthread_id,
                "title": title,
                "content": content,
            }
            resp = client.table("posts").insert(payload).execute()
            data = getattr(resp, "data", None)
            if isinstance(data, list) and data:
                logger.info(f"Created post by user {user_id}")
                return data[0]
            return None
        except Exception as exc:
            logger.exception(f"Failed to create post: {exc}")
            return None
    
    def get_post_by_id(self, post_id: str) -> Optional[Dict[str, Any]]:
        """Get post by ID with author information."""
        if not self.is_configured():
            logger.warning("Supabase not configured; skipping get_post_by_id.")
            return None
        
        client = self._client
        if client is None:
            return None
        
        try:
            resp = client.table("posts").select(
                "*, user_info!posts_user_id_fkey(email, first_name, last_name)"
            ).eq("post_id", post_id).limit(1).execute()
            data = getattr(resp, "data", None)
            if isinstance(data, list) and data:
                post = data[0]
                # Flatten author info
                if "user_info" in post and post["user_info"]:
                    author = post.pop("user_info")
                    post["author_email"] = author.get("email")
                    post["author_first_name"] = author.get("first_name")
                    post["author_last_name"] = author.get("last_name")
                return post
            return None
        except Exception as exc:
            logger.exception(f"Failed to get post {post_id}: {exc}")
            return None
    
    def list_posts_by_subthread(
        self,
        subthread_id: str,
        limit: int = 20,
        offset: int = 0,
    ) -> List[Dict[str, Any]]:
        """List posts in a subthread with author information."""
        if not self.is_configured():
            logger.warning("Supabase not configured; skipping list_posts_by_subthread.")
            return []
        
        client = self._client
        if client is None:
            return []
        
        try:
            resp = client.table("posts").select(
                "*, user_info!posts_user_id_fkey(email, first_name, last_name)"
            ).eq("subthread_id", subthread_id).order("created_at", desc=True).range(offset, offset + limit - 1).execute()
            data = getattr(resp, "data", None)
            if isinstance(data, list):
                # Flatten author info for each post
                for post in data:
                    if "user_info" in post and post["user_info"]:
                        author = post.pop("user_info")
                        post["author_email"] = author.get("email")
                        post["author_first_name"] = author.get("first_name")
                        post["author_last_name"] = author.get("last_name")
                return data
            return []
        except Exception as exc:
            logger.exception(f"Failed to list posts for subthread {subthread_id}: {exc}")
            return []
    
    def count_posts_by_subthread(self, subthread_id: str) -> int:
        """Count total posts in a subthread."""
        if not self.is_configured():
            logger.warning("Supabase not configured; skipping count_posts_by_subthread.")
            return 0
        
        client = self._client
        if client is None:
            return 0
        
        try:
            resp = client.table("posts").select("post_id", count="exact").eq("subthread_id", subthread_id).execute()
            return getattr(resp, "count", 0) or 0
        except Exception as exc:
            logger.exception(f"Failed to count posts: {exc}")
            return 0
    
    def delete_post(self, post_id: str, user_id: str) -> bool:
        """
        Delete a post and all its comments (via CASCADE).
        
        Args:
            post_id: UUID of the post to delete
            user_id: UUID of the user attempting deletion (must be post author)
            
        Returns:
            True if deleted successfully, False otherwise
        """
        if not self.is_configured():
            logger.warning("Supabase not configured; skipping delete_post.")
            return False
        
        client = self._client
        if client is None:
            return False
        
        try:
            # Verify the post exists and belongs to the user
            post = self.get_post_by_id(post_id)
            if not post:
                logger.warning(f"Post {post_id} not found")
                return False
            
            if post["user_id"] != user_id:
                logger.warning(f"User {user_id} attempted to delete post {post_id} owned by {post['user_id']}")
                return False
            
            # Delete the post (CASCADE will handle comments)
            resp = client.table("posts").delete().eq("post_id", post_id).execute()
            data = getattr(resp, "data", None)
            
            if isinstance(data, list) and data:
                logger.info(f"Deleted post {post_id} and all comments")
                return True
            
            return False
        except Exception as exc:
            logger.exception(f"Failed to delete post {post_id}: {exc}")
            return False
    
    # ========== Comment Operations ==========
    
    def create_comment(
        self,
        user_id: str,
        post_id: str,
        content: str,
        parent_id: Optional[str] = None,
    ) -> Optional[Dict[str, Any]]:
        """
        Create a new comment.
        
        Args:
            user_id: UUID of the author
            post_id: UUID of the post
            content: Comment content
            parent_id: Optional UUID of parent comment (for nested replies)
            
        Returns:
            Created comment data or None on failure
        """
        if not self.is_configured():
            logger.warning("Supabase not configured; skipping create_comment.")
            return None
        
        client = self._client
        if client is None:
            return None
        
        try:
            payload = {
                "user_id": user_id,
                "post_id": post_id,
                "content": content,
                "parent_id": parent_id,
                "has_parent": parent_id is not None,
            }
            resp = client.table("comments").insert(payload).execute()
            data = getattr(resp, "data", None)
            if isinstance(data, list) and data:
                logger.info(f"Created comment by user {user_id} on post {post_id}")
                return data[0]
            return None
        except Exception as exc:
            logger.exception(f"Failed to create comment: {exc}")
            return None
    
    def get_comment_by_id(self, comment_id: str) -> Optional[Dict[str, Any]]:
        """Get comment by ID with author information."""
        if not self.is_configured():
            logger.warning("Supabase not configured; skipping get_comment_by_id.")
            return None
        
        client = self._client
        if client is None:
            return None
        
        try:
            resp = client.table("comments").select(
                "*, user_info!comments_user_id_fkey(email, first_name, last_name)"
            ).eq("id", comment_id).limit(1).execute()
            data = getattr(resp, "data", None)
            if isinstance(data, list) and data:
                comment = data[0]
                # Flatten author info
                if "user_info" in comment and comment["user_info"]:
                    author = comment.pop("user_info")
                    comment["author_email"] = author.get("email")
                    comment["author_first_name"] = author.get("first_name")
                    comment["author_last_name"] = author.get("last_name")
                return comment
            return None
        except Exception as exc:
            logger.exception(f"Failed to get comment {comment_id}: {exc}")
            return None
    
    def list_comments_by_post(self, post_id: str) -> List[Dict[str, Any]]:
        """List all comments for a post with author information."""
        if not self.is_configured():
            logger.warning("Supabase not configured; skipping list_comments_by_post.")
            return []
        
        client = self._client
        if client is None:
            return []
        
        try:
            resp = client.table("comments").select(
                "*, user_info!comments_user_id_fkey(email, first_name, last_name)"
            ).eq("post_id", post_id).order("created_at", desc=False).execute()
            data = getattr(resp, "data", None)
            if isinstance(data, list):
                # Flatten author info for each comment
                for comment in data:
                    if "user_info" in comment and comment["user_info"]:
                        author = comment.pop("user_info")
                        comment["author_email"] = author.get("email")
                        comment["author_first_name"] = author.get("first_name")
                        comment["author_last_name"] = author.get("last_name")
                return data
            return []
        except Exception as exc:
            logger.exception(f"Failed to list comments for post {post_id}: {exc}")
            return []
    
    def count_comments_by_post(self, post_id: str) -> int:
        """Count total comments on a post."""
        if not self.is_configured():
            logger.warning("Supabase not configured; skipping count_comments_by_post.")
            return 0
        
        client = self._client
        if client is None:
            return 0
        
        try:
            resp = client.table("comments").select("id", count="exact").eq("post_id", post_id).execute()
            return getattr(resp, "count", 0) or 0
        except Exception as exc:
            logger.exception(f"Failed to count comments: {exc}")
            return 0
    
    def delete_comment(self, comment_id: str, user_id: str) -> bool:
        """
        Delete a comment (and all nested child comments via CASCADE).
        
        Args:
            comment_id: UUID of the comment to delete
            user_id: UUID of the user attempting deletion (must be comment author)
            
        Returns:
            True if deleted successfully, False otherwise
        """
        if not self.is_configured():
            logger.warning("Supabase not configured; skipping delete_comment.")
            return False
        
        client = self._client
        if client is None:
            return False
        
        try:
            # First verify the comment exists and belongs to the user
            comment = self.get_comment_by_id(comment_id)
            if not comment:
                logger.warning(f"Comment {comment_id} not found")
                return False
            
            if comment["user_id"] != user_id:
                logger.warning(f"User {user_id} attempted to delete comment {comment_id} owned by {comment['user_id']}")
                return False
            
            # Delete the comment (CASCADE will handle nested comments)
            resp = client.table("comments").delete().eq("id", comment_id).execute()
            data = getattr(resp, "data", None)
            
            if isinstance(data, list) and data:
                logger.info(f"Deleted comment {comment_id} and all nested replies")
                return True
            
            return False
        except Exception as exc:
            logger.exception(f"Failed to delete comment {comment_id}: {exc}")
            return False


# Singleton instance for app-wide use
supabase_client = SupabaseClient()

