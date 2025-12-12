"""
FastAPI application factory and startup configuration.
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from contextlib import asynccontextmanager
from app.core.config import settings
from app.core.supabase import supabase_client
from app.api.v1 import api_router


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
        print("⚠️  Warning: Supabase not configured. Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in .env")
    
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
    
    # CORS middleware
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.get_allowed_origins(),
        allow_credentials=True,
        allow_methods=["GET", "POST", "PUT", "DELETE"],
        allow_headers=["Authorization", "Content-Type"],
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
