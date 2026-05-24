# audit/35 — Follow-up tracker (2026-05-24)

Status board for items raised in `audit/35-auth-flows-smoke-2026-05-24.md` (auth flows smoke, Tier 4). Source doc lives on PR #466 branch `doc/audit-35-auth-smoke` (unmerged at time of writing).

| ID | Item | Severity | Status | Closed by |
|---|---|---|---|---|
| F-Auth-D1 | displayName digit-strip (`InputSanitizer.sanitizeName` `\p{L}` allow-list missing `\p{N}`) | MED | ✅ DONE | PR #470 (commit `bad97caa`) |
| F-Auth-D2 | CHANGELOG 6.44 says 30 s cooldown; UI is 60 s | LOW | ✅ DONE | PR #470 (CHANGELOG correction) |
| F-Auth-D3 | `checkRegistrationRateLimit` + `sendPasswordResetEmail` CFs lack `X-RateLimit-*` / `Retry-After` response headers (CONFIRMS audit/31 MED-2) | MED | 🟡 OPEN | — |
| F-Auth-D5 | `accounts:lookup` polling rate — investigate auth-state listener fan-out across Riverpod providers | LOW | 🟡 OPEN | — |
| §3.5 | Server-side verify `security_events` writes via admin SDK or Console (client-blind spot) | LOW | 🟡 OPEN | — |
| §5.2 | Capture Gmail `Authentication-Results:` block for `bookings@bookbed.io` (+ incidentally `noreply@firebaseapp.com`) → close audit/28 §5.3 | LOW | 🟡 DEFERRED | — |
| §6 | Cleanup PROD test users (2 UIDs flagged) — manual Firebase Console | P2 hygiene | 🟡 OPEN | — |

## Closed items detail

### F-Auth-D1 — displayName digit-strip — PR #470

- **Diff:** `lib/shared/utils/validators/input_sanitizer.dart` `[^\p{L}\s'\-]` → `[^\p{L}\p{N}\s'\-]` (unicode flag, allow-list)
- **Tests:** `test/shared/utils/validators/input_sanitizer_test.dart` 52/52 green; added `preserves digits in name (audit/35 F-Auth-D1)` + `preserves Unicode digits across scripts` (Arabic-Indic / Devanagari); updated 1 stale assertion (`removes script tags but preserves letters/digits` — `'John<script>alert(1)</script>Doe'` now yields `'Johnalert1Doe'`).
- **Defence-in-depth unchanged:** `_htmlTagPattern` strips HTML, `_controlCharPattern` strips control chars, allow-list still removes injection chars (`< > ; / \ " = ( ) { } & $`), `containsDangerousContent()` detector still flags XSS/SQLi.
- **Surface scope:** sanitizer is repo-wide. Owner registration (`enhanced_register_screen.dart:135-137`) AND widget guest name (`submit_booking_use_case.dart:117`) both benefit — guests with apartment numbers in their names no longer stripped.
- **Post-deploy verify recipe:** register `Test User2` on `bookbed-owner-dev.web.app` → expect `users/{uid}.full_name == "Test User2"` + `firebase.auth().currentUser.displayName == "Test User2"` + Mailinator welcome email greets `Hello Test User2,`.

### F-Auth-D2 — Cooldown drift — PR #470 (doc-only)

- **Source verdict:** `email_verification_screen.dart` `_startInitialCooldown` (line 48) + `_startCooldown` (line 290) both `_resendCooldown = 60;` — has always been 60 s. Matches Firebase Auth `sendEmailVerification()` internal rate-limit window (~60 s). CHANGELOG 6.44 text was wrong since 2026-02 ship date.
- **Diff:** `docs/CHANGELOG.md` entry 6.44 — "30-second initial cooldown" → "60-second initial cooldown" + explicit `Correction 2026-05-24 (audit/35 F-Auth-D2)` footnote noting prior text was wrong, behaviour unchanged.

## Outstanding items

### F-Auth-D3 — rate-limit headers absent

`checkRegistrationRateLimit` (eu-west1) + `sendPasswordResetEmail` (us-central1) return only standard Firebase Google-Frontend headers. No `X-RateLimit-Remaining` / `Retry-After`. Clients can only react to `{allowed:false}` response body.

**Action:** attach `res.setHeader('X-RateLimit-Remaining', N)` + `res.setHeader('Retry-After', secs)` in both CFs. See `functions/src/auth/checkRegistrationRateLimit.ts` + `functions/src/auth/sendPasswordResetEmail.ts`. Estimated effort: S (1-2 hr).

### F-Auth-D5 — auth-state listener fan-out

`accounts:lookup` polling rate observed higher than expected during smoke. Suspect: multiple Riverpod providers each install their own `FirebaseAuth.authStateChanges()` listener. Consolidate to a single shared stream → fewer wakeups.

**Action:** audit `lib/core/providers/enhanced_auth_provider.dart` + grep `authStateChanges` repo-wide. Likely candidates: `enhancedAuthProvider`, any user-profile provider, FCM token provider. Estimated effort: M (half-day, includes regression test for re-login + sign-out flows).

### §3.5 — server-side `security_events` verification

Smoke client could not directly verify Firestore writes to `security_events` (client-blind subcollection). Need either admin SDK script (`tool/verify-security-events.js`) or Firebase Console manual check.

**Action:** quick admin SDK one-liner against `bookbed-dev` to dump last N `security_events` docs per user UID. Estimated effort: XS (15 min).

### §5.2 — Gmail Authentication-Results capture

Deferred during smoke because the Mailinator inbox used does not expose Gmail-style headers. Need a real Gmail recipient to capture `Authentication-Results: mx.google.com; spf=... dkim=... dmarc=...` for the `bookings@bookbed.io` from-address (and incidentally `noreply@firebaseapp.com` for Firebase Auth verify emails).

**Action:** trigger one BB booking + one register-and-verify against a real `@gmail.com` recipient → forward raw email source to ops. Cross-reference with `memory/spf-gap-bookbed-io.md` (Resend not in SPF include; DMARC passes via DKIM-only alignment, p=none). Will close audit/28 §5.3. Estimated effort: XS (10 min once Gmail recipient available).

### §6 — PROD test user cleanup

Two UIDs created during PROD smoke + flagged in audit/35 §6 for manual deletion via Firebase Console (project `rab-booking-248fc`). Not deletable from client; needs operator with Console access.

**Action:** operator opens Firebase Console → Authentication → Users → search by smoke email → delete. Mirror cleanup recipe in `audit/15-prod-contamination-deep-check.md`. Estimated effort: XS (5 min).

## See also

- `audit/35-auth-flows-smoke-2026-05-24.md` (PR #466 branch `doc/audit-35-auth-smoke`) — source smoke report with §4 findings detail + §8 backlog
- `docs/CHANGELOG.md` entry 6.91 — audit/35 follow-up bullet (PR #470)
- `CLAUDE.md` audit/35 index line — PR #470 closure summary
- `memory/prod-auth-smoke-2026-05-24.md` — smoke session notes
- `memory/test-account-prod.md` — PROD smoke account safety rules
- `memory/spf-gap-bookbed-io.md` — informs §5.2 inference
