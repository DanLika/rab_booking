# Security Audit Follow-Up — 2026-05-26

**Scope:** Findings from `/security-audit:run` (Vibe Coding Academy v2.0, 165+ checks) executed against `hotfix/security-sprint-sf-038-046-047-048` (PR #512) post-merge prep.

**Trigger:** Three parallel agents (Firestore + CF + Frontend/Hosting/SSRF) returned 9 new findings beyond the audit/50 + audit/52 + sprint-PR known set.

---

## Result Status

| ID | Severity | Status | Fix landed in |
|---|---|---|---|
| F-NEW-01 | HIGH | ✅ Fixed (regression-fix) | This PR — re-applied 3 reverted compensating-delete calls in stripePayment.ts catch blocks |
| F-NEW-02 | MEDIUM | ✅ Fixed | This PR — new `utils/returnUrlValidation.ts` shared util applied to stripeConnect + stripeSubscription (3 sites) |
| F-NEW-03 | MEDIUM | ✅ Fixed | This PR — `ai_assistant_screen.dart:900` scheme allowlist (http/https only) |
| F-NEW-04 | MEDIUM | ✅ Fixed | This PR — `web_utils_web.dart:351` postMessage origin allowlist mirroring `payment_bridge.js` |
| F-NEW-05 | MEDIUM | ✅ Fixed | This PR — `icalSync.ts validateIcalUrl` rewritten async with `dns.lookup` + private-IP reject + IP-pinned `fetchIcalData` via custom `lookup` callback (defeats DNS rebinding) |
| F-NEW-06 | MEDIUM | ✅ Fixed | This PR — `updateBookingTokenExpiration.ts` added auth gate + per-uid rate limit (30/5min) + `owner_id === request.auth.uid` ownership check |
| F-NEW-07 | LOW | ✅ Fixed | This PR — `firestore.rules` deprecated top-level `/units`, `/bookings`, `/daily_prices` → `create: if false` |
| F-NEW-08 | LOW | ✅ Fixed | This PR — `firestore.rules` `/user_profiles/{userId}` split into `create`/`update`/`delete` with affectedKeys exclusion mirroring `/users/{uid}` |
| F-NEW-09 | LOW | ✅ Fixed | This PR — `firestore.rules` `securityEvents` create gated on field-shape allowlist (`hasOnly` + `type is string` + max 64 chars) |

---

## Notes per finding

### F-NEW-01 — Webhook dedup compensating-delete regression

Three of five `await eventRef.delete().catch(() => {})` calls I added in PR #512 commit `cf62d097` were reverted in the working tree between the security-review audit and this follow-up audit. The audit re-detected the regression at HIGH severity because the three reverted paths (`invoice.paid`, subscription `checkout.session.completed`, booking `checkout.session.completed`) silently strand paying customers — guest pays Stripe, placeholder booking cleanup deletes it 15 min later → no booking exists.

This PR re-applies the 3 deletes verbatim with the same comment pattern as the surviving 2 (`charge.refunded:1002`, `customer.subscription.deleted:1112`).

**Edge case acknowledged:** CF instance crash between dedup commit and the response handler still strands the dedup record (compensating delete never runs). Mitigation deferred to a follow-up using two-phase status (`status: "processing"` initial write + 5-min staleness re-claim).

### F-NEW-02 — Stripe redirect URL allowlist

`stripePayment.ts:80-120 isAllowedReturnUrl()` was the only validator. Three sibling Stripe-redirect surfaces (`stripeConnect.ts:82-87`, `stripeSubscription.ts:108-110`, `stripeSubscription.ts:157-159`) accepted client-controlled URLs unvalidated.

Extracted to `functions/src/utils/returnUrlValidation.ts` (`getAllowedReturnDomains`, `isAllowedReturnUrl`, `assertAllowedReturnUrl`). The Stripe Connect onboarding site is the highest-value phishing target — applied first. The two subscription sites apply the same util.

`stripePayment.ts`'s inline copy NOT refactored to use the util in this PR to keep diff small — TODO: consolidate in follow-up.

### F-NEW-05 — icalSync SSRF deep rewrite

Pre-fix `validateIcalUrl` was a synchronous substring blocklist on `hostname`. New approach:

1. Parse URL → reject non-http(s) scheme.
2. `dns.lookup(hostname, {all: true, verbatim: true})`.
3. New helper `isPrivateOrUnsafeIp(ip)` checks RFC1918, loopback, link-local (incl. `169.254.0.0/16` for GCP metadata), CGNAT, multicast, IPv4-mapped IPv6 (`::ffff:a.b.c.d`), IPv6 ULA (`fc00::/7`), IPv6 link-local (`fe80::/10`).
4. Reject if ANY resolved address fails the check.
5. Return the FIRST resolved address as `pinnedAddress` + `pinnedFamily`.
6. `fetchIcalData` accepts `pinnedAddress` + passes it via custom `lookup` callback in `http.RequestOptions` — ALL DNS resolutions inside that request are bypassed in favour of the pinned IP, defeating DNS rebinding.
7. Redirect handler re-validates the redirect destination AND obtains a fresh pin for the next hop.

`validateIcalUrl` is now async — top-level caller (line 449) and redirect handler (line 601) both updated.

**Defence-in-depth note:** owner-supplied URLs still go through this validator before any fetch. A rogue/compromised owner cannot reach internal metadata server or RFC1918 ranges to exfiltrate GCP service-account tokens, even with hex/octal/decimal IP encodings or DNS rebinding setups.

### F-NEW-06 — updateBookingTokenExpiration

Pre-fix CF was anonymous. Now requires `request.auth`, verifies `booking.owner_id === request.auth.uid` after `findBookingById`, and applies `checkRateLimit('update_booking_token_exp:{uid}', 30, 300)`. The 404/200 booking-ID enumeration oracle is now gated by auth + rate limit; token re-arming requires owning the booking.

### F-NEW-07/08/09 — Firestore rules

- **F-NEW-07**: deprecated `/units`, `/bookings`, `/daily_prices` top-level write surface locked to `create: if false`. Read clauses unchanged (legacy migration tools may still read; existing docs can still be updated/deleted by owner for cleanup). New writes must go through subcollection paths.
- **F-NEW-08**: `/user_profiles/{userId}` split into per-op rules with the same `affectedKeys` exclusion list as `/users/{userId}` (protects `role`, `isAdmin`, `accountStatus`, `account_type`, `trial*`, `statusChanged*`, `lifetime_license_*`). Eliminates self-elevation surface if a future code path ever reads role/isAdmin from `/user_profiles`.
- **F-NEW-09**: `securityEvents` subcollection — `create` now requires `keys().hasOnly(['type','timestamp','deviceId','ipAddress','location','metadata'])` + `type is string` + `type.size() <= 64`. Prevents audit-trail poisoning via arbitrary field injection. **Timestamp binding deferred** — client at `lib/core/services/security_events_service.dart:60` uses `Timestamp.fromDate(event.timestamp)` not `FieldValue.serverTimestamp()`; binding `timestamp == request.time` would break this. Documented TODO in the rule.

---

## Out of scope (existing known findings, not re-reported)

- F-50-02 (CRITICAL): `loginAttempts/{email}` open write — **still UNFIXED**, separate PR planned (full CF refactor required)
- F-50-04 (HIGH): error stacks logged — in flight PR #483 (PR #495 merged for the production case per memory `pr483-stack-leak-finding`)
- F-50-05 (MED): App Check enforcement — partial via SF-046 in PR #512 (audit-only mode shipped); full enforcement gated on F-50-02 closure + RECAPTCHA_SITE_KEY + client App Check init
- F-50-05a (HIGH): undici CVE — in flight
- F-50-05b/06/07 (MED): missing CSP / HSTS / Permissions-Policy on hosting — bundled headers PR planned (requires F-50-10 eval removal first)
- F-50-08 (MED): widget X-Content-Type-Options / Referrer-Policy — verified present in `firebase.json` widget target now; may already be closed
- F-50-09 (MED): `devices/{deviceId}` unbounded update — affectedKeys guard pending
- F-50-10 (LOW): web/index.html:669 eval() — pending
- F-50-11 (LOW): web/iframe_resizer.js:13 postMessage targetOrigin '*' — pending
- F-50-12 (LOW): audit/raw/secrets.txt in git — pending
- F-50-13 (LOW): npm audit moderate noise (fast-xml-parser via @google-cloud/storage) — monitor
- SF-039 (P1): `idempotencyKey` sweep on 6 remaining Stripe write calls — pending
- SF-040 (P1): `getStripeClient()` sk_test/sk_live prefix assertion per GCLOUD_PROJECT — pending
- F-52-03 / SF-037 (P3 deferred): `ALLOWED_SUBSCRIPTION_PRICE_IDS` empty — Stripe has 0 live products, fail-CLOSED correct, CI guard `scripts/check-no-stray-stripe-ui.sh` enforces reopen triggers

---

## Verification

- `npx tsc --noEmit` clean post-fix (4 functions touched, 1 new util)
- Existing tests passing (no test changes required by these fixes; SF-038 dedup tests cover the original case)
- Live smoke deferred to operator post-deploy on bookbed-dev:
  - `firebase deploy --only functions:handleStripeWebhook,functions:createStripeConnectAccount,functions:createSubscriptionCheckoutSession,functions:createCustomerPortalSession,functions:updateBookingTokenExpiration,functions:scheduledIcalSync,functions:syncIcalFeedNow --project bookbed-dev`
  - `firebase deploy --only firestore:rules --project bookbed-dev`
  - Smoke: anon call to `updateBookingTokenExpiration` should return `unauthenticated`; subscription checkout with attacker domain returnUrl should return `invalid-argument`; iCal feed with `http://2130706433/` should fail validation.

---

## Refs

- Audit run: this turn (2026-05-26)
- Branch: `hotfix/security-sprint-sf-038-046-047-048`
- Related PRs: #508 (F-52-01/02), #509 (audit/52 doc), #512 (security sprint)
- Audit ancestors: audit/50, audit/52
