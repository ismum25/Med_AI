"""add typed ocr report tables

Revision ID: a1f54c8be231
Revises: 947ab1fc1411
Create Date: 2026-04-17 14:10:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision: str = "a1f54c8be231"
down_revision: Union[str, None] = "947ab1fc1411"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    tables = set(inspector.get_table_names())

    if "blood_test_reports" not in tables:
        op.create_table(
            "blood_test_reports",
            sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
            sa.Column("report_id", postgresql.UUID(as_uuid=True), nullable=False),
            sa.Column("patient_name", sa.String(length=255), nullable=True),
            sa.Column("patient_identifier", sa.String(length=120), nullable=True),
            sa.Column("lab_name", sa.String(length=255), nullable=True),
            sa.Column("doctor_name", sa.String(length=255), nullable=True),
            sa.Column("report_date", sa.String(length=30), nullable=True),
            sa.Column("raw_metadata", sa.JSON(), nullable=True),
            sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=True),
            sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=True),
            sa.ForeignKeyConstraint(["report_id"], ["medical_reports.id"], ondelete="CASCADE"),
            sa.PrimaryKeyConstraint("id"),
            sa.UniqueConstraint("report_id"),
        )

    if "blood_test_results" not in tables:
        op.create_table(
            "blood_test_results",
            sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
            sa.Column("blood_report_id", postgresql.UUID(as_uuid=True), nullable=False),
            sa.Column("raw_parameter", sa.String(length=255), nullable=False),
            sa.Column("canonical_parameter", sa.String(length=255), nullable=True),
            sa.Column("value_text", sa.String(length=120), nullable=True),
            sa.Column("value_num", sa.Float(), nullable=True),
            sa.Column("unit", sa.String(length=50), nullable=True),
            sa.Column("reference_range", sa.String(length=120), nullable=True),
            sa.Column("ref_low", sa.Float(), nullable=True),
            sa.Column("ref_high", sa.Float(), nullable=True),
            sa.Column("flag", sa.String(length=30), nullable=True),
            sa.Column("source_confidence", sa.Float(), nullable=True),
            sa.Column("source_page", sa.Integer(), nullable=True),
            sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=True),
            sa.ForeignKeyConstraint(["blood_report_id"], ["blood_test_reports.id"], ondelete="CASCADE"),
            sa.PrimaryKeyConstraint("id"),
        )

    if "urine_test_reports" not in tables:
        op.create_table(
            "urine_test_reports",
            sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
            sa.Column("report_id", postgresql.UUID(as_uuid=True), nullable=False),
            sa.Column("patient_name", sa.String(length=255), nullable=True),
            sa.Column("patient_identifier", sa.String(length=120), nullable=True),
            sa.Column("lab_name", sa.String(length=255), nullable=True),
            sa.Column("doctor_name", sa.String(length=255), nullable=True),
            sa.Column("report_date", sa.String(length=30), nullable=True),
            sa.Column("raw_metadata", sa.JSON(), nullable=True),
            sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=True),
            sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=True),
            sa.ForeignKeyConstraint(["report_id"], ["medical_reports.id"], ondelete="CASCADE"),
            sa.PrimaryKeyConstraint("id"),
            sa.UniqueConstraint("report_id"),
        )

    if "urine_test_results" not in tables:
        op.create_table(
            "urine_test_results",
            sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
            sa.Column("urine_report_id", postgresql.UUID(as_uuid=True), nullable=False),
            sa.Column("raw_parameter", sa.String(length=255), nullable=False),
            sa.Column("canonical_parameter", sa.String(length=255), nullable=True),
            sa.Column("value_text", sa.String(length=120), nullable=True),
            sa.Column("value_num", sa.Float(), nullable=True),
            sa.Column("unit", sa.String(length=50), nullable=True),
            sa.Column("reference_range", sa.String(length=120), nullable=True),
            sa.Column("ref_low", sa.Float(), nullable=True),
            sa.Column("ref_high", sa.Float(), nullable=True),
            sa.Column("flag", sa.String(length=30), nullable=True),
            sa.Column("source_confidence", sa.Float(), nullable=True),
            sa.Column("source_page", sa.Integer(), nullable=True),
            sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=True),
            sa.ForeignKeyConstraint(["urine_report_id"], ["urine_test_reports.id"], ondelete="CASCADE"),
            sa.PrimaryKeyConstraint("id"),
        )

    if "radiology_reports" not in tables:
        op.create_table(
            "radiology_reports",
            sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
            sa.Column("report_id", postgresql.UUID(as_uuid=True), nullable=False),
            sa.Column("patient_name", sa.String(length=255), nullable=True),
            sa.Column("patient_identifier", sa.String(length=120), nullable=True),
            sa.Column("lab_name", sa.String(length=255), nullable=True),
            sa.Column("doctor_name", sa.String(length=255), nullable=True),
            sa.Column("report_date", sa.String(length=30), nullable=True),
            sa.Column("modality", sa.String(length=120), nullable=True),
            sa.Column("body_part", sa.String(length=120), nullable=True),
            sa.Column("study_name", sa.String(length=255), nullable=True),
            sa.Column("findings", sa.Text(), nullable=True),
            sa.Column("impression", sa.Text(), nullable=True),
            sa.Column("recommendation", sa.Text(), nullable=True),
            sa.Column("raw_metadata", sa.JSON(), nullable=True),
            sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=True),
            sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=True),
            sa.ForeignKeyConstraint(["report_id"], ["medical_reports.id"], ondelete="CASCADE"),
            sa.PrimaryKeyConstraint("id"),
            sa.UniqueConstraint("report_id"),
        )

    op.execute("CREATE INDEX IF NOT EXISTS ix_blood_test_results_canonical_parameter ON blood_test_results (canonical_parameter)")
    op.execute("CREATE INDEX IF NOT EXISTS ix_urine_test_results_canonical_parameter ON urine_test_results (canonical_parameter)")


def downgrade() -> None:
    op.execute("DROP INDEX IF EXISTS ix_urine_test_results_canonical_parameter")
    op.execute("DROP INDEX IF EXISTS ix_blood_test_results_canonical_parameter")

    op.execute("DROP TABLE IF EXISTS radiology_reports CASCADE")
    op.execute("DROP TABLE IF EXISTS urine_test_results CASCADE")
    op.execute("DROP TABLE IF EXISTS urine_test_reports CASCADE")
    op.execute("DROP TABLE IF EXISTS blood_test_results CASCADE")
    op.execute("DROP TABLE IF EXISTS blood_test_reports CASCADE")
