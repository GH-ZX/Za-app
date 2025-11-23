from passlib.context import CryptContext
from jose import JWTError, jwt
from datetime import datetime, timedelta
from typing import Optional, Dict, Any
import os

# Security configuration
# Primary application JWT secret (legacy/local usage)
SECRET_KEY = os.getenv("JWT_SECRET_KEY", "your-secret-key-here-change-in-production")
ALGORITHM = os.getenv("JWT_ALGORITHM", "HS256")
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "30"))

# Optional Supabase JWT secret. When present we'll validate Supabase-issued tokens
# against this secret. This value should come from your Supabase project's JWT secret
# (service_role key or the project's JWT config) set in the environment for the backend.
SUPABASE_JWT_SECRET = os.getenv("SUPABASE_JWT_SECRET")

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a plain password against its hash"""
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    """Hash a password"""
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    """Create JWT access token"""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def verify_token(token: str) -> Optional[Dict[str, Any]]:
    """Verify JWT token and return decoded payload.

    This helper will attempt to verify a token against the configured
    SUPABASE_JWT_SECRET (when present) and fall back to the application
    SECRET_KEY.

    Returns the decoded payload (dict) on success, or None on failure.
    """
    # Try Supabase secret first if configured (read dynamic env value each call)
    supabase_secret = os.getenv("SUPABASE_JWT_SECRET")
    secrets_to_try = [s for s in (supabase_secret, SECRET_KEY) if s]
    for secret in secrets_to_try:
        try:
            payload = jwt.decode(token, secret, algorithms=[ALGORITHM])
            return payload
        except JWTError:
            continue
    return None