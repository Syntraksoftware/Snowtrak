"""External dependency adapters for trails_service."""

from db.connection import get_pool
from services.trail_matcher import DescentSegmentInput, match_all_descents

__all__ = ["DescentSegmentInput", "get_pool", "match_all_descents"]
