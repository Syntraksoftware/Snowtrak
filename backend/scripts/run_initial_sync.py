#!/usr/bin/env python3
"""
One-shot OpenSkiMap-style GeoJSON ingest into ``map_trail.ski_runs`` (asyncpg).

Requires:
  - ``SYNTRAK_DATABASE_URL`` (``postgresql+psycopg://`` or ``postgresql://``; normalized for asyncpg)
  - ``OPENSKIMAP_RUNS_GEOJSON_URL`` (HTTPS GeoJSON FeatureCollection of run lines)

Does **not** require ``OPENSKIMAP_SYNC_ENABLED`` (that flag only gates the APScheduler job in ``main.py``).

Run from repository root (with repo-root ``.venv`` active):

  ./.venv/bin/python backend/scripts/run_initial_sync.py

Or from ``backend/``:

  ../.venv/bin/python scripts/run_initial_sync.py

Local file (dev / no HTTPS URL): put GeoJSON under ``backend/data/`` (gitignored except ``.gitkeep``), then:

  ./.venv/bin/python backend/scripts/run_initial_sync.py --file backend/data/runs.geojson

After a successful run, expect ``SELECT COUNT(*) FROM map_trail.ski_runs`` in the tens of thousands
(depending on the upstream dataset). This script prints that count and a small ``ST_DWithin`` check.
"""

from __future__ import annotations

import argparse
import asyncio
import logging
import os
import sys
from pathlib import Path

# ``db`` lives under backend/; ``services.openskimap_sync`` under map-backend/
# ``parents``: …/backend/scripts/run_initial_sync.py → [scripts, backend, repo_root]
_BACKEND_ROOT = Path(__file__).resolve().parents[1]
_REPO_ROOT = Path(__file__).resolve().parents[2]
_MAP_BACKEND_ROOT = _BACKEND_ROOT / "map-backend"
sys.path.insert(0, str(_BACKEND_ROOT))
sys.path.insert(0, str(_MAP_BACKEND_ROOT))

logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
logger = logging.getLogger("run_initial_sync")


def _load_env() -> None:
    try:
        from dotenv import load_dotenv
    except ImportError:
        return
    load_dotenv(_REPO_ROOT / ".env")
    load_dotenv(_BACKEND_ROOT / ".env")
    # Prefer map-backend service env over repo/backend fallbacks for keys it defines.
    load_dotenv(_MAP_BACKEND_ROOT / ".env", override=True)


async def _run_verify_queries(conn, lon: float, lat: float, radius_m: float) -> None:
    total = await conn.fetchval("SELECT COUNT(*) FROM map_trail.ski_runs")
    logger.info("map_trail.ski_runs row count: %s", f"{total:,}" if total is not None else total)

    nearby = await conn.fetchval(
        """
        SELECT COUNT(*) FROM map_trail.ski_runs AS r
        WHERE ST_DWithin(
            r.geom::geography,
            ST_SetSRID(ST_MakePoint($1::double precision, $2::double precision), 4326)::geography,
            $3::double precision
        )
        """,
        lon,
        lat,
        radius_m,
    )
    logger.info(
        "ST_DWithin sample: %s runs within %.0f m of (%.4f, %.4f) (uses GiST + geography cast)",
        f"{nearby:,}" if nearby is not None else nearby,
        radius_m,
        lon,
        lat,
    )


async def _async_main(args: argparse.Namespace) -> int:
    _load_env()

    dsn_raw = args.dsn or os.environ.get("SYNTRAK_DATABASE_URL")
    if not dsn_raw or not dsn_raw.strip():
        logger.error(
            "SYNTRAK_DATABASE_URL is not set. Add it to %s or export it; or pass --dsn",
            _MAP_BACKEND_ROOT / ".env",
        )
        return 1

    file_path: Path | None = None
    if args.file:
        file_path = Path(args.file).expanduser().resolve()
        if not file_path.is_file():
            logger.error("Not a file: %s", file_path)
            return 1

    url = (args.url or os.environ.get("OPENSKIMAP_RUNS_GEOJSON_URL") or "").strip()
    if not file_path and not url:
        logger.error(
            "Provide --file PATH or set OPENSKIMAP_RUNS_GEOJSON_URL in %s / pass --url",
            _MAP_BACKEND_ROOT / ".env",
        )
        return 1

    from db.connection import close_pool, create_pool, get_pool, normalize_asyncpg_dsn
    from services.openskimap_sync import (
        sync_ski_runs_from_geojson_file,
        sync_ski_runs_from_openskimap,
    )

    dsn = normalize_asyncpg_dsn(dsn_raw)

    await create_pool(
        dsn=dsn,
        min_size=1,
        max_size=5,
        command_timeout=3600.0,
    )
    pool = get_pool()
    assert pool is not None

    try:
        async with pool.acquire() as conn:
            if file_path is not None:
                logger.info("Starting ingest from file %s", file_path)
                n = await sync_ski_runs_from_geojson_file(conn, file_path)
            else:
                logger.info("Starting ingest from %s", url)
                n = await sync_ski_runs_from_openskimap(
                    conn, url=url, bust_cache=not args.no_cache_bust
                )
            logger.info("Upserted %s run features", f"{n:,}")

            if not args.skip_verify:
                await _run_verify_queries(
                    conn,
                    lon=args.lon,
                    lat=args.lat,
                    radius_m=args.radius_m,
                )
    finally:
        await close_pool()

    return 0


def main() -> None:
    p = argparse.ArgumentParser(description="Initial OpenSkiMap GeoJSON → map_trail.ski_runs ingest")
    src = p.add_mutually_exclusive_group()
    src.add_argument("--url", help="GeoJSON HTTPS URL (else OPENSKIMAP_RUNS_GEOJSON_URL)")
    src.add_argument(
        "--file",
        metavar="PATH",
        help="Local GeoJSON file (e.g. backend/data/runs.geojson); skips HTTP download",
    )
    p.add_argument("--dsn", help="Postgres URL for asyncpg (else SYNTRAK_DATABASE_URL)")
    p.add_argument(
        "--no-cache-bust",
        action="store_true",
        help="Do not append ?v=YYYYMMDD to the GeoJSON URL",
    )
    p.add_argument(
        "--skip-verify",
        action="store_true",
        help="Skip COUNT and ST_DWithin checks after ingest",
    )
    p.add_argument(
        "--lon",
        type=float,
        default=6.8654,
        help="Longitude for ST_DWithin sample (default: Chamonix area)",
    )
    p.add_argument(
        "--lat",
        type=float,
        default=45.8326,
        help="Latitude for ST_DWithin sample",
    )
    p.add_argument(
        "--radius-m",
        type=float,
        default=5000.0,
        help="Radius in meters for ST_DWithin sample",
    )
    args = p.parse_args()
    raise SystemExit(asyncio.run(_async_main(args)))


if __name__ == "__main__":
    main()
