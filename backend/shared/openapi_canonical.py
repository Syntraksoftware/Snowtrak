"""
OpenAPI / Swagger helpers — document canonical ``/api/v1/*`` routes only.

Non-canonical paths are excluded from the generated schema so ``/docs`` reflects
the supported contract.
"""

from __future__ import annotations

from typing import Any

from fastapi import FastAPI
from fastapi.openapi.utils import get_openapi

CANONICAL_API_DESCRIPTION = """
## Canonical API surface

All supported clients MUST use **`/api/v1/*`** paths documented here.
"""


def configure_canonical_openapi(
    app: FastAPI,
    *,
    service_title: str,
    service_version: str = "1.0.0",
    canonical_prefix: str = "/api/v1",
) -> None:
    """Attach a filtered OpenAPI generator that drops deprecated-tagged operations."""

    def custom_openapi() -> dict[str, Any]:
        if app.openapi_schema:
            return app.openapi_schema

        schema = get_openapi(
            title=service_title,
            version=service_version,
            description=CANONICAL_API_DESCRIPTION.strip(),
            routes=app.routes,
        )

        schema["info"]["x-canonical-prefix"] = canonical_prefix

        paths: dict[str, Any] = {}
        for path, path_item in schema.get("paths", {}).items():
            if not path.startswith(canonical_prefix):
                continue

            filtered_path_item: dict[str, Any] = {}
            for method, operation in path_item.items():
                if method.startswith("x-"):
                    filtered_path_item[method] = operation
                    continue
                tags = operation.get("tags") or []
                if any("deprecated" in tag.lower() for tag in tags):
                    continue
                filtered_path_item[method] = operation

            if any(k for k in filtered_path_item if not k.startswith("x-")):
                paths[path] = filtered_path_item

        schema["paths"] = paths
        app.openapi_schema = schema
        return app.openapi_schema

    app.openapi = custom_openapi  # type: ignore[method-assign]
