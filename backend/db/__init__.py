"""Shared database layout entrypoints.

Alembic migrations live in ``db/migrations/``; configure ``SYNTRAK_DATABASE_URL`` and run
``alembic upgrade head`` from ``backend/``. ORM models for map geo tables are in
``map-backend/db/orm_models.py`` (schema ``map_trail``).
"""
