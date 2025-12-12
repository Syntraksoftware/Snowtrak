"""
Integration tests for authentication endpoints.
"""
import pytest
from fastapi import status


class TestRegisterEndpoint:
    """Test user registration endpoint."""
    
    def test_register_success(self, client, clean_storage, test_user_data):
        """Test successful user registration."""
        response = client.post("/api/v1/auth/register", json=test_user_data)
        
        assert response.status_code == status.HTTP_201_CREATED
        data = response.json()
        assert "access_token" in data
        assert "refresh_token" in data
        assert "user" in data
        assert data["user"]["email"] == test_user_data["email"]
        assert data["user"]["first_name"] == test_user_data["first_name"]
        assert data["user"]["last_name"] == test_user_data["last_name"]
    
    def test_register_duplicate_email(self, client, clean_storage, test_user):
        """Test registration with duplicate email fails."""
        response = client.post(
            "/api/v1/auth/register",
            json={
                "email": test_user.email,
                "password": "password123",
                "first_name": "Test",
                "last_name": "User"
            }
        )
        
        assert response.status_code == status.HTTP_409_CONFLICT
        assert "already exists" in response.json()["detail"].lower()
    
    def test_register_missing_fields(self, client, clean_storage):
        """Test registration with missing required fields."""
        response = client.post(
            "/api/v1/auth/register",
            json={"email": "test@example.com"}
        )
        
        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY
    
    def test_register_invalid_email(self, client, clean_storage):
        """Test registration with invalid email format."""
        response = client.post(
            "/api/v1/auth/register",
            json={
                "email": "not-an-email",
                "password": "password123"
            }
        )
        
        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


class TestLoginEndpoint:
    """Test user login endpoint."""
    
    def test_login_success(self, client, clean_storage, test_user, login_credentials):
        """Test successful login."""
        response = client.post("/api/v1/auth/login", json=login_credentials)
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert "access_token" in data
        assert "refresh_token" in data
        assert "user" in data
        assert data["user"]["email"] == login_credentials["email"]
    
    def test_login_invalid_email(self, client, clean_storage):
        """Test login with non-existent email."""
        response = client.post(
            "/api/v1/auth/login",
            json={"email": "nonexistent@example.com", "password": "password123"}
        )
        
        assert response.status_code == status.HTTP_401_UNAUTHORIZED
        assert "invalid" in response.json()["detail"].lower()
    
    def test_login_invalid_password(self, client, clean_storage, test_user):
        """Test login with incorrect password."""
        response = client.post(
            "/api/v1/auth/login",
            json={"email": test_user.email, "password": "wrongpassword"}
        )
        
        assert response.status_code == status.HTTP_401_UNAUTHORIZED
        assert "invalid" in response.json()["detail"].lower()
    
    def test_login_missing_fields(self, client, clean_storage):
        """Test login with missing fields."""
        response = client.post("/api/v1/auth/login", json={"email": "test@example.com"})
        
        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


class TestRefreshTokenEndpoint:
    """Test token refresh endpoint."""
    
    def test_refresh_token_success(self, client, clean_storage, test_user):
        """Test successful token refresh."""
        # First login to get tokens
        login_response = client.post(
            "/api/v1/auth/login",
            json={"email": test_user.email, "password": "testpassword123"}
        )
        refresh_token = login_response.json()["refresh_token"]
        
        # Refresh the token
        response = client.post(
            "/api/v1/auth/refresh",
            json={"refresh_token": refresh_token}
        )
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert "access_token" in data
        assert "refresh_token" in data
        # New tokens should be different
        assert data["refresh_token"] != refresh_token
    
    def test_refresh_token_invalid(self, client, clean_storage):
        """Test refresh with invalid token."""
        response = client.post(
            "/api/v1/auth/refresh",
            json={"refresh_token": "invalid.token.here"}
        )
        
        assert response.status_code == status.HTTP_401_UNAUTHORIZED
    
    def test_refresh_token_with_access_token(self, client, clean_storage, test_user):
        """Test refresh endpoint rejects access token."""
        # Get access token
        login_response = client.post(
            "/api/v1/auth/login",
            json={"email": test_user.email, "password": "testpassword123"}
        )
        access_token = login_response.json()["access_token"]
        
        # Try to use access token as refresh token
        response = client.post(
            "/api/v1/auth/refresh",
            json={"refresh_token": access_token}
        )
        
        assert response.status_code == status.HTTP_401_UNAUTHORIZED
    
    def test_refresh_token_missing(self, client, clean_storage):
        """Test refresh without token."""
        response = client.post("/api/v1/auth/refresh", json={})
        
        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


