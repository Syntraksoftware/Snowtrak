# Scripts

Local development utilities. None of these are deployed or run in CI; they are
invoked by hand.

| Script | What it does |
|---|---|
| `check_secrets.sh` | Scan tracked files for credentials before a push |
| `dump_supabase_schema.py` | Regenerate [`docs/database_schema.md`](../docs/database_schema.md) from the live database |
| `set_asc_secrets.sh` | Upload the App Store Connect key and ids as GitHub secrets |

## check_secrets.sh

Greps tracked files for API keys, JWTs and service-role keys. Exit 0 is clean,
exit 1 means review the matches before pushing — UUIDs and method names do
match the patterns sometimes, so read them rather than suppressing the check.

```bash
./scripts/check_secrets.sh
```

## dump_supabase_schema.py

Run it after applying a migration, and commit the refreshed
`docs/database_schema.md` in the same change as the migration.

```bash
.venv/bin/python scripts/dump_supabase_schema.py
```

## set_asc_secrets.sh

Sets `ASC_KEY_BASE64`, `ASC_KEY_ID` and `ASC_ISSUER_ID`, consumed by
[`.github/workflows/ios-testflight.yml`](../.github/workflows/ios-testflight.yml)
and [`frontend/ios/fastlane/Fastfile`](../frontend/ios/fastlane/Fastfile).

```bash
./scripts/set_asc_secrets.sh \
  -k /path/AuthKey_XXXXXXXXXX.p8 \
  -K XXXXXXXXXX \
  -I <issuer-uuid> \
  -R owner/repo
```

## Notifications

`send_notification.sh` and `notification_demo.sh` used to live here. They drove
`/api/v1/notifications/test/*`, a global in-memory queue with no user id and no
auth, which the app polled every two seconds. All of it is gone. In-app
notifications are derived from pending follow requests; see
`frontend/lib/providers/notification_provider.dart`.
