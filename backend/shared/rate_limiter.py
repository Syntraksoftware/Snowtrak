"""Redis-backed request rate limiting shared across backend services."""

from __future__ import annotations

import fnmatch
import logging
import time
from dataclasses import dataclass
from typing import Callable, Iterable, Optional

from fastapi import FastAPI
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import JSONResponse, Response

import redis.asyncio as redis

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class RateLimitPolicy:
    """A route/method-specific rate limit policy."""

    path_pattern: str
    methods: Optional[set[str]]
    limit: int
    window_seconds: int

    @classmethod
    def from_dict(cls, value: dict) -> "RateLimitPolicy":
        methods = value.get("methods")
        normalized_methods = None

        if methods:
            normalized_methods = {method.upper() for method in methods}

        return cls(
            path_pattern=value["path_pattern"],
            methods=normalized_methods,
            limit=int(value["limit"]),
            window_seconds=int(value["window_seconds"]),
        )


def _default_client_key(request: Request) -> str:
    forwarded_for = request.headers.get("x-forwarded-for")
    if forwarded_for:
        return forwarded_for.split(",")[0].strip()

    if request.client and request.client.host:
        return request.client.host

    return "unknown"


class RedisRateLimitMiddleware(BaseHTTPMiddleware):
    """Middleware that enforces Redis-backed rate limits by method and route."""

    def __init__(
        self,
        app,
        *,
        redis_client: redis.Redis,
        namespace: str,
        policies: Iterable[RateLimitPolicy],
        default_policy: Optional[RateLimitPolicy] = None,
        client_key_func: Optional[Callable[[Request], str]] = None,
        fail_open: bool = True,
    ):
        super().__init__(app)
        self.redis_client = redis_client
        self.namespace = namespace
        self.policies = list(policies)
        self.default_policy = default_policy
        self.client_key_func = client_key_func or _default_client_key
        self.fail_open = fail_open

    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        policy = self._select_policy(request)

        if policy is None:
            return await call_next(request)

        method = request.method.upper()
        path = request.url.path
        client_key = self.client_key_func(request)
        now = int(time.time())
        window_bucket = now // policy.window_seconds
        redis_key = (
            f"rate_limit:{self.namespace}:{method}:{path}:{client_key}:{window_bucket}"
        )

        try:
            request_count = await self.redis_client.incr(redis_key)

            if request_count == 1:
                await self.redis_client.expire(redis_key, policy.window_seconds)

            ttl = await self.redis_client.ttl(redis_key)
            retry_after = max(ttl, 0)
            remaining = max(policy.limit - int(request_count), 0)

            if int(request_count) > policy.limit:
                return JSONResponse(
                    status_code=429,
                    content={
                        "detail": "Rate limit exceeded",
                        "limit": policy.limit,
                        "window_seconds": policy.window_seconds,
                        "retry_after": retry_after,
                    },
                    headers={
                        "Retry-After": str(retry_after),
                        "X-RateLimit-Limit": str(policy.limit),
                        "X-RateLimit-Remaining": "0",
                        "X-RateLimit-Reset": str(now + retry_after),
                    },
                )

            response = await call_next(request)
            response.headers["X-RateLimit-Limit"] = str(policy.limit)
            response.headers["X-RateLimit-Remaining"] = str(remaining)
            response.headers["X-RateLimit-Reset"] = str(now + retry_after)
            return response

        except Exception as exc:
            if self.fail_open:
                logger.warning(
                    "Rate limiter failed open for %s %s: %s",
                    method,
                    path,
                    exc,
                )
                return await call_next(request)

            logger.error("Rate limiter failed closed for %s %s: %s", method, path, exc)
            return JSONResponse(
                status_code=503,
                content={"detail": "Rate limiting unavailable"},
            )

    def _select_policy(self, request: Request) -> Optional[RateLimitPolicy]:
        method = request.method.upper()
        path = request.url.path

        for policy in self.policies:
            method_matches = policy.methods is None or method in policy.methods
            path_matches = fnmatch.fnmatch(path, policy.path_pattern)

            if method_matches and path_matches:
                return policy

        return self.default_policy


def add_redis_rate_limiter(
    app: FastAPI,
    *,
    redis_url: str,
    namespace: str,
    policies: Iterable[dict | RateLimitPolicy],
    default_limit: Optional[int] = None,
    default_window_seconds: int = 60,
    client_key_func: Optional[Callable[[Request], str]] = None,
    fail_open: bool = True,
) -> None:
    """Attach Redis-backed rate limiter middleware to a FastAPI app."""

    parsed_policies: list[RateLimitPolicy] = []

    for policy in policies:
        if isinstance(policy, RateLimitPolicy):
            parsed_policies.append(policy)
        else:
            parsed_policies.append(RateLimitPolicy.from_dict(policy))

    default_policy = None
    if default_limit is not None:
        default_policy = RateLimitPolicy(
            path_pattern="*",
            methods=None,
            limit=int(default_limit),
            window_seconds=int(default_window_seconds),
        )

    redis_client = redis.from_url(redis_url, decode_responses=True)

    app.add_middleware(
        RedisRateLimitMiddleware,
        redis_client=redis_client,
        namespace=namespace,
        policies=parsed_policies,
        default_policy=default_policy,
        client_key_func=client_key_func,
        fail_open=fail_open,
    )

    @app.on_event("shutdown")
    async def _close_rate_limiter_redis() -> None:
        await redis_client.aclose()
