"""
Shared modules across all backend services.
"""

from .contracts import (
    ERROR_CODES,
    ErrorDetails,
    ErrorResponse,
    ListMeta,
    ListResponse,
    PaginationMeta,
    ResponseMeta,
    SuccessResponse,
)
from .exception_handlers import (
    setup_exception_handlers,
)
from .middleware import (
    RequestIDMiddleware,
    add_request_id_middleware,
    get_request_id,
)
from .track_pipeline_schemas import (
    ActivityIn,
    ActivityOut,
    ActivityStatsOut,
    ActivityType,
    ChartSpot,
    ElevationChartDataOut,
    ElevationCorrectionRequest,
    ElevationCorrectionResponse,
    LiftBandRange,
    LocationIn,
    LocationOut,
    PointSegmentType,
    ProcessedTrackIn,
    ProcessedTrackOut,
    RunSummaryOut,
    SegmentOut,
    SegmentType,
    SourceType,
    TrackPointIn,
    TrackPointOut,
    TrailMatchRequest,
    TrailMatchResponse,
)

__all__ = [
    # Contracts
    "ErrorResponse",
    "SuccessResponse",
    "ListResponse",
    "ListMeta",
    "ResponseMeta",
    "PaginationMeta",
    "ErrorDetails",
    "ERROR_CODES",
    # Track / map pipeline (Pydantic v2)
    "PointSegmentType",
    "SourceType",
    "SegmentType",
    "ActivityType",
    "TrackPointIn",
    "TrackPointOut",
    "ProcessedTrackIn",
    "ProcessedTrackOut",
    "SegmentOut",
    "ActivityStatsOut",
    "RunSummaryOut",
    "ChartSpot",
    "LiftBandRange",
    "ElevationChartDataOut",
    "ElevationCorrectionRequest",
    "ElevationCorrectionResponse",
    "TrailMatchRequest",
    "TrailMatchResponse",
    "LocationIn",
    "LocationOut",
    "ActivityIn",
    "ActivityOut",
    # Middleware
    "add_request_id_middleware",
    "get_request_id",
    "RequestIDMiddleware",
    # Exception handlers
    "setup_exception_handlers",
]
