# Syntrak

> A skiing-focused fitness tracking and social community app built with Flutter, FastAPI, and Flask.

Syntrak combines the activity tracking features of Strava with social community features similar to Reddit and Threads, specifically designed for skiing enthusiasts.

## Overview

Syntrak is a comprehensive mobile application that enables users to:

- **Track Activities**: Record skiing activities with GPS tracking, route visualization, and detailed metrics
- **Social Community**: Engage in community-driven discussions, share activities, and connect with other skiers
- **Groups & Clubs**: Join skiing groups, participate in challenges, and build your skiing community
- **Profile & Analytics**: View detailed statistics, activity history, and progress over time

## Architecture

This is a monorepo containing three main components:

```
syntrak-app/
├── frontend/              # Flutter mobile app (iOS & Android)
├── main-backend/          # FastAPI backend (Authentication & Core API)
└── community-backend/     # Flask backend (Community features)
```

### Tech Stack

- **Frontend**: Flutter (Dart) with Provider for state management
- **Main Backend**: FastAPI (Python) with Supabase integration
- **Community Backend**: Flask (Python) with Supabase integration
- **Database**: Supabase (PostgreSQL)
- **Maps**: Google Maps Flutter SDK
- **Location**: Geolocator for GPS tracking

## Quick Start

### Prerequisites

- **Flutter**: 3.0+ ([Install Flutter](https://flutter.dev/docs/get-started/install))
- **Python**: 3.11+ ([Install Python](https://www.python.org/downloads/))
- **Supabase Account**: ([Sign up](https://supabase.com)) - Optional but recommended
- **Google Maps API Key**: ([Get API Key](https://console.cloud.google.com/)) - For map features

### 1. Clone the Repository

```bash
git clone https://github.com/Syntraksoftware/syntrak-application.git
cd syntrak-application
```

### 2. Frontend Setup

```bash
cd frontend
flutter pub get
```

**Configure Google Maps** (for map features):

- iOS: Add API key to `ios/Runner/AppDelegate.swift`
- Android: Add API key to `android/app/src/main/AndroidManifest.xml`

See [Frontend README](frontend/README.md) for detailed setup instructions.

### 3. Main Backend Setup

```bash
cd main-backend
python3 -m venv .venv
source .venv/bin/activate   # macOS/Linux (use .venv\Scripts\activate on Windows)
.venv/bin/pip install -r requirements.txt
```

Use the venv’s pip (e.g. `pip install` after activation or `.venv/bin/pip`) so you don’t hit the system “externally-managed-environment” error. Activate with `source .venv/bin/activate` before running the app.

**Configure Supabase** (optional):

```bash
cp .env.example .env
# Edit .env with your Supabase credentials
```

See [Main Backend README](main-backend/README.md) for detailed setup.

### 4. Community Backend Setup

The first time you run the community backend, `./run.sh` will create a `venv`, install dependencies, and start the server. No separate setup step is required.

To set up manually (optional):

```bash
cd community-backend
python3 -m venv venv
venv/bin/pip install -r requirements.txt
```

If install fails (e.g. on Python 3.13 with an old venv), remove the venv and run again: `rm -rf venv && ./run.sh`.

See [Community Backend README](community-backend/README.md) for detailed setup.

### 5. Run the Application

## Start Menu (macOS)

Use this section when you want the fastest path to boot everything locally.

### Option A: Start all services (4 terminals)

Terminal 1 - Main backend (FastAPI on 8080):

```bash
cd main-backend
source .venv/bin/activate
python run.py
```

Terminal 2 - Community backend (Flask on 5001):

```bash
cd community-backend
./run.sh
```

Terminal 3 - Activity backend (FastAPI on 5100):

```bash
cd activity-backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python main.py
```

Terminal 4 - Flutter app:

```bash
cd frontend
flutter pub get
flutter run
```

### Option B: Start only app + auth backend

Terminal 1:

```bash
cd main-backend
source .venv/bin/activate
python run.py
```

Terminal 2:

```bash
cd frontend
flutter run
```

### Health checks

- Main backend: `http://127.0.0.1:8080/health`
- Community backend: `http://127.0.0.1:5001/health`
- Activity backend: `http://127.0.0.1:5100/health`

### Run Frontend on iOS Simulator (optional details)

Prerequisites: Xcode installed (from the Mac App Store) and Xcode command-line tools set up (`xcode-select --install` if needed).

1. Open the iOS Simulator (optional; Flutter can open it for you):

   - In Xcode: **Xcode → Open Developer Tool → Simulator**
   - Or from terminal: `open -a Simulator`
2. Boot a simulator device if none is running: in the Simulator app, use **File → Open Simulator** and choose an iPhone (e.g. iPhone 16). Wait until the home screen appears.
3. From the project root, go to the frontend and run:

```bash
cd frontend
flutter run
```

Flutter will detect the running simulator and build and launch the app there. To target a specific device (e.g. a certain iPhone model), list devices first:

```bash
flutter devices
```

Then run on a chosen device:

```bash
flutter run -d <device_id>
```

Example: `flutter run -d "iPhone 16 Pro"` or use the device ID from `flutter devices`.

4. While the app is running you can press `r` in the terminal for hot reload and `R` for hot restart. Press `q` to quit.

If the simulator is already open and no other devices are connected, `flutter run` from the `frontend` directory is enough; Flutter will pick the iOS simulator by default.

## Project Structure

```
syntrak-app/
├── frontend/                    # Flutter mobile application
│   ├── lib/
│   │   ├── core/               # Theme, helpers
│   │   ├── models/             # Data models
│   │   ├── providers/          # State management
│   │   ├── screens/            # UI screens
│   │   ├── services/           # API, location, storage services
│   │   └── widgets/             # Reusable widgets
│   ├── doc/                    # Frontend documentation
│   └── README.md
│
├── main-backend/                # FastAPI backend (Auth & Core)
│   ├── app/
│   │   ├── api/v1/            # API endpoints
│   │   ├── core/              # Config, security, storage
│   │   └── schemas/           # Pydantic models
│   ├── doc/                   # Backend documentation
│   └── README.md
│
├── community-backend/           # Flask backend (Community)
│   ├── routes/                # API routes
│   ├── models/                # Data models
│   ├── services/              # Business logic
│   ├── doc/                   # Community backend docs
│   └── README.md
│
└── docs/                       # Root-level documentation
```

## Documentation

### Frontend Documentation

- [Frontend README](frontend/README.md) - Setup and development guide
- [Map Services](frontend/doc/map.md) - Map implementation and GPS tracking
- [Architecture](frontend/doc/architecture_map_service.md) - Service architecture
- [UI/UX Guidelines](frontend/doc/ui_ux_prompt.md) - Design system
- [Testing Guide](frontend/doc/testing.md) - Testing best practices

### Backend Documentation

- [Main Backend README](main-backend/README.md) - Authentication API setup
- [Community Backend README](community-backend/README.md) - Community features

## Key Features

### Activity Tracking

- Real-time GPS tracking with route visualization
- Multiple activity types (Alpine, Cross-Country, Freestyle, Backcountry, Snowboard)
- Live metrics (distance, speed, elevation, duration)
- Activity history and detailed analytics
- Offline recording support

### Map Services

- Google Maps integration
- Real-time route polyline rendering
- GPS point filtering and smoothing
- Route calculation (distance, elevation, pace)
- Activity detail maps with start/end markers

### Social Features

- Community feed with posts and replies
- Thread-style conversations
- Likes, reposts, and comments
- Groups and clubs
- User profiles and activity sharing

### Authentication

- JWT-based authentication
- Secure password hashing (bcrypt)
- Token refresh mechanism
- Supabase integration for user management

```bash
cd frontend
flutter test
```

## Development

### Security Checks

Run this before commit/push to catch accidentally committed secrets in tracked files:

```bash
./scripts/check_secrets.sh
```

### Running Tests

**Frontend:**

```bash
cd frontend
flutter test
```

**Main Backend:**

```bash
cd main-backend
pytest
```

**Community Backend:**

```bash
cd community-backend
# See community-backend/doc/TEST_RESULTS.md
```

### Code Style

- **Flutter**: Follow [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- **Python**: Follow [PEP 8](https://pep8.org/) (use `black` formatter)

### Environment Variables

Each backend has its own `.env` file. See respective README files for configuration details.

## Contributing

1. Create a feature branch from `main`
2. Make your changes
3. Write/update tests
4. Submit a pull request

## 🔗 Links

- **Frontend**: [Flutter Documentation](https://flutter.dev/docs)
- **Main Backend**: [FastAPI Documentation](https://fastapi.tiangolo.com/)
- **Community Backend**: [Flask Documentation](https://flask.palletsprojects.com/)
- **Supabase**: [Supabase Documentation](https://supabase.com/docs)
