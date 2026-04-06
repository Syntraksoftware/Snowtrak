# Step A Service Boundaries

This folder defines the target package boundaries for splitting map-backend into focused services.

## Target packages

- activities_service: owns activity persistence and retrieval APIs.
- trails_service: owns trail matching and resort GeoJSON APIs.
- elevation_dem_service: owns DEM correction and DEM tile cache logic.
- sync_worker_service: owns OpenSkiMap ingestion jobs.

## Import rules

- Domain packages must not import each other directly.
- Shared contracts must come from backend/shared.
- Database access should go through each domain's own adapter module.
- Do not add sys.path mutation in domain modules.

## Migration map (current -> target)

- backend/routers/activities.py -> domains/activities_service/api.py
- backend/routers/trails.py -> domains/trails_service/api.py
- backend/routers/elevation.py -> domains/elevation_dem_service/api.py
- backend/map-backend/services/dem_service.py -> domains/elevation_dem_service/dem_provider.py
- backend/map-backend/services/openskimap_sync.py -> domains/sync_worker_service/sync_job.py

## Step A scope

Step A is scaffolding only.
No runtime behavior changes should be introduced in this step.
