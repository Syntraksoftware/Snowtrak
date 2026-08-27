#!/usr/bin/env python3
"""End-to-end DELETE orchestration test (map_trail + public.activities)."""

from __future__ import annotations

import asyncio
import sys
import uuid
from datetime import UTC, datetime
from pathlib import Path

import httpx
import jwt
from dotenv import load_dotenv

REPO = Path(__file__).resolve().parents[2]
load_dotenv(REPO / "backend" / "activity-backend" / ".env")
sys.path.insert(0, str(REPO / "backend" / "activity-backend"))

from config import get_config  # noqa: E402

MAP_URL = "http://127.0.0.1:5200"
ACTIVITY_URL = "http://127.0.0.1:5100"
TEST_USER_ID = "00000000-0000-4000-8000-000000000099"


def mint_token(user_id: str) -> str:
    cfg = get_config()
    payload = {
        "sub": user_id,
        "exp": datetime.now(UTC).timestamp() + 3600,
    }
    return jwt.encode(payload, cfg.JWT_SECRET, algorithm=cfg.JWT_ALGORITHM)


async def create_map_activity(client: httpx.AsyncClient) -> str:
    body = {
        "user_id": TEST_USER_ID,
        "processed_track": {
            "id": str(uuid.uuid4()),
            "recorded_at": datetime.now(UTC).isoformat(),
            "source_type": "live",
            "points": [
                {
                    "lat": 47.5,
                    "lon": 8.5,
                    "elevation_m": 1200.0,
                    "timestamp": datetime.now(UTC).isoformat(),
                    "speed_kmh": 12.0,
                },
                {
                    "lat": 47.501,
                    "lon": 8.501,
                    "elevation_m": 1190.0,
                    "timestamp": datetime.now(UTC).isoformat(),
                    "speed_kmh": 15.0,
                },
            ],
        },
        "segments": [],
        "stats": {
            "total_distance_km": 0.15,
            "total_vertical_drop_m": 10.0,
            "top_speed_kmh": 15.0,
            "avg_speed_kmh": 13.0,
            "moving_time_s": 120.0,
            "trail_count": 0,
        },
    }
    r = await client.post(f"{MAP_URL}/activities", json=body, timeout=30.0)
    r.raise_for_status()
    map_id = r.json()["id"]
    print(f"  ✓ map_trail activity created: {map_id}")
    return map_id


async def verify_map_points(client: httpx.AsyncClient, map_id: str) -> int:
    r = await client.get(f"{MAP_URL}/activities/{map_id}", timeout=30.0)
    r.raise_for_status()
    n = len(r.json().get("processed_track", {}).get("points") or [])
    print(f"  ✓ map_trail points before delete: {n}")
    return n


async def create_feed_activity(client: httpx.AsyncClient, token: str, map_id: str) -> str:
    now = datetime.now(UTC).isoformat()
    body = {
        "type": "alpine",
        "name": "DELETE orchestration smoke",
        "start_time": now,
        "end_time": now,
        "is_public": True,
        "map_activity_id": map_id,
        "processing_status": "ready",
        "locations": [
            {"latitude": 47.5, "longitude": 8.5, "timestamp": now},
        ],
    }
    r = await client.post(
        f"{ACTIVITY_URL}/api/v1/activities",
        json=body,
        headers={"Authorization": f"Bearer {token}"},
        timeout=30.0,
    )
    r.raise_for_status()
    feed_id = r.json()["id"]
    print(f"  ✓ public.activities row created: {feed_id} (map_activity_id={map_id})")
    return feed_id


async def delete_feed_activity(client: httpx.AsyncClient, token: str, feed_id: str) -> None:
    r = await client.delete(
        f"{ACTIVITY_URL}/api/v1/activities/{feed_id}",
        headers={"Authorization": f"Bearer {token}"},
        timeout=30.0,
    )
    r.raise_for_status()
    print(f"  ✓ DELETE activity-backend responded: {r.json()}")


async def verify_map_gone(client: httpx.AsyncClient, map_id: str) -> None:
    r = await client.get(f"{MAP_URL}/activities/{map_id}", timeout=30.0)
    if r.status_code == 404:
        print(f"  ✓ map_trail activity {map_id} gone (404)")
        return
    raise RuntimeError(f"map activity still exists: HTTP {r.status_code} {r.text[:200]}")


async def main() -> None:
    print("\n=== DELETE orchestration E2E ===\n")
    token = mint_token(TEST_USER_ID)

    async with httpx.AsyncClient() as client:
        for name, url in (("map-backend", f"{MAP_URL}/health"), ("activity-backend", f"{ACTIVITY_URL}/health")):
            r = await client.get(url, timeout=5.0)
            if r.status_code != 200:
                raise SystemExit(f"{name} not healthy: {r.status_code}")
            print(f"  ✓ {name} healthy")

        map_id = await create_map_activity(client)
        await verify_map_points(client, map_id)
        feed_id = await create_feed_activity(client, token, map_id)
        await delete_feed_activity(client, token, feed_id)
        await verify_map_gone(client, map_id)

    print("\nDELETE orchestration test PASSED.\n")


if __name__ == "__main__":
    asyncio.run(main())
