"""Remove unique constraint from personal_id to allow multiple NULL values

Revision ID: 003
Revises: 002
Create Date: 2025-11-17 01:00:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '003'
down_revision = '002'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Remove the unique constraint from personal_id
    # This allows multiple users to have NULL personal_id
    op.drop_constraint('users_personal_id_key', 'users', type_='unique')


def downgrade() -> None:
    # Re-add the unique constraint if rolling back
    op.create_unique_constraint('users_personal_id_key', 'users', ['personal_id'])
