from typing import Optional, Union, Dict, Any
from sqlalchemy.orm import Session
from app.core.security import get_password_hash, verify_password
from app.crud.base import CRUDBase
from app.models.user import User, UserRole
from app.schemas.user import UserCreate, UserUpdate, UserProfileUpdate


class CRUDUser(CRUDBase[User, UserCreate, UserUpdate]):
    def get_by_email(self, db: Session, *, email: str) -> Optional[User]:
        return db.query(User).filter(User.email == email).first()

    def get_by_supabase_id(self, db: Session, *, supabase_id: str) -> Optional[User]:
        return db.query(User).filter(User.supabase_id == supabase_id).first()
    
    def get_by_username(self, db: Session, *, username: str) -> Optional[User]:
        return db.query(User).filter(User.username == username).first()
    
    def create(self, db: Session, *, obj_in: UserCreate) -> User:
        db_obj = User(
            email=obj_in.email,
            username=obj_in.username,
            full_name=obj_in.full_name,
            hashed_password=get_password_hash(obj_in.password),
            is_active=obj_in.is_active,
            role=obj_in.role or UserRole.STANDARD_USER,
            personal_id=obj_in.personal_id,
            years_of_experience=obj_in.years_of_experience,
            joining_date=obj_in.joining_date,
        )
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj

    def create_from_supabase(self, db: Session, *, supabase_id: str, email: Optional[str], full_name: Optional[str]) -> User:
        """Create a local User record for a Supabase-authenticated user.

        Note: username is required and must be unique. We'll try to derive it from the
        email or full_name. If neither yield a unique username, generate a safe fallback.
        """
        # Try to derive username
        base_username = None
        if email:
            base_username = email.split("@")[0]
        elif full_name:
            base_username = full_name.lower().replace(" ", "_")

        username = base_username or f"user_{supabase_id[:8]}"
        # Ensure uniqueness - append digits until unique
        suffix = 0
        while db.query(User).filter(User.username == username).first() is not None:
            suffix += 1
            username = f"{base_username or 'user'}_{suffix}"

        db_obj = User(
            username=username,
            email=email,
            full_name=full_name or username,
            hashed_password=None,
            is_active=True,
            role=UserRole.STANDARD_USER,
            supabase_id=supabase_id,
        )
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj
    
    def authenticate(self, db: Session, *, username: str, password: str) -> Optional[User]:
        user = self.get_by_username(db, username=username)
        if not user:
            return None
        if not verify_password(password, user.hashed_password):
            return None
        return user
    
    def is_active(self, user: User) -> bool:
        return user.is_active
    
    def is_admin(self, user: User) -> bool:
        """Check if user has admin role"""
        return user.role == UserRole.ADMIN
    
    def is_superuser(self, user: User) -> bool:
        """Backward compatibility: check if user is admin"""
        return self.is_admin(user)
    
    def update_profile(
        self, 
        db: Session, 
        *, 
        db_obj: User, 
        obj_in: Union[UserProfileUpdate, Dict[str, Any]]
    ) -> User:
        """
        Update user profile with proper password hashing if password is included.
        """
        if isinstance(obj_in, dict):
            update_data = obj_in
        else:
            update_data = obj_in.dict(exclude_unset=True)
        
        # Handle password hashing if password is being updated
        if "password" in update_data:
            update_data["hashed_password"] = get_password_hash(update_data.pop("password"))
        
        # Update the user object
        for field, value in update_data.items():
            if hasattr(db_obj, field):
                setattr(db_obj, field, value)
        
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj

user = CRUDUser(User)