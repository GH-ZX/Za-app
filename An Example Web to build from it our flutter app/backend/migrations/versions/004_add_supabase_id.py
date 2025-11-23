"""Add supabase_id to users and allow nullable hashed_password

Revision ID: 004
Revises: 003
Create Date: 2025-11-23 00:00:00.000000

"""
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = '004'
down_revision = '003'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Add the supabase_id column (nullable for existing rows) with a unique index
    op.add_column('users', sa.Column('supabase_id', sa.String(length=100), nullable=True))
    op.create_index(op.f('ix_users_supabase_id'), 'users', ['supabase_id'], unique=True)

    # Make hashed_password nullable so externally-managed users are supported
    op.alter_column('users', 'hashed_password', existing_type=sa.String(length=255), nullable=True)


def downgrade() -> None:
    # Revert: make hashed_password NOT NULL and drop supabase_id
    op.alter_column('users', 'hashed_password', existing_type=sa.String(length=255), nullable=False)
    op.drop_index(op.f('ix_users_supabase_id'), table_name='users')
    op.drop_column('users', 'supabase_id')
