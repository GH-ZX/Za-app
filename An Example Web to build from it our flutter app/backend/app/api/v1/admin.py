from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func

from app import crud, schemas
from app.api import deps
from app.core import get_db
from app.models.user import User
from app.models.project import Project
from app.models.task import Task, TaskStatus, TaskPriority

router = APIRouter()

@router.post("/users/", response_model=schemas.User)
def create_user_admin(
    *,
    db: Session = Depends(get_db),
    user_in: schemas.UserCreate,
    current_admin: schemas.User = Depends(deps.get_current_admin_user),
) -> Any:
    """
    Create new user. Admin only.
    
    Requires superuser authorization.
    """
    # Check if username already exists
    existing_user = crud.user.get_by_username(db, username=user_in.username)
    if existing_user:
        raise HTTPException(
            status_code=400,
            detail="The user with this username already exists in the system.",
        )
    
    # Check if email is provided and already exists
    if user_in.email:
        existing_user = crud.user.get_by_email(db, email=user_in.email)
        if existing_user:
            raise HTTPException(
                status_code=400,
                detail="The user with this email already exists in the system.",
            )
    
    # Create user with is_active=True by default and include new profile fields
    user_create = schemas.UserCreate(
        username=user_in.username,
        email=user_in.email,
        full_name=user_in.full_name,
        password=user_in.password,
        is_active=True,
        role=user_in.role,
        personal_id=user_in.personal_id,
        years_of_experience=user_in.years_of_experience,
        joining_date=user_in.joining_date
    )
    
    new_user = crud.user.create(db, obj_in=user_create)
    return new_user

@router.get("/users", response_model=List[schemas.User])
def get_all_users(
    *,
    db: Session = Depends(get_db),
    skip: int = 0,
    limit: int = 100,
    current_admin: schemas.User = Depends(deps.get_current_admin_user),
) -> Any:
    """
    Get all users. Admin only.
    """
    users = crud.user.get_multi(db, skip=skip, limit=limit)
    return users

@router.get("/users/{user_id}", response_model=schemas.User)
def get_user_by_id(
    *,
    db: Session = Depends(get_db),
    user_id: int,
    current_admin: schemas.User = Depends(deps.get_current_admin_user),
) -> Any:
    """
    Get user by ID. Admin only.
    """
    user = crud.user.get(db, id=user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

@router.put("/users/{user_id}/activate", response_model=schemas.User)
def activate_user(
    *,
    db: Session = Depends(get_db),
    user_id: int,
    current_admin: schemas.User = Depends(deps.get_current_admin_user),
) -> Any:
    """
    Activate a user. Admin only.
    """
    user = crud.user.get(db, id=user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    user_update = schemas.UserUpdate(is_active=True)
    user = crud.user.update(db, db_obj=user, obj_in=user_update)
    return user

@router.put("/users/{user_id}/deactivate", response_model=schemas.User)
def deactivate_user(
    *,
    db: Session = Depends(get_db),
    user_id: int,
    current_admin: schemas.User = Depends(deps.get_current_admin_user),
) -> Any:
    """
    Deactivate a user. Admin only.
    """
    user = crud.user.get(db, id=user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    if user.id == current_admin.id:
        raise HTTPException(status_code=400, detail="Cannot deactivate yourself")
    
    user_update = schemas.UserUpdate(is_active=False)
    user = crud.user.update(db, db_obj=user, obj_in=user_update)
    return user

@router.get("/users/{user_id}/projects", response_model=List[schemas.Project])
def get_user_projects(
    *,
    db: Session = Depends(get_db),
    user_id: int,
    skip: int = 0,
    limit: int = 100,
    current_admin: schemas.User = Depends(deps.get_current_admin_user),
) -> Any:
    """
    Get all projects owned by a specific user. Admin only.
    """
    user = crud.user.get(db, id=user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    projects = crud.project.get_by_owner(db, owner_id=user_id, skip=skip, limit=limit)
    return projects

@router.get("/users/{user_id}/tasks", response_model=List[schemas.Task])
def get_user_tasks(
    *,
    db: Session = Depends(get_db),
    user_id: int,
    skip: int = 0,
    limit: int = 100,
    current_admin: schemas.User = Depends(deps.get_current_admin_user),
) -> Any:
    """
    Get all tasks assigned to a specific user. Admin only.
    """
    user = crud.user.get(db, id=user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    tasks = crud.task.get_by_assignee(db, assignee_id=user_id, skip=skip, limit=limit)
    return tasks

@router.get("/tasks", response_model=List[schemas.Task])
def get_all_tasks(
    *,
    db: Session = Depends(get_db),
    skip: int = 0,
    limit: int = 100,
    current_admin: schemas.User = Depends(deps.get_current_admin_user),
) -> Any:
    """
    Get all tasks across all projects. Admin only.
    """
    tasks = crud.task.get_multi(db, skip=skip, limit=limit)
    return tasks

@router.get("/projects", response_model=List[schemas.Project])
def get_all_projects(
    *,
    db: Session = Depends(get_db),
    skip: int = 0,
    limit: int = 100,
    current_admin: schemas.User = Depends(deps.get_current_admin_user),
) -> Any:
    """
    Get all projects across all users. Admin only.
    """
    projects = crud.project.get_multi(db, skip=skip, limit=limit)
    return projects

@router.get("/projects/{project_id}/tasks", response_model=List[schemas.Task])
def get_project_tasks_admin(
    *,
    db: Session = Depends(get_db),
    project_id: int,
    skip: int = 0,
    limit: int = 100,
    current_admin: schemas.User = Depends(deps.get_current_admin_user),
) -> Any:
    """
    Get all tasks for a specific project. Admin only.
    """
    project = crud.project.get(db, id=project_id)
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")
    
    tasks = crud.task.get_by_project(db, project_id=project_id, skip=skip, limit=limit)
    return tasks

@router.get("/stats/system", response_model=schemas.SystemStats)
def get_system_stats(
    *,
    db: Session = Depends(get_db),
    current_admin: schemas.User = Depends(deps.get_current_admin_user),
) -> Any:
    """
    Get system-wide statistics. Admin only.
    """
    # Count users
    total_users = db.query(func.count(User.id)).scalar()
    active_users = db.query(func.count(User.id)).filter(User.is_active == True).scalar()
    inactive_users = total_users - active_users
    
    # Count projects and tasks
    total_projects = db.query(func.count(Project.id)).scalar()
    total_tasks = db.query(func.count(Task.id)).scalar()
    
    # Tasks by status
    status_counts = db.query(
        Task.status, func.count(Task.id)
    ).group_by(Task.status).all()
    
    tasks_by_status = [
        schemas.TaskStatusCount(status=status, count=count)
        for status, count in status_counts
    ]
    
    # Tasks by priority
    priority_counts = db.query(
        Task.priority, func.count(Task.id)
    ).group_by(Task.priority).all()
    
    tasks_by_priority = [
        schemas.TaskPriorityCount(priority=priority, count=count)
        for priority, count in priority_counts
    ]
    
    return schemas.SystemStats(
        total_users=total_users,
        active_users=active_users,
        inactive_users=inactive_users,
        total_projects=total_projects,
        total_tasks=total_tasks,
        tasks_by_status=tasks_by_status,
        tasks_by_priority=tasks_by_priority
    )

@router.get("/stats/users", response_model=List[schemas.UserStats])
def get_users_stats(
    *,
    db: Session = Depends(get_db),
    skip: int = 0,
    limit: int = 100,
    current_admin: schemas.User = Depends(deps.get_current_admin_user),
) -> Any:
    """
    Get statistics for all users. Admin only.
    """
    users = crud.user.get_multi(db, skip=skip, limit=limit)
    user_stats = []
    
    for user in users:
        projects_count = db.query(func.count(Project.id)).filter(Project.owner_id == user.id).scalar()
        tasks_created_count = db.query(func.count(Task.id)).filter(Task.created_by_id == user.id).scalar()
        tasks_assigned_count = db.query(func.count(Task.id)).filter(Task.assignee_id == user.id).scalar()
        
        user_stats.append(schemas.UserStats(
            id=user.id,
            username=user.username,
            full_name=user.full_name,
            projects_count=projects_count,
            tasks_created_count=tasks_created_count,
            tasks_assigned_count=tasks_assigned_count
        ))
    
    return user_stats

@router.get("/stats/projects", response_model=List[schemas.ProjectStats])
def get_projects_stats(
    *,
    db: Session = Depends(get_db),
    skip: int = 0,
    limit: int = 100,
    current_admin: schemas.User = Depends(deps.get_current_admin_user),
) -> Any:
    """
    Get statistics for all projects. Admin only.
    """
    projects = crud.project.get_multi(db, skip=skip, limit=limit)
    project_stats = []
    
    for project in projects:
        # Get owner info
        owner = crud.user.get(db, id=project.owner_id)
        
        # Count total tasks for this project
        total_tasks = db.query(func.count(Task.id)).filter(Task.project_id == project.id).scalar()
        
        # Tasks by status for this project
        status_counts = db.query(
            Task.status, func.count(Task.id)
        ).filter(Task.project_id == project.id).group_by(Task.status).all()
        
        tasks_by_status = [
            schemas.TaskStatusCount(status=status, count=count)
            for status, count in status_counts
        ]
        
        project_stats.append(schemas.ProjectStats(
            id=project.id,
            name=project.name,
            key=project.key,
            owner_username=owner.username if owner else "Unknown",
            total_tasks=total_tasks,
            tasks_by_status=tasks_by_status
        ))
    
    return project_stats