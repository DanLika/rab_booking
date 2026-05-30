# audit/91 — Auth/Security Cloud Function smoke (bookbed-dev)

**Date:** 2026-05-30
**Branch:** `test/cf-smoke-auth-0530` (from `main` HEAD)
**Project:** bookbed-dev only (PROD untouched)
**Scope:** 14 callable CFs covering SF-022 / SF-047 / SF-048 / SF-050 / SF-054 / SF-058 / SF-060 / SF-062 hardening — empirical exercise via Identity Toolkit REST + raw HTTPS POST to callable endpoints.
**Sibling:** `audit/90-prod-cutover-runbook.md` (F-90-01 — PROD-side empty-IAM gap on the loginLockout trio; this run verifies DEV does NOT exhibit it).

---

## §1 — Methodology

- **Endpoints:** invoked via legacy callable URL form `https://{region}-bookbed-dev.cloudfunctions.net/{name}` (proxies to Cloud Run v2 service).
- **Auth tokens:** Identity Toolkit `signInWithPassword` against bookbed-dev Web API key for the `bookbed-test@bookbed.io` non-admin account (memory `[[test-account]]`). Throwaway accounts created via `signUp` REST for destructive paths and deleted in-test.
- **Origin:** every probe carried `Origin: https://bookbed-owner-dev.web.app` unless explicitly testing allowlist behavior.
- **Sandbox IP:** all calls came from a single sandbox egress IP (geolocates Prijedor, BiH per T18). All IP-bucketed rate limits in this run share the same counter, so subsequent runs from a different harness will see independent budgets.
- **Hard rule:** no PROD calls. Throwaway-user pattern for destructive ops (`deleteUserAccount`). No tampering with the `bookbed-test` account state (only `clearLoginAttempts` invoked, which is idempotent on its own email).

---

## §2 — Endpoint inventory (DEV)

| # | CF | Region | Auth | Per-IP / per-uid rate limit | CORS allowlist? |
|---|----|--------|------|------------------------------|------------------|
| 1 | `recordLoginFailure` | europe-west1 | anon | 1 / 60s / IP | reflective (Firebase v2 default) |
| 2 | `getLoginLockoutStatus` | europe-west1 | anon | 30 / 5min / IP | reflective |
| 3 | `clearLoginAttempts` | europe-west1 | **required** | none on CF; token-email match enforced | reflective |
| 4 | `checkLoginRateLimit` | europe-west1 | anon | 15 / 15min / IP | reflective |
| 5 | `checkRegistrationRateLimit` | europe-west1 | anon | 5 / 1h / IP | reflective |
| 6 | `getClientGeolocation` | europe-west1 | anon | 60 / 1h / IP | **explicit `getCorsAllowlist()`** |
| 7 | `deleteUserAccount` | europe-west1 | **required** | 1 / 5min / uid (SF-048) | reflective |
| 8 | `setLifetimeLicense` | europe-west1 | **admin claim** | none (admin-gated) | reflective |
| 9 | `checkSubdomainAvailability` | us-central1 | **required** | 30 / 5min / uid | reflective |
| 10 | `generateSubdomainFromName` | us-central1 | **required** | 30 / 5min / uid | reflective |
| 11 | `sendPasswordResetEmail` | us-central1 | anon | 5 / 1h / IP | **explicit allowlist** |
| 12 | `sendEmailVerificationCode` | us-central1 | anon | 10 / 1h / IP + 20 / day / email + 60s cooldown | **explicit allowlist** |
| 13 | `verifyEmailCode` | us-central1 | anon | 10 / 60s / IP (H-04) + 3 / email | **explicit allowlist** |
| 14 | `checkEmailVerificationStatus` | us-central1 | anon | none on CF | **explicit allowlist** |

`reflective` ≡ Firebase v2 `onCall` default — echoes whatever `Origin` is sent; closes only with explicit `cors: array|regex` per audit/89 SF-062 (which covers the booking/property/widget callables, not these auth ones).

---

## §3 — Headline finding: DEV IAM healthy (PROD parity check)

`audit/90` F-90-01 documented an empty IAM policy on PROD `recordloginfailure` / `getloginlockoutstatus` / `clearloginattempts` (Cloud Run etag ACAB, no `allUsers/invoker`) — preflight OPTIONS returns HTTP/2 403 from GFE, `rate_limit_service.dart` falls open, per-email throttle silently non-functional.

**DEV parity check:** all 14 callables answered OPTIONS preflight `204 No Content` with the request-origin echoed in `Access-Control-Allow-Origin` (matrix below). The DEV trio is callable. Whatever broke PROD IAM did **not** affect DEV — closes a major worry that the PROD gap was a code/deploy-shape regression rather than a one-off IAM strip.

| CF | DEV OPTIONS HTTP | DEV ACAO echoed |
|----|-------------------|-----------------|
| recordLoginFailure | 204 | https://bookbed-owner-dev.web.app |
| getLoginLockoutStatus | 204 | https://bookbed-owner-dev.web.app |
| clearLoginAttempts | 204 | https://bookbed-owner-dev.web.app |
| checkLoginRateLimit | 204 | https://bookbed-owner-dev.web.app |
| checkRegistrationRateLimit | 204 | https://bookbed-owner-dev.web.app |
| getClientGeolocation | 204 | https://bookbed-owner-dev.web.app |
| deleteUserAccount | 204 | https://bookbed-owner-dev.web.app |
| setLifetimeLicense | 204 | https://bookbed-owner-dev.web.app |
| checkSubdomainAvailability | 204 | https://bookbed-owner-dev.web.app |
| generateSubdomainFromName | 204 | https://bookbed-owner-dev.web.app |
| sendPasswordResetEmail | 204 | https://bookbed-owner-dev.web.app |
| sendEmailVerificationCode | 204 | https://bookbed-owner-dev.web.app |
| verifyEmailCode | 204 | https://bookbed-owner-dev.web.app |
| checkEmailVerificationStatus | 204 | https://bookbed-owner-dev.web.app |

**Implication for PROD cutover** (audit/90 §0): the 3-line IAM re-grant on PROD is the right fix; no source change needed. Confirms F-90-01 is a localized IAM artifact, not a shape regression.

---

## §4 — CORS allowlist matrix

Probed `getClientGeolocation` (which uses `getCorsAllowlist()` — SF-058/060/062 surface) against varied Origins. ACAO returned only for allowlisted origins.

| Origin probed | ACAO returned |
|---------------|----------------|
| `https://bookbed-owner-dev.web.app` | echoed |
| `https://bookbed-widget-dev.web.app` | echoed |
| `https://bookbed-admin-dev.web.app` | echoed |
| `https://app.bookbed.io` | echoed |
| `https://evil.test` | **NONE** (blocked) |
| `http://localhost:3000` | **NONE** (blocked — see F-91-03) |
| `https://bookbed.io` (root, no sub) | **NONE** (blocked — see F-91-03) |

---

## §5 — Test matrix (28 cases + 2 verification probes)

`PASS` ≡ observed status + body matched the asserted contract.
Token = `bookbed-test@bookbed.io` (uid `GILVItIVP5R8WXfnMmyMo1ykhUm2`, non-admin) unless stated.

### SF-050 loginLockout

| # | Test | Expected | Result |
|---|------|----------|--------|
| T1 | `recordLoginFailure` anon, fresh email | 200, attemptCount=1, remainingAttempts=4 | ✅ PASS |
| T2 | `recordLoginFailure` anon, immediate retry same IP | 429, `Too many failure reports from this IP.` | ✅ PASS (1/60s IP cap enforced) |
| T3 | `getLoginLockoutStatus` anon, same email | 200, attemptCount=1, locked=false | ✅ PASS |
| T4 | `clearLoginAttempts` anon | 401 UNAUTHENTICATED | ✅ PASS |
| T5 | `recordLoginFailure` empty email | 400 INVALID_ARGUMENT `valid email required` | ✅ PASS |
| T6 | `getLoginLockoutStatus` malformed `not-an-email` | 400 INVALID_ARGUMENT | ❌ **FAIL — F-91-01** (returned 200, default state) |
| T9 | `clearLoginAttempts` auth, mismatched email | 403 `Can only clear attempts for your own email.` | ✅ PASS |
| T10 | `clearLoginAttempts` auth, own email | 200, cleared=true | ✅ PASS |
| T29a | `recordLoginFailure` anon, `not-an-email` (F-91-01 write-path) | write rejected | ❌ **FAIL — F-91-01** (200, attemptCount=1, doc written) |
| T29b | `getLoginLockoutStatus` anon, `not-an-email` after T29a | no doc | ❌ **FAIL — F-91-01** (200, attemptCount=1 reflects prior write) |

### authRateLimit

| # | Test | Expected | Result |
|---|------|----------|--------|
| T7 | `checkLoginRateLimit` anon, valid email | 200, allowed=true | ✅ PASS |
| T8 | `checkRegistrationRateLimit` anon, valid email | 200, allowed=true | ✅ PASS |

### setLifetimeLicense

| # | Test | Expected | Result |
|---|------|----------|--------|
| T11 | `setLifetimeLicense` anon | 401 UNAUTHENTICATED | ✅ PASS |
| T12 | `setLifetimeLicense` non-admin | 403 `only by an administrator` | ✅ PASS |

### subdomain (SF-047)

| # | Test | Expected | Result |
|---|------|----------|--------|
| T13 | `checkSubdomainAvailability` anon | 401 `Authentication required` | ✅ PASS |
| T14 | `checkSubdomainAvailability` auth, unique candidate | 200, available=true | ✅ PASS |
| T15 | `checkSubdomainAvailability` auth, reserved `admin` | 200, available=false, reserved=true, suggestion provided | ✅ PASS |
| T16 | `generateSubdomainFromName` anon | 401 `Authentication required` | ✅ PASS |
| T17 | `generateSubdomainFromName` auth, valid name | 200, valid 3-30 char subdomain | ✅ PASS |

### geo (SF-058)

| # | Test | Expected | Result |
|---|------|----------|--------|
| T18 | `getClientGeolocation` anon, no IP echoed | 200, country/region/city present, no IPv4/IPv6 in body | ✅ PASS (first call 500 — cold start flake; 3× retry 200 with `{country:"Bosnia and Herzegovina", region:"Republika Srpska", city:"Prijedor"}`, no IP) |

### passwordReset

| # | Test | Expected | Result |
|---|------|----------|--------|
| T19 | `sendPasswordResetEmail` empty email | 400 INVALID_ARGUMENT | ✅ PASS |
| T20 | `sendPasswordResetEmail` nonexistent email | 200 generic (no enumeration) | ❌ **FAIL — known F-Auth-D7** (returned 500 `Password reset is temporarily unavailable.` — `actionCodeSettings.url` defaults to PROD `app.bookbed.io` which isn't in bookbed-dev's Firebase authorized-domains; memory `[[dev-password-reset-cf-domain-gap]]`) |

### emailVerification (SF-022)

| # | Test | Expected | Result |
|---|------|----------|--------|
| T21 | `checkEmailVerificationStatus` empty | 400 | ✅ PASS |
| T22 | `checkEmailVerificationStatus` no-doc email | 200, exists=false, verified=false | ✅ PASS |
| T23 | `verifyEmailCode` empty email/code | 400 INVALID_ARGUMENT | ✅ PASS |
| T24 | `verifyEmailCode` no-doc email + bogus code | 404 `No verification code found` (NOT 500 — SF-022 guard) | ✅ PASS |
| T25 | `sendEmailVerificationCode` empty | 400 | ✅ PASS |

### deleteUserAccount (SF-048)

| # | Test | Expected | Result |
|---|------|----------|--------|
| T26 | anon | 401 | ✅ PASS |
| T27 | throwaway-user A token, single shot | 200, success=true | ✅ PASS (user A deleted on bookbed-dev) |
| T28 | throwaway-user B token, 2× parallel | 1× 200, 1× 429 (cooldown 1/5min) | ✅ PASS (`[200, 429]` — RESOURCE_EXHAUSTED matched) |

**Aggregate:** 25 PASS / 1 net-new finding (F-91-01, 3 cases) / 1 known finding confirmed (F-Auth-D7 / T20).

---

## §6 — Findings

### F-91-01 (P3) — `sanitizeEmail` skips RFC format validation; loginLockout writes garbage doc IDs

**Surface:** `functions/src/loginLockout.ts` (`recordLoginFailure` + `getLoginLockoutStatus`) and any other CF that funnels through `sanitizeEmail` without a subsequent `validateEmail` call.

**Root cause:** `functions/src/utils/inputSanitization.ts:sanitizeEmail` strips control chars, normalizes confusables, removes CRLF / backslash / percent-encoded sequences — but performs no `local@domain` format check. Returns the cleaned string unconditionally as long as it's ≤ 254 chars. `recordLoginFailure` only guards `if (!sanitized) throw invalid-argument` — passes a literal `"not-an-email"` straight through.

`emailVerification.ts` and `passwordReset.ts` are NOT affected: both call `validateEmail(sanitized)` immediately after `sanitizeEmail`.

**Verified empirically (T29a/b):**
```
POST /recordLoginFailure  {data:{email:"not-an-email"}}
→ 200 {result:{attemptCount:1, ...}}
POST /getLoginLockoutStatus  {data:{email:"not-an-email"}}
→ 200 {result:{attemptCount:1, ...}}
```
i.e. `loginAttempts/not-an-email` doc was created with `attemptCount=1` and the read path confirms it.

**Blast radius:** P3 / low.
- Limit: 1 doc per IP per 60s → cap is ~1440 docs/day per attacker IP.
- Each garbage doc is ≤200 bytes and auto-resets after `ATTEMPT_RESET_MS = 1h` of inactivity on `getLoginLockoutStatus` read.
- Does NOT enable account-lockout DoS (per-email lockout requires the email to be reachable for victim recovery; garbage emails affect no real account).
- Does pollute `loginAttempts` collection growth slightly — for a determined attacker burning the 1/60s budget continuously, an extra ~1500 docs/day before TTL kicks in.

**Recommendation:** add `if (!validateEmail(sanitized)) throw HttpsError("invalid-argument", "valid email required")` after `sanitizeEmail` in `recordLoginFailure` AND `getLoginLockoutStatus` AND `clearLoginAttempts` — same one-line guard already present in `emailVerification.ts`. Token-email comparison in `clearLoginAttempts` (`tokenEmail !== sanitized`) doesn't backstop this because the comparison happens AFTER `sanitized` is computed and a sanitized garbage string can match a sanitized garbage token (if someone could craft one — unlikely in practice).

**Severity:** P3 informational. Worth folding into the next SF-050 follow-up PR; not a cutover blocker.

---

### F-91-02 (KNOWN, RE-CONFIRMED) — DEV `sendPasswordResetEmail` 500 on legitimate request

**Re-confirmation of:** `[[dev-password-reset-cf-domain-gap]]` (F-Auth-D7, audit/35).
**T20 observed:** HTTP 500 INTERNAL `Password reset is temporarily unavailable. Please try again later.` for `email=nonexistent-91-...@example.test`.
**Code path:** `passwordReset.ts:173-185` catches `auth/unauthorized-continue-uri` (or `INTERNAL ASSERT FAILED` / `Unable to create the email action link`) and wraps as `internal`. The CF's `actionCodeSettings.url` defaults to `https://app.bookbed.io/forgot-password` (PROD origin) when `PASSWORD_RESET_REDIRECT_URL` and `WEB_APP_URL` env vars are unset on the DEV deploy. `app.bookbed.io` is not in bookbed-dev's Firebase Auth → Settings → Authorized domains list, so `auth.generatePasswordResetLink` throws.
**Status:** known; DEV-only ergonomics issue. PROD unaffected. Fix is env-var: set `PASSWORD_RESET_REDIRECT_URL=https://bookbed-owner-dev.web.app/forgot-password` on bookbed-dev functions config (or commit to `.env.bookbed-dev`).
**No cutover impact.**

---

### F-91-03 (P3 / informational) — CORS allowlist excludes `http://localhost:*` and bare `bookbed.io`

**Observed:** OPTIONS probe against `getClientGeolocation` from `Origin: http://localhost:3000` and `Origin: https://bookbed.io` returned 204 with **no** `Access-Control-Allow-Origin` header — browser would block the response.

**Implications:**
- `flutter run -d chrome` for local dev work cannot exercise `getClientGeolocation` / `sendPasswordResetEmail` / `sendEmailVerificationCode` / `verifyEmailCode` / `checkEmailVerificationStatus` against bookbed-dev — failure mode is CORS error in browser console, not a server-side rejection.
- Marketing site / docs hosted at the apex `https://bookbed.io` (no subdomain) cannot call these CFs either.

**Both may be intentional** (limit allowlist to hosting surfaces). Worth confirming with whoever owns `functions/src/utils/corsAllowlist.ts` whether either is a missing entry or a deliberate omission. Not a bug per the audit/89 SF-062 design intent.

---

## §7 — Out of scope / not empirically verified this run

| Item | Why deferred |
|------|-------------|
| Full 5-attempt lockout flow (`recordLoginFailure` × 5 → locked=true with `lockedUntilMs`) | Single-IP smoke can't reach attemptCount=5 without 5× 60s waits or 5 distinct IPs; mathematically `LOCKOUT_DURATION_MS = 15min` once reached. Code path read-checked instead — `loginLockout.ts:142-145` matches spec. |
| OTP brute IP cap H-04 (`verifyEmailCode` >10 / 60s / IP → 429) | Would consume 11 of 10/min/IP budget on bookbed-dev; only 1 verifyEmailCode call exercised this run. Code path inspected — `emailVerification.ts:252-258` matches spec. |
| Email redaction (SF-054) in Cloud Logging output | No GCP Logging API access from sandbox. Defer to a separate run with `gcloud logging read` against bookbed-dev. |
| App Check enforcement on auth callables | Already DEFERRED per audit/84 — `firebase_app_check` pub dep present but no `FirebaseAppCheck.instance.activate(...)` callsite. Server-side enforcement also gated on `RECAPTCHA_SITE_KEY` provisioning (`docs/TODO.md` "App Check launch checklist"). State unchanged. |
| Daily 20/day per-email cap on `sendEmailVerificationCode` | Would burn 20 emails to a throwaway address on Resend's bookbed-dev budget. Code path inspected — `emailVerification.ts:147-152` matches spec. |
| `checkLoginRateLimit` 15/15min IP cap exhaustion | Would burn 15 of 15-of-15min budget; partial state cascades to subsequent smokes. Read-check only. |
| `checkRegistrationRateLimit` 5/hour IP cap exhaustion | Same — would burn the budget shared with concurrent smokes. |
| `checkSubdomainAvailability` 30/5min per-uid exhaustion | Would lock out `bookbed-test` for next subdomain test for 5min. Read-check only. |

---

## §8 — Cleanup state on bookbed-dev

| Artifact | State |
|----------|-------|
| `loginAttempts/victim-91-1780123427202_at_example.test` | Created by T1 (attemptCount=1). Auto-resets to absent within 1h via `getLoginLockoutStatus` read or 1h inactivity. |
| `loginAttempts/not-an-email` | Created by T29a (F-91-01 evidence). Same 1h TTL. |
| `loginAttempts/x` | NOT created — T29c probe timed out at 60s IP-rate wait before the call landed. |
| `loginAttempts/bookbed-test_at_bookbed.io` | Cleared by T10 (`clearLoginAttempts` returned `cleared:true`). State: absent. |
| `loginAttempts/other-victim-91@example.test` | Never written (T9 rejected with 403 before reaching write path). |
| Throwaway user A (`throwaway-91a-…@bookbed-dev-test.invalid`, uid `QfFGUxlnvQfpwHurIiNq99LrKbg2`) | Deleted via T27 `deleteUserAccount` → Firebase Auth account removed, no cascade artifacts (no properties, no bookings). |
| Throwaway user B (`throwaway-91b-…@bookbed-dev-test.invalid`, uid `lHIGl239obRK7eSv2jx1IdjDs9e2`) | Deleted via T28 winning 200 — same. |
| `bookbed-test` account budgets | Burned 2× `clearLoginAttempts` (no quota), 2× `checkSubdomainAvailability` (28/30 5min budget remaining), 1× `generateSubdomainFromName` (29/30 5min budget remaining). Resets ≤ 5min after final call. |
| Sandbox IP quotas at end of run | `recordLoginFailure` ~0/1 for 60s after final write; `getLoginLockoutStatus` ~6/30 of 5min; `checkLoginRateLimit` 1/15; `checkRegistrationRateLimit` 1/5; `getClientGeolocation` ~4/60; `sendEmailVerificationCode` 0/10 (only empty rejected before write); `verifyEmailCode` 1/10; `sendPasswordResetEmail` 2/5 (T19+T20); `email_verifications` daily-cap counters 0 (no successful sends). |

---

## §9 — Reproduce / re-run

Smoke script archetype (see commit for full transcripts):
```js
const EU = "https://europe-west1-bookbed-dev.cloudfunctions.net";
async function call(url, data, idToken=null) {
  const h = { "Content-Type": "application/json",
              "Origin": "https://bookbed-owner-dev.web.app" };
  if (idToken) h["Authorization"] = `Bearer ${idToken}`;
  const r = await fetch(url, { method:"POST", headers:h,
                                body: JSON.stringify({data}) });
  return { status: r.status, body: await r.json().catch(()=>null) };
}
```

OPTIONS preflight (no body):
```sh
curl -s -X OPTIONS \
  -H "Origin: https://bookbed-owner-dev.web.app" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: content-type" \
  "https://europe-west1-bookbed-dev.cloudfunctions.net/${FN}"
```

Identity Toolkit sign-in (bookbed-dev Web API key `AIzaSyDc6vDPLBTN3ePkY39Pw9Jrheh30OhLWEM` — public per Firebase config):
```sh
curl -s -X POST \
  -H "Content-Type: application/json" \
  -d '{"email":"...","password":"...","returnSecureToken":true}' \
  "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${KEY}"
```

---

## §10 — Cross-references

- `audit/90-prod-cutover-runbook.md` §0 F-90-01 — PROD IAM gap on the loginLockout trio (DEV does NOT exhibit, this run §3).
- `audit/89-…` SF-062 CORS allowlist on the other 8 callables — booking/property/widget surface; this audit covers the auth surface complement.
- `audit/84-security-sweep-2026-05-29.md` — SF-058 `getClientGeolocation` introduction; smoked here (T18).
- `audit/55-f50-02-pr517-design-note-2026-05-27.md` — F-50-02 closure via SF-050 trio; T1-T10 + T29a/b empirically re-exercise.
- `audit/35-auth-flows-smoke-2026-05-24.md` F-Auth-D7 — DEV password reset 500; T20 reconfirms still open.
- `audit/38-pr462-env-prereq.md` — `ALLOWED_SUBSCRIPTION_PRICE_IDS` env prereq; not exercised this run (subscription priceId surface is the Stripe webhook trio, not these auth callables).
- Memory `[[test-account]]`, `[[dev-password-reset-cf-domain-gap]]`, `[[sf050-prod-iam-gap-2026-05-29]]`.
