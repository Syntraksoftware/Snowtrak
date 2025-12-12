"""
Unit tests for security utilities (password hashing).
"""
import pytest
from app.core.security import hash_password, verify_password


class TestPasswordHashing:
    """Test password hashing and verification."""
    
    def test_hash_password_creates_different_hashes(self):
        """Test that hashing the same password produces different hashes (due to salt)."""
        password = "testpassword123"
        hash1 = hash_password(password)
        hash2 = hash_password(password)
        
        assert hash1 != hash2  # Different salts should produce different hashes
        assert len(hash1) > 0
        assert len(hash2) > 0
    
    def test_verify_password_correct(self):
        """Test password verification with correct password."""
        password = "testpassword123"
        hashed = hash_password(password)
        
        assert verify_password(password, hashed) is True
    
    def test_verify_password_incorrect(self):
        """Test password verification with incorrect password."""
        password = "testpassword123"
        wrong_password = "wrongpassword"
        hashed = hash_password(password)
        
        assert verify_password(wrong_password, hashed) is False
    
    def test_hash_password_empty_string(self):
        """Test hashing empty password."""
        hashed = hash_password("")
        assert len(hashed) > 0
        assert verify_password("", hashed) is True
    
    def test_hash_password_special_characters(self):
        """Test hashing password with special characters."""
        password = "p@ssw0rd!#$%^&*()"
        hashed = hash_password(password)
        assert verify_password(password, hashed) is True
    
    def test_hash_password_unicode(self):
        """Test hashing password with unicode characters."""
        password = "密码123🔒"
        hashed = hash_password(password)
        assert verify_password(password, hashed) is True


