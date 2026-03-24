"""
Deprecation Headers Middleware

Adds appropriate deprecation headers (Deprecation, Sunset, Link) to deprecated API endpoints.
This helps clients understand what endpoints are being phased out and when.

Usage:
    from shared.deprecation import add_deprecation_middleware, DEPRECATION_CONFIG
    
    app = FastAPI()
    add_deprecation_middleware(app)
"""

from datetime import datetime, timedelta
from typing import Dict, List, Tuple
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import Response
from starlette.requests import Request


class DeprecationMiddleware(BaseHTTPMiddleware):
    """
    Middleware to add deprecation headers to deprecated API endpoints.
    
    Checks if the request path matches a deprecated pattern and adds
    Deprecation, Sunset, and Link headers to the response.
    """
    
    def __init__(self, app, deprecation_paths: Dict[str, Dict[str, str]]):
        """
        Args:
            app: FastAPI application instance
            deprecation_paths: Dict mapping deprecated path patterns to deprecation info
                             e.g. {"/api/posts": {"sunset_date": "2026-06-21", "replacement": "/api/v1/posts"}}
        """
        super().__init__(app)
        self.deprecation_paths = deprecation_paths
    
    async def dispatch(self, request: Request, call_next) -> Response:
        response = await call_next(request)
        
        # Check if current request path is deprecated
        for deprecated_path, config in self.deprecation_paths.items():
            if request.url.path.startswith(deprecated_path):
                # Add standard deprecation headers per RFC 8594
                response.headers["Deprecation"] = "true"
                
                # Sunset header: when the endpoint will be removed
                sunset_date = config.get("sunset_date")
                if sunset_date:
                    response.headers["Sunset"] = sunset_date
                
                # Link header: pointer to replacement endpoint
                replacement = config.get("replacement")
                if replacement:
                    response.headers["Link"] = f'<{replacement}>; rel="successor-version"'
                
                # Custom header: migration guide or message
                deprecation_msg = config.get("message")
                if deprecation_msg:
                    response.headers["X-Deprecation-Message"] = deprecation_msg
                
                break
        
        return response


def add_deprecation_middleware(app, deprecation_paths: Dict[str, Dict[str, str]]):
    """
    Helper function to add deprecation middleware to FastAPI app.
    
    Args:
        app: FastAPI application instance
        deprecation_paths: Dict mapping deprecated paths to configuration
        
    Example:
        app = FastAPI()
        deprecation_paths = {
            "/api/posts": {
                "sunset_date": "2026-06-21",
                "replacement": "/api/v1/posts",
                "message": "Use /api/v1/posts instead. Support ends 2026-06-21."
            }
        }
        add_deprecation_middleware(app, deprecation_paths)
    """
    app.add_middleware(DeprecationMiddleware, deprecation_paths=deprecation_paths)


# Deprecation configuration for community-backend
# Legacy /api/* routes deprecated in favor of /api/v1/*
COMMUNITY_BACKEND_DEPRECATIONS = {
    "/api/subthreads": {
        "sunset_date": "Sun, 21 Jun 2026 00:00:00 GMT",
        "replacement": "/api/v1/subthreads",
        "message": "Endpoint moved to /api/v1/subthreads. Support ends 2026-06-21.",
    },
    "/api/posts": {
        "sunset_date": "Sun, 21 Jun 2026 00:00:00 GMT",
        "replacement": "/api/v1/posts",
        "message": "Endpoint moved to /api/v1/posts. Support ends 2026-06-21.",
    },
    "/api/comments": {
        "sunset_date": "Sun, 21 Jun 2026 00:00:00 GMT",
        "replacement": "/api/v1/comments",
        "message": "Endpoint moved to /api/v1/comments. Support ends 2026-06-21.",
    },
}
