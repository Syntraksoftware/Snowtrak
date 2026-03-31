"""Write-oriented post routes."""
import logging
import os
import sys
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status

# Add backend directory to path for shared imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from middleware.auth import get_current_user
from routes.community_models import (
    CommunityDeletePostResponse,
    CommunityPostResponse,
    PostRepostResponse,
    PostCreate,
    PostUpdate,
    PostVoteRequest,
    PostVoteResponse,
)
from services.supabase_client import get_community_client

logger = logging.getLogger(__name__)
router = APIRouter()


@router.post("/", response_model=CommunityPostResponse, status_code=status.HTTP_201_CREATED)
async def create_post(
    data: PostCreate,
    user_id: str = Depends(get_current_user),
):
    """Create a new post."""
    community_client = get_community_client()
    try:
        subthread = community_client.get_subthread_by_id(data.subthread_id)
        if not subthread:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Subthread not found",
            )

        quoted_id = (data.quoted_post_id or "").strip() or None
        quoted_comment_id = (data.quoted_comment_id or "").strip() or None
        if quoted_id and quoted_comment_id:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Cannot quote both a post and a comment",
            )

        if quoted_id:
            qpost = community_client.get_post_by_id(quoted_id)
            if not qpost:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Quoted post not found",
                )

        if quoted_comment_id:
            qcom = community_client.get_comment_by_id(quoted_comment_id)
            if not qcom:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Quoted comment not found",
                )

        repost_of_id = (data.repost_of_post_id or "").strip() or None
        repost_of_comment_id = (data.repost_of_comment_id or "").strip() or None
        if repost_of_id and repost_of_comment_id:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Cannot duplicate-repost both a post and a comment",
            )

        if repost_of_id:
            parent = community_client.get_post_by_id(repost_of_id)
            if not parent:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Repost target post not found",
                )

        if repost_of_comment_id:
            parent_comment = community_client.get_comment_by_id(repost_of_comment_id)
            if not parent_comment:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Repost target comment not found",
                )

        created_post = community_client.create_post(
            user_id=user_id,
            subthread_id=data.subthread_id,
            title=data.title,
            content=data.content,
            quoted_post_id=quoted_id,
            repost_of_post_id=repost_of_id,
            quoted_comment_id=quoted_comment_id,
            repost_of_comment_id=repost_of_comment_id,
        )
        if not created_post:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create post",
            )

        return created_post
    except HTTPException:
        raise
    except Exception as exception:
        logger.error(f"Error creating post: {exception}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal Server Error",
        )


@router.post("/{post_id}/repost", response_model=PostRepostResponse)
async def repost_post(
    post_id: UUID,
    user_id: str = Depends(get_current_user),
):
    """Create/keep repost marker for a post."""
    community_client = get_community_client()
    try:
        result = community_client.set_post_repost(
            post_id=str(post_id),
            user_id=user_id,
            reposted=True,
        )
        if not result:
            if community_client.get_post_by_id(str(post_id)):
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Could not save repost. If this continues, check that "
                    "the post_reposts table exists (see community-backend SQL setup).",
                )
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Post not found",
            )
        return result
    except HTTPException:
        raise
    except Exception as exception:
        logger.error("Error reposting post: %s", exception)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal Server Error",
        )


@router.delete("/{post_id}/repost", response_model=PostRepostResponse)
async def undo_repost_post(
    post_id: UUID,
    user_id: str = Depends(get_current_user),
):
    """Remove repost marker for a post."""
    community_client = get_community_client()
    try:
        result = community_client.set_post_repost(
            post_id=str(post_id),
            user_id=user_id,
            reposted=False,
        )
        if not result:
            if community_client.get_post_by_id(str(post_id)):
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Could not update repost. If this continues, check that "
                    "the post_reposts table exists (see community-backend SQL setup).",
                )
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Post not found",
            )
        return result
    except HTTPException:
        raise
    except Exception as exception:
        logger.error("Error removing repost on post: %s", exception)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal Server Error",
        )


@router.patch("/{post_id}", response_model=CommunityPostResponse)
async def update_post(
    post_id: UUID,
    data: PostUpdate,
    user_id: str = Depends(get_current_user),
):
    """Update a post owned by the authenticated user."""
    community_client = get_community_client()
    try:
        updated_post = community_client.update_post(
            post_id=str(post_id),
            user_id=user_id,
            title=data.title,
            content=data.content,
        )
        if not updated_post:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Post not found or unauthorized",
            )

        return updated_post
    except HTTPException:
        raise
    except Exception as exception:
        logger.error(f"Error updating post: {exception}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal Server Error",
        )


@router.post("/{post_id}/vote", response_model=PostVoteResponse)
async def vote_post(
    post_id: UUID,
    data: PostVoteRequest,
    user_id: str = Depends(get_current_user),
):
    """Vote on a post with values -1, 0, or 1."""
    if data.vote_type not in (-1, 0, 1):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="vote_type must be one of: -1, 0, 1",
        )

    community_client = get_community_client()
    try:
        vote_result = community_client.set_post_vote(
            post_id=str(post_id),
            user_id=user_id,
            vote_type=data.vote_type,
        )
        if not vote_result:
            if community_client.get_post_by_id(str(post_id)):
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Could not save vote. If this continues, check that "
                    "the post_votes table exists (see community-backend SQL setup).",
                )
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Post not found",
            )

        return vote_result
    except HTTPException:
        raise
    except Exception as exception:
        logger.error(f"Error voting post: {exception}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal Server Error",
        )


@router.delete("/{post_id}", response_model=CommunityDeletePostResponse)
async def delete_post(
    post_id: UUID,
    user_id: str = Depends(get_current_user),
):
    """Delete a post and related comments."""
    community_client = get_community_client()
    try:
        is_deleted = community_client.delete_post(str(post_id), user_id)
        if not is_deleted:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Post not found or unauthorized",
            )

        return CommunityDeletePostResponse(
            message="Post and all comments deleted successfully",
            deleted_post_id=str(post_id),
        )
    except HTTPException:
        raise
    except Exception as exception:
        logger.error(f"Error deleting post: {exception}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal Server Error",
        )
