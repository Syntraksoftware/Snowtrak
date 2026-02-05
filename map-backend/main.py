"""
Map Backend - FastAPI Application
Service for static map images and elevation correction.
"""
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from config import get_config
from services.supabase_client import initialize_map_client

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)

config = get_config()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup/shutdown lifecycle."""
    logger.info(f"Starting Map Backend on {config.HOST}:{config.PORT}")
    logger.info(f"Environment: {config.FASTAPI_ENV} | Debug: {config.DEBUG}")

    # Initialize Supabase client once at startup
    try:
        initialize_map_client()
        logger.info("✅ Supabase client initialized successfully")
    except Exception as e:
        logger.error(f"❌ Failed to initialize Supabase client: {e}")
        raise

    yield

    logger.info("Shutting down Map Backend")


app = FastAPI(
    title="Map Backend API",
    description="Service for static map images and elevation correction",
    version="1.0.0",
    lifespan=lifespan,
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=config.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["Content-Type", "Authorization"],
)

# Routers
from routes.maps import router as maps_router
from routes.elevation import router as elevation_router

app.include_router(maps_router)
app.include_router(elevation_router)


@app.get("/")
def root():
    return {"service": "Map Backend", "status": "running", "version": "1.0.0"}


@app.get("/health")
def health():
    return {"status": "healthy", "service": "map-backend"}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "main:app",
        host=config.HOST,
        port=config.PORT,
        reload=config.DEBUG,
        log_level="info",
    )
