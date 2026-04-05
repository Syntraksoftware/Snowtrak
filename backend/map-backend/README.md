# Map Backend

FastAPI microservice for static map image generation and elevation data lookup for the Syntrak skiing application.

## 1. Purpose and scope

The Map Backend provides location-based utilities: generating static map images for activity recording and detail views, and enriching GPS coordinates with elevation data. This service acts as a facade over Google Maps (map images) and Open Elevation API (elevation lookup), reducing direct API calls from the frontend.

**Key responsibilities:**
- Static map generation (`/api/maps/*`)
- Elevation lookup for GPS coordinates (`/api/elevation/*`)
- JWT authentication and service integration
- Caching map images for offline access

## 2. Architecture overview

### High-level design

Map Backend is a lightweight FastAPI microservice that wraps external mapping APIs and exposes simplified endpoints for the Flutter frontend. It does not manage persistent data; instead, it acts as a pass-through with optional result caching.

```
Flutter Frontend (map_api.dart)
  ↓ HTTP POST (coordinates, zoom level)
Map Backend (/api/maps/*, /api/elevation/*)
  ↓ HTTPS
Google Maps Static API + Open Elevation API
  ↓
Static map image URL + elevation data
```

### Key design patterns

- **Facade pattern**: Wraps Google Maps and Open Elevation API behind simplified HTTP endpoints
- **Service locator**: External API credentials (API keys) managed centrally in config; credentials injected into service instances
- **Optional JWT auth**: Endpoints support optional authorization for tracking/billing purposes; unauthenticated requests allowed
- **Supabase coordination**: Can query Supabase for user preferences (saved map styles, zoom defaults) if needed in future

### Data contracts/models

**Static Map request:**
- `center_lat`, `center_lng`: Center point latitude/longitude
- `zoom`: Zoom level (1–21)
- `width`, `height`: Image dimensions in pixels (default: 600×400)
- `path`: Optional polyline of GPS coordinates to overlay on map
- `markers`: Optional array of marker locations

**Static Map response:**
- `url`: HTTPS URL to static map image
- `cache_key`: Optional identifier for offline caching

**Elevation Lookup request:**
- `locations`: Array of {latitude, longitude} objects (up to 1000 points)

**Elevation Lookup response:**
- `results`: Array of {latitude, longitude, elevation_meters} objects

**Elevation correction (`POST /api/elevation/correct`):**
- Request/response types live in `backend/shared/track_pipeline_schemas.py` as `ElevationCorrectionRequest` / `ElevationCorrectionResponse` (mirrors Dart `TrackPoint` and the map pipeline contract).
- Up to 512 points per call; returns the same track with `elevation_m` filled from the configured elevation API.

Canonical Pydantic models for the full track pipeline (`TrackPointIn`, `ProcessedTrackOut`, `SegmentOut`, `ActivityStatsOut`, `RunSummaryOut`, `TrailMatchRequest`/`Response`, `ActivityIn`/`Out`, etc.) also live in that shared module for use across services.

**Note:** Server-generated **dynamic map HTML** was removed; the mobile app renders maps natively.

### External integrations

- **Google Maps Static API** (https://maps.googleapis.com/maps/api/staticmap): Generates static map images with paths and markers
- **Open Elevation API** (https://api.open-elevation.com/api/v1/lookup): Bulk elevation data for coordinates
- **Supabase**: Optional coordination for user preferences (reserved for future use)

## 3. Code structure and key components

### File map

```
backend/map-backend/
├── main.py                     # FastAPI app setup, lifespan, startup hooks
├── config.py                   # Environment variables & settings
├── routes/
│   ├── maps.py                # Static map endpoints (/api/maps/*)
│   └── elevation.py           # Elevation endpoints (/api/elevation/*)
├── services/
│   ├── static_map_client.py   # Google Maps Static API client
│   └── elevation_client.py    # Open Elevation API wrapper
├── middleware/
│   └── auth.py                # JWT extraction (optional auth)
├── CURL_TESTS.md              # Manual endpoint testing guide
├── LOCAL_SETUP.md             # Local development walkthrough
└── requirements.txt           # Python dependencies
```

### Entry points

- **main.py**: Initializes FastAPI app, registers routes, starts ASGI server on port 5200
- **routes/maps.py**: Defines static map endpoints; receives coordinate/zoom inputs, calls static_map_client, returns image URL or binary image
- **routes/elevation.py**: Defines elevation lookup endpoints; receives location arrays, calls elevation_client, returns enriched data

### Critical logic

1. **Static map generation** (maps.py): Accepts center lat/lng and zoom; constructs Google Maps Static API URL with authentication; returns HTTPS image URL
2. **Elevation lookup** (elevation.py): Batches coordinate requests in chunks of ≤1000; calls Open Elevation API; returns elevation in meters for each point
3. **Response caching**: Optionally caches elevation results in Supabase or Redis to reduce repeated API calls
4. **Error handling**: Gracefully handles external API failures (returns 503 Service Unavailable); logs errors for monitoring

### Configuration

Environment variables (set via `.env` or deployment config):
- `MAP_STORAGE_BACKEND`: `supabase` (default) or `postgis`
- `GOOGLE_MAPS_API_KEY`: Google Maps Static API key
- `OPEN_ELEVATION_API_URL`: Open Elevation API endpoint (default: https://api.open-elevation.com/api/v1/lookup)
- `JWT_SECRET`: Shared secret for token validation (from deployment config)
- `HOST`, `PORT`: Server bind address (default: 127.0.0.1:5200)
- `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`: Required when `MAP_STORAGE_BACKEND=supabase`
- `POSTGIS_DSN` or `POSTGIS_HOST/PORT/DB/USER/PASSWORD`: Used when `MAP_STORAGE_BACKEND=postgis`

## 4. Development and maintenance guidelines

### Setup instructions

1. **Install and run:**
   ```bash
  # From repository root
  python3.11 -m venv .venv
  ./.venv/bin/pip install -r backend/requirements.txt

  cd backend/map-backend
  ../../.venv/bin/python -m pip install -r requirements.txt
   cp .env.example .env
   # Edit .env: set GOOGLE_MAPS_API_KEY, OPEN_ELEVATION_API_URL, JWT_SECRET
  ../../.venv/bin/python main.py
   ```

2. **Obtain API credentials:**
   - Google Maps Static API: Create project in Google Cloud Console, enable Static Maps API, generate API key
   - Open Elevation API: Free service; no key required (but rate-limited; optional fallback to paid elevation service)

### Testing strategy

- Unit tests for map URL construction and elevation request batching
- Integration tests against live Google Maps and Open Elevation APIs (use test coordinates)
- Manual curl tests in CURL_TESTS.md for endpoint verification

**Run tests:**
```bash
pytest tests/
pytest tests/ -v --tb=short  # Verbose output
```

### Code standards

- Service classes encapsulate external API calls (separation of concerns)
- Routes handle HTTP marshaling; services handle business logic
- Config.py centralizes all environment variable loading
- Shared auth middleware via `backend/shared/auth.py` (consistent token validation)

### Common pitfalls

- **Google Maps API key leakage**: Never commit `.env` file; rotate keys if accidentally exposed
- **Elevation API rate limits**: Batch requests and implement retry logic; consider caching results
- **Coordinate validation**: Ensure latitude (-90..90) and longitude (-180..180) are valid before sending to external APIs
- **Cache invalidation**: If caching elevation results, set TTL appropriately (e.g., 7 days for static terrain)

### Logging and monitoring

- Logs: Standard Python logging to stdout
- Key log points: External API calls (request/response), rate limit hits, authentication errors
- Monitor: External API latency, cache hit ratio, token validation failures

## 5. Deployment and operations

### Build and deployment

```bash
# Local Docker build
docker build -t syntrak-map-backend:latest .

# Via docker-compose from backend root
cd backend
docker-compose up -d syntrak-map-backend

# Run map-backend with local PostGIS storage ownership
MAP_STORAGE_BACKEND=postgis docker-compose up -d postgis map-backend

# Optional: initialize local map storage tables
psql "postgresql://syntrak:syntrak_local_dev@localhost:5432/syntrak" \
  -f map-backend/engine/geometry/001_init_postgis_storage.sql
```

Service runs on port 5200 and communicates with Google Maps and Open Elevation API over HTTPS.

### Runtime requirements

- Python 3.11+ (FastAPI, Pydantic)
- Internet access to Google Maps Static API and Open Elevation API (HTTPS)
- Environment variables: `GOOGLE_MAPS_API_KEY`, `JWT_SECRET`
- Shared backend/shared/ directory for auth utilities

### Health checks

- **Liveness**: HTTP GET `/health` (returns 200 if service running)
- **Readiness**: Successful external API call (test static map or elevation endpoint)

### Backward compatibility

- Static map endpoint response format (URL + cache_key) should remain stable
- Adding optional parameters to elevation request is non-breaking
- Version API if major contract changes needed (e.g., elevation units)

## 6. Examples and usage

### Generate static map image

```bash
curl -X POST http://localhost:5200/api/maps/static \
  -H "Content-Type: application/json" \
  -d '{
    "center_lat": 39.2847,
    "center_lng": -106.5007,
    "zoom": 13,
    "width": 600,
    "height": 400
  }'
```

Response:
```json
{"url": "https://maps.googleapis.com/maps/api/staticmap?..."}
```

### Generate map with activity path overlay

```bash
curl -X POST http://localhost:5200/api/maps/static \
  -H "Content-Type: application/json" \
  -d '{
    "center_lat": 39.2847,
    "center_lng": -106.5007,
    "zoom": 13,
    "path": [
      {"lat": 39.2847, "lng": -106.5007},
      {"lat": 39.2848, "lng": -106.5006},
      {"lat": 39.2850, "lng": -106.5005}
    ]
  }'
```

### Lookup elevation for GPS points

```bash
curl -X POST http://localhost:5200/api/elevation/lookup \
  -H "Content-Type: application/json" \
  -d '{
    "locations": [
      {"latitude": 39.2847, "longitude": -106.5007},
      {"latitude": 39.2848, "longitude": -106.5006}
    ]
  }'
```

Response:
```json
{
  "results": [
    {"latitude": 39.2847, "longitude": -106.5007, "elevation_meters": 3208},
    {"latitude": 39.2848, "longitude": -106.5006, "elevation_meters": 3205}
  ]
}
```

### Simple single-point elevation

```bash
curl "http://localhost:5200/api/elevation/point?lat=39.2847&lng=-106.5007"
```

## 7. Troubleshooting and FAQs

### Common errors

**403 Forbidden (Google Maps API)**: Invalid or restricted API key
- Check: Google Maps API key is correct and has Static Maps API enabled
- Check: API key has appropriate usage restrictions (IP allowlist, referrer domain)
- Check: Quota not exceeded in Google Cloud Console

**429 Too Many Requests (Open Elevation)**: Rate limit exceeded
- Implement exponential backoff for retries
- Cache elevation results (TTL 7 days)
- Consider upgrade to paid elevation API if frequent lookups needed

**Invalid coordinates**: Latitude or longitude out of range
- Ensure latitude is -90..90 and longitude is -180..180
- Check for null or NaN values in GPS data

### Debugging tips

- Use Google Maps Static API URL builder (https://mapsplatform.google.com/maps-products/#static-maps) to test API calls directly
- Trace elevation requests via logs; compare against Open Elevation API documentation
- Test with fixed test coordinates to isolate frontend vs. backend issues

### Performance tuning

- Cache static map URLs for repeated center/zoom/path combinations (Redis or Supabase)
- Batch elevation requests to minimize API calls (supported by Open Elevation API batch endpoint)
- Consider CDN (CloudFront, Cloudflare) for static map image caching
- Monitor Google Maps API costs; implement request rate limiting if budget needed

## 8. Change log and versioning

### Recent updates

- **2024-01**: Initial FastAPI service with static map and elevation endpoints
- **2024-02**: Added optional JWT authentication for usage tracking
- **2024-03**: Integrated Open Elevation API as primary elevation provider

### Version compatibility

- Map Backend v1 expects: static map requests with {center_lat, center_lng, zoom, width, height}; elevation requests with {locations: [{latitude, longitude}]}
- Frontend expects map-backend running on port 5200 via app configuration (app_config.dart)
- Shared backend services (auth) imported from `backend/shared`
