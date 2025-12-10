# Syntrak Auth API

Minimal FastAPI backend for authentication with in-memory storage. Perfect for development and prototyping.

## 🚀 Quick Start

### 1. Setup Environment

```bash
cd backend
python -m venv venv
source venv/bin/activate  # macOS/Linux
pip install -r requirements.txt
```

### 2. Run Server

```bash
python run.py
```

Server starts at `http://localhost:8080`

API docs available at `http://localhost:8080/docs`

## 📡 API Endpoints

### Authentication

- `POST /api/v1/auth/register` - Register new user
- `POST /api/v1/auth/login` - Login (returns access + refresh tokens)
- `POST /api/v1/auth/refresh` - Refresh access token

### Users

- `GET /api/v1/users/me` - Get current user profile
- `PUT /api/v1/users/me` - Update profile

## 🔑 Example Usage

### Register
```bash
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "first_name": "John",
    "last_name": "Doe"
  }'
```

### Login
```bash
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

Returns:
```json
{
  "access_token": "eyJ...",
  "refresh_token": "eyJ...",
  "token_type": "bearer",
  "expires_at": "2024-01-15T12:00:00",
  "user": {
    "id": "uuid",
    "email": "test@example.com",
    "first_name": "John",
    "last_name": "Doe"
  }
}
```

### Access Protected Route
```bash
curl http://localhost:8080/api/v1/users/me \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

## ⚙️ Configuration

Create `.env` file (optional):

```bash
cp .env.example .env
```

Default settings work out of the box. Customize if needed:

- `SECRET_KEY` - JWT signing key (change in production!)
- `ACCESS_TOKEN_EXPIRE_MINUTES` - Token lifetime (default: 60)
- `ALLOWED_ORIGINS` - CORS origins (default: localhost:3000)

## 💾 Storage

**In-Memory Storage**: All data is stored in memory and resets on server restart. Perfect for development, not for production.

To persist data, you'll need to add a database (PostgreSQL, MySQL, etc.).

## 🔒 Security Notes

- Change `SECRET_KEY` in production (use `openssl rand -hex 32`)
- Passwords hashed with bcrypt (12 rounds)
- JWT tokens with HS256 algorithm
- CORS configured for Flutter frontend

## 📁 Project Structure

```
backend/
├── app/
│   ├── api/
│   │   ├── v1/
│   │   │   ├── auth.py       # Auth endpoints
│   │   │   └── users.py      # User endpoints
│   │   └── dependencies.py   # Auth middleware
│   ├── core/
│   │   ├── config.py         # Settings
│   │   ├── jwt.py            # JWT utilities
│   │   ├── security.py       # Password hashing
│   │   └── storage.py        # In-memory storage
│   ├── schemas/              # Pydantic models
│   └── main.py               # FastAPI app
├── requirements.txt
└── run.py                    # Dev server
```

## 🛠️ Development

**Auto-reload enabled**: Server automatically restarts on code changes.

**API Documentation**: Visit `/docs` for interactive Swagger UI.

**Health Check**: `GET /health` returns server status.
