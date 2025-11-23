import os
import uuid
from jose import jwt

from app.core import security


def test_supabase_token_auto_creates_local_user(monkeypatch, client):
    """Simulate a Supabase-issued JWT and call /api/v1/auth/me.

    Expectation: Backend verifies the token using SUPABASE_JWT_SECRET and
    auto-creates a local User mapped by supabase_id when the user doesn't exist.
    """
    # Set a test SUPABASE_JWT_SECRET for verification
    test_secret = 'test-supabase-secret'
    monkeypatch.setenv('SUPABASE_JWT_SECRET', test_secret)

    # Build a fake supabase user payload
    supabase_id = str(uuid.uuid4())
    payload = {
        'sub': supabase_id,
        'email': 'sbuser@example.com',
        'name': 'Supabase Test'
    }

    # Create an HS256 JWT signed with the SUPABASE_JWT_SECRET
    token = jwt.encode(payload, test_secret, algorithm=security.ALGORITHM)

    headers = {'Authorization': f'Bearer {token}'}
    response = client.get('/api/v1/auth/me', headers=headers)

    assert response.status_code == 200
    data = response.json()
    # Username will be derived from email (sbuser)
    assert data['email'] == 'sbuser@example.com'
    assert data['full_name'] == 'Supabase Test'
    assert data['username'].startswith('sbuser')
