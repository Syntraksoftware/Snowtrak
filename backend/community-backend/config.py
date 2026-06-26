"""Configuration for Community Backend FastAPI app."""

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
    PORT: int = 5001
    HOST: str = "0.0.0.0"
    CORS_ORIGINS: list[str] = [
        "http://localhost:3000",
        "http://localhost:8080",
        "http://localhost:5173",
    ]

    # Redis-backed rate limiter
    RATE_LIMIT_ENABLED: bool = True
    RATE_LIMIT_REDIS_URL: str = "redis://localhost:6379/0"
    RATE_LIMIT_NAMESPACE: str = "community-backend"
    RATE_LIMIT_FAIL_OPEN: bool = True
    RATE_LIMIT_DEFAULT_LIMIT: int = 240
    RATE_LIMIT_DEFAULT_WINDOW_SECONDS: int = 60
    RATE_LIMIT_POLICIES: list[dict] = Field(default_factory=list)

    # Redis-backed response cache for read-heavy community endpoints
    CACHE_ENABLED: bool = True
    CACHE_REDIS_URL: str = "redis://localhost:6379/0"
    CACHE_NAMESPACE: str = "community-backend-cache"
    CACHE_FEED_TTL_SECONDS: int = 15
    CACHE_POST_COMMENTS_TTL_SECONDS: int = 20
    MEDIA_CACHE_CONTROL_SECONDS: int = 31536000
    MEDIA_INLINE_CACHE_TTL_SECONDS: int = 86400
    MEDIA_INLINE_MAX_BYTES: int = 5 * 1024 * 1024

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
    """Get cached config instance."""
    return Config()
