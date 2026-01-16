"""
Unified Supabase client for interacting with all database tables.

This module uses composition (multiple inheritance) to combine all operation
classes into a single unified client while keeping code organized in separate files.

Database Tables:
- user_info: User authentication and profile data
- subthreads: Community topics/categories
- posts: User posts within subthreads
- comments: Comments on posts (supports nesting)
"""
from __future__ import annotations

from .base import SupabaseBase
from .users import UserOperations
from .subthreads import SubthreadOperations
from .posts import PostOperations
from .comments import CommentOperations


class SupabaseClient(
    UserOperations,
    SubthreadOperations,
    PostOperations,
    CommentOperations,
):
    """
    Unified Supabase client combining all operations.
    
    Uses multiple inheritance (mixin pattern) to combine:
    - UserOperations: user_info table CRUD
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
    "SubthreadOperations",
    "PostOperations",
    "CommentOperations",
    "supabase_client",
]
