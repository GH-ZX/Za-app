from sqlalchemy.orm import Session
from typing import List, Optional, Dict, Any, Union
from app.models import UserCertificate
from app.schemas import CertificateCreate
from .base import CRUDBase


class CRUDCertificate(CRUDBase[UserCertificate, CertificateCreate, CertificateCreate]):
    """CRUD operations for UserCertificate model"""

    def create(
        self,
        db: Session,
        *,
        obj_in: Union[CertificateCreate, Dict[str, Any]],
        user_id: int,
        file_path: str,
    ) -> UserCertificate:
        """Create a new certificate with user_id and file_path"""
        if isinstance(obj_in, dict):
            obj_data = obj_in
        else:
            obj_data = obj_in.dict()
        
        obj_data["user_id"] = user_id
        obj_data["file_path"] = file_path
        
        db_obj = self.model(**obj_data)
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj

    def get_by_user_id(
        self, db: Session, *, user_id: int
    ) -> List[UserCertificate]:
        """Get all certificates for a specific user"""
        return db.query(UserCertificate).filter(
            UserCertificate.user_id == user_id
        ).order_by(UserCertificate.uploaded_at.desc()).all()

    def get_by_id_and_user_id(
        self, db: Session, *, certificate_id: int, user_id: int
    ) -> Optional[UserCertificate]:
        """Get a specific certificate for a user"""
        return db.query(UserCertificate).filter(
            UserCertificate.id == certificate_id,
            UserCertificate.user_id == user_id
        ).first()

    def delete_by_id_and_user_id(
        self, db: Session, *, certificate_id: int, user_id: int
    ) -> bool:
        """Delete a specific certificate for a user"""
        certificate = self.get_by_id_and_user_id(
            db, certificate_id=certificate_id, user_id=user_id
        )
        if certificate:
            db.delete(certificate)
            db.commit()
            return True
        return False


certificate_crud = CRUDCertificate(UserCertificate)
