"""Maps router aggregator."""

from fastapi import APIRouter

from routes.maps_dynamic_routes import router as maps_dynamic_router
from routes.maps_static_routes import router as maps_static_router

router = APIRouter(prefix="/api/maps", tags=["maps"])
router.include_router(maps_static_router)
router.include_router(maps_dynamic_router)
