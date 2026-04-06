Alembic revision scripts for PostGIS (map-backend ORM).

Run from `backend/`:

```bash
export SYNTRAK_DATABASE_URL=postgresql+psycopg://USER:PASSWORD@HOST:PORT/DATABASE
alembic upgrade head
```

`env.py` loads SQLAlchemy metadata from `map-backend/db/` and appends `map-backend` to `sys.path`.
