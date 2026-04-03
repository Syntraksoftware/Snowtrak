"""Configuration for Map Backend (FastAPI)."""

from functools import lru_cache
from typing import Literal

from pydantic import computed_field, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Config(BaseSettings):
    """Typed settings loaded from environment variables."""

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

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
    GOOGLE_MAPS_API_KEY: str
    GOOGLE_MAPS_STATIC_API_URL: str = "https://maps.googleapis.com/maps/api/staticmap"
    GOOGLE_MAPS_ELEVATION_API_URL: str = "https://maps.googleapis.com/maps/api/elevation/json"
    GOOGLE_MAPS_JS_API_URL: str = "https://maps.googleapis.com/maps/api/js"
    GOOGLE_MAPS_MAP_ID: str = ""
    STATIC_MAP_WIDTH: int = 600
    STATIC_MAP_HEIGHT: int = 400
    STATIC_MAP_ZOOM: int = 12

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
        if (
            self.MAP_STORAGE_BACKEND == "supabase"
            and (not self.SUPABASE_URL or not self.SUPABASE_SERVICE_ROLE_KEY)
        ):
            raise ValueError(
                "SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are required when "
                "MAP_STORAGE_BACKEND=supabase"
            )
        return self


@lru_cache(maxsize=1)
def get_config() -> Config:
    return Config()
