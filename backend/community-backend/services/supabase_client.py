"""
Supabase client wrapper for community feature operations.

This module provides access to the unified SupabaseClient from main-backend,
configured with community-backend's settings.
"""
import logging
from typing import Optional

from config import get_config
from supabase import Client, create_client

from services.community_comment_operations import CommunityCommentOperations
from services.community_post_operations import CommunityPostOperations
from services.community_subthread_operations import CommunitySubthreadOperations

# Global client instance - initialized at app startup
_community_client: Optional["CommunitySupabaseClient"] = None
logger = logging.getLogger(__name__)


def initialize_community_client() -> "CommunitySupabaseClient":
    """
    Initialize the Supabase client at application startup.
    
    This should be called once during FastAPI lifespan startup.
    Avoids lazy initialization race conditions and redundant client creation.
    
    Returns:
        SupabaseClient instance configured with community-backend's settings
    """
    global _community_client
    config = get_config()
    try:
        supabase = create_client(config.SUPABASE_URL, config.SUPABASE_SERVICE_ROLE_KEY)
        _community_client = CommunitySupabaseClient(supabase)
        logger.info("✅ Supabase client initialized at startup")
        return _community_client
    except Exception as e:
        logger.error(f"❌ Failed to initialize Supabase client: {e}")
        raise


def get_community_client() -> "CommunitySupabaseClient":
    """
    Get the community Supabase client instance.
    
    IMPORTANT: Call initialize_community_client() at app startup before using this.
    
    Returns:
        CommunitySupabaseClient instance
        
    Raises:
        RuntimeError: If client was not initialized at startup
    """
    if _community_client is None:
        raise RuntimeError(
            "Supabase client not initialized. "
            "Call initialize_community_client() during app startup (in lifespan)."
        )
    return _community_client

class CommunitySupabaseClient(
    CommunitySubthreadOperations,
    CommunityPostOperations,
    CommunityCommentOperations,
):
    """Handles all Supabase operations for the community feature."""
    
    def __init__(self, supabase_client: Client):
        """Initialize with an existing authenticated Supabase client instance."""
        self._client = supabase_client