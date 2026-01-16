"""
API v1 router aggregation.
"""
from fastapi import APIRouter
from app.api.v1 import auth, users, notifications
from app.api.v1.activities import router as activities_router

api_router = APIRouter(prefix="/api/v1")

# Include all v1 routers
api_router.include_router(auth.router)
api_router.include_router(users.router)
api_router.include_router(notifications.router)
api_router.include_router(activities_router)