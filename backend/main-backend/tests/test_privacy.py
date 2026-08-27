"""Integration tests for PUT /api/v1/users/me/privacy."""


def test_setting_privacy_persists_and_echoes(client, stub_supabase):
    response = client.put("/api/v1/users/me/privacy", json={"is_private": True})
    assert response.status_code == 200
    assert response.json() == {"is_private": True}
    assert stub_supabase.user_info["user-1"]["is_private"] is True


def test_clearing_privacy_persists(client, stub_supabase):
    client.put("/api/v1/users/me/privacy", json={"is_private": True})
    response = client.put("/api/v1/users/me/privacy", json={"is_private": False})
    assert response.json() == {"is_private": False}
    assert stub_supabase.user_info["user-1"]["is_private"] is False
