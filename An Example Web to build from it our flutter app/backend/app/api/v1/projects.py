from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app import crud, schemas
from app.api import deps
from app.core import get_db

router = APIRouter()

@router.post("/", response_model=schemas.Project)
def create_project(
    *,
    db: Session = Depends(get_db),
    project_in: schemas.ProjectCreate,
    current_user: schemas.User = Depends(deps.get_current_active_user),
) -> Any:
    """
    Create new project.
    """
    # Check if project key already exists
    if crud.project.get_by_key(db=db, key=project_in.key):
        raise HTTPException(status_code=400, detail="Project key already exists")
    
    project = crud.project.create_with_owner(
        db=db, obj_in=project_in, owner_id=current_user.id
    )
    return project

@router.get("/", response_model=List[schemas.Project])
def read_projects(
    db: Session = Depends(get_db),
    skip: int = 0,
    limit: int = 100,
    current_user: schemas.User = Depends(deps.get_current_active_user),
) -> Any:
    """
    Retrieve projects owned by current user.
    """
    projects = crud.project.get_by_owner(
        db=db, owner_id=current_user.id, skip=skip, limit=limit
    )
    return projects

@router.get("/{id}", response_model=schemas.Project)
def read_project(
    *,
    db: Session = Depends(get_db),
    id: int,
    current_user: schemas.User = Depends(deps.get_current_active_user),
) -> Any:
    """
    Get project by ID.
    """
    project = crud.project.get(db=db, id=id)
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")
    if project.owner_id != current_user.id:
        raise HTTPException(status_code=400, detail="Not enough permissions")
    return project

@router.put("/{id}", response_model=schemas.Project)
def update_project(
    *,
    db: Session = Depends(get_db),
    id: int,
    project_in: schemas.ProjectUpdate,
    current_user: schemas.User = Depends(deps.get_current_active_user),
) -> Any:
    """
    Update a project.
    """
    project = crud.project.get(db=db, id=id)
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")
    if project.owner_id != current_user.id:
        raise HTTPException(status_code=400, detail="Not enough permissions")
    project = crud.project.update(db=db, db_obj=project, obj_in=project_in)
    return project

@router.delete("/{id}", response_model=schemas.Project)
def delete_project(
    *,
    db: Session = Depends(get_db),
    id: int,
    current_user: schemas.User = Depends(deps.get_current_active_user),
) -> Any:
    """
    Delete a project.
    """
    project = crud.project.get(db=db, id=id)
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")
    if project.owner_id != current_user.id:
        raise HTTPException(status_code=400, detail="Not enough permissions")
    project = crud.project.remove(db=db, id=id)
    return project