#!/usr/bin/env bash
# Defensive allUsers/invoker re-grant for PUBLIC v2 onCall callables on rab-booking-248fc (PROD).
# Runs AFTER `firebase deploy --only functions --project rab-booking-248fc`.
#
# Background:
#  - v2 onCall deploys can strip Cloud Run `allUsers/invoker` when `cors:` shape changes
#    between `true` and array/RegExp (see [[cf-deploy-cors-shape-iam-strip]]).
#  - First-deploy of new callables can ship with empty IAM (see [[sf050-prod-iam-gap-2026-05-29]],
#    audit/90 F-90-01 — recordLoginFailure/getLoginLockoutStatus/clearLoginAttempts already
#    affected on PROD).
#  - PR #598 (CORS sweep) + PR #609 (SF-078 17-callable CORS) both changed CORS shape on
#    callables wired with getCorsAllowlist() — landing on PROD HEAD 3a8b6b66 now triggers
#    the strip risk for the full public-callable set.
#
# Idempotency: `gcloud run services add-iam-policy-binding` is a no-op if the binding already
# exists; safe to run multiple times.
#
# Selection criteria for each name below:
#  1. Source declares `cors: getCorsAllowlist()` in its `onCall(...)` config, AND
#  2. Service exists as a Cloud Run service in the listed region on rab-booking-248fc, AND
#  3. The callable does NOT require admin/owner authorization (admin callables are auth-only;
#     widget/guest/public-facing callables need `allUsers`).
#
# NOT INCLUDED (intentional):
#  - onRequest endpoints (`getUnitIcalFeed`, `handleStripeWebhook`) — different IAM model,
#    not affected by onCall `cors:` shape change. Verify separately if smoke shows issues.
#  - Scheduled / Firestore-trigger functions — never need `allUsers`.
#  - Auth-only callables (`createOwnerBookingAtomic`, `updateBookingAtomic`,
#    `setPropertySubdomain`, `generateSubdomainFromName`, admin callables) — must remain
#    auth-required; adding `allUsers` would weaken access control.

set -uo pipefail

PROJECT=rab-booking-248fc

# 20 public callables in us-central1 (legacy region: Stripe, booking, email, iCal, subdomain)
USC1=(
  checksubdomainavailability
  createbookingatomic
  createcustomerportalsession
  createstripecheckoutsession
  createstripeconnectaccount
  createsubscriptioncheckoutsession
  checkemailverificationstatus
  disconnectstripeaccount
  getbookingbystripesession
  getstripeaccountstatus
  guestcancelbooking
  resendbookingemail
  resendguestbookingemail
  sendcustomemailtoguest
  sendemailverificationcode
  sendpasswordresetemail
  syncicalfeednow
  updatebookingtokenexpiration
  verifybookingaccess
  verifyemailcode
)

# 15 public callables in europe-west1 (audit-driven new region: availability, lockout,
# password-history, booking-actions, geolocation, deleteUserAccount, revokeTokens)
EUW1=(
  approvebooking
  cancelbooking
  checkloginratelimit
  checkpasswordhistory
  checkregistrationratelimit
  clearloginattempts
  completebooking
  deleteuseraccount
  getclientgeolocation
  getloginlockoutstatus
  getunitavailability
  recordloginfailure
  rejectbooking
  revokeallrefreshtokens
  savepasswordtohistory
)

OK_COUNT=0
ERR_COUNT=0
ERR_NAMES=()

re_grant() {
  local region=$1; shift
  for svc in "$@"; do
    out=$(gcloud run services add-iam-policy-binding "$svc" \
      --project="$PROJECT" --region="$region" \
      --member=allUsers --role=roles/run.invoker \
      --quiet 2>&1)
    rc=$?
    if [[ $rc -eq 0 ]]; then
      echo "OK  $region/$svc"
      OK_COUNT=$((OK_COUNT + 1))
    else
      echo "ERR $region/$svc rc=$rc"
      echo "    $out" | head -3
      ERR_COUNT=$((ERR_COUNT + 1))
      ERR_NAMES+=("$region/$svc")
    fi
  done
}

echo "T_REGRANT_START=$(date -u +%FT%TZ)"
echo "PROJECT=$PROJECT"
echo "===== us-central1 (${#USC1[@]} callables) ====="
re_grant us-central1 "${USC1[@]}"
echo "===== europe-west1 (${#EUW1[@]} callables) ====="
re_grant europe-west1 "${EUW1[@]}"
echo "T_REGRANT_END=$(date -u +%FT%TZ)"
echo "===== SUMMARY ====="
echo "OK=$OK_COUNT  ERR=$ERR_COUNT  TOTAL=$((OK_COUNT + ERR_COUNT))"
if [[ $ERR_COUNT -gt 0 ]]; then
  echo "FAILED:"
  printf '  %s\n' "${ERR_NAMES[@]}"
  exit 1
fi
echo "All bindings applied. Verify via OPTIONS preflight on a sample callable."
