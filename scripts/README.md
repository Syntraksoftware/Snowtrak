# Syntrak Notification Testing Scripts

## Secret Safety Check

Before pushing changes, run:

```bash
./scripts/check_secrets.sh
```

This scans tracked files for common leaked-key patterns (Google API keys, JWT-like tokens, and high-risk env assignments).

Test in-app notifications by triggering them from the terminal.

## Prerequisites

1. **Backend Running**: Start the main backend server
   ```bash
   cd main-backend
   source venv/bin/activate
   python run.py
   ```

2. **Flutter App Running**: Start the Flutter app (iOS Simulator or device)
   ```bash
   cd frontend
   flutter run
   ```

## Quick Test Commands

Send individual test notifications:

```bash
# Kudos notification
./scripts/send_notification.sh test-kudos

# Comment notification
./scripts/send_notification.sh test-comment

# New follower notification
./scripts/send_notification.sh test-follow

# Powder day alert
./scripts/send_notification.sh test-powder

# Achievement unlocked
./scripts/send_notification.sh test-achievement

# Weather alert
./scripts/send_notification.sh test-weather
```

## Custom Notifications

Send a custom notification with your own content:

```bash
./scripts/send_notification.sh <type> "<title>" "<message>" [sender_name]
```

**Notification Types:**
- `kudos` - Someone liked your activity
- `comment` - New comment on your activity
- `follow` - Someone followed you
- `friendActivity` - Friend completed an activity
- `challenge` - Challenge update
- `group` - Group activity update
- `weather` - Weather alert
- `powderDay` - Fresh snow notification
- `achievement` - Achievement unlocked
- `system` - System notification

**Examples:**

```bash
# Custom kudos
./scripts/send_notification.sh kudos "❤️ New Kudos!" "John loved your ski run!" "John Smith"

# Custom achievement
./scripts/send_notification.sh achievement "🏆 Badge Earned!" "You completed 100km this week!"

# Custom weather alert
./scripts/send_notification.sh weather "⚠️ Storm Warning" "Heavy snowfall expected tomorrow"
```

## Demo Mode

Run a full demonstration with multiple notifications:

```bash
./scripts/notification_demo.sh
```

This will send 6 different notification types with 3-second delays between each.

## Direct API Calls (curl)

You can also use curl directly:

```bash
# Generic notification
curl -X POST http://127.0.0.1:8080/api/v1/notifications/test \
  -H "Content-Type: application/json" \
  -d '{
    "type": "kudos",
    "title": "Test Title",
    "message": "Test message content",
    "sender_name": "Test User"
  }'

# Quick endpoints (no JSON body needed)
curl -X POST http://127.0.0.1:8080/api/v1/notifications/test/kudos
curl -X POST http://127.0.0.1:8080/api/v1/notifications/test/comment
curl -X POST http://127.0.0.1:8080/api/v1/notifications/test/follow
curl -X POST http://127.0.0.1:8080/api/v1/notifications/test/powder-day
curl -X POST http://127.0.0.1:8080/api/v1/notifications/test/achievement
curl -X POST http://127.0.0.1:8080/api/v1/notifications/test/weather

# With custom parameters
curl -X POST "http://127.0.0.1:8080/api/v1/notifications/test/kudos?sender=Emma&activity=Powder%20Run"
curl -X POST "http://127.0.0.1:8080/api/v1/notifications/test/powder-day?resort=Vail&inches=24"
```

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/notifications/test` | POST | Send custom notification |
| `/api/v1/notifications/test/kudos` | POST | Quick kudos notification |
| `/api/v1/notifications/test/comment` | POST | Quick comment notification |
| `/api/v1/notifications/test/follow` | POST | Quick follow notification |
| `/api/v1/notifications/test/powder-day` | POST | Quick powder day alert |
| `/api/v1/notifications/test/achievement` | POST | Quick achievement notification |
| `/api/v1/notifications/test/weather` | POST | Quick weather alert |
| `/api/v1/notifications/pending` | GET | Get pending notifications (clears queue) |
| `/api/v1/notifications/history` | GET | Get notification history |
| `/api/v1/notifications/clear` | DELETE | Clear all notifications |

## How It Works

1. **Terminal Script** → Sends HTTP request to backend
2. **Backend** → Stores notification in pending queue
3. **Flutter App** → Polls `/notifications/pending` every 2 seconds
4. **App Receives** → Shows banner notification + adds to notification list
5. **User Taps Bell** → Views all notifications in the Notifications Screen

## Troubleshooting

**Notifications not appearing?**
- Ensure backend is running on port 8080
- Ensure Flutter app is running and connected to the same network
- Check backend logs for "🔔 Test notification triggered" messages
- For physical devices, update the base URL in `notification_provider.dart` to your Mac's IP address

**Connection refused?**
- Backend might not be running: `cd main-backend && python run.py`
- Check if port 8080 is available: `lsof -i :8080`
