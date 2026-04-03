"""Authentication router aggregator."""

from fastapi import APIRouter

from app.api.v1.auth_login_route import router as auth_login_router
from app.api.v1.auth_refresh_route import router as auth_refresh_router
from app.api.v1.auth_register_route import router as auth_register_router

router = APIRouter(prefix="/auth", tags=["Authentication"])
router.include_router(auth_register_router)
router.include_router(auth_login_router)
router.include_router(auth_refresh_router)
