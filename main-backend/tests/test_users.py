"""
Integration tests for user endpoints.
"""
import pytest
from fastapi import status


class TestGetCurrentUser:
    """Test GET /api/v1/users/me endpoint."""
    
    def test_get_current_user_success(self, client, clean_storage, test_user):
        """Test getting current user with valid token."""
        # Login first
        login_response = client.post(
            "/api/v1/auth/login",
            json={"email": test_user.email, "password": "testpassword123"}
        )
        token = login_response.json()["access_token"]
        
        # Get current user
        response = client.get(
            "/api/v1/users/me",
            headers={"Authorization": f"Bearer {token}"}
        )
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["id"] == test_user.id
        assert data["email"] == test_user.email
        assert data["first_name"] == test_user.first_name
        assert data["last_name"] == test_user.last_name
    
    def test_get_current_user_no_token(self, client, clean_storage):
        """Test getting current user without token."""
        response = client.get("/api/v1/users/me")
        
        assert response.status_code == status.HTTP_401_UNAUTHORIZED
    
    def test_get_current_user_invalid_token(self, client, clean_storage):
        """Test getting current user with invalid token."""
        response = client.get(
            "/api/v1/users/me",
            headers={"Authorization": "Bearer invalid.token.here"}
        )
        
        assert response.status_code == status.HTTP_401_UNAUTHORIZED


class TestUpdateCurrentUser:
    """Test PUT /api/v1/users/me endpoint."""
    
    def test_update_user_success(self, client, clean_storage, test_user):
        """Test updating user profile."""
        # Login first
        login_response = client.post(
            "/api/v1/auth/login",
            json={"email": test_user.email, "password": "testpassword123"}
        )
        token = login_response.json()["access_token"]
        
        # Update user
        update_data = {
            "first_name": "Updated",
            "last_name": "Name"
        }
        response = client.put(
            "/api/v1/users/me",
            headers={"Authorization": f"Bearer {token}"},
            json=update_data
        )
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["first_name"] == "Updated"
        assert data["last_name"] == "Name"
        assert data["email"] == test_user.email  # Email shouldn't change
    
    def test_update_user_partial(self, client, clean_storage, test_user):
        """Test updating only first name."""
        # Login first
        login_response = client.post(
            "/api/v1/auth/login",
            json={"email": test_user.email, "password": "testpassword123"}
        )
        token = login_response.json()["access_token"]
        
        # Update only first name
        update_data = {"first_name": "OnlyFirst"}
        response = client.put(
            "/api/v1/users/me",
            headers={"Authorization": f"Bearer {token}"},
            json=update_data
        )
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["first_name"] == "OnlyFirst"
        assert data["last_name"] == test_user.last_name  # Should remain unchanged
    
    def test_update_user_no_token(self, client, clean_storage):
        """Test updating user without token."""
        response = client.put(
            "/api/v1/users/me",
            json={"first_name": "Test"}
        )
        
        assert response.status_code == status.HTTP_401_UNAUTHORIZED


