"""add doctor_profiles.availability_timezone

Revision ID: b2c8e4a1f3d0
Revises: a1f54c8be231
Create Date: 2026-04-24

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "b2c8e4a1f3d0"
down_revision: Union[str, None] = "a1f54c8be231"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    if "doctor_profiles" not in inspector.get_table_names():
        return
    cols = {c["name"] for c in inspector.get_columns("doctor_profiles")}
    if "availability_timezone" in cols:
        return
    op.add_column(
        "doctor_profiles",
        sa.Column("availability_timezone", sa.String(length=64), nullable=True),
    )


def downgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    if "doctor_profiles" not in inspector.get_table_names():
        return
    cols = {c["name"] for c in inspector.get_columns("doctor_profiles")}
    if "availability_timezone" not in cols:
        return
    op.drop_column("doctor_profiles", "availability_timezone")
