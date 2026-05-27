#!/usr/bin/env bash
# F-50-02 Smoke #2 — Rules deployed.
# Verifies: anon direct write to loginAttempts/{email} returns PERMISSION_DENIED (was open pre-fix).
set -euo pipefail

PROJECT="bookbed-dev"
TS="$(date +%s)"
EMAIL="f50rules-${TS}@bookbed-dev.invalid"
DOC_ID="$(echo "$EMAIL" | tr 'A-Z' 'a-z' | sed 's/[^a-z0-9@._-]/_/g')"

echo "=== Anon direct Firestore write attempt (expect 403/permission-denied) ==="
echo "=== EMAIL=${EMAIL} DOC_ID=${DOC_ID}"
echo ""

# Firestore REST API: PATCH (create-or-update) without auth header.
# Pre-fix this would 200; post-fix must 403.
HTTP_CODE=$(curl -sS -o /tmp/f50-smoke2-body.json -w "%{http_code}" \
  -X PATCH \
  -H "Content-Type: application/json" \
  -d "{
    \"fields\": {
      \"email\": {\"stringValue\": \"${EMAIL}\"},
      \"attemptCount\": {\"integerValue\": 99},
      \"lockedUntil\": {\"timestampValue\": \"2099-12-31T23:59:59Z\"}
    }
  }" \
  "https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents/loginAttempts/${DOC_ID}")

echo "HTTP_CODE=${HTTP_CODE}"
echo "BODY:"
cat /tmp/f50-smoke2-body.json
echo ""

if [ "$HTTP_CODE" = "403" ] || [ "$HTTP_CODE" = "401" ]; then
  echo "RESULT: PASS — anon write denied"
elif [ "$HTTP_CODE" = "200" ]; then
  echo "RESULT: FAIL — anon write SUCCEEDED, rules not enforcing"
  exit 1
else
  echo "RESULT: UNCLEAR — got HTTP ${HTTP_CODE}"
  exit 2
fi
