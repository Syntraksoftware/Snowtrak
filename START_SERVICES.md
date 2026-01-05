# Starting Syntrak Services

## Quick Start Commands

### 1. Start Main Backend (FastAPI - Port 8080)
```bash
cd main-backend
source venv/bin/activate
python run.py
```

### 2. Start Community Backend (Flask - Port 5001)
```bash
cd community-backend
source venv/bin/activate
python app.py
```

### 3. Run Flutter App on iOS Simulator
```bash
cd frontend
flutter run -d FFBE6643-CF4D-4B4B-A8D8-E70AC135B009
```

## All-in-One Startup Script

```bash
# Terminal 1 - Main Backend
cd main-backend && source venv/bin/activate && python run.py

# Terminal 2 - Community Backend  
cd community-backend && source venv/bin/activate && python app.py

# Terminal 3 - Flutter App
cd frontend && flutter run -d FFBE6643-CF4D-4B4B-A8D8-E70AC135B009
```

## Verify Services Are Running

```bash
# Check main backend
curl http://127.0.0.1:8080/health

# Check community backend
curl http://127.0.0.1:5001/

# Check if ports are in use
lsof -i:8080,5001
```

## Troubleshooting Connection Issues

### If Flutter app can't connect to backend:

1. **Verify backend is running:**
   ```bash
   curl http://127.0.0.1:8080/health
   ```

2. **Check API service configuration:**
   - File: `frontend/lib/services/api_service.dart`
   - Should use: `http://127.0.0.1:8080/api/v1`

3. **For iOS Simulator:**
   - Use `127.0.0.1` (not `localhost`)
   - Simulator shares host network, so `127.0.0.1` works

4. **For Physical Device:**
   - Use your Mac's IP address (e.g., `http://192.168.1.100:8080`)
   - Find IP: `ifconfig | grep "inet " | grep -v 127.0.0.1`

5. **Restart Flutter with clean build:**
   ```bash
   cd frontend
   flutter clean
   flutter pub get
   flutter run -d <device-id>
   ```

## Stop All Services

```bash
# Stop main backend
lsof -ti:8080 | xargs kill

# Stop community backend
lsof -ti:5001 | xargs kill

# Stop Flutter
pkill -f "flutter run"
```

## Current Configuration

- **Main Backend:** http://127.0.0.1:8080
- **Community Backend:** http://127.0.0.1:5001
- **API Base URL:** http://127.0.0.1:8080/api/v1
- **Simulator Device:** iPhone 16 (FFBE6643-CF4D-4B4B-A8D8-E70AC135B009)

