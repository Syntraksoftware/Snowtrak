# Running Map Backend Locally (Without Docker)

## Prerequisites

- Python 3.11+
- pip (Python package manager)
- virtualenv or venv (recommended)

## Setup Steps

### 1. Navigate to map-backend directory

```bash
cd map-backend
```

### 2. Create a virtual environment

```bash
# Create virtual environment
python3 -m venv venv

# Activate virtual environment
# On macOS/Linux:
source venv/bin/activate

# On Windows:
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process // Bypass Power Shell security restriction
venv\Scripts\Activate.ps1
```

### 3. Install dependencies

```bash
pip install -r requirements.txt
```

### 4. Create `.env` file

```bash
cp .env.example .env
```

### 5. Configure `.env` with your credentials

Edit `map-backend/.env`:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
JWT_SECRET=your_jwt_secret
GOOGLE_MAPS_API_KEY=your_google_maps_api_key
FASTAPI_ENV=development
HOST=127.0.0.1
PORT=5200
```

### 6. Run the server

```bash
# Option 1: Using python main.py
python main.py

# Option 2: Using uvicorn (more control)
uvicorn main:app --reload --host 127.0.0.1 --port 5200

# Option 3: Using the run script
bash run.sh
```

You should see:
```
INFO:     Uvicorn running on http://127.0.0.1:5200
INFO:     Application startup complete
```

### 7. Test the service

In a new terminal:

```bash
# Health check
curl http://localhost:5200/health

# Root endpoint
curl http://localhost:5200/

# Test elevation endpoint
curl "http://localhost:5200/api/elevation/point?lat=40.7128&lng=-74.0060"
```

## Common Issues & Solutions

### "ModuleNotFoundError: No module named 'fastapi'"

You haven't installed dependencies. Run:

```bash
pip install -r requirements.txt
```

### "command not found: python3"

Python is not installed or not in PATH. Install Python 3.11+ from https://www.python.org

### "SUPABASE_URL is not set"

Create `.env` file and fill in all required variables:

```bash
cp .env.example .env
# Edit .env with your values
```

### Windows: "Could not install packages due to an OSError: [WinError 2]"

This happens when installing packages globally instead of in the virtual environment.

**Fix:** Ensure virtual environment is activated before installing:

```cmd
# Command Prompt
venv\Scripts\activate.bat
pip install -r requirements.txt

# PowerShell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

Verify activation by checking for `(venv)` in your prompt:
```
(venv) D:\...\map-backend>
```

### Google Maps: "RefererNotAllowedMapError" or "This page can't load Google Maps correctly"

This happens when opening the dynamic map HTML via `file://` or when the API key is
restricted to specific HTTP referrers. The Google Maps JS API **requires an HTTP(S) origin**.

**Option A: Serve the HTML via a local web server**

```bash
curl -X POST "http://localhost:5200/api/maps/dynamic/html" \
  -H "Content-Type: application/json" \
  -d '{
    "center_lat": 37.7749,
    "center_lng": -122.4194,
    "zoom": 12,
    "width": 900,
    "height": 600
  }' > map.html

python3 -m http.server 8088
```

Open: `http://localhost:8088/map.html`

**Option B: Allow localhost in API key restrictions**

Google Cloud Console → APIs & Services → Credentials → your API key:
- Application restrictions: **HTTP referrers**
- Add: `http://localhost:*/*`

Also ensure **Maps JavaScript API** is enabled for the project.

### Port 5200 already in use

Either:
1. Kill the process using port 5200:
```bash
lsof -i :5200
kill -9 <PID>
```

2. Or change the port in `.env`:
```env
PORT=5201
```

### "This IP, site or mobile application is not authorized to use this API key"

Your Google Maps API key has restrictions blocking your server IP or backend requests.

**Quick fix (development):**
1. Go to [Google Cloud Console](https://console.cloud.google.com/) → APIs & Services → Credentials
2. Click your API key
3. Set **Application restrictions** to **None**
4. Ensure **Maps Elevation API**, **Maps JavaScript API**, and **Maps Static API** are enabled
5. Click **Save** and wait ~1 minute

**Production fix:**
1. Set **Application restrictions** to **IP addresses**
2. Add your server IP (check error message for IP) and `127.0.0.1`
3. Save and restart the backend

### Virtual environment not activating

Make sure you're using the correct command for your OS:

```bash
# macOS/Linux
source venv/bin/activate

# Windows (CMD)
venv\Scripts\activate.bat

# Windows (PowerShell)
venv\Scripts\Activate.ps1
```

## Development Commands

### Run with auto-reload (for development)

```bash
uvicorn main:app --reload --host 127.0.0.1 --port 5200
```

Changes to files will automatically reload the server.

### Run without auto-reload (for production-like testing)

```bash
uvicorn main:app --host 0.0.0.0 --port 5200
```

### View API documentation

Once the server is running, visit:

```
http://localhost:5200/docs
```

This opens the interactive Swagger UI where you can test endpoints directly.

### Alternative API docs (ReDoc)

```
http://localhost:5200/redoc
```

## Testing Endpoints

### Quick test with cURL

```bash
# Health check
curl http://localhost:5200/health

# Static map
curl -X POST http://localhost:5200/api/maps/static \
  -H "Content-Type: application/json" \
  -d '{
    "center_lat": 37.7749,
    "center_lng": -122.4194,
    "zoom": 12
  }'

# Elevation lookup
curl "http://localhost:5200/api/elevation/point?lat=40.7128&lng=-74.0060"
```

### Use the test script

From project root (not map-backend):

```bash
# Copy the test script from CURL_TESTS.md
# Save as test_map_backend.sh

chmod +x test_map_backend.sh
./test_map_backend.sh
```

## Deactivating Virtual Environment

When done, deactivate the virtual environment:

```bash
deactivate
```

## Running Multiple Backends Locally

If you want to run all backends locally:

### Terminal 1 - Map Backend

```bash
cd map-backend
source venv/bin/activate
python main.py
```

### Terminal 2 - Activity Backend

```bash
cd activity-backend
source venv/bin/activate
python main.py
```

### Terminal 3 - Community Backend

```bash
cd community-backend
source venv/bin/activate
python main.py
```

Each backend runs on different ports:
- Map Backend: `http://localhost:5200`
- Activity Backend: `http://localhost:5100`
- Community Backend: `http://localhost:5001`

## Troubleshooting

### Check Python version

```bash
python3 --version
# Should be 3.11 or higher
```

### Check installed packages

```bash
pip list
```

### Reinstall dependencies (clean install)

```bash
pip install --upgrade -r requirements.txt
```

### Clear pip cache

```bash
pip cache purge
pip install -r requirements.txt
```

### View detailed errors

If the server fails to start, check for detailed error messages:

```bash
python main.py 2>&1 | head -50
```

### Test imports manually

```bash
python3 -c "from fastapi import FastAPI; print('FastAPI OK')"
python3 -c "from config import get_config; print('Config OK')"
```

## File Structure

```
map-backend/
├── main.py                      # FastAPI app entry point
├── config.py                    # Configuration & env vars
├── requirements.txt             # Python dependencies
├── .env                         # Environment variables (create from .env.example)
├── .env.example                 # Environment template
├── run.sh                       # Run script
├── Dockerfile                   # Docker configuration
├── .dockerignore               # Docker ignore rules
├── .gitignore                  # Git ignore rules
├── README.md                   # Service documentation
├── CURL_TESTS.md              # API test commands
├── middleware/
│   ├── __init__.py
│   └── auth.py                # JWT authentication
├── routes/
│   ├── __init__.py
│   ├── static_maps.py         # Static map routes
│   └── elevation.py           # Elevation routes
├── schemas/
│   ├── static_maps.py         # Static map models
│   └── elevation.py           # Elevation models
└── services/
    ├── __init__.py
    ├── supabase_client.py     # Supabase initialization
    ├── static_map_client.py   # Google Maps Static API
    └── elevation_client.py    # Google Maps Elevation API
```

## Next Steps

1. ✅ Set up virtual environment
2. ✅ Install dependencies
3. ✅ Configure `.env`
4. ✅ Run the server
5. ✅ Test endpoints
6. ✅ View API docs at `/docs`
7. ✅ Check logs for errors

## Performance Tips

- Keep `--reload` off in production
- Use `--workers` flag for multiple worker processes
- Monitor memory usage with: `top` or `htop`
- Check logs for slow queries

## Additional Resources

- FastAPI docs: https://fastapi.tiangolo.com
- Uvicorn docs: https://www.uvicorn.org
- Google Maps API: https://developers.google.com/maps
- Supabase docs: https://supabase.com/docs

