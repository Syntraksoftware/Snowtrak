"""
Admin Notification Testing API
Allows triggering test notifications from terminal/scripts for testing purposes.
"""
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from enum import Enum
import uuid

router = APIRouter(prefix="/notifications", tags=["notifications"])


class NotificationType(str, Enum):
    kudos = "kudos"
    comment = "comment"
    follow = "follow"
    friend_activity = "friendActivity"
    challenge = "challenge"
    group = "group"
    weather = "weather"
    powder_day = "powderDay"
    achievement = "achievement"
    system = "system"


class TestNotificationRequest(BaseModel):
    """Request body for triggering a test notification"""
    type: NotificationType = NotificationType.system
    title: str
    message: str
    sender_name: Optional[str] = None
    avatar_url: Optional[str] = None
    action_route: Optional[str] = None


class NotificationResponse(BaseModel):
    """Response model for a notification"""
    id: str
    type: str
    title: str
    message: str
    created_at: str
    is_read: bool = False
    sender_name: Optional[str] = None
    avatar_url: Optional[str] = None
    action_route: Optional[str] = None


# In-memory storage for test notifications (for demo purposes)
# In production, use a database or message queue
_pending_notifications: List[dict] = []
_notification_history: List[dict] = []


@router.post("/test", response_model=NotificationResponse)
async def trigger_test_notification(request: TestNotificationRequest):
    """
    Trigger a test notification that will appear in the app.
    
    **Usage from terminal:**
    ```bash
    curl -X POST http://localhost:8080/api/v1/notifications/test \\
      -H "Content-Type: application/json" \\
      -d '{"type": "kudos", "title": "New Kudos!", "message": "Sarah liked your activity"}'
    ```
    
    **Notification Types:**
    - kudos: Someone gave kudos
    - comment: New comment
    - follow: New follower
    - friendActivity: Friend completed activity
    - challenge: Challenge update
    - group: Group activity
    - weather: Weather alert
    - powderDay: Fresh snow alert
    - achievement: New achievement
    - system: System notification
    """
    notification = {
        "id": str(uuid.uuid4()),
        "type": request.type.value,
        "title": request.title,
        "message": request.message,
        "created_at": datetime.utcnow().isoformat() + "Z",
        "is_read": False,
        "sender_name": request.sender_name,
        "avatar_url": request.avatar_url,
        "action_route": request.action_route,
    }
    
    _pending_notifications.append(notification)
    _notification_history.append(notification)
    
    print(f"🔔 Test notification triggered: [{request.type.value}] {request.title}")
    
    return NotificationResponse(**notification)


@router.get("/pending", response_model=List[NotificationResponse])
async def get_pending_notifications():
    """
    Get all pending notifications and clear the queue.
    The Flutter app polls this endpoint to receive notifications.
    """
    global _pending_notifications
    notifications = _pending_notifications.copy()
    _pending_notifications = []  # Clear after fetching
    return [NotificationResponse(**n) for n in notifications]


@router.get("/history", response_model=List[NotificationResponse])
async def get_notification_history(limit: int = 50):
    """Get notification history (most recent first)"""
    sorted_history = sorted(
        _notification_history, 
        key=lambda x: x["created_at"], 
        reverse=True
    )[:limit]
    return [NotificationResponse(**n) for n in sorted_history]


@router.delete("/clear")
async def clear_notifications():
    """Clear all pending and historical notifications"""
    global _pending_notifications, _notification_history
    _pending_notifications = []
    _notification_history = []
    return {"message": "All notifications cleared"}


# Quick test endpoints for each notification type
@router.post("/test/kudos")
async def test_kudos(sender: str = "Sarah Chen", activity: str = "Morning Ski Run"):
    """Quick endpoint to test kudos notification"""
    return await trigger_test_notification(TestNotificationRequest(
        type=NotificationType.kudos,
        title="❤️ New Kudos!",
        message=f"{sender} gave kudos to your {activity}",
        sender_name=sender,
    ))


@router.post("/test/comment")
async def test_comment(sender: str = "Mike Johnson", comment: str = "Amazing run! 🎿"):
    """Quick endpoint to test comment notification"""
    return await trigger_test_notification(TestNotificationRequest(
        type=NotificationType.comment,
        title="💬 New Comment",
        message=f'{sender}: "{comment}"',
        sender_name=sender,
    ))


@router.post("/test/follow")
async def test_follow(follower: str = "Alex Kim"):
    """Quick endpoint to test follow notification"""
    return await trigger_test_notification(TestNotificationRequest(
        type=NotificationType.follow,
        title="👤 New Follower",
        message=f"{follower} started following you",
        sender_name=follower,
    ))


@router.post("/test/powder-day")
async def test_powder_day(resort: str = "Whistler Blackcomb", inches: int = 12):
    """Quick endpoint to test powder day notification"""
    return await trigger_test_notification(TestNotificationRequest(
        type=NotificationType.powder_day,
        title="❄️ Powder Day Alert!",
        message=f"{inches} inches of fresh snow at {resort}!",
    ))


@router.post("/test/achievement")
async def test_achievement(name: str = "Speed Demon", description: str = "Reached 50 km/h"):
    """Quick endpoint to test achievement notification"""
    return await trigger_test_notification(TestNotificationRequest(
        type=NotificationType.achievement,
        title="🏆 Achievement Unlocked!",
        message=f'"{name}" - {description}',
    ))


@router.post("/test/weather")
async def test_weather(alert: str = "High winds expected at the summit"):
    """Quick endpoint to test weather notification"""
    return await trigger_test_notification(TestNotificationRequest(
        type=NotificationType.weather,
        title="⚠️ Weather Alert",
        message=alert,
    ))
