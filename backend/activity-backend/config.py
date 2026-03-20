"""Configuration for Activity Backend (FastAPI)."""
import os
from dotenv import load_dotenv

load_dotenv()


def _require_env(name: str) -> str:
    value = os.getenv(name)
    if not value:
        raise ValueError(f"Required environment variable {name} is not set")
    return value


class Config:
    """Base configuration."""

    # Supabase
    SUPABASE_URL = _require_env("SUPABASE_URL")
    SUPABASE_SERVICE_ROLE_KEY = _require_env("SUPABASE_SERVICE_ROLE_KEY")

    # JWT
    JWT_SECRET = _require_env("JWT_SECRET")
    JWT_ALGORITHM = os.getenv("JWT_ALGORITHM", "HS256")

    # FastAPI / server
    FASTAPI_ENV = os.getenv("FASTAPI_ENV", "development")
    DEBUG = FASTAPI_ENV == "development"
    PORT = int(os.getenv("PORT", 5100))
    # Bind host: default to localhost for safety; override with HOST=0.0.0.0 when needed
    HOST = os.getenv("HOST", "127.0.0.1")

    # CORS
    CORS_ORIGINS = [
        "http://localhost:3000",
        "http://localhost:8080",
        "http://localhost:5173",
    ]


def get_config() -> Config:
    env = os.getenv("FASTAPI_ENV", "development")
    return Config()
