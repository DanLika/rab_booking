#!/usr/bin/env bash
# F-50-02 Smoke #1 — CFs deployed, rules NOT yet deployed.
# Verifies: recordLoginFailure callable creates loginAttempts/{email} doc + IP rate limit fires.
set -euo pipefail

PROJECT="bookbed-dev"
TS="$(date +%s)"
EMAIL="f50smoke-${TS}@bookbed-dev.invalid"
DOC_ID="$(echo "$EMAIL" | tr 'A-Z' 'a-z' | sed 's/[^a-z0-9@._-]/_/g')"

# Cloud Run direct URLs (Gen2 onCall — allUsers invoker, no auth header).
CF_REC="https://recordloginfailure-whc46z5xxq-ew.a.run.app"
CF_GET="https://getloginlockoutstatus-whc46z5xxq-ew.a.run.app"

echo "=== EMAIL=${EMAIL}"
echo "=== DOC_ID=${DOC_ID}"
echo ""

call_callable () {
  local url="$1"; local payload="$2"
  curl -sS -X POST \
    -H "Content-Type: application/json" \
    -d "${payload}" \
    "$url"
}

echo "--- Call #1: recordLoginFailure (expect 200 + attemptCount:1) ---"
R1=$(call_callable "$CF_REC" "{\"data\":{\"email\":\"${EMAIL}\"}}")
echo "$R1"
echo ""

echo "--- Call #2 (immediate): recordLoginFailure (expect 429 resource-exhausted) ---"
R2=$(call_callable "$CF_REC" "{\"data\":{\"email\":\"${EMAIL}\"}}")
echo "$R2"
echo ""

echo "--- getLoginLockoutStatus (expect attemptCount:1) ---"
R3=$(call_callable "$CF_GET" "{\"data\":{\"email\":\"${EMAIL}\"}}")
echo "$R3"
echo ""

echo "--- Firestore doc read via Admin SDK ---"
cd /tmp/bb-pr517-review-wt/functions
node -e "
const admin = require('firebase-admin');
admin.initializeApp({projectId: 'bookbed-dev'});
admin.firestore().collection('loginAttempts').doc('${DOC_ID}').get().then(s => {
  if (!s.exists) { console.log('MISSING'); process.exit(2); }
  const d = s.data();
  console.log(JSON.stringify({
    exists: true,
    email: d.email,
    attemptCount: d.attemptCount,
    lockedUntil: d.lockedUntil ? d.lockedUntil.toDate().toISOString() : null,
    lastAttemptAt: d.lastAttemptAt ? d.lastAttemptAt.toDate().toISOString() : null,
  }, null, 2));
  process.exit(0);
}).catch(e => { console.error('ERR', e.message); process.exit(1); });
"

echo ""
echo "--- Cleanup: delete loginAttempts/${DOC_ID} ---"
node -e "
const admin = require('firebase-admin');
admin.initializeApp({projectId: 'bookbed-dev'});
admin.firestore().collection('loginAttempts').doc('${DOC_ID}').delete().then(() => {
  console.log('DELETED'); process.exit(0);
}).catch(e => { console.error('ERR', e.message); process.exit(1); });
"
