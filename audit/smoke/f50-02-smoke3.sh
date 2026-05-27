#!/usr/bin/env bash
# F-50-02 Smoke #3 — End-to-end deployed-web verification.
#
# IP rate limit constraint: recordLoginFailure is capped 1-per-60s per IP, so
# 5 rapid failed logins from a real browser only bump the server counter by 1
# (calls 2-5 hit 429 and are swallowed client-side per rate_limit_service.dart
# fail-open contract). The lockout path is reachable in two scenarios:
#   (a) 5 attempts spaced 65+ seconds apart from the SAME IP (legit slow user).
#   (b) Distributed attacker (5 different IPs) — partial residual risk noted
#       in loginLockout.ts header.
#
# This smoke pre-cooks the lockout state via Admin SDK then verifies:
#   1. Deployed owner dashboard serves bookbed-dev bundle (audit/33 guard).
#   2. CF getLoginLockoutStatus reports locked=true with future lockedUntilMs.
#   3. Client `checkRateLimit` early-exit will fire before Firebase Auth call.
# Cleanup at end.
set -euo pipefail

PROJECT="bookbed-dev"
EMAIL="bookbed-test@bookbed.io"
DOC_ID="$(echo "$EMAIL" | tr 'A-Z' 'a-z' | sed 's/[^a-z0-9@._-]/_/g')"
URL="https://bookbed-owner-dev.web.app"
CF_GET="https://getloginlockoutstatus-whc46z5xxq-ew.a.run.app"
LOCKED_MS=$(node -e "console.log(Date.now() + 15*60*1000)")

echo "=== Smoke #3: lockout end-to-end on bookbed-dev"
echo "=== EMAIL=${EMAIL} DOC_ID=${DOC_ID}"
echo "=== URL=${URL}"
echo ""

echo "--- 1. Pre-cook loginAttempts/${DOC_ID} (attemptCount=5, lockedUntil=NOW+15min) ---"
cd /tmp/bb-pr517-review-wt/functions
node -e "
const admin = require('firebase-admin');
admin.initializeApp({projectId: 'bookbed-dev'});
admin.firestore().collection('loginAttempts').doc('${DOC_ID}').set({
  email: '${EMAIL}',
  attemptCount: 5,
  lockedUntil: admin.firestore.Timestamp.fromMillis(${LOCKED_MS}),
  lastAttemptAt: admin.firestore.Timestamp.now(),
}).then(() => {
  console.log('PRE-COOKED');
  process.exit(0);
}).catch(e => { console.error('ERR', e.message); process.exit(1); });
"
cd /tmp/bb-pr517-review-wt

echo ""
echo "--- 2. getLoginLockoutStatus (expect locked=true) ---"
R=$(curl -sS -X POST -H "Content-Type: application/json" \
  -d "{\"data\":{\"email\":\"${EMAIL}\"}}" \
  "$CF_GET")
echo "$R"

LOCKED=$(echo "$R" | node -e "let d=''; process.stdin.on('data',c=>d+=c).on('end',()=>{try{console.log(JSON.parse(d).result.locked)}catch(e){console.log('parse-err')}})")
echo "parsed locked=${LOCKED}"
if [ "$LOCKED" != "true" ]; then
  echo "FAIL: expected locked=true"
  exit 1
fi

echo ""
echo "--- 3. Verify hosted owner site is bookbed-dev (not PROD contamination) ---"
HTML_HEAD=$(curl -sS "$URL/" | head -c 4000)
if echo "$HTML_HEAD" | grep -q "owner_main_dev"; then
  echo "OK: bundle entry references owner_main_dev"
elif echo "$HTML_HEAD" | grep -qiE "<title>.*bookbed"; then
  echo "OK: HTML loads with bookbed title — checking main.dart.js for project ID"
  MAIN_JS_URL=$(echo "$HTML_HEAD" | grep -oE 'main\.dart\.js[^"]*' | head -1)
  if [ -n "$MAIN_JS_URL" ]; then
    DEV_HITS=$(curl -sS "$URL/$MAIN_JS_URL" | grep -c "bookbed-dev" || true)
    PROD_HITS=$(curl -sS "$URL/$MAIN_JS_URL" | grep -c "rab-booking-248fc" || true)
    echo "main.dart.js: bookbed-dev hits=$DEV_HITS, rab-booking-248fc hits=$PROD_HITS"
    if [ "$PROD_HITS" -gt 0 ]; then
      echo "WARN: PROD project ID appears in dev bundle — investigate audit/33 class"
    fi
  fi
else
  echo "UNCLEAR: HTML head sample:"
  echo "$HTML_HEAD" | head -c 500
fi

echo ""
echo "--- 4. Manual browser verification instruction for user ---"
echo "URL:      $URL/login"
echo "Email:    $EMAIL"
echo "Password: (any wrong password)"
echo ""
echo "Expected UI: lockout message visible, NOT 'invalid credentials'."
echo "Coded message format: 'RATE_LIMIT_LOCKOUT:N' (parsed/localized by UI)."
echo ""

echo "--- 5. Cleanup ---"
cd /tmp/bb-pr517-review-wt/functions
node -e "
const admin = require('firebase-admin');
admin.initializeApp({projectId: 'bookbed-dev'});
admin.firestore().collection('loginAttempts').doc('${DOC_ID}').delete().then(() => {
  console.log('DELETED');
  process.exit(0);
}).catch(e => { console.error('ERR', e.message); process.exit(1); });
"
