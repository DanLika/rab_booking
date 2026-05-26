#!/usr/bin/env bash
#
# F-52-03 reopen-trigger guard (audit/52 / SF-037).
#
# Fails if ANY of the following are true:
#
#   1. A new caller of SubscriptionRepository.createCheckoutSession,
#      .createPortalSession, or any consumer of
#      subscriptionRepositoryProvider appears in lib/ outside
#      lib/features/subscription/data/subscription_repository.dart
#      itself (the definition site).
#
#   2. The literal `createSubscriptionCheckoutSession` appears in any
#      lib/ file outside subscription_repository.dart (the dead-code
#      wrapper).
#
#   3. The "coming soon" / "stay tuned" canary text is removed from
#      `_showUpgradeDialog` body in
#      lib/features/subscription/screens/subscription_screen.dart.
#      That dialog is what keeps the web "Upgrade Now" button from
#      hitting the broken Cloud Function — losing the canary means
#      someone wired a real checkout call.
#
# Why: audit/52 demoted F-52-03 (ALLOWED_SUBSCRIPTION_PRICE_IDS empty
# on prod) from P0 → P3 deferred. The demotion rests on structural
# evidence: zero call-graph consumers + canary dialog + 0 Stripe
# products. If any of those changes, the empty allowlist becomes a
# release blocker — operator must run tool/setup-pr462-env.sh and
# remove this guard in the same PR.
#
# Exits:
#   0 — all 3 conditions safe (audit-52 deferral still holds)
#   1 — at least one trigger fires; F-52-03 reopens to P0

set -euo pipefail

LIB_DIR="${LIB_DIR:-lib}"
REPO_FILE="lib/features/subscription/data/subscription_repository.dart"
DIALOG_FILE="lib/features/subscription/screens/subscription_screen.dart"

failed=0

# --- Trigger 1+2: stray callers / new file referencing the callable -------
# Allowlist: the repo definition file itself. Everything else is a real
# call site that must trip the reopen.
STRAY=$(rg -n \
    -e 'subscriptionRepositoryProvider' \
    -e 'createSubscriptionCheckoutSession' \
    -e 'subscriptionRepository\.createCheckoutSession' \
    -e 'subscriptionRepository\.createPortalSession' \
    -e 'SubscriptionRepository\(.*\)\.createCheckoutSession' \
    -e 'SubscriptionRepository\(.*\)\.createPortalSession' \
    "$LIB_DIR" 2>/dev/null \
  | grep -v "^${REPO_FILE}:" || true)

if [ -n "$STRAY" ]; then
    echo "::error::F-52-03 reopen — new caller of SubscriptionRepository found:"
    printf '%s\n' "$STRAY"
    echo
    echo "Fix: provision ALLOWED_SUBSCRIPTION_PRICE_IDS on rab-booking-248fc"
    echo "+ bookbed-dev BEFORE merging this caller. See"
    echo "docs/audits/stripe-credentials-and-flow-52.md § F-52-03."
    failed=1
fi

# --- Trigger 3: canary text removed from _showUpgradeDialog ---------------
# Extract the _showUpgradeDialog function body (20 lines after declaration)
# and look for either inert-state marker. If neither appears, the dialog
# was rewired to a real flow.
if [ -f "$DIALOG_FILE" ]; then
    DIALOG_BODY=$(rg -A20 '_showUpgradeDialog' "$DIALOG_FILE" 2>/dev/null || true)
    if [ -n "$DIALOG_BODY" ]; then
        if ! printf '%s\n' "$DIALOG_BODY" | rg -iq "coming soon|stay tuned"; then
            echo "::error::F-52-03 reopen — canary text removed from"
            echo "_showUpgradeDialog body in $DIALOG_FILE."
            echo
            echo "The dialog was rewired from inert 'coming soon' state to"
            echo "an active flow. Provision ALLOWED_SUBSCRIPTION_PRICE_IDS"
            echo "and remove this guard in the same PR."
            failed=1
        fi
    fi
fi

exit "$failed"
