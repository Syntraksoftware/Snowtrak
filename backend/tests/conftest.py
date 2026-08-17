"""Pytest bootstrap: ``backend/`` and ``map-backend/`` on ``sys.path`` for imports."""

from __future__ import annotations

import os

# Placeholder configuration, set before the service is imported. These services
# declare SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY and JWT_SECRET as required
# fields, so importing them constructs a Config that fails without values. The
# tests stub every outbound call, so the values only need to exist.
#
# setdefault writes into os.environ, which pydantic-settings ranks above the
# .env file. That makes the suite hermetic in both directions: it runs on a
# fresh clone with no .env, and it stops running against a developer's real
# Supabase credentials by accident.
os.environ.setdefault("SUPABASE_URL", "https://placeholder.supabase.co")
os.environ.setdefault("SUPABASE_SERVICE_ROLE_KEY", "placeholder-service-role-key")
os.environ.setdefault("JWT_SECRET", "placeholder-jwt-secret-for-tests-only")

import sys
from pathlib import Path

import pytest

_BACKEND = Path(__file__).resolve().parents[1]
_MAP_BACKEND = _BACKEND / "map-backend"

sys.path.insert(0, str(_BACKEND))
sys.path.insert(0, str(_MAP_BACKEND))


@pytest.fixture
def anyio_backend() -> str:
    return "asyncio"
