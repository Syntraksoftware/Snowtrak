"""Service layer helpers for main-backend.

Export commonly-used service singletons from here for convenient imports.
"""

from .weather import weather_service

__all__ = ["weather_service"]
