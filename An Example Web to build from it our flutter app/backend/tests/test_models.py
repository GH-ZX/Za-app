"""
Tests for database models.
"""

import pytest
from sqlalchemy.orm import Session

from app.models.user import User
from app.crud.crud_user import user as crud_user
from app.schemas.user import UserCreate


class TestUserModel:
    """Tests for User model."""
    
    def test_create_user_with_email(self, db: Session):
        """Test creating a user with email."""
        user_in = UserCreate(
            username="emailuser",
            email="emailuser@example.com",
            full_name="Email User",
            password="password123",
            is_active=True
        )
        
        user = crud_user.create(db, obj_in=user_in)
        
        assert user.id is not None
        assert user.username == "emailuser"
        assert user.email == "emailuser@example.com"
        assert user.full_name == "Email User"
        assert user.is_active is True
        assert user.is_superuser is False
        assert user.hashed_password != "password123"  # Should be hashed
    
    def test_create_user_without_email(self, db: Session):
        """Test creating a user without email."""
        user_in = UserCreate(
            username="noemailuser",
            full_name="No Email User",
            password="password123",
            is_active=True
        )
        
        user = crud_user.create(db, obj_in=user_in)
        
        assert user.id is not None
        assert user.username == "noemailuser"
        assert user.email is None
        assert user.full_name == "No Email User"
        assert user.is_active is True
    
    def test_user_email_optional(self, db: Session):
        """Test that email field is optional."""
        user_in = UserCreate(
            username="optionalemailuser",
            full_name="Optional Email User",
            password="password123"
        )
        
        user = crud_user.create(db, obj_in=user_in)
        
        assert user.email is None
    
    def test_multiple_users_same_email(self, db: Session):
        """Test that multiple users can have no email."""
        user1_in = UserCreate(
            username="user1",
            full_name="User One",
            password="password123"
        )
        user1 = crud_user.create(db, obj_in=user1_in)
        
        user2_in = UserCreate(
            username="user2",
            full_name="User Two",
            password="password123"
        )
        user2 = crud_user.create(db, obj_in=user2_in)
        
        assert user1.email is None
        assert user2.email is None
        assert user1.id != user2.id
    
    def test_user_password_hashing(self, db: Session):
        """Test that passwords are properly hashed."""
        plain_password = "myplainpassword123"
        user_in = UserCreate(
            username="hashuser",
            full_name="Hash User",
            password=plain_password
        )
        
        user = crud_user.create(db, obj_in=user_in)
        
        # Password should not be stored as plain text
        assert user.hashed_password != plain_password
        # Should be bcrypt hash
        assert user.hashed_password.startswith("$2b$")
    
    def test_user_timestamps(self, db: Session):
        """Test that created_at and updated_at are set."""
        user_in = UserCreate(
            username="timestampuser",
            full_name="Timestamp User",
            password="password123"
        )
        
        user = crud_user.create(db, obj_in=user_in)
        
        assert user.created_at is not None
        assert user.updated_at is not None
    
    def test_user_default_values(self, db: Session):
        """Test that default values are set correctly."""
        user_in = UserCreate(
            username="defaultuser",
            full_name="Default User",
            password="password123"
        )
        
        user = crud_user.create(db, obj_in=user_in)
        
        assert user.is_active is True
        assert user.is_superuser is False
    
    def test_get_user_by_username(self, db: Session):
        """Test retrieving user by username."""
        user_in = UserCreate(
            username="getbyusername",
            full_name="Get By Username",
            password="password123"
        )
        created_user = crud_user.create(db, obj_in=user_in)
        
        retrieved_user = crud_user.get_by_username(db, username="getbyusername")
        
        assert retrieved_user is not None
        assert retrieved_user.id == created_user.id
        assert retrieved_user.username == "getbyusername"
    
    def test_get_user_by_email(self, db: Session):
        """Test retrieving user by email."""
        user_in = UserCreate(
            username="getbyemail",
            email="getbyemail@example.com",
            full_name="Get By Email",
            password="password123"
        )
        created_user = crud_user.create(db, obj_in=user_in)
        
        retrieved_user = crud_user.get_by_email(db, email="getbyemail@example.com")
        
        assert retrieved_user is not None
        assert retrieved_user.id == created_user.id
        assert retrieved_user.email == "getbyemail@example.com"
    
    def test_get_user_by_email_none(self, db: Session):
        """Test that get_by_email returns None for non-existent email."""
        user = crud_user.get_by_email(db, email="nonexistent@example.com")
        assert user is None
    
    def test_authenticate_user_success(self, db: Session):
        """Test user authentication with correct password."""
        user_in = UserCreate(
            username="authuser",
            full_name="Auth User",
            password="correctpassword123"
        )
        crud_user.create(db, obj_in=user_in)
        
        authenticated_user = crud_user.authenticate(
            db,
            username="authuser",
            password="correctpassword123"
        )
        
        assert authenticated_user is not None
        assert authenticated_user.username == "authuser"
    
    def test_authenticate_user_wrong_password(self, db: Session):
        """Test user authentication with wrong password."""
        user_in = UserCreate(
            username="authuser2",
            full_name="Auth User 2",
            password="correctpassword123"
        )
        crud_user.create(db, obj_in=user_in)
        
        authenticated_user = crud_user.authenticate(
            db,
            username="authuser2",
            password="wrongpassword"
        )
        
        assert authenticated_user is None
    
    def test_authenticate_user_not_found(self, db: Session):
        """Test authentication with non-existent user."""
        authenticated_user = crud_user.authenticate(
            db,
            username="nonexistent",
            password="password123"
        )
        
        assert authenticated_user is None
    
    def test_is_active_method(self, db: Session):
        """Test is_active method."""
        user_in = UserCreate(
            username="activeuser",
            full_name="Active User",
            password="password123",
            is_active=True
        )
        user = crud_user.create(db, obj_in=user_in)
        
        assert crud_user.is_active(user) is True
    
    def test_is_superuser_method(self, db: Session):
        """Test is_superuser method."""
        user_in = UserCreate(
            username="superuser",
            full_name="Super User",
            password="password123"
        )
        user = crud_user.create(db, obj_in=user_in)
        user.is_superuser = True
        db.add(user)
        db.commit()
        
        assert crud_user.is_superuser(user) is True
