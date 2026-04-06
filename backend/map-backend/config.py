"""Configuration for Map Backend (FastAPI)."""

from functools import lru_cache
from pathlib import Path
from typing import Literal

from pydantic import computed_field, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

# Load ``.env`` next to this file so ``uvicorn main:app`` works from ``backend/`` or ``map-backend/``.
_MAP_BACKEND_ENV = Path(__file__).resolve().parent / ".env"


class Config(BaseSettings):
    """Typed settings loaded from environment variables."""

    model_config = SettingsConfigDict(env_file=_MAP_BACKEND_ENV, extra="ignore")

    MAP_STORAGE_BACKEND: Literal["supabase", "postgis"] = "supabase"

    SUPABASE_URL: str | None = None
    SUPABASE_SERVICE_ROLE_KEY: str | None = None

    POSTGIS_DSN: str | None = None
    POSTGIS_HOST: str = "postgis"
    POSTGIS_PORT: int = 5432
    POSTGIS_DB: str = "syntrak"
    POSTGIS_USER: str = "syntrak"
    POSTGIS_PASSWORD: str = "syntrak_local_dev"
    JWT_SECRET: str
    JWT_ALGORITHM: str = "HS256"
    FASTAPI_ENV: str = "development"
    PORT: int = 5200
    HOST: str = "127.0.0.1"
    CORS_ORIGINS: list[str] = [
        "http://localhost:3000",
        "http://localhost:8080",
        "http://localhost:5173",
    ]
    STATIC_MAP_WIDTH: int = 600
    STATIC_MAP_HEIGHT: int = 400
    STATIC_MAP_ZOOM: int = 12

    # OpenSkiMap-style GeoJSON bulk sync (requires asyncpg pool + migration 002 ``source_id``).
    # Scheduler runs only when BOTH are set (see ``openskimap_sync_armed``).
    OPENSKIMAP_SYNC_ENABLED: bool = False
    OPENSKIMAP_RUNS_GEOJSON_URL: str | None = None

    @computed_field
    @property
    def openskimap_sync_armed(self) -> bool:
        """True only when the daily OpenSkiMap job should be registered (explicit flag + non-empty URL)."""
        url = (self.OPENSKIMAP_RUNS_GEOJSON_URL or "").strip()
        return bool(self.OPENSKIMAP_SYNC_ENABLED and url)

    @computed_field
    @property
    def postgis_dsn(self) -> str:
        # Build DSN from individual fields when POSTGIS_DSN is not set.
        if self.POSTGIS_DSN:
            return self.POSTGIS_DSN
        return (
            f"postgresql://{self.POSTGIS_USER}:{self.POSTGIS_PASSWORD}"
            f"@{self.POSTGIS_HOST}:{self.POSTGIS_PORT}/{self.POSTGIS_DB}"
        )

    @computed_field
    @property
    def DEBUG(self) -> bool:
        return self.FASTAPI_ENV == "development"

    @model_validator(mode="after")
    def validate_storage_backend_requirements(self):
        if self.MAP_STORAGE_BACKEND == "supabase" and (
            not self.SUPABASE_URL or not self.SUPABASE_SERVICE_ROLE_KEY
        ):
            raise ValueError(
                "SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are required when "
                "MAP_STORAGE_BACKEND=supabase"
            )
        if self.OPENSKIMAP_SYNC_ENABLED and not (self.OPENSKIMAP_RUNS_GEOJSON_URL or "").strip():
            raise ValueError(
                "OPENSKIMAP_RUNS_GEOJSON_URL is required when OPENSKIMAP_SYNC_ENABLED is true"
            )
        return self


@lru_cache(maxsize=1)
def get_config() -> Config:
    return Config()
