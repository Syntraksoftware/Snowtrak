"""
FastAPI application factory and startup configuration.
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from contextlib import asynccontextmanager
import sys
import os

# Add backend directory to path for shared imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "../../"))

from app.core.config import settings
from app.core.supabase import supabase_client
from app.api.v1 import api_router
from shared import add_request_id_middleware, setup_exception_handlers


def _print_owned_domains_banner() -> None:
    """Print owned domains and canonical routes at startup."""
    print("SERVICE OWNERSHIP: main-backend")
    print("domains: auth/users, notifications")
    print("routes: /api/v1/auth, /api/v1/users, /api/v1/notifications")



@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan manager."""
    # Startup
    print("🚀 Starting Syntrak Auth API...")
    print(f"📦 Environment: {settings.environment}")
    
    # Display storage backend information
    if supabase_client.is_configured():
        print("💾 Using Supabase database (persistent storage)")
    else:
        print("💾 Using in-memory storage (data resets on restart)")
        print("⚠️ Warning: Supabase not configured. Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in .env")

    _print_owned_domains_banner()
    
    yield
    
    # Shutdown
    print("👋 Shutting down Syntrak Auth API...")


def create_application() -> FastAPI:
    """Application factory - creates and configures FastAPI app."""
    app = FastAPI(
        title=settings.app_name,
        version=settings.app_version,
        description="Authentication API for Syntrak with Supabase integration",
        docs_url="/docs" if settings.debug else None,
        redoc_url="/redoc" if settings.debug else None,
        lifespan=lifespan,
    )
    
    # Add request ID middleware (must be before other middleware)
    add_request_id_middleware(app)
    
    # Setup exception handlers for standardized error responses
    setup_exception_handlers(app)
    
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
