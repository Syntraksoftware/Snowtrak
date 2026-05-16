"""Post operations composed from read and write post mixins."""

from services.community_post_read_operations import CommunityPostReadOperations
from services.community_post_write_operations import CommunityPostWriteOperations


class CommunityPostOperations(
    CommunityPostReadOperations,
    CommunityPostWriteOperations,
):
    """Compatibility wrapper that exposes all post operations."""
