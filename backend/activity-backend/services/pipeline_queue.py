"""Redis Streams queue for async activity pipeline jobs."""

from __future__ import annotations

import json
import logging
from typing import Any

from config import get_config

logger = logging.getLogger(__name__)

_redis_client: Any | None = None


def _get_redis():
    global _redis_client
    if _redis_client is not None:
        return _redis_client

    cfg = get_config()
    if not cfg.REDIS_URL:
        return None

    try:
        import redis
    except ImportError as exc:
        raise RuntimeError("redis package required when REDIS_URL is set") from exc

    _redis_client = redis.from_url(cfg.REDIS_URL, decode_responses=True)
    return _redis_client


def ensure_consumer_group() -> None:
    client = _get_redis()
    if client is None:
        return

    cfg = get_config()
    try:
        client.xgroup_create(
            cfg.PIPELINE_STREAM_KEY,
            cfg.PIPELINE_CONSUMER_GROUP,
            id="0",
            mkstream=True,
        )
        logger.info("Created Redis consumer group %s", cfg.PIPELINE_CONSUMER_GROUP)
    except Exception as exc:
        if "BUSYGROUP" not in str(exc):
            raise


def publish_pipeline_job(payload: dict[str, Any]) -> str | None:
    """Enqueue a pipeline job. Returns Redis message id, or None when Redis is disabled."""
    client = _get_redis()
    if client is None:
        return None

    cfg = get_config()
    message_id = client.xadd(cfg.PIPELINE_STREAM_KEY, {"payload": json.dumps(payload)})
    return str(message_id)


def read_pipeline_jobs(consumer_name: str, count: int = 1, block_ms: int = 5000) -> list[dict]:
    client = _get_redis()
    if client is None:
        return []

    cfg = get_config()
    rows = client.xreadgroup(
        groupname=cfg.PIPELINE_CONSUMER_GROUP,
        consumername=consumer_name,
        streams={cfg.PIPELINE_STREAM_KEY: ">"},
        count=count,
        block=block_ms,
    )
    jobs: list[dict] = []
    for _stream, messages in rows:
        for message_id, fields in messages:
            raw = fields.get("payload") or "{}"
            jobs.append({"id": message_id, "payload": json.loads(raw)})
    return jobs


def ack_pipeline_job(message_id: str) -> None:
    client = _get_redis()
    if client is None:
        return
    cfg = get_config()
    client.xack(cfg.PIPELINE_STREAM_KEY, cfg.PIPELINE_CONSUMER_GROUP, message_id)
