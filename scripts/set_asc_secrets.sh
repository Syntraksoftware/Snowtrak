#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: $0 -k /path/AuthKey_ABC.p8 -K KEY_ID -I ISSUER_ID -R owner/repo [-a APP_IDENTIFIER] [-p PROV_PROFILE_NAME]

Sets GitHub Actions secrets needed for the iOS TestFlight workflow:
  - ASC_KEY_BASE64 (base64-encoded .p8)
  - ASC_KEY_ID
  - ASC_ISSUER_ID
  - APP_IDENTIFIER (optional)
  - PROV_PROFILE_NAME (optional)

Requires `gh` CLI authenticated with permissions to set repo secrets.
EOF
}

KEY_PATH=""
KEY_ID=""
ISSUER_ID=""
REPO=""
APP_IDENTIFIER=""
PROV_PROFILE_NAME=""

while getopts "k:K:I:R:a:p:h" opt; do
  case "$opt" in
    k) KEY_PATH="$OPTARG" ;;
    K) KEY_ID="$OPTARG" ;;
    I) ISSUER_ID="$OPTARG" ;;
    R) REPO="$OPTARG" ;;
    a) APP_IDENTIFIER="$OPTARG" ;;
    p) PROV_PROFILE_NAME="$OPTARG" ;;
    h) usage; exit 0 ;;
    *) usage; exit 1 ;;
  esac
done

if [[ -z "$KEY_PATH" || -z "$KEY_ID" || -z "$ISSUER_ID" || -z "$REPO" ]]; then
  usage
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI not found. Install and authenticate: https://cli.github.com/"
  exit 1
fi

if [[ ! -f "$KEY_PATH" ]]; then
  echo "Key file not found: $KEY_PATH"
  exit 1
fi

echo "Encoding key and uploading secrets to repo: $REPO"

# Base64 encode without newlines
ASC_KEY_BASE64=$(base64 "$KEY_PATH" | tr -d '\n')

echo "Setting ASC_KEY_BASE64..."
gh secret set ASC_KEY_BASE64 --repo "$REPO" --body "$ASC_KEY_BASE64"

echo "Setting ASC_KEY_ID..."
gh secret set ASC_KEY_ID --repo "$REPO" --body "$KEY_ID"

echo "Setting ASC_ISSUER_ID..."
gh secret set ASC_ISSUER_ID --repo "$REPO" --body "$ISSUER_ID"

if [[ -n "$APP_IDENTIFIER" ]]; then
  echo "Setting APP_IDENTIFIER..."
  gh secret set APP_IDENTIFIER --repo "$REPO" --body "$APP_IDENTIFIER"
fi

if [[ -n "$PROV_PROFILE_NAME" ]]; then
  echo "Setting PROV_PROFILE_NAME..."
  gh secret set PROV_PROFILE_NAME --repo "$REPO" --body "$PROV_PROFILE_NAME"
fi

echo "All done. Secrets set for $REPO (ASC_KEY_ID=$KEY_ID)."
