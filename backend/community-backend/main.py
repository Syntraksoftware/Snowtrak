"""
⚠️ DEPRECATION NOTICE: This file is the application definition only.
DO NOT run this file directly.

✅ Use the standardized entry point instead:
   python run.py

Community Backend - FastAPI Application

A standalone microservice for Reddit-like community features.
"""
import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import logging

from config import get_config
from services.supabase_client import initialize_community_client

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

config = get_config()


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
    lifespan=lifespan
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=config.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["Content-Type", "Authorization"],
)

# Import and include routers
from routes.subthreads import router as subthreads_router
from routes.posts import router as posts_router
from routes.comments import router as comments_router

app.include_router(subthreads_router, prefix="/api/subthreads", tags=["subthreads"])
app.include_router(posts_router, prefix="/api/posts", tags=["posts"])
app.include_router(comments_router, prefix="/api/comments", tags=["comments"])


@app.get("/")
def root():
    """Root endpoint."""
    return {
        "service": "Community Backend",
        "version": "1.0.0",
        "status": "running"
    }


@app.get("/health")
def health():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "service": "community-backend"
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host=config.HOST,
        port=config.PORT,
        reload=config.DEBUG,
        log_level="info"
    )
