"""External dependency adapters for activities_service."""

from db.connection import require_pool_conn

__all__ = ["require_pool_conn"]
