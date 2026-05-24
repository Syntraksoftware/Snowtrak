#!/usr/bin/env python3
"""Generate checked-in OpenAPI snapshots from each FastAPI app factory."""

from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path
from typing import Any

BACKEND = Path(__file__).resolve().parents[1]
REPO_ROOT = BACKEND.parent
OUT_DIR = REPO_ROOT / "packages" / "shared" / "openapi"

_EXPORT_ENV = {
    "JWT_SECRET": "openapi-export-secret",
    "SUPABASE_URL": "https://export-test.supabase.co",
    "SUPABASE_SERVICE_ROLE_KEY": "export-test-key",
    "RATE_LIMIT_ENABLED": "false",
    "CACHE_REDIS_URL": "redis://localhost:6379/0",
    "MAP_STORAGE_BACKEND": "supabase",
    "DEBUG": "true",
}


def _write_snapshot(filename: str, schema: dict[str, Any]) -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    target = OUT_DIR / filename
    target.write_text(json.dumps(schema, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(f"Wrote {target.relative_to(REPO_ROOT)} ({target.stat().st_size} bytes)")


def _run_snippet(*, cwd: Path, snippet: str) -> dict[str, Any]:
    import tempfile

    out_file = Path(tempfile.mkstemp(suffix=".json")[1])
    try:
        env = {
            "PATH": os.environ.get("PATH", ""),
            "PYTHONPATH": str(cwd),
            "PYTHONDONTWRITEBYTECODE": "1",
            "OPENAPI_SNAPSHOT_OUT": str(out_file),
            **_EXPORT_ENV,
        }

        code = f"""
import json
import os
import sys
sys.path.insert(0, {str(cwd)!r})
{snippet}
"""
        subprocess.run(
            [sys.executable, "-c", code],
            cwd="/tmp",
            env=env,
            check=True,
            capture_output=True,
            text=True,
        )
        return json.loads(out_file.read_text(encoding="utf-8"))
    finally:
        out_file.unlink(missing_ok=True)


def _main_openapi() -> dict[str, Any]:
    cwd = BACKEND / "main-backend"
    return _run_snippet(
        cwd=cwd,
        snippet="""
from app.core.supabase import supabase_client
from app.main import create_application

supabase_client.is_configured = lambda: False
schema = create_application().openapi()
with open(os.environ["OPENAPI_SNAPSHOT_OUT"], "w", encoding="utf-8") as fh:
    json.dump(schema, fh)
""",
    )


def _activity_openapi() -> dict[str, Any]:
    cwd = BACKEND / "activity-backend"
    return _run_snippet(
        cwd=cwd,
        snippet="""
import main
schema = main.app.openapi()
with open(os.environ["OPENAPI_SNAPSHOT_OUT"], "w", encoding="utf-8") as fh:
    json.dump(schema, fh)
""",
    )


def _community_openapi() -> dict[str, Any]:
    cwd = BACKEND / "community-backend"
    return _run_snippet(
        cwd=cwd,
        snippet="""
import main
schema = main.app.openapi()
with open(os.environ["OPENAPI_SNAPSHOT_OUT"], "w", encoding="utf-8") as fh:
    json.dump(schema, fh)
""",
    )


def _map_openapi() -> dict[str, Any]:
    cwd = BACKEND / "map-backend"
    return _run_snippet(
        cwd=cwd,
        snippet="""
from application import create_app
schema = create_app().openapi()
with open(os.environ["OPENAPI_SNAPSHOT_OUT"], "w", encoding="utf-8") as fh:
    json.dump(schema, fh)
""",
    )


def main() -> None:
    exporters = [
        ("openapi-main.json", _main_openapi),
        ("openapi-activity.json", _activity_openapi),
        ("openapi-community.json", _community_openapi),
        ("openapi-map.json", _map_openapi),
    ]

    for filename, exporter in exporters:
        print(f"Generating {filename}...")
        _write_snapshot(filename, exporter())

    print("OpenAPI snapshots updated.")


if __name__ == "__main__":
    main()
