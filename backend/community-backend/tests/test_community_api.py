from fastapi import status

from middleware.auth import get_current_user


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
        response = client.get("/api/v1/posts/post-missing")

        assert response.status_code == status.HTTP_404_NOT_FOUND

    def test_list_posts_by_user_standard(self, client):
        response = client.get("/api/v1/posts/user/user-1")

        assert response.status_code == status.HTTP_200_OK
        body = response.json()
        assert "items" in body
        assert "meta" in body
        assert body["items"][0]["post_id"] == "post-1"

    def test_list_post_comments_not_found(self, client):
        response = client.get("/api/v1/posts/post-missing/comments")

        assert response.status_code == status.HTTP_404_NOT_FOUND

    def test_delete_post_not_found(self, client):
        response = client.delete("/api/v1/posts/post-missing")

        assert response.status_code == status.HTTP_404_NOT_FOUND

    def test_update_post_success(self, client):
        response = client.patch(
            "/api/v1/posts/post-1",
            json={"content": "Updated content"},
        )

        assert response.status_code == status.HTTP_200_OK
        assert response.json()["content"] == "Updated content"

    def test_vote_post_success(self, client):
        response = client.post(
            "/api/v1/posts/post-1/vote",
            json={"vote_type": 1},
        )

        assert response.status_code == status.HTTP_200_OK
        assert response.json()["vote_value"] == 1

    def test_vote_post_invalid_type(self, client):
        response = client.post(
            "/api/v1/posts/post-1/vote",
            json={"vote_type": 2},
        )

        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


class TestCommentEndpoints:
    def test_create_comment_success(self, client):
        response = client.post(
            "/api/v1/comments",
            json={"post_id": "post-1", "content": "Nice route"},
        )

        assert response.status_code == status.HTTP_201_CREATED
        assert response.json()["content"] == "Nice route"

    def test_create_comment_missing_parent(self, client):
        response = client.post(
            "/api/v1/comments",
            json={
                "post_id": "post-1",
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
            json={"post_id": "post-1", "content": "Auth required"},
        )

        assert response.status_code == status.HTTP_401_UNAUTHORIZED


class TestServerErrorPath:
    def test_subthread_list_surfaces_500(self, client, stub_client):
        def explode(limit=50):
            raise RuntimeError("boom")

        stub_client.list_subthreads = explode
        response = client.get("/api/v1/subthreads")

        assert response.status_code == status.HTTP_500_INTERNAL_SERVER_ERROR
