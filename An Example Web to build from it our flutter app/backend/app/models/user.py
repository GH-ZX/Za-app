from enum import Enum
from sqlalchemy import Column, String, Boolean, DateTime, Integer, Date, func
from sqlalchemy.orm import relationship
from .base import BaseModel


class UserRole(str, Enum):
    """User role enumeration for role-based access control (RBAC)"""
    ADMIN = "admin"
    STANDARD_USER = "standard_user"


class User(BaseModel):
    __tablename__ = "users"
    
    username = Column(String(50), unique=True, index=True, nullable=False)
    email = Column(String(100), index=True, nullable=True)
    # ID of the corresponding Supabase Auth user (when using Supabase Auth)
    supabase_id = Column(String(100), unique=True, index=True, nullable=True)
    full_name = Column(String(100), nullable=False)
    # When using Supabase Auth the application can rely on supabase_id and
    # token verification; hashed_password can be null for externally-managed users.
    hashed_password = Column(String(255), nullable=True)
    is_active = Column(Boolean, default=True)
    role = Column(String(20), default=UserRole.STANDARD_USER, nullable=False)
    
    # New optional fields
    personal_id = Column(String(50), index=True, nullable=True)
    years_of_experience = Column(Integer, nullable=True)
    joining_date = Column(Date, nullable=True)
    
    # Relationships
    created_projects = relationship("Project", back_populates="owner", cascade="all, delete-orphan")
    assigned_tasks = relationship("Task", back_populates="assignee", foreign_keys="[Task.assignee_id]")
    created_tasks = relationship("Task", back_populates="created_by", foreign_keys="[Task.created_by_id]")
    certificates = relationship("UserCertificate", back_populates="user", cascade="all, delete-orphan")