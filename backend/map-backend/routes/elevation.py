"""Routes for elevation correction and lookup."""

import logging

from fastapi import APIRouter, Depends, HTTPException, status
from shared.track_pipeline_schemas import (
    ElevationCorrectionRequest,
    ElevationCorrectionResponse,
    TrackPointOut,
)

from middleware.auth import get_optional_user
from models.elevation import ElevationRequest, ElevationResponse, ElevationResult
from services.elevation_client import get_elevation_client

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/elevation", tags=["elevation"])


@router.post("/correct", response_model=ElevationCorrectionResponse)
async def correct_track_elevation(
    request: ElevationCorrectionRequest,
    user_id: str | None = Depends(get_optional_user),
):
    """
    Fill or overwrite `elevation_m` using the configured DEM provider (same client as /lookup).

    Mirrors the `TrackPoint` / `ElevationCorrectionRequest` contract in `shared.track_pipeline_schemas`.
    """
    try:
        client = get_elevation_client()
        coordinates = [(p.lat, p.lon) for p in request.points]
        raw = await client.get_elevation(coordinates)
        if len(raw) != len(request.points):
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="Elevation provider returned a mismatched result count",
            )

        corrected: list[TrackPointOut] = []
        for pt, row in zip(request.points, raw, strict=True):
            elev = row.get("elevation")
            if elev is None:
                raise HTTPException(
                    status_code=status.HTTP_502_BAD_GATEWAY,
                    detail="Elevation provider omitted elevation for a coordinate",
                )
            corrected.append(
                TrackPointOut(
                    lat=pt.lat,
                    lon=pt.lon,
                    elevation_m=float(elev),
                    timestamp=pt.timestamp,
                    speed_kmh=pt.speed_kmh,
                    segment_type=pt.segment_type,
                )
            )

        logger.info(
            "Elevation correction for %s points (user: %s)",
            len(corrected),
            user_id or "anonymous",
        )
        return ElevationCorrectionResponse(points=corrected)

    except HTTPException:
        raise
    except Exception as e:
        logger.error("Error correcting elevation: %s", e)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to correct elevation: {e!s}",
        ) from None


@router.post("/lookup", response_model=ElevationResponse)
async def lookup_elevation(
    request: ElevationRequest, user_id: str | None = Depends(get_optional_user)
):
    """
    Look up elevation data for a list of coordinates.

    Authentication is optional. Returns elevation in meters for each coordinate.
    Maximum 1000 coordinates per request.
    """
    try:
        client = get_elevation_client()

        # Convert request to coordinate tuples
        coordinates = [(loc.latitude, loc.longitude) for loc in request.locations]

        # Fetch elevation data
        results = await client.get_elevation(coordinates)

        # Convert to response model
        elevation_results = [
            ElevationResult(
                latitude=result["latitude"],
                longitude=result["longitude"],
                elevation=result["elevation"],
            )
            for result in results
        ]

        logger.info(
            f"Elevation lookup completed for {len(elevation_results)} points (user: {user_id or 'anonymous'})"
        )

        return ElevationResponse(results=elevation_results, count=len(elevation_results))

    except Exception as e:
        logger.error(f"Error looking up elevation: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to lookup elevation: {str(e)}",
        ) from None


@router.get("/point")
async def get_point_elevation(
    lat: float, lng: float, user_id: str | None = Depends(get_optional_user)
):
    """
    Simple GET endpoint for single point elevation lookup.

    Query parameters:
    - lat: Latitude (-90 to 90)
    - lng: Longitude (-180 to 180)
    """
    if not (-90 <= lat <= 90):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Latitude must be between -90 and 90"
        ) from None

    if not (-180 <= lng <= 180):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Longitude must be between -180 and 180"
        ) from None

    try:
        client = get_elevation_client()

        results = await client.get_elevation([(lat, lng)])

        if not results:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="No elevation data found for coordinates",
            ) from None

        result = results[0]

        logger.info(f"Point elevation lookup completed (user: {user_id or 'anonymous'})")

        return {
            "latitude": result["latitude"],
            "longitude": result["longitude"],
            "elevation": result["elevation"],
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error looking up point elevation: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to lookup elevation: {str(e)}",
        ) from None
