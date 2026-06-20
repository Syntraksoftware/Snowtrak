"""Shared JWT environment variable parsing for satellite backends."""

from pydantic import AliasChoices, Field

# main-backend signs tokens with SECRET_KEY; other services validate with JWT_SECRET.
# Accept both names so local .env files stay aligned without duplicate entries.
JWT_SECRET_FIELD = Field(validation_alias=AliasChoices("JWT_SECRET", "SECRET_KEY"))
