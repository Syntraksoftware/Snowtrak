"""
Supabase client wrapper for community feature operations.

This module provides access to the unified SupabaseClient from main-backend,
configured with community-backend's settings.
"""
import sys
from pathlib import Path

# Add main-backend to Python path so we can import the unified client
main_backend_path = Path(__file__).parent.parent.parent / "main-backend"
if str(main_backend_path) not in sys.path:
    sys.path.insert(0, str(main_backend_path))

from app.core.supabase import SupabaseClient
from config import get_config

# Global client instance
_community_client = None


def get_community_client() -> SupabaseClient:
    """
    Get or create the unified Supabase client instance configured for community-backend.
    
    Returns:
        SupabaseClient instance configured with community-backend's settings
    """
    global _community_client
    if _community_client is None:
        config = get_config()
        # Initialize the unified client with community-backend's config
        _community_client = SupabaseClient(
            url=config.SUPABASE_URL,
            service_key=config.SUPABASE_SERVICE_ROLE_KEY
        )
    return _community_client


# For backward compatibility, alias CommunitySupabaseClient to SupabaseClient
# This allows existing code to continue working
CommunitySupabaseClient = SupabaseClient
