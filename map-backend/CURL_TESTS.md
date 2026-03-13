# Map Backend - cURL Test Commands

This file contains cURL commands to test all endpoints in the Map Backend API.

## Important: macOS/Linux vs Windows Commands

`curl` examples in this document are split by shell type and are not interchangeable.

- `bash` blocks are for macOS/Linux shells and use `\` for line continuation.
- `powershell` blocks are for Windows PowerShell and use backtick `` ` `` for line continuation.
- In Windows PowerShell, `curl` maps to `Invoke-WebRequest`, so GNU-style flags (`-X`, `-H`, `-d`) behave differently unless you use `curl.exe`.

If you are on Windows, use the dedicated PowerShell examples/scripts below.

## Prerequisites

- Map Backend running on `http://localhost:5200`
- `GOOGLE_MAPS_API_KEY` configured in `.env`
- `curl` installed

## Environment Setup

```bash
# Export base URL for convenience
export MAP_BACKEND_URL="http://localhost:5200"
export GOOGLE_MAPS_API_KEY="your_google_maps_api_key_here"
```

```powershell
# Set base URL for this PowerShell session
$env:MAP_BACKEND_URL = "http://localhost:5200"
```

## Health & Status Endpoints

### 1. Health Check

Check if the service is running and healthy.

```bash
curl -X GET "${MAP_BACKEND_URL}/health" \
  -H "Content-Type: application/json"
```

**Expected Response:**
```json
{
  "status": "healthy",
  "service": "map-backend"
}
```

### 2. Root Endpoint

Get service information.

```bash
curl -X GET "${MAP_BACKEND_URL}/" \
  -H "Content-Type: application/json"
```

**Expected Response:**
```json
{
  "service": "Map Backend",
  "status": "running",
  "version": "1.0.0"
}
```

## Static Map Endpoints

### 3. Generate Static Map URL (POST)

Generate a static map URL with advanced options including paths and markers.

```bash
curl -X POST "${MAP_BACKEND_URL}/api/maps/static" \
  -H "Content-Type: application/json" \
  -d '{
    "center_lat": 37.7749,
    "center_lng": -122.4194,
    "zoom": 12,
    "width": 600,
    "height": 400,
    "markers": [
      [37.7749, -122.4194],
      [37.7849, -122.4094]
    ],
    "path": [
      [37.7749, -122.4194],
      [37.7800, -122.4150],
      [37.7849, -122.4094]
    ]
  }'
```

**Expected Response:**
```json
{
  "url": "https://maps.googleapis.com/maps/api/staticmap?center=37.7749,-122.4194&zoom=12&size=600x400&key=YOUR_KEY&style=feature:all|element:labels|visibility:off&markers=37.7749,-122.4194|37.7849,-122.4094&path=color:0x3b82f6|weight:2|37.7749,-122.4194|37.7800,-122.4150|37.7849,-122.4094",
  "center_lat": 37.7749,
  "center_lng": -122.4194,
  "zoom": 12,
  "width": 600,
  "height": 400
}
```

### 4. Generate Static Map URL (Without Markers/Path)

Generate a simple static map URL without overlays.

```bash
curl -X POST "${MAP_BACKEND_URL}/api/maps/static" \
  -H "Content-Type: application/json" \
  -d '{
    "center_lat": 40.7128,
    "center_lng": -74.0060,
    "zoom": 13,
    "width": 800,
    "height": 600
  }'
```

### 5. Fetch Static Map Image as Binary (POST)

Fetch the actual map image as binary PNG data. This saves the image to a file.

```bash
curl -X POST "${MAP_BACKEND_URL}/api/maps/static/image" \
  -H "Content-Type: application/json" \
  -d '{
    "center_lat": 37.7749,
    "center_lng": -122.4194,
    "zoom": 12,
    "width": 600,
    "height": 400
  }' \
  -o map_image.png
```

**Note:** This returns binary image data, so we use `-o` to save it to a file.

### 6. Simple Static Map URL (GET)

Simple GET endpoint for quick static map URL generation without advanced options.

```bash
curl -X GET "${MAP_BACKEND_URL}/api/maps/static/simple?lat=37.7749&lng=-122.4194&zoom=14&width=600&height=400" \
  -H "Content-Type: application/json"
```

**Expected Response:**
```json
{
  "url": "https://maps.googleapis.com/maps/api/staticmap?center=37.7749,-122.4194&zoom=14&size=600x400&key=YOUR_KEY&style=feature:all|element:labels|visibility:off",
  "center_lat": 37.7749,
  "center_lng": -122.4194,
  "zoom": 14,
  "width": 600,
  "height": 400
}
```

## Dynamic Map Endpoints (Interactive)

**Important:** Do **not** open the HTML via `file://` or you'll hit
`RefererNotAllowedMapError`. Serve it via HTTP.

### 7. Dynamic Map HTML (POST)

Returns interactive map HTML (Google Maps JS API).

```bash
curl -X POST "${MAP_BACKEND_URL}/api/maps/dynamic/html" \
  -H "Content-Type: application/json" \
  -d '{
    "center_lat": 37.7749,
    "center_lng": -122.4194,
    "zoom": 12,
    "width": 900,
    "height": 600,
    "markers": [[37.7749, -122.4194]]
  }' > map.html

python3 -m http.server 8088
```

Open: `http://localhost:8088/map.html`

### 8. Dynamic Map JSON (POST)

Returns JSON containing HTML.

```bash
curl -X POST "${MAP_BACKEND_URL}/api/maps/dynamic" \
  -H "Content-Type: application/json" \
  -d '{
    "center_lat": 37.7749,
    "center_lng": -122.4194,
    "zoom": 12,
    "width": 900,
    "height": 600
  }'
```

## Elevation Endpoints

### 9. Bulk Elevation Lookup (POST)

Get elevation data for multiple coordinates (up to 1000).

```bash
curl -X POST "${MAP_BACKEND_URL}/api/elevation/lookup" \
  -H "Content-Type: application/json" \
  -d '{
    "locations": [
      {
        "latitude": 40.7128,
        "longitude": -74.0060
      },
      {
        "latitude": 34.0522,
        "longitude": -118.2437
      },
      {
        "latitude": 41.8781,
        "longitude": -87.6298
      }
    ]
  }'
```

**Expected Response:**
```json
{
  "results": [
    {
      "latitude": 40.7128,
      "longitude": -74.0060,
      "elevation": 10.456
    },
    {
      "latitude": 34.0522,
      "longitude": -118.2437,
      "elevation": 87.234
    },
    {
      "latitude": 41.8781,
      "longitude": -87.6298,
      "elevation": 181.123
    }
  ],
  "count": 3
}
```

### 10. Single Point Elevation Lookup (GET)

Get elevation data for a single coordinate using a simple GET endpoint.

```bash
curl -X GET "${MAP_BACKEND_URL}/api/elevation/point?lat=40.7128&lng=-74.0060" \
  -H "Content-Type: application/json"
```

**Expected Response:**
```json
{
  "latitude": 40.7128,
  "longitude": -74.0060,
  "elevation": 10.456
}
```

## Authenticated Requests

Most endpoints support optional JWT authentication. Include an Authorization header with a valid JWT token.

### Example with JWT Token

```bash
curl -X POST "${MAP_BACKEND_URL}/api/maps/static" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "center_lat": 37.7749,
    "center_lng": -122.4194,
    "zoom": 12
  }'
```

## Error Handling

### 400 Bad Request - Invalid Coordinates

```bash
curl -X GET "${MAP_BACKEND_URL}/api/elevation/point?lat=91&lng=-74.0060" \
  -H "Content-Type: application/json"
```

**Expected Response:**
```json
{
  "detail": "Latitude must be between -90 and 90"
}
```

### 401 Unauthorized - Missing Token (if required)

```bash
curl -X POST "${MAP_BACKEND_URL}/api/maps/static" \
  -H "Content-Type: application/json" \
  -d '{"center_lat": 37.7749, "center_lng": -122.4194}'
```

**Note:** Authentication is optional for most endpoints, so this may succeed without a token.

### 500 Internal Server Error - API Failure

If the Google Maps API key is invalid or the API service is unavailable, you may receive:

```json
{
  "detail": "Failed to generate static map: ..."
}
```

## Testing Script

### Option A: macOS/Linux (Bash)

Save this as `test_map_backend.sh` to run all tests in macOS/Linux:

```bash
#!/bin/bash

BASE_URL="http://localhost:5200"

echo "========== Testing Map Backend =========="
echo ""

echo "1. Health Check"
curl -X GET "${BASE_URL}/health" | jq .
echo ""

echo "2. Root Endpoint"
curl -X GET "${BASE_URL}/" | jq .
echo ""

echo "3. Simple Static Map"
curl -X GET "${BASE_URL}/api/maps/static/simple?lat=37.7749&lng=-122.4194&zoom=12" | jq .
echo ""

echo "4. Static Map with POST"
curl -X POST "${BASE_URL}/api/maps/static" \
  -H "Content-Type: application/json" \
  -d '{"center_lat": 37.7749, "center_lng": -122.4194, "zoom": 12}' | jq .
echo ""

echo "5. Single Point Elevation"
curl -X GET "${BASE_URL}/api/elevation/point?lat=40.7128&lng=-74.0060" | jq .
echo ""

echo "6. Bulk Elevation Lookup"
curl -X POST "${BASE_URL}/api/elevation/lookup" \
  -H "Content-Type: application/json" \
  -d '{
    "locations": [
      {"latitude": 40.7128, "longitude": -74.0060},
      {"latitude": 34.0522, "longitude": -118.2437}
    ]
  }' | jq .
echo ""

echo "========== Tests Complete =========="
```

Make it executable and run:

```bash
chmod +x test_map_backend.sh
./test_map_backend.sh
```

### Option B: Windows (PowerShell)

Save this as `test_map_backend.ps1` to run all tests in Windows PowerShell:

```powershell
$ErrorActionPreference = "Stop"
$BASE_URL = "http://localhost:5200"

function Step([string]$Title) {
  Write-Host "`n========== $Title ==========" -ForegroundColor Cyan
}

Step "1. Health Check"
Invoke-RestMethod -Method Get -Uri "$BASE_URL/health" | ConvertTo-Json -Depth 10

Step "2. Root Endpoint"
Invoke-RestMethod -Method Get -Uri "$BASE_URL/" | ConvertTo-Json -Depth 10

Step "3. Simple Static Map (GET)"
Invoke-RestMethod -Method Get -Uri "$BASE_URL/api/maps/static/simple?lat=37.7749&lng=-122.4194&zoom=12&width=600&height=400" | ConvertTo-Json -Depth 10

$staticBody = @{
  center_lat = 37.7749
  center_lng = -122.4194
  zoom = 12
  width = 600
  height = 400
} | ConvertTo-Json -Depth 10 -Compress

Step "4. Static Map URL (POST)"
Invoke-RestMethod -Method Post -Uri "$BASE_URL/api/maps/static" -ContentType "application/json" -Body $staticBody | ConvertTo-Json -Depth 10

Step "5. Static Map Image (POST)"
Invoke-WebRequest -Method Post -Uri "$BASE_URL/api/maps/static/image" -ContentType "application/json" -Body $staticBody -OutFile "map_image.png"
Write-Host "Saved map_image.png"

$dynamicBody = @{
  center_lat = 37.7749
  center_lng = -122.4194
  zoom = 12
  width = 900
  height = 600
  markers = @(, @(37.7749, -122.4194))  # unary comma prevents array flattening
} | ConvertTo-Json -Depth 10 -Compress

Step "6. Dynamic Map HTML (POST)"
Invoke-WebRequest -Method Post -Uri "$BASE_URL/api/maps/dynamic/html" -ContentType "application/json" -Body $dynamicBody -OutFile "dynamic_map.html"
Write-Host "Saved dynamic_map.html"

Step "7. Dynamic Map JSON (POST)"
Invoke-RestMethod -Method Post -Uri "$BASE_URL/api/maps/dynamic" -ContentType "application/json" -Body $dynamicBody | ConvertTo-Json -Depth 10

Step "8. Single Point Elevation (GET)"
Invoke-RestMethod -Method Get -Uri "$BASE_URL/api/elevation/point?lat=40.7128&lng=-74.0060" | ConvertTo-Json -Depth 10

$elevationBody = @{
  locations = @(
    @{ latitude = 40.7128; longitude = -74.0060 }
    @{ latitude = 34.0522; longitude = -118.2437 }
  )
} | ConvertTo-Json -Depth 10 -Compress

Step "9. Bulk Elevation Lookup (POST)"
Invoke-RestMethod -Method Post -Uri "$BASE_URL/api/elevation/lookup" -ContentType "application/json" -Body $elevationBody | ConvertTo-Json -Depth 10

Write-Host "`n========== Tests Complete ==========" -ForegroundColor Green
Write-Host "To view dynamic map: run 'py -m http.server 8088' and open http://localhost:8088/map.html"
```

Run it:

```powershell
# If script execution is blocked for this session
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

.\test_map_backend.ps1
```

## Real-World Examples

### Example 1: Get Elevation Profile Along a Route

```bash
curl -X POST "${MAP_BACKEND_URL}/api/elevation/lookup" \
  -H "Content-Type: application/json" \
  -d '{
    "locations": [
      {"latitude": 37.770, "longitude": -122.419},
      {"latitude": 37.771, "longitude": -122.418},
      {"latitude": 37.772, "longitude": -122.417},
      {"latitude": 37.773, "longitude": -122.416}
    ]
  }' | jq .
```

### Example 2: Generate Map with Trail Path

```bash
curl -X POST "${MAP_BACKEND_URL}/api/maps/static" \
  -H "Content-Type: application/json" \
  -d '{
    "center_lat": 37.771,
    "center_lng": -122.418,
    "zoom": 14,
    "path": [
      [37.770, -122.419],
      [37.771, -122.418],
      [37.772, -122.417],
      [37.773, -122.416]
    ],
    "markers": [
      [37.770, -122.419],
      [37.773, -122.416]
    ]
  }'
```

### Example 3: Fetch and Display Map Image

```bash
# Fetch map image and save
curl -X POST "${MAP_BACKEND_URL}/api/maps/static/image" \
  -H "Content-Type: application/json" \
  -d '{
    "center_lat": 37.7749,
    "center_lng": -122.4194,
    "zoom": 12,
    "width": 800,
    "height": 600
  }' -o map_image.png

# Display on macOS
open map_image.png

# Display on Linux
display map_image.png
```

## Notes

- All coordinates use latitude/longitude format (not lng/lat)
- Zoom levels range from 0 to 22
- Image dimensions range from 1 to 1280 pixels
- Maximum 1000 coordinates per elevation lookup request
- Google Maps API key must be set in `.env` file
- All timestamps in responses are in UTC

