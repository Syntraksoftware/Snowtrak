"""
Core configuration module using Pydantic Settings.
Loads environment variables and provides type-safe config access.
"""

import json

from pydantic import Field, field_validator, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings with validation."""

    model_config = SettingsConfigDict(
        env_file=".env",
        case_sensitive=False,
        env_file_encoding="utf-8",
        extra="ignore",
    )

    # App Info
    app_name: str = Field(default="Syntrak Auth API", alias="APP_NAME")
    app_version: str = Field(default="1.0.0", alias="APP_VERSION")
    debug: bool = Field(default=True, alias="DEBUG")
    environment: str = Field(default="development", alias="ENVIRONMENT")

    # Server
    host: str = Field(default="0.0.0.0", alias="HOST")
    port: int = Field(default=8080, alias="PORT")

    # JWT
    secret_key: str = Field(default="dev-secret-key-change-in-production", alias="SECRET_KEY")
    algorithm: str = Field(default="HS256", alias="ALGORITHM")
    access_token_expire_minutes: int = Field(default=60, alias="ACCESS_TOKEN_EXPIRE_MINUTES")
    refresh_token_expire_days: int = Field(default=7, alias="REFRESH_TOKEN_EXPIRE_DAYS")

    # CORS - stored as string in env, converted to list
    # Allow origins for mobile app development (iOS simulator, Android emulator, web)
    allowed_origins: str = Field(
        default="http://localhost:3000,http://127.0.0.1:3000", alias="ALLOWED_ORIGINS"
    )

    # Security
    bcrypt_rounds: int = Field(default=12, alias="BCRYPT_ROUNDS")

    # Supabase
    supabase_url: str | None = Field(default=None, alias="SUPABASE_URL")
    supabase_service_role_key: str | None = Field(default=None, alias="SUPABASE_SERVICE_ROLE_KEY")

    # Redis-backed rate limiter
    rate_limit_enabled: bool = Field(default=True, alias="RATE_LIMIT_ENABLED")
    rate_limit_redis_url: str = Field(default="redis://localhost:6379/0", alias="RATE_LIMIT_REDIS_URL")
    rate_limit_namespace: str = Field(default="main-backend", alias="RATE_LIMIT_NAMESPACE")
    rate_limit_fail_open: bool = Field(default=True, alias="RATE_LIMIT_FAIL_OPEN")
    rate_limit_default_limit: int = Field(default=240, alias="RATE_LIMIT_DEFAULT_LIMIT")
    rate_limit_default_window_seconds: int = Field(default=60, alias="RATE_LIMIT_DEFAULT_WINDOW_SECONDS")
    rate_limit_policies: list = Field(default_factory=list, alias="RATE_LIMIT_POLICIES")

    @field_validator("rate_limit_policies", mode="before")
    @classmethod
    def parse_policies(cls, v: str | list) -> list:
        """Parse JSON policies string or accept list directly."""
        if isinstance(v, list):
            return v
        if isinstance(v, str):
            return json.loads(v) if v else []
        return []

    def get_allowed_origins(self) -> list[str]:
        """Get allowed origins as a list."""
        if isinstance(self.allowed_origins, str):
            origins = [
                origin.strip() for origin in self.allowed_origins.split(",") if origin.strip()
            ]
            # Filter out "*" if present (not compatible with allow_credentials=True)
            return [o for o in origins if o != "*"]
        return self.allowed_origins if isinstance(self.allowed_origins, list) else []

    @model_validator(mode="after")
    def validate_supabase_config(self):
        """
        Validate that Supabase URL and service role key are either both set or both None.

        Raises:
            ValueError: If only one of supabase_url or supabase_service_role_key is provided.
        """
        url_provided = self.supabase_url is not None and str(self.supabase_url).strip() != ""
        key_provided = (
            self.supabase_service_role_key is not None
            and str(self.supabase_service_role_key).strip() != ""
        )

        if url_provided != key_provided:
            if url_provided:
                raise ValueError(
                    "supabase_url is provided but supabase_service_role_key is missing. "
                    "Both SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be set together."
                )
            else:
                raise ValueError(
                    "supabase_service_role_key is provided but supabase_url is missing. "
                    "Both SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be set together."
                )

        return self


# Global settings instance
settings = Settings()
