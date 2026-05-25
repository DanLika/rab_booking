# Security Audit — 2026-05-25 (vibe-coding-academy /security-audit:run full)

**Scope**: full audit, Flutter (656 dart) + Cloud Functions (104 ts) + web (4 js) + firebase.json + firestore.rules (441) + storage.rules (73). Dedupe vs `docs/SECURITY_FIXES.md` SF-001..SF-026 + prior `audit/*` runs.
**Method**: 5 parallel domain agents (frontend, CF auth/IDOR, rules, Stripe, headers/CORS/deps) + line-level verification on every claim before inclusion.

## TL;DR

| Severity | Count | Net-new since SF-026 |
|----------|-------|----------------------|
| CRITICAL | 3 | F-50-01 (PR #462), F-50-02 (anon lockout DoS), F-50-03 (Stripe webhook replay = money path) |
| HIGH     | 2 | F-50-04 (stack-trace logs), F-50-05a (undici) |
| MEDIUM   | 6 | F-50-05 (App Check — downgraded), F-50-05b (no CSP owner+admin), F-50-06..09 |
| LOW      | 4 | F-50-10, F-50-11, F-50-12, F-50-13 |
| **Total** | **15** | **15** |

**Severity-calibration note**: F-50-02 and F-50-03 elevated from HIGH after second-pass review. F-50-02 is anon-exploitable customer-impacting lockout (no auth needed → CRITICAL). F-50-03 sits on the money path with normal-operation triggers (Stripe network retries); current partial session-id dedup is ad-hoc not principled → CRITICAL. F-50-05 (App Check) downgraded to MEDIUM: standard Firebase model, defense-in-depth, F-50-02 fix kills the credential-stuffing synergy that was the original HIGH argument.

3 agent claims **rejected on verification** (not in counts above): `ical_feeds resource==null` (harmless read on non-existent doc), Stripe Connect account-ownership (`ownerId = request.auth.uid`, properly scoped at `stripeConnect.ts:35`), `loginAttempts` CRITICAL downgrade (no PII; reclassed HIGH — enumeration + lockout-DoS).

---

## CRITICAL

### F-50-01 — Subscription `priceId` allow-list bypass
- **File**: `functions/src/stripeSubscription.ts:37–47, 84`
- **Evidence**: `const {priceId, returnUrl} = request.data;` flows directly to `price: priceId` in `lineItems`. Allow-list check is **commented out** (`// if (!ALLOWED_PRICES.includes(priceId)) { ... }`).
- **Impact**: Authenticated user can pass any Stripe Price ID in their account (including ones from other test products) → subscribe at wrong price / 0¢.
- **Status**: Already tracked. PR #462 implements the allow-list; audit/38 documents env prereq (`ALLOWED_SUBSCRIPTION_PRICE_IDS` empty on dev, missing on prod).
- **Action**: Unblock PR #462 — provision Stripe Prices in test+live, set per-env env files, merge.

---

### F-50-02 — `loginAttempts` collection is wide-open [CRITICAL]
- **File**: `firestore.rules:386–391`
- **Evidence**:
  ```
  match /loginAttempts/{email} {
    allow get, create, update: if true;
    allow list, delete: if false;
  }
  ```
- **Impact (two attacks)**:
  1. **Email enumeration**: anon `getDoc('loginAttempts/<sanitized-email>')` confirms whether that email has ever attempted login. Pre-auth oracle.
  2. **Account lockout DoS**: anon `setDoc('loginAttempts/<victim-email>', { attempts: 999, lockedUntil: <future> })` locks out a victim from logging in. The Dart `rate_limit_service.dart` trusts these values.
- **Fix options** (pick one):
  - **Best**: move rate-limit reads/writes into a callable Cloud Function (request not yet authenticated → use a short-lived signed token + App Check) and lock the rule to `if false`.
  - **Quick**: keep client writes but enforce `request.resource.data.keys().hasOnly(['attempts','lockedUntil','firstAttemptAt'])` and `request.resource.data.attempts is int && attempts <= 10`. Email enumeration remains until full lockdown.

### F-50-03 — Stripe webhook lacks event-ID dedup [CRITICAL]
- **File**: `functions/src/stripePayment.ts:887–901` (`constructEvent` only)
- **Evidence**: signature verification present; no `event.id` storage / dedup before processing.
- **Impact**: Stripe retries (network blip, 5xx) replay the same `event.id`; current code path will re-send confirmation emails, re-credit owner balance, re-mark bookings paid. Single-event-per-effect is not guaranteed.
- **Fix**: at top of handler after `constructEvent`, `runTransaction(t => { const ref = db.collection('stripe_webhook_events').doc(event.id); if ((await t.get(ref)).exists) return /* skip */; t.create(ref, { receivedAt: serverTimestamp() }) })` with TTL policy (30 days).

## HIGH

### F-50-04 — Error stacks logged to Cloud Logging across CFs
- **Files**: `bookingManagement.ts:57`, `verifyBookingAccess.ts:232`, `getBookingByStripeSession.ts:148`, `stripePayment.ts:856`, `updateBookingTokenExpiration.ts:95` (others likely)
- **Evidence**: structured `logError`/`logWarn` payloads include `error.stack`, which embeds file paths, line numbers, and bundled module names from `lib/`.
- **Impact**: anyone with `roles/logging.viewer` (which expands across team/contractor IAM bindings) gets a free reverse-engineering surface. Also can leak DB error text for SQL-shaped Firestore errors.
- **Fix**: in `logger.ts`, scrub: `{ message: error.message, code: error.code }` only. Keep stack on Sentry (already scrubbed), not Cloud Logging.

### F-50-05a — `undici ≤6.23.0` (transitive via firebase-admin) in iCal-fetch path
- **File**: `functions/package-lock.json` → `node_modules/undici` (transitive via `@firebase/*`); used by `functions/src/icalSync.ts` (owner-supplied URLs)
- **Evidence**: `npm audit --json` reports 8 CVEs on `undici`: HTTP Request/Response Smuggling, CRLF Injection in `upgrade` option, Insufficient Randomness, unbounded decompression DoS, bad-cert DoS, WebSocket length overflow, WebSocket memory exhaustion, WebSocket exception.
- **Impact**: most CVEs are server-side (we are the client) → low. **But**: CRLF in `upgrade` option + smuggling/decompression DoS apply when a malicious target controls the response. iCal feed URLs are owner-supplied → owner-grade attacker can inject malicious URL that points to a server returning crafted responses → CF resource exhaustion or auth-header smuggling.
- **Fix**: bump `firebase-admin` / `firebase-functions` to whichever release ships `undici ≥6.23.1`. If upstream lags, add `overrides: { "undici": "^7.0.0" }` to `functions/package.json` and re-test SDK compat. Verify with `npm audit` after.

---

## MEDIUM

### F-50-05 — App Check not enforced on any Cloud Function [downgraded from HIGH]
- **Evidence**: `grep -r enforceAppCheck functions/src/` → zero hits.
- **Impact**: public Firebase Web API key + onCall is the standard Firebase model; App Check is defense-in-depth, not primary control. Original HIGH was justified by F-50-02 credential-stuffing synergy — once F-50-02 lands, that path dies. No abuse signal in current logs.
- **Defer until**: after F-50-02 and F-50-05a ship. Then revisit with real abuse-rate data.
- **Fix when scheduled**: enable App Check (reCAPTCHA Enterprise for web, DeviceCheck/AppAttest iOS, Play Integrity Android) → add `enforceAppCheck: true` on auth-required onCalls. Keep public functions (getUnitAvailability, icalExport) without enforcement. Rollout is L (Flutter SDK side + per-platform attest providers + per-CF flag).

### F-50-05b — Owner + admin sites have NO `Content-Security-Policy`
- **File**: `firebase.json` owner and admin hosting blocks — `**` headers list contains only `X-Frame-Options`, `X-Content-Type-Options`, `Referrer-Policy`. Zero CSP.
- **Evidence**: only the widget block defines CSP (`frame-ancestors *`), and even that is frame-ancestors-only — no `default-src`/`script-src`.
- **Impact**: owner dashboard is the most XSS-sensitive surface (Stripe Connect onboarding redirect targets, owner-controlled property descriptions rendered in Flutter web). No CSP = no defense-in-depth if an XSS sink ever slips in.
- **Fix** (incremental, report-only mode first to avoid breaking Flutter web bundle):
  ```json
  {
    "key": "Content-Security-Policy-Report-Only",
    "value": "default-src 'self'; script-src 'self' 'wasm-unsafe-eval' https://js.stripe.com https://www.gstatic.com; connect-src 'self' https://*.googleapis.com https://*.firebaseio.com https://api.stripe.com https://*.sentry.io; img-src 'self' data: https:; style-src 'self' 'unsafe-inline'; frame-src https://js.stripe.com https://hooks.stripe.com; object-src 'none'; base-uri 'self'; form-action 'self'; frame-ancestors 'none'"
  }
  ```
  Ship in report-only first, collect violations from Sentry/console for 1 week, then promote to enforcing `Content-Security-Policy`. Flutter web needs `wasm-unsafe-eval` (CanvasKit); test thoroughly. F-50-10 `eval()` in `web/index.html:669` must be removed first or CSP will break.

### F-50-06 — `firebase.json` missing HSTS on all 3 sites
- **File**: `firebase.json` (owner / widget / admin hosting blocks)
- **Fix**: add to each `"source": "**"` headers array:
  ```json
  { "key": "Strict-Transport-Security", "value": "max-age=63072000; includeSubDomains; preload" }
  ```
  Note: only enable `preload` once you've committed to no HTTP-only subdomain — review subdomain inventory first.

### F-50-07 — `firebase.json` missing `Permissions-Policy` on all 3 sites
- **Fix** (owner/admin):
  ```json
  { "key": "Permissions-Policy", "value": "camera=(), microphone=(), geolocation=(), payment=(self), usb=(), interest-cohort=()" }
  ```
  Widget should keep `payment=(self)` (Stripe Checkout flow) and otherwise lock down.

### F-50-08 — `widget` site lacks `X-Content-Type-Options` + `Referrer-Policy`
- **File**: `firebase.json` widget target — only has `X-Frame-Options: ALLOWALL`, CSP `frame-ancestors *`, and cache headers.
- **Fix**: add `X-Content-Type-Options: nosniff` and `Referrer-Policy: strict-origin-when-cross-origin`. Both compatible with embed-anywhere use case.

### F-50-09 — `devices/{deviceId}` update is unbounded
- **File**: `firestore.rules:127`
- **Evidence**: `allow create, update: if isOwner(userId)` with no `affectedKeys()` constraint.
- **Impact**: user can rewrite any field on their own device docs (low real risk since data is self-scoped, but defeats forensic integrity if devices are ever consulted for fraud signals).
- **Fix**: add `request.resource.data.diff(resource.data).affectedKeys().hasOnly(['lastSeenAt','fcmToken','appVersion','platform'])`.

---

## LOW

### F-50-10 — `web/index.html:669` uses `eval()` for ES6 feature detection
- **Evidence**: `eval('class Test {}; let x = () => {}; const y = \`test\`;')` — only `eval()` call in entire web bundle.
- **Impact**: blocks future CSP `script-src 'self'` (must allow `'unsafe-eval'`); flagged by SAST.
- **Fix**: replace with try-block parse check or `'class' in window`-style detection; or drop entirely (every supported browser has these for years).

### F-50-11 — `web/iframe_resizer.js:13` postMessage targetOrigin `'*'`
- **Evidence**: `window.parent.postMessage({type:'resize', height}, '*');`
- **Impact**: data leaked is only a numeric height → low real risk; still best-practice violation. Could be exploited if the iframe ever passes more than height in the future.
- **Fix**: capture the embedding origin from initial handshake (parent sends `{type:'init', origin}` to iframe) and use that; or compute `document.referrer`-based origin at load.

### F-50-12 — `audit/raw/secrets.txt` checked into git
- **Evidence**: `git ls-files | grep secret` returns this file; contents are line-by-line grep dump of code references (apiKey, token) in `lib/` and `functions/src/`.
- **Impact**: not real secrets, but reveals file:line of all auth-token handling — accelerates an attacker's recon if repo is ever public/leaked.
- **Fix**: add `audit/raw/` to `.gitignore`; remove the file (`git rm`) and document the convention in `CLAUDE.md`.

### F-50-13 — Remaining `npm audit` moderate noise (post-undici-fix)
- **Evidence**: after F-50-05a undici bump, residual moderate-class is `fast-xml-parser` via `@google-cloud/storage` + a few `undici`-secondary moderates if upstream lags.
- **Impact**: SDK-internal, no direct user-input path.
- **Fix**: monitor; pin `fast-xml-parser` via `overrides` if upstream drags past Q3.

---

## Verified clean (no findings)

- ✅ No `.env` in git history (verified `git log --all --full-history`)
- ✅ `.gitignore` correctly blocks `.env*`, `*.pem`, `*.key`, `*service-account*.json`
- ✅ `firebase_options*.dart` + `android/app/google-services.json` API keys are public-by-design Firebase Web keys, NOT a finding (access enforced by Auth + Rules)
- ✅ Bookings rule (T11c / SF-019) — confirmed locked; widget routes through `getUnitAvailability` callable
- ✅ `ical_events` (SF-023), storage `ical-exports/` (SF-025), `widget_settings` split (SF-021) — confirmed in current rules
- ✅ SSRF defense in `icalSync.ts` (blocks 127.x, 10.x, 169.254.x, metadata.google.internal) — SF-002
- ✅ `crypto.timingSafeEqual` used for `bookingAccessToken.ts:184` and `icalExport.ts:44` token comparison
- ✅ Stripe webhook **signature** verification present (`stripePayment.ts:898`)
- ✅ Stripe Connect account creation properly scoped: `ownerId = request.auth.uid` (`stripeConnect.ts:35`) — NOT `request.data.ownerId` (agent claim rejected)
- ✅ Rate limiting present on auth, password reset, email verify, guest cancel, token verify (`authRateLimit.ts` + per-CF `checkRateLimit`)
- ✅ No CORS wildcard with credentials on auth-required CFs
- ✅ No `pull_request_target` workflows; GitHub Actions secrets handled correctly
- ✅ Android deep-link intent filter has `autoVerify=true`; iOS Info.plist has no cleartext exceptions
- ✅ Service worker `firebase-messaging-sw.js` origin-checks notification clicks
- ✅ Price calculation server-side from Firestore (`atomicBooking.ts` reads `nightly_price`); amounts in integer cents end-to-end

## False positives rejected during verification

- ❌ `ical_feeds` `resource==null` fallback (firestore.rules:366) — reading non-existent doc is harmless; rule design is correct
- ❌ Stripe Connect "ownership gap" (stripeConnect.ts:55) — caller's `request.auth.uid` IS the ownerId, no spoofing possible
- ❌ `loginAttempts` CRITICAL — downgraded to HIGH (no direct PII leak; enumeration + lockout-DoS)

---

## Suggested fix order (PR sizing)

1. **F-50-04** (1 PR, S): scrub `error.stack` from `logger.ts` — one-file change, drop-in.
2. **F-50-02** (1 PR, M) — **promoted to top of CRITICAL queue**: `loginAttempts` either CF migration or strict field-mutation guard. Anon lockout DoS is live.
3. **F-50-03** (1 PR, M) — **CRITICAL money-path**: Stripe webhook event-ID dedup table + TTL policy. Before that, spot-check Stripe Dashboard → Events for recent retry-pairs on same `event.id` to size historical exposure.
4. **F-50-05a** (1 PR, S): undici bump via `overrides` in `functions/package.json`; verify SDK compat.
5. **F-50-06, F-50-07, F-50-08** (1 PR, S): firebase.json header additions — config-only.
6. **F-50-10** then **F-50-05b** (1 PR each, S+M): remove `web/index.html:669` eval first, then add CSP-Report-Only on owner+admin; promote to enforce after 1 week of clean Sentry.
7. **F-50-09, F-50-11, F-50-12** (1 PR, XS each, can bundle): defensive tightenings.
8. **F-50-05** (after #2 ships, L): App Check enrolment — revisit with real abuse-rate data.
9. **F-50-13** (passive): track upstream Firebase SDK release notes; bump quarterly.

`F-50-01` is owned by PR #462 — separate workstream.

## Follow-up: Semgrep scan
This audit was manual + agent review only. Semgrep 1.156.0 is available on this host. Recommend running `semgrep_scan` against `functions/src/` + `lib/` as a separate cycle to add taint-analysis coverage (catches sources/sinks the regex agents miss). Not blocking — additive rigor layer.
