#!/usr/bin/env bash
# Refresh checked-in OpenAPI snapshots (no running servers required).
#
# Usage (from repo root):
#   backend/scripts/export_openapi.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PYTHON="${PYTHON:-python3}"

exec "$PYTHON" "$ROOT/backend/scripts/generate_openapi_snapshots.py"
