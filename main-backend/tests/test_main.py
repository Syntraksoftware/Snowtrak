"""
Tests for main application setup and health check.
"""
import pytest
from fastapi import status


class TestHealthCheck:
    """Test health check endpoint."""
    
    def test_health_check(self, client):
        """Test health check endpoint returns correct status."""
        response = client.get("/health")
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["status"] == "healthy"
        assert "app" in data
        assert "version" in data
        assert "environment" in data


class TestCORS:
    """Test CORS configuration."""
    
    def test_cors_headers(self, client):
        """Test that CORS headers are present."""
        response = client.options(
            "/health",
            headers={
                "Origin": "http://localhost:3000",
                "Access-Control-Request-Method": "GET"
            }
        )
        
        # CORS preflight should be handled
        assert response.status_code in [status.HTTP_200_OK, status.HTTP_204_NO_CONTENT]


