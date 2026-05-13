"""add doctor source fields

Revision ID: 1f3a9c7d2b11
Revises: c4d5e6f7a8b9
Create Date: 2026-05-13 00:00:00.000000
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "1f3a9c7d2b11"
down_revision: Union[str, Sequence[str], None] = "c4d5e6f7a8b9"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "doctor_profiles",
        sa.Column("source_profile_url", sa.String(length=512), nullable=True),
    )
    op.create_unique_constraint(
        "uq_doctor_profiles_source_profile_url",
        "doctor_profiles",
        ["source_profile_url"],
    )
    op.add_column(
        "doctor_profiles",
        sa.Column("profile_image_url", sa.Text(), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("doctor_profiles", "profile_image_url")
    op.drop_constraint(
        "uq_doctor_profiles_source_profile_url",
        "doctor_profiles",
        type_="unique",
    )
    op.drop_column("doctor_profiles", "source_profile_url")