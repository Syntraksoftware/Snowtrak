"""
Shared modules across all backend services.
"""

from .contracts import (
    ERROR_CODES,
    ErrorDetails,
    ErrorResponse,
    ListMeta,
    ListResponse,
    PaginationMeta,
    ResponseMeta,
    SuccessResponse,
)
from .exception_handlers import (
    setup_exception_handlers,
)
from .middleware import (
    RequestIDMiddleware,
    add_request_id_middleware,
    get_request_id,
)

__all__ = [
    # Contracts
    "ErrorResponse",
    "SuccessResponse",
    "ListResponse",
    "ListMeta",
    "ResponseMeta",
    "PaginationMeta",
    "ErrorDetails",
    "ERROR_CODES",
    # Middleware
    "add_request_id_middleware",
    "get_request_id",
    "RequestIDMiddleware",
    # Exception handlers
    "setup_exception_handlers",
]
