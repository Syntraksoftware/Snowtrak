"""
Supabase client for community feature operations.

This client handles all CRUD operations for subthreads, posts, and comments.
It's designed to work with the same Supabase instance as the auth system
but is self-contained for easy migration.
"""
from typing import Optional, List, Dict, Any
import logging
from datetime import datetime

from supabase import create_client, Client
from config import get_config

logger = logging.getLogger(__name__)

# Global client instance
_community_client = None


def get_community_client():
    """
    Get or create the community Supabase client instance.
    
    Returns:
        CommunitySupabaseClient instance
    """
    global _community_client
    if _community_client is None:
        config = get_config()
        supabase = create_client(config.SUPABASE_URL, config.SUPABASE_SERVICE_ROLE_KEY)
        _community_client = CommunitySupabaseClient(supabase)
    return _community_client


class CommunitySupabaseClient:
    """
    Handles all Supabase operations for the community feature.
    
    Tables:
    - subthreads: Community topics/categories
    - posts: User posts within subthreads
    - comments: Comments on posts (supports nesting)
    """
    
    def __init__(self, supabase_client: Client):
        """
        Initialize with an existing Supabase client.
        
        Args:
            supabase_client: Authenticated Supabase client instance
        """
        self._client = supabase_client
    
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
        try:
            payload = {
                "name": name,
                "description": description,
            }
            resp = self._client.table("subthreads").insert(payload).execute()
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
        try:
            resp = self._client.table("subthreads").select("*").eq("id", subthread_id).limit(1).execute()
            data = getattr(resp, "data", None)
            if isinstance(data, list) and data:
                return data[0]
            return None
        except Exception as exc:
            logger.exception(f"Failed to get subthread {subthread_id}: {exc}")
            return None
    
    def get_subthread_by_name(self, name: str) -> Optional[Dict[str, Any]]:
        """Get subthread by name."""
        try:
            resp = self._client.table("subthreads").select("*").eq("name", name).limit(1).execute()
            data = getattr(resp, "data", None)
            if isinstance(data, list) and data:
                return data[0]
            return None
        except Exception as exc:
            logger.exception(f"Failed to get subthread by name {name}: {exc}")
            return None
    
    def list_subthreads(self, limit: int = 50) -> List[Dict[str, Any]]:
        """List all subthreads."""
        try:
            resp = self._client.table("subthreads").select("*").order("created_at", desc=True).limit(limit).execute()
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
        try:
            # Verify the subthread exists
            subthread = self.get_subthread_by_id(subthread_id)
            if not subthread:
                logger.warning(f"Subthread {subthread_id} not found")
                return False
            
            # Delete the subthread (CASCADE will handle posts and their comments)
            resp = self._client.table("subthreads").delete().eq("id", subthread_id).execute()
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
        try:
            payload = {
                "user_id": user_id,
                "subthread_id": subthread_id,
                "title": title,
                "content": content,
            }
            resp = self._client.table("posts").insert(payload).execute()
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
        try:
            resp = self._client.table("posts").select(
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
        try:
            resp = self._client.table("posts").select(
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
        try:
            from postgrest import CountMethod
            resp = self._client.table("posts").select("post_id", count=CountMethod.exact).eq("subthread_id", subthread_id).execute()
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
            resp = self._client.table("posts").delete().eq("post_id", post_id).execute()
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
        try:
            payload = {
                "user_id": user_id,
                "post_id": post_id,
                "content": content,
                "parent_id": parent_id,
                "has_parent": parent_id is not None,
            }
            resp = self._client.table("comments").insert(payload).execute()
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
        try:
            resp = self._client.table("comments").select(
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
        try:
            resp = self._client.table("comments").select(
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
        try:
            from postgrest import CountMethod
            resp = self._client.table("comments").select("id", count=CountMethod.exact).eq("post_id", post_id).execute()
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
            resp = self._client.table("comments").delete().eq("id", comment_id).execute()
            data = getattr(resp, "data", None)
            
            if isinstance(data, list) and data:
                logger.info(f"Deleted comment {comment_id} and all nested replies")
                return True
            
            return False
        except Exception as exc:
            logger.exception(f"Failed to delete comment {comment_id}: {exc}")
            return False
