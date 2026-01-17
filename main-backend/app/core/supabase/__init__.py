"""
Unified Supabase client for interacting with all database tables.

This module uses composition (multiple inheritance) to combine all operation
classes into a single unified client while keeping code organized in separate files.

Database Tables:
- user_info: User authentication and profile data
- profiles: Extended user profile data (1-1 with auth.users)
- subthreads: Community topics/categories
- posts: User posts within subthreads
- comments: Comments on posts (supports nesting)
- activities: User activities (skiing, etc.)
- activity_locations: GPS points for activities
"""
from __future__ import annotations

from .base import SupabaseBase
from .users import UserOperations
from .profiles import ProfileOperations
from .subthreads import SubthreadOperations
from .posts import PostOperations
from .comments import CommentOperations
from .activities import ActivityOperations


class SupabaseClient(
    UserOperations,
    ProfileOperations,
    SubthreadOperations,
    PostOperations,
    CommentOperations,
    ActivityOperations,
):
    """
    Unified Supabase client combining all operations.
    
    Uses multiple inheritance (mixin pattern) to combine:
    - UserOperations: user_info table CRUD
    - ProfileOperations: profiles table CRUD
    - SubthreadOperations: subthreads table CRUD
    - PostOperations: posts table CRUD
    - CommentOperations: comments table CRUD
    - ActivityOperations: activities table CRUD
    
    All classes inherit from SupabaseBase which handles connection management.
    """
    pass


# Singleton instance for app-wide use
supabase_client = SupabaseClient()


# Export everything for convenient imports
__all__ = [
    "SupabaseClient",
    "SupabaseBase",
    "UserOperations",
    "ProfileOperations",
    "SubthreadOperations",
    "PostOperations",
    "CommentOperations",
    "ActivityOperations",
    "supabase_client",
]
