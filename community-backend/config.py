"""
Configuration for Community Backend Flask app.
"""
import os
from dotenv import load_dotenv

load_dotenv()


class Config:
    """Base configuration."""
    
    # Supabase
    SUPABASE_URL = os.getenv("SUPABASE_URL")
    SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
    
    # JWT
    JWT_SECRET = os.getenv("JWT_SECRET")
    JWT_ALGORITHM = "HS256"
    
    # Flask
    FLASK_ENV = os.getenv("FLASK_ENV", "production")
    DEBUG = FLASK_ENV == "development"
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
    FLASK_ENV = "development"


class ProductionConfig(Config):
    """Production configuration."""
    DEBUG = False
    FLASK_ENV = "production"


# Config dictionary
config = {
    "development": DevelopmentConfig,
    "production": ProductionConfig,
    "default": DevelopmentConfig,
}


def get_config():
    """Get configuration based on environment."""
    env = os.getenv("FLASK_ENV", "development")
    return config.get(env, config["default"])
