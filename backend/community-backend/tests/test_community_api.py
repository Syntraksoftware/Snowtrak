from fastapi import status

from middleware.auth import get_current_user

# Must match StubCommunityClient post_id (UUID path params avoid /posts/feed collision).
STUB_POST_ID = "11111111-1111-1111-1111-111111111111"
STUB_POST_MISSING = "00000000-0000-0000-0000-000000000099"
STUB_MEDIA_URL = "https://stub.supabase.co/storage/v1/object/public/community-media/user-1/x.png"


class _FakeMediaConfig:
    SUPABASE_URL = "https://stub.supabase.co"
    MEDIA_INLINE_CACHE_TTL_SECONDS = 86400
    MEDIA_INLINE_MAX_BYTES = 5 * 1024 * 1024


class _FakeImageResponse:
    status_code = 200
    headers = {"content-type": "image/png"}
    content = b"\x89PNG\r\n\x1a\n\x00"


class _FakeAsyncClient:
    def __init__(self, *args, **kwargs):
        pass

    async def __aenter__(self):
        return self

    async def __aexit__(self, exc_type, exc, tb):
        return False

    async def get(self, url):
        assert url == STUB_MEDIA_URL
        return _FakeImageResponse()


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

    def test_upload_media_success(self, client):
        response = client.post(
            "/api/v1/media/upload",
            files={
                "file": ("x.png", b"\x89PNG\r\n\x1a\n\x00", "image/png"),
            },
        )
        assert response.status_code == status.HTTP_201_CREATED
        body = response.json()
        assert "url" in body
        assert "community-media" in body["url"]

    def test_list_feed_posts_includes_cached_inline_media_asset(
        self,
        client,
        monkeypatch,
        stub_client,
    ):
        from routes import posts_read_routes
        from services import community_media_assets

        async def fake_get_cached_image(url):
            assert url == STUB_MEDIA_URL
            return b"cached-image", "image/png"

        async def fake_get_cached_json(key):
            return None

        async def fake_set_cached_json(key, value, ttl_seconds):
            return None

        stub_client.post["media_urls"] = [STUB_MEDIA_URL]
        monkeypatch.setattr(posts_read_routes, "get_cached_json", fake_get_cached_json)
        monkeypatch.setattr(posts_read_routes, "set_cached_json", fake_set_cached_json)
        monkeypatch.setattr(
            community_media_assets,
            "get_config",
            lambda: _FakeMediaConfig(),
        )
        monkeypatch.setattr(
            community_media_assets,
            "get_cached_image",
            fake_get_cached_image,
        )

        response = client.get("/api/v1/feed?limit=10")

        assert response.status_code == status.HTTP_200_OK
        item = response.json()["items"][0]
        assert item["media_urls"] == [STUB_MEDIA_URL]
        assert item["media_assets"] == [
            {
                "url": STUB_MEDIA_URL,
                "content_type": "image/png",
                "encoding": "base64",
                "data": "Y2FjaGVkLWltYWdl",
                "size_bytes": 12,
                "cache_status": "HIT",
            }
        ]

    def test_get_post_fetches_and_caches_inline_media_asset(
        self,
        client,
        monkeypatch,
        stub_client,
    ):
        from services import community_media_assets

        stored = {}

        async def fake_get_cached_image(url):
            return None

        async def fake_set_cached_image(url, body, content_type, ttl_seconds):
            stored["url"] = url
            stored["body"] = body
            stored["content_type"] = content_type
            stored["ttl_seconds"] = ttl_seconds

        stub_client.post["media_urls"] = [STUB_MEDIA_URL]
        monkeypatch.setattr(
            community_media_assets,
            "get_config",
            lambda: _FakeMediaConfig(),
        )
        monkeypatch.setattr(
            community_media_assets,
            "get_cached_image",
            fake_get_cached_image,
        )
        monkeypatch.setattr(
            community_media_assets,
            "set_cached_image",
            fake_set_cached_image,
        )
        monkeypatch.setattr(
            community_media_assets.httpx,
            "AsyncClient",
            _FakeAsyncClient,
        )

        response = client.get(f"/api/v1/posts/{STUB_POST_ID}")

        assert response.status_code == status.HTTP_200_OK
        body = response.json()
        assert body["media_assets"][0]["cache_status"] == "MISS"
        assert body["media_assets"][0]["data"] == "iVBORw0KGgoA"
        assert stored == {
            "url": STUB_MEDIA_URL,
            "body": _FakeImageResponse.content,
            "content_type": "image/png",
            "ttl_seconds": 86400,
        }

    def test_upload_media_octet_stream_heic_filename(self, client):
        response = client.post(
            "/api/v1/media/upload",
            files={
                "file": ("IMG_1234.heic", b"fake-bytes", "application/octet-stream"),
            },
        )
        assert response.status_code == status.HTTP_201_CREATED
        assert "url" in response.json()

    def test_upload_media_unsupported_type(self, client):
        response = client.post(
            "/api/v1/media/upload",
            files={
                "file": ("malware.exe", b"MZ", "application/octet-stream"),
            },
        )
        assert response.status_code == status.HTTP_415_UNSUPPORTED_MEDIA_TYPE

    def test_upload_media_too_large(self, client):
        response = client.post(
            "/api/v1/media/upload",
            files={
                "file": (
                    "huge.png",
                    b"x" * (50 * 1024 * 1024 + 1),
                    "image/png",
                ),
            },
        )
        assert response.status_code == status.HTTP_413_REQUEST_ENTITY_TOO_LARGE

    def test_create_post_with_media_urls(self, client):
        url = "https://stub.supabase.co/storage/v1/object/public/community-media/u/y.png"
        response = client.post(
            "/api/v1/posts",
            json={
                "subthread_id": "sub-1",
                "title": "Pic",
                "content": "Check this",
                "media_urls": [url],
            },
        )
        assert response.status_code == status.HTTP_201_CREATED
        assert response.json()["media_urls"] == [url]

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

    def test_create_post_with_quote_success(self, client):
        response = client.post(
            "/api/v1/posts",
            json={
                "subthread_id": "sub-1",
                "title": "nba > My take",
                "content": "Agree with this.",
                "quoted_post_id": STUB_POST_ID,
            },
        )

        assert response.status_code == status.HTTP_201_CREATED
        body = response.json()
        assert body["quoted_post_id"] == STUB_POST_ID
        assert body["content"] == "Agree with this."

    def test_create_post_quote_target_missing(self, client):
        response = client.post(
            "/api/v1/posts",
            json={
                "subthread_id": "sub-1",
                "title": "x > y",
                "content": "Quote",
                "quoted_post_id": STUB_POST_MISSING,
            },
        )

        assert response.status_code == status.HTTP_404_NOT_FOUND

    def test_create_post_duplicate_repost_target_ok(self, client):
        response = client.post(
            "/api/v1/posts",
            json={
                "subthread_id": "sub-1",
                "title": "dup title",
                "content": "dup body",
                "repost_of_post_id": STUB_POST_ID,
            },
        )

        assert response.status_code == status.HTTP_201_CREATED
        assert response.json()["repost_of_post_id"] == STUB_POST_ID

    def test_create_post_duplicate_repost_target_missing(self, client):
        response = client.post(
            "/api/v1/posts",
            json={
                "subthread_id": "sub-1",
                "title": "dup",
                "content": "dup",
                "repost_of_post_id": STUB_POST_MISSING,
            },
        )

        assert response.status_code == status.HTTP_404_NOT_FOUND

    def test_create_post_duplicate_repost_comment_ok(self, client):
        response = client.post(
            "/api/v1/posts",
            json={
                "subthread_id": "sub-1",
                "title": "Comment repost",
                "content": "Great conditions",
                "repost_of_comment_id": "comment-1",
            },
        )

        assert response.status_code == status.HTTP_201_CREATED
        assert response.json()["repost_of_comment_id"] == "comment-1"

    def test_create_post_quote_comment_success(self, client):
        response = client.post(
            "/api/v1/posts",
            json={
                "subthread_id": "sub-1",
                "title": "thread > My reply",
                "content": "Agree.",
                "quoted_comment_id": "comment-1",
            },
        )

        assert response.status_code == status.HTTP_201_CREATED
        body = response.json()
        assert body["quoted_comment_id"] == "comment-1"
        assert body["content"] == "Agree."

    def test_create_post_quote_both_targets_rejected(self, client):
        response = client.post(
            "/api/v1/posts",
            json={
                "subthread_id": "sub-1",
                "title": "x",
                "content": "y",
                "quoted_post_id": STUB_POST_ID,
                "quoted_comment_id": "comment-1",
            },
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
        """Only /api/v1/feed is canonical; old paths must not resolve."""
        r_v1 = client.get("/api/v1/posts/feed?limit=10")
        r_legacy = client.get("/api/posts/feed?limit=10")

        assert r_v1.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY
        assert r_legacy.status_code == status.HTTP_404_NOT_FOUND

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

    def test_repost_post_success(self, client):
        response = client.post(f"/api/v1/posts/{STUB_POST_ID}/repost")
        assert response.status_code == status.HTTP_200_OK
        body = response.json()
        assert body["post_id"] == STUB_POST_ID
        assert body["reposted"] is True
        assert body["repost_count"] == 1

    def test_undo_repost_post_success(self, client):
        response = client.delete(f"/api/v1/posts/{STUB_POST_ID}/repost")
        assert response.status_code == status.HTTP_200_OK
        body = response.json()
        assert body["post_id"] == STUB_POST_ID
        assert body["reposted"] is False


class TestCommentEndpoints:
    def test_create_comment_success(self, client):
        response = client.post(
            "/api/v1/comments",
            json={"post_id": STUB_POST_ID, "content": "Nice route"},
        )

        assert response.status_code == status.HTTP_201_CREATED
        assert response.json()["content"] == "Nice route"

    def test_create_comment_nested_parent_not_allowed(self, client):
        response = client.post(
            "/api/v1/comments",
            json={
                "post_id": STUB_POST_ID,
                "content": "Reply",
                "parent_id": "comment-missing",
            },
        )

        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY

    def test_get_comment_not_found(self, client):
        response = client.get("/api/v1/comments/comment-missing")

        assert response.status_code == status.HTTP_404_NOT_FOUND

    def test_delete_comment_not_found(self, client):
        response = client.delete("/api/v1/comments/comment-missing")

        assert response.status_code == status.HTTP_404_NOT_FOUND

    def test_update_comment_success(self, client, app):
        app.dependency_overrides[get_current_user] = lambda: "user-2"
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
