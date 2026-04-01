import pytest
from fastapi.testclient import TestClient

import main as community_main
from middleware.auth import get_current_user, get_optional_user
from routes import subthreads as subthreads_routes
from routes import comments as comments_routes
from routes import media_routes, posts_read_routes, posts_write_routes
from services.community_media_operations import (
    CommunityMediaUploadResult,
    normalize_upload_mime_and_extension,
)

_MEDIA_MAX = 50 * 1024 * 1024


# Matches test_community_api STUB_POST_ID (UUID path params avoid /posts/feed collision).
STUB_POST_ID = "11111111-1111-1111-1111-111111111111"
STUB_MEDIA_URL = (
    "https://stub.supabase.co/storage/v1/object/public/community-media/user-1/x.png"
)


class StubCommunityClient:
    def __init__(self):
        self.subthread = {
            "id": "sub-1",
            "name": "Powder Chasers",
            "description": "Powder reports and planning",
            "created_at": "2026-01-01T00:00:00Z",
        }
        self.post = {
            "post_id": STUB_POST_ID,
            "user_id": "user-1",
            "subthread_id": "sub-1",
            "title": "Bluebird day",
            "content": "Perfect visibility all day",
            "created_at": "2026-01-01T01:00:00Z",
            "author_email": "user@example.com",
            "author_first_name": "Ski",
            "author_last_name": "Rider",
            "like_count": 1,
            "liked_by_current_user": True,
            "repost_count": 0,
            "reposted_by_current_user": False,
            "share_count": 0,
            "quoted_post_id": None,
            "quoted_post": None,
            "repost_of_post_id": None,
            "quoted_comment_id": None,
            "quoted_comment": None,
            "repost_of_comment_id": None,
            "media_urls": [],
        }
        self.comment = {
            "id": "comment-1",
            "user_id": "user-2",
            "post_id": STUB_POST_ID,
            "parent_id": None,
            "content": "Great conditions",
            "has_parent": False,
            "created_at": "2026-01-01T01:10:00Z",
            "author_email": "friend@example.com",
            "author_first_name": "Pow",
            "author_last_name": "Fan",
            "repost_count": 0,
            "reposted_by_current_user": False,
            "media_urls": [],
        }

    def upload_community_media(self, user_id, file_bytes, content_type, extension):
        if len(file_bytes) > _MEDIA_MAX:
            return CommunityMediaUploadResult(error="too_large")
        if not normalize_upload_mime_and_extension(content_type, extension):
            return CommunityMediaUploadResult(error="unsupported_type")
        return CommunityMediaUploadResult(url=STUB_MEDIA_URL)

    def list_subthreads(self, limit=50):
        return [self.subthread]

    def create_subthread(self, name, description=None):
        created = dict(self.subthread)
        created["name"] = name
        created["description"] = description
        return created

    def get_subthread_by_id(self, subthread_id):
        if subthread_id == "sub-1":
            return self.subthread
        return None

    def list_posts_by_subthread(self, subthread_id, limit=20, offset=0):
        if subthread_id != "sub-1":
            return []
        return [self.post]

    def list_recent_posts(self, limit=20, offset=0, current_user_id=None):
        return [self.post]

    def count_all_posts(self):
        return 1

    def count_posts_by_subthread(self, subthread_id):
        return 1 if subthread_id == "sub-1" else 0

    def delete_subthread(self, subthread_id):
        return subthread_id == "sub-1"

    def create_post(
        self,
        user_id,
        subthread_id,
        title,
        content,
        quoted_post_id=None,
        repost_of_post_id=None,
        quoted_comment_id=None,
        repost_of_comment_id=None,
        media_urls=None,
    ):
        if subthread_id != "sub-1":
            return None
        created = dict(self.post)
        created["title"] = title
        created["content"] = content
        created["user_id"] = user_id
        if quoted_post_id:
            created["quoted_post_id"] = quoted_post_id
        else:
            created["quoted_post_id"] = None
        if repost_of_post_id:
            created["repost_of_post_id"] = repost_of_post_id
        else:
            created["repost_of_post_id"] = None
        if quoted_comment_id:
            created["quoted_comment_id"] = quoted_comment_id
        else:
            created["quoted_comment_id"] = None
        if repost_of_comment_id:
            created["repost_of_comment_id"] = repost_of_comment_id
        else:
            created["repost_of_comment_id"] = None
        created["quoted_post"] = None
        created["quoted_comment"] = None
        created["media_urls"] = list(media_urls or [])
        return created

    def get_post_by_id(self, post_id):
        if post_id == STUB_POST_ID:
            return self.post
        return None

    def list_posts_by_user_id(self, user_id, limit=20, offset=0, current_user_id=None):
        if user_id != "user-1":
            return []
        return [self.post]

    def list_comments_by_post(self, post_id, current_user_id=None):
        if post_id != STUB_POST_ID:
            return []
        return [dict(self.comment)]

    def list_comments_by_post_ids(self, post_ids, current_user_id=None):
        return {pid: self.list_comments_by_post(pid, current_user_id=current_user_id) for pid in post_ids}

    def count_comments_by_post(self, post_id):
        return 1 if post_id == STUB_POST_ID else 0

    def delete_post(self, post_id, user_id):
        return post_id == STUB_POST_ID and user_id == "user-1"

    def update_post(self, post_id, user_id, title=None, content=None):
        if post_id != STUB_POST_ID or user_id != "user-1":
            return None
        updated = dict(self.post)
        if title is not None:
            updated["title"] = title
        if content is not None:
            updated["content"] = content
        self.post = updated
        return updated

    def set_post_vote(self, post_id, user_id, vote_type):
        if post_id != STUB_POST_ID:
            return None
        if vote_type not in (-1, 0, 1):
            return None
        return {
            "post_id": post_id,
            "user_id": user_id,
            "vote_value": vote_type,
            "score": vote_type,
        }

    def set_post_repost(self, post_id, user_id, reposted):
        if post_id != STUB_POST_ID:
            return None
        self.post["reposted_by_current_user"] = bool(reposted)
        self.post["repost_count"] = 1 if reposted else 0
        return {
            "post_id": post_id,
            "user_id": user_id,
            "reposted": bool(reposted),
            "repost_count": self.post["repost_count"],
        }

    def create_comment(self, user_id, post_id, content, parent_id=None, media_urls=None):
        if post_id != STUB_POST_ID:
            return None
        created = dict(self.comment)
        created["id"] = "comment-2"
        created["user_id"] = user_id
        created["post_id"] = post_id
        created["content"] = content
        created["parent_id"] = parent_id
        created["has_parent"] = parent_id is not None
        created["media_urls"] = list(media_urls or [])
        return created

    def get_comment_by_id(self, comment_id):
        if comment_id == "comment-1":
            return self.comment
        return None

    def delete_comment(self, comment_id, user_id):
        return comment_id == "comment-1" and user_id == "user-2"

    def update_comment(self, comment_id, user_id, content):
        if comment_id != "comment-1" or user_id != "user-2":
            return None
        updated = dict(self.comment)
        updated["content"] = content
        self.comment = updated
        return updated

    def set_comment_vote(self, comment_id, user_id, vote_type):
        if comment_id != "comment-1":
            return None
        if vote_type not in (-1, 0, 1):
            return None
        return {
            "comment_id": comment_id,
            "user_id": user_id,
            "vote_value": vote_type,
            "score": vote_type,
        }


@pytest.fixture
def stub_client():
    return StubCommunityClient()


@pytest.fixture
def app(monkeypatch, stub_client):
    monkeypatch.setattr(community_main, "initialize_community_client", lambda: stub_client)
    monkeypatch.setattr(subthreads_routes, "get_community_client", lambda: stub_client)
    monkeypatch.setattr(posts_read_routes, "get_community_client", lambda: stub_client)
    monkeypatch.setattr(posts_write_routes, "get_community_client", lambda: stub_client)
    monkeypatch.setattr(comments_routes, "get_community_client", lambda: stub_client)
    monkeypatch.setattr(media_routes, "get_community_client", lambda: stub_client)

    community_main.app.dependency_overrides[get_current_user] = lambda: "user-1"
    community_main.app.dependency_overrides[get_optional_user] = lambda: "user-1"

    yield community_main.app

    community_main.app.dependency_overrides.clear()


@pytest.fixture
def client(app):
    with TestClient(app) as test_client:
        yield test_client
