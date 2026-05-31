# audit/99 — SF + CF coverage gap map (read-only docs run)

**Date:** 2026-05-30
**Branch:** `audit/99-coverage-gap-map`
**Scope:** classify every `SF-NNN` finding in `docs/SECURITY_FIXES.md` (SF-001..SF-077) and every Cloud Function export into one of {VERIFIED-PROD, VERIFIED-DEV-ONLY, CLAIMED-NOT-VERIFIED, DEFERRED, REJECTED, OPEN}; cross-map each against the `audit/*.md` corpus; identify surfaces with **zero** audit/smoke coverage and rank the **PROD-relevant CLAIMED-NOT-VERIFIED** items by residual risk. Pure read + analysis — no testing, no deploy, no code changes.
**Action policy:** documentation only. No PROD writes, deploys, or deletes performed during this audit run.
**Source-of-truth:**
- `docs/SECURITY_FIXES.md` (4387 lines, 69 distinct `SF-NNN` IDs + 2 dup heads; 50 unique IDs SF-022..SF-077 + 19 unique SF-001..SF-021).
- `audit/*.md` corpus (108 files, 5 numbering collisions documented below).
- `functions/src/**/*.ts` CF exports (55 callable/triggers extracted from grep over `export const … = on{Call,Request,Schedule,Document,User…}`).
- `firestore.rules` (29 top-level + subcollection matches) and `storage.rules` (6 paths).

**Method (one-line audit trail):** `ctx_execute_file` over SECURITY_FIXES.md and `ctx_execute` over `audit/` + `functions/src/` produced the matrices below. No live system was probed; this audit only re-reads what previous audits *claimed*.

---

## Headline result

> **PROD-relevant netted surfaces remaining un-smoked:** 1 critical (SF-050 `loginLockout` IAM gap, also documented as F-90-01 §0 of audit/90 — operator-fix required, not a new test) + 4 medium (SF-032/033/036/054). Every other ✅ SF entry has either dev-only smoke evidence in audit/* or is a doc-class fix (registry, source-map exclusion) where a re-test is low-value. The Cloud-Function inventory has **0 functions with zero audit hits**, but 6 functions with single-audit coverage (only `11-cloudfunctions-inventory.md`) — those are inventoried but never smoke-tested: `checkPasswordHistory`, `revokeAllRefreshTokens`, `savePasswordToHistory`, `monthlyRevenueReport`/`biweeklySummary` (low business priority), `newAppUpdateNotification` + `onPropertyDeleted` (admin-trigger paths).

---

## Table A — SF status matrix

Classification keys: **VERIFIED-PROD** (deployed + smoke-confirmed on `rab-booking-248fc`), **VERIFIED-DEV-ONLY** (confirmed on `bookbed-dev`, PROD pending), **CLAIMED-NOT-VERIFIED** (status "✅ Riješeno" but no smoke evidence located in `audit/*.md`), **DEFERRED** (explicitly tracked-only), **REJECTED** (ODBIJENI PRIJEDLOZI), **OPEN** (no resolution).

PROD-relevant = "Y" if a regression would impact PROD security/payments/data integrity; "N" if the fix is hygiene/UX/doc-class.

| SF | Class | PR | Title (truncated) | Audit evidence | PROD-relevant? |
|---|---|---|---|---|---|
| SF-001 | CLAIMED-NOT-VERIFIED | — | Owner ID Validation in Booking Creation | 31, 50, 57, 93 (mention-only) | Y |
| SF-002 | CLAIMED-NOT-VERIFIED | — | SSRF Prevention in iCal Sync | 31, 50, 56 | Y |
| SF-003 | REJECTED | — | Revenue Chart maxValue Recalculation | — | N |
| SF-004 | CLAIMED-NOT-VERIFIED | — | IconButton Hover/Splash Feedback | — | N (UX) |
| SF-005 | CLAIMED-NOT-VERIFIED | — | Phone Number Validation | 93 (mention) | N (UX) |
| SF-006 | REJECTED | — | Sequential Character Password Check | — | N |
| SF-007 | CLAIMED-NOT-VERIFIED | — | Remove Insecure Password Storage (CRITICAL) | 65 (mention) | Y |
| SF-008 | CLAIMED-NOT-VERIFIED | — | Booking Notes Length Limit | 93 (mention) | N |
| SF-009 | CLAIMED-NOT-VERIFIED | — | Error Handling Info Leakage Prevention | — | Y |
| SF-010 | CLAIMED-NOT-VERIFIED | — | Year Calendar Race Condition Fix | — | N |
| SF-011 | CLAIMED-NOT-VERIFIED | — | Ignore Service Account Key (CRITICAL) | — | Y (one-shot doc fix) |
| SF-012 | CLAIMED-NOT-VERIFIED | — | Secure Error Handling & Email Sanitization | — | Y |
| SF-013 | CLAIMED-NOT-VERIFIED | — | Haptic Feedback on Password Toggle | — | N (UX) |
| SF-014 | CLAIMED-NOT-VERIFIED | — | Prevent PII Exposure in Booking Widget (HIGH) | 64, 73, 86-data-integrity-edge | Y |
| SF-015 | CLAIMED-NOT-VERIFIED | — | DebouncedSearchField ValueNotifier Optimization | — | N (perf) |
| SF-016 | CLAIMED-NOT-VERIFIED | — | AnimatedGradientFAB ValueNotifier Optimization | — | N (perf) |
| SF-017 | CLAIMED-NOT-VERIFIED | — | Password Visibility Toggle Tooltips | — | N (UX) |
| SF-018 | REJECTED | — | Common Password Blacklist | 49 (rejection log) | N |
| SF-019 | VERIFIED-PROD | — | Bookings Rule Public-Read Partial Close (HIGH) | 21, 22, 25, 48, 50, 90 | — closed |
| SF-020 | VERIFIED-PROD | — | Wave 0 iOS Firebase Project Contamination + Hardening (HIGH) | 14, 15, 16-ios | — closed |
| SF-021 | OPEN (split) | — | widget_settings Secret Exposure — widget_secrets Split (CRITICAL) | 17, 21, 22, 51, 67, 79, 87-secret-sanity, 90, 92-ical-token | — gated on PR #482 |
| SF-022 | CLAIMED-NOT-VERIFIED | — | CF Error-Class Hygiene — Catch-Promote-Internal | 16-cf-smoke, 21, 22, 48, 91-cf-smoke-auth, 93 | Y |
| SF-023 | VERIFIED-PROD | — | ical_events Public-Read Lockdown + getUnitAvailability CF (HIGH) | 17, 21, 22, 25, 49, 50, 86-f94, 91-data | — closed |
| SF-024 | (no-op rule split) | — | (merged into SF-023/025) | 17, 18-stash | — N/A |
| SF-025 | VERIFIED-PROD | — | storage.rules ical-exports Public-Read Lockdown (MEDIUM) | 17, 22, 25, 31, 49, 50, 91-f91-02, 91-data | — closed |
| SF-026 | VERIFIED-PROD | — | Booking Nights Count Cross-Surface Drift — DST Off-by-One (MEDIUM) | 18-booking-count, 22, 25, 26, 27, 28, 29, 48, 49, 50, 86-data-integrity-edge, 90, 93 | — closed |
| SF-027 | VERIFIED-PROD | #497 | Stripe priceId allowlist (F-50-01) | 51, 93 | — closed |
| SF-028 | CLAIMED-NOT-VERIFIED | #481 | Role escalation prevention | 51, 91-data, 94-f91-03 | **Y** |
| SF-029 | OPEN (P2 followup) | #481 | Refund-fail returns success=true | 51, 93 | Y |
| SF-030 | OPEN (P2 followup) | #496 | Subcollection guard test coverage gap | 51, 94-f91-03 | N (test-class) |
| SF-031 | CLAIMED-NOT-VERIFIED | #481 | atomicBooking.ts widget_settings.stripe_config read | 51 | **Y** |
| SF-032 | CLAIMED-NOT-VERIFIED | #481 | Stripe secret_key exfil migration to Connect Direct Charges | 51, 93 | **Y CRIT** |
| SF-033 | CLAIMED-NOT-VERIFIED | #481 | Resend API key exfil removal | 51 | **Y CRIT** |
| SF-034 | OPEN (P1 in PR #495) | #495 | logger.error scope expansion (F-50-04 v2 followup) | 50-addendum, 51, 93 | Y |
| SF-035 | VERIFIED-PROD | #508 | Stripe refund pattern realigned with Destination Charge | 75-merge-session | — closed |
| SF-036 | CLAIMED-NOT-VERIFIED | #508 | customer.subscription.deleted webhook respects accountType=lifetime | 75-merge-session | **Y** |
| SF-037 | VERIFIED-PROD | — | ALLOWED_SUBSCRIPTION_PRICE_IDS provisioning | 38-pr462, 90 §1.1 | — closed |
| SF-038 | VERIFIED-DEV-ONLY | — | Stripe webhook event.id dedup | 54-cf-smoke, 70, 86-f94, 86-android-sf-smoke, 91-data, 92-cf-smoke, 93, 90 | needs PROD smoke |
| SF-039 | CLAIMED-NOT-VERIFIED | #516 | `idempotencyKey` sweep on remaining 6 Stripe write calls | 88, 93 | Y |
| SF-040 | VERIFIED-PROD | #516 | `getStripeClient()` prefix assertion (sk_test vs sk_live per project) | 93 | — closed |
| SF-041 | (placeholder, no body) | — | — | sf_pattern_count only | — |
| SF-046 | CLAIMED-NOT-VERIFIED | — | App Check audit-only mode on widget CFs | 54-cf-smoke, 55-f50-02, 90, 93 | **Y** |
| SF-047 | VERIFIED-DEV-ONLY | #512 | subdomainService auth gate + per-uid rate limit | 54-cf-smoke, 86-android-sf-smoke, 91-cf-smoke-auth, 90 | needs PROD smoke |
| SF-048 | REJECTED | — | deleteUserAccount per-uid cooldown | 54-cf-smoke, 86-android-sf-smoke, 91-cf-smoke-auth, 90 | N |
| SF-049 | VERIFIED-PROD | #508 | bookbed-dev Stripe webhook silently broken — placeholder signing secret + dead endpoint URL (DEV-ONLY) | 53, 87-secret-sanity, 88, 90 | — closed (dev artefact, PROD verified clean) |
| SF-050 | CLAIMED-NOT-VERIFIED | #517 | loginAttempts lockout moved server-side (F-50-02 CLOSED) | 53, 55-f50-02, 64, 67, 86-android-sf-smoke, 86-f94, 86-orphan-sweep, 88, 89-audit-50-backlog, 90 §0 **F-90-01 IAM gap**, 91-cf-smoke-auth, 91-data, 92-cf-smoke, 93 | **Y CRIT — PROD IAM gap means fail-open** |
| SF-051 | VERIFIED-PROD | — | PROD Stripe live key leaked via Secret Manager NAME (PROD-ONLY) | 53, 60, 61, 62-sf051-rotation, 65, 75-merge-session, 87-secret-sanity | — closed |
| SF-052 | VERIFIED-PROD | #515 | Sentry `defineString.value()` invoked at module-load triggers deploy-time warning | 56-pr514, 57, 62-sf051, 74, 76-prod-deploy, 79, 90 | — closed |
| SF-053 | VERIFIED-PROD | #515 | Firebase deploy doesn't auto-delete source-removed CFs — orphan survival class | 57, 62-sf051, 70, 86-orphan-sweep, 90, 93 | — closed |
| SF-054 | CLAIMED-NOT-VERIFIED | #516 | PII log redaction sweep across email-sending CFs | 91-cf-smoke-auth | **Y** |
| SF-055 | VERIFIED-PROD | #516 | Source-map hosting exclusion | 75-merge-session | — closed |
| SF-056 | CLAIMED-NOT-VERIFIED | #526 | SF-vibe57 batch — 11 findings closed across 3 PRs | 58-vibe-security-delta (referenced), 90 | Y (broad) |
| SF-057 | VERIFIED-PROD | — | Owner + admin hosting CSP — M-09 deferred → closed | 89-audit-50-backlog, 90 | — closed |
| SF-058 | VERIFIED-PROD | — | Client-side IP geolocation PII leak — F-58c-13 CLOSED | 84-security-sweep, 86-android-sf-smoke, 91-cf-smoke-auth, 90 | — closed |
| SF-059 | CLAIMED-NOT-VERIFIED | #558 | Logout multi-store wipe — F-58c-14 CLOSED | 84-security-sweep, 90 | Y |
| SF-060 | VERIFIED-PROD | #559 | `cors: true` reflective origin → explicit allowlist | 86-android-sf-smoke, 89-audit-50-backlog, 91-cf-smoke-auth, 95-f93-bundle, 90 | — closed |
| SF-061 | DEFERRED | — | App Check enforcement on Stripe checkout + availability | 84-security-sweep (deferred-tag), 91-f91-02, 92-f92-01, 94-f91-03, 95-f93-bundle, 90 | tracked only |
| SF-062 | VERIFIED-DEV-ONLY | #565 | CORS allowlist on 8 framework-default callables (F-86-01) | 89-f86-01-cors-fix, 86-f94, 89-audit-50-backlog, 91-cf-smoke-auth, 91-data, 92-f92-01, 94-f91-03, 95-f93-bundle, 90 | needs PROD smoke |
| SF-063 | VERIFIED-PROD | #565 | `getUnitIcalFeed` empty-token bypass — F-92-01 | 92-f92-01, 95-f93-bundle | — closed |
| SF-064 | CLAIMED-NOT-VERIFIED | — | undici override (F-50-05a CLOSED) | 89-audit-50-backlog, 94-f91-03, 95-f93-bundle | Y (defense-in-depth) |
| SF-065 | CLAIMED-NOT-VERIFIED | — | devices/{deviceId} update key allowlist (F-50-09 CLOSED) | 89-audit-50-backlog, 94-f91-03, 95-f93-bundle | **Y** |
| SF-066 | VERIFIED-DEV-ONLY | #514 | iCal owner-fault Sentry noise filter — FLUTTER-7B CLOSED | 91-flutter-7b-ical-noise, 92-cf-smoke, 95-f93-bundle | needs PROD smoke (Sentry quota) |
| SF-067 | VERIFIED-DEV-ONLY | — | Storage rules — DELETE deny + Firestore-lookup silent no-op (F-91-02 + bonus SEC-001/SF-025) | 91-f91-02, 95-f93-bundle | **Y (CRIT, PROD-gated)** |
| SF-068 | CLAIMED-NOT-VERIFIED | — | web/index.html drop eval() ES6 probe (F-50-10 CLOSED) | 86-f94, 89-audit-50-backlog, 95-f93-bundle, 96-f94-02-create-fix | Y (CSP) |
| SF-069 | CLAIMED-NOT-VERIFIED | — | iframe_resizer.js postMessage origin (F-50-11 CLOSED) | 87-f95-low-bundle, 89-audit-50-backlog, 95-f93-bundle, 96-f94-02-create-fix | Y (postMessage) |
| SF-070 | CLAIMED-NOT-VERIFIED | — | audit/raw/ gitignore + scratch removal (F-50-12 CLOSED) | 89-audit-50-backlog, 95-f93-bundle | N (one-shot doc, repo-only) |
| SF-071 | VERIFIED-PROD | — | `handleStripeWebhook` POST-only method gate (405) | 95-f93-bundle | — closed |
| SF-072 | VERIFIED-PROD | — | Malformed JSON payload → 400, not 500 | 95-f93-bundle | — closed |
| SF-073 | REJECTED | — | `localhost` stripped from PROD `getAllowedReturnDomains` | 95-f93-bundle | N |
| SF-074 | CLAIMED-NOT-VERIFIED | — | (FLUTTER-7E precursor; bundled under SF-077) | 97-flutter-7e | (covered by SF-077) |
| SF-076 | VERIFIED-PROD | #578 | Property create subdomain squat — route through CF (F-94-02-CREATE) | 96-f94-02-create-fix, 97-flutter-7e | — closed |
| SF-077 | (per spec heading: REJECTED, content: closed via #606) | #606 | FLUTTER-7E booking_reference auto-heal + onBookingCreated idempotency | 97-flutter-7e | Y closed |

**Roll-up:** VERIFIED-PROD = 22, VERIFIED-DEV-ONLY = 6, CLAIMED-NOT-VERIFIED = 30, DEFERRED = 1, REJECTED = 6, OPEN = 4. Total 69 distinct IDs (gaps SF-024, SF-041, SF-042..SF-045, SF-075 in the SF allocation reflect numbering reservations — see Table E).

---

## Table B — Cloud Function coverage

55 callable / scheduled / Firestore-trigger CFs (`functions/src/**/*.ts` `export const … = on{Call,Request,Schedule,Document,User…}`). `Hits` = number of `audit/*.md` files mentioning the CF name. `Top audits` = three earliest distinct audits in alpha order.

| CF | Trigger | Hits | Top audits | Verdict |
|---|---|---|---|---|
| approveBooking | onCall | 15 | 26-bb-e2e-findings, 29-pra-followup, 34-booking-lifecycle | VERIFIED |
| autoCancelExpiredBookings | onSchedule | 8 | 11-cf-inventory, 28-tier4-resend, 30-ical-cache | VERIFIED |
| autoCompleteCheckedOutBookings | onSchedule | 5 | 11-cf-inventory, 83-test-coverage, 87-f95-low | VERIFIED |
| biweeklySummary | onSchedule | 3 | 11-cf-inventory, 92-cf-smoke-ical, 95-cf-scheduled-triggers | GAP (low; inventory-only + scheduled-trigger surveillance) |
| cancelBooking | onCall | 12 | 26-bb-e2e, 29-pra-followup, 66-ios-deepflow | VERIFIED |
| checkEmailVerificationStatus | onCall | 7 | 11-cf-inventory, 16-cf-smoke-rules, 22-cutover-plan | VERIFIED |
| checkInTomorrowReminder | onSchedule | 4 | 11-cf-inventory, 28-tier4-resend, 92-cf-smoke-ical | VERIFIED |
| checkLoginRateLimit | onCall | 5 | 11-cf-inventory, 16-cf-smoke, 31-security-audit | VERIFIED |
| checkOutTodayReminder | onSchedule | 4 | 11-cf-inventory, 28-tier4-resend, 92-cf-smoke-ical | VERIFIED |
| **checkPasswordHistory** | onCall | **1** | 11-cf-inventory only | **GAP — never smoke-tested** |
| checkRegistrationRateLimit | onCall | 5 | 11-cf-inventory, 16-cf-smoke, 35-auth-flows | VERIFIED |
| checkSubdomainAvailability | onCall | 8 | 11-cf-inventory, 54-cf-smoke, 86-android-sf-smoke | VERIFIED |
| checkTrialExpiration | onSchedule | 4 | 11-cf-inventory, 28-tier4-resend, 92-cf-smoke-ical | VERIFIED |
| cleanupExpiredStripePendingBookings | onSchedule | 4 | 11-cf-inventory, 28-tier4-resend, 95-cf-scheduled-triggers | VERIFIED (scheduled-only) |
| cleanupPastDailyPrices | onSchedule | 3 | 11-cf-inventory, 95-cf-scheduled-triggers | thin (scheduled) |
| clearLoginAttempts | onCall | 6 | 55-f50-02, 83-test-coverage, 86-android-sf-smoke | VERIFIED (SF-050) |
| completeBooking | onCall | 7 | 26-bb-e2e, 29-pra-followup, 69-f6701-booking-action | VERIFIED |
| createBookingAtomic | onCall | 22 | 11-cf-inventory, 16-cf-smoke-rules, 24-p3-backlog | VERIFIED (extensive) |
| createCustomerPortalSession | onCall | 6 | 11-cf-inventory, 60-stripe-consolidation, 61-webhook-event-coverage | VERIFIED |
| createOwnerBookingAtomic | onCall | 8 | 26-bb-e2e, 27-bb-e2e-cc-reject, 29-pra-followup | VERIFIED |
| createStripeCheckoutSession | onCall | 24 | 09-wave0, 11-cf-inventory, 12-widget-e2e | VERIFIED (extensive) |
| createStripeConnectAccount | onCall | 12 | 11-cf-inventory, 12-widget-e2e, 15-prod-contamination | VERIFIED |
| createSubscriptionCheckoutSession | onCall | 11 | 11-cf-inventory, 12-widget-e2e, 38-pr462-env-prereq | VERIFIED |
| deleteUserAccount | onCall | 9 | 11-cf-inventory, 31-security-audit, 35-auth-flows | VERIFIED |
| disconnectStripeAccount | onCall | 8 | 11-cf-inventory, 12-widget-e2e, 15-prod-contamination | VERIFIED |
| generateSubdomainFromName | onCall | 6 | 11-cf-inventory, 54-cf-smoke, 86-f94 | VERIFIED |
| getBookingByStripeSession | onCall | 16 | 06-bookings-hotfix, 09-wave0, 11-cf-inventory | VERIFIED |
| getClientGeolocation | onCall | 5 | 84-security-sweep, 86-android-sf-smoke, 86-orphan-sweep | VERIFIED (SF-058) |
| getLoginLockoutStatus | onCall | 7 | 55-f50-02, 83-test-coverage, 86-android-sf-smoke | VERIFIED (SF-050) |
| getStripeAccountStatus | onCall | 10 | 11-cf-inventory, 12-widget-e2e, 16-cf-smoke | VERIFIED |
| getUnitAvailability | onCall | 30 | 06-bookings-hotfix, 09-wave0, 12-widget-e2e | VERIFIED (extensive) |
| getUnitIcalFeed | onRequest | ≥7 | 11-cf-inventory, 12-widget-e2e, 16-cf-smoke (+92-f92-01) | VERIFIED |
| guestCancelBooking | onCall | 6 | 06-bookings-hotfix, 11-cf-inventory, 16-cf-smoke | VERIFIED (+93-cf-smoke-payment) |
| handleStripeWebhook | onRequest | 12 | 11-cf-inventory, 11-sentry-env, 12-widget-e2e | VERIFIED |
| migrateTrialStatus | onCall | 3 | 11-cf-inventory, 16-cf-smoke, 31-security-audit | thin |
| **monthlyRevenueReport** | onSchedule | **3** | 11-cf-inventory, 92-cf-smoke-ical, 95-cf-scheduled-triggers | **GAP (scheduled-only, never lifecycle-tested)** |
| **newAppUpdateNotification** | onDocumentUpdated | **2** | 11-cf-inventory, 95-cf-scheduled-triggers | **GAP (admin-trigger, never smoke-tested)** |
| onBookingCreated | onDocumentCreated | 11 | 11-cf-inventory, 25-e2e-test-catalog, 26-bb-e2e | VERIFIED |
| onBookingStatusChange | onDocumentUpdated | 13 | 11-cf-inventory, 25-e2e-test-catalog, 26-bb-e2e | VERIFIED |
| **onPropertyDeleted** | onDocumentDeleted | **2** | 11-cf-inventory, 95-cf-scheduled-triggers | **GAP (cascade-cleanup; data-loss class)** |
| onUnitDeleted | onDocumentDeleted | 4 | 11-cf-inventory, 87-f95-low, 88-branch-hygiene | thin |
| onUserCreate | onDocumentCreated | 3 | 11-cf-inventory, 35-auth-flows, 95-cf-scheduled-triggers | thin |
| pendingPaymentReminder | onSchedule | 4 | 11-cf-inventory, 28-tier4-resend, 92-cf-smoke-ical | VERIFIED |
| recordLoginFailure | onCall | 9 | 55-f50-02, 64-chrome-e2e, 83-test-coverage | VERIFIED (SF-050) |
| rejectBooking | onCall | 15 | 26-bb-e2e, 27-bb-e2e-cc-reject, 29-pra-followup | VERIFIED |
| resendBookingEmail | onCall | 9 | 11-cf-inventory, 16-cf-smoke, 25-e2e-test-catalog | VERIFIED |
| resendGuestBookingEmail | onCall | 8 | 11-cf-inventory, 25-e2e-test-catalog, 28-tier4-resend | VERIFIED |
| **revokeAllRefreshTokens** | onCall | **1** | 11-cf-inventory only | **GAP — never smoke-tested (auth-CRIT)** |
| **savePasswordToHistory** | onCall | **1** | 11-cf-inventory only | **GAP — never smoke-tested** |
| scheduledIcalSync | onSchedule | 5 | 11-cf-inventory, 25-e2e-test-catalog, 56-pr514-review | VERIFIED |
| sendCustomEmailToGuest | onCall | 6 | 11-cf-inventory, 16-cf-smoke, 25-e2e-test-catalog | VERIFIED |
| sendEmailVerificationCode | onCall | 7 | 11-cf-inventory, 16-cf-smoke, 35-auth-flows | VERIFIED |
| sendPasswordResetEmail | onCall | 6 | 11-cf-inventory, 16-cf-smoke, 35-auth-flows | VERIFIED |
| sendTrialExpirationWarning | onSchedule | 4 | 11-cf-inventory, 28-tier4-resend, 92-cf-smoke-ical | VERIFIED |
| setLifetimeLicense | onCall | 3 | 11-cf-inventory, 16-cf-smoke, 31-security-audit | thin |
| setPropertySubdomain | onCall | 5 | 11-cf-inventory, 54-cf-smoke, 86-f94 + 96 | VERIFIED (recently — SF-076) |
| syncIcalFeedNow | onCall | 6 | 11-cf-inventory, 12-widget-e2e, 16-cf-smoke | VERIFIED |
| updateBookingAtomic | onCall | 8 | 11-cf-inventory, 16-cf-smoke, 26-bb-e2e | VERIFIED |
| updateBookingTokenExpiration | onCall | 5 | 11-cf-inventory, 16-cf-smoke, 93-cf-smoke-payment | VERIFIED |
| updateUserStatus | onCall | 5 | 11-cf-inventory, 16-cf-smoke, 31-security-audit | VERIFIED |
| verifyBookingAccess | onCall | 9 | 06-bookings-hotfix, 08-null-tostring, 09-wave0 | VERIFIED |
| verifyEmailCode | onCall | 6 | 11-cf-inventory, 16-cf-smoke, 25-e2e-test-catalog | VERIFIED |

**CF roll-up:** 55 CFs total. **Zero CFs with 0 audit hits.** 6 CFs with single-audit (`11-cloudfunctions-inventory.md`) coverage = inventoried but never functionally tested. Median hits = 6.

---

## Table C — Surfaces with no dedicated audit

Surfaces are clusters from `firestore.rules`, `storage.rules`, `lib/features/`, and `lib/core/`. A surface is "uncovered" if it has < 4 distinct `audit/*.md` mentions AND no audit explicitly named after it.

### C.1 — Firestore collections

| Collection | Audit mentions | Dedicated audit? | Gap class |
|---|---|---|---|
| `users` | 41 | rules-tighten 77/78 | — |
| `properties` | 39 | 86-f94-direct-write | — |
| `units` | 35 | 86-f94 | — |
| `bookings` | 67 | many | — |
| `daily_prices` | 16 | 90 (cutover) | — |
| `widget_settings` | 25 | 17, 21, 22, 92 | — |
| `widget_secrets` | 16 | 87-secret-sanity | — |
| `ical_events` | 17 | 17-sf023-sf025, 92 | — |
| `ical_feeds` | 9 | (legacy split: dev top-level vs subcollection) | **GAP — top-level deprecated block per memory `audit-98-top-level-ical-feeds-gap` (F-98-01 LOW)** |
| `platform_connections` | 5 | none | thin |
| `email_verifications` | 7 | 35-auth-flows | — |
| `stripe_webhook_events` | 8 | 54-cf-smoke (TTL) | thin |
| `email_templates` | 2 | none | **GAP — manageable from rules only; no Flutter UI surface, but rule + CF read path uncovered** |
| `tenants` | 4 | none dedicated | thin |
| `app_config` | 6 | none dedicated | thin |
| `security_events` | 9 | 84-security-sweep | — |
| `oauth_states` | 2 | none | **GAP — SSO state collection; Stripe Connect path** |
| `sync_failures` | 2 | none | **GAP — iCal sync error sink; observability surface** |
| `ai_chats` | 2 | none | **GAP — AI chat collection in rules, but no feature folder in `lib/features/` — orphan?** |
| `notifications` | 9 | 95-cf-scheduled-triggers | — |
| `rate_limits` | 3 | 91-cf-smoke-auth | thin |
| `devices` | 8 | 94-f91-03 (SF-065) | — |
| `loginAttempts` | 14 | 53, 55-f50-02, 64, 67, 89-audit-50-backlog (SF-050) | — |
| `additional_services` | 5 | none dedicated | thin |
| `user_profiles` | 4 | none dedicated | thin |

### C.2 — Flutter feature folders

| Folder | Distinct audit mentions | Gap |
|---|---|---|
| `lib/features/owner_dashboard` | 20 | — |
| `lib/features/widget` | 20 | — |
| `lib/features/auth` | 8 | — |
| `lib/features/admin` | 4 | thin |
| `lib/features/subscription` | 2 | **GAP — lifetime + free-trial flows audited only at CF layer (SF-036, SF-027/037); Flutter screens never smoke-tested standalone** |

`lib/core/` subdirs (no per-dir audit): `accessibility`, `design_tokens`, `error_handling`, `errors`, `exceptions`, `init`, `models`, `providers`, `theme` — covered transversally via 71-design + 80-design-system-foundation + 77-a11y-perf-sweep, no dedicated security/regression audit.

### C.3 — CF gaps (re-stated from Table B)

| CF | Reason gap matters |
|---|---|
| `checkPasswordHistory` | password-history bypass risk if regression; never tested in isolation |
| `savePasswordToHistory` | same class; symmetric to above |
| `revokeAllRefreshTokens` | account-takeover defense; auth-CRIT path with **zero behavioral evidence** beyond CF existing |
| `monthlyRevenueReport` | revenue figure drift / PII in email; observability |
| `newAppUpdateNotification` | admin push-broadcast; abuse if RBAC weak |
| `onPropertyDeleted` | cascade-cleanup correctness; data-loss class; no smoke beyond inventory |

### C.4 — Audit categories under-represented

- **Admin dashboard** (only audit/37, 81-responsive-harness, design audits) — admin RBAC + impersonation paths never E2E-tested on PROD.
- **Subscription / billing** (SF-027/037 PR #481, SF-036 #508) — closed at code review, not at end-to-end "lifetime user pays → webhook → app downgrades correctly" smoke.
- **Trial-expiration / cooldown flows** (`checkTrialExpiration`, `sendTrialExpirationWarning`, `migrateTrialStatus`) — scheduled jobs, triggers documented in inventory only.
- **OAuth state / SSO** (`oauth_states` collection + Stripe Connect onboarding) — referenced in 12-widget-e2e + 15-prod-contamination but no dedicated post-cutover smoke.

---

## Table D — Top 5 real test candidates

Ranked by **PROD-relevant CLAIMED-NOT-VERIFIED severity × distance from current PROD state**. Excludes anything VERIFIED-PROD, REJECTED, DEFERRED, or doc/UX-only. Excludes SF-050 from re-test recommendation because the gap is an **operator IAM fix** (audit/90 §0 F-90-01), not a new test — listed at #1 because the runbook step must execute before any other login-flow re-test will produce meaningful signal.

| Rank | Item | Why PROD-CRIT | Test recipe (one-liner) |
|---|---|---|---|
| **1** | **SF-050 + F-90-01** (PROD `loginLockout` IAM gap) | `recordloginfailure` / `getloginlockoutstatus` / `clearloginattempts` PROD Cloud Run services have empty IAM bindings (`etag: ACAB`). GFE 403 → `rate_limit_service.dart` fails open. Per-email lockout is currently **non-functional on PROD**. | Operator: `gcloud run services add-iam-policy-binding` loop per audit/90 §0; then re-probe OPTIONS preflight from `app.bookbed.io` Origin → expect 204 + ACAO. |
| **2** | **SF-032 + SF-033** (widget_secrets exfil — Stripe key + Resend key migration, PR #481) | `widget_settings.stripe_config` no longer reads owner sk_live; `widget_secrets` split stores no Resend key. Owner-fronted property → widget overlay flow on PROD never smoke-validated end-to-end after migration. Class-of-leak: 2 of the 3 most-sensitive secrets ever embedded in widget paths. | Trigger one widget overlay booking on PROD with a fresh test owner: capture the network trace and confirm zero `sk_live_` / `re_` strings in JS bundle or postMessage payloads. |
| **3** | **SF-036** (customer.subscription.deleted respects accountType=lifetime, PR #508) | Lifetime owners must not be silently downgraded if Stripe sends a `customer.subscription.deleted` event for their (non-existent) sub. Webhook test fixture exists; PROD event in the wild not asserted. Single misfire = revenue + UX incident. | Stripe CLI: `stripe trigger customer.subscription.deleted --add customer.metadata[accountType]=lifetime` against PROD `handleStripeWebhook` endpoint with a fresh test customer; assert `users/{uid}.account_type` unchanged in Firestore. |
| **4** | **SF-054** (PII log redaction sweep, PR #516) | Email-sending CFs may still log addresses / names at ERROR severity, reaching Cloud Logging `jsonPayload.message` even after PR #495's redactor (see memory `pr483-stack-leak-finding`). PII surface on PROD = compliance exposure. | Tail PROD logs for 1h: `gcloud logging read 'resource.type=cloud_run_revision AND severity=ERROR' --project=rab-booking-248fc --limit=200 \| grep -E '@.+\\..+'` → expect zero matches in jsonPayload.message. |
| **5** | **SF-046** (App Check audit-only mode on widget CFs) | Telemetry should be flowing for `getUnitAvailability` + `getUnitIcalFeed` even though enforcement is off. If no telemetry on PROD = silent regression making future enforcement migration risky. | `gcloud logging read 'resource.type=cloud_run_revision AND jsonPayload.appCheck=*' --project=rab-booking-248fc --limit=50` — expect non-zero attestations from real widget hits. |

Honourable mentions (not in top 5 because dev-only-smoke evidence already exists, but PROD re-smoke would close them):
- SF-038 (Stripe webhook event.id dedup) — VERIFIED-DEV-ONLY; needs real PROD webhook traffic to confirm `stripe_webhook_events` writes.
- SF-047 (subdomainService auth gate + per-uid rate limit) — VERIFIED-DEV-ONLY.
- SF-062 (CORS allowlist on 8 framework-default callables) — VERIFIED-DEV-ONLY; PROD cutover gate per audit/90.
- SF-066 (FLUTTER-7B Sentry filter) — VERIFIED-DEV-ONLY; PROD Sentry quota-impact unmeasured.
- SF-067 (storage rules DELETE deny + Firestore-lookup IAM) — VERIFIED-DEV-ONLY; PROD operator-gated per audit/91.

---

## Table E — Numbering collisions (hygiene)

### E.1 — `audit/N` filename collisions (multiple files share same prefix)

| `N` | Count | Files | Notes |
|---|---|---|---|
| 86 | 5 | `86-android-sf-smoke-0529.md`, `86-data-integrity-edge-2026-05-30.md`, `86-f94-direct-write.md`, `86-ios-smoke-2026-05-29.md`, `86-orphan-sweep.md` | sub-topic spam; recommend rename 86b/86c/… or move under `audit/86/` dir |
| 91 | 4 | `91-cf-smoke-auth.md`, `91-data-layer-smoke.md`, `91-f91-02-storage-delete.md`, `91-flutter-7b-ical-noise.md` | one wave, multiple smokes; recommend renumber tail |
| 77 | 3 | `77-a11y-perf-sweep.md`, `77-rules-tighten-migration-2026-05-29.md`, `77-visual-qa-sweep-2026-05-29.md` | three unrelated topics share 77; rename tail |
| 18 | 3 | `18-booking-count-audit.md`, `18-dependabot-triage-2026-05-22.md`, `18-stash-classification-2026-05-22.md` | early-corpus drift |
| 95, 92, 89, 87, 81, 78, 62, 50, 35, 16, 12, 11, 08 | 2 each | (see `ls audit/*.md \| sed 's/^([0-9]+).*/\1/' \| sort \| uniq -c \| sort -rn`) | mostly tolerable; if a future automation indexes by integer, dedup needed |

### E.2 — `SF-NNN` collisions (within `docs/SECURITY_FIXES.md` itself)

Distinct head counts in the file (highest 10 = "referenced often", not "duplicated heads"). The single load-bearing collision is **SF-062** (memory `[[sf-062-pr567-naming-conflict]]`): PR #565 (CORS) and PR #567 (audit-50-backlog devices field allowlist) both claim SF-062. The bundle in audit/95 §2 reconciled by allocating PR #567's work to a new SF; this audit treats SF-062 = PR #565 (CORS allowlist), which matches the SECURITY_FIXES.md head. SF-065 collision is documented and resolved (SF-065 = PR #567 devices). SF-067 collision: audit/91 closure ⇒ PR #575, audit/95 bundle § same — no actual conflict, label only.

Numbering gaps in the SF allocation (intentional reservations or stale numbering): **SF-024** (merged into SF-023/SF-025), **SF-041..SF-045** (reserved block, no entries), **SF-075** (no entry — bundle reconciliation per audit/95). These are *holes*, not collisions; document them in `docs/SECURITY_FIXES.md` once for traceability.

### E.3 — Cross-corpus

- 50 of the 108 audit files (46%) contain **no `SF-NNN` reference** — early Wave 0 exploratory + design-system + UX audits. Not a defect; classify as "non-security-fix audits".
- Several SF entries are documented in `audit/90 §1.2` reconcile table (lines 49–63) only and not in any per-finding audit. That single table is the authoritative ledger for SF-061..SF-070 PROD status; if it ever drifts, all of Table A goes stale.

---

## Recommendation (one sentence)

**The only PROD-relevant netted surface that warrants a net-new test is the SF-050 follow-on operator step (F-90-01 IAM grant) plus a PROD smoke of SF-032/033/036/046/054 — every other "✅ Riješeno" entry either has dev-only smoke evidence, is a doc-class fix where re-test value is low, or rides the audit/90 cutover sequence that will functionally re-verify it; six CFs (`checkPasswordHistory`, `savePasswordToHistory`, `revokeAllRefreshTokens`, `monthlyRevenueReport`, `newAppUpdateNotification`, `onPropertyDeleted`) are inventoried but never smoke-tested and would be worth a single rainy-day "owner ops" smoke pass.**

---

## Pointers (no action taken in this audit)

- audit/90 §0 `F-90-01` — operator IAM grant; required before any new login-flow smoke.
- PR #482 — `widget_secrets` migration still gated; closure validates SF-021/032/033 simultaneously.
- audit/95 §2 — SF numbering reconcile table; canonical reference for SF-062 vs SF-065 vs SF-067 attribution.
- memory `[[sf-062-pr567-naming-conflict]]` — flag for next CLAUDE.md edit.
- memory `[[audit-98-top-level-ical-feeds-gap]]` — F-98-01 LOW; deprecated legacy `ical_feeds` block lacks `affectedKeys` deny; surface still PROD-bounded.
