"""Presigned upload + async pipeline enqueue (Phase 3)."""

from __future__ import annotations

import logging
from datetime import datetime
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException, status

from config import get_config
from middleware.auth import get_current_user
from models import UploadCompleteResponse, UploadUrlRequest, UploadUrlResponse
from services.pipeline_processor import PipelineProcessor, build_storage_key
from services.pipeline_queue import publish_pipeline_job
from services.supabase_client import get_activity_client
from shared.pipeline_enums import ProcessingStatus

logger = logging.getLogger(__name__)
router = APIRouter()


@router.post("/upload-url", response_model=UploadUrlResponse, status_code=status.HTTP_201_CREATED)
async def create_upload_url(
    body: UploadUrlRequest,
    user_id: str = Depends(get_current_user),
):
    """Reserve a feed activity row and return a presigned Supabase Storage upload URL."""
    activity_client = get_activity_client()
    config = get_config()

    activity_id = str(uuid4())
    storage_key = build_storage_key(user_id, activity_id, body.source_type)
    now = datetime.utcnow().isoformat() + "Z"

    created = activity_client.create_activity(
        user_id=user_id,
        name=body.name or "Processing upload…",
        start_time=now,
        end_time=now,
        activity_type=body.activity_type,
        gps_path=[],
        duration_seconds=0,
        distance_meters=0.0,
        elevation_gain_meters=0.0,
        visibility="private",
        processing_status=ProcessingStatus.pending,
        storage_key=storage_key,
        activity_id=activity_id,
    )
    if not created:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create placeholder activity",
        )

    try:
        signed = activity_client.create_signed_upload_url(
            config.ACTIVITY_UPLOAD_BUCKET,
            storage_key,
            config.UPLOAD_URL_EXPIRES_S,
        )
    except Exception as exc:
        logger.exception("signed upload URL failed activity_id=%s", activity_id)
        activity_client.delete_activity(activity_id, user_id)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create upload URL",
        ) from exc

    activity_client.update_activity_pipeline_fields(
        activity_id,
        user_id,
        processing_status=ProcessingStatus.uploading,
    )

    return UploadUrlResponse(
        activity_id=activity_id,
        upload_url=signed.get("signed_url") or signed.get("signedUrl") or "",
        storage_key=storage_key,
        token=signed.get("token"),
        processing_status=ProcessingStatus.uploading,
    )


@router.post(
    "/{activity_id}/upload-complete",
    response_model=UploadCompleteResponse,
    status_code=status.HTTP_202_ACCEPTED,
)
async def upload_complete(
    activity_id: str,
    user_id: str = Depends(get_current_user),
):
    """Client finished uploading raw file — enqueue or run pipeline inline."""
    activity_client = get_activity_client()
    record = activity_client.get_activity_by_id(activity_id)
    if not record or str(record.get("user_id")) != user_id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Activity not found")

    storage_key = record.get("storage_key")
    if not storage_key:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Activity has no storage_key; request upload-url first",
        )

    source_type = "fit" if str(storage_key).endswith(".fit") else "gpx"
    job_payload = {
        "event": "file_uploaded",
        "activity_id": activity_id,
        "user_id": user_id,
        "storage_key": storage_key,
        "source_type": source_type,
    }

    message_id = publish_pipeline_job(job_payload)
    processor = PipelineProcessor(activity_client=activity_client)

    if message_id is None:
        await processor.process_uploaded_file(
            activity_id=activity_id,
            user_id=user_id,
            storage_key=storage_key,
            source_type=job_payload["source_type"],
        )
        final_status = ProcessingStatus.ready
        message = "Pipeline processing completed"
    else:
        activity_client.update_activity_pipeline_fields(
            activity_id,
            user_id,
            processing_status=ProcessingStatus.processing,
        )
        final_status = ProcessingStatus.processing
        message = "Pipeline processing queued"

    return UploadCompleteResponse(
        activity_id=activity_id,
        processing_status=final_status,
        message=message,
    )
