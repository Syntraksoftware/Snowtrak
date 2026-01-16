"""
Activity API endpoints
Handles activity CRUD operations 
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import Optional, List 
from datetime import datetime 
from app.schemas import (ActivityCreate, ActivityUpdate, ActivityResponse, LocationResponse, ErrorResponse)
from app.core.storage import User, Activity, activity_store
from app.core.supabase import supabase_client
from app.api.dependencies import get_current_user
import logging

logger = logging.getLogger(__name__) 

router = APIRouter(prefix="/activities", tags=["Activities"])

@router.post("/", response_model=ActivityResponse) 

# define route of the endpoint
def create_activity(activity: ActivityCreate, current_user: User = Depends(get_current_user)) -> ActivityResponse:
    """Create a new activity"""