from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from app.models.task import TaskStatus, TaskPriority
from .base import BaseSchema

class TaskBase(BaseModel):
    title: str
    description: Optional[str] = None
    status: TaskStatus = TaskStatus.TODO
    priority: TaskPriority = TaskPriority.MEDIUM
    estimate_hours: Optional[int] = None
    due_date: Optional[datetime] = None

class TaskCreate(TaskBase):
    project_id: int
    assignee_id: Optional[int] = None

class TaskUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    status: Optional[TaskStatus] = None
    priority: Optional[TaskPriority] = None
    assignee_id: Optional[int] = None
    estimate_hours: Optional[int] = None
    due_date: Optional[datetime] = None

class Task(BaseSchema, TaskBase):
    project_id: int
    assignee_id: Optional[int] = None
    created_by_id: int
    
    class Config:
        from_attributes = True