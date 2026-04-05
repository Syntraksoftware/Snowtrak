"""
PostGIS-backed object relational mapping (ORM) for resort geometry and recorded activities.

Requires PostgreSQL(supabase) with PostGIS (`CREATE EXTENSION postgis;`). Plain Postgres
without PostGIS cannot store `geometry` columns.

Schema DDL is managed by Alembic: `backend/db/migrations/versions/001_initial_postgis_and_map_trail.py`.
"""

from __future__ import annotations

import uuid
from datetime import datetime
from typing import Any

from geoalchemy2 import Geometry
from sqlalchemy import DateTime, Float, ForeignKey, Integer, String, Text, Uuid
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from db.base import Base

# Isolated from `public.activities` (Supabase / activity-backend). Matches Alembic `001_initial`.
_MAP_SCHEMA = "map_trail"


class SkiRun(Base):
    """Named downhill line on the resort map."""

    __tablename__ = "ski_runs"
    __table_args__ = {"schema": _MAP_SCHEMA}

    id: Mapped[uuid.UUID] = mapped_column(Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String(512), nullable=False)
    difficulty: Mapped[str | None] = mapped_column(String(64), nullable=True)
    geom: Mapped[Any] = mapped_column(
        Geometry(geometry_type="LINESTRING", srid=4326, dimension=2, spatial_index=True),
        nullable=False,
    )


class SkiLift(Base):
    """Lift alignment polyline (WGS84)."""

    __tablename__ = "ski_lifts"
    __table_args__ = {"schema": _MAP_SCHEMA}

    id: Mapped[uuid.UUID] = mapped_column(Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String(512), nullable=False)
    geom: Mapped[Any] = mapped_column(
        Geometry(geometry_type="LINESTRING", srid=4326, dimension=2, spatial_index=True),
        nullable=False,
    )


class Activity(Base):
    """Recorded session header; detailed samples live in `track_points` / `segments`."""

    __tablename__ = "activities"
    __table_args__ = {"schema": _MAP_SCHEMA}

    id: Mapped[uuid.UUID] = mapped_column(Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(Uuid(as_uuid=True), nullable=False, index=True)
    recorded_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    stats: Mapped[dict[str, Any] | None] = mapped_column(JSONB, nullable=True)

    track_points: Mapped[list["TrackPoint"]] = relationship(  # noqa: UP037
        back_populates="activity",
        cascade="all, delete-orphan",
    )
    segments: Mapped[list["Segment"]] = relationship(  # noqa: UP037
        back_populates="activity",
        cascade="all, delete-orphan",
    )


class TrackPoint(Base):
    """Single GPS sample; Z is elevation (m) in WGS84 geographic 3D."""

    __tablename__ = "track_points"
    __table_args__ = {"schema": _MAP_SCHEMA}

    id: Mapped[uuid.UUID] = mapped_column(Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4)
    activity_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey(f"{_MAP_SCHEMA}.activities.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    geom: Mapped[Any] = mapped_column(
        Geometry(geometry_type="POINTZ", srid=4326, spatial_index=True),
        nullable=False,
    )
    speed_kmh: Mapped[float] = mapped_column(Float, nullable=False)
    segment_type: Mapped[str | None] = mapped_column(String(32), nullable=True)

    activity: Mapped[Activity] = relationship(back_populates="track_points")


class Segment(Base):
    """Classified interval along an activity track (indices into ordered track points)."""

    __tablename__ = "segments"
    __table_args__ = {"schema": _MAP_SCHEMA}

    id: Mapped[uuid.UUID] = mapped_column(Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4)
    activity_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey(f"{_MAP_SCHEMA}.activities.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    type: Mapped[str] = mapped_column(String(32), nullable=False)
    start_idx: Mapped[int] = mapped_column(Integer, nullable=False)
    end_idx: Mapped[int] = mapped_column(Integer, nullable=False)
    trail_name: Mapped[str | None] = mapped_column(Text, nullable=True)

    activity: Mapped[Activity] = relationship(back_populates="segments")
