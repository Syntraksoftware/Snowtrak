"""Post router aggregator."""
from fastapi import APIRouter

from routes.posts_read_routes import router as posts_read_router
from routes.posts_write_routes import router as posts_write_router

router = APIRouter()
router.include_router(posts_write_router)
router.include_router(posts_read_router)
