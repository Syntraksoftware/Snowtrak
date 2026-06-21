"""Notification request/response schemas."""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import StrEnum

from pydantic import BaseModel, Field


class NotificationType(StrEnum):
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


class DevicePlatform(StrEnum):
    ios = "ios"
    android = "android"
    web = "web"


class DeviceTokenRegisterRequest(BaseModel):
    """Request body for registering an FCM device token."""

    token: str = Field(min_length=20, max_length=4096)
    platform: DevicePlatform
    device_id: str | None = Field(default=None, max_length=255)
    app_version: str | None = Field(default=None, max_length=64)
    locale: str | None = Field(default=None, max_length=32)
    timezone: str | None = Field(default=None, max_length=64)


class DeviceTokenUnregisterRequest(BaseModel):
    """Request body for unregistering an FCM device token."""

    token: str = Field(min_length=20, max_length=4096)


class DeviceTokenResponse(BaseModel):
    """Response model for device token registration."""

    user_id: str
    token: str
    platform: str
    device_id: str | None = None
    app_version: str | None = None
    locale: str | None = None
    timezone: str | None = None
    is_active: bool = True


class SendNotificationRequest(BaseModel):
    """Authenticated self-test request body for sending a push notification."""

    user_id: str
    title: str = Field(min_length=1, max_length=120)
    body: str = Field(min_length=1, max_length=240)
    data: dict[str, str] = Field(default_factory=dict)
    image_url: str | None = None
    badge: int | None = Field(default=None, ge=0)


class TestNotificationRequest(BaseModel):
    """Request body for triggering a local test notification."""

    type: NotificationType = NotificationType.system
    title: str
    message: str
    sender_name: str | None = None
    avatar_url: str | None = None
    action_route: str | None = None


class NotificationResponse(BaseModel):
    """Response model for a local test notification."""

    id: str
    type: str
    title: str
    message: str
    created_at: str
    is_read: bool = False
    sender_name: str | None = None
    avatar_url: str | None = None
    action_route: str | None = None


@dataclass
class NotificationPayload:
    """Push notification payload for a user."""

    title: str
    body: str
    data: dict[str, str] = field(default_factory=dict)
    image_url: str | None = None
    sound: str = "default"
    badge: int | None = None


@dataclass
class NotificationSendResult:
    """Result of sending a notification to active devices."""

    requested: int
    successful: int
    failed: int
    deactivated_tokens: list[str] = field(default_factory=list)
    errors: list[str] = field(default_factory=list)
