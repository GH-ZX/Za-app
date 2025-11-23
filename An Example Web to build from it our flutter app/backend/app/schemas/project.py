from pydantic import BaseModel
from typing import Optional, List
from .base import BaseSchema

class ProjectBase(BaseModel):
    name: str
    description: Optional[str] = None
    key: str

class ProjectCreate(ProjectBase):
    pass

class ProjectUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    key: Optional[str] = None

class Project(BaseSchema, ProjectBase):
    owner_id: int
    
    # We'll add tasks later to avoid circular imports
    class Config:
        from_attributes = True