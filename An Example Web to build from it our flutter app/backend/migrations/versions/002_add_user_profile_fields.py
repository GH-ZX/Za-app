"""Add user profile fields: personal_id, years_of_experience, joining_date

Revision ID: 002
Revises: 001
Create Date: 2025-11-13 02:13:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '002'
down_revision = '001'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Add personal_id column (unique, optional)
    op.add_column('users', sa.Column('personal_id', sa.String(length=50), nullable=True))
    op.create_unique_constraint('users_personal_id_key', 'users', ['personal_id'])
    op.create_index('ix_users_personal_id', 'users', ['personal_id'])
    
    # Add years_of_experience column (integer, optional)
    op.add_column('users', sa.Column('years_of_experience', sa.Integer(), nullable=True))
    
    # Add joining_date column (date, optional)
    op.add_column('users', sa.Column('joining_date', sa.Date(), nullable=True))


def downgrade() -> None:
    # Remove joining_date column
    op.drop_column('users', 'joining_date')
    
    # Remove years_of_experience column
    op.drop_column('users', 'years_of_experience')
    
    # Remove personal_id column and its constraints
    op.drop_index('ix_users_personal_id', 'users')
    op.drop_constraint('users_personal_id_key', 'users', type_='unique')
    op.drop_column('users', 'personal_id')
