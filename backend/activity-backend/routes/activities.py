"""Activity router aggregator."""

from fastapi import APIRouter

from routes.activities_list_routes import router as activities_list_router
from routes.activities_management_routes import router as activities_management_router
from routes.activities_social_routes import router as activities_social_router

router = APIRouter(prefix="/api/v1/activities", tags=["activities"])
router.include_router(activities_management_router)
router.include_router(activities_list_router)
router.include_router(activities_social_router)
