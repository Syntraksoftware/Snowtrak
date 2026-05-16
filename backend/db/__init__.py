"""Shared database layout entrypoints.

Alembic migrations live in ``db/migrations/``; configure ``SYNTRAK_DATABASE_URL`` and run
``alembic upgrade head`` from ``backend/``. Asyncpg pool helpers live in ``db/connection.py``.
ORM models for map geo tables are in ``map-backend/orm/orm_models.py`` (schema ``map_trail``).
"""

from db.connection import close_pool, create_pool, get_db, get_pool, normalize_asyncpg_dsn

__all__ = [
    "close_pool",
    "create_pool",
    "get_db",
    "get_pool",
    "normalize_asyncpg_dsn",
]
