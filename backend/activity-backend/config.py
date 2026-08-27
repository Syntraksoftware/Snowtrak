"""Configuration for Activity Backend (FastAPI)."""

import json
from functools import lru_cache

from pydantic import Field, computed_field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict
from shared.jwt_env import JWT_SECRET_FIELD


class Config(BaseSettings):
    """Typed settings loaded from environment variables."""

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    SUPABASE_URL: str
    SUPABASE_SERVICE_ROLE_KEY: str
    JWT_SECRET: str = JWT_SECRET_FIELD
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

    # Redis-backed rate limiter
    RATE_LIMIT_ENABLED: bool = True
    RATE_LIMIT_REDIS_URL: str = "redis://localhost:6379/0"
    RATE_LIMIT_NAMESPACE: str = "activity-backend"
    RATE_LIMIT_FAIL_OPEN: bool = True
    RATE_LIMIT_DEFAULT_LIMIT: int = 240
    RATE_LIMIT_DEFAULT_WINDOW_SECONDS: int = 60
    RATE_LIMIT_POLICIES: list[dict] = Field(default_factory=list)

    @field_validator("RATE_LIMIT_POLICIES", mode="before")
    @classmethod
    def parse_policies(cls, v: str | list) -> list:
        """Parse JSON policies string or accept list directly."""
        if isinstance(v, list):
            return v
        if isinstance(v, str):
            return json.loads(v) if v else []
        return []

    @computed_field
    @property
    def DEBUG(self) -> bool:
        return self.FASTAPI_ENV == "development"


@lru_cache(maxsize=1)
def get_config() -> Config:
    return Config()
