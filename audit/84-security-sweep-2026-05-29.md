# Security Sweep — 2026-05-29

Closes audit/79 §3 findings via 3 landed PRs + 1 deferred. Triggered by
`/vibe-security` audit recap (pre-`/loop` autonomous sequence).

## PRs landed

| # | Branch | PR | Closes | Status |
|---|---|---|---|---|
| 1 | `ops/csp-hosting` | [#557](https://github.com/DanLika/rab_booking/pull/557) | audit/79 §3 #2 + #6 (CSP owner+admin + hosting headers) | ✅ merged |
| 2 | `ops/auth-pii-logout` | [#558](https://github.com/DanLika/rab_booking/pull/558) | F-58c-13 (IP-geo CF) + F-58c-14 (logout multi-store wipe) | ✅ merged |
| 3 | `ops/cors-allowlist` | [#559](https://github.com/DanLika/rab_booking/pull/559) | F-58-07 (cors:true → allowlist) | ✅ merged |
| 4 | — | — | App Check enforcement (audit/79 §3 #1) | ⏭️ DEFERRED — see below |

## Results matrix

| Fix | Result |
|---|---|
| audit/79 §3 #2 (CSP owner+admin) + #6 (hosting headers redeployed) | ENFORCED-GREEN — `curl -sI` returns full CSP on `app.bookbed.io` + `bookbed-admin.web.app`; widget keeps `frame-ancestors *`; `main.dart.js` 200 across all 3 hosts; CanvasKit / Sentry / Firebase / Stripe origins permitted incl. `worker-src 'self' blob:` (advisor catch). |
| audit/79 §3 #3 (IP-geo PII leak) — F-58c-13 | ENFORCED-GREEN — `getClientGeolocation` callable (europe-west1) deployed dev + prod; IAM `allUsers/invoker` granted; POST returns 200 + `{country, region, city}` only; client IP never leaves server. |
| audit/79 §3 #5 (logout multi-store) — F-58c-14 | ENFORCED-GREEN — `signOut()` now calls `wipeWebStorageOnLogout()` on `kIsWeb` (sessionStorage + localStorage + cookies + optional `location.reload()`). Conditional import: `web_storage_wipe.dart` → `_web.dart` (real) / `_stub.dart` (no-op on mobile/desktop). |
| audit/79 §3 #4 (cors:true → allowlist) — F-58-07 | ENFORCED-PARTIAL — 10 explicit `cors: true` occurrences across 5 files swapped to `cors: getCorsAllowlist()`; CORS smoke confirmed evil-origin rejection + allowlist echo on dev + prod. **Scope note**: audit/58 estimated ~35 callables; reality is 10 explicit + remainder relying on Firebase v2 framework default (still reflective). Broader sweep is follow-up; landing here closes the explicit-cors-true regression class. |
| audit/79 §3 #1 (App Check enforce) | DEFERRED — `firebase_app_check: ^0.4.1+4` pub dep loaded BUT no `FirebaseAppCheck.instance.activate(...)` call anywhere in `lib/`. Verified-rate metric guaranteed 0%; flipping `enforceAppCheck` on `createStripeCheckoutSession` + `getUnitAvailability` would block ALL legit traffic. Prereq: client `FirebaseAppCheck.instance.activate(webProvider: ReCaptchaV3Provider('site-key'))` per surface; ~150 LOC + reCAPTCHA Enterprise key provisioning. |

## Manual items NOT automated

- Sentry quota / inbound-filter changes (sentry.io UI only)
- Branch protection on `main` (GitHub Settings → Branches)
- App Check enforce flip — when client init lands, re-run STEP 4's verified-rate
  gate (Cloud Monitoring `firebaseappcheck.googleapis.com/request_count` ≥0.95)
  THEN flip `enforceAppCheck: true` on:
  - `functions/src/stripePayment.ts` `createStripeCheckoutSession`
  - `functions/src/availability.ts` `getUnitAvailability`

## Operational notes

**PROD CF IAM stripping**: deploying onCall with `cors: ARRAY` (vs `cors: true`)
on Firebase Functions v2 stripped the existing `allUsers/invoker` Cloud Run IAM
binding on PROD for all 7 updated CFs (europe-west1 + us-central1). ~60 s
degraded window between deploy completion and `gcloud run services
add-iam-policy-binding` re-grant. Smoke verified PROD recovered green
post-restoration. **Bake into deploy playbook**: any `cors` shape change ON
PROD → follow immediately with allUsers/invoker re-grant loop.

**Worktree .env handling**: `functions/.env*` are gitignored, so fresh
worktrees can't deploy CFs without manual `cp` from main working tree. Hit
this twice. Could be wrapped in `tool/deploy-dev.sh` cousin — out of scope.

## Memory updates queued

- `bookbed-dev-stripe-cf-egress-fail.md` ← unchanged
- New: `cf-deploy-cors-shape-iam-strip.md` — record IAM stripping class
- F-58c-13 RESOLVED — annotate memory entry
- F-58c-14 RESOLVED — annotate memory entry
- F-58-07 RESOLVED-PARTIAL — annotate memory entry

## Verification timestamps

| Step | Time (UTC) | Evidence |
|---|---|---|
| CSP deploy + smoke | 2026-05-29T14:27Z | `curl -sI` 3 hosts |
| IP-geo CF deploy + smoke | 2026-05-29T14:50Z | POST returns geo JSON |
| logout wipe code | 2026-05-29T14:53Z | PR #558 squash-merge |
| CORS deploy + smoke | 2026-05-29T15:13Z | OPTIONS preflight matrix |
| PROD IAM re-grant | 2026-05-29T15:13Z | `add-iam-policy-binding` returns `version: 1` per CF |

Author: Claude Opus 4.7 + Duško Ličanin (autonomous PROD sweep per
`/vibe-security` AUTHORIZATION envelope, 2026-05-29).
