"""
Unit tests for JWT token utilities.
"""

from datetime import timedelta

import pytest
from jose import JWTError

from app.core.config import settings
from app.core.jwt import create_access_token, create_refresh_token, decode_token, verify_token_type


class TestJWTTokenCreation:
    """Test JWT token creation."""

    def test_create_access_token(self):
        """Test creating an access token."""
        data = {"sub": "user123", "email": "test@example.com"}
        token = create_access_token(data)

        assert token is not None
        assert isinstance(token, str)
        assert len(token) > 0

    def test_create_refresh_token(self):
        """Test creating a refresh token."""
        data = {"sub": "user123", "email": "test@example.com"}
        token = create_refresh_token(data)

        assert token is not None
        assert isinstance(token, str)
        assert len(token) > 0

    def test_access_token_has_correct_type(self):
        """Test that access token has type 'access'."""
        data = {"sub": "user123", "email": "test@example.com"}
        token = create_access_token(data)
        token_data = decode_token(token)

        assert token_data.token_type == "access"

    def test_refresh_token_has_correct_type(self):
        """Test that refresh token has type 'refresh'."""
        data = {"sub": "user123", "email": "test@example.com"}
        token = create_refresh_token(data)
        token_data = decode_token(token)

        assert token_data.token_type == "refresh"

    def test_create_access_token_with_custom_expiry(self):
        """Test creating access token with custom expiration."""
        data = {"sub": "user123", "email": "test@example.com"}
        custom_delta = timedelta(minutes=30)
        token = create_access_token(data, expires_delta=custom_delta)

        assert token is not None
        token_data = decode_token(token)
        assert token_data.user_id == "user123"


class TestJWTTokenDecoding:
    """Test JWT token decoding and validation."""

    def test_decode_valid_access_token(self):
        """Test decoding a valid access token."""
        data = {"sub": "user123", "email": "test@example.com"}
        token = create_access_token(data)
        token_data = decode_token(token)

        assert token_data.user_id == "user123"
        assert token_data.email == "test@example.com"
        assert token_data.token_type == "access"

    def test_decode_valid_refresh_token(self):
        """Test decoding a valid refresh token."""
        data = {"sub": "user123", "email": "test@example.com"}
        token = create_refresh_token(data)
        token_data = decode_token(token)

        assert token_data.user_id == "user123"
        assert token_data.email == "test@example.com"
        assert token_data.token_type == "refresh"

    def test_decode_invalid_token_raises_error(self):
        """Test that decoding an invalid token raises JWTError."""
        invalid_token = "invalid.token.here"

        with pytest.raises(JWTError):
            decode_token(invalid_token)

    def test_decode_token_missing_user_id(self):
        """Test that token without 'sub' field raises error."""
        # Create a token without 'sub' field
        from jose import jwt

        payload = {
            "email": "test@example.com",
            "type": "access",
            "exp": 9999999999,  # Far future
            "iat": 1000000000,
        }
        token = jwt.encode(payload, settings.secret_key, algorithm=settings.algorithm)

        with pytest.raises(JWTError):
            decode_token(token)


class TestTokenTypeVerification:
    """Test token type verification."""

    def test_verify_access_token_type(self):
        """Test verifying access token type."""
        data = {"sub": "user123", "email": "test@example.com"}
        token = create_access_token(data)
        token_data = decode_token(token)

        assert verify_token_type(token_data, "access") is True
        assert verify_token_type(token_data, "refresh") is False

    def test_verify_refresh_token_type(self):
        """Test verifying refresh token type."""
        data = {"sub": "user123", "email": "test@example.com"}
        token = create_refresh_token(data)
        token_data = decode_token(token)

        assert verify_token_type(token_data, "refresh") is True
        assert verify_token_type(token_data, "access") is False
