"""
Configuration for Community Backend Flask app.
"""
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
    JWT_ALGORITHM = "HS256"
    
    # FastAPI
    FASTAPI_ENV = os.getenv("FASTAPI_ENV", "development")
    DEBUG = FASTAPI_ENV == "development"
    PORT = int(os.getenv("PORT", 5001))
    
    # CORS
    CORS_ORIGINS = [
        "http://localhost:3000",  # Flutter web dev
        "http://localhost:8080",  # FastAPI backend
        "http://localhost:5173",  # Vite dev server
    ]


class DevelopmentConfig(Config):
    """Development configuration."""
    DEBUG = True
    FASTAPI_ENV = "development"


class ProductionConfig(Config):
    """Production configuration."""
    DEBUG = False
    FASTAPI_ENV = "production"


# Config dictionary
config = {
    "development": DevelopmentConfig,
    "production": ProductionConfig,
    "default": DevelopmentConfig,
}


def get_config():
    """Get configuration based on environment."""
    env = os.getenv("FASTAPI_ENV", Config.FASTAPI_ENV)
    return config.get(env, config["default"])
