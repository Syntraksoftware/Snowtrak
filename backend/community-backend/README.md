# Community Backend - FastAPI Microservice

A standalone FastAPI backend for the community feature (Reddit-like functionality).

## Overview

This is a separate FastAPI-based microservice handling all community operations:
- Subthreads (topic categories)
- Posts (user content)
- Comments (with nesting support)

## Features

- 🔥 FastAPI REST API
- 🗄️ Supabase integration
- 🔐 JWT authentication
- 📝 Complete CRUD operations
- 🎯 Self-contained and deployable

## Project Structure

```
backend/community-backend/
├── main.py                 # FastAPI application entry point
├── run.py                  # Standardized runtime entry point
├── config.py              # Configuration settings
├── requirements.txt       # Python dependencies
├── .env.example          # Environment variables template
├── models/               # Data models
│   └── community.py     # Subthread, Post, Comment models
├── routes/              # API endpoints
│   ├── subthreads.py   # Subthread routes
│   ├── posts.py        # Post routes
│   └── comments.py     # Comment routes
├── services/           # Business logic
│   └── supabase_client.py  # Supabase operations
└── middleware/        # Authentication & helpers
    └── auth.py       # JWT verification

```

## Setup

### 1. Install Dependencies

```bash
cd backend/community-backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### 2. Configure Environment

Copy `.env.example` to `.env` and fill in your credentials:

```bash
cp .env.example .env
```

Edit `.env`:
```
SUPABASE_URL=your-supabase-url
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
JWT_SECRET=your-jwt-secret
FASTAPI_ENV=development
PORT=5001
```

### 3. Create Supabase Tables

Run the SQL from `../backend/app/community/SUPABASE_SCHEMA.md` in your Supabase SQL Editor.

### 4. Run the Server

```bash
# Check if Python 3.12 is available
python3.12 --version

# If yes, use it:
python3.12 -m venv venv
source venv/bin/activate
pip install --upgrade pip setuptools wheel
pip install -r requirements.txt
python run.py
```

The server will start on `http://localhost:5001`

## API Endpoints

### Subthreads

- `GET /api/subthreads` - List all subthreads
- `POST /api/subthreads` - Create new subthread (authenticated)
- `GET /api/subthreads/<id>` - Get subthread details
- `GET /api/subthreads/<id>/posts` - List posts in subthread

### Posts

- `POST /api/posts` - Create new post (authenticated)
- `GET /api/posts/<id>` - Get post details
- `PUT /api/posts/<id>` - Update post (authenticated, owner only)
- `DELETE /api/posts/<id>` - Delete post (authenticated, owner only)

### Comments

- `POST /api/comments` - Create new comment (authenticated)
- `GET /api/posts/<post_id>/comments` - List all comments for post
- `PUT /api/comments/<id>` - Update comment (authenticated, owner only)
- `DELETE /api/comments/<id>` - Delete comment (authenticated, owner only)

## Authentication

The API uses JWT tokens for authentication. Include the token in the Authorization header:

```
Authorization: Bearer <your-jwt-token>
```

Get a token from the main FastAPI backend:
```bash
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password"}'
```

## Example Requests

### Create a Subthread

```bash
curl -X POST http://localhost:5001/api/subthreads \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "technology",
    "description": "Tech discussions"
  }'
```

### Create a Post

```bash
curl -X POST http://localhost:5001/api/posts \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "subthread_id": "uuid-here",
    "title": "My First Post",
    "content": "Hello everyone!"
  }'
```

### Create a Comment

```bash
curl -X POST http://localhost:5001/api/comments \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "post_id": "uuid-here",
    "content": "Great post!"
  }'
```

## Development

### Running in Development Mode

```bash
export FASTAPI_ENV=development
python run.py
```

This enables:
- Auto-reload on code changes
- Debug mode
- Detailed error messages

### Testing

**Setup for testing:**

```bash
# Install runtime + test dependencies
cd backend/community-backend
source venv/bin/activate   # if using a venv
pip install -r requirements-test.txt
```

**Run tests:**

```bash
cd backend/community-backend
source venv/bin/activate   # if using a venv
python -m pytest tests/test_community_api.py -q
```

**Important:** Run pytest from this directory so `import main` resolves correctly.

**Manual smoke checks:**

```bash
# Test health check
curl http://localhost:5001/health

# Test subthreads list
curl http://localhost:5001/api/v1/subthreads
```

## Deployment

### Docker (Recommended)

```bash
docker build -t community-backend .
docker run -p 5001:5001 --env-file .env community-backend
```

### Traditional Deployment

Use gunicorn for production:

```bash
pip install gunicorn
gunicorn -w 4 -b 0.0.0.0:5001 app:app
```

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `SUPABASE_URL` | Supabase project URL | Yes |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase service role key | Yes |
| `JWT_SECRET` | Secret for JWT verification | Yes |
| `FASTAPI_ENV` | Environment (development/production) | No |
| `PORT` | Server port | No (default: 5001) |

## CORS

CORS is configured to allow requests from:
- `http://localhost:3000` (Flutter web dev)
- `http://localhost:8080` (FastAPI backend)

Update `main.py` to add more origins if needed.

## License

Same as parent application.
