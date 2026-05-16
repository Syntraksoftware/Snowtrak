"""Add optional stable external id on ski_runs for OpenSkiMap / bulk sync upserts.

Revision ID: 002_ski_runs_source
Revises: 001_initial
Create Date: 2026-04-05

"""

from __future__ import annotations

from alembic import op
from sqlalchemy import text

revision = "002_ski_runs_source"
down_revision = "001_initial"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute(
        text(
            "ALTER TABLE map_trail.ski_runs "
            "ADD COLUMN IF NOT EXISTS source_id TEXT"
        )
    )
    op.execute(
        text(
            "CREATE UNIQUE INDEX IF NOT EXISTS uq_map_trail_ski_runs_source_id "
            "ON map_trail.ski_runs (source_id)"
        )
    )


def downgrade() -> None:
    op.execute(
        text("DROP INDEX IF EXISTS map_trail.uq_map_trail_ski_runs_source_id")
    )
    op.execute(text("ALTER TABLE map_trail.ski_runs DROP COLUMN IF EXISTS source_id"))
