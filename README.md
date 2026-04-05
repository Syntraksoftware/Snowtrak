# Snowtrak

> A skiing-focused fitness tracking and social community app built with Flutter, FastAPI, and Supabase.

### 1. Clone Repository
```bash
git clone https://github.com/Syntraksoftware/syntrak-application.git
cd syntrak-application
```

### 2. Backend Setup (One-time)
The backend uses a **shared Python environment** at the **repository root**: `.venv` (one venv for all four microservices).

```bash
# From repository root (syntrak-application/)
python3.11 -m venv .venv
./.venv/bin/pip install -r backend/requirements.txt
```
**Configure Environment Variables** (optional, defaults provided):
```bash
cd backend
cp main-backend/.env.example main-backend/.env
cp community-backend/.env.example community-backend/.env
cp activity-backend/.env.example activity-backend/.env
cp map-backend/.env.example map-backend/.env
```
See [Backend README](backend/README.md) for detailed configuration.

### 3. Frontend Setup
```bash
cd frontend
flutter pub get
```

**Configure Google Maps:**
- iOS: Add API key to `ios/Runner/AppDelegate.swift`
- Android: Add API key to `android/app/src/main/AndroidManifest.xml`
See [Frontend README](frontend/README.md) for detailed setup.

## Running the Application
> Start All Backend Services
Start all 4 microservices with a single command (`backend/run.py` starts each service with the Python from the repo-root `.venv`):

```bash
cd backend
python run.py
```

> Start Individual Backend Service
```bash
cd backend
python run.py --service <service-name>
```

Available services: `main`, `community`, `activity`, `map`
Example: `python run.py --service main` (authentication only)

> Start Frontend (iOS Simulator)
Prerequisites: Xcode installed with command-line tools (`xcode-select --install`)
`open -a Simulator`

# Run the Flutter app
```
cd frontend
flutter run
```
Then press `r` for hot reload, `R` for hot restart, or `q` to quit.
For other devices: `flutter devices` to list available, then `flutter run -d <device_id>`

### Developer Note (Loopback Networking)
On some macOS + Docker setups, `localhost` works while `127.0.0.1` may timeout for published container ports.

If you see connection timeout errors from Flutter/Dio:
- Prefer `http://localhost:<port>` for local development API base URLs
- Confirm backend is up with `cd backend && docker compose ps`
- Verify connectivity with `curl http://localhost:8080/health`
- If still failing, restart Docker Desktop and the app (runtime URL overrides may be cached)

### Health Checks
Verify all services are running:
```bash
curl http://localhost:8080/health     # Main backend
curl http://localhost:5001/health     # Community backend
curl http://localhost:5100/health     # Activity backend
curl http://localhost:5200/health     # Map backend
```

### Run With Docker Compose
Start all backend containers (default mode: Supabase-backed map service) from the repository root:
```bash
docker compose up --build
```

Run backend containers in background:
```bash
docker compose up --build -d
```

Use local PostGIS for map-backend (optional map-storage ownership mode):
```bash
cd backend
MAP_STORAGE_BACKEND=postgis docker compose --profile postgis up -d --build postgis map-backend
```

Check map-backend health status:
```bash
curl -sS http://localhost:5200/health
```
Expected (when PostGIS mode is enabled):
```json
{"status":"healthy","service":"map-backend","storage":{"backend":"postgis","initialized":true,"status":"healthy"}}
```

Stop all containers:
```bash
docker compose down
```

If you previously used older compose files with fixed container names, run this once to clear legacy containers:
```bash
docker rm -f syntrak-postgis syntrak-map-backend syntrak-main-backend syntrak-community-backend syntrak-activity-backend 2>/dev/null || true
```

## Documentation
- **[Backend README](backend/README.md)** - Backend services, startup, configuration
- **[Frontend README](frontend/README.md)** - Frontend setup, development
- **[Backend Technical Guide](backend/docs/technical_guide.md)** - Backend architecture, contracts, operations, troubleshooting
- **[Frontend Technical Guide](frontend/docs/technical_guide.md)** - Frontend architecture, contracts, operations, troubleshooting
- **[Main Backend](backend/main-backend/README.md)** - Authentication API
- **[Community Backend](backend/community-backend/README.md)** - Social features
- **Frontend Docs**:
  - [Map Services](frontend/docs/map.md) - GPS and map implementation
  - [Architecture](frontend/docs/architecture_map_service.md) - Service architecture
  - [Testing](frontend/docs/testing.md) - Testing guide

### Code quality and linting
- This repository use ruff and mypy to assert code quality. 

**Ruff** is a fast Python linter and formatter. It catches bugs (unused imports, undefined names), keeps import order consistent, and can suggest modern syntax. For this repo it helps the four FastAPI services and `backend/shared/` stay consistent without running many separate tools.

**mypy** is a static type checker for Python. It checks that function arguments, return values, and data structures line up with type hints, which catches whole classes of errors before runtime. It is especially useful as you grow typed Pydantic models and shared helpers across `main-backend`, `community-backend`, `activity-backend`, and `map-backend`.

Configuration lives in `backend/pyproject.toml`. Dart analyzer settings are in `frontend/analysis_options.yaml`.

**Backend (shared venv at repository root):**

```bash
cd backend
../.venv/bin/ruff check .
../.venv/bin/ruff format --check .
../.venv/bin/ruff check . --fix
../.venv/bin/ruff format .
```

```bash
cd backend
../.venv/bin/mypy shared run.py
../.venv/bin/mypy map-backend
```

If `ruff` or `mypy` is not found, create the venv at the **repo root** and install: `python3 -m venv .venv` then `./.venv/bin/pip install -r backend/requirements.txt`.

**Frontend:**

```bash
cd frontend
flutter analyze
dart format --output=none --set-exit-if-changed .
```

**Alembic**:
- Is used to manage changes to the database schema over time, allowing you to version, upgrade, or rollback database structures in a controlled, trackable way. 
- In this context, Alembic is used to create and evolve all map-related database tables and PostGIS extensions within the project, ensuring the schema stays in sync with code changes through migration scripts instead of raw SQL files.

**References:** [Dart style](https://dart.dev/guides/language/effective-dart/style), [Ruff](https://docs.astral.sh/ruff/), [mypy](https://mypy.readthedocs.io/)

### Security
Run before committing to detect accidentally committed secrets:

```bash
./scripts/check_secrets.sh
```
