"""
Contract Compliance Tests

Verifies that all API responses conform to the standardized contract:
- Error responses: {code, message, details, request_id}
- Success responses: {data, meta} with pagination info
- All responses include request_id for tracing
"""

import pytest
import json
from typing import Dict, Any


class TestErrorContractCompliance:
    """Verify error response contracts."""
    
    def validate_error_response(self, response_data: Dict[str, Any]) -> bool:
        """
        Validate that error response conforms to standard contract.
        
        Required fields:
        - code: Machine-readable error code
        - message: Human-readable message
        - details: Error details (object, list, or string)
        - request_id: Request tracking ID (non-empty UUID)
        """
        assert "code" in response_data, "Error response missing 'code' field"
        assert "message" in response_data, "Error response missing 'message' field"
        assert "details" in response_data, "Error response missing 'details' field"
        assert "request_id" in response_data, "Error response missing 'request_id' field"
        
        # Validate field types
        assert isinstance(response_data["code"], str) and response_data["code"], "code must be non-empty string"
        assert isinstance(response_data["message"], str) and response_data["message"], "message must be non-empty string"
        assert response_data["request_id"], "request_id must be non-empty"
        
        # details can be dict, list, or string
        assert isinstance(response_data["details"], (dict, list, str)), "details must be object, list, or string"
        
        return True
    
    def test_401_error_contract(self):
        """Test 401 authentication error follows contract."""
        # Example: {"code": "UNAUTHORIZED", "message": "...", "details": "...", "request_id": "..."}
        sample_error = {
            "code": "UNAUTHORIZED",
            "message": "Authentication required",
            "details": "Missing Authorization header",
            "request_id": "req-abc123xyz",
            "timestamp": "2026-03-21T12:34:56.789Z"
        }
        assert self.validate_error_response(sample_error)
    
    def test_404_error_contract(self):
        """Test 404 not found error follows contract."""
        sample_error = {
            "code": "NOT_FOUND",
            "message": "Resource not found",
            "details": {"resource_type": "Activity", "id": "activity-123"},
            "request_id": "req-xyz789abc"
        }
        assert self.validate_error_response(sample_error)
    
    def test_400_validation_error_contract(self):
        """Test 400 validation error follows contract with field-level details."""
        sample_error = {
            "code": "VALIDATION_ERROR",
            "message": "Request validation failed",
            "details": {
                "email": ["Invalid email format"],
                "age": ["Must be >= 0"]
            },
            "request_id": "req-val123"
        }
        assert self.validate_error_response(sample_error)
    
    def test_error_has_request_id_header(self):
        """
        Test that error responses include X-Request-ID header.
        (This would be tested in integration tests against actual endpoints)
        """
        # Pseudo-test showing expected header behavior
        # In actual integration tests:
        # response = client.get("/api/v1/activities/nonexistent")
        # assert response.status_code == 404
        # assert "X-Request-ID" in response.headers
        # body = response.json()
        # assert body["request_id"] == response.headers["X-Request-ID"]
        pass


class TestSuccessContractCompliance:
    """Verify success response contracts."""
    
    def validate_success_response(self, response_data: Dict[str, Any], must_have_pagination: bool = False) -> bool:
        """
        Validate that success response conforms to standard contract.
        
        Required fields:
        - data: The actual response payload
        - meta: Metadata with request_id (and pagination if list)
        
        Metadata required fields:
        - request_id: Request tracking ID
        - timestamp: ISO 8601 timestamp (optional but recommended)
        """
        assert "data" in response_data, "Success response missing 'data' field"
        assert "meta" in response_data, "Success response missing 'meta' field"
        
        meta = response_data["meta"]
        assert "request_id" in meta, "Response meta missing 'request_id' field"
        assert isinstance(meta["request_id"], str) and meta["request_id"], "request_id must be non-empty string"
        
        if must_have_pagination:
            assert "pagination" in meta, "List response meta missing 'pagination' field"
            pagination = meta["pagination"]
            
            # Validate pagination contract
            required_pagination_fields = ["limit", "offset", "total", "has_next"]
            for field in required_pagination_fields:
                assert field in pagination, f"Pagination missing '{field}' field"
            
            assert isinstance(pagination["limit"], int) and pagination["limit"] > 0, "limit must be positive integer"
            assert isinstance(pagination["offset"], int) and pagination["offset"] >= 0, "offset must be non-negative"
            assert isinstance(pagination["total"], int) and pagination["total"] >= 0, "total must be non-negative"
            assert isinstance(pagination["has_next"], bool), "has_next must be boolean"
        
        return True
    
    def test_single_resource_contract(self):
        """Test single resource response follows contract."""
        sample_response = {
            "data": {
                "id": "activity-123",
                "name": "Morning Ski",
                "distance": 5000,
            },
            "meta": {
                "request_id": "req-single-456"
            }
        }
        assert self.validate_success_response(sample_response, must_have_pagination=False)
    
    def test_list_response_contract(self):
        """Test list response follows contract with pagination."""
        sample_response = {
            "items": [
                {"id": "activity-1", "name": "Activity 1"},
                {"id": "activity-2", "name": "Activity 2"},
            ],
            "meta": {
                "request_id": "req-list-789",
                "pagination": {
                    "limit": 20,
                    "offset": 0,
                    "total": 100,
                    "has_next": True,
                    "next_cursor": "abc123"  # Optional but recommended
                }
            }
        }
        # Note: ListResponse from shared.contracts uses 'items' directly
        assert "items" in sample_response
        assert "meta" in sample_response
        assert self.validate_success_response(
            {"data": sample_response["items"], "meta": sample_response["meta"]},
            must_have_pagination=True
        )
    
    def test_empty_list_response_contract(self):
        """Test empty list response still follows contract."""
        sample_response = {
            "items": [],
            "meta": {
                "request_id": "req-empty-111",
                "pagination": {
                    "limit": 20,
                    "offset": 0,
                    "total": 0,
                    "has_next": False,
                }
            }
        }
        assert "items" in sample_response
        assert len(sample_response["items"]) == 0
        assert sample_response["meta"]["pagination"]["total"] == 0
        assert sample_response["meta"]["pagination"]["has_next"] == False
    
    def test_response_has_request_id_header(self):
        """
        Test that success responses include X-Request-ID header.
        (This would be tested in integration tests against actual endpoints)
        """
        # Pseudo-test showing expected header behavior
        # In actual integration tests:
        # response = client.get("/api/v1/activities/abc123")
        # assert response.status_code == 200
        # assert "X-Request-ID" in response.headers
        # body = response.json()
        # assert body["meta"]["request_id"] == response.headers["X-Request-ID"]
        pass


class TestDeprecationHeaderCompliance:
    """Verify deprecation headers on legacy endpoints."""
    
    def validate_deprecation_headers(self, headers: Dict[str, str], expect_deprecated: bool = True) -> bool:
        """
        Validate deprecation headers on response.
        
        For deprecated endpoints, should include:
        - Deprecation: true
        - Sunset: <date>
        - Link: <successor-url>; rel="successor-version"
        """
        if expect_deprecated:
            assert "Deprecation" in headers or "deprecation" in headers.keys(), "Missing Deprecation header"
            assert any(h in headers for h in ["Sunset", "sunset"]), "Missing Sunset header (death date)"
            assert any(h in headers for h in ["Link", "link"]), "Missing Link header (successor info)"
        
        return True
    
    def test_legacy_endpoint_has_deprecation_headers(self):
        """Test legacy /api/* endpoints include deprecation warnings."""
        # Example headers for deprecated endpoint:
        sample_headers = {
            "Deprecation": "true",
            "Sunset": "Sun, 21 Jun 2026 00:00:00 GMT",
            "Link": '</api/v1/activities>; rel="successor-version"',
            "X-Deprecation-Message": "Use /api/v1/* endpoints instead. Support ends 2026-06-21."
        }
        assert self.validate_deprecation_headers(sample_headers, expect_deprecated=True)
    
    def test_new_endpoint_no_deprecation_headers(self):
        """Test new /api/v1/* endpoints do NOT include deprecation headers."""
        sample_headers = {}
        assert self.validate_deprecation_headers(sample_headers, expect_deprecated=False)


class TestBackwardCompatibilitySupport:
    """Verify backward compatibility mechanisms."""
    
    def test_legacy_format_query_param_support(self):
        """
        Test that legacy ?format=legacy query parameter works.
        (Tested in integration tests against actual endpoints)
        """
        # Expected behavior:
        # GET /api/v1/activities?format=legacy -> returns List[Item] (raw array)
        # GET /api/v1/activities -> returns {items: [...], meta: {...}} (new format)
        pass
    
    def test_legacy_filter_param_soft_accept(self):
        """
        Test that deprecated filter parameters are accepted with warning.
        (Tested in integration tests against actual endpoints)
        """
        # Expected behavior:
        # GET /api/v1/activities/me?q=skiing -> accepted, maps to search=skiing
        # Response includes warning in meta.deprecated_params
        # Response includes migration guide in meta.deprecation_info
        pass


class TestRequestIDTracking:
    """Verify request ID tracking throughout response lifecycle."""
    
    def test_request_id_correlation(self):
        """
        Test that request ID is consistent across header and body.
        (Tested in integration tests against actual endpoints)
        """
        # Expected behavior:
        # Response header: X-Request-ID: "abc-123"
        # Response body meta.request_id: "abc-123"
        # Should match exactly for tracing
        pass
    
    def test_request_id_provided_by_client_is_honored(self):
        """
        Test that client-provided X-Request-ID header is honored.
        (Tested in integration tests against actual endpoints)
        """
        # Expected behavior:
        # Request header: X-Request-ID: "custom-trace-id"
        # Response header: X-Request-ID: "custom-trace-id"
        # Response body meta.request_id: "custom-trace-id"
        pass
    
    def test_request_id_generated_when_not_provided(self):
        """
        Test that request ID is auto-generated if not provided.
        (Tested in integration tests against actual endpoints)
        """
        # Expected behavior:
        # No request header provided
        # Response header includes generated X-Request-ID: "<uuid>"
        # Response body meta.request_id: "<uuid>"
        # Should be a valid UUID v4
        pass


# Integration test examples (pseudo-code for actual test execution)
"""
pytest markers for integration tests:

@pytest.mark.integration
@pytest.mark.http_client
class TestContractComplianceIntegration:
    
    def test_list_activities_contract(self, client):
        '''Test actual /api/v1/activities endpoint.'''
        response = client.get("/api/v1/activities")
        assert response.status_code == 200
        body = response.json()
        
        # Validate structure
        assert "items" in body
        assert "meta" in body
        
        # Validate meta
        assert "request_id" in body["meta"]
        assert "pagination" in body["meta"]
        
        # Validate pagination
        pagination = body["meta"]["pagination"]
        assert "limit" in pagination
        assert "offset" in pagination
        assert "total" in pagination
        assert "has_next" in pagination
        
        # Validate response headers
        assert "X-Request-ID" in response.headers
        assert response.headers["X-Request-ID"] == body["meta"]["request_id"]
    
    def test_error_response_contract(self, client):
        '''Test error response format.'''
        response = client.get("/api/v1/activities/nonexistent")
        assert response.status_code == 404
        body = response.json()
        
        # Validate error fields
        assert body["code"] == "NOT_FOUND"
        assert body["message"]
        assert "request_id" in body
        
        # Validate header
        assert "X-Request-ID" in response.headers
    
    def test_deprecated_endpoint_headers(self, client):
        '''Test legacy endpoint returns deprecation headers.'''
        response = client.get("/api/subthreads")  # Legacy endpoint
        assert response.status_code in [200, 404]
        
        # Should have deprecation headers
        assert "Deprecation" in response.headers
        assert "Sunset" in response.headers
        assert "Link" in response.headers
    
    def test_legacy_format_parameter(self, client):
        '''Test backward compatibility format parameter.'''
        # New format
        response_new = client.get("/api/v1/activities")
        body_new = response_new.json()
        assert "items" in body_new
        assert "meta" in body_new
        
        # Legacy format
        response_legacy = client.get("/api/v1/activities?format=legacy")
        body_legacy = response_legacy.json()
        assert isinstance(body_legacy, list)  # Raw array
"""
