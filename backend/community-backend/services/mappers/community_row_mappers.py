"""Shared row mapping helpers for community read operations."""
from typing import Any, Dict


def flatten_user_info(row: Dict[str, Any], field: str = "user_info") -> None:
    author = row.get(field)
    if not author:
        return
    row.pop(field, None)
    row["author_email"] = author.get("email")
    row["author_first_name"] = author.get("first_name")
    row["author_last_name"] = author.get("last_name")
