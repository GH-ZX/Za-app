"""
Tests for authentication endpoints.
"""

import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.models.user import User


class TestAuthLogin:
    """Tests for POST /api/v1/auth/login endpoint."""
    
    def test_login_success(self, client: TestClient, regular_user: User):
        """Test successful login with correct credentials."""
        response = client.post(
            "/api/v1/auth/login",
            data={"username": "testuser", "password": "testuser123456"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data
        assert data["token_type"] == "bearer"
    
    def test_login_invalid_username(self, client: TestClient):
        """Test login with non-existent username."""
        response = client.post(
            "/api/v1/auth/login",
            data={"username": "nonexistent", "password": "password123"}
        )
        
        assert response.status_code == 400
        assert "Incorrect username or password" in response.json()["detail"]
    
    def test_login_invalid_password(self, client: TestClient, regular_user: User):
        """Test login with incorrect password."""
        response = client.post(
            "/api/v1/auth/login",
            data={"username": "testuser", "password": "wrongpassword"}
        )
        
        assert response.status_code == 400
        assert "Incorrect username or password" in response.json()["detail"]
    
    def test_login_inactive_user(self, client: TestClient, inactive_user: User):
        """Test login with inactive user account."""
        response = client.post(
            "/api/v1/auth/login",
            data={"username": "inactiveuser", "password": "inactive123456"}
        )
        
        assert response.status_code == 400
        assert "Inactive user" in response.json()["detail"]
    
    def test_login_returns_valid_token(self, client: TestClient, regular_user: User):
        """Test that login returns a valid JWT token."""
        response = client.post(
            "/api/v1/auth/login",
            data={"username": "testuser", "password": "testuser123456"}
        )
        
        assert response.status_code == 200
        token = response.json()["access_token"]
        
        # Use token to access protected endpoint
        headers = {"Authorization": f"Bearer {token}"}
        me_response = client.get("/api/v1/auth/me", headers=headers)
        
        assert me_response.status_code == 200
        assert me_response.json()["username"] == "testuser"


class TestAuthMe:
    """Tests for GET /api/v1/auth/me endpoint."""
    
    def test_get_current_user_success(self, client: TestClient, user_token: str):
        """Test getting current user info with valid token."""
        headers = {"Authorization": f"Bearer {user_token}"}
        response = client.get("/api/v1/auth/me", headers=headers)
        
        assert response.status_code == 200
        data = response.json()
        assert data["username"] == "testuser"
        assert data["email"] == "testuser@example.com"
        assert data["full_name"] == "Test User"
        assert data["is_active"] is True
        assert data["is_superuser"] is False
    
    def test_get_current_user_no_token(self, client: TestClient):
        """Test getting current user without token."""
        response = client.get("/api/v1/auth/me")
        
        assert response.status_code == 403
    
    def test_get_current_user_invalid_token(self, client: TestClient):
        """Test getting current user with invalid token."""
        headers = {"Authorization": "Bearer invalid_token"}
        response = client.get("/api/v1/auth/me", headers=headers)
        
        assert response.status_code == 401
    
    def test_get_current_user_inactive(self, client: TestClient, db: Session, inactive_user: User):
        """Test getting current user when user is inactive."""
        # Login should fail for inactive user
        response = client.post(
            "/api/v1/auth/login",
            data={"username": "inactiveuser", "password": "inactive123456"}
        )
        
        assert response.status_code == 400
        assert "Inactive user" in response.json()["detail"]


class TestAuthRegisterRemoved:
    """Tests to verify registration endpoint has been removed."""
    
    def test_register_endpoint_not_found(self, client: TestClient):
        """Test that POST /api/v1/auth/register returns 404."""
        response = client.post(
            "/api/v1/auth/register",
            json={
                "username": "newuser",
                "email": "newuser@example.com",
                "full_name": "New User",
                "password": "password123"
            }
        )
        
        assert response.status_code == 404
    
    def test_register_endpoint_method_not_allowed(self, client: TestClient):
        """Test that registration endpoint is not available."""
        # Try different HTTP methods
        response = client.post("/api/v1/auth/register")
        assert response.status_code == 404
