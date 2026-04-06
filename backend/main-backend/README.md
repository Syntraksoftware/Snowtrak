# Syntrak Auth API

FastAPI backend for authentication with Supabase integration. Supports persistent storage with automatic fallback to in-memory storage for development.

## 🚀 Quick Start

### 1. Setup Environment

```bash
# From repository root
python3.11 -m venv .venv
./.venv/bin/pip install -r backend/requirements.txt

cd backend/main-backend
../../.venv/bin/python -m pip install -r requirements.txt
```

### 2. Configure Supabase (Optional but Recommended)

1. **Create Supabase Project**: Go to [Supabase](https://supabase.com) and create a new project
2. **Run SQL Script**: Execute `docs/supabase_schema.sql` in Supabase SQL Editor
3. **Get Credentials**: Copy your Project URL and Service Role Key from Settings → API
4. **Configure Environment**: 
   ```bash
   cp .env.example .env
   # Edit .env and add your Supabase credentials
   ```

See [Supabase Setup Guide](docs/SUPABASE_SETUP.md) for detailed instructions.

### 3. Run Server

```bash
python run.py
```

Server starts at `http://localhost:8080`

**Expected output:**
- ✅ `💾 Using Supabase database (persistent storage)` - Supabase configured correctly
- ⚠️ `💾 Using in-memory storage` - Supabase not configured, using fallback

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

### Environment Variables

Create `.env` file:

```bash
cp .env.example .env
```

**Required for Supabase:**
- `SUPABASE_URL` - Your Supabase project URL (e.g., `https://xxxxx.supabase.co`)
- `SUPABASE_SERVICE_ROLE_KEY` - Service role key from Supabase Settings → API

**Optional Settings:**
- `SECRET_KEY` - JWT signing key (change in production! Use `openssl rand -hex 32`)
- `ACCESS_TOKEN_EXPIRE_MINUTES` - Token lifetime (default: 60)
- `REFRESH_TOKEN_EXPIRE_DAYS` - Refresh token lifetime (default: 7)
- `ALLOWED_ORIGINS` - CORS origins (comma-separated, default: localhost:3000)
- `BCRYPT_ROUNDS` - Password hashing rounds (default: 12)

## 💾 Storage

**Supabase (Recommended)**: Persistent PostgreSQL database with automatic backups and scaling.

**In-Memory Fallback**: If Supabase is not configured, the app automatically falls back to in-memory storage. Data resets on server restart.

**To use Supabase:**
1. Create a Supabase project
2. Run the SQL schema script (`docs/supabase_schema.sql`)
3. Add credentials to `.env`
4. Restart the server

See [Supabase Setup Guide](docs/SUPABASE_SETUP.md) for detailed instructions.

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
