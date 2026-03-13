# Map Backend

Map Backend is a FastAPI microservice that provides static map image generation and elevation correction APIs for the Syntrak application.

## Features

- **Static Map Generation**: Generate static map images with optional paths and markers using the Google Maps Static API
- **Elevation Lookup**: Get elevation data for coordinates using the Google Maps Elevation API
- **JWT Authentication**: Optional authentication for API tracking
- **Docker Support**: Fully containerized with Docker

## Tech Stack

- **FastAPI**: Modern, fast web framework
- **Google Maps Static API**: For generating static maps
- **Google Maps Elevation API**: For elevation data
- **Supabase**: Database and authentication
- **Docker**: Containerization

## Setup

### Prerequisites

- Python 3.11+
- Docker (optional)
- Mapbox access token

### Local Development

1. Install dependencies:
```bash
cd map-backend
pip install -r requirements.txt
```

2. Create `.env` file (use `.env.example` as template):
```bash
cp .env.example .env
```

3. Configure environment variables:
```env
SUPABASE_URL=your_supabase_url
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
JWT_SECRET=your_jwt_secret
MAPBOX_ACCESS_TOKEN=your_mapbox_token
```

4. Run the server:
```bash
python main.py
```

Or with uvicorn:
```bash
uvicorn main:app --reload --port 5200
```

### Docker

Build and run with Docker:
```bash
docker build -t map-backend .
docker run -p 5200:5200 --env-file .env map-backend
```

Or use docker-compose from project root:
```bash
docker-compose up map-backend
```

## API Endpoints

### Health & Status

- `GET /` - Service information
- `GET /health` - Health check endpoint

### Static Maps

- `POST /api/maps/static` - Generate static map URL with advanced options
- `POST /api/maps/static/image` - Fetch static map image as binary
- `GET /api/maps/static/simple` - Simple static map URL generation

### Elevation

- `POST /api/elevation/lookup` - Bulk elevation lookup (up to 1000 points)
- `GET /api/elevation/point` - Single point elevation lookup

## API Examples

### Generate Static Map URL

```bash
curl -X POST http://localhost:5200/api/maps/static \
  -H "Content-Type: application/json" \
  -d '{
    "center_lat": 37.7749,
    "center_lng": -122.4194,
    "zoom": 12,
    "width": 600,
    "height": 400
  }'
```

### Get Elevation Data

```bash
curl -X POST http://localhost:5200/api/elevation/lookup \
  -H "Content-Type: application/json" \
  -d '{
    "locations": [
      {"latitude": 37.7749, "longitude": -122.4194},
      {"latitude": 37.7849, "longitude": -122.4094}
    ]
  }'
```

### Simple Elevation Lookup

```bash
curl "http://localhost:5200/api/elevation/point?lat=37.7749&lng=-122.4194"
```

## Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `SUPABASE_URL` | Supabase project URL | Required |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase service role key | Required |
| `JWT_SECRET` | JWT signing secret | Required |
| `MAPBOX_ACCESS_TOKEN` | Mapbox API access token | "" |
| `OPEN_ELEVATION_API_URL` | Elevation API URL | https://api.open-elevation.com/api/v1/lookup |
| `FASTAPI_ENV` | Environment (development/production) | development |
| `HOST` | Server host | 127.0.0.1 |
| `PORT` | Server port | 5200 |
| `STATIC_MAP_WIDTH` | Default map width | 600 |
| `STATIC_MAP_HEIGHT` | Default map height | 400 |
| `STATIC_MAP_ZOOM` | Default zoom level | 12 |

## Development

### Project Structure

```
map-backend/
├── main.py                 # FastAPI app & lifecycle
├── config.py              # Configuration
├── requirements.txt       # Python dependencies
├── Dockerfile            # Docker configuration
├── .dockerignore         # Docker ignore rules
├── .env.example          # Environment template
├── middleware/
│   └── auth.py           # JWT authentication
├── routes/
│   ├── maps.py           # Static map routes
│   └── elevation.py      # Elevation routes
└── services/
    ├── supabase_client.py    # Supabase client
    ├── static_map_client.py  # Google Maps Static API client
    └── elevation_client.py   # Google Maps Elevation API client
```

### Testing

Run the service and test endpoints:

```bash
# Health check
curl http://localhost:5200/health

# Service info
curl http://localhost:5200/
```

## Authentication

Most endpoints support optional authentication. Include JWT token in Authorization header:

```bash
curl -X POST http://localhost:5200/api/maps/static \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"center_lat": 37.7749, "center_lng": -122.4194}'
```

## Contributing

Follow the existing code structure and patterns from activity-backend and community-backend.

## License

Part of the Syntrak Application project.
