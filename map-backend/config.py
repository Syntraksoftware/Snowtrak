"""Configuration for Map Backend (FastAPI)."""
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
    PORT = int(os.getenv("PORT", 5200))
    # Bind host: default to localhost for safety; override with HOST=0.0.0.0 when needed
    HOST = os.getenv("HOST", "127.0.0.1")

    # CORS
    CORS_ORIGINS = [
        "http://localhost:3000",
        "http://localhost:8080",
        "http://localhost:5173",
    ]

    # Map API Configuration
    MAPBOX_ACCESS_TOKEN = os.getenv("MAPBOX_ACCESS_TOKEN", "")
    OPEN_ELEVATION_API_URL = os.getenv("OPEN_ELEVATION_API_URL", "https://api.open-elevation.com/api/v1/lookup")
    
    # Static Map Configuration
    STATIC_MAP_WIDTH = int(os.getenv("STATIC_MAP_WIDTH", 600))
    STATIC_MAP_HEIGHT = int(os.getenv("STATIC_MAP_HEIGHT", 400))
    STATIC_MAP_ZOOM = int(os.getenv("STATIC_MAP_ZOOM", 12))


def get_config() -> Config:
    env = os.getenv("FASTAPI_ENV", "development")
    return Config()
