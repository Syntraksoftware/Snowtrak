Map Backend — Beta / Internal Testflight Notice

Status: intentionally disabled in Beta (staging)

Purpose

For internal beta / TestFlight builds we intentionally do not run the Map Backend. Map-related features (static map generation, elevation lookup, PostGIS sync) are not required for the beta; disabling the container avoids DNS/DB errors and reduces external API usage.

Behavior

- The map-backend container should not be present or running on staging/beta droplets.
- Monitoring/alerting for the map-backend service should be suppressed for the beta environment to avoid noise.

How to re-enable (staging -> enable map-backend)

`backend/deploy/docker-compose.staging.yml` does not define `map-backend` and
`backend/deploy/Caddyfile.example` gives staging no map host, so the staging
stack does not read `backend/map-backend/.env` at all. These steps are for
standing up a separate map-beta deployment: step 2 is what puts the service in
the stack, and only then does step 1's env file get read.

1. Ensure SYNTRAK_DATABASE_URL in `backend/map-backend/.env` in the staging checkout points to a resolvable and reachable Postgres/Supabase instance.
2. Add the map-backend service to `backend/deploy/docker-compose.staging.yml`, copying the block from `docker-compose.production.yml` and moving the published port into the 15xxx range so it does not collide with production.
3. Restart or start the map-backend container on the droplet:

```bash
# on droplet, in the staging checkout -- not the production one
cd /srv/snowtrak-staging
docker compose -f backend/deploy/docker-compose.staging.yml -p snowtrak-staging up -d map-backend
```

Notes

- If using Supabase for map storage, set `MAP_STORAGE_BACKEND=supabase` and ensure `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are set in the env file.
- If using PostGIS, enable the PostGIS extension on the target DB and set `POSTGIS_*` values.

Suggested small operational change

- Add a short check in your deployment script to `docker rm -f` any pre-existing map-backend containers when deploying beta, or better, ensure your deployment tooling only brings up services defined in `docker-compose.staging.yml`.
