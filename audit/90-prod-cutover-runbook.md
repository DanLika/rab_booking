# audit/90 — PROD Cutover Runbook (sequenced)

**Date:** 2026-05-29
**Branch:** `docs/audit-90-prod-cutover-runbook`
**Scope:** executive runbook for promoting every dev-only / partially-PROD fix to `rab-booking-248fc` PROD. Sequenced, with per-step verification + rollback.
**Action policy:** documentation only. No PROD writes, deploys, or deletes performed during this audit run. Every operator action requires explicit per-step approval.
**Author note:** this consolidates audit/86 (orphans), audit/87 (secret sanity), audit/88 (branch hygiene), audit/22 (T11c canonical order — still the reference template), and audit/76 (last unified PROD deploy 2026-05-28) into a single forward path. Cross-reference rather than re-derive.

---

## §0 URGENT — current-state PROD breakage (FIX OUTSIDE THE CUTOVER WINDOW)

One finding discovered during this audit MUST be remediated independently of the sequenced cutover below, because it represents present silent damage to the live system. Do not bundle into the cutover deploy.

### F-90-01 — SF-050 PROD `loginLockout` CFs have NO `allUsers` IAM grant → silently fail-open

**Severity:** P1 (silent), credential-stuffing throttle is currently disabled on PROD.

**Evidence (probed 2026-05-29T18:12-18:13Z):**

| CF | OPTIONS preflight (Origin: app.bookbed.io) | ACAO header | Authoritative |
|---|---|---|---|
| `getunitavailability` (positive control) | `HTTP/2 204` | `access-control-allow-origin: https://app.bookbed.io` | function reachable |
| `recordloginfailure` | `HTTP/2 403` from `server: Google Frontend` | absent | **GFE rejects pre-function** |
| `getloginlockoutstatus` | `HTTP/2 403` from `server: Google Frontend` | absent | **GFE rejects pre-function** |
| `clearloginattempts` | `HTTP/2 403` from `server: Google Frontend` | absent | **GFE rejects pre-function** |
| `recordloginfailure` POST (anon, JSON body) | `HTTP=403` | absent | confirms not a CORS-only quirk |

`gcloud run services get-iam-policy <svc> --region=europe-west1` returns `etag: ACAB` with no `bindings:` block on all three. Cross-check `getclientgeolocation` (also europe-west1, anon-callable): returns `bindings: - members: [allUsers], role: roles/run.invoker` — proving the empty policy on the 3 loginLockout services is the actual state, not a format quirk.

**Why it matters:** `lib/core/services/rate_limit_service.dart` falls open on CF errors (see SF-050 fix notes: "Fail-open on CF errors (CF outage doesn't lock all users out)"). Browser POST to any of the 3 CFs returns GFE `403`, the Dart client interprets as a service outage, and lockout is skipped. PROD currently has no server-side login-attempt counter at all. Distributed credential stuffing succeeds without throttle (the IP-based `checkLoginRateLimit` remains as a fallback, but the per-email lockout that SF-050 was designed to enforce is non-functional).

**Suspected root cause:** SF-050 PR #517 deployed CF sources to PROD but the auto-grant of `roles/run.invoker → allUsers` failed silently — likely because of the same v2 onCall IAM stripping class documented in memory `[[cf-deploy-cors-shape-iam-strip]]`. PR #559 (SF-060) on 2026-05-29 redeployed sibling eu-west1 CFs and stripped IAM at that time; the audit/84 STEP 3 IAM re-grant loop covered the 7 PR #559 CFs but not the SF-050 trio because they weren't in that PR's diff.

**Fix (operator) — does NOT require code, deploy, or merge:**

```bash
for SVC in recordloginfailure getloginlockoutstatus clearloginattempts; do
  gcloud run services add-iam-policy-binding "$SVC" \
    --project=rab-booking-248fc \
    --region=europe-west1 \
    --member=allUsers \
    --role=roles/run.invoker
done
```

**Verification:** re-run the OPTIONS preflight from the evidence table. All three should return `HTTP/2 204` + `access-control-allow-origin: https://app.bookbed.io`. Authenticated `clearLoginAttempts` will still 401 from the function (auth gate) — that's correct; the IAM grant only opens GFE so the function code can enforce its own auth.

**Rollback:** `gcloud run services remove-iam-policy-binding <svc> --member=allUsers --role=roles/run.invoker` per service. Restores the broken state cleanly.

**Don't sequence this with cutover.** Fix immediately, in a separate window. Add the OPTIONS probe to standing pre-deploy smoke (see §5).

---

## §1 Pre-cutover checklist

Do every box BEFORE the first PROD-touching command in §3. Anything red here aborts the cutover.

### 1.1 PROD env (Secret Manager + .env file)

| Item | Present on PROD? | Source-of-truth | Blocker? |
|---|---|---|---|
| `STRIPE_SECRET_KEY` (Secret Manager, v=5, sha256 healthy, post-SF-051 rotation) | ✅ | audit/62 SF-051 closure | — |
| `STRIPE_WEBHOOK_SECRET` (Secret Manager, v=10 latest) | ✅ | gcloud probe 2026-05-29 | — |
| `RESEND_API_KEY` (Secret Manager, v=2) | ✅ | gcloud probe 2026-05-29 | — |
| `SENTRY_DSN` (Secret Manager, v=1) | ✅ | gcloud probe — bound to all 7 audit/76-deployed CFs, value `https://2d78b15…@…ingest.de.sentry.io/4510516869464144` | — |
| `ICAL_TOKEN_PEPPER` (Secret Manager) | ❌ MISSING | audit/87 §"Critical gap" | **YES — blocks PR #482 merge** |
| `ALLOWED_SUBSCRIPTION_PRICE_IDS` (CF env var, NOT Secret Manager) | ⚠️ bound but EMPTY (`ALLOWED_SUBSCRIPTION_PRICE_IDS=` on all CFs probed) | gcloud probe 2026-05-29 | **YES — fail-CLOSED for any subscription checkout if SF-038/F-50-01 allow-list enforcement is wired without populating** |

Provisioning recipes:

**`ICAL_TOKEN_PEPPER` (needs operator with `roles/secretmanager.admin`):**

```bash
openssl rand -hex 32 > /tmp/pepper.txt
gcloud secrets create ICAL_TOKEN_PEPPER \
  --project=rab-booking-248fc \
  --data-file=/tmp/pepper.txt \
  --replication-policy=automatic
shred -u /tmp/pepper.txt 2>/dev/null || rm -P /tmp/pepper.txt
# Bind to CF via redeploy in §3 (functions code already references via defineSecret)
```

Source authority: audit/87 §"Provisioning recipe".

**`ALLOWED_SUBSCRIPTION_PRICE_IDS` (file edit, NOT Secret Manager):**

1. Create PROD subscription Prices in Stripe Dashboard live mode (Products → Prices). Capture the `price_*` IDs.
2. Edit `functions/.env.rab-booking-248fc` locally — set `ALLOWED_SUBSCRIPTION_PRICE_IDS=price_AAA,price_BBB,price_CCC` (comma-separated, no spaces).
3. Confirm file is `.gitignored` (it already is — env files are gitignored).
4. The new value lands on PROD only when the CF that reads it is redeployed; sequenced in §3.

Cross-reference: audit/38 (PR #462 env-prereq), `[[widget-secrets-exfil-deploy-prereqs]]`.

### 1.2 PROD Firestore indexes — `daily_prices` composite

Probed 2026-05-29. Already healthy:

| Index ID | Scope | Fields | State |
|---|---|---|---|
| `CICAgNir940K` | COLLECTION | `available`+`date`+`__name__` | READY |
| `CICAgOi39IkK` | COLLECTION_GROUP | `unit_id`+`available`+`date`+`__name__` | READY |

`getUnitAvailability` runs cleanly against PROD `daily_prices` (positive control: OPTIONS preflight 204). Per audit/22 §3.2 + SF-019, **add +30s wait after any new composite reports `READY`** before exercising the dependent query. Today no new index is required; this row stays GREEN.

### 1.3 PROD orphan CFs (SF-053)

audit/86 §"PROD" sweep: 5 expected orphans, all Firebase Extensions:

```
ext-delete-user-data-clearData
ext-delete-user-data-handleDeletion
ext-delete-user-data-handleSearch
ext-storage-resize-images-backfillResizedImages
ext-storage-resize-images-generateResizedImage
```

These are NOT delete candidates. They are managed by `firebase ext:*`. PROD has 0 real orphans. Cutover does not need a pre-deploy orphan sweep on PROD this cycle. STAGING has 5 real orphans (audit/86 §"STAGING") — out of scope here.

### 1.4 Cloud Run service-name case verification

Confirmed via `gcloud run services list --project=rab-booking-248fc`. All 50+ services on PROD use **lowercased** names (e.g. `approveBooking → approvebooking`, `getUnitAvailability → getunitavailability`, `recordLoginFailure → recordloginfailure`). The IAM re-grant loop in §4 MUST address services by their lowercase name. Memory `[[cf-deploy-cors-shape-iam-strip]]` rationale captured.

### 1.5 SF status truth table (dev-only vs PROD)

| SF | Description | DEV | PROD | Pending op |
|---|---|---|---|---|
| SF-038 | Stripe webhook `event.id` dedup | ✅ | ✅ shipped (audit/76 §6) | — |
| SF-046 | App Check `consumeAppCheckToken:true` audit-only on `getUnitAvailability` + `createStripeCheckoutSession` | ✅ | ✅ shipped (non-breaking; SF-061 enforcement deferred — out of scope §7) | — |
| SF-047 | `checkSubdomainAvailability` + `generateSubdomainFromName` auth + per-uid rate limit | ✅ | ✅ shipped (PR #512) | — |
| SF-048 | `deleteUserAccount` 5-min per-uid cooldown | ✅ | ✅ shipped | — |
| SF-049 | bookbed-dev webhook signing-secret placeholder repair | dev-only | n/a | — |
| SF-050 | `loginAttempts` server-side lockout (3 new eu-west1 CFs + rule lock) | ✅ | 🟡 CFs deployed, rule deployed (`firestore.rules:465-467 allow read, write: if false`), **IAM `allUsers` MISSING — see §0 F-90-01** | §0 only |
| SF-051 | PROD Stripe live-key leak via Secret Manager NAME | n/a | ✅ CLOSED 2026-05-27 (v=5, leaky secret DELETEd, brownout 6-8 min, 0 customer impact) | — |
| SF-052 | Sentry `defineString.value()` deploy-time warning | 🟡 OPEN | 🟡 OPEN | out of scope §7 (cosmetic) |
| SF-053 | Firebase deploy doesn't auto-delete orphan CFs | recipe | recipe — audit/86 sweep on PROD: 0 real orphans | — |
| SF-056 | vibe57 batch (rules H-01/M-04/M-05/L-04 + CF H-04/H-06/H-08/H-09/M-11 + hosting M-09) | ✅ (#526/#527/#528) | ✅ closed | — |
| SF-057 | Owner + admin hosting CSP | ✅ (PR #557) | ✅ shipped 2026-05-29T14:27Z (smoke confirmed) | — |
| SF-058 | Client-side IP geolocation PII leak — `getClientGeolocation` CF eu-west1 | ✅ | ✅ shipped (PR #558, CF live, IAM `allUsers` granted — verified positive in §0 probe) | — |
| SF-059 | Logout multi-store wipe (sessionStorage + localStorage + cookies) | ✅ | ✅ shipped (PR #558, web client only — kIsWeb guard) | — |
| SF-060 | `cors: true` → explicit allowlist on 10 callables | ✅ (PR #559) | ✅ shipped 2026-05-29T15:13Z (IAM re-grant loop ran post-deploy per audit/84 STEP 3) | — |
| SF-061 | App Check enforcement (`enforceAppCheck: true`) | — | — | DEFERRED (reCAPTCHA prereq) — out of scope §7 |
| **SF-062** | CORS allowlist on **8 framework-default callables** (F-86-01) | ✅ DEV CLOSED via PR #565 | ❌ **NOT shipped to PROD** | **PRIMARY CUTOVER ITEM — see §3** |
| **PR #482** | `widget_secrets` subcollection lockdown (SF-021) | DEV-deployed | ❌ **NOT shipped to PROD** | **CUTOVER ITEM — gated on §1.1 ICAL_TOKEN_PEPPER provisioning** |

Net: SF-062 (PR #565) is the only ready-to-cut PR pending PROD. PR #482 is the only DRAFT pending PROD. Everything else is either already live or out of scope.

### 1.6 PROD Stripe in-flight check (audit/76 §1 carryover)

Repeat right before §3 first deploy (5-minute test window):

```bash
gcloud logging read 'resource.type="cloud_function" AND resource.labels.function_name="handleStripeWebhook" AND timestamp>="'"$(date -u -v-60M +%Y-%m-%dT%H:%M:%SZ)"'"' \
  --project=rab-booking-248fc --limit=20 --format='value(timestamp,jsonPayload.event_type)' 2>&1 | head -20
```

If the last 60 minutes show 0 `payment_intent.succeeded` / `checkout.session.completed`, the window is clean. Otherwise wait.

---

## §2 Hard rules (do not deviate)

1. **Canonical deploy order is CF → widget bundle → rules.** Source: audit/22 §3 + SF-019. The rule is *the lockout step*; if rules deploy first, the live widget bundle still calling the old contract breaks. Each cutover item in §3 follows this order.
2. **Per-fix sequencing, not bulk.** Treat SF-062 and PR #482 as independent operator gates. Land #565, smoke, then start #482 prereqs. Don't bundle.
3. **IAM re-grant loop fires after every cors-shape-change deploy.** v2 `onCall` strips Cloud Run `allUsers/invoker` when `cors` flips between `true` ↔ array/RegExp. Memory `[[cf-deploy-cors-shape-iam-strip]]`. The §4 loop is non-optional.
4. **Branch-guard every git op.** `git branch --show-current` between every destructive sequence. Multi-agent race documented in memory `[[multi-agent-git-race]]`.
5. **Lowercase service names everywhere in IAM commands.** Verified §1.4.
6. **No `--no-verify`, no `--no-gpg-sign`, no `--amend` of pushed commits.** Standard project posture.
7. **Don't fix §0 F-90-01 inside the cutover deploy window** (advisor catch). Independent fix, independent verification, independent rollback path.

---

## §3 Sequenced deploy steps

Two cutover items today. Order: SF-062 first (mature, tests green, no prereqs); PR #482 after, once ICAL_TOKEN_PEPPER + ALLOWED_SUBSCRIPTION_PRICE_IDS are provisioned.

### 3.1 PR #565 → SF-062 PROD deploy (CORS allowlist on 8 framework-default callables)

**Source branch:** `fix/f86-01-cors-8-callables` (open, base=main, title `fix(security): CORS allowlist on 8 callables (F-86-01, SF-062)`, CI: `Test Cloud Functions` PASS, `Validate Firestore Rules` PASS, `Run Tests` pending — confirm GREEN before merge).

**CFs touched:** 8 total across 6 source files (per `docs/SECURITY_FIXES.md` SF-062 §"Files modified"):

| Region | CFs |
|---|---|
| us-central1 | `createBookingAtomic`, `createStripeCheckoutSession`, `guestCancelBooking`, `checkSubdomainAvailability` |
| europe-west1 | `deleteUserAccount`, `recordLoginFailure`, `getLoginLockoutStatus`, `clearLoginAttempts` |

**Pre-merge checks (operator):**

```bash
cd /Users/duskolicanin/git/bookbed
git fetch origin
git checkout fix/f86-01-cors-8-callables
git pull --ff-only
cd functions && npm run build && npm test && npm run test:rules
cd ..
flutter analyze 2>&1 | grep -iE 'error|warning' | head -20
```

Acceptance: 0 build errors, 387/387 jest pass, 46/46 rules pass, 0 flutter analyze errors.

**Step 3.1.1 — merge PR (operator approval required):**

```bash
gh pr merge 565 --squash --delete-branch
```

**Step 3.1.2 — CF deploy (PROD):**

```bash
cd /Users/duskolicanin/git/bookbed
git checkout main
git pull --ff-only origin main

firebase deploy \
  --only functions:checkSubdomainAvailability,\
functions:createBookingAtomic,\
functions:createStripeCheckoutSession,\
functions:guestCancelBooking,\
functions:deleteUserAccount,\
functions:recordLoginFailure,\
functions:getLoginLockoutStatus,\
functions:clearLoginAttempts \
  --project rab-booking-248fc \
  --force
```

Expected duration: ~5-10 min per CF cold deploy. Watch for `Deploy complete!` final line. Memory `[[firebase-cf-orphan-survival-class]]` — if deploy aborts on orphan check (CI=true non-interactive failure mode), see SF-053 sweep recipe; PROD currently has 0 real orphans (audit/86 §"PROD") so this is unlikely.

**Step 3.1.3 — IAM re-grant loop (MANDATORY per §4):**

Run the loop in §4 IMMEDIATELY after the deploy command returns. Window of broken state is ~60s per memory `[[cf-deploy-cors-shape-iam-strip]]` if you skip.

**Step 3.1.4 — Post-deploy CORS smoke (positive + negative + evil):**

See §5 SF-062 row. All 8 callables × 3 origin checks (`app.bookbed.io` ✓, `view.bookbed.io` ✓, `evil.test` ✗).

**Step 3.1.5 — App-flow smoke (widget payment hot-path):**

Open `https://view.bookbed.io/?property=<PROD_property_id>&unit=<PROD_unit_id>` in incognito. Pick dates. Submit. Confirm: Stripe Checkout redirect succeeds. (We are NOT charging — close the Stripe page before payment; the smoke is about CORS + the new `cors: getCorsAllowlist()` not interfering with `createStripeCheckoutSession` reachability.) If owner dashboard reachable: open Booking with a non-Stripe path, hit `Potvrdi` → `approveBooking` succeeds — that's an audit/76 positive control that the booking lifecycle CFs (separate sibling, not in #565) still respond.

**Step 3.1.6 — Sentry watch (5 min):**

```bash
gcloud logging read 'severity>=ERROR AND resource.type="cloud_function" AND resource.labels.function_name=~"createBookingAtomic|createStripeCheckoutSession|guestCancelBooking|checkSubdomainAvailability|deleteUserAccount|recordLoginFailure|getLoginLockoutStatus|clearLoginAttempts"' \
  --project=rab-booking-248fc --limit=20 --format='value(timestamp,severity,jsonPayload.message)' 2>&1 | head -30
```

0 new errors expected. If `Origin not allowed` errors spike for legitimate origins (e.g. tenant subdomains), see rollback below.

**Step 3.1.7 — Rules + hosting bundle: NOT applicable for SF-062.**

PR #565 modifies CFs only. No rule changes, no widget bundle changes. Skip step 3.3 + 3.4 from the audit/22 template.

**Rollback (if any §3.1.4-6 smoke fails):**

```bash
git revert <merge-commit-sha>
git push origin main
# Then redeploy the 8 CFs with the reverted source:
firebase deploy --only functions:checkSubdomainAvailability,functions:createBookingAtomic,functions:createStripeCheckoutSession,functions:guestCancelBooking,functions:deleteUserAccount,functions:recordLoginFailure,functions:getLoginLockoutStatus,functions:clearLoginAttempts --project rab-booking-248fc --force
# Re-run §4 IAM loop AGAIN — the revert is itself a cors-shape change in the opposite direction.
```

Rollback budget: ~15 min (revert + redeploy + IAM re-grant).

---

### 3.2 PR #482 → SF-021 widget_secrets lockdown PROD deploy (BLOCKED until §1.1 green)

**Source branch:** `hotfix/widget-secrets-exfil` (open as Draft, base=main, title prefixed "Draft — deploy prereqs blocking").

**Prereqs (operator must complete BEFORE running 3.2.1):**

1. `ICAL_TOKEN_PEPPER` provisioned on PROD per §1.1 recipe. Verify: `gcloud secrets versions list ICAL_TOKEN_PEPPER --project=rab-booking-248fc` returns ≥ 1 ENABLED version.
2. `ALLOWED_SUBSCRIPTION_PRICE_IDS` populated in `functions/.env.rab-booking-248fc` per §1.1 recipe. Verify by re-grep the file post-edit.
3. Stripe LIVE-mode subscription Prices exist (Stripe Dashboard → Products → Prices) matching the IDs in step 2.

**If any prereq is red, STOP. Do not merge PR #482.** Re-run audit/87 sanity. Re-confirm Stripe Dashboard.

**Step 3.2.1 — pre-merge checks (operator):**

```bash
cd /Users/duskolicanin/git/bookbed
git fetch origin
git checkout hotfix/widget-secrets-exfil
git pull --ff-only
cd functions && npm run build && npm test && npm run test:rules
cd .. && flutter analyze 2>&1 | grep -iE 'error|warning' | head -20
```

Acceptance criteria same as 3.1.

**Step 3.2.2 — promote PR from Draft to ready + merge:**

Operator manual via GitHub UI. Then:

```bash
gh pr merge 482 --squash --delete-branch
git checkout main && git pull --ff-only origin main
```

**Step 3.2.3 — CF deploy:**

Per PR #482 body, the CFs binding `ICAL_TOKEN_PEPPER` are `getUnitIcalFeed` (us-central1) and `icalExport` (us-central1). Plus any CF binding `ALLOWED_SUBSCRIPTION_PRICE_IDS` value (currently `createSubscriptionCheckoutSession`).

```bash
firebase deploy \
  --only functions:getUnitIcalFeed,functions:icalExport,functions:createSubscriptionCheckoutSession \
  --project rab-booking-248fc \
  --force
```

Expected duration: ~10 min. Watch for `Deploy complete!`.

**Step 3.2.4 — verify env binding picked up:**

```bash
gcloud functions describe getUnitIcalFeed \
  --project=rab-booking-248fc --region=us-central1 --gen2 \
  --format='value(serviceConfig.secretEnvironmentVariables)' | grep -i pepper

gcloud functions describe createSubscriptionCheckoutSession \
  --project=rab-booking-248fc --region=us-central1 --gen2 \
  --format='value(serviceConfig.environmentVariables.ALLOWED_SUBSCRIPTION_PRICE_IDS)'
```

First command: should print a line containing `ICAL_TOKEN_PEPPER`. Second: should print the comma-separated price IDs, NOT empty.

**Step 3.2.5 — migration script (per PR #482 body §"Migration"):**

```bash
GOOGLE_CLOUD_PROJECT=rab-booking-248fc \
  node functions/scripts/migrate-widget-secrets-pepper.js --force \
  2>&1 | tee audit/migrations/$(date +%Y-%m-%d)-prod-widget-secrets-pepper.log
```

Confirm output reports `N docs migrated` matching the count of existing iCal feeds on PROD. Re-run in dry-run mode: should report `0 docs to migrate` (idempotency check).

**Step 3.2.6 — widget bundle redeploy (per PR #482 body):**

```bash
flutter clean && flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter build web --release --target lib/widget_main.dart
firebase deploy --only hosting:widget --project rab-booking-248fc
```

Cache-bust check:

```bash
curl -sI 'https://view.bookbed.io/' | grep -iE 'last-modified|etag'
```

`last-modified` within minutes of deploy.

**Step 3.2.7 — Firestore rules deploy (LAST):**

Per audit/22 §3 hard rule — rules go LAST.

```bash
firebase deploy --only firestore:rules --project rab-booking-248fc
```

**Step 3.2.8 — Smoke:**

- Anon read attempt against PROD `widget_secrets` subcollection should return `PERMISSION_DENIED`. Use the §5 SF-021 row recipe.
- Widget calendar paints on `https://view.bookbed.io/?property=<PROD_property_id>&unit=<PROD_unit_id>` in incognito.
- One throwaway iCal export feed creation by the bookbed-test-on-PROD owner → URL contains peppered token, NOT the raw subscription_id. (Operator action only — do NOT use a real customer property.)

**Rollback:** revert the merge commit; redeploy the 3 CFs; redeploy widget bundle; redeploy rules. ~20 min total. Migration is forward-only — there is NO inverse script (same pattern as audit/22 §3.6 SF-026), so rollback leaves migrated docs in their new shape; that's acceptable because the new shape is backwards-readable (the migration adds fields, doesn't remove).

---

## §4 IAM re-grant loop (post any cors-shape-change deploy)

**When to run:** immediately after any `firebase deploy --only functions:*` that touched CF source files modifying the `cors` option (true ↔ array/RegExp). Both §3.1 and §3.2 trigger this. Memory `[[cf-deploy-cors-shape-iam-strip]]` rationale.

**Script (use lowercase service names per §1.4):**

```bash
# After §3.1 (SF-062 / PR #565) — 8 services across both regions
US_SVCS=(checksubdomainavailability createbookingatomic createstripecheckoutsession guestcancelbooking)
EU_SVCS=(deleteuseraccount recordloginfailure getloginlockoutstatus clearloginattempts)

for SVC in "${US_SVCS[@]}"; do
  gcloud run services add-iam-policy-binding "$SVC" \
    --project=rab-booking-248fc \
    --region=us-central1 \
    --member=allUsers \
    --role=roles/run.invoker
done

for SVC in "${EU_SVCS[@]}"; do
  gcloud run services add-iam-policy-binding "$SVC" \
    --project=rab-booking-248fc \
    --region=europe-west1 \
    --member=allUsers \
    --role=roles/run.invoker
done
```

```bash
# After §3.2 (PR #482) — 3 services, all us-central1
for SVC in getuniticalfeed icalexport createsubscriptioncheckoutsession; do
  gcloud run services add-iam-policy-binding "$SVC" \
    --project=rab-booking-248fc \
    --region=us-central1 \
    --member=allUsers \
    --role=roles/run.invoker
done
```

**Verification after the loop (per service):**

```bash
gcloud run services get-iam-policy "$SVC" \
  --project=rab-booking-248fc --region="$REGION" \
  --format='value(bindings.role,bindings.members)' | grep allUsers
```

Should print a single line per service confirming `roles/run.invoker  ['allUsers']`.

**Time-to-effect:** IAM propagation typically < 30 s, often instant. Re-run the OPTIONS preflight from §5 if a service still returns 403 after 60 s.

---

## §5 Smoke matrix (post-cutover)

Run all rows in parallel after each §3 sub-section completes. Use the §1.6 in-flight window check before starting.

| Smoke | Command | Pass criterion | Source |
|---|---|---|---|
| **SF-062 CORS positive (app.bookbed.io)** | `curl -sS -D - -o /dev/null -X OPTIONS -H 'Origin: https://app.bookbed.io' -H 'Access-Control-Request-Method: POST' https://<lowercase-svc>-e2afn4c6mq-{ew\|uc}.a.run.app/` | `HTTP/2 204` + `access-control-allow-origin: https://app.bookbed.io` | §0 positive control template |
| **SF-062 CORS positive (view.bookbed.io)** | same with `Origin: https://view.bookbed.io` | `HTTP/2 204` + ACAO echo | per `getCorsAllowlist()` spec |
| **SF-062 CORS negative (evil.test)** | same with `Origin: https://evil.test` | `HTTP/2 204` BUT **no `access-control-allow-origin` header** (browser will reject); OR `HTTP/2 403` (also acceptable) | SF-060 smoke template |
| **SF-021 anon Firestore CG `widget_secrets`** | `gcloud` admin-token query against CG `widget_secrets` — confirm anon equivalent in incognito fetch in DevTools Network shows `permission-denied` | per audit/22 §3.4 anon-CG template | adapted |
| **CF reachability anon** | `curl -sS -X POST -H 'Content-Type: application/json' -d '{"data":{}}' https://<svc-url>/` | `HTTP 401 UNAUTHENTICATED` from the function (NOT `403` from GFE, NOT `404`) — confirms IAM grant works and function code runs | audit/76 §6 template |
| **Stripe egress (paid-flow prereq)** | trigger 1 throwaway Stripe Connect status read via the owner dashboard's debug tab OR `gcloud functions logs read getStripeAccountStatus --project=rab-booking-248fc --limit=5` for last invocation success | 200 from Stripe API; no `network error` / `socket hang up` | audit/76 §6 template (post-PR #541 Stripe egress fix) |
| **Stripe webhook dedup (SF-038)** | Stripe Dashboard → Developers → Webhooks → send a test event; observe handler ignores second delivery of same `event.id` | second invocation logs `Duplicate event.id — skipping` | SF-038 acceptance |
| **SF-050 IAM (recurring monitor — §0 fix verification)** | `curl -sS -D - -o /dev/null -X OPTIONS -H 'Origin: https://app.bookbed.io' https://{recordloginfailure,getloginlockoutstatus,clearloginattempts}-e2afn4c6mq-ew.a.run.app/` | all three: `HTTP/2 204` + ACAO echo | §0 evidence-table inverse |
| **Hosting headers (SF-057 CSP retain)** | `curl -sI https://app.bookbed.io` | `content-security-policy:` header present, `strict-transport-security` present | SF-057 acceptance |
| **Auth flow (login)** | open https://app.bookbed.io in incognito; log in with bookbed-test-on-PROD account (per `[[test-account-prod]]`); should succeed | no `permission-denied`, no 403 console errors, dashboard paints | recurring |
| **Widget calendar paints** | open `https://view.bookbed.io/?property=<PROD_property_id>&unit=<PROD_unit_id>` in incognito | calendar canvas paints; no `permission-denied` in Sentry | audit/22 §3.4 template |

A single failure in any row blocks moving from §3.1 to §3.2 (or from §3.2 to the "post-cutover monitoring" phase).

---

## §6 Operator blockers (need your name / approval)

These items I (Claude) cannot resolve. They require human action.

| ID | Blocker | Owner | Action |
|---|---|---|---|
| **B-1** | `ICAL_TOKEN_PEPPER` provisioning on PROD | operator with `roles/secretmanager.admin` on `rab-booking-248fc` | §1.1 recipe; gates §3.2 |
| **B-2** | PROD subscription Prices in Stripe Dashboard live mode + populate `ALLOWED_SUBSCRIPTION_PRICE_IDS` in `functions/.env.rab-booking-248fc` | operator with Stripe Dashboard owner access + local file edit access | §1.1 recipe; gates §3.2 |
| **B-3** | SF-050 IAM grants for `recordloginfailure` / `getloginlockoutstatus` / `clearloginattempts` (§0 F-90-01) | operator with `roles/run.admin` on `rab-booking-248fc` | §0 fix block; **DO NOT bundle with §3 cutover** |
| **B-4** | Merge PR #565 → main | operator with merge rights | gates §3.1.2 |
| **B-5** | Promote PR #482 from Draft → ready and merge | operator with merge rights (only AFTER B-1 + B-2 green) | gates §3.2.2 |
| **B-6** | audit/88 branch hygiene deletes (12 remote merged-into-main candidates + 47 unmerged review + 55 local) | operator approval per batch | NOT cutover-blocking; deferred from audit/88 with explicit "user must approve" policy. I will not run `gh api -X DELETE` or `git push origin --delete` without your per-batch say-so. |
| **B-7** | STAGING orphan cleanup (5 real orphans per audit/86 §"STAGING") + 13 missing deploys decision (redeploy or retire staging) | operator strategic decision | NOT PROD-cutover-blocking; out of scope §7 |
| **B-8** | SF-052 Sentry `defineString.value()` lazy-init follow-up PR | future PR author | cosmetic; defer post-cutover |

---

## §7 Explicitly out of scope (for this runbook)

Document and exclude. These either are deferred by design or are not PROD-cutover-blocking.

- **SF-061 App Check enforcement (`enforceAppCheck: true`).** Deferred per audit/84 STEP 4 — requires `RECAPTCHA_SITE_KEY` provisioning + 7-day verified-rate ≥ 0.95 gate per audit/85. See TODO.md "App Check launch checklist".
- **SF-052 Sentry `.value()` lazy init.** Cosmetic deploy-time warning, runtime unaffected. Bundle with next `functions/src/sentry.ts` touch.
- **Staging orphan cleanup + 13 missing CF deploys.** audit/86 §"STAGING" — separate decision (redeploy vs retire).
- **audit/88 branch deletes.** Documentation only this cycle; operator gate per batch (B-6 above).
- **Wider CORS sweep beyond the 18 callables already migrated (10 in PR #559 + 8 in PR #565).** audit/58 estimated ~35 callables — remainder relies on Firebase v2 framework default which is still reflective. Follow-up audit candidate.
- **SF-051 IAM audit + access-log scan** post-rotation. Done in audit/62 SF-051 closure; no carry-forward.
- **App Check client init follow-ups** (4 of 5 unchecked boxes in audit/85). reCAPTCHA registration + 7d watch — pre-SF-061 work.

---

## §8 Rollback posture (summary)

| Step | Rollback | Window |
|---|---|---|
| §0 F-90-01 IAM grant | `gcloud run services remove-iam-policy-binding` per service | < 30 s |
| §3.1 SF-062 CF deploy | `git revert <merge-sha>` + redeploy 8 CFs + re-run §4 IAM loop | ~15 min |
| §3.2 SF-021 CF deploy | `git revert <merge-sha>` + redeploy 3 CFs + redeploy widget bundle + redeploy rules + re-run §4 IAM loop | ~20 min |
| §3.2 migration script | forward-only — no inverse. Migrated docs are backwards-readable (additive field shape), so revert leaves data in migrated form; that's acceptable. | n/a |
| §1.1 ICAL_TOKEN_PEPPER provision | `gcloud secrets delete ICAL_TOKEN_PEPPER --project=rab-booking-248fc` (only if not bound to any CF) | < 30 s |

Failed-forward posture mirrors audit/22 §5. If §3.1 smoke fails after IAM re-grant + 60 s wait, revert. If §3.2 smoke fails, revert in reverse order (rules → widget → CFs → migration data left as-is).

---

## §9 What this runbook does NOT do

- Does NOT execute any of §0, §1, §3, §4 commands. All operator-gated.
- Does NOT decide whether to fix §0 before §3 or vice versa. Recommendation is §0 first (it's silent broken right now), but the cutover deploys are independent.
- Does NOT delete any PROD secret, CF, branch, or document.
- Does NOT modify any source code. The only file produced by this audit is this runbook.

---

## Cross-references

- [audit/22-prod-cutover-plan.md](./22-prod-cutover-plan.md) — T11c canonical CF→widget→rules template, still authoritative for shape
- [audit/76-prod-deploy-2026-05-28.md](./76-prod-deploy-2026-05-28.md) — most recent unified PROD deploy session; §1 in-flight check + §3 IAM loop pattern
- [audit/86-orphan-sweep.md](./86-orphan-sweep.md) — PROD 0 real orphans confirmation (SF-053)
- [audit/87-secret-sanity.md](./87-secret-sanity.md) — PROD `ICAL_TOKEN_PEPPER` missing (B-1)
- [audit/88-branch-hygiene.md](./88-branch-hygiene.md) — branch delete inventory (B-6, deferred)
- [audit/89-f86-01-cors-fix.md](./89-f86-01-cors-fix.md) — SF-062 fix detail (on `fix/f86-01-cors-8-callables` branch, not on main yet)
- [docs/SECURITY_FIXES.md](../docs/SECURITY_FIXES.md) — SF-038 / SF-046 / SF-047 / SF-048 / SF-050 / SF-051 / SF-052 / SF-053 / SF-056 / SF-057 / SF-058 / SF-059 / SF-060 / SF-061 / SF-062 canonical entries
- [docs/TODO.md](../docs/TODO.md) — "App Check launch checklist" (SF-061 prereqs)
- memories: `[[cf-deploy-cors-shape-iam-strip]]`, `[[widget-secrets-exfil-deploy-prereqs]]`, `[[firebase-cf-orphan-survival-class]]`, `[[test-account-prod]]`

---

## Sign-off

Documentation only. No PROD writes / deploys / deletes performed. Every operator action is per-step approval-gated.

**Next concrete moves (in operator priority order):**

1. **B-3** — fix §0 F-90-01 IAM grants on the 3 SF-050 CFs (independent of cutover; silent broken right now).
2. **B-4** — merge PR #565 → run §3.1 sequence end-to-end (lowest risk; tests green; no env prereqs).
3. **B-1 + B-2** — provision `ICAL_TOKEN_PEPPER` + populate `ALLOWED_SUBSCRIPTION_PRICE_IDS` PROD values.
4. **B-5** — promote + merge PR #482 → run §3.2 sequence.
5. Defer B-6, B-7, B-8 to next session.
