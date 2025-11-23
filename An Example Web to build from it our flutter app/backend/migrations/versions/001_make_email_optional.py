"""Make email optional and remove unique constraint

Revision ID: 001
Revises: 
Create Date: 2025-11-12 20:54:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '001'
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Remove UNIQUE constraint from email column
    op.drop_constraint('users_email_key', 'users', type_='unique')
    
    # Make email nullable
    op.alter_column('users', 'email',
               existing_type=sa.String(length=100),
               nullable=True,
               existing_nullable=False)


def downgrade() -> None:
    # Restore email as NOT NULL
    op.alter_column('users', 'email',
               existing_type=sa.String(length=100),
               nullable=False,
               existing_nullable=True)
    
    # Restore UNIQUE constraint on email
    op.create_unique_constraint('users_email_key', 'users', ['email'])
