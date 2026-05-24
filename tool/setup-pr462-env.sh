#!/usr/bin/env bash
#
# tool/setup-pr462-env.sh
#
# Operator helper for PR #462 (`hotfix/role-escalation-deploy-unblock`) env prereq.
# Sets ALLOWED_SUBSCRIPTION_PRICE_IDS on bookbed-dev (test mode) + rab-booking-248fc
# (live mode) so that post-merge CF deploy does not fall into deny-all (fail-CLOSED).
#
# Reference: audit/38-pr462-env-prereq.md
# Reads (input only): functions/.env, functions/.env.rab-booking-248fc
# Writes:             functions/.env (comment-out empty default),
#                     functions/.env.bookbed-dev (CREATE),
#                     functions/.env.rab-booking-248fc (APPEND or UPDATE)
#
# Run from repo root: tool/setup-pr462-env.sh
# Use bash 3+ (macOS default). No external deps beyond grep, sed, awk.

set -euo pipefail

# --- helpers ---

red()    { printf "\033[31m%s\033[0m\n" "$*" >&2; }
green()  { printf "\033[32m%s\033[0m\n" "$*"; }
yellow() { printf "\033[33m%s\033[0m\n" "$*"; }
bold()   { printf "\033[1m%s\033[0m\n" "$*"; }

die() { red "ERROR: $*"; exit 1; }

confirm() {
  local prompt="${1:-Proceed?}"
  local reply
  read -r -p "$prompt [y/N] " reply
  case "$reply" in
    [yY]|[yY][eE][sS]) return 0 ;;
    *) return 1 ;;
  esac
}

validate_price_id() {
  # Stripe Price IDs: 'price_' + 24+ url-safe chars
  local id="$1"
  if ! printf "%s" "$id" | grep -qE '^price_[A-Za-z0-9]{14,}$'; then
    return 1
  fi
  return 0
}

# Parse comma-separated input → validate each → echo trimmed CSV or die
parse_and_validate_csv() {
  local raw="$1"
  local label="$2"
  local out=""
  local first=1
  local id
  IFS=',' read -r -a arr <<< "$raw"
  for id in "${arr[@]}"; do
    id="$(printf "%s" "$id" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    [ -z "$id" ] && continue
    if ! validate_price_id "$id"; then
      die "$label — invalid Price ID format: '$id' (expected 'price_' + alphanumeric, 20+ chars)"
    fi
    if [ "$first" -eq 1 ]; then
      out="$id"
      first=0
    else
      out="$out,$id"
    fi
  done
  if [ -z "$out" ]; then
    die "$label — no valid Price IDs supplied"
  fi
  printf "%s" "$out"
}

mask_csv() {
  # For confirmation display: mask middle of each Price ID.
  local csv="$1"
  local id masked first=1
  local result=""
  IFS=',' read -r -a arr <<< "$csv"
  for id in "${arr[@]}"; do
    if [ "${#id}" -ge 12 ]; then
      masked="${id:0:8}****${id: -4}"
    else
      masked="${id:0:4}****"
    fi
    if [ "$first" -eq 1 ]; then
      result="$masked"
      first=0
    else
      result="$result,$masked"
    fi
  done
  printf "%s" "$result"
}

# --- pre-flight ---

if [ ! -f functions/.env ]; then
  die "Not at repo root (functions/.env not found). cd to repo root and re-run."
fi

if [ ! -d functions ]; then
  die "functions/ directory missing — wrong working dir?"
fi

bold "PR #462 env setup — ALLOWED_SUBSCRIPTION_PRICE_IDS"
echo "Repo: $(pwd)"
echo "Branch: $(git branch --show-current 2>/dev/null || echo '(detached)')"
echo
yellow "Read audit/38-pr462-env-prereq.md FIRST if you haven't already."
echo
if ! confirm "Continue?"; then
  echo "Aborted."
  exit 0
fi

# --- inspect current state ---

echo
bold "Current state:"
if grep -qE '^ALLOWED_SUBSCRIPTION_PRICE_IDS=' functions/.env; then
  current_value="$(grep -E '^ALLOWED_SUBSCRIPTION_PRICE_IDS=' functions/.env | head -1 | sed 's/^[^=]*=//')"
  if [ -z "$current_value" ]; then
    echo "  functions/.env:           ALLOWED_SUBSCRIPTION_PRICE_IDS= (empty — will be commented out)"
  else
    echo "  functions/.env:           ALLOWED_SUBSCRIPTION_PRICE_IDS=$(mask_csv "$current_value")"
    yellow "  Non-empty value in shared .env — review manually. Proceeding anyway."
  fi
else
  echo "  functions/.env:           (key absent)"
fi

if [ -f functions/.env.bookbed-dev ]; then
  if grep -qE '^ALLOWED_SUBSCRIPTION_PRICE_IDS=' functions/.env.bookbed-dev; then
    yellow "  functions/.env.bookbed-dev: file exists AND has ALLOWED_SUBSCRIPTION_PRICE_IDS already set."
    yellow "  Backup will be created at functions/.env.bookbed-dev.bak"
  else
    echo "  functions/.env.bookbed-dev: file exists (no ALLOWED_* line; will append)"
  fi
else
  echo "  functions/.env.bookbed-dev: (does not exist — will create)"
fi

if [ -f functions/.env.rab-booking-248fc ]; then
  if grep -qE '^ALLOWED_SUBSCRIPTION_PRICE_IDS=' functions/.env.rab-booking-248fc; then
    yellow "  functions/.env.rab-booking-248fc: ALLOWED_SUBSCRIPTION_PRICE_IDS already present."
    yellow "  Existing line will be replaced (backup to .bak)."
  else
    echo "  functions/.env.rab-booking-248fc: exists (no ALLOWED_* line; will append)"
  fi
else
  yellow "  functions/.env.rab-booking-248fc: (does not exist — will create)"
fi
echo

# --- gather inputs ---

bold "Step 1 — Test mode Price IDs (Stripe Dashboard → Test mode → Products)"
echo "Paste comma-separated price IDs for bookbed-dev (e.g. price_xxxTESTmonthly,price_xxxTESTyearly):"
read -r raw_dev
DEV_CSV="$(parse_and_validate_csv "$raw_dev" "dev")"
echo "  ✓ Validated: $(mask_csv "$DEV_CSV")"
echo

bold "Step 2 — Live mode Price IDs (Stripe Dashboard → Live mode → Products)"
echo "Paste comma-separated price IDs for rab-booking-248fc (e.g. price_xxxLIVEmonthly,price_xxxLIVEyearly):"
read -r raw_prod
PROD_CSV="$(parse_and_validate_csv "$raw_prod" "prod")"
echo "  ✓ Validated: $(mask_csv "$PROD_CSV")"
echo

# --- safety check: ensure test ≠ live overlap ---

dev_first="$(printf "%s" "$DEV_CSV" | awk -F, '{print $1}')"
case ",$PROD_CSV," in
  *",$dev_first,"*)
    red "DANGER: A test-mode ID ($dev_first) appears in the LIVE list."
    red "This usually means cross-contamination. Stripe test/live are separate accounts."
    die "Aborting. Verify which Dashboard you copied each from."
    ;;
esac

# --- confirmation ---

bold "Plan:"
echo "  Dev (.env.bookbed-dev)         ← $(mask_csv "$DEV_CSV")"
echo "  Prod (.env.rab-booking-248fc)  ← $(mask_csv "$PROD_CSV")"
echo "  Shared (.env)                  ← comment out empty default"
echo
if ! confirm "Apply these changes?"; then
  echo "Aborted. No files modified."
  exit 0
fi

# --- apply: dev ---

DEV_ENV="functions/.env.bookbed-dev"
if [ -f "$DEV_ENV" ]; then
  cp "$DEV_ENV" "$DEV_ENV.bak"
  # Remove any existing ALLOWED_* line, then append
  awk '!/^ALLOWED_SUBSCRIPTION_PRICE_IDS=/' "$DEV_ENV.bak" > "$DEV_ENV"
  printf "ALLOWED_SUBSCRIPTION_PRICE_IDS=%s\n" "$DEV_CSV" >> "$DEV_ENV"
  green "  ✓ Updated $DEV_ENV (backup: $DEV_ENV.bak)"
else
  cat > "$DEV_ENV" <<EOF
# Per-environment overrides for Firebase Functions on bookbed-dev.
# This file is gitignored. Each developer maintains their own copy.
# See audit/38-pr462-env-prereq.md for context.

ALLOWED_SUBSCRIPTION_PRICE_IDS=$DEV_CSV
EOF
  green "  ✓ Created $DEV_ENV"
fi

# --- apply: prod ---

PROD_ENV="functions/.env.rab-booking-248fc"
if [ -f "$PROD_ENV" ]; then
  cp "$PROD_ENV" "$PROD_ENV.bak"
  awk '!/^ALLOWED_SUBSCRIPTION_PRICE_IDS=/' "$PROD_ENV.bak" > "$PROD_ENV"
  printf "ALLOWED_SUBSCRIPTION_PRICE_IDS=%s\n" "$PROD_CSV" >> "$PROD_ENV"
  green "  ✓ Updated $PROD_ENV (backup: $PROD_ENV.bak)"
else
  cat > "$PROD_ENV" <<EOF
# Per-environment overrides for Firebase Functions on rab-booking-248fc (PROD).
# This file is gitignored. Only operators with prod deploy rights edit this.
# See audit/38-pr462-env-prereq.md for context.

ALLOWED_SUBSCRIPTION_PRICE_IDS=$PROD_CSV
EOF
  green "  ✓ Created $PROD_ENV"
fi

# --- apply: shared .env hygiene ---

if grep -qE '^ALLOWED_SUBSCRIPTION_PRICE_IDS=$' functions/.env; then
  cp functions/.env functions/.env.bak
  # macOS BSD sed: -i requires backup arg
  sed -i.tmp 's|^ALLOWED_SUBSCRIPTION_PRICE_IDS=$|# ALLOWED_SUBSCRIPTION_PRICE_IDS intentionally per-env; see .env.<projectId>|' functions/.env
  rm -f functions/.env.tmp
  green "  ✓ Commented out empty default in functions/.env (backup: functions/.env.bak)"
elif grep -qE '^ALLOWED_SUBSCRIPTION_PRICE_IDS=' functions/.env; then
  yellow "  ⚠ functions/.env has a non-empty ALLOWED_SUBSCRIPTION_PRICE_IDS — left untouched. Review manually."
else
  echo "  · functions/.env has no ALLOWED_* line; nothing to comment out."
fi

# --- final summary ---

echo
bold "✓ Done. Next steps:"
cat <<'EOF'

  1. Smoke local: cd functions && npm run build  → expect 0 errors

  2. Deploy DEV first (soak):
       cd functions
       npm run deploy --project bookbed-dev

  3. Smoke DEV (replace <id-token>):
       # Valid priceId — expect 200 with checkout URL
       curl -X POST \
         https://europe-west1-bookbed-dev.cloudfunctions.net/createSubscriptionCheckoutSession \
         -H "Authorization: Bearer <id-token>" \
         -H "Content-Type: application/json" \
         -d '{"data":{"priceId":"<your-test-priceId>","returnUrl":"https://example.com"}}'

       # Bogus priceId — expect 400 invalid-argument "Price not allowed."
       curl ... -d '{"data":{"priceId":"price_invalid","returnUrl":"..."}}'

       # Also verify logs:
       gcloud functions logs read createSubscriptionCheckoutSession \
         --project=bookbed-dev --region=europe-west1 --limit=20

  4. If DEV smoke passes → merge PR #462 → deploy PROD:
       cd functions
       npm run deploy --project rab-booking-248fc

  5. Smoke PROD (same curl as DEV with prod hostname + a real test customer).

  Rollback: restore .bak files; redeploy. Or `git checkout functions/.env`
  (since .env.<projectId> files are gitignored, they persist regardless).

EOF

green "Setup complete. Backups left at functions/.env*.bak — delete after successful PROD smoke."
