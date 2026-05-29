# audit/87 — Pre-smoke Secret Manager sanity (SF-049 recipe)

**Date**: 2026-05-29
**Scope**: Secret Manager across all 3 Firebase projects
**Methodology**: `gcloud secrets versions access latest --secret=NAME --project=PROJ` → check format prefix + length + placeholder patterns (`PLACEHOLDER`, `placeholder`, `TODO`, `CHANGEME`). Raw values NEVER printed to context — only `len=N kind=X` summary.

> Background: SF-049 was the dev `STRIPE_WEBHOOK_SECRET = whsec_PLACEHOLDER` finding (27 chars, ~5 months silent failure). Recipe formalized in [bookbed-dev-stripe-webhook-secret-placeholder.md]. This sweep applies it forward.

---

## Results

### bookbed-dev (5 secrets, all OK)

```
OK: ICAL_TOKEN_PEPPER       — len=64  kind=OK_LEN
OK: RESEND_API_KEY          — len=36  kind=OK
OK: SENTRY_DSN              — len=95  kind=OK
OK: STRIPE_SECRET_KEY       — len=107 kind=TEST
OK: STRIPE_WEBHOOK_SECRET   — len=38  kind=OK
```

✅ All format-validated. SF-049 webhook placeholder confirmed remediated.

### rab-booking-248fc PROD (4 secrets + 1 apphosting, all OK)

```
OK: RESEND_API_KEY          — len=36  kind=OK
OK: SENTRY_DSN              — len=95  kind=OK
OK: STRIPE_SECRET_KEY       — len=107 kind=LIVE
OK: STRIPE_WEBHOOK_SECRET   — len=38  kind=OK
SKIP: apphosting-github-conn-pca4v4f-github-oauthtoken-562435 (managed by Firebase/AppHosting)
```

✅ `STRIPE_SECRET_KEY len=107 kind=LIVE` confirms SF-051 v5 rotation healthy (old v4 401-confirmed dead per memory `prod-stripe-key-leaked-via-secret-name-2025-12-21.md`).

### bookbed-staging (4 secrets, all OK)

```
OK: RESEND_API_KEY          — len=36  kind=OK
OK: SENTRY_DSN              — len=95  kind=OK
OK: STRIPE_SECRET_KEY       — len=107 kind=TEST
OK: STRIPE_WEBHOOK_SECRET   — len=38  kind=OK
```

✅ TEST-mode Stripe is appropriate for STAGING.

---

## ❌ Critical gap — missing secrets

### PROD (`rab-booking-248fc`) — MISSING `ICAL_TOKEN_PEPPER`

**Impact**: PR #482 (`hotfix/widget-secrets-exfil`, SF-021 widget_secrets subcollection lockdown) is BLOCKED from merge until this is provisioned.

PR #482 body explicitly lists:
> `- [ ] ICAL_TOKEN_PEPPER env var provisioned in dev + prod — NOT present on main`

Confirmed today (audit/86 sweep): dev has it (len=64), PROD does not.

### STAGING (`bookbed-staging`) — MISSING `ICAL_TOKEN_PEPPER`

Same gap. If STAGING is retained as a pre-PROD gate (see audit/86 note on stale CF deploys), this needs to be provisioned before the SF-021 deploy chain can route through STAGING.

### Provisioning recipe

```bash
# Generate cryptographically random 64-byte hex pepper
openssl rand -hex 32 > /tmp/pepper.txt

# PROD
gcloud secrets create ICAL_TOKEN_PEPPER \
  --project=rab-booking-248fc \
  --data-file=/tmp/pepper.txt \
  --replication-policy=automatic

# STAGING (only if keeping staging in rotation)
gcloud secrets create ICAL_TOKEN_PEPPER \
  --project=bookbed-staging \
  --data-file=/tmp/pepper.txt \
  --replication-policy=automatic

# Bind to CFs via firebase deploy (functions code already references it via defineSecret)
# Then `firebase deploy --only functions:getUnitIcalFeed,functions:icalExport --project=PROJ`

shred -u /tmp/pepper.txt   # macOS: use `rm -P` instead
```

⚠️ Per [memory/widget-secrets-exfil-deploy-prereqs.md], the branch also references `RESEND_API_KEY` (✅ already present) and `ALLOWED_SUBSCRIPTION_PRICE_IDS` (separate env-var class, NOT in Secret Manager — env files). Both confirmed independently of this sweep.

---

## Format reference (what `kind=` means)

| Secret | Expected prefix | Expected len | Validator |
|---|---|---|---|
| `STRIPE_SECRET_KEY` | `sk_live_*` (LIVE) or `sk_test_*` (TEST) or `rk_*` (restricted) | ≥100 | Stripe spec |
| `STRIPE_WEBHOOK_SECRET` | `whsec_*` | ≥32 | Stripe spec |
| `RESEND_API_KEY` | `re_*` | ≥32 | Resend spec |
| `SENTRY_DSN` | `https://*ingest*sentry.io*` | ≥40 | Sentry DSN format |
| `ICAL_TOKEN_PEPPER` | (any) | ≥32 bytes | application-defined |

Sweep flags `BAD:` only on: NOREAD (permission/IAM), EMPTY, placeholder string match, or length-below-min for known types. `WARN:` on unrecognized prefix-format.

---

## Cross-reference

- [memory/bookbed-dev-stripe-webhook-secret-placeholder.md](../memory/bookbed-dev-stripe-webhook-secret-placeholder.md) — SF-049 origin
- [memory/widget-secrets-exfil-deploy-prereqs.md](../memory/widget-secrets-exfil-deploy-prereqs.md) — PR #482 prereq breakdown
- [memory/prod-stripe-key-leaked-via-secret-name-2025-12-21.md](../memory/prod-stripe-key-leaked-via-secret-name-2025-12-21.md) — SF-051 (DEFINITIVE-CLOSED) lineage; rotation v=5 confirmed in this sweep
- [audit/38-pr462-env-prereq.md](./38-pr462-env-prereq.md) — `ALLOWED_SUBSCRIPTION_PRICE_IDS` non-SM env-var class

---

## Sign-off

12 of 13 present secrets (excluding apphosting SKIP) pass sanity. **2 missing across PROD + STAGING (`ICAL_TOKEN_PEPPER`)**. No placeholders, no empties, no truncations. PROD Stripe LIVE rotation healthy.

Next sweep: re-run after `ICAL_TOKEN_PEPPER` provisioning to gate PR #482 merge.
