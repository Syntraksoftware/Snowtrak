"""Shared vote/repost persistence helpers."""

from typing import Any


def set_vote(
    client: Any,
    *,
    table_name: str,
    entity_field: str,
    entity_id: str,
    user_id: str,
    vote_type: int,
) -> int:
    if vote_type == 0:
        client.table(table_name).delete().eq(entity_field, entity_id).eq(
            "user_id",
            user_id,
        ).execute()
    else:
        existing = (
            client.table(table_name)
            .select("id")
            .eq(entity_field, entity_id)
            .eq("user_id", user_id)
            .limit(1)
            .execute()
        )
        payload: dict[str, Any] = {
            entity_field: entity_id,
            "user_id": user_id,
            "vote_value": vote_type,
        }
        if isinstance(getattr(existing, "data", None), list) and existing.data:
            client.table(table_name).update({"vote_value": vote_type}).eq(
                entity_field, entity_id
            ).eq("user_id", user_id).execute()
        else:
            client.table(table_name).insert(payload).execute()

    score_response = (
        client.table(table_name).select("vote_value").eq(entity_field, entity_id).execute()
    )
    score_rows = getattr(score_response, "data", None)
    if not isinstance(score_rows, list):
        return 0
    return sum(int(row.get("vote_value", 0)) for row in score_rows)


def set_like(
    client: Any,
    *,
    table_name: str,
    entity_field: str,
    entity_id: str,
    user_id: str,
    liked: bool,
) -> int:
    """Add or remove one like, and return the entity's like count.

    A like is the presence of a row, so there is no value to update the way
    set_vote does. The unique constraint on (entity, user) means liking twice
    is a no-op rather than a second row, but the read below keeps the insert
    from relying on the constraint to raise.
    """
    if liked:
        existing = (
            client.table(table_name)
            .select("id")
            .eq(entity_field, entity_id)
            .eq("user_id", user_id)
            .limit(1)
            .execute()
        )
        rows = getattr(existing, "data", None)
        if not (isinstance(rows, list) and rows):
            client.table(table_name).insert(
                {entity_field: entity_id, "user_id": user_id}
            ).execute()
    else:
        client.table(table_name).delete().eq(entity_field, entity_id).eq(
            "user_id",
            user_id,
        ).execute()

    count_response = (
        client.table(table_name).select("id").eq(entity_field, entity_id).execute()
    )
    count_rows = getattr(count_response, "data", None)
    return len(count_rows) if isinstance(count_rows, list) else 0
