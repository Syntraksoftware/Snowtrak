"""
Pydantic v2 API contracts mirroring frontend Dart models under `frontend/lib/models/`.

Separate service from google map html service rendering 
Used as the canonical shape for map/track pipeline payloads across services.

Field names use snake_case; JSON matches typical Flutter `json_serializable` output.

json use snake case for the client (elevation_m, recorded_at, etc.)

"""

from __future__ import annotations

from datetime import datetime
from enum import StrEnum
from typing import Annotated, Self


from pydantic import BaseModel, ConfigDict, Field, model_validator




class PointSegmentType(StrEnum):
    lift = "lift"
    run = "run"
    transition = "transition"


class SourceType(StrEnum):
    gpx = "gpx"
    fit = "fit"
    live = "live"


class SegmentType(StrEnum):
    descent = "descent"
    lift = "lift"
    flat = "flat"
    pause = "pause"


class ActivityType(StrEnum):
    alpine = "alpine"
    cross_country = "cross_country"
    freestyle = "freestyle"
    backcountry = "backcountry"
    snowboard = "snowboard"
    other = "other"


# --- Track pipeline (Dart: TrackPoint, ProcessedTrack, Segment) ---

class TrackPointIn(BaseModel):
    """Atomic GPS sample (input). `elevation_m` optional when requesting DEM correction.
    
    DEM Correction: process that uses a digital elevation model (DEM) to correct the elevation of a track point.
    """

    model_config = ConfigDict(extra="forbid") # any extra fields are forbidden

    lat: Annotated[float, Field(ge=-90, le=90)]
    lon: Annotated[float, Field(ge=-180, le=180)]
    elevation_m: float | None = None
    timestamp: datetime
    speed_kmh: float = Field(..., ge=0)
    segment_type: PointSegmentType | None = None


class TrackPointOut(BaseModel):
    """
    Atomic GPS sample (output); elevation from sensor or corrected.
    After DEM correction is applied: 
    """

    model_config = ConfigDict(extra="forbid")

    lat: Annotated[float, Field(ge=-90, le=90)]
    lon: Annotated[float, Field(ge=-180, le=180)]
    elevation_m: float
    timestamp: datetime
    speed_kmh: float = Field(..., ge=0)
    segment_type: PointSegmentType | None = None


class ProcessedTrackIn(BaseModel):
    """Engine 1 normalized track (input)."""

    model_config = ConfigDict(extra="forbid")

    id: str
    points: list[TrackPointIn] = Field(..., min_length=1)
    recorded_at: datetime
    source_type: SourceType


class ProcessedTrackOut(BaseModel):
    """Engine 1 normalized track (output)."""

    model_config = ConfigDict(extra="forbid")

    id: str
    points: list[TrackPointOut] = Field(..., min_length=1)
    recorded_at: datetime
    source_type: SourceType


class SegmentOut(BaseModel):
    """Engine 2 classified slice."""

    model_config = ConfigDict(extra="forbid")

    type: SegmentType
    points: list[TrackPointOut]
    start_index: int = Field(..., ge=0)
    end_index: int = Field(..., ge=0)
    trail_name: str | None = None
    difficulty: str | None = None


# --- Engine 3 stats ---


class ActivityStatsOut(BaseModel):
    """Activity-level aggregates (Engine 3)."""

    model_config = ConfigDict(extra="forbid")

    total_distance_km: float = Field(..., ge=0)
    total_vertical_drop_m: float
    top_speed_kmh: float = Field(..., ge=0)
    avg_speed_kmh: float = Field(..., ge=0)
    moving_time_s: float = Field(..., ge=0, description="Wall-clock moving duration in seconds")
    trail_count: int = Field(..., ge=0, description="Distinct named trails in the activity")


class RunSummaryOut(BaseModel):
    """Per-descent aggregates (Engine 3)."""

    model_config = ConfigDict(extra="forbid")

    distance_km: float = Field(..., ge=0)
    vertical_drop_m: float
    top_speed_kmh: float = Field(..., ge=0)
    avg_speed_kmh: float = Field(..., ge=0)
    moving_time_s: float = Field(..., ge=0)
    trail_name: str | None = None


# --- Engine 5 chart (Dart: FlSpot + LiftBandRange) ---

class ChartSpot(BaseModel):
    """One `fl_chart` sample: x = distance along route, y = elevation (m)."""

    model_config = ConfigDict(extra="forbid")

    x: float
    y: float


class LiftBandRange(BaseModel):
    """Horizontal span (e.g. km) for lift shading on the elevation chart."""

    model_config = ConfigDict(extra="forbid")

    start: float
    end: float


class ElevationChartDataOut(BaseModel):
    """Elevation profile payload for `fl_chart` (Engine 5)."""

    model_config = ConfigDict(extra="forbid")

    spots: list[ChartSpot]
    lift_band_ranges: list[LiftBandRange]
    min_elev_m: float
    max_elev_m: float


# --- Map-backend: elevation correction (batch DEM fill) ---


class ElevationCorrectionRequest(BaseModel):
    """Correct or fill elevations for a sequence of track points."""

    model_config = ConfigDict(extra="forbid")

    points: list[TrackPointIn] = Field(..., min_length=1, max_length=512)


class ElevationCorrectionResponse(BaseModel):
    model_config = ConfigDict(extra="forbid")

    points: list[TrackPointOut]


# --- Trail matching (Engine / resort integration) ---

class TrailMatchRequest(BaseModel):
    """Match track geometry to named trails (implementation-specific)."""

    model_config = ConfigDict(extra="forbid")

    processed_track: ProcessedTrackIn | None = None
    points: list[TrackPointIn] | None = Field(
        None, description="Alternative to processed_track when no Engine 1 id exists yet"
    )
    resort_id: str | None = None

    @model_validator(mode="after")
    def require_track_payload(self) -> Self:
        has_track = self.processed_track is not None
        has_points = self.points is not None and len(self.points) > 0
        if not has_track and not has_points:
            raise ValueError("Provide processed_track or a non-empty points list")
        return self


class TrailMatchResponse(BaseModel):
    model_config = ConfigDict(extra="forbid")

    segments: list[SegmentOut] = Field(default_factory=list)


# --- Activity (Dart: Activity + Location) ---


class LocationIn(BaseModel):
    """Location row for activity create/update payloads."""

    model_config = ConfigDict(extra="forbid")

    id: str | None = None
    activity_id: str | None = None
    latitude: Annotated[float, Field(ge=-90, le=90)]
    longitude: Annotated[float, Field(ge=-180, le=180)]
    altitude: float | None = None
    accuracy: float | None = None
    speed: float | None = None
    timestamp: datetime


class LocationOut(BaseModel):
    model_config = ConfigDict(extra="forbid")

    id: str
    activity_id: str
    latitude: float
    longitude: float
    altitude: float | None = None
    accuracy: float | None = None
    speed: float | None = None
    timestamp: datetime


class ActivityIn(BaseModel):
    """Create/update body aligned with `Activity.toJson` / activity-backend.
    should be processed by the server before creating/ storing the activity"""

    model_config = ConfigDict(extra="forbid")

    type: ActivityType
    name: str | None = None
    description: str | None = None
    distance: float = Field(..., ge=0, description="Meters")
    duration: int = Field(..., ge=0, description="Seconds")
    elevation_gain: float = Field(0, description="Meters")
    start_time: datetime
    end_time: datetime
    average_pace: float = Field(0, ge=0, description="Seconds per km")
    max_pace: float = Field(0, ge=0, description="Seconds per km")
    calories: int | None = Field(None, ge=0)
    is_public: bool = True
    locations: list[LocationIn] = Field(default_factory=list)
    # Optional pipeline attachments (populated when server runs engines)
    processed_track: ProcessedTrackIn | None = None
    segments: list[SegmentOut] | None = None
    stats: ActivityStatsOut | None = None
    run_summaries: list[RunSummaryOut] | None = None
    elevation_chart: ElevationChartDataOut | None = None


class ActivityOut(BaseModel):
    """Stored activity with optional derived pipeline fields."""

    model_config = ConfigDict(extra="forbid")

    id: str
    user_id: str
    type: ActivityType
    name: str | None = None
    description: str | None = None
    distance: float = Field(..., ge=0)
    duration: int = Field(..., ge=0)
    elevation_gain: float = 0
    start_time: datetime
    end_time: datetime
    average_pace: float = 0
    max_pace: float = 0
    calories: int | None = None
    is_public: bool
    created_at: datetime
    locations: list[LocationOut] = Field(default_factory=list)
    processed_track: ProcessedTrackOut | None = None
    segments: list[SegmentOut] | None = None
    stats: ActivityStatsOut | None = None
    run_summaries: list[RunSummaryOut] | None = None
    elevation_chart: ElevationChartDataOut | None = None
