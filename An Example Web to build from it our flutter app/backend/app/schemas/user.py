from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import date
from .base import BaseSchema
from ..models.user import UserRole


class UserBase(BaseModel):
    username: str
    email: Optional[str] = None
    full_name: str
    is_active: bool = True
    role: UserRole = UserRole.STANDARD_USER
    personal_id: Optional[str] = None
    years_of_experience: Optional[int] = None
    joining_date: Optional[date] = None


class UserCreate(UserBase):
    password: str


class UserUpdate(BaseModel):
    username: Optional[str] = None
    email: Optional[str] = None
    full_name: Optional[str] = None
    is_active: Optional[bool] = None
    role: Optional[UserRole] = None
    password: Optional[str] = None
    personal_id: Optional[str] = None
    years_of_experience: Optional[int] = None
    joining_date: Optional[date] = None


class UserProfileUpdate(BaseModel):
    """Schema for user profile updates (self or admin)"""
    email: Optional[str] = None
    full_name: Optional[str] = None
    personal_id: Optional[str] = None
    years_of_experience: Optional[int] = None
    joining_date: Optional[date] = None


class User(BaseSchema, UserBase):
    pass

class UserLogin(BaseModel):
    username: str
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    username: Optional[str] = None