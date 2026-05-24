# Audit 31 — Security Audit (2026-05-23)

> **Renumbered 2026-05-24**: originally drafted as audit/31, renumbered to 31
> after collision discovered (audit/31 = Terminal A's PR-A followup PR #459;
> audit/30 = Terminal G's isAdminFromFirestore doc PR #462).

**Scope**: Firestore + Storage rules, Cloud Functions (TS, 41 files), web hosting headers, secrets, web/index.html. Ran `/security-audit:security-audit` slash command.

**Methodology**: Manual + Explore-agent CF deep-dive + advisor cross-check. Skipped Semgrep (token-heavy; manual coverage already addresses OWASP-equivalent classes).

---

## Findings

### ⚠️ HIGH-1 — SSRF redirect bypass in iCal sync

**File**: `functions/src/icalSync.ts:434-500` (`fetchIcalData`)

**Issue**: `validateIcalUrl()` is called once before the initial fetch (line 345), but redirect targets at line 466 are followed **without re-validation**. An attacker who controls an iCal feed URL (allowed: any HTTPS domain is accepted with only a log warning) can:

1. Submit `https://evil.example/feed.ics`
2. Server responds `302 Location: http://169.254.169.254/latest/meta-data/iam/security-credentials/<sa>`
3. CF follows blindly → fetches GCP metadata server → response body contains short-lived SA token
4. The post-fetch validator at line 356-358 (`!icalData.includes("BEGIN:VCALENDAR")`) throws an error that **includes the first 100 chars of the response body** → token chunks leak into logs/Sentry

**Fix**: re-run `validateIcalUrl()` on the redirect target before recursing.

### ⚠️ MED-2 — `resendGuestBookingEmail` rate-limit ordering + DoS

**File**: `functions/src/resendGuestBookingEmail.ts:68-80`

**Issues**:
- Rate-limit key is `resend_guest_email:${bookingReference}` — **no IP component**.
- Limit (3/hr) applied **before** email-match check (line 108).
- Endpoint is unauthenticated.

**Attack**: An attacker who knows a victim's booking reference (leakable via screen-share, support emails, Slack screenshots) can call the endpoint 3× with a wrong email from any IP, exhausting the per-reference budget. Result: legitimate guest sees `resource-exhausted` for 1h and cannot resend their own confirmation. This is a low-friction targeted DoS.

**Fix**: bind key to `hashIp(clientIp):bookingReference` and/or add an IP-only pre-check (e.g. 10/hr per IP) before any work.

### ⚠️ MED-3 — `loginAttempts` rule `if true` (documented but unsafe)

**File**: `firestore.rules:386-391`

**Status**: Already documented in code as "intentional" with rationale (client-side rate limit for UX). But the rule allows **any unauthenticated party to write any document** in `/loginAttempts/{email}`:

- DoS: write `lockedUntil: <100 years from now>` to victim's doc → victim's client refuses to attempt login (until manual cache reset / Firestore doc deletion).
- Bypass own lockout: write `attemptCount: 0` to evade the client check (still subject to Firebase Auth server-side limits, so impact is bounded).

**Fix (deferred — not in this PR)**: move rate-limit reads/writes to a `checkLoginRateLimit` callable that uses Admin SDK + per-IP key. Already partially built (`functions/src/authRateLimit.ts:52`). Client-side `RateLimitService` (lib/core/services/rate_limit_service.dart) should call that instead of direct Firestore writes. Followup task.

### ⚠️ MED-4 — Owner/Admin hosting missing baseline security headers

**File**: `firebase.json:22-46` (owner target), `firebase.json:96-110` (admin target)

**Missing**:
- `X-Frame-Options: DENY` → owner dashboard + admin clickjackable
- `X-Content-Type-Options: nosniff`
- `Referrer-Policy: strict-origin-when-cross-origin`

**Widget target intentionally** has `X-Frame-Options: ALLOWALL` + `frame-ancestors *` (embeddable). Do not touch.

**Fix**: add the three headers to owner+admin targets. **Skip CSP this round** — CanvasKit requires `'wasm-unsafe-eval'` + multiple gstatic/firebaseio/googleapis origins; getting it wrong breaks the app. CSP is a separate scoped task.

### ⚠️ LOW-5 — `resendBookingEmail` (owner-auth'd) has no rate limit

**File**: `functions/src/resendBookingEmail.ts:43`

**Issue**: Authenticated owner can spam guest inbox via the platform's Resend quota. Owner risk is bounded (account suspension possible), but worth adding a per-booking limit (e.g. 5/hr per booking_id) to bound Resend quota damage.

**Fix (deferred)**: add `checkRateLimit('resend_owner:${bookingId}', 5, 3600)`.

### ⚠️ LOW-6 — `passwordReset` per-email throttle missing

**File**: `functions/src/passwordReset.ts:58-70`

**Issue**: IP-rate-limit only (5/hr). Firebase Auth itself rate-limits `generatePasswordResetLink`, so impact is bounded. Per-email Firestore-backed throttle would harden against IP-rotation spam.

**Fix (deferred)**: optional; Firebase Auth's default is acceptable.

---

## Verified clean

- `availability.ts` — no PII leak, rate-limited ✓
- `getBookingByStripeSession.ts` — IP-rate, `cs_` prefix validation ✓
- `verifyBookingAccess.ts` + `guestCancelBooking.ts` — capability-based, per-IP rate ✓
- `admin/setLifetimeLicense.ts`, `admin/updateUserStatus.ts`, `migrations/migrateTrialStatus.ts` — all gate on `request.auth.token.isAdmin === true` ✓
- `deleteUserAccount.ts` — caller deletes only own account ✓
- `handleStripeWebhook` — signature verified, refund handler idempotent (Stripe's `amount_refunded` is cumulative) ✓
- `sendEmailVerificationCode` — Firestore-backed daily limit via transaction ✓
- `storage.rules` — all paths properly scoped, SF-001/SF-002/SF-025 enforced ✓
- Secret scan: no `sk_live_`, `whsec_`, `AIza...`, `.env`, service-account files committed ✓

---

## Retracted from initial agent report

The Explore-agent flagged `sendEmailVerificationCode` as HIGH (no Firestore-backed rate limit). **Wrong** — `emailVerification.ts:127-150` runs a transaction that enforces `DAILY_LIMIT=20` per email. In-memory `checkRateLimit` is supplementary per-IP. No fix needed.

---

## This PR will fix

- HIGH-1 (icalSync SSRF redirect): in scope
- MED-2 (resendGuestBookingEmail rate-limit): in scope

Other findings will be **proposed via this audit doc** and require explicit user approval to land (firebase.json hosting headers + firestore.rules `loginAttempts` move are higher blast-radius than a one-shot security fix should carry).

## See also

- `docs/SECURITY_FIXES.md` (SF-001..026 history)
- `.claude/rules/cloud-functions.md` (logger, rate-limit utilities)
- `.claude/rules/firestore.md` (T11c context, bookings read rule)
