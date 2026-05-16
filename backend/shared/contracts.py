"""
Shared API Contract Models

Standardized request/response envelopes, error formats, and pagination models
across all backend services (main-backend, activity-backend, community-backend).

Defines canonical API contract to ensure consistent behavior across service boundaries and prevent frontend drift.

Usage:
    from shared.contracts import ErrorResponse, SuccessResponse, PaginationMeta

    # Error response
    error = ErrorResponse(
        code="VALIDATION_ERROR",
        message="Request validation failed",
        details={"email": ["Invalid email format"]},
        request_id="req-123abc"
    )

    Error code possible: "VALIDATION_ERROR", "UNAUTHORIZED", "NOT_FOUND", "INTERNAL_SERVER_ERROR"

    # Success response with pagination
    success = SuccessResponse(
        data={"items": [...], "total": 50},
        meta=PaginationMeta(limit=20, offset=0, total=50, next_cursor="abc123")
    )
"""

from datetime import datetime
from typing import Any

from pydantic import BaseModel, Field


class PaginationMeta(BaseModel):
    """
    Standardized pagination metadata for list responses.

    Attributes:
        limit: Number of items returned per page (query parameter)
        offset: Starting position in the result set (query parameter)
        total: Total number of items available
        next_cursor: Opaque cursor for cursor-based pagination (next page start)
        has_next: Whether more items exist after current page
    """

    limit: int = Field(ge=1, le=200, description="Items per page")
    offset: int = Field(ge=0, description="Starting position")
    total: int = Field(ge=0, description="Total items available")
    next_cursor: str | None = Field(None, description="Cursor for next page")
    has_next: bool = Field(description="More items available after this page")


class ErrorDetails(BaseModel):
    """
    Flexible error details that support field-level or structured error reporting.

    Can be:
    - Validation errors: {"field_name": ["error1", "error2"]}
    - System errors: {"error_code": "DB_CONNECTION", "trace_id": "trace-123"}
    - Generic: {"message": "Additional error context"}
    """

    class Config:
        extra = "allow"  # Allow arbitrary keys for flexibility


class ErrorResponse(BaseModel):
    """
    Standardized error response envelope.

    All error responses must include: code, message, details, and request_id.
    The request_id is essential for debugging and tracing.

    Attributes:
        code: Machine-readable error code (e.g., "VALIDATION_ERROR", "UNAUTHORIZED")
        message: Human-readable error message
        details: Structured error details (object for flexibility)
        request_id: Unique identifier for this request (for debugging)
        timestamp: ISO 8601 timestamp of error occurrence
    """

    code: str = Field(description="Machine-readable error code")
    message: str = Field(description="Human-readable error message")
    details: dict[str, Any] | list[str] | str = Field(
        description="Structured error details (object, list, or string)"
    )
    request_id: str = Field(description="Unique request identifier for tracing")
    timestamp: datetime | None = Field(
        default_factory=datetime.utcnow, description="Error timestamp in ISO 8601 format"
    )


class ResponseMeta(BaseModel):
    """
    Metadata included in all success responses.

    Attributes:
        request_id: Unique identifier matching corresponding error responses
        timestamp: Response generation time
        deprecated_params: List of deprecated parameters used in this request
    """

    request_id: str = Field(description="Request identifier for correlation")
    timestamp: datetime | None = Field(
        default_factory=datetime.utcnow, description="Response timestamp"
    )
    deprecated_params: list[str] | None = Field(
        None, description="Deprecated parameters used (soft-accept migration indication)"
    )
    deprecation_info: str | None = Field(
        None, description="Deprecation message or link to migration guide"
    )


class SuccessResponse(BaseModel):
    """
    Standardized success response envelope.

    All successful responses use this wrapper with data + metadata separation.

    Attributes:
        data: The actual response payload (any structure)
        meta: StandardResponseMeta with request_id, timestamp, and migration hints
    """

    data: Any = Field(description="Response payload")
    meta: ResponseMeta = Field(description="Response metadata")


class ListMeta(ResponseMeta):
    """
    Metadata for paginated list responses (extends ResponseMeta with pagination).

    Attributes:
        pagination: PaginationMeta with limit, offset, total, next_cursor, has_next
    """

    pagination: PaginationMeta = Field(description="Pagination metadata")


class ListResponse(BaseModel):
    """
    Standardized paginated list response.

    All list endpoints must return items in this envelope with pagination metadata.

    Attributes:
        items: List of actual items
        meta: ListMeta with pagination and request tracking
    """

    items: list[Any] = Field(description="List of items")
    meta: ListMeta = Field(description="Pagination and metadata")


# Backward compatibility aliases (for phased migration)
PaginatedResponse = ListResponse
DataResponse = SuccessResponse


# Error code constants (canonical error codes across all services)
ERROR_CODES = {
    # 4xx - Client errors
    "VALIDATION_ERROR": "Request validation failed",
    "UNAUTHORIZED": "Authentication required",
    "FORBIDDEN": "Insufficient permissions",
    "NOT_FOUND": "Resource not found",
    "CONFLICT": "Resource conflict (e.g., duplicate)",
    "DEPRECATED_PARAM": "Using deprecated parameter",
    # 5xx - Server errors
    "INTERNAL_ERROR": "Internal server error",
    "SERVICE_UNAVAILABLE": "Service temporarily unavailable",
    "DATABASE_ERROR": "Database operation failed",
}
