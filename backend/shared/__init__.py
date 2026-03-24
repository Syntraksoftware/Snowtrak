"""
Shared modules across all backend services.
"""

from .contracts import (
    ErrorResponse,
    SuccessResponse,
    ListResponse,
    ListMeta,
    ResponseMeta,
    PaginationMeta,
    ErrorDetails,
    ERROR_CODES,
)
from .middleware import (
    add_request_id_middleware,
    get_request_id,
    RequestIDMiddleware,
)
from .exception_handlers import (
    setup_exception_handlers,
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
