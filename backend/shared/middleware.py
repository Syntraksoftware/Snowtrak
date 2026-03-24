"""
Request ID Middleware

Generates and injects a unique request ID for every incoming request.
This enables request tracing across services and helps correlate errors.

The middleware:
1. Checks for X-Request-ID header
2. If present, validates and uses it
3. If absent, generates a new UUID v4
4. Attaches to request.state for downstream access
5. Includes in all responses via exception handlers

Usage:
    from shared.middleware import add_request_id_middleware
    
    app = FastAPI()
    add_request_id_middleware(app)
"""

import uuid
from typing import Callable
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response


REQUEST_ID_HEADER = "X-Request-ID"
REQUEST_ID_ATTR = "request_id"


class RequestIDMiddleware(BaseHTTPMiddleware):
    """
    Middleware to generate and attach request IDs to all incoming requests.
    
    Request IDs are either read from X-Request-ID header or auto-generated.
    They are attached to request.state.request_id for access in handlers.
    """
    
    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        # Check for existing request ID in header
        request_id = request.headers.get(REQUEST_ID_HEADER)
        
        # If not provided, generate a new one
        if not request_id:
            request_id = str(uuid.uuid4())
        
        # Attach to request state for handlers to access
        request.state.request_id = request_id
        
        # Call the next middleware/handler
        response = await call_next(request)
        
        # Add request ID to response headers for client correlation
        response.headers[REQUEST_ID_HEADER] = request_id
        
        return response


def add_request_id_middleware(app):
    """
    Helper function to add request ID middleware to FastAPI app.
    
    Args:
        app: FastAPI application instance
    
    Example:
        app = FastAPI()
        add_request_id_middleware(app)
    """
    app.add_middleware(RequestIDMiddleware)


def get_request_id(request: Request) -> str:
    """
    Helper to retrieve request_id from request state.
    
    Args:
        request: FastAPI Request object
        
    Returns:
        Request ID string
        
    Example:
        @app.get("/")
        async def handler(request: Request):
            req_id = get_request_id(request)
            return {"request_id": req_id}
    """
    return getattr(request.state, REQUEST_ID_ATTR, str(uuid.uuid4()))
