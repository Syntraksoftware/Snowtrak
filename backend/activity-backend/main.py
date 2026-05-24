"""
⚠️ DEPRECATION NOTICE: This file is the application definition only.
DO NOT run this file directly.

✅ Use the standardized entry point instead:
   python run.py

Activity Backend - FastAPI Application
Minimal service for skiing activity records.
"""

import asyncio
import logging
import os
import sys
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Add backend directory to path for shared imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from shared import add_request_id_middleware, setup_exception_handlers
from shared.openapi_canonical import configure_canonical_openapi
from shared.rate_limiter import add_redis_rate_limiter

from config import get_config
from routes.activities import router as activities_router
from services.pipeline_worker import PipelineWorker
from services.supabase_client import initialize_activity_client

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)

config = get_config()


def _get_rate_limit_policies() -> list[dict]:
    """Route-level rate limit policies for activity endpoints."""
    default_policies = [
        {
            "path_pattern": "/api/v1/activities",
            "methods": ["POST"],
            "limit": 30,
            "window_seconds": 60,
        },
        {
            "path_pattern": "/api/v1/activities/*",
            "methods": ["GET", "PUT", "DELETE"],
            "limit": 100,
            "window_seconds": 60,
        },
    ]
    if config.RATE_LIMIT_POLICIES:
        return config.RATE_LIMIT_POLICIES
    return default_policies


def _log_owned_domains_banner() -> None:
    """Log owned domains and canonical routes at startup."""
    logger.info("SERVICE OWNERSHIP: activity-backend")
    logger.info("domains: activities")
    logger.info("routes: /api/v1/activities")


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup/shutdown lifecycle."""
    logger.info(f"Starting Activity Backend on {config.HOST}:{config.PORT}")
    logger.info(f"Environment: {config.FASTAPI_ENV} | Debug: {config.DEBUG}")

    # Initialize Supabase client once at startup
    initialize_activity_client()
    _log_owned_domains_banner()

    worker = PipelineWorker()
    worker_task = asyncio.create_task(worker.run_forever())

    yield

    worker.stop()
    worker_task.cancel()
    try:
        await worker_task
    except asyncio.CancelledError:
        pass
    logger.info("Shutting down Activity Backend")


app = FastAPI(
    title="Activity Backend API",
    description="Canonical surface: /api/v1/activities",
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
)

configure_canonical_openapi(
    app,
    service_title="Activity Backend API",
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

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=config.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["Content-Type", "Authorization", "X-Request-ID"],
)

# Routers
app.include_router(activities_router)


@app.get("/")
def root():
    return {"service": "Activity Backend", "status": "running"}


@app.get("/health")
def health():
    return {"status": "healthy", "service": "activity-backend"}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "main:app",
        host=config.HOST,
        port=config.PORT,
        reload=config.DEBUG,
        log_level="info",
    )
