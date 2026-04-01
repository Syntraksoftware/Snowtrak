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

### Unified Entry Point

All services follow the same standardized entry point: **`python run.py`**

This approach:

- Uses configuration from `config.py` (settings, PORT, HOST, DEBUG)
- Loads environment variables from `.env` file
- Works with the shared Python virtual environment at `/backend/.venv`
- Provides consistent behavior across all services

### Start All Services (1 Terminal, 1 Command)

```bash
cd backend
python run.py
```

This launches all 4 services in parallel with graceful shutdown on Ctrl+C.

### Start Individual Service

```bash
cd backend
python run.py --service <service-name>
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

# Or with the shared venv explicitly:
../../.venv/bin/python run.py
```

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

All services use a shared Python environment located at `/backend/.venv`:

```bash
# View Python version
./.venv/bin/python --version

# View installed packages
./.venv/bin/pip list

# Install new dependency for all services
./.venv/bin/pip install <package>
```

### Creating the Environment (if needed)

```bash
cd /backend
python3.11 -m venv .venv
./.venv/bin/pip install -r requirements.txt
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
