# Snowtrak

> A skiing-focused fitness tracking and social community app built with Flutter, FastAPI, and Supabase.

### 1. Clone Repository
```bash
git clone https://github.com/Syntraksoftware/syntrak-application.git
cd syntrak-application
```

### 2. Backend Setup (One-time)
The backend uses a **shared Python environment** at `backend/.venv` for all 4 microservices.

```bash
cd backend
python3.11 -m venv .venv
./.venv/bin/pip install -r requirements.txt
```
**Configure Environment Variables** (optional, defaults provided):
```bash
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
Start all 4 microservices with a single command:

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

### Health Checks
Verify all services are running:
```bash
curl http://127.0.0.1:8080/health     # Main backend
curl http://127.0.0.1:5001/health     # Community backend
curl http://127.0.0.1:5100/health     # Activity backend
curl http://127.0.0.1:5200/health     # Map backend
```

### Run With Docker Compose
Start all backend containers from the repository root:
```bash
docker compose up --build
```

Run backend containers in background:
```bash
docker compose up --build -d
```

Stop all containers:
```bash
docker compose down
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

### Code Style

- **Flutter**: [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- **Python**: [PEP 8](https://pep8.org/) (use `black` formatter)

### Security
Run before committing to detect accidentally committed secrets:

```bash
./scripts/check_secrets.sh
```
