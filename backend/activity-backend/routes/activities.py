"""Activity router aggregator."""

from fastapi import APIRouter

from routes.activities_list_routes import router as activities_list_router
from routes.activities_management_routes import router as activities_management_router
from routes.activities_social_routes import router as activities_social_router
from routes.activities_upload_routes import router as activities_upload_router
from routes.stats_routes import router as stats_router

router = APIRouter(prefix="/api/v1/activities", tags=["activities"])
# stats_router must come before management_router so /me/stats is not swallowed
# by the /{activity_id} wildcard.
router.include_router(stats_router)
router.include_router(activities_upload_router)
router.include_router(activities_management_router)
router.include_router(activities_list_router)
router.include_router(activities_social_router)
