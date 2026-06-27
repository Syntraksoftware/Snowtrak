"""Legacy query parameter name detection for soft-accept migration."""

from typing import Any

FILTER_MAPPING = {
    "q": "search", "query": "search", "text": "search", "term": "search",
    "activity_type": "type", "entity_type": "type", "kind": "type",
    "from": "start_date", "from_date": "start_date", "start": "start_date",
    "to": "end_date", "to_date": "end_date", "end": "end_date", "until": "end_date",
}


def check_deprecated_params(
    request_params: dict[str, Any], mapping: dict[str, str] = FILTER_MAPPING
) -> list[str]:
    """Return any legacy parameter names present in the request."""
    return [name for name in mapping if name in request_params]
