# audit/99 — Security audit (multi-agent sweep, 2026-05-30)

**Scope:** Full repo sweep after invocation of `/security-audit:run` skill.
**Skill:** vibe-coding-academy/security-audit v2.1.0 (Supabase-shaped → adapted to Firebase).
**Method:** 4 parallel `security-engineer` agents (rules, CFs, Flutter client, deps/config), each pre-loaded with `CLAUDE.md` audit index + `MEMORY.md` to suppress duplicates.
**Reconciled against:** audit/01..98 + MEMORY.md topic files. Only NET-NEW or CONFIRM-OPEN findings listed.

## Headline

`firestore.rules:264-266` `bookings` update rule uses correct SF-068 shape (`!affectedKeys().hasAny([deny-list])`) but the deny-list covers status-machine fields ONLY. PR #554 (audit/78 Phase B) scoped it that narrowly; PR #578 / SF-068 F-94 swept properties/ical_feeds/widget_settings but did **not** sweep `bookings`. Property owner can write CF-managed scalars on their own booking via plain Firestore SDK. **Reachability requires attacker to know a victim's `pi_...` value** (not enumerable from client) for the refund-routing variant — so realistic exploit scope is **local-state corruption on the attacker's own bookings**: forging `emails_sent.*` to suppress idempotent CF re-sends (audit/34 §5 read sites at bookingManagement.ts:316,461,499-511), rewriting `booking_reference` to break support workflows, rewriting `owner_id` to detach a booking from its dashboard list, tampering `created_at` audit-trail. The "wrong-booking refund" variant remains possible if a PI value leaks through any future client/log path — preventive close mirrors SF-068.

## Findings — by severity

### HIGH (1)

| # | ID | File:line | Finding |
|---|---|---|---|
| 99-01 | F-99-01 | `firestore.rules:264-266` | `bookings` update deny-list is status-machine-only — `payment_intent_id`, `emails_sent.*`, `booking_reference`, `owner_id`, `created_at`, `source`, `provider_id` all owner-writable on own bookings. Exploits (realistic, no prerequisite): forge `emails_sent.initial_trigger_processed=true` to suppress CF idempotent re-send; rewrite `owner_id`/`booking_reference` to break support tooling; tamper `created_at` audit trail. Latent (needs PI leak): refund-routing collision via stripePayment.ts:1015 `collectionGroup('bookings').where('payment_intent_id','==',X).limit(1)` — would corrupt local refund state (booking flagged refunded, owner emailed, calendar window released), not Stripe-side funds. **Fix:** extend the existing `!affectedKeys().hasAny([...])` deny-list at line 266 by appending `'payment_intent_id', 'emails_sent', 'booking_reference', 'owner_id', 'created_at', 'source', 'provider_id'`. Same shape as SF-068 sibling closures. |

### MEDIUM (3)

| # | ID | File:line | Finding |
|---|---|---|---|
| 99-02 | F-99-02 | `functions/src/passwordHistory.ts:76,137` | `checkPasswordHistory` + `savePasswordToHistory` have no rate-limit; bcrypt `compareSync` loop on stored hashes = asymmetric compute-DoS (self-scope). **Fix:** `checkRateLimit('pwhist:${userId}', 10, 300)` per passwordReset.ts pattern. |
| 99-04 | F-99-04 | `firebase.json:121` (widget hosting) | Widget target has only `frame-ancestors *` — no `script-src`/`connect-src`/`object-src` controls. Widget XSS gets unrestricted egress. **Fix:** add scoped CSP retaining `frame-ancestors *` but constraining `script-src 'self' 'unsafe-inline' 'unsafe-eval' https://js.stripe.com`, `connect-src 'self' https://*.cloudfunctions.net https://*-rab-booking-248fc.cloudfunctions.net`, `object-src 'none'`, `base-uri 'self'`. |
| 99-05 | F-99-05 | `firebase.json:30-90,135-195` (owner + admin) | Missing `Cross-Origin-Opener-Policy`. Owner dashboard runs Stripe Connect onboarding in popup; without COOP, `window.opener` reachable from popup = tabnabbing surface. **Fix:** `Cross-Origin-Opener-Policy: same-origin-allow-popups` on owner + admin; leave widget on `unsafe-none` for embeddability. |

### LOW (7) + INFO (4)

| # | ID | File:line | Finding | Sev |
|---|---|---|---|---|
| 99-06 | F-99-06 | `firestore.rules:164-172` | `devices` update allows `platform` mutation; forensic tamper risk (session-token holder on device A can rewrite to look like device B). `set(merge:true)` re-issuing same value = no-op per memory `firestore-affectedkeys-set-merge`; legit refresh unaffected. **Fix:** drop `platform` from `hasOnly` → `['lastSeenAt', 'fcmToken', 'appVersion']`. | LOW |
| 99-07 | F-99-07 | `functions/src/revokeTokens.ts:38` | `revokeAllRefreshTokens` no rate-limit; self-storm = Auth API load + own-device cascade. **Fix:** `checkRateLimit('revoke:${userId}', 3, 300)`. | LOW |
| 99-08 | F-99-08 | `functions/src/icalSync.ts:406` | `syncIcalFeedNow` no rate-limit; combined with hex-IPv6 SSRF residual (memory `ssrf-ipv4-mapped-ipv6-hex-hole`, audit/56) raises exploitation budget. **Fix:** `enforceRateLimit(uid, "ical_sync_now", {maxCalls:10, windowMs:60000})`. | LOW |
| 99-09 | F-99-09 | `functions/src/smsService.ts:13-15` | Twilio creds via `process.env.X \|\| ""` not `defineSecret`. Dormant (early-return if empty) but when activated bypasses Secret Manager rotation discipline established in SF-051 / audit/52. **Fix:** `defineSecret("TWILIO_*")` + bind via `{secrets: [...]}`. | LOW |
| 99-10 | F-99-10 | `functions/src/{emailService,depositCalculation,dateValidation,resendBookingEmail,resendGuestBookingEmail}.ts` | Shared validators `throw new Error(...)` instead of `HttpsError("invalid-argument", ...)`. Per memory `sentry-beforesend-httperror-only`: plain Error escalates to `internal` HttpsError, reaches Sentry as noise. Same class as FLUTTER-7B (closed PR #568 / SF-066). **Fix:** swap to `HttpsError`. | LOW |
| 99-11 | F-99-11 | `lib/core/utils/web_utils_web.dart:325,332` | `sendMessageToParent` posts `targetOrigin: '*'`. Today only one caller (stripe-popup-close, no PII) so LOW. Inconsistent with iframe_resizer.js + payment_bridge.js trusted-origin pattern; footgun for future PII-bearing callers. **Fix:** require explicit `targetOrigin` parameter OR compute from `_isAllowedPostMessageOrigin`. | LOW (MED footgun) |
| 99-12 | F-99-12 | `firebase.json:56,168` | CSP `connect-src https://*.cloudfunctions.net` wildcard allows ANY GCP project's CFs from owner/admin origin. **Fix:** replace with `https://*-rab-booking-248fc.cloudfunctions.net` (per-project, per-region). Defer to hardening sprint. | LOW |
| 99-13 | F-99-13 | `firebase.json:56,168` | CSP `connect-src` missing `https://*.a.run.app` — silent block if Gen2 callables migrate to Cloud Run domains. **Fix:** add if/when migration begins. | LOW |
| 99-14 | F-99-14 | `firebase.json:56,168` | CSP `https://*.googleapis.com` overbroad (covers storage/compute/etc). **Fix:** narrow to `identitytoolkit`, `firestore`, `firebaseinstallations`, `firebaseappcheck`, `securetoken`, `oauth2`, `fcm`. Defer. | LOW |
| 99-15 | F-99-15 | `lib/core/services/deep_link_service.dart:75-143` | Cold-start auth race: `_handleAppDeepLink` calls `context.go()` for `/owner/*` without `FirebaseAuth.currentUser` check. Dormant — no `app_links`/`uni_links` stream wired in pubspec. F-62-05 class. **Fix:** front-load auth-state guard before path switch. | INFO (latent) |
| 99-16 | F-99-16 | `web/firebase-messaging-sw.js:121` + `web/index.html:795` | `urlToOpen` concatenates `bookingId` from FCM push payload without format validation. Trust-bounded by FCM signing today; defense-in-depth via `/^[A-Z0-9_-]{6,40}$/i` regex. | INFO |
| 99-17 | F-99-17 | `functions/package.json` (transitive) | 8 moderate `uuid <11.1.1` CVE (GHSA-w5hq-g745-h8pq) via `firebase-admin@12` → `@google-cloud/storage` → `gaxios`. Bounds-check on buf path; not exploitable in CF context (no untrusted buf input). **Fix:** defer — needs `firebase-admin@13` upgrade. | INFO (transitive) |
| 99-03 | F-99-03 | `firestore.rules:181-194` | `user_profiles` deny-list missing Stripe linkage mirror from `/users/{uid}` (lines 67-72,80-85). Comment at line 176 promises mirror but never backfilled when SF-vibe57 H-01 added Stripe fields. **Latent** — current CFs only delete `user_profiles` (deleteUserAccount.ts:396), zero read sites for `.stripeCustomerId` etc. INFO until a future read appears; comment drift is the structural risk. **Fix:** append `stripe_account_id`, `stripe_customer_id`, `stripe_connected_at`, `stripeSubscriptionId`, `stripeCustomerId` to both `hasAny` arrays when convenient. | INFO (latent) |

### CONFIRM-OPEN (1)

| # | ID | File:line | Finding |
|---|---|---|---|
| 99-18 | audit/89 followup | ~15 callables across `stripeConnect.ts`, `stripeSubscription.ts`, `resendBookingEmail.ts`, `verifyBookingAccess.ts`, `getBookingByStripeSession.ts`, `customEmail.ts`, `migrations/migrateTrialStatus.ts`, `admin/*`, `passwordHistory.ts`, `revokeTokens.ts`, `authRateLimit.ts`, `syncIcalFeedNow`, `createOwnerBookingAtomic`, `updateBookingAtomic` | Still missing `cors: getCorsAllowlist()` after PR #565 / audit/89 closed 8. Auth-gated so HIGH→LOW, but reflective-Origin default per audit/58 F-58-07 remains exploitable in cookie/CSRF contexts. **Fix:** sweep PR + post-deploy `allUsers/invoker` re-grant loop (memory `cf-deploy-cors-shape-iam-strip`). |

## Clean checks — no findings

- Stripe webhook signature: `stripePayment.ts:930` uses `webhooks.constructEvent(req.rawBody, sig, secret)` correctly
- `enforceAppCheck: false` on availability + stripe: intentional per SF-046
- ADC pattern: no service-account JSON loading
- `onBookingCreated` idempotency: CLOSED audit/34 §5 (bookingManagement.ts:316)
- `SecureStorageService`: SF-007 verified (no password storage)
- `SharedPreferences` use: only theme/locale/view-mode/form-draft; no auth/Stripe tokens
- `payment_bridge.js` receive path: solid origin check via URL parsing + `.endsWith('.bookbed.io')`
- `HtmlUtils.escapeHtml`: applied at every PII insertion in email templates
- No `WebView` / `flutter_html` / `innerHTML` / `document.write` on user content
- `.gitignore`: `.env*` family + `*.key` + `*.keystore` properly ignored; 0 tracked secrets in `git ls-files`
- HSTS preload syntax valid (1y + includeSubDomains + preload)
- `**/*.map` excluded from all 3 hosting targets
- No `Access-Control-Allow-Origin` on hosting (CFs own CORS via `getCorsAllowlist()`)

## Suppressed duplicates (already documented in audit/*)

F-50-02 (CLOSED PR #517), F-50-04 (CLOSED PR #495), F-50-09/10/11/12 (CLOSED PR #567), F-58c-13 logout multi-store + IP-geo (CLOSED PR #558), F-67-01 owner confirm/reject (OPEN — known), F-67-03 widget storage leak (OPEN — known), F-86-01 CORS allowlist (CLOSED dev PR #565), F-86-02 unbounded CG queries (LOW OPEN), F-90-01 SF-050 PROD IAM gap (🚨 OPEN — operator-gated), F-91-02 storage DELETE (CLOSED SF-067), F-92-01 iCal token (CLOSED SF-063), F-93-02 findBookingById (CLOSED PR #572), F-94-02/03/04 direct-write (CLOSED PR #578 SF-068), F-94-02-CREATE squat (OPEN, pending lib refactor), F-CUT-01 lockfile drift (CLOSED commit 167e6353), SF-051 Stripe key leak (CLOSED), SF-052 Sentry DSN (CLOSED), 18 widget silent-guards (KNOWN), payment-bridge DEV whitelist gap (OPEN LOW), Flutter web canvas semantics gap (KNOWN F-58c-21), Marionette gotchas (KNOWN), DateFormat static-locale trap (CLOSED PR #471).

## Recommended action order

1. **P1** — F-99-01 bookings affectedKeys (HIGH; idempotency-forge + audit-trail-tamper exploitable today; refund-routing latent on PI leak; single rules patch, mirrors SF-068)
2. **P2** — F-99-02 passwordHistory rate-limit (MED; ~10 lines)
3. **P3** — F-99-04 widget CSP scope (MED; one firebase.json edit per surface)
4. **P3** — F-99-05 COOP on owner+admin (MED; one firebase.json edit per surface)
5. **P4** — F-99-07, F-99-08 rate-limits (LOW; bundle with F-99-02)
6. **P4** — F-99-10 plain-Error → HttpsError refactor (LOW; Sentry noise)
7. **P5** — Audit/89 CORS sweep + IAM re-grant (CONFIRM-OPEN; ~15 callables in one PR; mind cors-shape IAM-strip class)
8. **Defer** — F-99-03 user_profiles mirror (INFO, latent), F-99-09 smsService (dormant), F-99-12/13/14 CSP wildcards, F-99-15/16 latent, F-99-17 uuid transitive (awaiting firebase-admin@13)

## Method notes

- **Source-code audit only.** Working-tree state. Deployed PROD/DEV state (Cloud Run IAM grants, env vars, Secret Manager versions, App Check enforcement mode) **not verified** — operator-gated items like F-90-01 SF-050 remain operator's responsibility to verify post-deploy.
- Skill is Supabase-shaped (pg_graphql, RLS, Realtime `private:false`, SECURITY DEFINER, PostgREST operators, Helmet, cookies). Adapted to Firebase: Firestore rules `affectedKeys`, CF `enforceAppCheck`, Cloud Run CORS, App Check.
- `semgrep p/owasp-top-ten p/jwt p/secrets p/typescript` on `functions/src/` returned 0 findings (rule packs possibly empty in offline mode).
- `npm audit` run from `functions/`: 8 moderate transitive, 0 high/critical.
- Agents pre-loaded with audit index + MEMORY topic list; duplicate-suppression worked — 0 false re-flags vs ~20 documented closures.
- F-99-01 verified against the rule file directly: `firestore.rules:264-266` uses SF-068 deny-list shape (`!affectedKeys().hasAny([...])`); the deny-list contains 7 status-machine fields only, leaving all other CF-managed scalars owner-writable.

—

**Pointer added to CLAUDE.md audit log:** (operator may merge after review.)
