Map Backend — Beta / Internal Testflight Notice

Status: **enabled on staging as of 2026-08-20**

Earlier this document described map-backend as intentionally disabled on
staging. That was true of the Compose file but never of the app: the Flutter
staging flavour builds with `map_features_enabled: true` and points at
`staging-map.syntrak.io`, so "disabled" in practice meant every staging map
call failed on DNS rather than being switched off.

Staging now runs the same four services as production, on port 15200. To
actually disable map features for a beta build, set
`map_features_enabled: false` in the staging lane of
`frontend/ios/fastlane/Fastfile` -- changing the backend alone does not do it.

Remaining setup

- `staging-map.syntrak.io` needs a DNS A record pointing at the droplet.
- `backend/map-backend/.env` must exist in the staging checkout with
  staging-specific credentials. Do not copy production's: the map service
  writes, and pointing staging at the production database is how a test
  corrupts real data.

Notes

- If using Supabase for map storage, set `MAP_STORAGE_BACKEND=supabase` and ensure `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are set in the env file.
- If using PostGIS, enable the PostGIS extension on the target DB and set `POSTGIS_*` values.

Suggested small operational change

- Add a short check in your deployment script to `docker rm -f` any pre-existing map-backend containers when deploying beta, or better, ensure your deployment tooling only brings up services defined in `docker-compose.staging.yml`.
