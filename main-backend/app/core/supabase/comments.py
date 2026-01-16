"""Comment database operations."""
from __future__ import annotations

from typing import Optional, Dict, Any, List
import logging

from .base import SupabaseBase

logger = logging.getLogger(__name__)


class CommentOperations(SupabaseBase):
    """
    Comment table operations.
    
    Handles CRUD operations for comments on posts (supports nesting).
    """

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
