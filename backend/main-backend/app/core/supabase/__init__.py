"""
Unified Supabase client for interacting with all database tables.

Modulse uses composition (multiple inheritance) to combine all operation
classes into a single unified client while keeping code organized in separate files.

Database Tables:
- user_info: User authentication and profile data
- profiles: Extended user profile data (1-1 with auth.users)
- subthreads: Community topics/categories
- posts: User posts within subthreads
- comments: Comments on posts (supports nesting)
"""

from __future__ import annotations

from .base import SupabaseBase
from .comments import CommentOperations
from .posts import PostOperations
from .profiles import ProfileOperations
from .subthreads import SubthreadOperations
from .users import UserOperations


class SupabaseClient(
    UserOperations,
    ProfileOperations,
    SubthreadOperations,
    PostOperations,
    CommentOperations,
):
    """
    Unified Supabase client combining all operations.

    Uses multiple inheritance (mixin pattern) to combine:
    - UserOperations: user_info table CRUD
    - ProfileOperations: profiles table CRUD
    - SubthreadOperations: subthreads table CRUD
    - PostOperations: posts table CRUD
    - CommentOperations: comments table CRUD

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
    "supabase_client",
]
