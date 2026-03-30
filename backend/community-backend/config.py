"""Configuration for Community Backend FastAPI app."""

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
    PORT: int = 5001
    HOST: str = "0.0.0.0"
    CORS_ORIGINS: List[str] = [
        "http://localhost:3000",
        "http://localhost:8080",
        "http://localhost:5173",
    ]

    @computed_field
    @property
    def DEBUG(self) -> bool:
        return self.FASTAPI_ENV == "development"


@lru_cache(maxsize=1)
def get_config() -> Config:
    """Get cached config instance."""
    return Config()
