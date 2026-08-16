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
from domains.activities_service.infra import get_activities_conn as activities_conn_impl
from domains.activities_service.infra import upload_thumbnail as thumbnail_upload_impl
from domains.activities_service.ports import set_activities_conn_provider, set_thumbnail_uploader
from domains.elevation_dem_service.api import router as elevation_dem_router
from domains.elevation_dem_service.infra import correct_dem_batch
from domains.elevation_dem_service.ports import set_batch_correct_provider
from domains.sync_worker_service.job import run_openskimap_sync
from domains.sync_worker_service.infra import run_sync as sync_runner_impl
from domains.sync_worker_service.ports import set_sync_runner_provider
from domains.trails_service.api import router as trails_router
from domains.trails_service.infra import get_trails_conn as trails_conn_impl
from domains.trails_service.ports import set_trails_conn_provider
from services.storage_backend import get_storage_health, initialize_storage_backend
from shared.rate_limiter import add_redis_rate_limiter
from shared.openapi_canonical import configure_canonical_openapi
from zoneinfo import ZoneInfo

logger = logging.getLogger(__name__)

V1_MAP_PREFIX = "/api/v1/map"


def _get_rate_limit_policies() -> list[dict]:
    """Route-level default policies. Specific routes should come first."""
    cfg = get_config()
    default_policies = [
        {
            "path_pattern": "/api/v1/map/elevation/correct",
            "methods": ["POST"],
            "limit": 30,
            "window_seconds": 60,
        },
        {
            "path_pattern": "/api/v1/map/activities",
            "methods": ["POST"],
            "limit": 30,
            "window_seconds": 60,
        },
        {
            "path_pattern": "/api/v1/map/activities/*",
            "methods": ["GET", "PUT", "DELETE"],
            "limit": 100,
            "window_seconds": 60,
        },
    ]

    if cfg.RATE_LIMIT_POLICIES:
        return cfg.RATE_LIMIT_POLICIES

    return default_policies


set_activities_conn_provider(activities_conn_impl)
set_thumbnail_uploader(thumbnail_upload_impl)
set_trails_conn_provider(trails_conn_impl)
set_batch_correct_provider(correct_dem_batch)
set_sync_runner_provider(sync_runner_impl)


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

    dsn = cfg.SYNTRAK_DATABASE_URL or os.environ.get("SYNTRAK_DATABASE_URL")
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
        description="Canonical surface: /api/v1/map/* (elevation, trails, map activities)",
        version="1.0.0",
        lifespan=lifespan,
        docs_url="/docs",
        redoc_url="/redoc",
        openapi_url="/openapi.json",
    )

    configure_canonical_openapi(
        app,
        service_title="Map Backend API",
        service_version="1.0.0",
        canonical_prefix=V1_MAP_PREFIX,
    )

    if cfg.RATE_LIMIT_ENABLED:
        add_redis_rate_limiter(
            app,
            redis_url=cfg.RATE_LIMIT_REDIS_URL,
            namespace=cfg.RATE_LIMIT_NAMESPACE,
            policies=_get_rate_limit_policies(),
            default_limit=cfg.RATE_LIMIT_DEFAULT_LIMIT,
            default_window_seconds=cfg.RATE_LIMIT_DEFAULT_WINDOW_SECONDS,
            fail_open=cfg.RATE_LIMIT_FAIL_OPEN,
        )
        logger.info(
            "Redis rate limiter enabled (namespace=%s, redis=%s)",
            cfg.RATE_LIMIT_NAMESPACE,
            cfg.RATE_LIMIT_REDIS_URL,
        )
    else:
        logger.warning("Redis rate limiter disabled via RATE_LIMIT_ENABLED=false")

    app.add_middleware(
        CORSMiddleware,
        allow_origins=cfg.CORS_ORIGINS,
        allow_credentials=True,
        allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        allow_headers=["Content-Type", "Authorization"],
    )

    # Canonical v1 map routes
    app.include_router(elevation_dem_router, prefix=V1_MAP_PREFIX)
    app.include_router(trails_router, prefix=V1_MAP_PREFIX)
    app.include_router(activities_router, prefix=V1_MAP_PREFIX)

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
