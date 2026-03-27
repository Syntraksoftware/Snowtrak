# Syntrak Flow Navigation Notes

This folder is a practical onboarding map for the three core end-to-end flows in the current codebase.
For any proposed changes or error spotted, please raise an issue. 
Feel free to contact Matthew Ng via email: ctngah@connect.ust.hk

## Flows

- Auth flow: `doc/auth-flow/README.md`
- Activity flow: `doc/activity-flow/README.md`
- Community flow: `doc/community-flow/README.md`

## How to use this folder

1. Start with auth flow to understand app bootstrap, token lifecycle, and service ownership.
2. Move to activity flow to trace request payload conversion and response formatting.
3. Read community flow to understand route versioning and deprecation behavior.
4. While reading each flow, open the listed files in order and follow one request path from UI/provider to backend route.

## Source of truth rule

When documentation and code differ, treat code as source of truth and update docs afterward.

Primary ownership reference:

- `docs/service-ownership.md`
