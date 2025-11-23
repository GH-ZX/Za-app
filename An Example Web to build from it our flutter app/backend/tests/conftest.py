"""
Pytest configuration and shared fixtures for all tests.
"""

import os
import tempfile
from typing import Generator

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, Session

from app.core.database import Base
from app.core.security import get_password_hash
from app.main import app
from app.core import get_db
from app.models.user import User, UserRole
from app.crud.crud_user import user as crud_user
from app.schemas.user import UserCreate


# Create temporary database for testing
@pytest.fixture(scope="session")
def db_engine():
    """Create a temporary SQLite database for testing."""
    db_fd, db_path = tempfile.mkstemp()
    database_url = f"sqlite:///{db_path}"
    
    engine = create_engine(
        database_url,
        connect_args={"check_same_thread": False}
    )
    
    Base.metadata.create_all(bind=engine)
    
    yield engine
    
    os.close(db_fd)
    os.unlink(db_path)


@pytest.fixture(scope="session")
def SessionLocal(db_engine):
    """Create a SessionLocal for the test database."""
    return sessionmaker(autocommit=False, autoflush=False, bind=db_engine)


@pytest.fixture
def db(SessionLocal) -> Generator[Session, None, None]:
    """Provide a database session for each test."""
    connection = SessionLocal.kw["bind"].connect()
    transaction = connection.begin()
    session = SessionLocal(bind=connection)
    
    yield session
    
    session.close()
    transaction.rollback()
    connection.close()


@pytest.fixture
def client(db: Session) -> TestClient:
    """Provide a test client with a test database."""
    def override_get_db():
        yield db
    
    app.dependency_overrides[get_db] = override_get_db
    
    yield TestClient(app)
    
    app.dependency_overrides.clear()


@pytest.fixture
def admin_user(db: Session) -> User:
    """Create an admin user for testing."""
    user_in = UserCreate(
        username="admin",
        email="admin@example.com",
        full_name="Admin User",
        password="admin123456",
        is_active=True,
        role=UserRole.ADMIN
    )
    user = crud_user.create(db, obj_in=user_in)
    return user


@pytest.fixture
def regular_user(db: Session) -> User:
    """Create a regular user for testing."""
    user_in = UserCreate(
        username="testuser",
        email="testuser@example.com",
        full_name="Test User",
        password="testuser123456",
        is_active=True
    )
    return crud_user.create(db, obj_in=user_in)


@pytest.fixture
def inactive_user(db: Session) -> User:
    """Create an inactive user for testing."""
    user_in = UserCreate(
        username="inactiveuser",
        email="inactive@example.com",
        full_name="Inactive User",
        password="inactive123456",
        is_active=False
    )
    return crud_user.create(db, obj_in=user_in)


@pytest.fixture
def admin_token(client: TestClient, admin_user: User) -> str:
    """Get a valid JWT token for admin user."""
    response = client.post(
        "/api/v1/auth/login",
        data={"username": "admin", "password": "admin123456"}
    )
    assert response.status_code == 200
    return response.json()["access_token"]


@pytest.fixture
def user_token(client: TestClient, regular_user: User) -> str:
    """Get a valid JWT token for regular user."""
    response = client.post(
        "/api/v1/auth/login",
        data={"username": "testuser", "password": "testuser123456"}
    )
    assert response.status_code == 200
    return response.json()["access_token"]
