from fastapi import status

from middleware.auth import get_current_user

# Must match StubCommunityClient post_id (UUID path params avoid /posts/feed collision).
STUB_POST_ID = "11111111-1111-1111-1111-111111111111"
STUB_POST_MISSING = "00000000-0000-0000-0000-000000000099"


class TestSubthreadEndpoints:
    def test_list_subthreads_standard(self, client):
        response = client.get("/api/v1/subthreads")

        assert response.status_code == status.HTTP_200_OK
        body = response.json()
        assert "items" in body
        assert "meta" in body
        assert body["items"][0]["id"] == "sub-1"

    def test_create_subthread_success(self, client):
        response = client.post(
            "/api/v1/subthreads",
            json={"name": "Tree Runs", "description": "Lines in the trees"},
        )

        assert response.status_code == status.HTTP_201_CREATED
        assert response.json()["name"] == "Tree Runs"

    def test_get_subthread_not_found(self, client):
        response = client.get("/api/v1/subthreads/sub-missing")

        assert response.status_code == status.HTTP_404_NOT_FOUND

    def test_list_subthread_posts_not_found(self, client):
        response = client.get("/api/v1/subthreads/sub-missing/posts")

        assert response.status_code == status.HTTP_404_NOT_FOUND

    def test_delete_subthread_not_found(self, client):
        response = client.delete("/api/v1/subthreads/sub-missing")

        assert response.status_code == status.HTTP_404_NOT_FOUND


class TestPostEndpoints:
    def test_create_post_success(self, client):
        response = client.post(
            "/api/v1/posts",
            json={
                "subthread_id": "sub-1",
                "title": "Condition report",
                "content": "Boot-deep at first chair",
            },
        )

        assert response.status_code == status.HTTP_201_CREATED
        assert response.json()["title"] == "Condition report"

    def test_create_post_subthread_not_found(self, client):
        response = client.post(
            "/api/v1/posts",
            json={
                "subthread_id": "sub-missing",
                "title": "Condition report",
                "content": "Boot-deep at first chair",
            },
        )

        assert response.status_code == status.HTTP_404_NOT_FOUND

    def test_create_post_invalid_payload(self, client):
        response = client.post(
            "/api/v1/posts",
            json={"subthread_id": "sub-1", "content": "Missing title"},
        )

        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY

    def test_get_post_not_found(self, client):
        response = client.get(f"/api/v1/posts/{STUB_POST_MISSING}")

        assert response.status_code == status.HTTP_404_NOT_FOUND

    def test_list_posts_by_user_standard(self, client):
        response = client.get("/api/v1/posts/user/user-1")

        assert response.status_code == status.HTTP_200_OK
        body = response.json()
        assert "items" in body
        assert "meta" in body
        assert body["items"][0]["post_id"] == STUB_POST_ID

    def test_list_feed_posts_canonical_path(self, client):
        """GET /api/v1/feed is the canonical feed endpoint."""
        response = client.get("/api/v1/feed?limit=10")

        assert response.status_code == status.HTTP_200_OK
        body = response.json()
        assert "items" in body
        assert body["items"][0]["post_id"] == STUB_POST_ID

    def test_legacy_feed_paths_are_not_available(self, client):
        """Only /api/v1/feed is canonical; /posts/feed should not resolve as feed."""
        r_v1 = client.get("/api/v1/posts/feed?limit=10")
        r_legacy = client.get("/api/posts/feed?limit=10")

        assert r_v1.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY
        assert r_legacy.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY

    def test_list_post_comments_not_found(self, client):
        response = client.get(f"/api/v1/posts/{STUB_POST_MISSING}/comments")

        assert response.status_code == status.HTTP_404_NOT_FOUND

    def test_batch_post_comments(self, client):
        response = client.post(
            "/api/v1/posts/comments/batch",
            json={"post_ids": [STUB_POST_ID, STUB_POST_MISSING]},
        )

        assert response.status_code == status.HTTP_200_OK
        body = response.json()
        assert "items" in body
        assert len(body["items"]) == 2
        assert body["items"][0]["post_id"] == STUB_POST_ID
        assert len(body["items"][0]["comments"]) == 1
        assert body["items"][0]["comments"][0]["id"] == "comment-1"
        assert body["items"][1]["post_id"] == STUB_POST_MISSING
        assert body["items"][1]["comments"] == []

    def test_batch_post_comments_too_many_distinct_ids(self, client):
        response = client.post(
            "/api/v1/posts/comments/batch",
            json={"post_ids": [f"p{i}" for i in range(51)]},
        )

        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY

    def test_get_post_conversation_matches_comments(self, client):
        r_comments = client.get(f"/api/v1/posts/{STUB_POST_ID}/comments")
        r_conv = client.get(f"/api/v1/posts/{STUB_POST_ID}/conversation")

        assert r_comments.status_code == status.HTTP_200_OK
        assert r_conv.status_code == status.HTTP_200_OK
        assert r_comments.json()["items"] == r_conv.json()["items"]

    def test_delete_post_not_found(self, client):
        response = client.delete(f"/api/v1/posts/{STUB_POST_MISSING}")

        assert response.status_code == status.HTTP_404_NOT_FOUND

    def test_update_post_success(self, client):
        response = client.patch(
            f"/api/v1/posts/{STUB_POST_ID}",
            json={"content": "Updated content"},
        )

        assert response.status_code == status.HTTP_200_OK
        assert response.json()["content"] == "Updated content"

    def test_vote_post_success(self, client):
        response = client.post(
            f"/api/v1/posts/{STUB_POST_ID}/vote",
            json={"vote_type": 1},
        )

        assert response.status_code == status.HTTP_200_OK
        assert response.json()["vote_value"] == 1

    def test_vote_post_invalid_type(self, client):
        response = client.post(
            f"/api/v1/posts/{STUB_POST_ID}/vote",
            json={"vote_type": 2},
        )

        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


class TestCommentEndpoints:
    def test_create_comment_success(self, client):
        response = client.post(
            "/api/v1/comments",
            json={"post_id": STUB_POST_ID, "content": "Nice route"},
        )

        assert response.status_code == status.HTTP_201_CREATED
        assert response.json()["content"] == "Nice route"

    def test_create_comment_missing_parent(self, client):
        response = client.post(
            "/api/v1/comments",
            json={
                "post_id": STUB_POST_ID,
                "content": "Reply",
                "parent_id": "comment-missing",
            },
        )

        assert response.status_code == status.HTTP_404_NOT_FOUND

    def test_get_comment_not_found(self, client):
        response = client.get("/api/v1/comments/comment-missing")

        assert response.status_code == status.HTTP_404_NOT_FOUND

    def test_delete_comment_not_found(self, client):
        response = client.delete("/api/v1/comments/comment-missing")

        assert response.status_code == status.HTTP_404_NOT_FOUND

    def test_update_comment_success(self, client):
        response = client.patch(
            "/api/v1/comments/comment-1",
            json={"content": "Updated reply"},
        )

        assert response.status_code == status.HTTP_200_OK
        assert response.json()["content"] == "Updated reply"

    def test_vote_comment_success(self, client):
        response = client.post(
            "/api/v1/comments/comment-1/vote",
            json={"vote_type": -1},
        )

        assert response.status_code == status.HTTP_200_OK
        assert response.json()["vote_value"] == -1

    def test_requires_auth_when_override_removed(self, client, app):
        app.dependency_overrides.pop(get_current_user, None)

        response = client.post(
            "/api/v1/comments",
            json={"post_id": STUB_POST_ID, "content": "Auth required"},
        )

        assert response.status_code == status.HTTP_401_UNAUTHORIZED


class TestServerErrorPath:
    def test_subthread_list_surfaces_500(self, client, stub_client):
        def explode(limit=50):
            raise RuntimeError("boom")

        stub_client.list_subthreads = explode
        response = client.get("/api/v1/subthreads")

        assert response.status_code == status.HTTP_500_INTERNAL_SERVER_ERROR
