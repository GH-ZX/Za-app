from pydantic import BaseModel
from typing import Dict, List
from app.models.task import TaskStatus, TaskPriority

class TaskStatusCount(BaseModel):
    status: TaskStatus
    count: int

class TaskPriorityCount(BaseModel):
    priority: TaskPriority
    count: int

class UserStats(BaseModel):
    id: int
    username: str
    full_name: str
    projects_count: int
    tasks_created_count: int
    tasks_assigned_count: int

class SystemStats(BaseModel):
    total_users: int
    active_users: int
    inactive_users: int
    total_projects: int
    total_tasks: int
    tasks_by_status: List[TaskStatusCount]
    tasks_by_priority: List[TaskPriorityCount]

class ProjectStats(BaseModel):
    id: int
    name: str
    key: str
    owner_username: str
    total_tasks: int
    tasks_by_status: List[TaskStatusCount]