from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from .api import router as api_router
from .core.database import create_tables, SessionLocal
from .models.user import User, UserRole
from .core.security import get_password_hash
import os


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan: run startup and shutdown tasks here."""
    # Startup: ensure DB tables exist and seed initial admin if needed
    create_tables()

    db = SessionLocal()
    try:
        # If any admin exists, do nothing
        print("Checking for existing admin user...")
        existing_admin = db.query(User).filter(User.role == UserRole.ADMIN).first()
        if not existing_admin:
            # Read seed credentials from environment (with safe defaults)
            print("No existing admin user found. Creating a new one...")
            admin_username = os.getenv("ADMIN_USERNAME", "admin")
            admin_email = os.getenv("ADMIN_EMAIL", "admin@example.com")
            admin_full_name = os.getenv("ADMIN_FULL_NAME", "Administrator")
            admin_password = os.getenv("ADMIN_PASSWORD", "admin12345")

            # If a user exists with same username/email, promote to admin
            user_by_username = db.query(User).filter(User.username == admin_username).first()
            user_by_email = db.query(User).filter(User.email == admin_email).first()
            target = user_by_username or user_by_email
            if target:
                target.role = UserRole.ADMIN
                if not target.is_active:
                    target.is_active = True
                db.commit()
            else:
                # Create new admin user
                new_admin = User(
                    username=admin_username,
                    email=admin_email,
                    full_name=admin_full_name,
                    hashed_password=get_password_hash(admin_password),
                    is_active=True,
                    role=UserRole.ADMIN,
                )
                db.add(new_admin)
                db.commit()
    finally:
        db.close()

    # Yield control to the application
    yield

    # Shutdown: add any cleanup here if needed

def create_application() -> FastAPI:
    app = FastAPI(
        title="Task Management API",
        description="A simple task management system API similar to Jira",
        version="1.0.0",
        openapi_url="/api/v1/openapi.json",
        lifespan=lifespan,
    )
    
    # Set up CORS
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],  # In production, specify specific origins
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    
    # Include routers
    app.include_router(api_router, prefix="/api")
    
    return app

app = create_application()

@app.get("/")
async def root():
    return {"message": "Task Management API", "version": "1.0.0"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}