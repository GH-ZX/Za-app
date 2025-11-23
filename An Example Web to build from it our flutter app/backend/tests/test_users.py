"""
Tests for the users API endpoints (PUT /api/v1/users/{user_id}).
"""

import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.models.user import User
from app.crud.crud_user import user as crud_user
from app.schemas.user import UserCreate, UserProfileUpdate


class TestUpdateUserProfile:
    """Test suite for user profile update endpoint."""
    
    def test_user_can_update_own_profile(
        self, 
        client: TestClient, 
        regular_user: User, 
        user_token: str
    ):
        """Test that a user can update their own profile."""
        update_data = {
            "full_name": "Updated Name",
            "email": "newemail@example.com",
            "personal_id": "ID-12345",
            "years_of_experience": 5,
            "joining_date": "2020-01-15"
        }
        
        response = client.put(
            f"/api/v1/users/{regular_user.id}",
            json=update_data,
            headers={"Authorization": f"Bearer {user_token}"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["full_name"] == "Updated Name"
        assert data["email"] == "newemail@example.com"
        assert data["personal_id"] == "ID-12345"
        assert data["years_of_experience"] == 5
        assert data["joining_date"] == "2020-01-15"
    
    def test_user_can_update_partial_profile(
        self,
        client: TestClient,
        regular_user: User,
        user_token: str
    ):
        """Test that a user can update only some fields in their profile."""
        update_data = {
            "full_name": "Partially Updated"
        }
        
        response = client.put(
            f"/api/v1/users/{regular_user.id}",
            json=update_data,
            headers={"Authorization": f"Bearer {user_token}"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["full_name"] == "Partially Updated"
        # Original email should remain unchanged
        assert data["email"] == "testuser@example.com"
    
    def test_admin_can_update_any_user_profile(
        self,
        client: TestClient,
        regular_user: User,
        admin_token: str
    ):
        """Test that an admin can update any user's profile."""
        update_data = {
            "full_name": "Admin Updated Name",
            "personal_id": "ADMIN-ID-999",
            "years_of_experience": 10
        }
        
        response = client.put(
            f"/api/v1/users/{regular_user.id}",
            json=update_data,
            headers={"Authorization": f"Bearer {admin_token}"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["full_name"] == "Admin Updated Name"
        assert data["personal_id"] == "ADMIN-ID-999"
        assert data["years_of_experience"] == 10
    
    def test_user_cannot_update_other_user_profile(
        self,
        client: TestClient,
        regular_user: User,
        db: Session
    ):
        """Test that a regular user cannot update another user's profile."""
        # Create another regular user
        other_user_in = UserCreate(
            username="otheruser",
            email="other@example.com",
            full_name="Other User",
            password="other123456",
            is_active=True
        )
        other_user = crud_user.create(db, obj_in=other_user_in)
        
        # Get token for first user
        response = client.post(
            "/api/v1/auth/login",
            data={"username": "testuser", "password": "testuser123456"}
        )
        user_token = response.json()["access_token"]
        
        # Try to update other user's profile
        update_data = {
            "full_name": "Hacked Name"
        }
        
        response = client.put(
            f"/api/v1/users/{other_user.id}",
            json=update_data,
            headers={"Authorization": f"Bearer {user_token}"}
        )
        
        assert response.status_code == 403
        assert "Not enough permissions" in response.json()["detail"]
    
    def test_update_nonexistent_user(
        self,
        client: TestClient,
        admin_token: str
    ):
        """Test updating a user that doesn't exist."""
        update_data = {
            "full_name": "Updated Name"
        }
        
        response = client.put(
            "/api/v1/users/99999",
            json=update_data,
            headers={"Authorization": f"Bearer {admin_token}"}
        )
        
        assert response.status_code == 404
        assert "User not found" in response.json()["detail"]
    
    def test_update_without_authentication(
        self,
        client: TestClient,
        regular_user: User
    ):
        """Test that unauthenticated requests are rejected."""
        update_data = {
            "full_name": "Updated Name"
        }
        
        response = client.put(
            f"/api/v1/users/{regular_user.id}",
            json=update_data
        )
        
        assert response.status_code == 403
    
    def test_update_with_empty_payload(
        self,
        client: TestClient,
        regular_user: User,
        user_token: str
    ):
        """Test that updating with empty payload doesn't change anything."""
        original_name = regular_user.full_name
        
        response = client.put(
            f"/api/v1/users/{regular_user.id}",
            json={},
            headers={"Authorization": f"Bearer {user_token}"}
        )
        
        assert response.status_code == 200
        data = response.json()
        # Name should remain unchanged
        assert data["full_name"] == original_name
    
    def test_update_all_profile_fields(
        self,
        client: TestClient,
        regular_user: User,
        user_token: str
    ):
        """Test updating all available profile fields at once."""
        update_data = {
            "email": "complete@example.com",
            "full_name": "Complete Update",
            "personal_id": "COMPLETE-123",
            "years_of_experience": 7,
            "joining_date": "2019-06-20"
        }
        
        response = client.put(
            f"/api/v1/users/{regular_user.id}",
            json=update_data,
            headers={"Authorization": f"Bearer {user_token}"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["email"] == "complete@example.com"
        assert data["full_name"] == "Complete Update"
        assert data["personal_id"] == "COMPLETE-123"
        assert data["years_of_experience"] == 7
        assert data["joining_date"] == "2019-06-20"
    
    def test_update_profile_persists_in_database(
        self,
        client: TestClient,
        regular_user: User,
        user_token: str,
        db: Session
    ):
        """Test that profile updates are persisted in the database."""
        update_data = {
            "full_name": "Persistent Update",
            "personal_id": "PERSIST-456"
        }
        
        response = client.put(
            f"/api/v1/users/{regular_user.id}",
            json=update_data,
            headers={"Authorization": f"Bearer {user_token}"}
        )
        
        assert response.status_code == 200
        
        # Verify the data was persisted by querying the database
        db_user = crud_user.get(db, id=regular_user.id)
        assert db_user.full_name == "Persistent Update"
        assert db_user.personal_id == "PERSIST-456"


class TestGetUserProfile:
    """Test suite for getting user profile endpoint."""
    
    def test_user_can_get_own_profile(
        self,
        client: TestClient,
        regular_user: User,
        user_token: str
    ):
        """Test that a user can retrieve their own profile."""
        response = client.get(
            f"/api/v1/users/{regular_user.id}",
            headers={"Authorization": f"Bearer {user_token}"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == regular_user.id
        assert data["username"] == regular_user.username
        assert data["email"] == regular_user.email
    
    def test_admin_can_get_any_user_profile(
        self,
        client: TestClient,
        regular_user: User,
        admin_token: str
    ):
        """Test that an admin can retrieve any user's profile."""
        response = client.get(
            f"/api/v1/users/{regular_user.id}",
            headers={"Authorization": f"Bearer {admin_token}"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == regular_user.id
        assert data["username"] == regular_user.username
    
    def test_user_cannot_get_other_user_profile(
        self,
        client: TestClient,
        regular_user: User,
        db: Session
    ):
        """Test that a regular user cannot retrieve another user's profile."""
        # Create another regular user
        other_user_in = UserCreate(
            username="otheruser",
            email="other@example.com",
            full_name="Other User",
            password="other123456",
            is_active=True
        )
        other_user = crud_user.create(db, obj_in=other_user_in)
        
        # Get token for first user
        response = client.post(
            "/api/v1/auth/login",
            data={"username": "testuser", "password": "testuser123456"}
        )
        user_token = response.json()["access_token"]
        
        # Try to get other user's profile
        response = client.get(
            f"/api/v1/users/{other_user.id}",
            headers={"Authorization": f"Bearer {user_token}"}
        )
        
        assert response.status_code == 403
        assert "Not enough permissions" in response.json()["detail"]
    
    def test_get_nonexistent_user(
        self,
        client: TestClient,
        admin_token: str
    ):
        """Test getting a user that doesn't exist."""
        response = client.get(
            "/api/v1/users/99999",
            headers={"Authorization": f"Bearer {admin_token}"}
        )
        
        assert response.status_code == 404
        assert "User not found" in response.json()["detail"]
    
    def test_get_without_authentication(
        self,
        client: TestClient,
        regular_user: User
    ):
        """Test that unauthenticated requests are rejected."""
        response = client.get(
            f"/api/v1/users/{regular_user.id}"
        )
        
        assert response.status_code == 403


class TestUserProfileUpdateAuthorization:
    """Test suite for authorization rules in profile updates."""
    
    def test_superuser_can_update_own_profile(
        self,
        client: TestClient,
        admin_user: User,
        admin_token: str
    ):
        """Test that a superuser can update their own profile."""
        update_data = {
            "full_name": "Admin Updated"
        }
        
        response = client.put(
            f"/api/v1/users/{admin_user.id}",
            json=update_data,
            headers={"Authorization": f"Bearer {admin_token}"}
        )
        
        assert response.status_code == 200
        assert response.json()["full_name"] == "Admin Updated"
    
    def test_superuser_can_update_regular_user(
        self,
        client: TestClient,
        regular_user: User,
        admin_token: str
    ):
        """Test that a superuser can update a regular user's profile."""
        update_data = {
            "full_name": "Updated by Admin",
            "personal_id": "ADMIN-UPDATED"
        }
        
        response = client.put(
            f"/api/v1/users/{regular_user.id}",
            json=update_data,
            headers={"Authorization": f"Bearer {admin_token}"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["full_name"] == "Updated by Admin"
        assert data["personal_id"] == "ADMIN-UPDATED"
    
    def test_inactive_user_cannot_update_profile(
        self,
        client: TestClient,
        inactive_user: User
    ):
        """Test that an inactive user cannot update their profile."""
        # Get token for inactive user (if possible)
        response = client.post(
            "/api/v1/auth/login",
            data={"username": "inactiveuser", "password": "inactive123456"}
        )
        
        # Login should fail for inactive user
        assert response.status_code == 400
        assert "Inactive user" in response.json()["detail"]
