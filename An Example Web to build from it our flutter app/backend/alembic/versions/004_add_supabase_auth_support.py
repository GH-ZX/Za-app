"""Add supabase_id and make hashed_password nullable

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
    # add supabase_id column
    op.add_column('users', sa.Column('supabase_id', sa.String(length=100), nullable=True))
    op.create_index(op.f('ix_users_supabase_id'), 'users', ['supabase_id'], unique=False)

    # allow hashed_password to be nullable for external-auth users
    op.alter_column('users', 'hashed_password', nullable=True, existing_type=sa.String(length=255))


def downgrade() -> None:
    # revert hashed_password nullable
    op.alter_column('users', 'hashed_password', nullable=False, existing_type=sa.String(length=255))

    # drop supabase_id
    op.drop_index(op.f('ix_users_supabase_id'), table_name='users')
    op.drop_column('users', 'supabase_id')
