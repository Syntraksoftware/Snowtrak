"""SQLAlchemy declarative base for map-backend PostGIS models."""

from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    """Shared metadata for ORM tables under `map-backend/db/`."""
