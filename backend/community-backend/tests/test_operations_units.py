import types
import uuid

import pytest

from services.community_comment_operations import CommunityCommentOperations
from services.community_post_operations import CommunityPostOperations
from services.community_subthread_operations import CommunitySubthreadOperations


class FakeResponse:
    def __init__(self, data=None, count=None):
        self.data = data
        self.count = count


class FakeQuery:
    def __init__(self, client, table_name):
        self.client = client
        self.table_name = table_name
        self.operation = "select"
        self.payload = None
        self.filters = []
        self.range_window = None
        self.limit_value = None
        self.order_field = None
        self.order_desc = False
        self.count_requested = False

    def select(self, _columns, count=None):
        self.operation = "select"
        self.count_requested = count is not None
        return self

    def insert(self, payload):
        self.operation = "insert"
        self.payload = payload
        return self

    def update(self, payload):
        self.operation = "update"
        self.payload = payload
        return self

    def delete(self):
        self.operation = "delete"
        return self

    def eq(self, field, value):
        self.filters.append((field, value))
        return self

    def order(self, field, desc=False):
        self.order_field = field
        self.order_desc = desc
        return self

    def range(self, start, end):
        self.range_window = (start, end)
        return self

    def limit(self, value):
        self.limit_value = value
        return self

    def _apply_filters(self, rows):
        filtered = list(rows)
        for field, value in self.filters:
            filtered = [row for row in filtered if row.get(field) == value]
        return filtered

    def execute(self):
        table_rows = self.client.tables[self.table_name]

        if self.operation == "insert":
            payload = dict(self.payload)
            if self.table_name == "subthreads" and "id" not in payload:
                payload["id"] = f"sub-{uuid.uuid4().hex[:6]}"
            if self.table_name == "posts" and "post_id" not in payload:
                payload["post_id"] = f"post-{uuid.uuid4().hex[:6]}"
            if self.table_name in {"comments", "post_votes", "comment_votes"} and "id" not in payload:
                payload["id"] = f"row-{uuid.uuid4().hex[:6]}"
            if self.table_name in {"subthreads", "posts", "comments"} and "created_at" not in payload:
                payload["created_at"] = "2026-01-02T00:00:00Z"
            table_rows.append(payload)
            return FakeResponse(data=[payload])

        filtered = self._apply_filters(table_rows)

        if self.operation == "update":
            updated = []
            for row in table_rows:
                match = all(row.get(field) == value for field, value in self.filters)
                if match:
                    row.update(self.payload)
                    updated.append(dict(row))
            return FakeResponse(data=updated)

        if self.operation == "delete":
            remaining = []
            deleted = []
            for row in table_rows:
                match = all(row.get(field) == value for field, value in self.filters)
                if match:
                    deleted.append(dict(row))
                else:
                    remaining.append(row)
            self.client.tables[self.table_name] = remaining
            return FakeResponse(data=deleted)

        rows = [dict(row) for row in filtered]

        if self.order_field:
            rows.sort(key=lambda item: item.get(self.order_field), reverse=self.order_desc)

        if self.range_window is not None:
            start, end = self.range_window
            rows = rows[start : end + 1]

        if self.limit_value is not None:
            rows = rows[: self.limit_value]

        count_value = len(filtered) if self.count_requested else None
        return FakeResponse(data=rows, count=count_value)


class FakeSupabaseClient:
    def __init__(self):
        self.tables = {
            "subthreads": [
                {
                    "id": "sub-1",
                    "name": "Powder",
                    "description": "Pow lines",
                    "created_at": "2026-01-01T00:00:00Z",
                }
            ],
            "posts": [
                {
                    "post_id": "post-1",
                    "user_id": "user-1",
                    "subthread_id": "sub-1",
                    "title": "First post",
                    "content": "Fresh snow",
                    "created_at": "2026-01-01T01:00:00Z",
                    "user_info": {
                        "email": "user@example.com",
                        "first_name": "Sky",
                        "last_name": "Rider",
                    },
                }
            ],
            "comments": [
                {
                    "id": "comment-1",
                    "user_id": "user-2",
                    "post_id": "post-1",
                    "content": "Nice line",
                    "parent_id": None,
                    "created_at": "2026-01-01T02:00:00Z",
                    "user_info": {
                        "email": "friend@example.com",
                        "first_name": "Pow",
                        "last_name": "Fan",
                    },
                }
            ],
            "post_votes": [],
            "comment_votes": [],
        }

    def table(self, table_name):
        return FakeQuery(self, table_name)


class OperationHarness(
    CommunitySubthreadOperations,
    CommunityPostOperations,
    CommunityCommentOperations,
):
    def __init__(self):
        self._client = FakeSupabaseClient()


@pytest.fixture(autouse=True)
def patch_postgrest_count_method(monkeypatch):
    monkeypatch.setitem(
        __import__("sys").modules,
        "postgrest",
        types.SimpleNamespace(CountMethod=types.SimpleNamespace(exact="exact")),
    )


@pytest.fixture
def operations_client():
    return OperationHarness()


def test_create_and_get_subthread(operations_client):
    created = operations_client.create_subthread(name="Touring", description="Backcountry")

    assert created is not None
    loaded = operations_client.get_subthread_by_name("Touring")
    assert loaded is not None
    assert loaded["description"] == "Backcountry"


def test_delete_subthread_not_found_returns_false(operations_client):
    deleted = operations_client.delete_subthread("sub-missing")

    assert deleted is False


def test_get_post_by_id_flattens_author(operations_client):
    post = operations_client.get_post_by_id("post-1")

    assert post is not None
    assert post["author_email"] == "user@example.com"
    assert "user_info" not in post


def test_update_post_enforces_owner(operations_client):
    denied = operations_client.update_post("post-1", "someone-else", title="Nope")
    allowed = operations_client.update_post("post-1", "user-1", title="Updated")

    assert denied is None
    assert allowed is not None
    assert allowed["title"] == "Updated"


def test_set_post_vote_computes_score(operations_client):
    vote_result = operations_client.set_post_vote("post-1", "user-1", 1)

    assert vote_result is not None
    assert vote_result["vote_value"] == 1
    assert vote_result["score"] == 1


def test_count_posts_by_subthread(operations_client):
    total = operations_client.count_posts_by_subthread("sub-1")

    assert total == 1


def test_create_comment_and_list_comments(operations_client):
    created = operations_client.create_comment("user-1", "post-1", "Great run")
    listed = operations_client.list_comments_by_post("post-1")

    assert created is not None
    assert created["has_parent"] is False
    assert len(listed) >= 1


def test_update_comment_enforces_owner(operations_client):
    denied = operations_client.update_comment("comment-1", "user-1", "new")
    allowed = operations_client.update_comment("comment-1", "user-2", "new")

    assert denied is None
    assert allowed is not None
    assert allowed["content"] == "new"


def test_set_comment_vote_invalid_type_returns_none(operations_client):
    result = operations_client.set_comment_vote("comment-1", "user-1", 2)

    assert result is None


def test_delete_comment_owner_required(operations_client):
    denied = operations_client.delete_comment("comment-1", "user-1")
    allowed = operations_client.delete_comment("comment-1", "user-2")

    assert denied is False
    assert allowed is True


def test_count_comments_by_post(operations_client):
    total = operations_client.count_comments_by_post("post-1")

    assert total == 1
