"""
⚠️ DEPRECATION NOTICE: This file is the application definition only.
DO NOT run this file directly.

✅ Use the standardized entry point instead:
   python run.py

Community Backend - FastAPI Application

A standalone microservice for Reddit-like community features.
"""

import logging
import os
import sys
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Add backend directory to path for shared imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from shared import ListResponse, add_request_id_middleware, setup_exception_handlers
from shared.deprecation import COMMUNITY_BACKEND_DEPRECATIONS, add_deprecation_middleware

from config import get_config
from routes.comments import router as comments_router
from routes.media_routes import router as media_router
from routes.posts import router as posts_router
from routes.posts_read_routes import list_feed_posts
from routes.subthreads import router as subthreads_router
from services.supabase_client import initialize_community_client

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

config = get_config()


def _log_owned_domains_banner() -> None:
    """Log owned domains and canonical routes at startup."""
    logger.info("=" * 64)
    logger.info("SERVICE OWNERSHIP: community-backend")
    logger.info("domains: community (subthreads/posts/comments)")
    logger.info(
        "routes: /api/subthreads, /api/posts, /api/comments, /api/posts/comments/batch, /api/posts/{id}/conversation"
    )
    logger.info("=" * 64)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifespan context manager for app startup/shutdown."""
    # Startup
    logger.info(f"Starting Community Backend on {config.HOST}:{config.PORT}")
    logger.info(f"Environment: {config.FASTAPI_ENV}")
    logger.info(f"Debug mode: {config.DEBUG}")

    # Initialize Supabase client at startup (thread-safe, single instance)
    try:
        initialize_community_client()
        logger.info("✅ Supabase Global Client Instance initialized successfully")
        _log_owned_domains_banner()
    except Exception as e:
        logger.error(f"❌ Failed to initialize services: {e}")
        raise

    yield

    # Shutdown
    logger.info("Shutting down Community Backend")


# Create FastAPI app
app = FastAPI(
    title="Community Backend API",
    description="Reddit-like community microservice",
    version="1.0.0",
    lifespan=lifespan,
)

# Add request ID middleware (must be before other middleware)
add_request_id_middleware(app)

# Setup exception handlers for standardized error responses
setup_exception_handlers(app)

# Add deprecation middleware for legacy /api/* routes
add_deprecation_middleware(app, COMMUNITY_BACKEND_DEPRECATIONS)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=config.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["Content-Type", "Authorization", "X-Request-ID"],
)

# Import and include routers
# Canonical global feed endpoint
# Registered directly (not via posts router) to avoid routing precedence with GET /{post_id}.
# IMPORTANT: This is the ONLY official feed endpoint. Clients must use GET /api/v1/feed
# (not /api/v1/posts/feed) to fetch the global feed across all subthreads.
app.add_api_route(
    "/api/v1/feed",
    list_feed_posts,
    methods=["GET"],
    response_model=ListResponse,
    tags=["posts"],
    summary="Global feed (canonical endpoint)",
    description="Fetch all posts across all subthreads, newest first. "
    "This is the only official feed endpoint.",
)

# Mount routers at /api/v1 (new version - standard)
app.include_router(subthreads_router, prefix="/api/v1/subthreads", tags=["subthreads"])
app.include_router(posts_router, prefix="/api/v1/posts", tags=["posts"])
app.include_router(comments_router, prefix="/api/v1/comments", tags=["comments"])
app.include_router(media_router, prefix="/api/v1/media", tags=["media"])

# Legacy /api/* routes deprecated (will be supported for 1 release cycle with deprecation headers)
# These are mounted after v1 routes so v1 takes precedence in routing
# Deprecation headers will be added via middleware or response handlers
app.include_router(subthreads_router, prefix="/api/subthreads", tags=["subthreads_deprecated"])
app.include_router(posts_router, prefix="/api/posts", tags=["posts_deprecated"])
app.include_router(comments_router, prefix="/api/comments", tags=["comments_deprecated"])
app.include_router(media_router, prefix="/api/media", tags=["media_deprecated"])


@app.get("/")
def root():
    """Root endpoint."""
    return {"service": "Community Backend", "version": "1.0.0", "status": "running"}


@app.get("/health")
def health():
    """Health check endpoint."""
    return {"status": "healthy", "service": "community-backend"}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "main:app", host=config.HOST, port=config.PORT, reload=config.DEBUG, log_level="info"
    )
