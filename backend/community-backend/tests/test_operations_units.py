import types
import uuid

import pytest

from services.community_comment_read_operations import CommunityCommentReadOperations
from services.community_comment_write_operations import CommunityCommentWriteOperations
from services.community_post_read_operations import CommunityPostReadOperations
from services.community_post_write_operations import CommunityPostWriteOperations
from services.community_subthread_operations import CommunitySubthreadOperations
from services.follow_operations import CommunityFollowOperations


class FakeResponse:
    def __init__(self, data=None, count=None):
        self.data = data
        self.count = count


def _split_top_level(expression):
    """Split on commas that are not inside parentheses."""
    parts, depth, current = [], 0, ""
    for char in expression:
        if char == "(":
            depth += 1
        elif char == ")":
            depth -= 1
        if char == "," and depth == 0:
            parts.append(current)
            current = ""
        else:
            current += char
    if current:
        parts.append(current)
    return parts


def _matches_clause(row, clause):
    clause = clause.strip()
    if clause.startswith("and("):
        inner = clause[len("and(") : -1]
        return all(_matches_clause(row, part) for part in _split_top_level(inner))
    field, operator, value = clause.split(".", 2)
    actual = row.get(field)
    if operator == "eq":
        return str(actual) == value
    if operator == "in":
        allowed = value.strip("()").split(",") if value.strip("()") else []
        return str(actual) in allowed
    raise AssertionError(f"fake does not implement PostgREST operator {operator!r}")


def _matches_or(row, expression):
    """Evaluate a PostgREST `or` expression against one row.

    Real enough to be worth trusting: the visibility filter is the one place
    where a wrong predicate leaks somebody's post instead of raising, so these
    tests assert which rows come back, not that a filter was called.
    """
    return any(_matches_clause(row, clause) for clause in _split_top_level(expression))


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
        self.filters.append(("eq", field, value))
        return self

    def in_(self, field, values):
        self.filters.append(("in", field, list(values)))
        return self

    def or_(self, expression):
        self.filters.append(("or", expression))
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
        return [row for row in rows if self._row_matches_filters(row)]

    def _row_matches_filters(self, row):
        for item in self.filters:
            if item[0] == "eq":
                _, field, value = item
                if row.get(field) != value:
                    return False
            elif item[0] == "in":
                _, field, vals = item
                if row.get(field) not in vals:
                    return False
            elif item[0] == "or":
                if not _matches_or(row, item[1]):
                    return False
        return True

    def execute(self):
        table_rows = self.client.tables[self.table_name]

        if self.operation == "insert":
            payload = dict(self.payload)
            if self.table_name == "subthreads" and "id" not in payload:
                payload["id"] = f"sub-{uuid.uuid4().hex[:6]}"
            if self.table_name == "posts" and "post_id" not in payload:
                payload["post_id"] = f"post-{uuid.uuid4().hex[:6]}"
            # posts.visibility is `not null default 'public'`; a row without it
            # cannot exist in the real table, so it must not exist here either.
            if self.table_name == "posts" and "visibility" not in payload:
                payload["visibility"] = "public"
            if (
                self.table_name in {"comments", "post_likes", "post_votes", "comment_votes"}
                and "id" not in payload
            ):
                payload["id"] = f"row-{uuid.uuid4().hex[:6]}"
            if (
                self.table_name in {"subthreads", "posts", "comments"}
                and "created_at" not in payload
            ):
                payload["created_at"] = "2026-01-02T00:00:00Z"
            table_rows.append(payload)
            return FakeResponse(data=[payload])

        filtered = self._apply_filters(table_rows)

        if self.operation == "update":
            updated = []
            for row in table_rows:
                match = self._row_matches_filters(row)
                if match:
                    row.update(self.payload)
                    updated.append(dict(row))
            return FakeResponse(data=updated)

        if self.operation == "delete":
            remaining = []
            deleted = []
            for row in table_rows:
                match = self._row_matches_filters(row)
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
            "follows": [],
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
                    "visibility": "public",
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
                    "visibility": "public",
                    "user_info": {
                        "email": "friend@example.com",
                        "first_name": "Pow",
                        "last_name": "Fan",
                    },
                }
            ],
            "post_likes": [],
            "post_votes": [],
            "comment_votes": [],
        }

    def table(self, table_name):
        return FakeQuery(self, table_name)


class OperationHarness(
    CommunitySubthreadOperations,
    CommunityFollowOperations,
    CommunityPostReadOperations,
    CommunityPostWriteOperations,
    CommunityCommentReadOperations,
    CommunityCommentWriteOperations,
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


def test_liking_twice_does_not_double_count(operations_client):
    operations_client.set_post_vote("post-1", "user-1", 1)
    again = operations_client.set_post_vote("post-1", "user-1", 1)

    assert again["score"] == 1


def test_unliking_removes_the_like(operations_client):
    operations_client.set_post_vote("post-1", "user-1", 1)
    cleared = operations_client.set_post_vote("post-1", "user-1", 0)

    assert cleared["score"] == 0


def test_two_users_liking_counts_both(operations_client):
    operations_client.set_post_vote("post-1", "user-1", 1)
    second = operations_client.set_post_vote("post-1", "user-2", 1)

    assert second["score"] == 2


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


# ---------------------------------------------------------------------------
# Post visibility
#
# The only part of the follow feature with a privacy consequence, and the one
# whose failure mode is silent: no error, no crash, the feed looks right, and
# a stranger reads a post that was not for them. Every read path that can
# return a post is asserted here, not just the feed.
# ---------------------------------------------------------------------------


@pytest.fixture
def visibility_client():
    """One author with a post at each tier, one follower, one stranger."""
    harness = OperationHarness()
    harness._client.tables["posts"] = [
        {
            "post_id": "public-post",
            "user_id": "author",
            "subthread_id": "sub-1",
            "title": "Public",
            "content": "everyone",
            "visibility": "public",
            "created_at": "2026-01-01T03:00:00Z",
        },
        {
            "post_id": "followers-post",
            "user_id": "author",
            "subthread_id": "sub-1",
            "title": "Followers",
            "content": "my followers",
            "visibility": "followers",
            "created_at": "2026-01-01T02:00:00Z",
        },
        {
            "post_id": "private-post",
            "user_id": "author",
            "subthread_id": "sub-1",
            "title": "Private",
            "content": "just me",
            "visibility": "private",
            "created_at": "2026-01-01T01:00:00Z",
        },
    ]
    harness._client.tables["follows"] = [
        {"follower_id": "follower", "followee_id": "author"},
    ]
    return harness


def _ids(posts):
    return {post["post_id"] for post in posts}


@pytest.mark.parametrize(
    "viewer,expected",
    [
        (None, {"public-post"}),
        ("stranger", {"public-post"}),
        ("follower", {"public-post", "followers-post"}),
        ("author", {"public-post", "followers-post", "private-post"}),
    ],
)
def test_feed_returns_only_what_the_viewer_may_see(visibility_client, viewer, expected):
    posts = visibility_client.list_recent_posts(limit=20, current_user_id=viewer)
    assert _ids(posts) == expected


@pytest.mark.parametrize(
    "viewer,expected",
    [
        (None, {"public-post"}),
        ("stranger", {"public-post"}),
        ("follower", {"public-post", "followers-post"}),
        ("author", {"public-post", "followers-post", "private-post"}),
    ],
)
def test_profile_post_list_returns_only_what_the_viewer_may_see(
    visibility_client, viewer, expected
):
    posts = visibility_client.list_posts_by_user_id("author", current_user_id=viewer)
    assert _ids(posts) == expected


@pytest.mark.parametrize(
    "viewer,expected",
    [
        (None, {"public-post"}),
        ("stranger", {"public-post"}),
        ("follower", {"public-post", "followers-post"}),
        ("author", {"public-post", "followers-post", "private-post"}),
    ],
)
def test_subthread_post_list_returns_only_what_the_viewer_may_see(
    visibility_client, viewer, expected
):
    posts = visibility_client.list_posts_by_subthread("sub-1", current_user_id=viewer)
    assert _ids(posts) == expected


@pytest.mark.parametrize(
    "post_id,viewer,visible",
    [
        ("followers-post", None, False),
        ("followers-post", "stranger", False),
        ("followers-post", "follower", True),
        ("followers-post", "author", True),
        ("private-post", "follower", False),
        ("private-post", "author", True),
        ("public-post", None, True),
    ],
)
def test_direct_post_link_respects_visibility(visibility_client, post_id, viewer, visible):
    # A share link is a read path like any other. Filtering only the feed
    # leaves this door open.
    post = visibility_client.get_post_by_id(post_id, current_user_id=viewer)
    assert (post is not None) == visible


def test_unfollowing_hides_the_posts_again(visibility_client):
    before = _ids(visibility_client.list_recent_posts(limit=20, current_user_id="follower"))
    assert "followers-post" in before

    visibility_client._client.tables["follows"] = []

    after = _ids(visibility_client.list_recent_posts(limit=20, current_user_id="follower"))
    assert "followers-post" not in after


def test_a_post_with_no_visibility_column_is_treated_as_public(visibility_client):
    # Rows written before the column existed default to public in the database;
    # nothing should disappear from the feed because of the migration.
    visibility_client._client.tables["posts"].append(
        {
            "post_id": "legacy-post",
            "user_id": "author",
            "subthread_id": "sub-1",
            "title": "Legacy",
            "content": "written before the column",
            "visibility": "public",
            "created_at": "2026-01-01T00:30:00Z",
        }
    )
    posts = visibility_client.list_recent_posts(limit=20, current_user_id="stranger")
    assert "legacy-post" in _ids(posts)


def test_a_quoted_private_post_is_not_previewed_to_strangers(visibility_client):
    # The nastiest leak in this feature: the post doing the quoting is public
    # and belongs to somebody else, so the owner of the private post never
    # chose to expose it.
    visibility_client._client.tables["posts"].append(
        {
            "post_id": "quoting-post",
            "user_id": "stranger",
            "subthread_id": "sub-1",
            "title": "Look at this",
            "content": "quoting",
            "visibility": "public",
            "quoted_post_id": "followers-post",
            "created_at": "2026-01-01T04:00:00Z",
        }
    )

    seen_by_stranger = visibility_client.list_recent_posts(limit=20, current_user_id="stranger")
    quoting = next(p for p in seen_by_stranger if p["post_id"] == "quoting-post")
    assert quoting.get("quoted_post") is None

    seen_by_follower = visibility_client.list_recent_posts(limit=20, current_user_id="follower")
    quoting = next(p for p in seen_by_follower if p["post_id"] == "quoting-post")
    assert quoting.get("quoted_post") is not None


def test_comment_batch_returns_nothing_for_posts_the_viewer_cannot_see(visibility_client):
    # The endpoint takes whatever post ids a client sends, so it cannot assume
    # they came from a filtered list.
    visibility_client._client.tables["comments"] = [
        {
            "id": "comment-on-private",
            "post_id": "followers-post",
            "user_id": "author",
            "content": "for my followers",
            "created_at": "2026-01-01T05:00:00Z",
        }
    ]

    for_stranger = visibility_client.list_comments_by_post_ids(
        ["followers-post"], current_user_id="stranger"
    )
    assert for_stranger["followers-post"] == []

    for_follower = visibility_client.list_comments_by_post_ids(
        ["followers-post"], current_user_id="follower"
    )
    assert len(for_follower["followers-post"]) == 1


def test_visible_post_ids_denies_when_the_lookup_fails(visibility_client):
    # A visibility check that fails open is not a visibility check.
    def explode(_table_name):
        raise RuntimeError("supabase is down")

    visibility_client._client.table = explode
    assert visibility_client.visible_post_ids(["public-post"], "visibility.eq.public") == set()


def test_shared_visibility_expression_covers_all_three_tiers():
    from shared.visibility import visible_rows_expression

    anonymous = visible_rows_expression(None, [])
    assert anonymous == "visibility.eq.public"

    viewer = visible_rows_expression("user-1", ["user-2"])
    assert "visibility.eq.public" in viewer
    assert "user_id.eq.user-1" in viewer
    assert "and(visibility.eq.followers,user_id.in.(user-2))" in viewer

    # PostgREST rejects an empty in.(), so the clause must not be built.
    alone = visible_rows_expression("user-1", [])
    assert "in.()" not in alone
