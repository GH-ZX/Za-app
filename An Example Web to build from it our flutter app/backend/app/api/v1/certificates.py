import os
import shutil
from typing import List
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.api import deps
from app import crud, schemas, models
from pathlib import Path

router = APIRouter()

# Configuration
UPLOAD_DIR = Path("/app/uploads/certificates")
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10 MB
ALLOWED_MIME_TYPES = {
    "application/pdf",
    "image/jpeg",
    "image/png",
    "image/gif",
    "image/webp",
    "application/msword",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
}

# Create upload directory if it doesn't exist
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)


@router.post(
    "/users/{user_id}/certificates",
    response_model=schemas.CertificateResponse,
    status_code=status.HTTP_201_CREATED,
    tags=["certificates"]
)
async def upload_certificate(
    user_id: int,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_active_user),
) -> schemas.CertificateResponse:
    """
    Upload a certificate for a user.
    
    - Users can upload certificates for themselves
    - Superusers can upload certificates for any user
    - File must be PDF or image (JPEG, PNG, GIF, WebP)
    - Maximum file size: 10 MB
    """
    
    # Authorization check
    if current_user.id != user_id and not current_user.is_superuser:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions to upload certificate for this user"
        )
    
    # Verify user exists
    user = crud.user.get(db, id=user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"User with ID {user_id} not found"
        )
    
    # Validate file type
    if file.content_type not in ALLOWED_MIME_TYPES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"File type '{file.content_type}' not allowed. Allowed types: PDF, JPEG, PNG, GIF, WebP, DOC, DOCX"
        )
    
    # Read file content
    file_content = await file.read()
    
    # Validate file size
    if len(file_content) > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail=f"File size exceeds maximum allowed size of 10 MB"
        )
    
    # Generate unique filename
    import uuid
    file_extension = Path(file.filename).suffix
    unique_filename = f"{uuid.uuid4()}{file_extension}"
    file_path = UPLOAD_DIR / str(user_id) / unique_filename
    
    # Create user-specific directory
    file_path.parent.mkdir(parents=True, exist_ok=True)
    
    # Save file
    try:
        with open(file_path, "wb") as f:
            f.write(file_content)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to save file: {str(e)}"
        )
    
    # Create certificate record in database
    certificate_data = schemas.CertificateCreate(
        file_name=file.filename,
        mime_type=file.content_type,
        file_size=len(file_content)
    )
    
    certificate = crud.certificate_crud.create(
        db,
        obj_in=certificate_data,
        user_id=user_id,
        file_path=str(file_path)
    )
    
    return certificate


@router.get(
    "/users/{user_id}/certificates",
    response_model=List[schemas.CertificateListResponse],
    tags=["certificates"]
)
async def list_user_certificates(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_active_user),
) -> List[schemas.CertificateListResponse]:
    """
    List all certificates for a user.
    
    - Users can view their own certificates
    - Superusers can view any user's certificates
    """
    
    # Authorization check
    if current_user.id != user_id and not current_user.is_superuser:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions to view certificates for this user"
        )
    
    # Verify user exists
    user = crud.user.get(db, id=user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"User with ID {user_id} not found"
        )
    
    certificates = crud.certificate_crud.get_by_user_id(db, user_id=user_id)
    return certificates


@router.get(
    "/users/{user_id}/certificates/{certificate_id}",
    response_model=schemas.CertificateResponse,
    tags=["certificates"]
)
async def get_certificate(
    user_id: int,
    certificate_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_active_user),
) -> schemas.CertificateResponse:
    """
    Get a specific certificate for a user.
    
    - Users can view their own certificates
    - Superusers can view any user's certificates
    """
    
    # Authorization check
    if current_user.id != user_id and not current_user.is_superuser:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions to view this certificate"
        )
    
    certificate = crud.certificate_crud.get_by_id_and_user_id(
        db, certificate_id=certificate_id, user_id=user_id
    )
    
    if not certificate:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Certificate with ID {certificate_id} not found for user {user_id}"
        )
    
    return certificate


@router.delete(
    "/users/{user_id}/certificates/{certificate_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    tags=["certificates"]
)
async def delete_certificate(
    user_id: int,
    certificate_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_active_user),
) -> None:
    """
    Delete a certificate for a user.
    
    - Users can delete their own certificates
    - Superusers can delete any user's certificates
    """
    
    # Authorization check
    if current_user.id != user_id and not current_user.is_superuser:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions to delete this certificate"
        )
    
    # Get certificate to find file path
    certificate = crud.certificate_crud.get_by_id_and_user_id(
        db, certificate_id=certificate_id, user_id=user_id
    )
    
    if not certificate:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Certificate with ID {certificate_id} not found for user {user_id}"
        )
    
    # Delete file from filesystem
    try:
        file_path = Path(certificate.file_path)
        if file_path.exists():
            file_path.unlink()
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete file: {str(e)}"
        )
    
    # Delete from database
    crud.certificate_crud.delete_by_id_and_user_id(
        db, certificate_id=certificate_id, user_id=user_id
    )
