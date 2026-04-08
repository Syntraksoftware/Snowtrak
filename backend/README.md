# Backend Services

Syntrak backend consists of 4 microservices, all using a unified Python environment and standardized entry points.

## Service Overview

| Service                     | Port | Host      | Purpose                                        |
| --------------------------- | ---- | --------- | ---------------------------------------------- |
| **main-backend**      | 8080 | 0.0.0.0   | Authentication, users, notifications, activity |
| **community-backend** | 5001 | 0.0.0.0   | Posts, threads, comments (Reddit-like)         |
| **activity-backend**  | 5100 | 127.0.0.1 | GPS tracking, kudos tracking                   |
| **map-backend**       | 5200 | 127.0.0.1 | Static maps, elevation API (Google Maps)       |

## Starting Services

Use the **repository-root** virtual environment (`.venv/` next to `backend/`), not a venv inside `backend/`. If you previously used `backend/.venv`, **move to the root `.venv`** (recreate at repo root and reinstall from `backend/requirements.txt`—see [Python Environment](#python-environment)). Always add or upgrade packages in that root `.venv` so all four services share one interpreter.

**Activate the venv** (each new shell), from the repository root:

```bash
cd /path/to/syntrak-application   # repository root
source .venv/bin/activate
```

Then run backend commands from `backend/` with plain `python` (the active interpreter is the root `.venv`). Alternatively, without activating: `../.venv/bin/python` from `backend/`, or `./.venv/bin/python backend/run.py` from the repo root.

### Unified Entry Point

All services follow the same standardized entry point: **`python run.py`**

This approach:

- Uses configuration from `config.py` (settings, PORT, HOST, DEBUG)
- Loads environment variables from `.env` file
- Expects the shared interpreter at **repository root** `.venv/` (activate it, or call that `python` explicitly)
- Provides consistent behavior across all services

### Start All Services (1 Terminal, 1 Command)

```bash
# From repo root after: source .venv/bin/activate
cd backend
python run.py
```

This launches all 4 services in parallel with graceful shutdown on Ctrl+C.

### Start Individual Service

```bash
cd backend
python run.py --service <service-name>   # with root .venv activated
```

Available services: `main`, `community`, `activity`, `map`

Examples:

```bash
python run.py --service main         # Start auth backend only
python run.py --service community    # Start community backend only
python run.py --service activity     # Start activity backend only
python run.py --service map          # Start maps backend only
```

### Start Single Service Directly

You can also navigate to a service directory and run it directly:

```bash
cd backend/main-backend
python run.py

# Or with the shared venv explicitly (repo root .venv):
../../.venv/bin/python run.py
```

Example for map-backend:

```bash
cd backend/map-backend
python run.py
# same idea: ../../.venv/bin/python run.py if the venv is not activated
```

### Map-backend: `main.py` is not legacy

`backend/map-backend/main.py` defines the FastAPI **`app`** object (routes, middleware, lifespan, DB pool hooks). **`map-backend/run.py`** is the process entry point: it starts Uvicorn with `main:app`. **Keep both files.** You should not run `python main.py` as a script (there is no `if __name__ == "__main__"` server block); that is what the comment at the top of `main.py` is about—not that the module is deprecated or removable.

## ⚙️ Configuration

### Configuration Files

Each service has a `config.py` file that defines:

- **HOST**: Server binding address (e.g., `0.0.0.0`, `127.0.0.1`)
- **PORT**: Server port number
- **DEBUG**: Development flag (enables reload, verbose logging)
- **SUPABASE_URL**: Supabase project URL
- **SUPABASE_SERVICE_ROLE_KEY**: Supabase service role key
- **JWT_SECRET**: JWT signing secret
- **Other service-specific settings**

### Environment Variables

Override defaults using `.env` file in each service directory:

```env
# Server Configuration
HOST=0.0.0.0
PORT=8080
FASTAPI_ENV=development

# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# JWT
JWT_SECRET=your-jwt-secret
```

### Map schema migrations (Supabase Postgres)

`map_trail` ski runs, lifts, activities, and related tables are managed with **Alembic** under `backend/db/migrations/`. Apply them against your **Supabase** database (enable the **PostGIS** extension in the SQL editor first). Set **`SYNTRAK_DATABASE_URL`** to a **`postgresql+psycopg://`** direct connection string, then from `backend/` run `alembic upgrade head`. Full steps: `backend/db/migrations/README.md`.

## Entry Point Details

### Standardized `run.py` Pattern

All services follow this pattern:

```python
"""
Service Runner - Configuration-driven entry point.
Run with: python run.py
"""
import uvicorn
from config import Config

if __name__ == "__main__":
    config = Config()
    uvicorn.run(
        "main:app",              # FastAPI app module
        host=config.HOST,        # From config
        port=config.PORT,        # From config
        reload=config.DEBUG,     # Auto-reload in development
        log_level="info" if config.DEBUG else "warning",
    )
```

## Health Checks

Verify services are running:

```bash
# Main backend
curl http://127.0.0.1:8080/health

# Community backend
curl http://127.0.0.1:5001/health

# Activity backend
curl http://127.0.0.1:5100/health

# Map backend
curl http://127.0.0.1:5200/health
```

## Python Environment

### Shared Virtual Environment

All services use a single environment at the **repository root**: `.venv/` (sibling of `backend/`, `frontend/`, etc.). Do not rely on a separate `backend/.venv`; if you still have an old one, migrate to the root layout and remove the duplicate to avoid confusion.

**Daily use:** from the repo root, `source .venv/bin/activate`, then `cd backend` and run `python`, `pytest`, `alembic`, etc. **Upgrading deps:** always use this root venv’s `pip` (or `pip install -r backend/requirements.txt` while activated).

```bash
# From repository root — view Python version
./.venv/bin/python --version

# View installed packages
./.venv/bin/pip list

# Install or upgrade a dependency for all services (repo root)
./.venv/bin/pip install <package>
./.venv/bin/pip install -r backend/requirements.txt
```

### Creating or recreating the environment

```bash
# From repository root (parent of backend/)
python3.11 -m venv .venv
./.venv/bin/pip install -r backend/requirements.txt
source .venv/bin/activate
```

## Service Documentation

Platform-level backend technical guide:

- [backend/docs/technical_guide.md](./docs/technical_guide.md) - Architecture, contracts, operations, and troubleshooting

Each service has its own README:

- [main-backend](./main-backend/README.md) - Authentication API
- [community-backend](./community-backend/README.md) - Community/social features
- [activity-backend](./activity-backend/README.md) - GPS and tracking
- [map-backend](./map-backend/README.md) - Maps and elevation

## Testing

Run tests for all services:

```bash
# Main backend tests
cd main-backend && pytest

# Community backend tests
cd community-backend && pytest

# See individual service READMEs for more details
```

## Docker

Run all backend services with Docker Compose:

```bash
cd backend
docker compose up --build
```

Run in detached mode:

```bash
cd backend
docker compose up --build -d
```

Stop services:

```bash
cd backend
docker compose down
```

If you want to start only one service:

```bash
cd backend
docker compose up --build map-backend
```
