# audit/53 — PROD Stripe live key leaked via Secret Manager NAME

**Date discovered:** 2026-05-26
**Date created (the bad secret):** 2025-12-21T09:24:19Z
**Severity:** P0 — credential structure leak (recovery non-trivial, well above zero)
**Project:** `rab-booking-248fc` (PROD only — `bookbed-dev` clean, no analog)
**Tracker:** SF-051 (SF-050 taken by concurrent F-50-02 server-side lockout fix)

## Summary

PROD Secret Manager contains a `firebase-managed: functions` secret whose **NAME** encodes a sanitized/uppercased form of a Stripe live secret key VALUE. The secret value is identical (by sha256) to the proper-named `STRIPE_SECRET_KEY` secret (same key, two names). No Cloud Function binds the leaky-named secret — it is a dangling duplicate from a one-off deploy or CLI invocation on 2025-12-21.

The NAME has been visible since 2025-12-21 to anyone with `roles/secretmanager.viewer` (or broader) via:

- `gcloud secrets list --project=rab-booking-248fc`
- Cloud Console → Secret Manager UI
- IAM diagnostic tooling
- Audit log surfaces for any `ListSecrets` / `GetSecret` request

**5+ months of exposure.** Treat the underlying Stripe live key as compromised.

## The artifact

| Field | Value |
|---|---|
| Secret name (123 chars) | `SK_LIVE_51SIS_GK_BOM_KO7V_DR04K3ETG_XGDTZ_T7T_O8BAS5G_IS8QS5L_ANPY_P2FFND_HM5BT7D_ONBEFBY_LLTE12Z7APE_OH0RH_S11M00A_LD9VEX1` |
| Value (verified, sha256 prefix) | `sk_live_51SIsGkBomKO...` (len=107, sha256 `d01c8773fd31d243...`) |
| Proper-named `STRIPE_SECRET_KEY` (sha256) | `d01c8773fd31d243...` ← **identical value** |
| CF bindings | **zero** (us-central1 + europe-west1 — no `serviceConfig.secretEnvironmentVariables` references) |
| Label | `firebase-managed: functions` (created by `defineSecret()` codepath at deploy) |
| Created | 2025-12-21T09:24:19Z |

## Why the NAME is a leak

Pattern: `name = uppercase(value)` with `_` inserted at CamelCase boundaries. Example mapping:

```
value: sk_live_51SIsGkBomKO7vDR04...
name:  SK_LIVE_51SIS_GK_BOM_KO7V_DR04...
```

Case ambiguity within each word means a NAME-only attacker doesn't get the exact key in one shot — `51SIs` / `51SiS` / `51siS` / `51SIS` are all consistent with `51SIS_`. Recovery cost: enumerate plausible case-permutations and probe Stripe API. Rate-limited but feasible for a determined actor in possession of the NAME and any Stripe live customer's public profile to test against.

This is **credential-structure leak**, not full disclosure. Plan accordingly.

## Root cause (low confidence)

Suspect operation that created the bad secret on 2025-12-21T09:24Z:

- `firebase functions:secrets:set <KEY_VALUE>` (passing the VALUE as the symbolic NAME argument). Firebase sanitizes the literal to match Secret Manager regex `[a-zA-Z][a-zA-Z0-9_-]*` — likely uppercases lowercase letters and replaces non-alphanumeric (incl. internal `:`/`-` if any) with `_`. Result: a secret whose name is a transformation of the literal key.
- Or: a one-off `gcloud secrets create <KEY_VALUE>` with the same misuse.
- Or: removed code that called `defineSecret('<KEY_VALUE>')` from a stripe-related script. (Current code at `functions/src/stripe.ts:12` + `functions/src/stripePayment.ts:35` correctly uses symbolic names — no such literal in HEAD.)

Commit `09fd74fe feat(stripe): Complete Stripe Live payment integration & fixes` landed 22 min AFTER secret creation, so it's adjacent but NOT proven causal. Operator should consult shell history and `firebase deploy` logs for 2025-12-21 09:00-10:00Z to confirm.

## Remediation sequence

Order matters: leaky secret is **unbound**, so deletion is safe-first; rotation is still required because the NAME has been visible for 5 months.

### 1. Delete the leaky secret (operator)

Important: `~/.claude/settings.json` PreToolUse hook blocks `gcloud secrets delete` CLI for agent sessions. Operator must use one of:

- **Cloud Console:** Project → Secret Manager → select the SK_LIVE_... secret → Delete.
- **REST API** (works with ADC):
  ```bash
  TOKEN=$(gcloud auth print-access-token)
  curl -s -X DELETE -H "Authorization: Bearer $TOKEN" \
    "https://secretmanager.googleapis.com/v1/projects/rab-booking-248fc/secrets/SK_LIVE_51SIS_GK_BOM_KO7V_DR04K3ETG_XGDTZ_T7T_O8BAS5G_IS8QS5L_ANPY_P2FFND_HM5BT7D_ONBEFBY_LLTE12Z7APE_OH0RH_S11M00A_LD9VEX1"
  ```

Because no CF binds it, no redeploy needed.

### 2. Rotate Stripe live key (operator)

- Stripe Dashboard → Developers → API Keys → Roll secret key.
- Note: rolling does NOT immediately invalidate the old key — Stripe gives a 12h grace window. Update PROD CFs (step 3-4) BEFORE the grace expires.

### 3. Update proper-named `STRIPE_SECRET_KEY` secret (operator)

```bash
# REST equivalent — agent CLI blocked
TOKEN=$(gcloud auth print-access-token)
PAYLOAD=$(echo -n "<new_sk_live_value>" | base64)
curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d "{\"payload\":{\"data\":\"$PAYLOAD\"}}" \
  "https://secretmanager.googleapis.com/v1/projects/rab-booking-248fc/secrets/STRIPE_SECRET_KEY:addVersion"
```

### 4. Redeploy CFs that bind `STRIPE_SECRET_KEY` (operator)

Confirm new version is picked up. CFs that bind via `version: 2` (pinned) need redeploy with `version: latest` or new pinned version. Functions Gen 2 instances cache prior secret values until cold start.

CFs binding `STRIPE_SECRET_KEY` (from `gcloud functions list ... --format="value(name,serviceConfig.secretEnvironmentVariables)"` on PROD): expect `createStripeCheckoutSession`, `createStripeConnectAccount`, `disconnectStripeAccount`, `getStripeAccountStatus`, `getBookingByStripeSession`, `cleanupExpiredStripePendingBookings`, `guestCancelBooking`, `handleStripeWebhook`. Enumerate before redeploy.

### 5. Access-log scan since 2025-12-21 (operator)

```bash
gcloud logging read \
  'protoPayload.methodName=~"AccessSecretVersion" AND protoPayload.resourceName=~"SK_LIVE_51SIS"' \
  --project=rab-booking-248fc \
  --freshness=180d --format=json | python3 -c "
import json, sys
for e in json.load(sys.stdin):
  pp = e.get('protoPayload', {})
  ai = pp.get('authenticationInfo', {})
  print(e.get('timestamp','')[:19], ai.get('principalEmail',''), pp.get('methodName',''))
"
```

Note: Secret Manager metadata listing (`ListSecrets`) is also logged — also scan for `methodName=~"ListSecrets"` to catch principals who simply enumerated names without accessing the value.

### 6. IAM audit on `roles/secretmanager.viewer` (operator)

```bash
gcloud projects get-iam-policy rab-booking-248fc \
  --format=json | python3 -c "
import json, sys
data = json.load(sys.stdin)
roles_of_interest = {'roles/secretmanager.viewer', 'roles/secretmanager.admin', 'roles/secretmanager.secretAccessor', 'roles/owner', 'roles/editor', 'roles/viewer'}
for b in data.get('bindings', []):
  if b['role'] in roles_of_interest:
    print(b['role'], '->', ', '.join(b['members']))
"
```

Triage anyone non-staff or non-current.

## Prevention (separate PR)

Two complementary controls:

### A. Lint / CI rule (cheap, prevents future)

Add to `tool/pre-deploy-checks.sh` (or equivalent CI guard):

```bash
# Reject defineSecret(/sk_test_|sk_live_|pk_test_|pk_live_|whsec_|re_/) literal patterns
if grep -rE "defineSecret\(['\"](sk_test_|sk_live_|pk_test_|pk_live_|whsec_|re_)" functions/src; then
  echo "FATAL: defineSecret() called with literal credential value — use symbolic name"
  exit 1
fi
```

### B. Periodic secret-name scan (durable)

New scheduled `secretNameSanityScan` Cloud Function (weekly), enumerates all secret names in both projects, regex-matches credential-shaped names (`SK_LIVE_`, `SK_TEST_`, `WHSEC_`, etc.), alerts via existing Sentry/email path. Companion to the pre-smoke value-placeholder check from SF-049.

## Verification — what was checked during audit

| Check | Method | Outcome |
|---|---|---|
| Secret exists on PROD | `secretmanager.secrets.get` via REST | ✅ confirmed |
| Secret has `firebase-managed: functions` label | metadata REST | ✅ |
| Value is real `sk_live_*` (not placeholder) | classifier function | ✅ |
| Value identity vs proper `STRIPE_SECRET_KEY` | sha256(value) compare | ✅ same hash |
| CF bindings | `gcloud functions list ... --format=json` filter on `secretEnvironmentVariables.secret` | ✅ zero in us-central1, zero in europe-west1 |
| dev analog | same scan on `bookbed-dev` | ✅ no analog (5 firebase-managed secrets all proper-named) |
| Other env analog | (not scanned — `bookbed-staging` worth checking) | ⚠️ TODO |

## Cross-references

- `memory/prod-stripe-key-leaked-via-secret-name-2025-12-21.md` (durable agent memory)
- `memory/ios-smoke-2026-05-26.md` (initial smoke trail that led here; F-2 misdiagnosis corrected)
- `memory/bookbed-dev-stripe-webhook-secret-placeholder.md` (sister class — different placeholder bug on dev webhook secret)
- SF-049 (dev-only webhook placeholder)
- SF-051 (this finding — `docs/SECURITY_FIXES.md`)
- Commit `09fd74fe` (adjacent in time, not proven causal)

## Open items (operator follow-up)

- [ ] Execute 6-step remediation sequence above
- [ ] Scan `bookbed-staging` for analogous leak (not done in this audit)
- [ ] Land lint/CI guard A
- [ ] Plan secret-name scan CF (control B)
- [ ] Once delete + rotation done, mark SF-051 closed and append "Closed" section here
