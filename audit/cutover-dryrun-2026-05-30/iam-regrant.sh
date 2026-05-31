#!/usr/bin/env bash
# Defensive allUsers/invoker re-grant for public callables on bookbed-dev
# Runs after firebase deploy --only functions.
# Idempotent: gcloud add-iam-policy-binding is a no-op if binding exists.

set -uo pipefail

PROJECT=bookbed-dev

USC1=(
  createbookingatomic createownerbookingatomic createstripecheckoutsession
  createsubscriptioncheckoutsession createstripeconnectaccount
  createcustomerportalsession disconnectstripeaccount getstripeaccountstatus
  checksubdomainavailability generatesubdomainfromname setpropertysubdomain
  guestcancelbooking updatebookingatomic updatebookingtokenexpiration
  verifybookingaccess getbookingbystripesession resendbookingemail
  resendguestbookingemail sendcustomemailtoguest sendemailverificationcode
  checkemailverificationstatus verifyemailcode sendpasswordresetemail
  syncicalfeednow getuniticalfeed handlestripewebhook createownerbookingatomic
)

EUW1=(
  getunitavailability recordloginfailure getloginlockoutstatus
  clearloginattempts deleteuseraccount getclientgeolocation
  approvebooking rejectbooking cancelbooking completebooking
  revokeallrefreshtokens checkpasswordhistory savepasswordtohistory
  checkloginratelimit checkregistrationratelimit
)

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
    else
      echo "ERR $region/$svc rc=$rc: $out"
    fi
  done
}

echo "T_REGRANT_START=$(date -u +%FT%TZ)"
re_grant us-central1 "${USC1[@]}"
re_grant europe-west1 "${EUW1[@]}"
echo "T_REGRANT_END=$(date -u +%FT%TZ)"
