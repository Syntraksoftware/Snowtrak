# Scripts

Collection of shell scripts and utilities for development, testing, and deployment of the Syntrak application.

## 1. Purpose and scope

Developer utility scripts provide quick access to common testing tasks and repository hygiene checks. Scripts simplify notification integration testing, secret scanning, and demonstration workflows.

**Available scripts:**
- `check_secrets.sh` — Scan tracked files for accidentally committed credentials or tokens
- `send_notification.sh` — Send test notifications to the Flutter app running on device/simulator
- `notification_demo.sh` — Automated demonstration of all notification types

## 2. Architecture overview

### High-level design

Scripts operate independently and communicate with backend services (main-backend for notifications) via HTTP or via direct shell/grep tooling (for secrets scanning). They are meant for local development only; not intended for production deployments.

```
Developer → script invocation (bash)
  ↓
check_secrets.sh (local file scanning)
  OR
send_notification.sh → HTTP POST → backend/main-backend (:8080)
  ↓
Flutter App (polls for notifications)
```

### Key design patterns

- **Shell scripts with error handling**: Bash scripts exit on first error (set -e) for reliability
- **HTTP POST for notifications**: Scripts use curl to send test notifications to backend
- **Grep-based pattern matching**: Secrets scanner uses regex to identify high-risk patterns
- **Idempotent operations**: Scripts can be run multiple times safely

### Data contracts/models

**Notification payload (sent via curl/script):**
- `type`: Notification category (kudos, comment, follow, powder-day, achievement, weather, etc.)
- `title`: Notification header text
- `message`: Notification body text
- `sender_name`: Optional name of the user/sender triggering the notification

### External integrations

- **main-backend** (:8080): Provides `/api/v1/notifications/test/*` endpoints and backends notification queue/polling
- **Flutter App**: Polls `/api/v1/notifications/pending` for new notifications every 2 seconds

## 3. Code structure and key components

### File map

```
scripts/
├── README.md                  # This file
├── check_secrets.sh          # Secret pattern scanner
├── send_notification.sh       # Test notification sender
└── notification_demo.sh       # Multi-notification demonstration
```

### Entry points

- **check_secrets.sh**: Invoked manually before git push; scans staged/tracked files for patterns
- **send_notification.sh**: Invoked manually to test notification flow; accepts type, title, message parameters
- **notification_demo.sh**: Invoked manually to run automated demo; sends 6 notification types with delays

### Critical logic

1. **Secrets scanning** (check_secrets.sh):
   - Grep patterns for API keys, JWT tokens, service role keys, high-risk env assignments
   - Scans tracked files only (excludes untracked, .gitignored)
   - Returns exit code 1 if patterns found; 0 if clean

2. **Notification sending** (send_notification.sh):
   - Parses arguments: type, title, message, sender_name
   - Constructs curl POST request to backend test endpoint
   - Supports quick shortcuts (test-kudos, test-comment, test-follow) for common types
   - Logs success/failure to stdout

3. **Demo workflow** (notification_demo.sh):
   - Sends 6 different notification types in sequence
   - Pauses 3 seconds between notifications for visual inspection
   - Helpful for QA and feature demonstrations

### Configuration

Hardcoded defaults (configurable via command-line arguments):
- Backend base URL: `http://127.0.0.1:8080` (update for devices/remote testing)
- Notification types: kudos, comment, follow, powderDay, achievement, weather, system
- Demo delay: 3 seconds between notifications

## 4. Development and maintenance guidelines

### Setup instructions

Scripts are located in `scripts/` directory at project root. Make executable:
```bash
chmod +x scripts/check_secrets.sh
chmod +x scripts/send_notification.sh
chmod +x scripts/notification_demo.sh
```

### Testing strategy

- Test check_secrets.sh: Create a file with a valid API key, run check_secrets.sh, verify it catches the pattern
- Test send_notification.sh: Run with main-backend on port 8080, Flutter app running, observe notification in app
- Test notification_demo.sh: Run full demo and watch all notification types appear in sequence

### Code standards

- All scripts use `#!/bin/bash` shebang (compatible with macOS and Linux)
- Error handling: `set -e` to exit on first error
- Logging: Scripts output to stdout with emoji prefixes (🔍, 🔔, ⚡) for clarity
- Color support: Optional ANSI color codes for terminal output

### Common pitfalls

- **Incorrect backend URL**: If testing on physical device, update `http://127.0.0.1:8080` to Mac's IP address in scripts
- **Port conflicts**: Ensure port 8080 is available; check with `lsof -i :8080`
- **Flutter app not polling**: Verify app is running and has internet connectivity to backend
- **Secrets scanner false positives**: Patterns may catch legitimate strings (method names, UUIDs); review matches manually

### Logging and monitoring

- Scripts output diagnostic information to stdout
- Backend logs notification requests (check with `python run.py` console output)
- Flutter app logs show polling intervals and received notifications

## 5. Deployment and operations

### Build and deployment

Scripts are not deployed; they are development utilities. Distribute via git repository.

### Runtime requirements

- Bash shell (macOS or Linux)
- `curl` utility (for HTTP requests)
- `grep` utility (for pattern scanning)
- main-backend running on port 8080 (for notification testing)
- Flutter app running on simulator or device (for notification reception)

### Health checks

- **Secrets scanner**: Run `./scripts/check_secrets.sh` before each commit to prevent leaks
- **Notification endpoint**: Test with `curl -X POST http://127.0.0.1:8080/api/v1/notifications/test/kudos`
- **App polling**: Monitor app's notification badge for new message indicators

### Backward compatibility

Scripts should remain stable; changes to notification type enums require coordination with backend and app.

## 6. Examples and usage

### Scan for secrets before committing

```bash
./scripts/check_secrets.sh
```

Exit code 0 = no secrets found; proceed with commit. Exit code 1 = patterns detected; review before pushing.

### Send quick test notifications

```bash
# Pre-defined notification types (fastest)
./scripts/send_notification.sh test-kudos
./scripts/send_notification.sh test-comment
./scripts/send_notification.sh test-follow
./scripts/send_notification.sh test-powder
./scripts/send_notification.sh test-achievement
./scripts/send_notification.sh test-weather
```

### Send custom notifications

```bash
# Generic custom notification
./scripts/send_notification.sh kudos "❤️ New Kudos!" "John loved your ski run!" "John Smith"

# Achievement notification
./scripts/send_notification.sh achievement "🏆 Badge Earned!" "You completed 100km this week!"

# Weather alert
./scripts/send_notification.sh weather "⚠️ Storm Warning" "Heavy snowfall expected tomorrow"
```

### Run automated demo

```bash
./scripts/notification_demo.sh
# Sends 6 notification types with 3-second delays between each
```

### Direct curl testing

```bash
# Quick notification via backend endpoint
curl -X POST http://127.0.0.1:8080/api/v1/notifications/test/kudos

# Custom notification with parameters
curl -X POST "http://127.0.0.1:8080/api/v1/notifications/test/kudos?sender=Emma&activity=Powder%20Run"

# Complex JSON payload
curl -X POST http://127.0.0.1:8080/api/v1/notifications/test \
  -H "Content-Type: application/json" \
  -d '{
    "type": "kudos",
    "title": "Test Title",
    "message": "Test message content",
    "sender_name": "Test User"
  }'
```

## 7. Troubleshooting and FAQs

### Common errors

**Connection refused (127.0.0.1:8080)**:
- main-backend not running: `cd backend/main-backend && source venv/bin/activate && python run.py`
- Wrong URL for physical device: Update script to use Mac's IP address (e.g., `http://192.168.1.X:8080`)
- Port 8080 in use: Check with `lsof -i :8080` and kill conflicting process

**Notifications not appearing in app**:
- Verify app is running and connected to backend: Check app logs
- Verify app is polling notifications: Monitor network tab in Xcode (iOS) or Android Studio
- Verify notification payload structure: Check backend logs for error messages

**Secrets scanner finds false positives**:
- Review grep patterns in check_secrets.sh
- Some UUIDs, method names, or configuration values may match patterns legitimately
- Consult team before suppressing checks

### Debugging tips

- Add verbose output to scripts: `set -x` at top of script to trace execution
- Test curl commands in isolation: Verify backend is responding before testing via script
- Monitor backend logs: `tail -f` backend output to see incoming notification requests
- Use Postman or API client: Test notification endpoints outside of scripts for faster iteration

### Performance tuning

- Notification demo is intentionally slow (3-second delays) for visual inspection; adjust with `-d` argument if needed
- Secrets scanner performance depends on repository size; should complete in <1 second for typical projects
- Notification polling interval (Flutter app): Currently 2 seconds; adjust in `notification_provider.dart` if lower latency needed

## 8. Change log and versioning

### Recent updates

- **2024-01**: Initial scripts: check_secrets.sh, send_notification.sh
- **2024-02**: Added notification_demo.sh for automated demonstration
- **2024-03**: Enhanced check_secrets.sh with additional API key patterns

### Version compatibility

- Scripts expect main-backend v1+ with `/api/v1/notifications/test/*` endpoints
- Scripts invoke shell builtins and curl; compatible with macOS and Linux bash
- Flutter app must support polling `/api/v1/notifications/pending`
