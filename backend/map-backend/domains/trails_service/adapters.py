"""Compatibility shim for trails_service external dependencies."""

from domains.trails_service.infra import DescentSegmentInput, get_trails_conn, match_descents

get_pool_conn = get_trails_conn
match_all_descents = match_descents

__all__ = [
	"DescentSegmentInput",
	"get_pool_conn",
	"get_trails_conn",
	"match_all_descents",
	"match_descents",
]
