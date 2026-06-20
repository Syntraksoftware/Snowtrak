"""Configuration for Activity Backend (FastAPI)."""

from functools import lru_cache

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
    PORT: int = 5100
    HOST: str = "127.0.0.1"
    CORS_ORIGINS: list[str] = [
        "http://localhost:3000",
        "http://localhost:8080",
        "http://localhost:5173",
    ]

    # Internal microservice URLs (S2S; not exposed to mobile clients)
    MAP_BACKEND_BASE_URL: str = "http://127.0.0.1:5200"
    NIVUS_BASE_URL: str = "http://127.0.0.1:5201"
    MAP_BACKEND_TIMEOUT_S: float = 30.0
    NIVUS_TIMEOUT_S: float = 120.0

    # Async pipeline (Phase 3) — optional; inline processing when unset
    REDIS_URL: str | None = None
    PIPELINE_STREAM_KEY: str = "syntrak:activity-pipeline"
    PIPELINE_CONSUMER_GROUP: str = "activity-backend-workers"

    # Supabase Storage bucket for raw GPX/FIT uploads
    ACTIVITY_UPLOAD_BUCKET: str = "activity-uploads"
    UPLOAD_URL_EXPIRES_S: int = 3600

    @computed_field
    @property
    def DEBUG(self) -> bool:
        return self.FASTAPI_ENV == "development"


@lru_cache(maxsize=1)
def get_config() -> Config:
    return Config()
