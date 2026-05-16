#!/usr/bin/env bash
set -euo pipefail

# Scan tracked files for common high-risk secret patterns before commit/push.
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if ! command -v git >/dev/null 2>&1; then
  echo "Error: git is required to run this check."
  exit 2
fi

SEARCH_TOOL=""
if command -v rg >/dev/null 2>&1; then
  SEARCH_TOOL="rg"
elif command -v grep >/dev/null 2>&1; then
  SEARCH_TOOL="grep"
else
  echo "Error: neither ripgrep (rg) nor grep is available."
  exit 2
fi

TRACKED_FILES=()
while IFS= read -r file; do
  TRACKED_FILES+=("$file")
done <<EOF
$(git -C "$ROOT_DIR" ls-files)
EOF

if [[ ${#TRACKED_FILES[@]} -eq 0 ]]; then
  echo "No tracked files found."
  exit 0
fi

# Exclude env and generated/build folders from scan.
FILTERED_FILES=()
for file in "${TRACKED_FILES[@]}"; do
  case "$file" in
    *.env|*.env.*|*.pem|*.key|*.p12|*.jks|*.keystore)
      continue
      ;;
    frontend/build/*|frontend/ios/Pods/*|frontend/ios/Runner.xcworkspace/*|frontend/ios/Runner.xcodeproj/*)
      continue
      ;;
  esac
  FILTERED_FILES+=("$file")
done

if [[ ${#FILTERED_FILES[@]} -eq 0 ]]; then
  echo "No files eligible for scanning."
  exit 0
fi

# Common secrets and key formats.
PATTERNS=(
  "AIzaSy[0-9A-Za-z_-]{33}"
  "eyJ[A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+"
  "(SUPABASE_SERVICE_ROLE_KEY|SECRET_KEY|JWT_SECRET)\\s*=\\s*[^\"'[:space:]]{24,}"
  "(AWS_SECRET_ACCESS_KEY|PRIVATE_KEY|BEGIN[[:space:]]+PRIVATE[[:space:]]+KEY)"
)

FOUND=0
for pattern in "${PATTERNS[@]}"; do
  if [[ "$SEARCH_TOOL" == "rg" ]]; then
    rg -nH --color=never -e "$pattern" "${FILTERED_FILES[@]}" >/tmp/syntrak_secret_hits.txt 2>/dev/null || true
  else
    grep -nH -E "$pattern" "${FILTERED_FILES[@]}" >/tmp/syntrak_secret_hits.txt 2>/dev/null || true
  fi

  if [[ -s /tmp/syntrak_secret_hits.txt ]]; then
    if [[ $FOUND -eq 0 ]]; then
      echo "Potential secrets detected in tracked files:"
      FOUND=1
    fi
    cat /tmp/syntrak_secret_hits.txt
  fi
done

rm -f /tmp/syntrak_secret_hits.txt

if [[ $FOUND -eq 1 ]]; then
  echo
  echo "Action required: remove or rotate exposed credentials before commit/push."
  exit 1
fi

echo "Secret scan passed: no obvious high-risk patterns found in tracked files."
