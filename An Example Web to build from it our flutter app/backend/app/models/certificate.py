from datetime import datetime
from sqlalchemy import Column, Integer, String, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from .base import Base


class UserCertificate(Base):
    """Model for user certificates and attachments"""
    __tablename__ = "user_certificates"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    file_name = Column(String(255), nullable=False)
    file_path = Column(String(500), nullable=False)
    mime_type = Column(String(100), nullable=False)
    file_size = Column(Integer, nullable=False)  # Size in bytes
    uploaded_at = Column(DateTime, default=datetime.utcnow, nullable=False, index=True)

    # Relationship
    user = relationship("User", back_populates="certificates")

    def __repr__(self):
        return f"<UserCertificate(id={self.id}, user_id={self.user_id}, file_name={self.file_name})>"
