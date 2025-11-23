from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from app.core import get_db, verify_token
from app.crud import user
from app.models.user import User, UserRole

security = HTTPBearer()


def get_current_user(
    db: Session = Depends(get_db),
    credentials: HTTPAuthorizationCredentials = Depends(security)
) -> User:
    """Get current authenticated user"""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    payload = verify_token(credentials.credentials)
    if payload is None:
        raise credentials_exception

    # First try legacy style where the token "sub" was the username
    sub = payload.get("sub")

    db_user = None
    if sub:
        # Try to find by supabase_id first (Supabase tokens will use UUID sub)
        db_user = user.get_by_supabase_id(db, supabase_id=sub)
        if not db_user:
            # Fall back to treating sub as username (legacy tokens)
            db_user = user.get_by_username(db, username=sub)

    # If user still not found, attempt to create a local profile using claims
    if db_user is None:
        # Try email and name claims from the token
        email = payload.get("email")
        name = payload.get("name") or payload.get("full_name")
        if sub:
            try:
                db_user = user.create_from_supabase(db, supabase_id=sub, email=email, full_name=name)
            except Exception:
                # Could not auto-create user - treat as unauthorized
                raise credentials_exception
        else:
            raise credentials_exception
        
    return db_user


def get_current_active_user(current_user: User = Depends(get_current_user)) -> User:
    """Get current active user"""
    if not user.is_active(current_user):
        raise HTTPException(status_code=400, detail="Inactive user")
    return current_user


def get_current_admin_user(current_user: User = Depends(get_current_active_user)) -> User:
    """Get current active admin user (using role-based access)"""
    if not user.is_admin(current_user):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions. Admin access required."
        )
    return current_user


def check_user_access(user_id: int, current_user: User) -> None:
    """
    Check if current user has access to view/edit a specific user's data.
    
    Authorization Rules:
    - Users can access their own data (user_id == current_user.id)
    - Admin users can access any user's data
    
    Raises:
        HTTPException: 403 Forbidden if user doesn't have access
    """
    if user_id != current_user.id and current_user.role != UserRole.ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions to access this resource"
        )