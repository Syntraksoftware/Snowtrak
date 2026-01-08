# Syntrak

> A skiing-focused fitness tracking and social community app built with Flutter, FastAPI, and Flask.

Syntrak combines the activity tracking features of Strava with social community features similar to Reddit and Threads, specifically designed for skiing enthusiasts.

## 🎯 Overview

Syntrak is a comprehensive mobile application that enables users to:
- **Track Activities**: Record skiing activities with GPS tracking, route visualization, and detailed metrics
- **Social Community**: Engage in community-driven discussions, share activities, and connect with other skiers
- **Groups & Clubs**: Join skiing groups, participate in challenges, and build your skiing community
- **Profile & Analytics**: View detailed statistics, activity history, and progress over time

## 🏗️ Architecture

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

## 🚀 Quick Start

### Prerequisites

- **Flutter**: 3.0+ ([Install Flutter](https://flutter.dev/docs/get-started/install))
- **Python**: 3.11+ ([Install Python](https://www.python.org/downloads/))
- **Supabase Account**: ([Sign up](https://supabase.com)) - Optional but recommended
- **Google Maps API Key**: ([Get API Key](https://console.cloud.google.com/)) - For map features

### 1. Clone the Repository

```bash
git clone https://github.com/Syntraksoftware/syntrak-application.git
cd syntrak-app
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
python -m venv venv
source venv/bin/activate  # macOS/Linux
# or
venv\Scripts\activate     # Windows

pip install -r requirements.txt
```

**Configure Supabase** (optional):
```bash
cp .env.example .env
# Edit .env with your Supabase credentials
```

See [Main Backend README](main-backend/README.md) for detailed setup.

### 4. Community Backend Setup

```bash
cd community-backend
python -m venv venv
source venv/bin/activate  # macOS/Linux
# or
venv\Scripts\activate     # Windows

pip install -r requirements.txt
```

See [Community Backend README](community-backend/README.md) for detailed setup.

### 5. Run the Application

**Start Main Backend:**
```bash
cd main-backend
python run.py
# Server runs on http://localhost:8080
```

**Start Community Backend:**
```bash
cd community-backend
./run.sh
# or
python app.py
# Server runs on http://localhost:5000
```

**Run Frontend:**
```bash
cd frontend
flutter run
```

## 📁 Project Structure

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

## 📚 Documentation

### Frontend Documentation
- [Frontend README](frontend/README.md) - Setup and development guide
- [Map Services](frontend/doc/map.md) - Map implementation and GPS tracking
- [Architecture](frontend/doc/architecture_map_service.md) - Service architecture
- [UI/UX Guidelines](frontend/doc/ui_ux_prompt.md) - Design system
- [Testing Guide](frontend/doc/testing.md) - Testing best practices

### Backend Documentation
- [Main Backend README](main-backend/README.md) - Authentication API setup
- [Community Backend README](community-backend/README.md) - Community features

## 🔑 Key Features

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

## 🛠️ Development

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

## 🤝 Contributing

1. Create a feature branch from `main`
2. Make your changes
3. Write/update tests
4. Submit a pull request

## 📝 License

[Add your license here]

## 🔗 Links

- **Frontend**: [Flutter Documentation](https://flutter.dev/docs)
- **Main Backend**: [FastAPI Documentation](https://fastapi.tiangolo.com/)
- **Community Backend**: [Flask Documentation](https://flask.palletsprojects.com/)
- **Supabase**: [Supabase Documentation](https://supabase.com/docs)

## 📧 Support

For questions or issues, please open an issue on GitHub or contact the development team.

---

**Built with ❄️ for the skiing community**
