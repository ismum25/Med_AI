"""add incident description

Revision ID: e1d2f3b4c5d6
Revises: 9c0d3c4a1f22
Create Date: 2026-05-13 00:00:00.000000
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "e1d2f3b4c5d6"
down_revision: Union[str, Sequence[str], None] = "9c0d3c4a1f22"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("incidents", sa.Column("description", sa.Text(), nullable=True))


def downgrade() -> None:
    op.drop_column("incidents", "description")