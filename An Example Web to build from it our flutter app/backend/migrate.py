#!/usr/bin/env python3
"""
Migration runner script for applying Alembic migrations
"""

import sys
import importlib.util
from pathlib import Path
from app.core.database import engine, SessionLocal
from app.models.user import User
from app.models.project import Project
from app.models.task import Task

# Get migrations directory
MIGRATIONS_DIR = Path(__file__).parent / "migrations" / "versions"

def get_applied_migrations(db):
    """Get list of applied migrations from database"""
    # For now, we'll track migrations in a simple way
    # In production, use Alembic's alembic_version table
    return []

def apply_migration(migration_file):
    """Apply a single migration file"""
    print(f"Applying migration: {migration_file.name}")
    
    # Load the migration module
    spec = importlib.util.spec_from_file_location("migration", migration_file)
    migration = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(migration)
    
    # Get the upgrade function
    if hasattr(migration, 'upgrade'):
        try:
            # Create a mock op object that can execute SQL
            from sqlalchemy import text
            db = SessionLocal()
            
            # For now, we'll use raw SQL execution
            # In production, use proper Alembic operations
            migration.upgrade()
            print(f"✅ Migration {migration_file.name} applied successfully")
        except Exception as e:
            print(f"❌ Error applying migration {migration_file.name}: {e}")
            return False
        finally:
            db.close()
    
    return True

def main():
    """Run all pending migrations"""
    print("Starting database migrations...")
    
    # Get all migration files
    migration_files = sorted(MIGRATIONS_DIR.glob("*.py"))
    migration_files = [f for f in migration_files if not f.name.startswith("__")]
    
    if not migration_files:
        print("No migrations found")
        return
    
    print(f"Found {len(migration_files)} migration(s)")
    
    # For this simple implementation, we'll just create tables
    # In production, use proper Alembic
    print("Creating all tables (if missing)...")
    from app.models.base import BaseModel
    BaseModel.metadata.create_all(bind=engine)
    print("✅ Tables ensured via SQLAlchemy metadata")

    # Ensure any lightweight compatibility migrations are applied
    # - Add supabase_id column if missing
    from sqlalchemy import inspect, text

    inspector = inspect(engine)
    columns = [c['name'] for c in inspector.get_columns('users')] if 'users' in inspector.get_table_names() else []

    with engine.connect() as conn:
        if 'supabase_id' not in columns:
            print('Adding missing column supabase_id to users...')
            try:
                # Postgres / SQLite compatible DDL - keep it simple
                conn.execute(text('ALTER TABLE users ADD COLUMN supabase_id VARCHAR(100)'))
                # Create unique index if supported
                conn.execute(text('CREATE UNIQUE INDEX IF NOT EXISTS ix_users_supabase_id ON users (supabase_id)'))
                print('✅ supabase_id column created')
            except Exception as e:
                print(f'⚠️ Could not add supabase_id column automatically: {e}')

        # Ensure hashed_password is nullable for externally managed users
        if 'hashed_password' in columns:
            # Try to drop NOT NULL constraint where supported (Postgres)
            try:
                conn.execute(text("ALTER TABLE users ALTER COLUMN hashed_password DROP NOT NULL"))
                print('✅ hashed_password made nullable')
            except Exception:
                # SQLite doesn't support ALTER COLUMN to drop not null; skip
                print('ℹ️ Skipped altering hashed_password nullability (not supported by engine)')

    print('Migration check complete.')

if __name__ == "__main__":
    main()
