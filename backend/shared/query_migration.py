"""
Query Parameter Migration Helpers

Supports soft-accept of legacy query parameter names during API migration.
Maps old parameter names to canonical versions and tracks usage.

Usage:
    from shared.query_migration import map_legacy_filters, FILTER_MAPPING
    
    # In your route handler
    search_value, deprecated_params = map_legacy_filters(
        request_params=request.query_params,
        mapping=FILTER_MAPPING
    )
"""

from typing import Dict, List, Tuple, Any, Optional
from starlette.requests import Request


# Canonical filter parameter names
CANONICAL_FILTERS = {
    "search": "Full-text search",
    "type": "Entity type filter",
    "start_date": "Start date filter",
    "end_date": "End date filter",
}

# Mapping of legacy parameter names to canonical names
# Format: {"legacy_name": "canonical_name"}
FILTER_MAPPING = {
    # Search variants
    "q": "search",
    "query": "search",
    "text": "search",
    "term": "search",
    
    # Type variants
    "activity_type": "type",
    "entity_type": "type",
    "kind": "type",
    
    # Date variants
    "from": "start_date",
    "from_date": "start_date",
    "start": "start_date",
    
    "to": "end_date",
    "to_date": "end_date",
    "end": "end_date",
    "until": "end_date",
}


def map_legacy_filters(
    request_params: Dict[str, Any],
    mapping: Dict[str, str] = FILTER_MAPPING
) -> Tuple[Dict[str, Any], List[str]]:
    """
    Map legacy query parameter names to canonical names.
    
    Implements soft-accept: legacy parameters are accepted and mapped to canonical names,
    but their usage is tracked and returned.
    
    Args:
        request_params: Query parameters from request (dict-like)
        mapping: Mapping of legacy names to canonical names
        
    Returns:
        Tuple of:
        - remapped_params: Dictionary with legacy params mapped to canonical names
        - deprecated_params: List of deprecated parameter names that were used
        
    Example:
        remapped, deprecated = map_legacy_filters(
            request.query_params,
            mapping={"q": "search", "from": "start_date"}
        )
        # If request had ?q=skiing&from=2026-01-01
        # Returns: ({"search": "skiing", "start_date": "2026-01-01"}, ["q", "from"])
    """
    remapped_params = dict(request_params)
    deprecated_params = []
    
    # Check each legacy name
    for legacy_name, canonical_name in mapping.items():
        if legacy_name in request_params:
            # Track the deprecated parameter
            if legacy_name not in deprecated_params:
                deprecated_params.append(legacy_name)
            
            # Map to canonical name if not already present
            if canonical_name not in remapped_params:
                remapped_params[canonical_name] = request_params[legacy_name]
            
            # Remove the legacy parameter from the remapped dict
            del remapped_params[legacy_name]
    
    return remapped_params, deprecated_params


def get_canonical_filter_value(
    request_params: Dict[str, Any],
    filter_name: str,
    mapping: Dict[str, str] = FILTER_MAPPING,
    default: Any = None
) -> Tuple[Any, bool]:
    """
    Get a single filter value, accepting both canonical and legacy parameter names.
    
    Args:
        request_params: Query parameters from request
        filter_name: Canonical filter name (e.g., "search", "start_date")
        mapping: Mapping of legacy names to canonical names
        default: Default value if parameter not found
        
    Returns:
        Tuple of:
        - value: The filter value (or default)
        - was_deprecated: Whether a deprecated parameter name was used
        
    Example:
        search, deprecated = get_canonical_filter_value(
            request.query_params,
            "search",
            default=None
        )
        # If request had ?q=skiing, returns ("skiing", True)
        # If request had ?search=skiing, returns ("skiing", False)
    """
    # Check for canonical name first
    if filter_name in request_params:
        return request_params[filter_name], False
    
    # Check for legacy names that map to this canonical name
    for legacy_name, canonical in mapping.items():
        if canonical == filter_name and legacy_name in request_params:
            return request_params[legacy_name], True
    
    return default, False


def check_deprecated_params(
    request_params: Dict[str, Any],
    mapping: Dict[str, str] = FILTER_MAPPING
) -> List[str]:
    """
    Check if any deprecated parameters are present in the request.
    
    Args:
        request_params: Query parameters from request
        mapping: Mapping of legacy names to canonical names
        
    Returns:
        List of deprecated parameter names that were found (empty if none)
        
    Example:
        deprecated = check_deprecated_params(request.query_params)
        if deprecated:
            print(f"Using deprecated parameters: {deprecated}")
    """
    deprecated = []
    for legacy_name in mapping.keys():
        if legacy_name in request_params:
            deprecated.append(legacy_name)
    return deprecated
