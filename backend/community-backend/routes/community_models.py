"""
Shared request and response models for community routes.
used for organizing and standardizing the data structures across different route modules, 
"""
from typing import List, Optional

from pydantic import BaseModel


class PostCreate(BaseModel):
    """Schema for creating a post."""
    subthread_id: str
    title: str
    content: str


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
