import enum
from sqlalchemy import Column, String, Text, Integer, ForeignKey, Enum, DateTime, func
from sqlalchemy.orm import relationship
from .base import BaseModel

class TaskStatus(enum.Enum):
    TODO = "todo"
    IN_PROGRESS = "in_progress" 
    IN_REVIEW = "in_review"
    DONE = "done"

class TaskPriority(enum.Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    URGENT = "urgent"

class Task(BaseModel):
    __tablename__ = "tasks"
    
    title = Column(String(200), nullable=False)
    description = Column(Text)
    status = Column(Enum(TaskStatus), default=TaskStatus.TODO, nullable=False)
    priority = Column(Enum(TaskPriority), default=TaskPriority.MEDIUM, nullable=False)
    
    # Foreign Keys
    project_id = Column(Integer, ForeignKey("projects.id"), nullable=False)
    assignee_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    created_by_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    
    # Additional fields
    estimate_hours = Column(Integer, nullable=True)
    due_date = Column(DateTime, nullable=True)
    
    # Relationships
    project = relationship("Project", back_populates="tasks")
    assignee = relationship("User", back_populates="assigned_tasks", foreign_keys=[assignee_id])
    created_by = relationship("User", back_populates="created_tasks", foreign_keys=[created_by_id])