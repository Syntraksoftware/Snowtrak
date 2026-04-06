"""Alembic environment: PostGIS migrations for map-backend ORM (`map-backend/db/`)."""

from __future__ import annotations

import os
import sys
from logging.config import fileConfig
from pathlib import Path

from alembic import context
from sqlalchemy import engine_from_config, pool

# backend/ (parent of db/)
_BACKEND_ROOT = Path(__file__).resolve().parents[2]
_MAP_BACKEND_ROOT = _BACKEND_ROOT / "map-backend"
sys.path.insert(0, str(_MAP_BACKEND_ROOT))

from db import orm_models  # noqa: E402, F401 — register models on Base.metadata
from db.base import Base  # noqa: E402

config = context.config

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata


def get_database_url() -> str:
    url = os.environ.get("SYNTRAK_DATABASE_URL")
    if url:
        return url
    ini_url = config.get_main_option("sqlalchemy.url")
    if not ini_url or ini_url.startswith("driver://"):
        raise RuntimeError(
            "Set SYNTRAK_DATABASE_URL (e.g. postgresql+psycopg://USER:PASS@HOST:5432/DB) "
            "or set sqlalchemy.url in backend/alembic.ini"
        )
    return ini_url


def run_migrations_offline() -> None:
    url = get_database_url()
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )

    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    configuration = config.get_section(config.config_ini_section, {})
    configuration["sqlalchemy.url"] = get_database_url()
    connectable = engine_from_config(
        configuration,
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(connection=connection, target_metadata=target_metadata)

        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
