"""
Admin Notification Testing API
Allows triggering test notifications from terminal/scripts for testing purposes.
"""

import uuid
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status

from app.api.dependencies import get_current_user
from app.core.storage import User
from app.core.supabase import supabase_client
from app.schemas.notifications import (
    DeviceTokenRegisterRequest,
    DeviceTokenResponse,
    DeviceTokenUnregisterRequest,
    NotificationPayload,
    NotificationResponse,
    NotificationType,
    SendNotificationRequest,
    TestNotificationRequest,
)
from app.services.notification_sender import NotificationConfigurationError, notification_sender

router = APIRouter(prefix="/notifications", tags=["notifications"])


_pending_notifications: list[dict] = []
_notification_history: list[dict] = []


@router.post(
    "/device-tokens",
    response_model=DeviceTokenResponse,
    status_code=status.HTTP_201_CREATED,
)
async def register_device_token(
    request: DeviceTokenRegisterRequest,
    current_user: User = Depends(get_current_user),
):
    """Register or refresh the current user's Firebase Cloud Messaging token."""
    row = supabase_client.upsert_device_token(
        user_id=current_user.id,
        token=request.token,
        platform=request.platform.value,
        device_id=request.device_id,
        app_version=request.app_version,
        locale=request.locale,
        timezone=request.timezone,
    )
    if row is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Device token storage is not configured",
        )

    return DeviceTokenResponse(**row)


@router.delete("/device-tokens", status_code=status.HTTP_204_NO_CONTENT)
async def unregister_device_token(
    request: DeviceTokenUnregisterRequest,
    current_user: User = Depends(get_current_user),
):
    """Deactivate the current user's Firebase Cloud Messaging token."""
    removed = supabase_client.deactivate_device_token(user_id=current_user.id, token=request.token)
    if not removed:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Device token storage is not configured",
        )
    return None


@router.post("/send")
async def send_notification(
    request: SendNotificationRequest,
    current_user: User = Depends(get_current_user),
):
    """
    Send a push notification to a user's active devices.

    This route is useful for authenticated self-tests. Event handlers should call
    notification_sender.send_to_user() directly for cross-user notifications.
    """
    if request.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot send notifications for another user",
        )

    try:
        result = notification_sender.send_to_user(
            request.user_id,
            NotificationPayload(
                title=request.title,
                body=request.body,
                data=request.data,
                image_url=request.image_url,
                badge=request.badge,
            ),
        )
    except NotificationConfigurationError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(exc),
        ) from exc

    return result


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


@router.get("/pending", response_model=list[NotificationResponse])
async def get_pending_notifications():
    """
    Get all pending notifications and clear the queue.
    The Flutter app polls this endpoint to receive notifications.
    """
    global _pending_notifications
    notifications = _pending_notifications.copy()
    _pending_notifications = []  # Clear after fetching
    return [NotificationResponse(**n) for n in notifications]


@router.get("/history", response_model=list[NotificationResponse])
async def get_notification_history(limit: int = 50):
    """Get notification history (most recent first)"""
    sorted_history = sorted(_notification_history, key=lambda x: x["created_at"], reverse=True)[
        :limit
    ]
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
    return await trigger_test_notification(
        TestNotificationRequest(
            type=NotificationType.kudos,
            title="❤️ New Kudos!",
            message=f"{sender} gave kudos to your {activity}",
            sender_name=sender,
        )
    )


@router.post("/test/comment")
async def test_comment(sender: str = "Mike Johnson", comment: str = "Amazing run! 🎿"):
    """Quick endpoint to test comment notification"""
    return await trigger_test_notification(
        TestNotificationRequest(
            type=NotificationType.comment,
            title="💬 New Comment",
            message=f'{sender}: "{comment}"',
            sender_name=sender,
        )
    )


@router.post("/test/follow")
async def test_follow(follower: str = "Alex Kim"):
    """Quick endpoint to test follow notification"""
    return await trigger_test_notification(
        TestNotificationRequest(
            type=NotificationType.follow,
            title="👤 New Follower",
            message=f"{follower} started following you",
            sender_name=follower,
        )
    )


@router.post("/test/powder-day")
async def test_powder_day(resort: str = "Whistler Blackcomb", inches: int = 12):
    """Quick endpoint to test powder day notification"""
    return await trigger_test_notification(
        TestNotificationRequest(
            type=NotificationType.powder_day,
            title="❄️ Powder Day Alert!",
            message=f"{inches} inches of fresh snow at {resort}!",
        )
    )


@router.post("/test/achievement")
async def test_achievement(name: str = "Speed Demon", description: str = "Reached 50 km/h"):
    """Quick endpoint to test achievement notification"""
    return await trigger_test_notification(
        TestNotificationRequest(
            type=NotificationType.achievement,
            title="🏆 Achievement Unlocked!",
            message=f'"{name}" - {description}',
        )
    )


@router.post("/test/weather")
async def test_weather(alert: str = "High winds expected at the summit"):
    """Quick endpoint to test weather notification"""
    return await trigger_test_notification(
        TestNotificationRequest(
            type=NotificationType.weather,
            title="⚠️ Weather Alert",
            message=alert,
        )
    )
