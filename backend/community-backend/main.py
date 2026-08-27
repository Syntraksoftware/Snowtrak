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
from shared.openapi_canonical import configure_canonical_openapi
from shared.rate_limiter import add_redis_rate_limiter

from config import get_config
from routes.comments import router as comments_router
from routes.media_routes import router as media_router
from routes.posts_read_routes import list_feed_posts, router as posts_read_router
from routes.posts_write_routes import router as posts_write_router
from routes.subthreads import router as subthreads_router
from services.community_cache import close_community_cache, initialize_community_cache
from services.supabase_client import initialize_community_client

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

config = get_config()


def _get_rate_limit_policies() -> list[dict]:
    """Route-level rate limit policies for community endpoints."""
    default_policies = [
        {
            "path_pattern": "/api/v1/posts",
            "methods": ["POST"],
            "limit": 20,
            "window_seconds": 60,
        },
        {
            "path_pattern": "/api/v1/comments",
            "methods": ["POST"],
            "limit": 60,
            "window_seconds": 60,
        },
        {
            "path_pattern": "/api/v1/subthreads",
            "methods": ["POST"],
            "limit": 10,
            "window_seconds": 60,
        },
        {
            "path_pattern": "/api/v1/*",
            "methods": ["GET"],
            "limit": 200,
            "window_seconds": 60,
        },
    ]
    if config.RATE_LIMIT_POLICIES:
        return config.RATE_LIMIT_POLICIES
    return default_policies


def _log_owned_domains_banner() -> None:
    """Log owned domains and canonical routes at startup."""
    logger.info("=" * 64)
    logger.info("SERVICE OWNERSHIP: community-backend")
    logger.info("domains: community (subthreads/posts/comments)")
    logger.info(
        "routes: /api/v1/feed, /api/v1/subthreads, /api/v1/posts, /api/v1/comments, /api/v1/media"
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
        initialize_community_cache()
        logger.info("✅ Supabase Global Client Instance initialized successfully")
        _log_owned_domains_banner()
    except Exception as e:
        logger.error(f"❌ Failed to initialize services: {e}")
        raise

    yield

    # Shutdown
    await close_community_cache()
    logger.info("Shutting down Community Backend")


# Create FastAPI app
app = FastAPI(
    title="Community Backend API",
    description="Canonical surface: /api/v1/* (feed, subthreads, posts, comments, media)",
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
)

configure_canonical_openapi(
    app,
    service_title="Community Backend API",
    service_version="1.0.0",
    canonical_prefix="/api/v1",
)

# Add request ID middleware (must be before other middleware)
add_request_id_middleware(app)

# Setup exception handlers for standardized error responses
setup_exception_handlers(app)

if config.RATE_LIMIT_ENABLED:
    add_redis_rate_limiter(
        app,
        redis_url=config.RATE_LIMIT_REDIS_URL,
        namespace=config.RATE_LIMIT_NAMESPACE,
        policies=_get_rate_limit_policies(),
        default_limit=config.RATE_LIMIT_DEFAULT_LIMIT,
        default_window_seconds=config.RATE_LIMIT_DEFAULT_WINDOW_SECONDS,
        fail_open=config.RATE_LIMIT_FAIL_OPEN,
    )
    logger.info(
        "Redis rate limiter enabled (namespace=%s, redis=%s)",
        config.RATE_LIMIT_NAMESPACE,
        config.RATE_LIMIT_REDIS_URL,
    )
else:
    logger.warning("Redis rate limiter disabled via RATE_LIMIT_ENABLED=false")

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
    include_in_schema=True,
)

# Mount routers at /api/v1 (new version - standard)
app.include_router(subthreads_router, prefix="/api/v1/subthreads", tags=["subthreads"])
app.include_router(posts_read_router, prefix="/api/v1/posts", tags=["posts"])
app.include_router(posts_write_router, prefix="/api/v1/posts", tags=["posts"])
app.include_router(comments_router, prefix="/api/v1/comments", tags=["comments"])
app.include_router(media_router, prefix="/api/v1/media", tags=["media"])


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
