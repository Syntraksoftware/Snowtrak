"""Alembic environment: PostGIS migrations for map-backend ORM (`map-backend/orm/`)."""

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

from orm import orm_models  # noqa: E402, F401 — register models on Base.metadata
from orm.base import Base  # noqa: E402

config = context.config

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata


def _load_url_from_map_backend_env() -> None:
    """Read SYNTRAK_DATABASE_URL out of map-backend/.env if it is not exported.

    Alembic only looks at os.environ, while the URL lives in the env file that
    every other tool reads -- so `alembic upgrade head` needed the variable
    exported by hand, and forgetting it did not say so: it fell back to the
    localhost URL in alembic.ini and failed as `role "syntrak" does not exist`.
    An exported value still wins, so CI and the droplet are unaffected.
    """
    if os.environ.get("SYNTRAK_DATABASE_URL"):
        return
    env_file = _MAP_BACKEND_ROOT / ".env"
    if not env_file.exists():
        return
    for line in env_file.read_text().splitlines():
        key, sep, value = line.partition("=")
        if sep and key.strip() == "SYNTRAK_DATABASE_URL":
            os.environ["SYNTRAK_DATABASE_URL"] = value.strip().strip("\"'")
            return


def get_database_url() -> str:
    _load_url_from_map_backend_env()
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
