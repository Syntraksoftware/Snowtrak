"""
Global Exception Handlers

Converts all exceptions to standardized ErrorResponse format with request_id tracking.

This module provides:
1. HTTPException handler - converts FastAPI HTTPException to ErrorResponse
2. Pydantic ValidationError handler - converts validation errors to ErrorResponse
3. Generic exception handler - catches unexpected errors and returns 500 response

Usage:
    from shared.exception_handlers import setup_exception_handlers
    
    app = FastAPI()
    setup_exception_handlers(app)
"""

import logging
from typing import Dict, Any
from starlette.requests import Request
from starlette.responses import JSONResponse
from fastapi import FastAPI
from fastapi.exceptions import HTTPException
from pydantic import ValidationError

from .contracts import ErrorResponse, ERROR_CODES
from .middleware import get_request_id


logger = logging.getLogger(__name__)


def get_error_code_from_status(status_code: int) -> str:
    """Map HTTP status code to error code constant."""
    status_to_code = {
        400: "VALIDATION_ERROR",
        401: "UNAUTHORIZED",
        403: "FORBIDDEN",
        404: "NOT_FOUND",
        409: "CONFLICT",
        500: "INTERNAL_ERROR",
        503: "SERVICE_UNAVAILABLE",
    }
    return status_to_code.get(status_code, "INTERNAL_ERROR")


def format_validation_details(errors: list) -> Dict[str, Any]:
    """
    Convert Pydantic ValidationError into structured field-level details.
    
    Args:
        errors: List of validation error dicts from pydantic
        
    Returns:
        Dictionary mapping field names to error messages
        
    Example:
        {"email": ["Invalid email format"], "age": ["Must be >= 0"]}
    """
    details = {}
    for error in errors:
        field_path = ".".join(str(loc) for loc in error["loc"][1:])  # Skip 'body'
        if field_path not in details:
            details[field_path] = []
        details[field_path].append(error["msg"])
    return details


async def http_exception_handler(request: Request, exc: HTTPException) -> JSONResponse:
    """
    Convert FastAPI HTTPException to standardized ErrorResponse.
    
    Args:
        request: Starlette Request
        exc: HTTPException from FastAPI
        
    Returns:
        JSONResponse with ErrorResponse envelope
    """
    request_id = get_request_id(request)
    
    # Extract error code from exception detail if it's a dict, else infer from status
    error_code = ERROR_CODES.get(
        get_error_code_from_status(exc.status_code),
        "INTERNAL_ERROR"
    )
    
    # Build error response
    error_response = ErrorResponse(
        code=error_code,
        message=exc.detail if isinstance(exc.detail, str) else "An error occurred",
        details=exc.detail if isinstance(exc.detail, dict) else str(exc.detail),
        request_id=request_id,
    )
    
    return JSONResponse(
        status_code=exc.status_code,
        content=error_response.model_dump(mode="json", by_alias=True),
    )


async def validation_error_handler(request: Request, exc: ValidationError) -> JSONResponse:
    """
    Convert Pydantic ValidationError to standardized ErrorResponse.
    
    Args:
        request: Starlette Request
        exc: Pydantic ValidationError
        
    Returns:
        JSONResponse with ErrorResponse envelope
    """
    request_id = get_request_id(request)
    
    # Format validation errors by field
    details = format_validation_details(exc.errors())
    
    error_response = ErrorResponse(
        code="VALIDATION_ERROR",
        message="Request validation failed",
        details=details,
        request_id=request_id,
    )
    
    return JSONResponse(
        status_code=400,
        content=error_response.model_dump(mode="json", by_alias=True),
    )


async def generic_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    """
    Catch-all handler for unexpected exceptions.
    
    Args:
        request: Starlette Request
        exc: Any unhandled exception
        
    Returns:
        JSONResponse with ErrorResponse envelope (500 Internal Error)
    """
    request_id = get_request_id(request)
    
    # Log the exception for debugging
    logger.exception(
        f"Unhandled exception in request {request_id}",
        exc_info=exc,
        extra={"request_id": request_id, "path": request.url.path}
    )
    
    error_response = ErrorResponse(
        code="INTERNAL_ERROR",
        message="An unexpected error occurred",
        details={"error_type": exc.__class__.__name__},
        request_id=request_id,
    )
    
    return JSONResponse(
        status_code=500,
        content=error_response.model_dump(mode="json", by_alias=True),
    )


def setup_exception_handlers(app: FastAPI):
    """
    Register all exception handlers with a FastAPI app.
    
    Args:
        app: FastAPI application instance
        
    Example:
        app = FastAPI()
        setup_exception_handlers(app)
    """
    app.add_exception_handler(HTTPException, http_exception_handler)
    app.add_exception_handler(ValidationError, validation_error_handler)
    app.add_exception_handler(Exception, generic_exception_handler)
