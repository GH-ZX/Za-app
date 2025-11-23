"""Implement RBAC role field

Revision ID: 003
Revises: 002
Create Date: 2025-11-16 23:27:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '003'
down_revision = '002'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Add new role column with default value
    op.add_column('users', sa.Column('role', sa.String(20), nullable=False, server_default='standard_user'))
    
    # Copy is_superuser values to role column
    # Users with is_superuser=True get role='admin', others get role='standard_user'
    op.execute("""
        UPDATE users 
        SET role = CASE 
            WHEN is_superuser = true THEN 'admin'
            ELSE 'standard_user'
        END
    """)
    
    # Remove the is_superuser column
    op.drop_column('users', 'is_superuser')


def downgrade() -> None:
    # Add back the is_superuser column
    op.add_column('users', sa.Column('is_superuser', sa.Boolean(), nullable=False, server_default='false'))
    
    # Copy role values back to is_superuser
    op.execute("""
        UPDATE users 
        SET is_superuser = CASE 
            WHEN role = 'admin' THEN true
            ELSE false
        END
    """)
    
    # Remove the role column
    op.drop_column('users', 'role')
