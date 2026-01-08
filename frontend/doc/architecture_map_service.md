# Map Services Architecture: Frontend vs Backend

## Current Implementation

### Frontend Services (✅ Correctly Placed)
- **GPS Filter Service** (`lib/services/gps_filter_service.dart`)
  - Real-time filtering of GPS points
  - Device-specific accuracy handling
  - Works offline
  
- **Location Service** (`lib/services/location_service.dart`)
  - Device GPS access
  - Real-time position streaming
  - Permission handling

- **Map Service** (`lib/services/map_service.dart`)
  - Google Maps rendering
  - Camera positioning
  - UI/UX utilities

### Frontend Services (⚠️ Could Be Hybrid)
- **Route Calculation Service** (`lib/services/route_calculation_service.dart`)
  - Currently: Frontend-only
  - Should be: Frontend for real-time + Backend for validation

---

## Recommended Architecture

### Frontend Responsibilities
```
┌─────────────────────────────────────┐
│      Frontend (Flutter/Dart)        │
├─────────────────────────────────────┤
│ ✅ GPS Tracking & Filtering         │
│ ✅ Real-time Map Rendering          │
│ ✅ Live Stats Calculation           │
│ ✅ Local Storage (Offline)          │
│ ✅ UI/UX Components                 │
└─────────────────────────────────────┘
```

**Rationale:**
- **Performance**: Real-time processing needs to be instant
- **Offline Support**: Users should record activities without internet
- **Battery Efficiency**: Local processing reduces network calls
- **User Experience**: Immediate feedback during recording

### Backend Responsibilities
```
┌─────────────────────────────────────┐
│    Backend (Python/FastAPI)         │
├─────────────────────────────────────┤
│ ✅ Activity Persistence             │
│ ✅ Route Validation & Correction    │
│ ✅ Metric Recalculation             │
│ ✅ Advanced Analytics               │
│ ✅ Route Processing (segments, etc)  │
│ ✅ Data Sync & Backup               │
└─────────────────────────────────────┘
```

**Rationale:**
- **Data Integrity**: Centralized validation ensures consistency
- **Cross-Platform**: Same calculations for web, iOS, Android
- **Advanced Features**: Server-side processing for complex analytics
- **Security**: Validate data before storage

---

## Proposed Backend Services

### 1. Activity API (`main-backend/app/api/v1/activities.py`)

```python
@router.post("/activities", response_model=ActivityResponse)
async def create_activity(
    activity: ActivityCreate,
    current_user: User = Depends(get_current_user)
):
    """
    Create a new activity.
    
    - Validates GPS data quality
    - Recalculates metrics server-side
    - Stores in database
    """
    # Validate route data
    validated_locations = validate_gps_data(activity.locations)
    
    # Recalculate metrics (server-side validation)
    metrics = calculate_route_metrics(validated_locations)
    
    # Store activity
    activity = save_activity(current_user.id, validated_locations, metrics)
    
    return activity
```

### 2. Route Processing Service (`main-backend/app/services/route_service.py`)

```python
class RouteService:
    """Server-side route processing and validation"""
    
    @staticmethod
    def validate_gps_data(locations: List[Location]) -> List[Location]:
        """
        Validate and correct GPS data:
        - Remove outliers
        - Smooth route
        - Correct elevation data
        """
        pass
    
    @staticmethod
    def calculate_route_metrics(locations: List[Location]) -> RouteMetrics:
        """
        Calculate route metrics:
        - Distance (haversine)
        - Elevation gain/loss
        - Speed/pace statistics
        - Moving time
        """
        pass
    
    @staticmethod
    def simplify_route(locations: List[Location]) -> List[Location]:
        """
        Simplify route using Douglas-Peucker algorithm
        Reduces storage while maintaining route shape
        """
        pass
    
    @staticmethod
    def correct_elevation(locations: List[Location]) -> List[Location]:
        """
        Correct elevation using DEM (Digital Elevation Model)
        More accurate than GPS altitude
        """
        pass
```

### 3. Activity Storage (`main-backend/app/core/activity_storage.py`)

```python
class ActivityStorage:
    """Handles activity persistence in Supabase"""
    
    def save_activity(self, user_id: str, activity: Activity) -> Activity:
        """Save activity to database"""
        pass
    
    def get_activities(self, user_id: str, filters: dict) -> List[Activity]:
        """Query activities with filters"""
        pass
    
    def get_activity(self, activity_id: str) -> Activity:
        """Get single activity"""
        pass
```

---

## Data Flow

### Recording Flow
```
1. User starts recording (Frontend)
   ↓
2. GPS points collected & filtered (Frontend)
   ↓
3. Real-time stats calculated (Frontend)
   ↓
4. Route displayed on map (Frontend)
   ↓
5. User stops recording (Frontend)
   ↓
6. Activity saved locally (Frontend - Offline)
   ↓
7. Activity synced to backend (Frontend → Backend)
   ↓
8. Backend validates & recalculates (Backend)
   ↓
9. Backend stores in database (Backend)
   ↓
10. Updated metrics returned (Backend → Frontend)
```

### Viewing Flow
```
1. User requests activity (Frontend)
   ↓
2. Check local storage first (Frontend)
   ↓
3. If not found, fetch from backend (Frontend → Backend)
   ↓
4. Backend returns activity with validated metrics (Backend → Frontend)
   ↓
5. Display on map (Frontend)
```

---

## Benefits of Hybrid Approach

### ✅ Advantages
1. **Offline Support**: Users can record without internet
2. **Performance**: Real-time calculations are instant
3. **Data Integrity**: Backend validates and corrects data
4. **Consistency**: Same metrics across all platforms
5. **Advanced Features**: Server-side processing for complex analytics

### ⚠️ Considerations
1. **Sync Complexity**: Need to handle offline/online sync
2. **Data Duplication**: Frontend calculates, backend recalculates
3. **Network Dependency**: Some features require backend

---

## Implementation Priority

### Phase 1: MVP (Current)
- ✅ Frontend services (GPS, filtering, calculations)
- ✅ Local storage
- ⚠️ Basic backend API (just store activities)

### Phase 2: Validation
- Add backend route validation
- Recalculate metrics server-side
- Return corrected data to frontend

### Phase 3: Advanced
- Route simplification
- Elevation correction
- Segment matching
- Heatmaps

---

## Recommendation

**Keep current frontend services** for:
- Real-time GPS tracking
- Map rendering
- Live calculations
- Offline support

**Add backend services** for:
- Activity persistence API
- Route validation
- Metric recalculation
- Advanced analytics

This hybrid approach gives you:
- ✅ Fast, responsive UI (frontend)
- ✅ Data integrity (backend)
- ✅ Offline capability (frontend)
- ✅ Advanced features (backend)

---

## Next Steps

1. **Create Backend Activity API** (`main-backend/app/api/v1/activities.py`)
2. **Create Route Service** (`main-backend/app/services/route_service.py`)
3. **Add Activity Storage** (`main-backend/app/core/activity_storage.py`)
4. **Update Frontend** to sync with backend after recording
5. **Add Validation** to ensure data quality

Would you like me to implement the backend services?

