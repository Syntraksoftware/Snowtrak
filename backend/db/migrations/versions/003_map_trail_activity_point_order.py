"""Track point ordering and segment difficulty for map_trail pipeline persistence.

Revision ID: 003_map_trail_activity_point_order
Revises: 002_ski_runs_source
Create Date: 2026-04-06

"""

from __future__ import annotations

from alembic import op
from sqlalchemy import text

revision = "003_map_trail_activity_point_order"
down_revision = "002_ski_runs_source"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute(
        text(
            "ALTER TABLE map_trail.track_points "
            "ADD COLUMN IF NOT EXISTS sort_idx INTEGER"
        )
    )
    op.execute(
        text(
            """
            UPDATE map_trail.track_points AS tp
            SET sort_idx = s.i
            FROM (
                SELECT id,
                       (ROW_NUMBER() OVER (PARTITION BY activity_id ORDER BY id) - 1)::int AS i
                FROM map_trail.track_points
            ) AS s
            WHERE tp.id = s.id AND tp.sort_idx IS NULL
            """
        )
    )
    op.execute(text("UPDATE map_trail.track_points SET sort_idx = 0 WHERE sort_idx IS NULL"))
    op.execute(
        text(
            "ALTER TABLE map_trail.track_points ALTER COLUMN sort_idx SET NOT NULL"
        )
    )
    op.execute(
        text(
            "CREATE UNIQUE INDEX IF NOT EXISTS uq_map_trail_track_points_activity_sort "
            "ON map_trail.track_points (activity_id, sort_idx)"
        )
    )

    op.execute(
        text(
            "ALTER TABLE map_trail.segments "
            "ADD COLUMN IF NOT EXISTS difficulty VARCHAR(64)"
        )
    )


def downgrade() -> None:
    op.execute(text("ALTER TABLE map_trail.segments DROP COLUMN IF EXISTS difficulty"))
    op.execute(
        text("DROP INDEX IF EXISTS map_trail.uq_map_trail_track_points_activity_sort")
    )
    op.execute(text("ALTER TABLE map_trail.track_points DROP COLUMN IF EXISTS sort_idx"))
