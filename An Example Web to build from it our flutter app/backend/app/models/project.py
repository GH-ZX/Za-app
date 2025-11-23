from sqlalchemy import Column, String, Text, Integer, ForeignKey, DateTime, func
from sqlalchemy.orm import relationship
from .base import BaseModel

class Project(BaseModel):
    __tablename__ = "projects"
    
    name = Column(String(100), nullable=False)
    description = Column(Text)
    key = Column(String(10), unique=True, index=True, nullable=False)  # e.g., "PROJ"
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    
    # Relationships
    owner = relationship("User", back_populates="created_projects")
    tasks = relationship("Task", back_populates="project", cascade="all, delete-orphan")