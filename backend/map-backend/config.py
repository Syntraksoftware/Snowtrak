"""Configuration for Map Backend (FastAPI)."""

from functools import lru_cache
from typing import List

from pydantic import computed_field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Config(BaseSettings):
    """Typed settings loaded from environment variables."""

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    SUPABASE_URL: str
    SUPABASE_SERVICE_ROLE_KEY: str
    JWT_SECRET: str
    JWT_ALGORITHM: str = "HS256"
    FASTAPI_ENV: str = "development"
    PORT: int = 5200
    HOST: str = "127.0.0.1"
    CORS_ORIGINS: List[str] = [
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
    def DEBUG(self) -> bool:
        return self.FASTAPI_ENV == "development"


@lru_cache(maxsize=1)
def get_config() -> Config:
    return Config()
