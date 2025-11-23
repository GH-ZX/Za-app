from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional


class CertificateCreate(BaseModel):
    """Schema for creating a certificate (metadata only)"""
    file_name: str = Field(..., min_length=1, max_length=255, description="Original file name")
    mime_type: str = Field(..., min_length=1, max_length=100, description="MIME type of the file")
    file_size: int = Field(..., gt=0, description="File size in bytes")


class CertificateResponse(BaseModel):
    """Schema for certificate response"""
    id: int
    user_id: int
    file_name: str
    file_path: str
    mime_type: str
    file_size: int
    uploaded_at: datetime

    class Config:
        from_attributes = True


class CertificateListResponse(BaseModel):
    """Schema for listing certificates"""
    id: int
    file_name: str
    mime_type: str
    file_size: int
    uploaded_at: datetime

    class Config:
        from_attributes = True
