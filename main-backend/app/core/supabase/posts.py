"""Post database operations."""
from __future__ import annotations

from typing import Optional, Dict, Any, List
import logging

from .base import SupabaseBase

logger = logging.getLogger(__name__)


class PostOperations(SupabaseBase):
    """
    Post table operations.
    
    Handles CRUD operations for user posts within subthreads.
    """

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
    
    def list_posts_by_user_id(
        self,
        user_id: str,
        limit: int = 20,
        offset: int = 0,
    ) -> List[Dict[str, Any]]:
        """List posts by user ID with author information."""
        if not self.is_configured():
            logger.warning("Supabase not configured; skipping list_posts_by_user_id.")
            return []
        
        client = self._client
        if client is None:
            return []
        
        try:
            resp = client.table("posts").select(
                "*, user_info!posts_user_id_fkey(email, first_name, last_name)"
            ).eq("user_id", user_id).order("created_at", desc=True).range(offset, offset + limit - 1).execute()
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
            logger.exception(f"Failed to list posts for user {user_id}: {exc}")
            return []
    
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
