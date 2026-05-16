"""Pytest bootstrap: ``backend/`` and ``map-backend/`` on ``sys.path`` for imports."""

from __future__ import annotations

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
