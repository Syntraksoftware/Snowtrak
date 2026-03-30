"""Shared helpers for standardized paginated list responses."""
from typing import List

from fastapi import Request

from shared import ListMeta, ListResponse, PaginationMeta, get_request_id


def build_paginated_list_response(
    request: Request,
    items: List,
    limit: int,
    offset: int,
    total: int,
) -> ListResponse:
    """
    Build a standardized list response with pagination metadata.
    Demo: 
    {
        request_id: "abc123",
        pagination: {
            limit: 20,  
            offset: 0,
            total: 100,
            next_cursor: null, ->  identifier for the next page, offset based pagination
            has_next: true
    }
    """
    request_id = get_request_id(request)
    pagination_metadata = PaginationMeta(
        limit=limit,
        offset=offset,
        total=total,
        next_cursor=None,
        has_next=offset + limit < total,
    )
    response_metadata = ListMeta(
        request_id=request_id,
        pagination=pagination_metadata,
    )
    return ListResponse(items=items, meta=response_metadata)
