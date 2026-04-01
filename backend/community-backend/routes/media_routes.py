"""Upload media for community posts/comments (Supabase Storage)."""
import logging
import os
import sys

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from middleware.auth import get_current_user
from pydantic import BaseModel
from services.constants.media_constants import (
    BUCKET_MISSING_MSG,
    STORAGE_MSG,
    TOO_LARGE_MSG,
    UNSUPPORTED_MSG,
)
from services.supabase_client import get_community_client

logger = logging.getLogger(__name__)
router = APIRouter()


class MediaUploadResponse(BaseModel):
    url: str


@router.post("/upload", response_model=MediaUploadResponse, status_code=status.HTTP_201_CREATED)
async def upload_community_media(
    file: UploadFile = File(...),
    user_id: str = Depends(get_current_user),
):
    """Single-file upload; returns public URL for use in post/comment create."""
    community_client = get_community_client()
    try:
        raw = await file.read()
        if not raw:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Empty file",
            )

        content_type = file.content_type or "application/octet-stream"
        name = (file.filename or "upload").lower()
        extension = name.rsplit(".", 1)[-1] if "." in name else "bin"

        result = community_client.upload_community_media(
            user_id=user_id,
            file_bytes=raw,
            content_type=content_type,
            extension=extension,
        )
        if result.error == "too_large":
            raise HTTPException(
                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                detail=TOO_LARGE_MSG,
            )
        if result.error == "unsupported_type":
            raise HTTPException(
                status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
                detail=UNSUPPORTED_MSG,
            )
        if result.error == "bucket_not_found":
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail=BUCKET_MISSING_MSG,
            )
        if result.error == "storage_error":
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail=STORAGE_MSG,
            )
        if not result.url:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Upload failed",
            )
        return MediaUploadResponse(url=result.url)
    except HTTPException:
        raise
    except Exception as exc:
        logger.exception("upload_community_media: %s", exc)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal Server Error",
        )
