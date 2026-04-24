"""add doctor_profiles.years_experience

Revision ID: c4d5e6f7a8b9
Revises: b2c8e4a1f3d0
Create Date: 2026-04-24

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "c4d5e6f7a8b9"
down_revision: Union[str, None] = "b2c8e4a1f3d0"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "doctor_profiles",
        sa.Column("years_experience", sa.Integer(), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("doctor_profiles", "years_experience")
