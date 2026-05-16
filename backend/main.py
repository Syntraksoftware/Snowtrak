"""
Unified map-backend HTTP entry for local dev and smoke tests.

Mounts the same FastAPI ``app`` as ``map-backend/main.py`` (all routers + CORS).

Run from repository root (venv active)::

    cd backend && ../.venv/bin/python -m uvicorn main:app --host 127.0.0.1 --port 5200

Requires map-backend env (at least ``JWT_SECRET`` and storage settings per
``map-backend/config.py``).
"""

from __future__ import annotations

import sys
from pathlib import Path

_ROOT = Path(__file__).resolve().parent
_MAP = _ROOT / "map-backend"
for _p in (_MAP, _ROOT):
    if str(_p) not in sys.path:
        sys.path.insert(0, str(_p))

from application import create_app

app = create_app()

__all__ = ["app"]
