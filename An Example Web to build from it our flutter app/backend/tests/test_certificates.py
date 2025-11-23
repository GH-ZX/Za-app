import pytest
from io import BytesIO
from fastapi.testclient import TestClient
from app.main import app
from app.core.database import get_db
from app import crud, schemas
from app.models import User, UserCertificate
from tests.conftest import SessionLocal, Base, engine


class TestCertificateUpload:
    """Test certificate upload functionality"""

    def test_user_can_upload_certificate_for_themselves(
        self, client: TestClient, user_token: str, regular_user: User, db
    ):
        """Test that a user can upload a certificate for themselves"""
        file_content = b"PDF file content"
        files = {"file": ("test.pdf", BytesIO(file_content), "application/pdf")}
        
        response = client.post(
            f"/api/v1/users/{regular_user.id}/certificates",
            files=files,
            headers={"Authorization": f"Bearer {user_token}"}
        )
        
        assert response.status_code == 201
        data = response.json()
        assert data["file_name"] == "test.pdf"
        assert data["mime_type"] == "application/pdf"
        assert data["file_size"] == len(file_content)
        assert data["user_id"] == regular_user.id

    def test_admin_can_upload_certificate_for_any_user(
        self, client: TestClient, admin_token: str, regular_user: User, db
    ):
        """Test that an admin can upload a certificate for any user"""
        file_content = b"Image content"
        files = {"file": ("photo.png", BytesIO(file_content), "image/png")}
        
        response = client.post(
            f"/api/v1/users/{regular_user.id}/certificates",
            files=files,
            headers={"Authorization": f"Bearer {admin_token}"}
        )
        
        assert response.status_code == 201
        data = response.json()
        assert data["file_name"] == "photo.png"
        assert data["mime_type"] == "image/png"

    def test_user_cannot_upload_certificate_for_other_user(
        self, client: TestClient, user_token: str, admin_user: User, regular_user: User, db
    ):
        """Test that a user cannot upload a certificate for another user"""
        file_content = b"PDF content"
        files = {"file": ("test.pdf", BytesIO(file_content), "application/pdf")}
        
        response = client.post(
            f"/api/v1/users/{admin_user.id}/certificates",
            files=files,
            headers={"Authorization": f"Bearer {user_token}"}
        )
        
        assert response.status_code == 403
        assert "Not enough permissions" in response.json()["detail"]

    def test_upload_invalid_file_type(
        self, client: TestClient, user_token: str, regular_user: User, db
    ):
        """Test that uploading invalid file type is rejected"""
        file_content = b"Executable content"
        files = {"file": ("malware.exe", BytesIO(file_content), "application/x-msdownload")}
        
        response = client.post(
            f"/api/v1/users/{regular_user.id}/certificates",
            files=files,
            headers={"Authorization": f"Bearer {user_token}"}
        )
        
        assert response.status_code == 400
        assert "not allowed" in response.json()["detail"]

    def test_upload_file_too_large(
        self, client: TestClient, user_token: str, regular_user: User, db
    ):
        """Test that uploading a file larger than 10MB is rejected"""
        # Create a file larger than 10MB
        large_content = b"x" * (11 * 1024 * 1024)
        files = {"file": ("large.pdf", BytesIO(large_content), "application/pdf")}
        
        response = client.post(
            f"/api/v1/users/{regular_user.id}/certificates",
            files=files,
            headers={"Authorization": f"Bearer {user_token}"}
        )
        
        assert response.status_code == 413
        assert "exceeds maximum" in response.json()["detail"]

    def test_upload_to_nonexistent_user(
        self, client: TestClient, user_token: str, db
    ):
        """Test that uploading to a nonexistent user returns 404"""
        file_content = b"PDF content"
        files = {"file": ("test.pdf", BytesIO(file_content), "application/pdf")}
        
        response = client.post(
            f"/api/v1/users/99999/certificates",
            files=files,
            headers={"Authorization": f"Bearer {user_token}"}
        )
        
        assert response.status_code == 404
        assert "not found" in response.json()["detail"]

    def test_upload_without_authentication(
        self, client: TestClient, regular_user: User, db
    ):
        """Test that uploading without authentication is rejected"""
        file_content = b"PDF content"
        files = {"file": ("test.pdf", BytesIO(file_content), "application/pdf")}
        
        response = client.post(
            f"/api/v1/users/{regular_user.id}/certificates",
            files=files
        )
        
        assert response.status_code == 403

    def test_upload_multiple_file_types(
        self, client: TestClient, user_token: str, regular_user: User, db
    ):
        """Test uploading different file types"""
        file_types = [
            ("test.pdf", b"PDF content", "application/pdf"),
            ("image.jpg", b"JPEG content", "image/jpeg"),
            ("image.png", b"PNG content", "image/png"),
            ("doc.docx", b"DOCX content", "application/vnd.openxmlformats-officedocument.wordprocessingml.document"),
        ]
        
        for filename, content, mime_type in file_types:
            files = {"file": (filename, BytesIO(content), mime_type)}
            response = client.post(
                f"/api/v1/users/{regular_user.id}/certificates",
                files=files,
                headers={"Authorization": f"Bearer {user_token}"}
            )
            assert response.status_code == 201


class TestCertificateList:
    """Test certificate listing functionality"""

    def test_user_can_list_own_certificates(
        self, client: TestClient, user_token: str, regular_user: User, db
    ):
        """Test that a user can list their own certificates"""
        # Upload a certificate first
        file_content = b"PDF content"
        files = {"file": ("test.pdf", BytesIO(file_content), "application/pdf")}
        client.post(
            f"/api/v1/users/{regular_user.id}/certificates",
            files=files,
            headers={"Authorization": f"Bearer {user_token}"}
        )
        
        # List certificates
        response = client.get(
            f"/api/v1/users/{regular_user.id}/certificates",
            headers={"Authorization": f"Bearer {user_token}"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) == 1
        assert data[0]["file_name"] == "test.pdf"

    def test_admin_can_list_any_user_certificates(
        self, client: TestClient, admin_token: str, user_token: str, regular_user: User, db
    ):
        """Test that an admin can list any user's certificates"""
        # Upload a certificate as regular user
        file_content = b"PDF content"
        files = {"file": ("test.pdf", BytesIO(file_content), "application/pdf")}
        client.post(
            f"/api/v1/users/{regular_user.id}/certificates",
            files=files,
            headers={"Authorization": f"Bearer {user_token}"}
        )
        
        # List as admin
        response = client.get(
            f"/api/v1/users/{regular_user.id}/certificates",
            headers={"Authorization": f"Bearer {admin_token}"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1

    def test_user_cannot_list_other_user_certificates(
        self, client: TestClient, user_token: str, admin_user: User, db
    ):
        """Test that a user cannot list another user's certificates"""
        response = client.get(
            f"/api/v1/users/{admin_user.id}/certificates",
            headers={"Authorization": f"Bearer {user_token}"}
        )
        
        assert response.status_code == 403

    def test_list_empty_certificates(
        self, client: TestClient, user_token: str, regular_user: User, db
    ):
        """Test listing certificates when none exist"""
        response = client.get(
            f"/api/v1/users/{regular_user.id}/certificates",
            headers={"Authorization": f"Bearer {user_token}"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data == []


class TestCertificateGet:
    """Test getting a specific certificate"""

    def test_user_can_get_own_certificate(
        self, client: TestClient, user_token: str, regular_user: User, db
    ):
        """Test that a user can get their own certificate"""
        # Upload a certificate first
        file_content = b"PDF content"
        files = {"file": ("test.pdf", BytesIO(file_content), "application/pdf")}
        upload_response = client.post(
            f"/api/v1/users/{regular_user.id}/certificates",
            files=files,
            headers={"Authorization": f"Bearer {user_token}"}
        )
        certificate_id = upload_response.json()["id"]
        
        # Get certificate
        response = client.get(
            f"/api/v1/users/{regular_user.id}/certificates/{certificate_id}",
            headers={"Authorization": f"Bearer {user_token}"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == certificate_id
        assert data["file_name"] == "test.pdf"

    def test_get_nonexistent_certificate(
        self, client: TestClient, user_token: str, regular_user: User, db
    ):
        """Test getting a nonexistent certificate"""
        response = client.get(
            f"/api/v1/users/{regular_user.id}/certificates/99999",
            headers={"Authorization": f"Bearer {user_token}"}
        )
        
        assert response.status_code == 404


class TestCertificateDelete:
    """Test certificate deletion"""

    def test_user_can_delete_own_certificate(
        self, client: TestClient, user_token: str, regular_user: User, db
    ):
        """Test that a user can delete their own certificate"""
        # Upload a certificate first
        file_content = b"PDF content"
        files = {"file": ("test.pdf", BytesIO(file_content), "application/pdf")}
        upload_response = client.post(
            f"/api/v1/users/{regular_user.id}/certificates",
            files=files,
            headers={"Authorization": f"Bearer {user_token}"}
        )
        certificate_id = upload_response.json()["id"]
        
        # Delete certificate
        response = client.delete(
            f"/api/v1/users/{regular_user.id}/certificates/{certificate_id}",
            headers={"Authorization": f"Bearer {user_token}"}
        )
        
        assert response.status_code == 204
        
        # Verify it's deleted
        get_response = client.get(
            f"/api/v1/users/{regular_user.id}/certificates/{certificate_id}",
            headers={"Authorization": f"Bearer {user_token}"}
        )
        assert get_response.status_code == 404

    def test_admin_can_delete_any_user_certificate(
        self, client: TestClient, admin_token: str, user_token: str, regular_user: User, db
    ):
        """Test that an admin can delete any user's certificate"""
        # Upload as regular user
        file_content = b"PDF content"
        files = {"file": ("test.pdf", BytesIO(file_content), "application/pdf")}
        upload_response = client.post(
            f"/api/v1/users/{regular_user.id}/certificates",
            files=files,
            headers={"Authorization": f"Bearer {user_token}"}
        )
        certificate_id = upload_response.json()["id"]
        
        # Delete as admin
        response = client.delete(
            f"/api/v1/users/{regular_user.id}/certificates/{certificate_id}",
            headers={"Authorization": f"Bearer {admin_token}"}
        )
        
        assert response.status_code == 204

    def test_user_cannot_delete_other_user_certificate(
        self, client: TestClient, user_token: str, admin_user: User, db
    ):
        """Test that a user cannot delete another user's certificate"""
        response = client.delete(
            f"/api/v1/users/{admin_user.id}/certificates/1",
            headers={"Authorization": f"Bearer {user_token}"}
        )
        
        assert response.status_code == 403
