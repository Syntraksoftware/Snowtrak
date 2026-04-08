"""
FastAPI map service entry for ``uvicorn main:app`` when cwd is ``map-backend/``.

Unified monorepo entry (same ``app`` surface): ``backend/main.py`` → ``uvicorn main:app``
from ``backend/`` with ``PYTHONPATH`` including ``backend`` and ``map-backend``, or use
``python -m uvicorn main:app`` after ``cd backend``.
"""

from __future__ import annotations

import sys
from pathlib import Path

_this_dir = Path(__file__).resolve().parent
if not (_this_dir / "db" / "connection.py").exists():
    sys.path.insert(0, str(_this_dir.parent))

from config import get_config
from application import create_app

app = create_app()
config = get_config()

if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "main:app",
        host=config.HOST,
        port=config.PORT,
        reload=config.DEBUG,
        log_level="info",
    )
