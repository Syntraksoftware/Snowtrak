#!/usr/bin/env python3
"""
Incremental smoke tests for the track pipeline (map-backend → Nivus → map_trail).

Run services first (separate terminals):
  python backend/run.py --service map        # :5200
  cd ~/Desktop && PYTHONPATH=. uvicorn nivus.app.main:app --port 5201
  python backend/run.py --service activity   # :5100  (optional for upload flow)

Usage:
  python backend/scripts/smoke_test_pipeline.py --health
  python backend/scripts/smoke_test_pipeline.py --nivus-math
  python backend/scripts/smoke_test_pipeline.py --elevation
  python backend/scripts/smoke_test_pipeline.py --full --gpx path/to/file.gpx --user-id <uuid>
  python backend/scripts/smoke_test_pipeline.py --all
"""

from __future__ import annotations

import argparse
import json
import sys
import uuid
from datetime import datetime, timezone
from pathlib import Path

import httpx

_BACKEND_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(_BACKEND_ROOT / "activity-backend"))

from services.gpx_parser import parse_gpx_bytes  # noqa: E402

DEFAULT_GPX = (
    _BACKEND_ROOT.parent
    / "frontend/test/engines/ingestion/parsers/fixtures/sample_track.gpx"
)
MAP_URL = "http://127.0.0.1:5200"
NIVUS_URL = "http://127.0.0.1:5201"
ACTIVITY_URL = "http://127.0.0.1:5100"


def _ok(label: str) -> None:
    print(f"  ✓ {label}")


def _fail(label: str, detail: str) -> None:
    print(f"  ✗ {label}: {detail}")
    raise SystemExit(1)


def check_health(client: httpx.Client) -> None:
    print("\n[1/4] Health checks")
    for name, url in (
        ("map-backend", f"{MAP_URL}/health"),
        ("nivus", f"{NIVUS_URL}/health"),
        ("activity-backend", f"{ACTIVITY_URL}/health"),
    ):
        try:
            r = client.get(url, timeout=5.0)
            if r.status_code == 200:
                _ok(f"{name} {url}")
            else:
                _fail(name, f"HTTP {r.status_code}")
        except httpx.HTTPError as exc:
            _fail(name, str(exc))


def load_gpx_points(gpx_path: Path, limit: int | None = None) -> list[dict]:
    raw = parse_gpx_bytes(gpx_path.read_bytes())
    if limit is not None:
        return raw[:limit]
    return raw


def test_elevation(client: httpx.Client, points: list[dict]) -> list[dict]:
    print("\n[2/4] map-backend elevation correction")
    r = client.post(f"{MAP_URL}/elevation/correct", json={"points": points}, timeout=60.0)
    if r.status_code != 200:
        _fail("elevation/correct", f"HTTP {r.status_code} {r.text[:200]}")
    out = r.json().get("points") or []
    if len(out) != len(points):
        _fail("elevation/correct", f"expected {len(points)} points, got {len(out)}")
    _ok(f"corrected {len(out)} points")
    return out


def test_nivus_math(client: httpx.Client, points: list[dict], match_trails: bool) -> dict:
    label = "trail match" if match_trails else "math-only"
    print(f"\n[3/4] Nivus pipeline ({label})")
    body = {
        "id": str(uuid.uuid4()),
        "recorded_at": points[0].get("timestamp") or datetime.now(timezone.utc).isoformat(),
        "source_type": "gpx",
        "match_trails": match_trails,
        "points": points,
    }
    r = client.post(f"{NIVUS_URL}/api/v1/pipeline/process", json=body, timeout=180.0)
    if r.status_code == 503 and match_trails:
        print("  ⚠ trail match unavailable (no DB); retry with --nivus-math only")
        _fail("nivus", r.text[:300])
    if r.status_code != 200:
        _fail("nivus", f"HTTP {r.status_code} {r.text[:300]}")
    data = r.json()
    seg_count = len(data.get("segments") or [])
    pt_count = len(data.get("processed_track", {}).get("points") or [])
    _ok(f"segments={seg_count} points_out={pt_count}")
    return data


def test_map_persist(client: httpx.Client, pipeline: dict, user_id: str) -> str:
    print("\n[4/4] map-backend persist (map_trail)")
    body = {
        "user_id": user_id,
        "processed_track": pipeline["processed_track"],
        "segments": pipeline.get("segments") or [],
        "stats": pipeline.get("stats"),
    }
    r = client.post(f"{MAP_URL}/activities", json=body, timeout=60.0)
    if r.status_code not in (200, 201):
        _fail("POST /activities", f"HTTP {r.status_code} {r.text[:300]}")
    activity_id = r.json().get("id")
    if not activity_id:
        _fail("POST /activities", "response missing id")
    _ok(f"map_activity_id={activity_id}")
    return str(activity_id)


def main() -> None:
    parser = argparse.ArgumentParser(description="Pipeline smoke tests")
    parser.add_argument("--health", action="store_true", help="Health checks only")
    parser.add_argument("--elevation", action="store_true", help="DEM correction step")
    parser.add_argument("--nivus-math", action="store_true", help="Nivus math-only (no DB)")
    parser.add_argument("--nivus-match", action="store_true", help="Nivus with trail matching (needs DB)")
    parser.add_argument("--persist", action="store_true", help="Persist to map_trail (needs SYNTRAK_DATABASE_URL on map-backend)")
    parser.add_argument("--full", action="store_true", help="elevation → nivus-match → persist")
    parser.add_argument("--all", action="store_true", help="health + nivus-math on fixture GPX")
    parser.add_argument("--gpx", type=Path, default=DEFAULT_GPX, help="GPX file path")
    parser.add_argument("--user-id", default="00000000-0000-4000-8000-000000000001", help="UUID for map_trail persist")
    parser.add_argument("--limit", type=int, default=50, help="Max GPX points (keep smoke fast)")
    args = parser.parse_args()

    if not any(
        (
            args.health,
            args.elevation,
            args.nivus_math,
            args.nivus_match,
            args.persist,
            args.full,
            args.all,
        )
    ):
        parser.print_help()
        raise SystemExit(0)

    if not args.gpx.exists():
        _fail("gpx", f"file not found: {args.gpx}")

    points = load_gpx_points(args.gpx, limit=args.limit)
    print(f"Loaded {len(points)} points from {args.gpx.name}")

    with httpx.Client() as client:
        if args.health or args.all:
            check_health(client)

        pipeline: dict | None = None

        if args.elevation or args.full:
            points = test_elevation(client, points)

        if args.nivus_math or args.all:
            pipeline = test_nivus_math(client, points, match_trails=False)

        if args.nivus_match or args.full:
            pipeline = test_nivus_math(client, points, match_trails=True)

        if args.persist or args.full:
            if pipeline is None:
                pipeline = test_nivus_math(client, points, match_trails=True)
            map_id = test_map_persist(client, pipeline, args.user_id)
            print(f"\nDone. Verify in DB: SELECT * FROM map_trail.activities WHERE id = '{map_id}';")

    print("\nSmoke run finished OK.")


if __name__ == "__main__":
    main()
