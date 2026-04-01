"""
Shared request and response models for community routes.
used for organizing and standardizing the data structures across different route modules, 
"""
from typing import List, Optional

from pydantic import BaseModel, Field


class PostCreate(BaseModel):
    """Schema for creating a post."""
    subthread_id: str
    title: str
    content: str
    quoted_post_id: Optional[str] = None
    repost_of_post_id: Optional[str] = None
    quoted_comment_id: Optional[str] = None
    repost_of_comment_id: Optional[str] = None
    media_urls: Optional[List[str]] = None


class CommunityQuotedPostPreview(BaseModel):
    """Minimal quoted post payload for quote posts (text-only)."""
    post_id: str
    user_id: str
    title: str
    content: str
    created_at: str
    author_email: Optional[str] = None
    author_first_name: Optional[str] = None
    author_last_name: Optional[str] = None


class CommunityQuotedCommentPreview(BaseModel):
    """Minimal quoted comment payload for quote posts (text-only)."""
    id: str
    user_id: str
    content: str
    created_at: str
    author_email: Optional[str] = None
    author_first_name: Optional[str] = None
    author_last_name: Optional[str] = None


class PostUpdate(BaseModel):
    """Schema for updating a post."""
    title: Optional[str] = None
    content: Optional[str] = None


class PostVoteRequest(BaseModel):
    """Schema for voting on a post."""
    vote_type: int


class PostVoteResponse(BaseModel):
    """Schema for post vote response."""
    post_id: str
    user_id: str
    vote_value: int
    score: int


class PostRepostResponse(BaseModel):
    """Schema for post repost toggle response."""
    post_id: str
    user_id: str
    reposted: bool
    repost_count: int


class CommunityPostResponse(BaseModel):
    """Schema for post response payload."""
    post_id: str
    user_id: str
    subthread_id: str
    title: str
    content: str
    created_at: str
    author_email: Optional[str] = None
    author_first_name: Optional[str] = None
    author_last_name: Optional[str] = None
    like_count: int = 0
    liked_by_current_user: bool = False
    repost_count: int = 0
    reposted_by_current_user: bool = False
    share_count: int = 0
    quoted_post_id: Optional[str] = None
    quoted_post: Optional[CommunityQuotedPostPreview] = None
    repost_of_post_id: Optional[str] = None
    quoted_comment_id: Optional[str] = None
    quoted_comment: Optional[CommunityQuotedCommentPreview] = None
    repost_of_comment_id: Optional[str] = None
    media_urls: List[str] = Field(default_factory=list)


class CommunityCommentResponse(BaseModel):
    """Schema for comment response payload."""
    id: str
    user_id: str
    post_id: str
    parent_id: Optional[str] = None
    content: str
    has_parent: bool
    created_at: str
    author_email: Optional[str] = None
    author_first_name: Optional[str] = None
    author_last_name: Optional[str] = None
    repost_count: int = 0
    reposted_by_current_user: bool = False
    media_urls: List[str] = Field(default_factory=list)


class CommunityDeletePostResponse(BaseModel):
    """Schema for post delete response."""
    message: str
    deleted_post_id: Optional[str] = None


class SubthreadCreate(BaseModel):
    """Schema for creating a subthread."""
    name: str
    description: Optional[str] = None


class CommunitySubthreadResponse(BaseModel):
    """Schema for subthread response payload."""
    id: str
    name: str
    description: Optional[str] = None
    created_at: str


class CommunitySubthreadDeleteResponse(BaseModel):
    """Schema for subthread delete response."""
    message: str
    deleted_subthread_id: Optional[str] = None


class CommentCreate(BaseModel):
    """Schema for creating a comment."""
    post_id: str
    content: str
    parent_id: Optional[str] = None
    media_urls: Optional[List[str]] = None


class CommentUpdate(BaseModel):
    """Schema for updating a comment."""
    content: str


class CommentVoteRequest(BaseModel):
    """Schema for voting on a comment."""
    vote_type: int


class CommentVoteResponse(BaseModel):
    """Schema for comment vote response."""
    comment_id: str
    user_id: str
    vote_value: int
    score: int


class CommunityDeleteCommentResponse(BaseModel):
    """Schema for comment delete response."""
    message: str
    deleted_comment_id: Optional[str] = None


class CommunityPostListResponse(BaseModel):
    """Schema for post list items in standardized envelopes."""
    items: List[CommunityPostResponse]


class CommunityCommentListResponse(BaseModel):
    """Schema for comment list items in standardized envelopes."""
    items: List[CommunityCommentResponse]


class CommentsBatchRequest(BaseModel):
    """Request body for fetching comments for many posts at once."""

    post_ids: List[str]


class PostCommentsBundle(BaseModel):
    """All comments for one post (chronological), for batch responses."""

    post_id: str
    comments: List[CommunityCommentResponse]


class CommentsBatchResponse(BaseModel):
    """Batch comments response; order of items matches deduped request order."""

    items: List[PostCommentsBundle]
