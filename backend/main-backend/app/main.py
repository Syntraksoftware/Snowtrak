"""
FastAPI application factory and startup configuration.
"""

import os
import sys
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

# Add backend directory to path for shared imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "../../"))

from shared import add_request_id_middleware, setup_exception_handlers
from shared.openapi_canonical import configure_canonical_openapi
from shared.rate_limiter import add_redis_rate_limiter

from app.api.v1 import api_router
from app.core.config import settings
from app.core.supabase import supabase_client
from app.services.weather import weather_service


def _get_rate_limit_policies() -> list[dict]:
    """Route-level rate limit policies for auth and core endpoints."""
    default_policies = [
        {
            "path_pattern": "/api/v1/auth/register",
            "methods": ["POST"],
            "limit": 5,
            "window_seconds": 60,
        },
        {
            "path_pattern": "/api/v1/auth/login",
            "methods": ["POST"],
            "limit": 10,
            "window_seconds": 60,
        },
        {
            "path_pattern": "/api/v1/auth/refresh",
            "methods": ["POST"],
            "limit": 30,
            "window_seconds": 60,
        },
        {
            "path_pattern": "/api/v1/users/*",
            "methods": ["GET"],
            "limit": 100,
            "window_seconds": 60,
        },
        {
            "path_pattern": "/api/v1/users/*",
            "methods": ["PUT"],
            "limit": 30,
            "window_seconds": 60,
        },
        {
            "path_pattern": "/api/v1/*",
            "methods": ["GET"],
            "limit": 200,
            "window_seconds": 60,
        },
    ]
    if settings.rate_limit_policies:
        return settings.rate_limit_policies
    return default_policies


def _print_owned_domains_banner() -> None:
    """Print owned domains and canonical routes at startup."""
    print("SERVICE OWNERSHIP: main-backend")
    print("domains: auth/users, notifications, weather")
    print("routes: /api/v1/auth, /api/v1/users, /api/v1/notifications, /api/v1/weather")


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan manager."""
    # Startup
    print("🚀 Starting Snowtrak Auth API...")
    print(f"📦 Environment: {settings.environment}")

    # Display storage backend information
    if supabase_client.is_configured():
        print("💾 Using Supabase database (persistent storage)")
    else:
        print("💾 Using in-memory storage (data resets on restart)")
        print(
            "⚠️ Warning: Supabase not configured. Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in .env"
        )

    _print_owned_domains_banner()

    yield

    # Shutdown
    weather_service.close()
    print("👋 Shutting down Snowtrak Auth API...")


def create_application() -> FastAPI:
    """Application factory - creates and configures FastAPI app."""
    app = FastAPI(
        title=settings.app_name,
        version=settings.app_version,
        description="Canonical surface: /api/v1/auth, /api/v1/users, /api/v1/notifications, /api/v1/weather",
        docs_url="/docs" if settings.debug else None,
        redoc_url="/redoc" if settings.debug else None,
        openapi_url="/openapi.json",
        lifespan=lifespan,
    )

    configure_canonical_openapi(
        app,
        service_title=settings.app_name,
        service_version=settings.app_version,
        canonical_prefix="/api/v1",
    )

    # Add request ID middleware (must be before other middleware)
    add_request_id_middleware(app)

    # Setup exception handlers for standardized error responses
    setup_exception_handlers(app)

    # Add Redis rate limiter (before CORS to catch rate limit violations early)
    if settings.rate_limit_enabled:
        add_redis_rate_limiter(
            app,
            redis_url=settings.rate_limit_redis_url,
            namespace=settings.rate_limit_namespace,
            policies=_get_rate_limit_policies(),
            default_limit=settings.rate_limit_default_limit,
            default_window_seconds=settings.rate_limit_default_window_seconds,
            fail_open=settings.rate_limit_fail_open,
        )
        print(
            f"Redis rate limiter enabled (namespace={settings.rate_limit_namespace}, "
            f"redis={settings.rate_limit_redis_url})"
        )
    else:
        print("Redis rate limiter disabled via RATE_LIMIT_ENABLED=false")

    # CORS middleware
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.get_allowed_origins(),
        allow_credentials=True,
        allow_methods=["GET", "POST", "PUT", "DELETE"],
        allow_headers=["Authorization", "Content-Type", "X-Request-ID"],
    )

    # Include API routers
    app.include_router(api_router)

    # Health check endpoint
    @app.get("/health")
    async def health_check():
        return JSONResponse(
            content={
                "status": "healthy",
                "app": settings.app_name,
                "version": settings.app_version,
                "environment": settings.environment,
            }
        )

    return app


# Create app instance
app = create_application()
