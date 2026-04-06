"""
FastAPI application factory for the map service (routers + CORS + lifespan).

Used by ``map-backend/main.py`` (``uvicorn main:app``) and ``backend/main.py`` (unified entry).
"""

from __future__ import annotations

import logging
import os
import sys
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

_this_dir = Path(__file__).resolve().parent
if not (_this_dir / "db" / "connection.py").exists():
    _backend_root = _this_dir.parent
    sys.path.insert(0, str(_backend_root))

from apscheduler.schedulers.asyncio import AsyncIOScheduler
from config import get_config
from db.connection import close_pool, create_pool, get_pool
from domains.activities_service.api import router as activities_router
from domains.elevation_dem_service.api import router as elevation_dem_router
from domains.sync_worker_service.job import run_openskimap_sync
from domains.trails_service.api import router as trails_router
from services.storage_backend import get_storage_health, initialize_storage_backend
from zoneinfo import ZoneInfo

logger = logging.getLogger(__name__)


async def _openskimap_scheduled_sync() -> None:
    cfg = get_config()
    if not cfg.openskimap_sync_armed:
        return
    pool = get_pool()
    if pool is None:
        logger.warning("OpenSkiMap sync skipped: asyncpg pool not available")
        return
    try:
        async with pool.acquire() as conn:
            n = await run_openskimap_sync(
                conn,
                url=cfg.OPENSKIMAP_RUNS_GEOJSON_URL,
            )
            logger.info("OpenSkiMap sync finished (%d runs)", n)
    except Exception:
        logger.exception("OpenSkiMap scheduled sync failed")


@asynccontextmanager
async def lifespan(_app: FastAPI) -> AsyncIterator[None]:
    cfg = get_config()
    logger.info("Starting Map Backend on %s:%s", cfg.HOST, cfg.PORT)
    logger.info("Environment: %s | Debug: %s", cfg.FASTAPI_ENV, cfg.DEBUG)

    try:
        initialize_storage_backend()
        logger.info("Storage backend initialized successfully")
    except Exception as e:
        logger.error("Failed to initialize storage backend: %s", e)
        raise

    dsn = os.environ.get("SYNTRAK_DATABASE_URL")
    if dsn:
        await create_pool(dsn=dsn)
    elif cfg.MAP_STORAGE_BACKEND == "postgis":
        await create_pool(dsn=cfg.postgis_dsn)
    else:
        await create_pool()

    scheduler: AsyncIOScheduler | None = None
    if cfg.openskimap_sync_armed:
        scheduler = AsyncIOScheduler(timezone=ZoneInfo("UTC"))
        scheduler.add_job(
            _openskimap_scheduled_sync,
            "cron",
            hour=3,
            minute=0,
            id="openskimap_ski_runs_sync",
            replace_existing=True,
        )
        scheduler.start()
        logger.info("OpenSkiMap ski_runs sync scheduled daily at 03:00 UTC")

    yield

    if scheduler is not None:
        scheduler.shutdown(wait=False)

    await close_pool()
    logger.info("Shutting down Map Backend")


def create_app() -> FastAPI:
    """Build FastAPI app with all map routers and CORS (fresh ``get_config()`` per call)."""
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    )
    cfg = get_config()
    app = FastAPI(
        title="Map Backend API",
        description="Service for elevation, trail matching, and map activity persistence",
        version="1.0.0",
        lifespan=lifespan,
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=cfg.CORS_ORIGINS,
        allow_credentials=True,
        allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        allow_headers=["Content-Type", "Authorization"],
    )

    app.include_router(elevation_dem_router)
    app.include_router(trails_router)
    app.include_router(activities_router)

    @app.get("/")
    def root() -> dict[str, str]:
        return {"service": "Map Backend", "status": "running", "version": "1.0.0"}

    @app.get("/health")
    def health() -> dict:
        storage = get_storage_health()
        st = "healthy" if storage.get("status") == "healthy" else "degraded"
        return {
            "status": st,
            "service": "map-backend",
            "storage": storage,
        }

    return app
