# Syntrak

> A skiing-focused fitness tracking and social community app built with Flutter, FastAPI, and Supabase.

Syntrak combines the activity tracking features of Strava with social community features similar to Reddit and Threads, specifically designed for skiing enthusiasts.

## Tech Stack

- **Frontend**: Flutter (Dart) with Provider state management
- **Backend**: FastAPI microservices with Supabase integration
- **Database**: Supabase (PostgreSQL)
- **Maps**: Google Maps Flutter SDK
- **Location**: Geolocator for GPS tracking

## 🚀 Quick Start

### Prerequisites

- **Flutter**: 3.0+ ([Install](https://flutter.dev/docs/get-started/install))
- **Python**: 3.11+ ([Install](https://www.python.org/downloads/))
- **Supabase Account**: ([Sign up](https://supabase.com)) - Optional
- **Google Maps API Key**: ([Get key](https://console.cloud.google.com/)) - For map features

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

## ▶️ Running the Application

### Start All Backend Services

Start all 4 microservices with a single command:

```bash
cd backend
python run.py
```

This launches:

- 🔐 **main-backend** (port 8080) - Authentication & core APIs
- 👥 **community-backend** (port 5001) - Posts, threads, comments
- 🎿 **activity-backend** (port 5100) - GPS tracking, kudos
- 🗺️ **map-backend** (port 5200) - Maps, elevation APIs

Press `Ctrl+C` to stop all services gracefully.

### Start Individual Backend Service

```bash
cd backend
python run.py --service <service-name>
```

Available services: `main`, `community`, `activity`, `map`

Example: `python run.py --service main` (authentication only)

### Start Frontend (iOS Simulator)

Prerequisites: Xcode installed with command-line tools (`xcode-select --install`)

```bash
# Start iOS Simulator (if not already running)
open -a Simulator

# Run the Flutter app
cd frontend
flutter run
```

Then press `r` for hot reload, `R` for hot restart, or `q` to quit.

For other devices: `flutter devices` to list available, then `flutter run -d <device_id>`

### Deploy Frontend UI to Vercel (Marketing Review)

This flow deploys the Flutter Web build as a static site so your team can review UI quickly.

1) Build the web app locally:

```bash
cd frontend
flutter pub get
flutter build web --release
```

2) Install Vercel CLI (one-time):

```bash
npm i -g vercel
```

3) Deploy from the `frontend` folder:

```bash
cd frontend
vercel
```

Use the prompts:
- Set up and deploy? `Y`
- Scope: select your account/team
- Link to existing project? `N` (first time)
- Project name: e.g. `syntrak-ui-review`
- In which directory is your code? `./`
- Override settings? `N` (the included `frontend/vercel.json` handles output and SPA rewrites)

4) Share preview URL with marketing. For production URL:

```bash
vercel --prod
```

Notes:
- This deploy is intended for UI review; backend-dependent features may need API/base URL config before full functionality.
- If routes return 404 on refresh, ensure deploy is from `frontend` so `frontend/vercel.json` is picked up.

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

Start frontend web container as well (served on http://localhost:8088):

```bash
docker compose --profile web up --build
```

Stop all containers:

```bash
docker compose down
```

## 📁 Project Structure

```
syntrak-application/
├── frontend/                    # Flutter mobile app
│   ├── lib/
│   │   ├── core/               # Theme, helpers
│   │   ├── models/             # Data models
│   │   ├── providers/          # State management
│   │   ├── screens/            # UI screens
│   │   ├── services/           # API, location, storage
│   │   └── widgets/            # Reusable widgets
│   ├── doc/                    # Frontend documentation
│   └── README.md
│
├── backend/                    # All microservices (unified)
│   ├── main-backend/           # FastAPI (Auth & Core)
│   ├── community-backend/      # FastAPI (Community)
│   ├── activity-backend/       # FastAPI (Activities)
│   ├── map-backend/            # FastAPI (Maps)
│   ├── .venv/                  # Shared Python environment
│   ├── requirements.txt        # Unified dependencies
│   ├── run.py                  # Master orchestrator
│   ├── README.md               # Backend documentation
│   └── (service READMEs)
│
└── docs/                       # Root documentation
```

## 📚 Documentation

- **[Backend README](backend/README.md)** - Backend services, startup, configuration
- **[Frontend README](frontend/README.md)** - Frontend setup, development
- **[Main Backend](backend/main-backend/README.md)** - Authentication API
- **[Community Backend](backend/community-backend/README.md)** - Social features
- **Frontend Docs**:
  - [Map Services](frontend/doc/map.md) - GPS & map implementation
  - [Architecture](frontend/doc/architecture_map_service.md) - Service architecture
  - [Testing](frontend/doc/testing.md) - Testing guide

## ✨ Key Features

### Activity Tracking

- Real-time GPS tracking with route visualization
- Multiple activity types (Alpine, Cross-Country, Freestyle, Backcountry)
- Live metrics (distance, speed, elevation, duration)
- Activity history and analytics
- Offline recording support

### Maps & Location

- Google Maps integration with real-time polyline rendering
- GPS point filtering and smoothing
- Elevation data correction
- Route distance and pace calculations

### Social Features

- Community feed with posts and replies
- Thread-style conversations
- Likes, reposts, and comments
- Groups and clubs
- User profiles and activity sharing

### Authentication & Security

- JWT-based authentication
- Bcrypt password hashing
- Token refresh mechanism
- Supabase user management

## 🧪 Development

### Running Tests

**Frontend:**

```bash
cd frontend
flutter test
```

**Backend:**

```bash
cd backend/<service>
pytest
```

### Code Style

- **Flutter**: [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- **Python**: [PEP 8](https://pep8.org/) (use `black` formatter)

### Security

Run before committing to detect accidentally committed secrets:

```bash
./scripts/check_secrets.sh
```

## 🔗 Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Supabase Documentation](https://supabase.com/docs)
- [Google Maps API](https://console.cloud.google.com/)
