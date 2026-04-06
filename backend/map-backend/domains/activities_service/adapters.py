"""Compatibility shim for activities_service external dependencies."""

from domains.activities_service.infra import get_activities_conn

require_pool_conn = get_activities_conn

__all__ = ["require_pool_conn", "get_activities_conn"]
