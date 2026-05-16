"""Shared validator helpers for post/comment write routes."""

from fastapi import HTTPException, status


def ensure_vote_type(value: int) -> None:
    if value not in (-1, 0, 1):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="vote_type must be one of: -1, 0, 1",
        ) from None


def ensure_text_or_media(content: str, media_urls: list[str], detail: str) -> None:
    if not (content or "").strip() and not media_urls:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=detail,
        ) from None
