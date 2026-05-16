"""
Map-backend SQLAlchemy ORM (PostGIS).

Tables for resort lines and recorded tracks live in schema ``map_trail`` so they do not
overlap ``public.activities`` from Supabase / activity-backend.

Applicability

- PostGIS required for geometry columns.
- Migrations: from ``backend/``, run ``alembic upgrade head`` (see ``backend/db/migrations/``).
  Optional legacy SQL: ``engine/geometry/001_init_postgis_storage.sql`` for reference;
  Alembic revision ``001_initial`` creates the same public cache tables plus ``map_trail.*``.
- Non-Postgres / no PostGIS: not applicable for this ORM.
"""

from orm.base import Base
from orm.orm_models import Activity, Segment, SkiLift, SkiRun, TrackPoint

__all__ = [
    "Base",
    "Activity",
    "Segment",
    "SkiLift",
    "SkiRun",
    "TrackPoint",
]
