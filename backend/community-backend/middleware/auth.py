"""Authentication utilities for JWT verification."""

import logging

from shared.auth import build_auth_dependencies

from config import get_config

config = get_config()
logger = logging.getLogger(__name__)

get_current_user, get_optional_user = build_auth_dependencies(
    jwt_secret=config.JWT_SECRET,
    jwt_algorithm=config.JWT_ALGORITHM,
    logger=logger,
)
