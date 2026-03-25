"""
⚠️ DEPRECATION NOTICE: This file is the application definition only.
DO NOT run this file directly.

✅ Use the standardized entry point instead:
   python run.py

Activity Backend - FastAPI Application
Minimal service for skiing activity records.
"""
import logging
from contextlib import asynccontextmanager
import sys
import os

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Add backend directory to path for shared imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from config import get_config
from services.supabase_client import initialize_activity_client
from shared import add_request_id_middleware, setup_exception_handlers

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)

config = get_config()


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

    yield

    logger.info("Shutting down Activity Backend")


app = FastAPI(
    title="Activity Backend API",
    description="Minimal backend for skiing activity records",
    version="1.0.0",
    lifespan=lifespan,
)

# Add request ID middleware (must be before other middleware)
add_request_id_middleware(app)

# Setup exception handlers for standardized error responses
setup_exception_handlers(app)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=config.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["Content-Type", "Authorization", "X-Request-ID"],
)

# Routers
from routes.activities import router as activities_router

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
