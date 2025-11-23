from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app import crud, schemas
from app.api import deps
from app.core import get_db

router = APIRouter()

@router.post("/", response_model=schemas.Task)
def create_task(
    *,
    db: Session = Depends(get_db),
    task_in: schemas.TaskCreate,
    current_user: schemas.User = Depends(deps.get_current_active_user),
) -> Any:
    """
    Create new task.
    """
    # Check if project exists and user has access
    project = crud.project.get(db=db, id=task_in.project_id)
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")
    if project.owner_id != current_user.id:
        raise HTTPException(status_code=400, detail="Not enough permissions")
    
    task = crud.task.create_with_user(
        db=db, obj_in=task_in, created_by_id=current_user.id
    )
    return task

@router.get("/", response_model=List[schemas.Task])
def read_tasks(
    db: Session = Depends(get_db),
    skip: int = 0,
    limit: int = 100,
    project_id: int = None,
    current_user: schemas.User = Depends(deps.get_current_active_user),
) -> Any:
    """
    Retrieve tasks. If project_id is provided, filter by project.
    """
    if project_id:
        print("Filtering tasks by project ID:", project_id)
        # Check if project exists and user has access
        project = crud.project.get(db=db, id=project_id)
        if not project:
            raise HTTPException(status_code=404, detail="Project not found")
        if project.owner_id != current_user.id:
            raise HTTPException(status_code=400, detail="Not enough permissions")
        
        tasks = crud.task.get_by_project(
            db=db, project_id=project_id, skip=skip, limit=limit
        )
    else:
        print("Retrieving tasks created by current user")
        # Get tasks created by current user
        tasks = crud.task.get_by_creator(
            db=db, creator_id=current_user.id, skip=skip, limit=limit
        )
        
    print(f"Retrieved {len(tasks)} tasks")
    return tasks

@router.get("/{id}", response_model=schemas.Task)
def read_task(
    *,
    db: Session = Depends(get_db),
    id: int,
    current_user: schemas.User = Depends(deps.get_current_active_user),
) -> Any:
    """
    Get task by ID.
    """
    task = crud.task.get(db=db, id=id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    
    # Check if user has access to the task (project owner or task creator)
    project = crud.project.get(db=db, id=task.project_id)
    if project.owner_id != current_user.id and task.created_by_id != current_user.id:
        raise HTTPException(status_code=400, detail="Not enough permissions")
    
    return task

@router.put("/{id}", response_model=schemas.Task)
def update_task(
    *,
    db: Session = Depends(get_db),
    id: int,
    task_in: schemas.TaskUpdate,
    current_user: schemas.User = Depends(deps.get_current_active_user),
) -> Any:
    """
    Update a task.
    """
    task = crud.task.get(db=db, id=id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    
    # Check if user has access to the task (project owner or task creator)
    project = crud.project.get(db=db, id=task.project_id)
    if project.owner_id != current_user.id and task.created_by_id != current_user.id:
        raise HTTPException(status_code=400, detail="Not enough permissions")
    
    task = crud.task.update(db=db, db_obj=task, obj_in=task_in)
    return task

@router.delete("/{id}", response_model=schemas.Task)
def delete_task(
    *,
    db: Session = Depends(get_db),
    id: int,
    current_user: schemas.User = Depends(deps.get_current_active_user),
) -> Any:
    """
    Delete a task.
    """
    task = crud.task.get(db=db, id=id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    
    # Check if user has access to the project (only project owner can delete)
    project = crud.project.get(db=db, id=task.project_id)
    if project.owner_id != current_user.id:
        raise HTTPException(status_code=400, detail="Not enough permissions")
    
    task = crud.task.remove(db=db, id=id)
    return task