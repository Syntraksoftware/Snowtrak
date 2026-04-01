"""Shared vote/repost persistence helpers."""
from typing import Any, Dict


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
        payload: Dict[str, Any] = {
            entity_field: entity_id,
            "user_id": user_id,
            "vote_value": vote_type,
        }
        if isinstance(getattr(existing, "data", None), list) and getattr(existing, "data"):
            client.table(table_name).update({"vote_value": vote_type}).eq(
                entity_field, entity_id
            ).eq("user_id", user_id).execute()
        else:
            client.table(table_name).insert(payload).execute()

    score_response = client.table(table_name).select("vote_value").eq(
        entity_field, entity_id
    ).execute()
    score_rows = getattr(score_response, "data", None)
    if not isinstance(score_rows, list):
        return 0
    return sum(int(row.get("vote_value", 0)) for row in score_rows)
