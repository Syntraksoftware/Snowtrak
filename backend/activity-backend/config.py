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

    @computed_field
    @property
    def DEBUG(self) -> bool:
        return self.FASTAPI_ENV == "development"


@lru_cache(maxsize=1)
def get_config() -> Config:
    return Config()
