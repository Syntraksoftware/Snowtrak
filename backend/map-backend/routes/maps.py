"""Maps router aggregator (static previews only; interactive maps use the Flutter client)."""

from fastapi import APIRouter

from routes.maps_static_routes import router as maps_static_router

router = APIRouter(prefix="/api/maps", tags=["maps"])
router.include_router(maps_static_router)
