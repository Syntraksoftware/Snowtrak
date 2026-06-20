"""Shared pipeline status values for activity-backend and workers."""

from __future__ import annotations

from enum import StrEnum


class ProcessingStatus(StrEnum):
    """Lifecycle of an activity through upload and server-side pipeline."""

    pending = "pending"
    uploading = "uploading"
    processing = "processing"
    ready = "ready"
    failed = "failed"
