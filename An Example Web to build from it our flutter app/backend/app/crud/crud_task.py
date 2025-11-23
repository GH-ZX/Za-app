from typing import List
from sqlalchemy.orm import Session
from app.crud.base import CRUDBase
from app.models.task import Task, TaskStatus
from app.schemas.task import TaskCreate, TaskUpdate

class CRUDTask(CRUDBase[Task, TaskCreate, TaskUpdate]):
    def get_by_project(
        self, db: Session, *, project_id: int, skip: int = 0, limit: int = 100
    ) -> List[Task]:
        return (
            db.query(self.model)
            .filter(Task.project_id == project_id)
            .offset(skip)
            .limit(limit)
            .all()
        )
    
    def get_by_assignee(
        self, db: Session, *, assignee_id: int, skip: int = 0, limit: int = 100
    ) -> List[Task]:
        print("Filtering tasks by assignee ID:", assignee_id)
        return (
            db.query(self.model)
            .filter(Task.assignee_id == assignee_id)
            .offset(skip)
            .limit(limit)
            .all()
        )
    
    def get_by_creator(
        self, db: Session, *, creator_id: int, skip: int = 0, limit: int = 100
    ) -> List[Task]:
        print("Filtering tasks by creator ID:", creator_id)
        return (
            db.query(self.model)
            .filter(Task.created_by_id == creator_id)
            .offset(skip)
            .limit(limit)
            .all()
        )
    
    def get_by_status(
        self, db: Session, *, status: TaskStatus, skip: int = 0, limit: int = 100
    ) -> List[Task]:
        return (
            db.query(self.model)
            .filter(Task.status == status)
            .offset(skip)
            .limit(limit)
            .all()
        )
    
    def create_with_user(
        self, db: Session, *, obj_in: TaskCreate, created_by_id: int
    ) -> Task:
        obj_in_data = obj_in.dict()
        db_obj = self.model(**obj_in_data, created_by_id=created_by_id)
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj

task = CRUDTask(Task)