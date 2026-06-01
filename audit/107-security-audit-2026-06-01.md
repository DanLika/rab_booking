# Audit/107 — Security Audit Sweep (2026-06-01)

**Trigger:** `/security-audit:security-audit` skill run on `main @ 866cc823` (post-#643/#638 merges, pre-#645).
**Scope:** Whole repo. 4 parallel `security-engineer` agents (functions/, lib/, rules+config, supply chain).
**Project size:** HUGE — 849 source files (127 TS + 722 Dart), 287K LoC.

## Methodology

| Agent | Surface | Tooling |
|-------|---------|---------|
| 1 | `functions/src/**/*.ts` (98 files) | grep + Read; SSRF, CORS, IDOR, payment, JWT, injection, validation, secret handling, rate-limit, returnUrl, Sentry filter, iCal token |
| 2 | `lib/**/*.dart` (722 files) | grep + Read; secrets, token storage, console.log, XSS-equivalent, deep-link, provider cache, geo PII, Stripe Connect, postMessage |
| 3 | `firestore.rules`, `storage.rules`, `firebase.json`, `.firebaserc`, `web/index.html` | direct rule audit; `affectedKeys` matrix; per-surface headers matrix |
| 4 | `functions/package.json` + lockfile, `pubspec.yaml` + lock | `npm audit --json`, `npm outdated`, typosquat heuristics, package hallucination cross-check |

Tagging: `NEW`, `KNOWN-SF-NNN`, `KNOWN-F-XX-NN`, `KNOWN-audit/NN`. For KNOWN entries, agents re-verified state on disk vs `MEMORY.md` baseline.

Adaptations: Supabase-specific bypass vectors (40+ in skill template) **skipped** — project is Firebase+Flutter. RLS / PostgREST / GraphQL / Realtime / pg_graphql / pgTAP / SupaShield checks not applicable.

## Findings (19 total)

### 🟠 HIGH (1)

**F-107-01** — `firestore.rules:332-334` — `widget_secrets` create/update lack `affectedKeys` allowlist. Owner can write arbitrary field names beyond documented `ical_export_token` / `stripe_secret_key` / `resend_api_key`. Surface bounded to property-owner trust domain but expansion-risk on a secrets-typed collection. **Fix:** add `hasOnly` for the 3 documented keys, OR move secrets to CF-write-only (mirror `loginAttempts` / `oauth_states` patterns).

### 🟡 MEDIUM (7)

**F-107-02** — `atomicBooking.ts:1657`, `:1920`, `admin/setLifetimeLicense.ts:23`, `admin/updateUserStatus.ts:26`, `migrations/migrateTrialStatus.ts:34` — 5 v2 `onCall` callables use bare `onCall(handler)` → framework-default reflective `Origin` echo. `audit/89` PR #565 swept 8 callables and missed these. Owner-write + admin paths. Auth checks present → leak-of-response-data + XSS amplifier, not write-bypass. **Fix:** add `cors: getCorsAllowlist()` per callable; PROD operator-gate: per-callable IAM re-grant after deploy ([[cf-deploy-cors-shape-iam-strip]]).

**F-107-03** — `firebase.json:119-121` — widget hosting surface ships **only** `Content-Security-Policy: frame-ancestors *` and `X-Frame-Options: ALLOWALL`. No `default-src` / `script-src` / `connect-src` / `style-src`. Zero CSP defense vs DOM XSS for the embed surface (`view.bookbed.io`). Owner + admin surfaces ship full CSP. **Fix:** add full CSP matching owner/admin but with `frame-ancestors *` allowed for iframe embedding.

**F-107-04** = **KNOWN-F-101-03 (OPEN, re-confirmed)** — `atomicBooking.ts:95`, `stripePayment.ts:69`, `loginLockout.ts:109`, `stripeSubscription.ts:28`, `guestCancelBooking.ts:87` — hot anonymous callables still ride per-CF-instance `rateLimitStore` `Map`. Scale-out resets budget; distributed bypass trivial. Highest-impact uncloosed memory item. **Fix:** swap to Firestore-backed `enforceRateLimit` keyed on IP-hash doc, or front via App Check.

**F-107-05** = **KNOWN-SF-068 (PARTIAL)** — `firestore.rules:215-220` — `properties.create.subdomain` format-valid subdomain squat still OPEN. Client writes `subdomain` field directly at create before CF reservation runs. **Fix:** refactor `firebase_owner_properties_repository.dart:195` to drop `subdomain` field at create; force `setPropertySubdomain` callable path. Rule can additionally strip `subdomain` from `create.affectedKeys`.

**F-107-06** = **KNOWN-audit/64** — `firebase.json` headers committed but PROD owner + admin hosting redeploy verification required. **Operator action:** `firebase deploy --only hosting:owner,hosting:admin --project rab-booking-248fc` + `curl -I` verify per surface.

**F-107-07** — `functions/package.json` — `firebase-admin@12.7.0`, 1 SemVer-major behind (`13.10.0`). Closes all 8 moderate npm-audit (uuid OOB GHSA-w5hq-g745-h8pq on transitives) on bump. **Fix:** bump to `^13.10.0`; smoke firestore + auth in dev.

**F-107-08** — `functions/package.json` — `firebase-functions@6.6.0`, 1 SemVer-major behind (`7.2.5`). Project already uses v2 triggers exclusively → low migration cost. **Fix:** bump to `^7.0.0`; smoke 35+ CFs (audit/79 matrix).

### 🔵 LOW (7)

**F-107-09** = **KNOWN-F-86-02 (OPEN, re-confirmed)** — `availability.ts:155-178` — `bookings` + `ical_events` CG queries lack date range filter. Only `limit(500)` per query. Silent truncation as platform scales → stale availability → double-bookings. **Fix:** add `.where("check_out",">=",startTs)` + `.where("end_date",">=",startTs)` (composite indexes required).

**F-107-10** — `stripeSubscription.ts` — `createSubscriptionCheckoutSession` + `createCustomerPortalSession` lack explicit `region` → default `us-central1` while auth CFs in `europe-west1`. EU latency + webhook routing drift risk. **Fix:** add `region: "us-central1"` explicit OR migrate to `europe-west1` (Stripe webhook URL update required).

**F-107-11** — `lib/core/utils/web_utils_web.dart:325, 332` — `sendMessageToParent` posts to `parent`/`opener` with target origin `'*'`. Leaks `sessionId` + `bookingRef` (Stripe `cs_*` IDs) to any embedder. Inbound IS origin-validated (F-NEW-04 closed). **Fix:** resolve target origin from trusted-list (mirror `_isAllowedPostMessageOrigin`); fall back to `view.bookbed.io` literal when parent unknown.

**F-107-12** = **KNOWN-F-67-03 (PARTIAL)** — `lib/features/widget/services/form_persistence_service.dart:131-138`, `booking_form_state.dart:344` — `notes` scrubbed but `firstName` / `lastName` / `email` / `phone` / `countryCode` / `adults` / `children` / `pets` still persist 15min in SharedPreferences keyed only by `unitId`. Shared-kiosk / iframe origin leak. **Fix:** move to sessionStorage on web (deferred refactor per source comment).

**F-107-13** — `firestore.rules:528-537` — deprecated top-level `ical_feeds` `read: if isAuthenticated() && (resource == null || …)` — the `resource == null` short-circuit allows any authenticated user to probe arbitrary `feedId` existence. Sibling of `audit/98` F-98-01. **Fix:** drop `resource == null` short-circuit; require property-owner check unconditionally. If no legacy docs remain, remove block entirely (already `create: if false`).

**F-107-14** — `firestore.rules:61-73` — `users.create` uses `hasAny` deny-list without `hasOnly` shape bind. User can plant arbitrary unmodeled fields at signup. Update deny-list is the real gate; create is unbounded. **Fix:** optional `hasOnly` allowlist on `users.create`. Defer-acceptable.

**F-107-15** = **KNOWN-CSP-tradeoff** — `firebase.json:56,168` — owner + admin CSPs use `'unsafe-inline'` + `'unsafe-eval'` + `https://*.cloudfunctions.net` wildcard. Flutter Web CanvasKit requires eval; wildcards allow cross-tenant CF inclusion. **Fix (P3):** narrow `*.cloudfunctions.net` to project-specific `https://{region}-rab-booking-248fc.cloudfunctions.net`. Long-term: wasm renderer or strict-dynamic+nonces.

### ℹ️ INFO (4)

**F-107-16** — `firestore.rules:147-156` — `securityEvents` `timestamp` field is client-controlled. Bind `request.resource.data.timestamp == request.time` once client uses `serverTimestamp`.

**F-107-17** — `storage.rules:17-22, 51` — `contentType` regex `image/(jpeg|png|webp|gif|heic|heif)` unanchored — `image/jpeg-evil-suffix` matches. Bounded by per-user prefix. **Fix:** anchor — `^image/(...)$`.

**F-107-18** = **KNOWN-SF-067** — `storage.rules` cross-product Firestore reads require `roles/datastore.viewer` on Firebase Storage service agent. Operator-side, not file-checkable. **Verify:** `gcloud projects get-iam-policy rab-booking-248fc --filter="bindings.role:roles/datastore.viewer"` on PROD + DEV.

**F-107-19** = **KNOWN-F-CUT-01** — `functions/package-lock.json` `lockfileVersion 3` was closed via `167e6353` but re-recurs silently if `npm install` rerun on local npm 11. Cloud Build uses npm 10. **Pre-PROD-cutover:** regen under `nvm use 20 && npm i -g npm@10` in CI parity environment.

## Verified CLOSED (re-checked on disk vs MEMORY.md baseline)

F-93-02 / SF-072 (booking Strategy 2 dual-path), F-92-01 / SF-063 (iCal empty-token), F-101-01 / SF-078 (returnUrl `new URL()` + userinfo reject), F-101-02 (env-gated localhost), SSRF / audit/57 M-11 (DNS-pinned, IPv6 hex), SF-066 (Sentry HttpsError filter), payment integer-cents math + `ALLOWED_SUBSCRIPTION_PRICE_IDS`, admin JWT-claim gate, F-58c-13 (geo PII via `getClientGeolocation`), F-58c-14 (`wipeWebStorageOnLogout`), F-67-01 (Confirm/Reject via callable), SF-007 (`flutter_secure_storage`), F-50-04 (PR #495 logger fix), F-50-10 (no `eval`), F-NEW-03 / F-NEW-04 (deep-link http(s)-only + postMessage inbound allowlist), F-94-* / SF-068 (`affectedKeys` deny on `properties` / `ical_feeds` / `widget_settings`), F-99-01 / SF-078 (bookings deny mirror), T11c (bookings read lockdown), SF-023 (`ical_events` CF-write-only), storage rule triple (split write/delete + `firestore.get` literal `(default)` + IAM grant — file side).

## Headers matrix

| Surface | CSP | X-Frame | X-CTO | Referrer | Permissions | HSTS |
|---|---|---|---|---|---|---|
| owner (`app.bookbed.io`) | FULL (`unsafe-inline`+`unsafe-eval`) | DENY | nosniff | strict-origin-when-cross-origin | locked-down | max-age=31536000 includeSubDomains preload |
| widget (`view.bookbed.io`) | **MINIMAL — only `frame-ancestors *`** ⚠️ F-107-03 | ALLOWALL | nosniff | strict-origin-when-cross-origin | locked-down | max-age=31536000 includeSubDomains preload |
| admin (`bookbed-admin.web.app`) | FULL (same as owner) | DENY | nosniff | strict-origin-when-cross-origin | locked-down | max-age=31536000 includeSubDomains preload |

## affectedKeys matrix (excerpt — full in audit prep)

| Collection | read | create | update allowlist | delete |
|---|---|---|---|---|
| `bookings` (canonical sub) | owner+property-owner | owner+pin | `affectedKeys.hasAny`(deny status+CF fields) | property-owner |
| `properties` | public | owner+subdomain format guard | `affectedKeys.hasAny`(deny `subdomain`/`owner_id`/`created_at`) | owner |
| `widget_settings` (sub) | public | property-owner | `affectedKeys.hasAny`(deny 4 ical_cache fields) | property-owner |
| `widget_secrets` (sub) | property-owner | **no allowlist** ⚠️ F-107-01 | **no allowlist** ⚠️ | property-owner |
| `ical_events` (sub) | property-owner | denied (CF-only, SF-023) | denied | denied |
| `ical_feeds` (sub) | property-owner | property-owner | `affectedKeys.hasAny`(deny 3 CF stat fields) | property-owner |
| `loginAttempts` | denied | denied | denied | denied (SF-050 CF-only) |
| `stripe_webhook_events` | denied | denied | denied | denied (SF-038) |
| `ical_feeds` (top-level deprecated) | authed + `resource==null` bypass ⚠️ F-107-13 | denied (`create: if false`) | property-owner | property-owner |

## Summary

```
🔴 CRITICAL: 0  |  🟠 HIGH: 1  |  🟡 MED: 7  |  🔵 LOW: 7  |  ℹ️ INFO: 4

NEW: 9 findings (1 HIGH, 2 MED, 4 LOW, 2 INFO)
KNOWN-OPEN: 4 (F-101-03, F-86-02, F-67-03 partial, SF-068 partial)
KNOWN-OPERATOR: 3 (audit/64 redeploy, SF-067 IAM, F-CUT-01 lockfile)
KNOWN-CLOSED-VERIFIED: 25+ items match MEMORY.md baseline
```

## Top 5 prioritized

1. **F-107-01 HIGH** — `widget_secrets` `affectedKeys` allowlist (single-line rule fix, biggest blast-radius cheap-fix)
2. **F-107-02 MED** — CORS gap on 5 callables (audit/89 PR #565 follow-up sweep)
3. **F-107-03 MED** — widget surface full CSP (`frame-ancestors *` only today)
4. **F-107-07 + F-107-08 MED** — `firebase-admin` 12→13 + `firebase-functions` 6→7 (closes 8 npm-audit + reduces drift)
5. **F-107-04 MED-OPEN** — F-101-03 rate-limit Firestore migration (oldest unclosed item from 2026-05-31)

## Notes

- `widget_secrets` HIGH is the highest-value cheap-fix on this sweep
- F-101-03 (= F-107-04) is the highest-impact UNCLOSED memory item
- npm-audit moderates are real but unreachable (uuid `buf`-param OOB write path not used in CF code) — bump for hygiene + future-proofing
- All Supabase-specific bypass vectors skipped — not applicable to Firebase+Flutter stack

## Cross-references

- See [[returnurl-startswith-bypass-rate-limit-instance-local]] (F-101-03 baseline)
- See [[f94-direct-write-sweep]] (SF-068 closure)
- See [[sf078-audit99-high-bundle]] (audit/100→101 rename)
- See [[cf-deploy-cors-shape-iam-strip]] (F-107-02 deploy-side gotcha)
- See [[prod-hosting-headers-deploy-gap]] (F-107-06 audit/64 baseline)
