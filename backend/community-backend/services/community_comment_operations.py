"""Comment operations composed from read and write comment mixins."""

from services.community_comment_read_operations import CommunityCommentReadOperations
from services.community_comment_write_operations import CommunityCommentWriteOperations


class CommunityCommentOperations(
    CommunityCommentReadOperations,
    CommunityCommentWriteOperations,
):
    """Compatibility wrapper that exposes all comment operations."""
