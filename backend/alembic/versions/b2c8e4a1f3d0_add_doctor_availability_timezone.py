"""add doctor_profiles.availability_timezone

Revision ID: b2c8e4a1f3d0
Revises: 947ab1fc1411
Create Date: 2026-04-24

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "b2c8e4a1f3d0"
down_revision: Union[str, None] = "947ab1fc1411"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "doctor_profiles",
        sa.Column("availability_timezone", sa.String(length=64), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("doctor_profiles", "availability_timezone")
