"""
In-memory user storage (fallback when Supabase not configured).
For development/demo only - data lost on restart.
"""
from typing import Dict, Optional
from datetime import datetime, timezone
import uuid


class User:
    """Simple user data class."""
    def __init__(
        self,
        email: str,
        hashed_password: str,
        first_name: Optional[str] = None,
        last_name: Optional[str] = None,
        id: Optional[str] = None,
        is_active: bool = True,
    ):
        # Use provided id or generate a real UUID for Supabase compatibility
        self.id = id or str(uuid.uuid4())
        self.email = email
        self.hashed_password = hashed_password
        self.first_name = first_name
        self.last_name = last_name
        self.is_active = is_active
        self.created_at = datetime.now(timezone.utc)
        self.last_login_at: Optional[datetime] = None


class UserStore:
    """In-memory user storage."""
    
    def __init__(self):
        self._users: Dict[str, User] = {}  # id -> User
        self._email_index: Dict[str, str] = {}  # email -> id
    
    def get_by_id(self, user_id: str) -> Optional[User]:
        """Get user by ID."""
        return self._users.get(user_id)
    
    def get_by_email(self, email: str) -> Optional[User]:
        """Get user by email."""
        user_id = self._email_index.get(email.lower())
        return self._users.get(user_id) if user_id else None
    
    def create(self, user: User) -> User:
        """Create new user."""
        self._users[user.id] = user
        self._email_index[user.email.lower()] = user.id
        return user
    
    def exists_by_email(self, email: str) -> bool:
        """Check if email is already registered."""
        return email.lower() in self._email_index


# Global instance
user_store = UserStore()


class Activity: 
    """
    Activity data class for in memory storage: 
    """
    
    def __init__(self,
        user_id: str,
        type: str,
        distance: float,
        duration: int,
        start_time: datetime,
        end_time: datetime,
        name: Optional[str] = None,
        description: Optional[str] = None,
        elevation_gain: float = 0,
        average_pace: float = 0,
        max_pace: float = 0,
        calories: Optional[int] = None,
        is_public: bool = True,
        id: Optional[str] = None,
        locations: Optional[list] = None,) -> None:
        self.id = id or str(uuid.uuid4())
        self.user_id = user_id
        self.type = type
        self.name = name
        self.description = description
        self.distance = distance
        self.duration = duration
        self.elevation_gain = elevation_gain
        self.start_time = start_time
        self.end_time = end_time
        self.average_pace = average_pace
        self.max_pace = max_pace
        self.calories = calories
        self.is_public = is_public
        self.created_at = datetime.now(timezone.utc)
        self.locations = locations or []
        
        
class ActivityStore:
    """In-memory activity storage."""
    
    def __init__(self):
        self._activities: Dict[str, Activity] = {}  # id -> Activity
        self._user_index: Dict[str, str] = {}  # user_id -> id
        
    def get_by_id(self, activity_id: str) -> Optional[Activity]:
        """Get activity by ID."""
        return self._activities.get(activity_id)
        
    def get_by_user_id(self, user_id:str, limit: int = 20, offset: int = 0) -> list[Activity]: 
        # offset is the starting index for pagination 
        """Get activites for a user, newest first"""
        activity_ids = self._user_index.get(user_id, [])
        # sort by created_at descending 
        activities = [self._activities[id] for id in activity_ids]
        activities.sort(key = lambda a: a.created_at, reverse = True)
        # get the last limit activities
        return activities[offset:offset + limit] # return a list of activities
    
        
    def create(self, activity: Activity) -> Activity:
        """Create new activity."""
        self._activities[activity.id] = activity
        if activity.user_id not in self._user_index:
            # create condition: if the user_id is not in the user_index, create a new list for the user_id (i.e the user has no activities yet, now created the first activity)
            self._user_index[activity.user_id] = []
        self._user_index[activity.user_id].append(activity.id)
        return activity
    
    def update(self, activity_id: str, **kwargs) -> Optional[Activity]:
        """Update activity fields."""
        activity = self._activities.get(activity_id)
        if activity:
            for key, value in kwargs.items():
                if hasattr(activity, key) and value is not None:
                    setattr(activity, key, value)
        return activity
    
    def delete(self, activity_id: str) -> bool:
        """Delete activity."""
        # Attempt to remove the activity from the _activities dictionary.
        # If it exists pop will return the Activity object; otherwise, returns None.
        activity = self._activities.pop(activity_id, None)
        if activity:
            # If the activity existed, check if the user_id is present in the user index.
            if activity.user_id in self._user_index:
                # Remove the activity_id from the user's list of activity IDs.
                self._user_index[activity.user_id] = [
                    aid for aid in self._user_index[activity.user_id] if aid != activity_id
                ]
            # Indicate successful deletion.
            return True
        return False
    
activity_store = ActivityStore()
# global instance of the activity store, used to store and manage activities in memory
 