"""
Tests for admin endpoints.
"""

import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.models.user import User
from app.crud.crud_user import user as crud_user


class TestAdminCreateUser:
    """Tests for POST /api/v1/admin/users/ endpoint."""
    
    def test_create_user_success_with_email(self, client: TestClient, admin_token: str, db: Session):
        """Test successful user creation with email by admin."""
        headers = {"Authorization": f"Bearer {admin_token}"}
        response = client.post(
            "/api/v1/admin/users/",
            headers=headers,
            json={
                "username": "newuser",
                "email": "newuser@example.com",
                "full_name": "New User",
                "password": "newpassword123"
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["username"] == "newuser"
        assert data["email"] == "newuser@example.com"
        assert data["full_name"] == "New User"
        assert data["is_active"] is True
        assert data["is_superuser"] is False
        assert "hashed_password" not in data
        
        # Verify user can login with new credentials
        login_response = client.post(
            "/api/v1/auth/login",
            data={"username": "newuser", "password": "newpassword123"}
        )
        assert login_response.status_code == 200
    
    def test_create_user_success_without_email(self, client: TestClient, admin_token: str, db: Session):
        """Test successful user creation without email by admin."""
        headers = {"Authorization": f"Bearer {admin_token}"}
        response = client.post(
            "/api/v1/admin/users/",
            headers=headers,
            json={
                "username": "noemailuser",
                "full_name": "No Email User",
                "password": "noemailpass123"
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["username"] == "noemailuser"
        assert data["email"] is None
        assert data["full_name"] == "No Email User"
        assert data["is_active"] is True
        
        # Verify user can login
        login_response = client.post(
            "/api/v1/auth/login",
            data={"username": "noemailuser", "password": "noemailpass123"}
        )
        assert login_response.status_code == 200
    
    def test_create_user_duplicate_username(self, client: TestClient, admin_token: str, regular_user: User):
        """Test user creation fails with duplicate username."""
        headers = {"Authorization": f"Bearer {admin_token}"}
        response = client.post(
            "/api/v1/admin/users/",
            headers=headers,
            json={
                "username": "testuser",  # Already exists
                "email": "different@example.com",
                "full_name": "Different User",
                "password": "password123"
            }
        )
        
        assert response.status_code == 400
        assert "username already exists" in response.json()["detail"].lower()
    
    def test_create_user_duplicate_email(self, client: TestClient, admin_token: str, regular_user: User):
        """Test user creation fails with duplicate email."""
        headers = {"Authorization": f"Bearer {admin_token}"}
        response = client.post(
            "/api/v1/admin/users/",
            headers=headers,
            json={
                "username": "differentuser",
                "email": "testuser@example.com",  # Already exists
                "full_name": "Different User",
                "password": "password123"
            }
        )
        
        assert response.status_code == 400
        assert "email already exists" in response.json()["detail"].lower()
    
    def test_create_user_multiple_same_email(self, client: TestClient, admin_token: str):
        """Test that multiple users can have no email."""
        headers = {"Authorization": f"Bearer {admin_token}"}
        
        # Create first user without email
        response1 = client.post(
            "/api/v1/admin/users/",
            headers=headers,
            json={
                "username": "user1",
                "full_name": "User One",
                "password": "password123"
            }
        )
        assert response1.status_code == 200
        
        # Create second user without email (should succeed)
        response2 = client.post(
            "/api/v1/admin/users/",
            headers=headers,
            json={
                "username": "user2",
                "full_name": "User Two",
                "password": "password123"
            }
        )
        assert response2.status_code == 200
    
    def test_create_user_non_admin_forbidden(self, client: TestClient, user_token: str):
        """Test that non-admin user cannot create users."""
        headers = {"Authorization": f"Bearer {user_token}"}
        response = client.post(
            "/api/v1/admin/users/",
            headers=headers,
            json={
                "username": "newuser",
                "email": "newuser@example.com",
                "full_name": "New User",
                "password": "password123"
            }
        )
        
        assert response.status_code == 403
        assert "Not enough permissions" in response.json()["detail"]
    
    def test_create_user_no_token_unauthorized(self, client: TestClient):
        """Test that unauthenticated user cannot create users."""
        response = client.post(
            "/api/v1/admin/users/",
            json={
                "username": "newuser",
                "email": "newuser@example.com",
                "full_name": "New User",
                "password": "password123"
            }
        )
        
        assert response.status_code == 403
    
    def test_create_user_invalid_token(self, client: TestClient):
        """Test that invalid token is rejected."""
        headers = {"Authorization": "Bearer invalid_token"}
        response = client.post(
            "/api/v1/admin/users/",
            headers=headers,
            json={
                "username": "newuser",
                "email": "newuser@example.com",
                "full_name": "New User",
                "password": "password123"
            }
        )
        
        assert response.status_code == 401
    
    def test_create_user_missing_required_field(self, client: TestClient, admin_token: str):
        """Test user creation fails with missing required fields."""
        headers = {"Authorization": f"Bearer {admin_token}"}
        
        # Missing username
        response = client.post(
            "/api/v1/admin/users/",
            headers=headers,
            json={
                "email": "test@example.com",
                "full_name": "Test User",
                "password": "password123"
            }
        )
        assert response.status_code == 422
        
        # Missing full_name
        response = client.post(
            "/api/v1/admin/users/",
            headers=headers,
            json={
                "username": "testuser",
                "email": "test@example.com",
                "password": "password123"
            }
        )
        assert response.status_code == 422
        
        # Missing password
        response = client.post(
            "/api/v1/admin/users/",
            headers=headers,
            json={
                "username": "testuser",
                "email": "test@example.com",
                "full_name": "Test User"
            }
        )
        assert response.status_code == 422
    
    def test_create_user_password_hashed(self, client: TestClient, admin_token: str, db: Session):
        """Test that password is properly hashed."""
        headers = {"Authorization": f"Bearer {admin_token}"}
        response = client.post(
            "/api/v1/admin/users/",
            headers=headers,
            json={
                "username": "hashtest",
                "full_name": "Hash Test",
                "password": "plainpassword123"
            }
        )
        
        assert response.status_code == 200
        
        # Get user from database
        user = crud_user.get_by_username(db, username="hashtest")
        assert user is not None
        assert user.hashed_password != "plainpassword123"
        assert user.hashed_password.startswith("$2b$")  # bcrypt hash prefix


class TestAdminGetUsers:
    """Tests for GET /api/v1/admin/users endpoint."""
    
    def test_get_all_users_success(self, client: TestClient, admin_token: str, regular_user: User):
        """Test getting all users as admin."""
        headers = {"Authorization": f"Bearer {admin_token}"}
        response = client.get("/api/v1/admin/users", headers=headers)
        
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) >= 2  # At least admin and regular user
        
        usernames = [user["username"] for user in data]
        assert "admin" in usernames
        assert "testuser" in usernames
    
    def test_get_all_users_non_admin_forbidden(self, client: TestClient, user_token: str):
        """Test that non-admin cannot get all users."""
        headers = {"Authorization": f"Bearer {user_token}"}
        response = client.get("/api/v1/admin/users", headers=headers)
        
        assert response.status_code == 403


class TestAdminGetUserById:
    """Tests for GET /api/v1/admin/users/{user_id} endpoint."""
    
    def test_get_user_by_id_success(self, client: TestClient, admin_token: str, regular_user: User):
        """Test getting user by ID as admin."""
        headers = {"Authorization": f"Bearer {admin_token}"}
        response = client.get(f"/api/v1/admin/users/{regular_user.id}", headers=headers)
        
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == regular_user.id
        assert data["username"] == "testuser"
    
    def test_get_user_by_id_not_found(self, client: TestClient, admin_token: str):
        """Test getting non-existent user."""
        headers = {"Authorization": f"Bearer {admin_token}"}
        response = client.get("/api/v1/admin/users/99999", headers=headers)
        
        assert response.status_code == 404


class TestAdminActivateDeactivateUser:
    """Tests for user activation/deactivation endpoints."""
    
    def test_activate_user_success(self, client: TestClient, admin_token: str, inactive_user: User):
        """Test activating an inactive user."""
        headers = {"Authorization": f"Bearer {admin_token}"}
        response = client.put(
            f"/api/v1/admin/users/{inactive_user.id}/activate",
            headers=headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["is_active"] is True
        
        # Verify user can now login
        login_response = client.post(
            "/api/v1/auth/login",
            data={"username": "inactiveuser", "password": "inactive123456"}
        )
        assert login_response.status_code == 200
    
    def test_deactivate_user_success(self, client: TestClient, admin_token: str, regular_user: User):
        """Test deactivating an active user."""
        headers = {"Authorization": f"Bearer {admin_token}"}
        response = client.put(
            f"/api/v1/admin/users/{regular_user.id}/deactivate",
            headers=headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["is_active"] is False
        
        # Verify user cannot login
        login_response = client.post(
            "/api/v1/auth/login",
            data={"username": "testuser", "password": "testuser123456"}
        )
        assert login_response.status_code == 400
        assert "Inactive user" in login_response.json()["detail"]
    
    def test_deactivate_self_forbidden(self, client: TestClient, admin_token: str, admin_user: User):
        """Test that admin cannot deactivate themselves."""
        headers = {"Authorization": f"Bearer {admin_token}"}
        response = client.put(
            f"/api/v1/admin/users/{admin_user.id}/deactivate",
            headers=headers
        )
        
        assert response.status_code == 400
        assert "Cannot deactivate yourself" in response.json()["detail"]
