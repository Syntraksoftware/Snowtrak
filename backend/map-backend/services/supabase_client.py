"""Supabase client initialization for Map Backend."""

from supabase import Client, create_client

from config import get_config

config = get_config()

# Global Supabase client instance
_map_client: Client | None = None


def initialize_map_client() -> None:
    """Initialize the global Supabase client for map backend."""
    global _map_client
    if _map_client is None:
        _map_client = create_client(config.SUPABASE_URL, config.SUPABASE_SERVICE_ROLE_KEY)


def get_map_client() -> Client:
    """Get the global Supabase client instance."""
    if _map_client is None:
        raise RuntimeError("Supabase client not initialized. Call initialize_map_client() first.")
    return _map_client
