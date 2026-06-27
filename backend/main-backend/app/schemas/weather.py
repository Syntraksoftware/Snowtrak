"""Weather snapshot schemas."""

from pydantic import BaseModel, ConfigDict, Field


class WeatherLocation(BaseModel):
    """Coordinates and location hint used for a weather lookup."""

    model_config = ConfigDict(from_attributes=True)

    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    city_hint: str | None = None


class WeatherSnapshotTemperatures(BaseModel):
    """Temperature values for a weather snapshot."""

    model_config = ConfigDict(from_attributes=True)

    ambient_celsius: float
    feels_like_celsius: float
    strava_reported_celsius: float | None = None


class WeatherSnapshotAtmosphere(BaseModel):
    """Atmospheric conditions for a weather snapshot."""

    model_config = ConfigDict(from_attributes=True)

    humidity_percent: int
    pressure_hpa: float
    uv_index: float


class WeatherSnapshotWind(BaseModel):
    """Wind conditions for a weather snapshot."""

    model_config = ConfigDict(from_attributes=True)

    speed_meters_per_second: float
    bearing_degrees: int
    cardinal_direction: str
    gust_meters_per_second: float | None = None


class WeatherSnapshotPrecipitation(BaseModel):
    """Precipitation signal for a weather snapshot."""

    model_config = ConfigDict(from_attributes=True)

    probability_percent: int
    type: str


class WeatherSnapshot(BaseModel):
    """Weather snapshot at a specific point in time."""

    model_config = ConfigDict(from_attributes=True)

    timestamp: str
    condition: str
    condition_code: str
    icon_url: str
    temperatures: WeatherSnapshotTemperatures
    atmosphere: WeatherSnapshotAtmosphere
    wind: WeatherSnapshotWind
    precipitation: WeatherSnapshotPrecipitation


class WeatherSnapshotRequest(BaseModel):
    """Request payload used to build a weather snapshot."""

    activity_id: int
    athlete_id: int
    location: WeatherLocation
    strava_reported_celsius: float | None = None


class WeatherSnapshotResponse(BaseModel):
    """Normalized weather response returned by the API."""

    model_config = ConfigDict(from_attributes=True)

    activity_id: int = Field(..., description="Activity identifier")
    athlete_id: int = Field(..., description="Athlete identifier")
    source: str
    location: WeatherLocation
    weather_snapshot: WeatherSnapshot