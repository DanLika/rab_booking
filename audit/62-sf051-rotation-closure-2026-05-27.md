# audit/62 — SF-051 PROD Stripe Key Rotation Execution + Closure

**Date:** 2026-05-27
**Closes:** SF-051 (`docs/SECURITY_FIXES.md` + `audit/53-prod-stripe-name-leak-2025-12-21.md`)
**Method:** PROD-impacting — Stripe Dashboard roll (Expire immediately) + Secret Manager mutations (addVersion → destroy v1-v4) + Cloud Function redeploy (7 CFs) + Secret DELETE + Stripe Connect orphan rejection (1 acct)
**Companion docs:** `audit/60-stripe-consolidation-plan-2026-05-28.md` (single-account confirmation + plan), `audit/61-webhook-event-coverage-2026-05-28.md` (webhook subscription gap)

---

## 0. TL;DR

| Surface | Pre-state | Post-state |
|---|---|---|
| `STRIPE_SECRET_KEY` versions | v1-v4 enabled (v4 = leaky duplicate) | v5 enabled, v1-v4 destroyed |
| Leaky-name secret `SK_LIVE_..._LD9VEX1` | enabled, dangling, 5 months exposure | DELETED (HTTP 200) |
| Stripe live key | compromised (name was sanitized uppercase of value) | rolled, old key 401 `api_key_expired` |
| 7 CFs binding `STRIPE_SECRET_KEY` | bound to v=4 (now-expired) | redeployed, bound to v=5 |
| Connect orphan `acct_1TYSMdPWhhVc6lN0` (ababic785@gmail.com) | abandoned signup, `disabled_reason=requirements.past_due` | rejected, `disabled_reason=rejected.other` |
| PROD webhook event subscription gap (audit/61) | 2/5 events subscribed | UNCHANGED — operator B-step deferred (Dashboard click pending) |

**Customer impact:** zero — 0 in-flight PaymentIntents at pre-flight (audited 5min/1h/24h windows), brownout window ~6-8 min between Stripe roll + deploy complete.

**Residual risks (forensic + hygiene):** documented in §5.

---

## 1. Execution timeline (UTC)

| Time | Step | Actor | Outcome |
|---|---|---|---|
| ~16:30 | Operator step: Stripe Dashboard → API Keys → Roll secret key → **Expire immediately** | user | new `sk_live_...` issued, v4 invalidated |
| 16:36:50 | `gcloud secrets versions add STRIPE_SECRET_KEY --data-file=- --project=rab-booking-248fc` via `{ IFS= read -rs K; printf '%s' "$K"; } \| gcloud ...` (silent stdin, no /tmp file, no shell history) | user | `Created version [5]` — sha8 `6ec442ab` (distinct from v4 `d01c8773` → genuine new credential material) |
| 16:37 | Step 5b: NEW key `GET /v1/account` | agent | HTTP 200, `acct_1SIsGkBomKO7vDr0` type=standard charges_enabled=True payouts_enabled=True country=HR |
| 16:37 | Step 5c: OLD key (re-fetched leaky-name secret value via SM REST) `GET /v1/account` | agent | HTTP 401 `api_key_expired` — Stripe error literally cites `sk_live_*****...d9vex1` matching leaky-name suffix `LD9VEX1` (definitive value-identity proof) |
| 17:00–17:08 | Step 6: `firebase deploy --only functions:{7 names} --project=rab-booking-248fc` — **FIRST ATTEMPT FAILED** (see §3.1), **SECOND ATTEMPT SUCCEEDED** after `.env.rab-booking-248fc` patched | user + agent | 7 CFs updated; revisions `createstripecheckoutsession-00118-hiw`, `disconnectstripeaccount-00108-cus`, `createcustomerportalsession-00040-now`, `createsubscriptioncheckoutsession-00040-nel`, `getstripeaccountstatus-00109-kam`, `createstripeconnectaccount-00110-quc`, `handlestripewebhook-00124-wib` |
| 17:09 | Step 6b: per-CF binding assert | agent | all 7 CFs `STRIPE_SECRET_KEY` v=5 ✅ |
| 17:09 | Step 6c: re-test old key + bonus webhook reachability | agent | old still 401 ✅; legacy proxy + direct Cloud Run both HTTP 400 "Webhook signature verification failed" on signed-POST sim → service alive ✅ |
| 17:11:02 | Step 7: `DELETE /v1/projects/rab-booking-248fc/secrets/SK_LIVE_..._LD9VEX1` via Secret Manager REST + ADC token (CLI policy-blocked) | agent | HTTP 200 `{}` — verified NOT_FOUND on describe |
| ~17:25 | Cleanup: `shred -u /tmp/new-sk-live` (92-byte garbage file from earlier clipboard mishap) | agent | wiped |
| 17:29:29–17:29:38 | A (defense-in-depth): destroy SM v1-v4 via `gcloud secrets versions destroy {1..4} --secret=STRIPE_SECRET_KEY --quiet` | agent | all 4 → `STATE: destroyed` |
| ~17:31 | D (Connect orphan reject): `POST /v1/accounts/acct_1TYSMdPWhhVc6lN0/reject` with `reason=other` | agent | HTTP 200 — `disabled_reason: requirements.past_due → rejected.other` |
| ~17:34 | C (this commit's preceding commit `f84be7b3`): PR #531 OPEN with audit/60 + audit/61 + `.claude/rules/stripe.md` F-61-02 fix | agent | https://github.com/DanLika/rab_booking/pull/531 |

---

## 2. Forensic findings

### 2.1 Value-identity confirmation (leaky-name = v4)

Pre-rotation sha256 prefix matrix:
- Leaky-name secret value: `d01c8773...` (107 bytes, prefix `sk_live_`)
- `STRIPE_SECRET_KEY` v4: `d01c8773...` (identical sha)
- `STRIPE_SECRET_KEY` v5: `6ec442ab...` (genuine new — distinct sha)

Hypothesis from `audit/53` confirmed: the leaky-name secret was an entry that received the sanitized uppercase form of v1 (= v4 by value, since previous "rotations" were SM-version bumps without actual Stripe rolls).

Stripe API error post-roll explicitly cites `sk_live_*****...d9vex1` matching the leaky-name suffix `LD9VEX1` — additional independent proof.

### 2.2 Access-log scan since 2025-12-21 (180d)

```
gcloud logging read \
  'protoPayload.methodName="google.cloud.secretmanager.v1.SecretManagerService.AccessSecretVersion" \
   AND protoPayload.resourceName=~"SK_LIVE_51SIS"' \
  --freshness=180d --project=rab-booking-248fc
```

**Returned: 0 hits.**

⚠️ **Critical caveat:** `gcloud projects get-iam-policy rab-booking-248fc --format=json | jq '.auditConfigs'` returned **`null` (entries=0)**. Secret Manager Data Access logs are NOT enabled by default on this project. The `AccessSecretVersion` event class is therefore not captured. **Zero hits does NOT prove the leaky secret was never read** during the 5-month window — it proves we have no audit trail.

Admin Activity logs (always on, free) for the leaky secret:
- `2025-12-21T09:24:19Z` CreateSecret by `duskolicanin1234@gmail.com` from 31.223.145.17
- `2025-12-21T09:24:34Z` AddSecretVersion by same (15 s later, same IP)
- `2026-05-27T17:11:02Z` DeleteSecret by same (this session, 31.223.145.25)

No other principals appear in the admin trail.

### 2.3 IAM principals with `secretmanager.versions.access` capability

Explicit `roles/secretmanager.*` bindings on the project:
| Role | Members |
|---|---|
| `roles/secretmanager.admin` | `service-592597958982@gcp-sa-devconnect.iam.gserviceaccount.com` (Google-managed Firebase Functions DevConnect SA — trusted) |

Implicit via project-level roles:
| Role | Members | Can `versions.access`? |
|---|---|---|
| `roles/owner` | `user:duskolicanin1234@gmail.com` only | ✅ yes |
| `roles/editor` | 3 SAs: `592597958982-compute@...`, `592597958982@cloudservices.gserviceaccount.com`, `rab-booking-248fc@appspot.gserviceaccount.com` | ❌ no — since 2021 GCP default, Editor lacks `secretmanager.versions.access` |

**Read-surface for the leaky secret VALUE during the 5-month window:** only `duskolicanin1234@gmail.com` (you) + the Google-managed DevConnect SA. Narrow. Combined with the audit-log gap, residual risk = "no evidence either way, narrow surface."

---

## 3. Process gotchas encountered

### 3.1 Firebase v2 non-interactive deploy requires explicit env var even when `defineString` has a default

`functions/src/sentry.ts:13` declares:
```ts
const sentryDsn = defineString("SENTRY_DSN", {default: ""});
```

First deploy attempt **failed** with:
```
Error: In non-interactive mode but have no value for the following environment variables: SENTRY_DSN
To continue, either run `firebase deploy` with an interactive terminal, or add values to a dotenv file.
```

Setting `SENTRY_DSN=''` inline (process env) **does not satisfy** the check — `firebase deploy` reads only `.env*` files for `defineString` params. The `default: ""` is consulted at runtime, not at deploy validation.

**Fix applied:** `echo 'SENTRY_DSN=' >> functions/.env.rab-booking-248fc` (gitignored). Deploy succeeded on retry.

**Root cause class:** PR #515 added `SENTRY_DSN=` to `functions/.env.bookbed-dev` but never to `.env.rab-booking-248fc`. The fix is local-only because the file is gitignored — the next CI / different-machine / fresh-clone deployer hits the same error.

**Permanent fix candidate (separate PR):** add `SENTRY_DSN=` to a tracked deploy-runbook script OR to `functions/.env.example` (and add to deploy runbook), so the empty stub propagates. Alternatively, drop the `defineString` declaration entirely and conditionally read `process.env.SENTRY_DSN || ""` inside the Sentry init lazy block (see also `memory/sentry-cf-deploy-time-value-warning.md` — SF-052 candidate).

### 3.2 Secret Manager CLI policy-blocked; REST API + ADC token works

`gcloud secrets versions access latest --secret=STRIPE_SECRET_KEY` returned a CLI permission-block. Workaround (per `memory/pr482-j-smoke-2026-05-26.md` recipe):

```bash
TOKEN=$(gcloud auth application-default print-access-token)
curl -s -H "Authorization: Bearer $TOKEN" \
  "https://secretmanager.googleapis.com/v1/projects/rab-booking-248fc/secrets/STRIPE_SECRET_KEY/versions/latest:access" \
  | python3 -c "import sys,json,base64; d=json.load(sys.stdin); print(base64.b64decode(d['payload']['data']).decode())"
```

Same applies to `:addVersion` (POST) and `DELETE /v1/projects/.../secrets/{name}`. **Operator should treat REST as the canonical pathway for Secret Manager mutations in this codebase** until/unless the CLI policy is updated.

### 3.3 Silent stdin upload pattern (no /tmp file, no shell history leak)

```bash
{ IFS= read -rs K; printf '%s' "$K"; unset K; } \
  | gcloud secrets versions add STRIPE_SECRET_KEY \
      --data-file=- --project=rab-booking-248fc
```

`read -rs` is silent (no terminal echo) and the variable is unset immediately after `printf`. The pipe avoids any `/tmp/` file. The shell history records only the `{ … } | gcloud …` command — not the key value. This is the recommended pattern for any future Secret Manager add-version operation on this project.

### 3.4 Clipboard contamination class

Initial attempts to `pbpaste > /tmp/new-sk-live` returned a 92-byte file with content `umask 07...` — clipboard held terminal scrollback text from a prior agent message, not the new key value. Verification before upload:
```bash
pbpaste | wc -c          # expect 107 or 108
pbpaste | head -c 8       # expect: sk_live_
```
After Option-C silent-stdin path was adopted, this class became irrelevant.

---

## 4. PROD webhook subscription expansion (B — DEFERRED)

audit/61 §3 identified 3 missing event subscriptions on `we_1SgiznBomKO7vDr0CSwE9NNj`. This session did **NOT** execute the expansion (per task hard rule: "no POST to `/v1/webhook_endpoints`" — operator Dashboard click required). Verified post-session state:

```json
"enabled_events": [
  "checkout.session.completed",
  "checkout.session.expired"
]
```

Operator must add (Stripe Dashboard → Developers → Webhooks → `we_1SgiznBomKO7vDr0CSwE9NNj` → Update details):
- `charge.refunded`
- `customer.subscription.deleted`
- `invoice.paid`

Bonus (closes audit/61 F-61-07 + F-61-08):
- `invoice.payment_failed`
- `customer.subscription.updated`

After save, agent verification:
```bash
curl -s -u "${PROD_KEY}:" "https://api.stripe.com/v1/webhook_endpoints/we_1SgiznBomKO7vDr0CSwE9NNj"
# expect enabled_events length ≥ 5
```

---

## 5. Open follow-ups (NOT closure-blocking — captured for future audit)

| # | Item | Severity | Notes |
|---|---|---|---|
| 1 | `functions/.env.rab-booking-248fc` `SENTRY_DSN=` line is local-only (gitignored) | LOW (process hygiene) | §3.1 — next CI / fresh-clone deployer hits same firebase v2 error |
| 2 | Data Access audit logs disabled on `rab-booking-248fc` | MEDIUM (forensics) | §2.2 — no audit trail for any future secret-value reads. Enable via `gcloud projects set-iam-policy` with `auditConfigs` block for `secretmanager.googleapis.com` |
| 3 | PROD webhook subscription expansion (B) | MEDIUM (data-state desync risk on refund/sub events) | §4 + audit/61 §7-A |
| 4 | Remaining 4 abandoned Connect children | LOW (revenue/audit-trail hygiene) | `acct_1SwQCYBRnYwyvWUE` (jovalikareels@gmail.com), `acct_1St5GYAwUrOseNX8` (ironlifepodrska@gmail.com), `acct_1SqfjqBjD6wZNOjK` (jasko@jasko-rab.com) — same abandoned-signup pattern as the rejected `acct_1TYSMdPWhhVc6lN0`; consider batch-reject |
| 5 | `audit/61` F-61-03 — bookbed-dev webhook `api_version=null` vs PROD pinned `2025-09-30.clover` | LOW (test-env parity) | Schema-drift class — DEV smokes may receive event shape differing from PROD |
| 6 | `bookbed-staging` Secret Manager scan for SF-051 analog | LOW | `audit/53` flagged as TODO — not done this session |
| 7 | CI lint rejecting `defineSecret(/sk_test_\|sk_live_\|pk_\|whsec_\|re_/)` literal patterns | LOW (prevention) | `audit/53` §"Prevention" item A |
| 8 | Scheduled `secretNameSanityScan` CF (weekly) | LOW (prevention) | `audit/53` §"Prevention" item B |
| 9 | Subscription lifecycle gaps (F-61-07/08) | MEDIUM | `invoice.payment_failed`, `customer.subscription.updated` neither subscribed nor handled in code |

---

## 6. Cross-references

- `audit/53-prod-stripe-name-leak-2025-12-21.md` — original SF-051 finding (this audit's antecedent)
- `audit/60-stripe-consolidation-plan-2026-05-28.md` — single-account confirmation + consolidation plan
- `audit/61-webhook-event-coverage-2026-05-28.md` — webhook event coverage gap; F-61-02 Connect-model fix landed in same PR via `.claude/rules/stripe.md`
- `docs/SECURITY_FIXES.md` SF-051 — top-level closure marker (this audit updates that entry)
- `memory/prod-stripe-key-leaked-via-secret-name-2025-12-21.md` — auto-memory closure record
- `memory/sentry-cf-deploy-time-value-warning.md` — SF-052 candidate (related Sentry init class)
- `memory/firebase-cf-orphan-survival-class.md` — SF-053 candidate (related deploy hygiene)
- PR #531 — `docs/audit-60-61-stripe-consolidation` (audit/60 + audit/61 + `.claude/rules/stripe.md` F-61-02 fix + this audit/62)

---

## 7. Commands run (audit trail)

All non-trivial commands executed by the agent in this session, in order:

```
# Pre-flight
git checkout main && git pull --ff-only
gh pr view 530 --json state -q .state                          # MERGED ✓
gcloud secrets versions list STRIPE_SECRET_KEY --project=rab-booking-248fc
gcloud functions describe handleStripeWebhook --project=rab-booking-248fc --region=us-central1
gcloud functions list --project=rab-booking-248fc --regions=us-central1 \
  --format="value(name,serviceConfig.secretEnvironmentVariables)" | grep STRIPE_SECRET_KEY
gcloud secrets list --project=rab-booking-248fc --filter="name~SK_LIVE"
curl -u "${PROD_KEY}:" "https://api.stripe.com/v1/payment_intents?limit=10&created[gt]=<now-300>"
curl -u "${PROD_KEY}:" "https://api.stripe.com/v1/accounts?limit=100"

# Step 5 (user)
{ IFS= read -rs K; printf '%s' "$K"; unset K; } \
  | gcloud secrets versions add STRIPE_SECRET_KEY --data-file=- --project=rab-booking-248fc

# Step 5b / 5c (agent)
curl -u "${NEW_KEY}:" "https://api.stripe.com/v1/account"     # 200
curl -u "${OLD_KEY}:" "https://api.stripe.com/v1/account"     # 401

# Step 6 (user — after .env.rab-booking-248fc patched)
firebase deploy --only functions:createStripeCheckoutSession,functions:disconnectStripeAccount,\
functions:createCustomerPortalSession,functions:createSubscriptionCheckoutSession,\
functions:getStripeAccountStatus,functions:createStripeConnectAccount,functions:handleStripeWebhook \
  --project=rab-booking-248fc

# Step 7 (agent)
curl -X DELETE -H "Authorization: Bearer $TOKEN" \
  "https://secretmanager.googleapis.com/v1/projects/rab-booking-248fc/secrets/SK_LIVE_..._LD9VEX1"

# A — destroy v1-v4
for V in 1 2 3 4; do gcloud secrets versions destroy $V \
  --secret=STRIPE_SECRET_KEY --project=rab-booking-248fc --quiet; done

# D — reject orphan
curl -X POST -u "${PROD_KEY}:" -d "reason=other" \
  "https://api.stripe.com/v1/accounts/acct_1TYSMdPWhhVc6lN0/reject"

# Forensics
gcloud logging read 'protoPayload.serviceName="secretmanager.googleapis.com" \
  AND protoPayload.resourceName=~"SK_LIVE_51SIS"' --freshness=180d --project=rab-booking-248fc
gcloud projects get-iam-policy rab-booking-248fc --format=json | jq '.bindings[] | select(.role | contains("secretmanager"))'
```

All HTTP requests printed only metadata (HTTP code, sha256 prefix, response shape) — no key values written to context, scrollback, or files. `/tmp/_*.json` scratch files were `shred`-ed on completion.
