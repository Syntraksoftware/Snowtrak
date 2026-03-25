"""
Community data models.

These classes represent the core entities in the community feature.
They mirror the Supabase schema and are used for type safety and validation.
"""
from typing import Optional
from datetime import datetime
from uuid import UUID


class Subthread:
    """
    Represents a community subthread (similar to a subreddit).
    
    Attributes:
        id: UUID primary key
        name: Unique name/slug for the subthread
        description: Optional description of the subthread
        created_at: Timestamp when subthread was created
    """
    
    def __init__(
        self,
        name: str,
        description: Optional[str] = None,
        id: Optional[str] = None,
        created_at: Optional[datetime] = None,
    ):
        self.id = id
        self.name = name
        self.description = description
        self.created_at = created_at or datetime.utcnow()
    
    def to_dict(self):
        """Convert to dictionary for API responses."""
        return {
            "id": self.id,
            "name": self.name,
            "description": self.description,
            "created_at": self.created_at.isoformat() if isinstance(self.created_at, datetime) else self.created_at,
        }


class Post:
    """
    Represents a community post.
    
    Attributes:
        post_id: UUID primary key
        user_id: UUID foreign key to user_info table
        subthread_id: UUID foreign key to subthreads table
        title: Post title
        content: Post body/content
        created_at: Timestamp when post was created
    """
    
    def __init__(
        self,
        user_id: str,
        subthread_id: str,
        title: str,
        content: str,
        post_id: Optional[str] = None,
        created_at: Optional[datetime] = None,
    ):
        self.post_id = post_id
        self.user_id = user_id
        self.subthread_id = subthread_id
        self.title = title
        self.content = content
        self.created_at = created_at or datetime.utcnow()
    
    def to_dict(self):
        """Convert to dictionary for API responses."""
        return {
            "post_id": self.post_id,
            "user_id": self.user_id,
            "subthread_id": self.subthread_id,
            "title": self.title,
            "content": self.content,
            "created_at": self.created_at.isoformat() if isinstance(self.created_at, datetime) else self.created_at,
        }


class Comment:
    """
    Represents a comment on a post (supports nested comments).
    
    Attributes:
        id: UUID primary key
        user_id: UUID foreign key to user_info table
        post_id: UUID foreign key to posts table
        parent_id: Optional UUID foreign key to comments table (for nested comments)
        has_parent: Boolean flag indicating if this is a reply
        content: Comment text
        created_at: Timestamp when comment was created
    """
    
    def __init__(
        self,
        user_id: str,
        post_id: str,
        content: str,
        parent_id: Optional[str] = None,
        id: Optional[str] = None,
        created_at: Optional[datetime] = None,
    ):
        self.id = id
        self.user_id = user_id
        self.post_id = post_id
        self.parent_id = parent_id
        self.has_parent = parent_id is not None
        self.content = content
        self.created_at = created_at or datetime.utcnow()
    
    def to_dict(self):
        """Convert to dictionary for API responses."""
        return {
            "id": self.id,
            "user_id": self.user_id,
            "post_id": self.post_id,
            "parent_id": self.parent_id,
            "has_parent": self.has_parent,
            "content": self.content,
            "created_at": self.created_at.isoformat() if isinstance(self.created_at, datetime) else self.created_at,
        }
