"""Background Redis Streams consumer for activity pipeline jobs."""

from __future__ import annotations

import asyncio
import logging
import uuid

from config import get_config
from services.pipeline_processor import PipelineProcessor
from services.pipeline_queue import ack_pipeline_job, ensure_consumer_group, read_pipeline_jobs
from services.supabase_client import get_activity_client

logger = logging.getLogger(__name__)


class PipelineWorker:
    def __init__(self, consumer_name: str | None = None) -> None:
        self._consumer_name = consumer_name or f"worker-{uuid.uuid4().hex[:8]}"
        self._running = False

    async def run_forever(self) -> None:
        cfg = get_config()
        if not cfg.REDIS_URL:
            logger.info("REDIS_URL unset; pipeline worker not started")
            return

        ensure_consumer_group()
        self._running = True
        logger.info("Pipeline worker started consumer=%s", self._consumer_name)

        processor = PipelineProcessor(activity_client=get_activity_client())
        while self._running:
            jobs = await asyncio.to_thread(
                read_pipeline_jobs,
                self._consumer_name,
                1,
                5000,
            )
            for job in jobs:
                payload = job["payload"]
                try:
                    await processor.process_uploaded_file(
                        activity_id=payload["activity_id"],
                        user_id=payload["user_id"],
                        storage_key=payload["storage_key"],
                        source_type=payload.get("source_type", "gpx"),
                    )
                    await asyncio.to_thread(ack_pipeline_job, job["id"])
                except Exception:
                    logger.exception(
                        "pipeline job failed message_id=%s activity_id=%s",
                        job["id"],
                        payload.get("activity_id"),
                    )

    def stop(self) -> None:
        self._running = False
