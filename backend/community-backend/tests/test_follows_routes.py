"""Tests for /api/v1/follows -- following, and following a private account.

A private account turns a follow into a request instead. The client cannot
tell the two apart from a 204, which is why the route now answers with a
body describing which one happened.

`{user_id}` in this router is typed `UUID` (routes/follows_routes.py, unchanged
by this task), so path segments must be real UUID text -- the "user-2" style
id the task brief's sketch used only works for values that never go through
FastAPI's path converter (current_user, and the requester ids embedded in a
response body).
"""

from middleware.auth import get_current_user

STUB_USER_2 = "22222222-2222-2222-2222-222222222222"
STUB_USER_3 = "33333333-3333-3333-3333-333333333333"


def test_following_a_public_account_returns_following(client, stub_client):
    stub_client.private_accounts = set()
    response = client.post(f"/api/v1/follows/{STUB_USER_2}")
    assert response.status_code == 200
    assert response.json() == {"state": "following"}
    assert ("user-1", STUB_USER_2) in stub_client.follows


def test_following_a_private_account_returns_requested(client, stub_client):
    stub_client.private_accounts = {STUB_USER_2}
    response = client.post(f"/api/v1/follows/{STUB_USER_2}")
    assert response.status_code == 200
    assert response.json() == {"state": "requested"}
    assert ("user-1", STUB_USER_2) in stub_client.requests
    assert ("user-1", STUB_USER_2) not in stub_client.follows


def test_cannot_follow_yourself(client, app):
    # get_current_user is fixed to "user-1" for every other test in this
    # suite; the self-follow guard compares it against a real UUID path
    # segment, so this test needs a matching override just for itself.
    app.dependency_overrides[get_current_user] = lambda: STUB_USER_2
    response = client.post(f"/api/v1/follows/{STUB_USER_2}")
    assert response.status_code == 400


def test_list_my_requests_is_not_shadowed_by_user_id_route(client, stub_client):
    stub_client.requests = {(STUB_USER_2, "user-1"), (STUB_USER_3, "user-1")}
    response = client.get("/api/v1/follows/me/requests")
    assert response.status_code == 200
    body = response.json()
    requester_ids = {item["user_id"] for item in body["items"]}
    assert requester_ids == {STUB_USER_2, STUB_USER_3}


def test_approve_request_turns_it_into_a_follow(client, stub_client):
    stub_client.requests = {(STUB_USER_2, "user-1")}
    response = client.post(f"/api/v1/follows/me/requests/{STUB_USER_2}/approve")
    assert response.status_code == 204
    assert (STUB_USER_2, "user-1") not in stub_client.requests
    assert (STUB_USER_2, "user-1") in stub_client.follows


def test_approve_request_404s_when_there_was_none(client, stub_client):
    stub_client.requests = set()
    response = client.post(f"/api/v1/follows/me/requests/{STUB_USER_2}/approve")
    assert response.status_code == 404


def test_deny_request_drops_it_without_following(client, stub_client):
    stub_client.requests = {(STUB_USER_2, "user-1")}
    response = client.delete(f"/api/v1/follows/me/requests/{STUB_USER_2}")
    assert response.status_code == 204
    assert (STUB_USER_2, "user-1") not in stub_client.requests
    assert (STUB_USER_2, "user-1") not in stub_client.follows


def test_withdraw_request_is_not_shadowed_by_unfollow_route(client, stub_client):
    stub_client.requests = {("user-1", STUB_USER_2)}
    response = client.delete(f"/api/v1/follows/{STUB_USER_2}/request")
    assert response.status_code == 204
    assert ("user-1", STUB_USER_2) not in stub_client.requests
