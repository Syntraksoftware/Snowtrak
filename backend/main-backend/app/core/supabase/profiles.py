"""Profile database operations."""

from __future__ import annotations

import logging
from datetime import datetime
from typing import Any

from .base import SupabaseBase

logger = logging.getLogger(__name__)


class ProfileOperations(SupabaseBase):
    """
    Profile table operations.

    Handles CRUD operations for the profiles table (Create, Read, Update, Delete):
    - id (uuid, primary key, foreign key to auth.users)
    - full_name (text, nullable)
    - username (text, unique, nullable)
    - bio (text, nullable)
    - avatar_url (text, nullable)
    - push_token (text, nullable): push notification token for backend to send notifications to the user
    - ski_level (text, nullable)
    - home (text, nullable) - nationality/home location
    - created_at (timestamptz, default now())
    - updated_at (timestamptz, default now(), updated via trigger)

    The id serves as both primary key and foreign key reference to auth.users.
    The one-to-one relationship ensures each authenticated user has exactly one profile.
    """

    def get_profile_by_id(self, user_id: str) -> dict[str, Any] | None:
        """
        Fetch profile by user ID.

        Arguments:
        - user_id: str, the id of the user to get the profile from the backend database

        Expected Return:
        - Optional[Dict[str, Any]]: the profile data for the user, or None if not found

        - e.g. [{'id': '123', 'full_name': 'John Doe', 'username': 'johndoe', 'bio': 'I am a software engineer', 'avatar_url': 'https://example.com/avatar.jpg', 'push_token': '1234567890', 'ski_level': 'beginner', 'home': 'New York', 'created_at': '2021-01-01 12:00:00', 'updated_at': '2021-01-01 12:00:00'}]
        """

        if not self.is_configured():
            # check if conenction is valid with a warning
            logger.warning("Supabase not configured; skipping get_profile_by_id.")
            return None

        client = self._client

        # `client` = Supabase Python SDK client instance, used for interacting with the Supabase database.
        # `client` None = the connection/configuration to Supabase hasn't been set up or is invalid.
        #  Supabase Python SDK (supabase-py) serves as the central entry point for interacting with project's database, authentication, and storage.

        if client is None:
            # Cannot make any database calls if there is no client.
            return None

        try:
            # `resp` = response from the database query
            resp = client.table("profiles").select("*").eq("id", user_id).limit(1).execute()
            # `data` = data returned from the database query
            data = getattr(resp, "data", None)

            if isinstance(data, list) and data:
                # `data[0]` = the first item in the list of data returned from the database query
                return data[0]
            # if the data is not a list or the list is empty, return None
            return None
        except Exception as exc:
            # if an error occurs, log the error and return None
            logger.exception(f"Failed to get profile for user {user_id}: {exc}")
            return None

    def create_profile(
        self,
        user_id: str,
        *,
        full_name: str | None = None,
        username: str | None = None,
        bio: str | None = None,
        avatar_url: str | None = None,
        push_token: str | None = None,
        ski_level: str | None = None,
        home: str | None = None,
    ) -> dict[str, Any] | None:
        """
        Create a new profile for a user.

        Returns the created profile dict on success, or None on failure.


        Arguments:
        - user_id: str, the id of the user to create the profile for
        - full_name: Optional[str], the full name of the user
        - username: Optional[str], the username of the user
        - bio: Optional[str], the bio of the user
        - avatar_url: Optional[str], the avatar url of the user
        - push_token: Optional[str], the push token of the user
        - ski_level: Optional[str], the ski level of the user
        - home: Optional[str], the home of the user

        Expected Return:
        - Optional[Dict[str, Any]]: the profile data for the user, or None if not found
        - e.g. [{'id': '123', 'full_name': 'John Doe', 'username': 'johndoe', 'bio': 'I am a software engineer', 'avatar_url': 'https://example.com/avatar.jpg', 'push_token': '1234567890', 'ski_level': 'beginner', 'home': 'New York', 'created_at': '2021-01-01 12:00:00', 'updated_at': '2021-01-01 12:00:00'}]
        """
        if not self.is_configured():
            logger.warning("Supabase not configured; skipping create_profile.")
            return None

        client = self._client
        if client is None:
            return None

        try:
            # payload = the data to be inserted into the database
            payload: dict[str, Any] = {
                "id": user_id,
            }
            if full_name is not None:
                payload["full_name"] = full_name
            if username is not None:
                payload["username"] = username
            if bio is not None:
                payload["bio"] = bio
            if avatar_url is not None:
                payload["avatar_url"] = avatar_url
            if push_token is not None:
                payload["push_token"] = push_token
            if ski_level is not None:
                payload["ski_level"] = ski_level
            if home is not None:
                payload["home"] = home

            resp = client.table("profiles").insert(payload).execute()
            data = getattr(resp, "data", None)
            if isinstance(data, list) and data:
                logger.info(f"Created profile for user {user_id}")
                return data[0]
            if isinstance(data, dict):
                return data
            logger.error("Supabase insert returned no data: %s", data)
            return None
        except Exception as exc:
            logger.exception(f"Failed to create profile for user {user_id}: {exc}")
            return None

    def update_profile(
        self,
        user_id: str,
        *,
        full_name: str | None = None,
        username: str | None = None,
        bio: str | None = None,
        avatar_url: str | None = None,
        push_token: str | None = None,
        ski_level: str | None = None,
        home: str | None = None,
    ) -> dict[str, Any] | None:
        """
        Update profile fields.

        Only updates provided fields (partial update).
        Returns updated profile dict on success, or None on failure.

        Arguments:
        - user_id: str, the id of the user to update the profile for
        - full_name: Optional[str], the full name of the user
        - username: Optional[str], the username of the user
        - bio: Optional[str], the bio of the user
        - avatar_url: Optional[str], the avatar url of the user
        - push_token: Optional[str], the push token of the user
        - ski_level: Optional[str], the ski level of the user
        - home: Optional[str], the home of the user

        Expected Return:
        - Optional[Dict[str, Any]]: the profile data for the user, or None if not found
        - e.g. [{'id': '123', 'full_name': 'John Doe', 'username': 'johndoe', 'bio': 'I am a software engineer', 'avatar_url': 'https://example.com/avatar.jpg', 'push_token': '1234567890', 'ski_level': 'beginner', 'home': 'New York', 'created_at': '2021-01-01 12:00:00', 'updated_at': '2021-01-01 12:00:00'}]
        """
        if not self.is_configured():
            logger.warning("Supabase not configured; skipping update_profile.")
            return None

        client = self._client
        if client is None:
            return None

        # Build update payload with only provided fields
        update_data: dict[str, Any] = {}
        if full_name is not None:
            update_data["full_name"] = full_name
        if username is not None:
            update_data["username"] = username
        if bio is not None:
            update_data["bio"] = bio
        if avatar_url is not None:
            update_data["avatar_url"] = avatar_url
        if push_token is not None:
            update_data["push_token"] = push_token
        if ski_level is not None:
            update_data["ski_level"] = ski_level
        if home is not None:
            update_data["home"] = home

        if not update_data:
            logger.warning("No fields to update provided")
            return None

        try:
            resp = client.table("profiles").update(update_data).eq("id", user_id).execute()
            data = getattr(resp, "data", None)
            if isinstance(data, list) and data:
                logger.info(f"Updated profile for user {user_id}")
                return data[0]
            if isinstance(data, dict):
                return data
            logger.error("Supabase update returned no data: %s", data)
            return None
        except Exception as exc:
            logger.exception(f"Failed to update profile for user {user_id}: {exc}")
            return None

    def username_exists(self, username: str, exclude_user_id: str | None = None) -> bool:
        """
        Check if username already exists (excluding a specific user if provided).

        Arguments:
        - username: str, the username to check if it exists
        - exclude_user_id: Optional[str], the id of the user to exclude from the check

        Expected Return:
        - bool: True if the username exists, False if it does not
        """
        if not self.is_configured():
            return False

        client = self._client
        if client is None:
            return False

        try:
            query = client.table("profiles").select("id").eq("username", username)
            if exclude_user_id:
                query = query.neq("id", exclude_user_id)
                # neq = not equal to, exclude the user_id from the check
            # `resp` = response from the database query
            resp = query.limit(1).execute()
            # `data` = data returned from the database query
            data = getattr(resp, "data", None)
            return isinstance(data, list) and len(data) > 0
        except Exception as exc:
            logger.exception(f"Error checking username existence: {exc}")
            return False

    def upload_avatar(
        self,
        user_id: str,
        file_content: bytes,
        file_extension: str = "jpg",
    ) -> str | None:
        """
        Upload avatar image to Supabase storage bucket 'avatars'.

        Args:
            user_id: UUID of the user
            file_content: Binary content of the image file
            file_extension: File extension (jpg, png, etc.)

        Returns:
            Public URL of the uploaded file, or None on failure
        """
        if not self.is_configured():
            logger.warning("Supabase not configured; skipping upload_avatar.")
            return None

        client = self._client
        if client is None:
            return None

        try:
            # Generate unique filename: user_id-timestamp.extension
            timestamp = int(datetime.now().timestamp())
            filename = f"{user_id}/{timestamp}.{file_extension}"

            # Upload to avatars bucket
            # Supabase Python SDK upload method signature
            client.storage.from_("avatars").upload(
                path=filename,
                file=file_content,
                file_options={"content-type": f"image/{file_extension}", "upsert": "true"},
            )

            # Get public URL - the get_public_url returns a string directly
            public_url = client.storage.from_("avatars").get_public_url(filename)

            logger.info(f"Uploaded avatar for user {user_id}: {filename}")
            return public_url
        except Exception as exc:
            logger.exception(f"Failed to upload avatar for user {user_id}: {exc}")
            return None

    def delete_avatar(self, user_id: str, avatar_url: str) -> bool:
        """
        Delete avatar image from Supabase storage.

        Args:
            user_id: UUID of the user
            avatar_url: URL of the avatar to delete

        Returns:
            True if deleted successfully, False otherwise
        """
        if not self.is_configured():
            logger.warning("Supabase not configured; skipping delete_avatar.")
            return False

        client = self._client
        if client is None:
            return False

        try:
            # Extract filename from URL
            # URL format: https://xxx.supabase.co/storage/v1/object/public/avatars/user_id/timestamp.ext
            if "/avatars/" in avatar_url:
                filename = avatar_url.split("/avatars/")[1]
                client.storage.from_("avatars").remove([filename])
                logger.info(f"Deleted avatar for user {user_id}: {filename}")
                return True
            return False
        except Exception as exc:
            logger.exception(f"Failed to delete avatar for user {user_id}: {exc}")
            return False
