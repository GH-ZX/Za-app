from typing import Any
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app import crud, schemas
from app.api import deps
from app.core import get_db

router = APIRouter()


@router.put("/{user_id}", response_model=schemas.User)
def update_user_profile(
    user_id: int,
    user_in: schemas.UserProfileUpdate,
    current_user: schemas.User = Depends(deps.get_current_active_user),
    db: Session = Depends(get_db),
) -> Any:
    """
    Update user profile.
    
    Authorization Rules:
    - Users can update their own profile (user_id == current_user.id)
    - Superusers can update any user's profile
    
    Updatable fields:
    - email
    - full_name
    - personal_id
    - years_of_experience
    - joining_date
    """
    # Get the user to update
    user = crud.user.get(db, id=user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Check authorization
    deps.check_user_access(user_id, current_user)
    
    # Update the user profile
    user = crud.user.update_profile(db, db_obj=user, obj_in=user_in)
    
    return user


@router.get("/{user_id}", response_model=schemas.User)
def get_user(
    user_id: int,
    current_user: schemas.User = Depends(deps.get_current_active_user),
    db: Session = Depends(get_db),
) -> Any:
    """
    Get user by ID.
    
    Authorization Rules:
    - Users can view their own profile
    - Superusers can view any user's profile
    """
    # Get the user
    user = crud.user.get(db, id=user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Check authorization
    deps.check_user_access(user_id, current_user)
    
    return user
