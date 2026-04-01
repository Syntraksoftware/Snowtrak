"""Users router aggregator."""
from fastapi import APIRouter

from app.api.v1.users_account_routes import router as users_account_router
from app.api.v1.users_avatar_routes import router as users_avatar_router
from app.api.v1.users_profile_routes import router as users_profile_router

router = APIRouter(prefix="/users", tags=["Users"])
router.include_router(users_account_router)
router.include_router(users_profile_router)
router.include_router(users_avatar_router)
