# Claude Code - Project Documentation

**BookBed** - Booking management platforma za property owner-e.

**Dodatni dokumenti:**
- [CLAUDE_BUGS_ARCHIVE.md](./docs/bugs-archive/CLAUDE_BUGS_ARCHIVE.md) - Detaljni bug fix-evi sa code examples
- [CLAUDE_WIDGET_SYSTEM.md](./docs/cloud-widget-systems/CLAUDE_WIDGET_SYSTEM.md) - Widget modovi, payment logic, pricing
- [CLAUDE_MCP_TOOLS.md](./docs/cloud-mcp-tools/CLAUDE_MCP_TOOLS.md) - MCP serveri, slash commands
- [EMAIL_SYSTEM.md](./docs/features/email-templates/EMAIL_SYSTEM.md) - Email template-i, payment rok, reminders
- [SECURITY_FIXES.md](./docs/SECURITY_FIXES.md) - Sigurnosne ispravke (SF-001, SF-002, ...)
- [CHANGELOG.md](./docs/CHANGELOG.md) - Svi changelogi v4.6–v6.87
- [TODO.md](./docs/TODO.md) - Planirani zadaci (Website Docs, Admin Controls, Security Fixes)
- [audit/11-cloudfunctions-inventory.md](./audit/11-cloudfunctions-inventory.md) - CF inventory (dev/prod), orphans, P0/P1/P2 cleanup (2026-05-21)
- [audit/11-sentry-env-fix.md](./audit/11-sentry-env-fix.md) - Sentry env-tag fix + Gen 2 `GCLOUD_PROJECT` finding (2026-05-21)
- [audit/17-sf023-sf025-rules-fix.md](./audit/17-sf023-sf025-rules-fix.md) - SF-023 ical_events lockdown + SF-025 storage rules + booking_services cleanup, dev-deployed (2026-05-22)
- [audit/18-booking-count-audit.md](./audit/18-booking-count-audit.md) - Booking-count surface audit (2026-05-22)
- [audit/19-wave3-cleanup.md](./audit/19-wave3-cleanup.md) - Wave 3 cleanup task tracking (2026-05-22)
- [audit/20-error-boundary-narrowing.md](./audit/20-error-boundary-narrowing.md) - ErrorBoundary catches VM-extension exceptions — narrowing proposal (2026-05-23)
- [audit/21-sprint-summary-2026-05-22-23.md](./audit/21-sprint-summary-2026-05-22-23.md) - Sprint close-out: PRs #447/#448/#449, mobile smoke, fail-CLOSED verification matrix (2026-05-23)
- [audit/22-prod-cutover-plan.md](./audit/22-prod-cutover-plan.md) - PROD cutover plan T11c + SF-023..026; canonical CF→widget→rules order; §8 open Qs Q1/Q5/Q6 user-input gated (2026-05-23)
- [audit/23-misc-follow-ups.md](./audit/23-misc-follow-ups.md) - Tier 2D consolidated investigation: 4 deferred items doc-only (2026-05-23)
- [audit/24-p3-backlog-investigations.md](./audit/24-p3-backlog-investigations.md) - P3 backlog from audit/21: getUnitIcalFeed region + getUnitAvailability logWarn + --release rule (2026-05-23)
- [audit/25-e2e-test-catalog.md](./audit/25-e2e-test-catalog.md) - Comprehensive E2E test catalog: surfaces under test, gaps, runbook (2026-05-23)
- [audit/26-bb-e2e-findings.md](./audit/26-bb-e2e-findings.md) - BB E2E findings consolidation: owner direct-write bypass + `provider_id` gap (2026-05-23)
- [audit/27-bb-e2e-cc-reject.md](./audit/27-bb-e2e-cc-reject.md) - BB E2E CC reject flow execution (Terminal D): pending → cancelled + rejection_reason → calendar release → re-book same dates (2026-05-23)
- [audit/28-tier4-resend-sentry-baseline.md](./audit/28-tier4-resend-sentry-baseline.md) - Tier 4 Resend + Sentry baseline: 18-template provider_id matrix (static), SPF gap (A1), DORMANT-5 finding (A2 → superseded by PR #462), trigger/verify/sentry scripts, fail-CLOSED recipe (2026-05-23)
- [audit/30-ical-cache-invalidation.md](./audit/30-ical-cache-invalidation.md) - iCal export cache invalidation (PR #461): helper extracted, 4 call sites, date-edit gate, atomicBooking pre-flush, icalSync deferred (2026-05-24)
- [audit/33-owner-dashboard-web-smoke-2026-05-24.md](./audit/33-owner-dashboard-web-smoke-2026-05-24.md) - Owner Dashboard web smoke HALTED on P1: `bookbed-owner-dev.web.app` deployed PROD-bundled build → Firestore writes hitting `rab-booking-248fc` instead of `bookbed-dev`; 3-part fix landed (owner_main_dev.dart asserts + per-env build commands + `tool/deploy-dev.sh` wrapper) via merge `ae1b18f3`; admin DEV surface follow-up in PR #467 (`fix/audit-33-admin-dev` → `lib/admin_main_dev.dart` + `tool/deploy-dev.sh` admin case + hosting-build.md TODO closed); owner DEV runtime HAR verified clean (0 PROD hits / 13 `bookbed-dev` Firestore + 2 `us-central1-bookbed-dev` CF) §11.3 (2026-05-24)
- [audit/32-tier4-widget-ui-smoke-2026-05-23.md](./audit/32-tier4-widget-ui-smoke-2026-05-23.md) - TIER 4 widget UI smoke (chrome-devtools), pre-#450 baseline: 4 ✅, CP3 widget_mode coupling 🟡, CP5 HR locale gap (PR #464, 2026-05-23)
- [audit/34-booking-lifecycle-e2e-2026-05-24.md](./audit/34-booking-lifecycle-e2e-2026-05-24.md) - Booking lifecycle E2E (BB + CC approve+reject): NEW §5 — `onBookingCreated` writes ZERO `emails_sent.*` keys (idempotency exposure); audit/27 §3+§5 still hold (PR #465, 2026-05-24)
- [audit/35-auth-flows-smoke-2026-05-24.md](./audit/35-auth-flows-smoke-2026-05-24.md) - Auth flows smoke (register/verify/reset): 5 checkpoints, 6 findings; C2 Gmail Authentication-Results DEFERRED §5.2; 2 PROD UIDs flagged for manual delete; CHANGELOG 6.44 cooldown drift 60↔30 (PR #466, 2026-05-24). **F-Auth-D1 + F-Auth-D2 closure PR #470** (`fix/audit-35-displayname-cooldown`, commit `bad97caa`): `InputSanitizer.sanitizeName` allow-list extended `[^\p{L}\s'\-]` → `[^\p{L}\p{N}\s'\-]` (digits preserved — "BB Smoke C1" no longer truncates to "BB Smoke C"); CHANGELOG 6.44 "30-second" corrected to "60-second" + audit/35 footnote. Tests 52/52 green (incl. 2 new regression tests + 1 stale assert updated). Defence-in-depth unchanged: `_htmlTagPattern` + `containsDangerousContent()` still catch XSS/SQLi. Side-effect: `submit_booking_use_case.dart:117` widget guest names now also keep digits.
- [audit/36-ios-owner-smoke-2026-05-24.md](./audit/36-ios-owner-smoke-2026-05-24.md) - iOS owner app smoke (marionette): 5 pass + 2 docs-gap + 1 blocked; FINDING-iOS-01 ErrorBoundary catches Marionette taps **✅ RESOLVED by PR #455** (audit/20 filter covers iOS via message + stack layers; marionette_flutter is pure Dart, platform-independent); FINDING-iOS-02 Rezervacije list empty + drawer badge=1 **✅ RESOLVED by audit/40 + fix `be93449a`** (NOT T11c — seed-data wrote wrong field names: `check_in_date` instead of canonical `check_in`; list query's `.orderBy('check_in')` filtered out the docs at Firestore level; cross-platform not iOS-specific) (PR #468, 2026-05-24)
- [audit/37-admin-dashboard-smoke-2026-05-24.md](./audit/37-admin-dashboard-smoke-2026-05-24.md) - Admin Dashboard smoke (pre-check + DEV probe + admin.md). Run pending: `fix/audit-33-admin-dev` (PR #467) merge + `tool/deploy-dev.sh admin` + admin custom-claim provisioning §9 (PR #469, 2026-05-24)
- [audit/38-pr462-env-prereq.md](./audit/38-pr462-env-prereq.md) - PR #462 BLOCKER: `ALLOWED_SUBSCRIPTION_PRICE_IDS` empty on dev (placeholder 2026-05-21) + missing on prod; fail-CLOSED post-merge → operator must create Stripe Prices (test+live modes) + set per-env env files before merge (2026-05-24)
- [audit/39-n4-flutter-keyboard-converter-2026-05-24.md](./audit/39-n4-flutter-keyboard-converter-2026-05-24.md) - audit/33 §4.4 N4 root cause: Flutter Engine web KeyboardConverter `kWebToLogicalKey[event.key]?[event.location]!` crashes on synthetic input with no entry at that location; stack trace + source-line read of `main.dart.js:63310-63315` confirm framework-internal, not BookBed code; SAFETY-clause no-fix; bonus §9 — SW stale-bundle long-tail on audit/33 N1 (first load returned PROD until SW + cache + IDB cleared) (2026-05-24)
- [audit/40-finding-ios-02-investigation.md](./audit/40-finding-ios-02-investigation.md) - FINDING-iOS-02 root cause: seed scripts wrote `check_in_date`/`check_out_date` instead of canonical `check_in`/`check_out`; list query's `.orderBy('check_in')` filtered out docs at Firestore level (badge omits orderBy, so it still matched). Cross-platform, NOT iOS-specific; T11c/provider_id/cache hypotheses ruled out. **Fix `be93449a`** (`fix/seed-checkin-field-name`, worktree-only, NOT pushed): `scripts/seed-bookbed-dev.js` 2-line rename + idempotent `audit/migrations/40-backfill-checkin-field.js` (5 docs backfilled on bookbed-dev: 4 test owner + 1 SEED_property_dev_01); post-fix live query Query C 0 → 1, all-status mirror 0 → 4. Same fix closes test-env-only side effect: `atomicBooking.ts:743-744` overlap-detection query was also missing these docs (duplicate-overlap writes could slip through). Investigation worktree branch `investigate/finding-ios-02` @ `4b087b09` (audit doc, NOT pushed). audit/36 §D6 "Nedavne Aktivnosti populates" was a misobservation (also confirmed empty pre-fix). Renumbered from audit/38 to avoid collision with [audit/38-pr462-env-prereq.md] (2026-05-24)
- [audit/48-consolidation-2026-05-24.md](./audit/48-consolidation-2026-05-24.md) - Consolidation orchestration: closed 6-day CI red, 22 PRs landed across Waves 2A–2I; bisect→fixture-lag pattern, `commit-tree` retrigger trick, AAB heap OOM under concurrency (2026-05-24)
- [audit/49-post-merge-smoke-orchestration-2026-05-24.md](./audit/49-post-merge-smoke-orchestration-2026-05-24.md) - Post-merge smoke orchestration: parallel platform smoke runs, deploy verification matrix, env-tag fix (2026-05-24)
- [audit/50-security-audit-2026-05-25.md](./audit/50-security-audit-2026-05-25.md) - Security audit (/security-audit:run full): 15 net-new findings (3 CRITICAL, 2 HIGH, 6 MEDIUM, 4 LOW). 3 CRITICAL: F-50-01 subscription priceId allow-list (PR #462 in flight), F-50-02 loginAttempts anon lockout DoS, F-50-03 Stripe webhook event-id dedup. Linked from PR #482 SF-021 widget_secrets Draft (commit `07069abf`, 2026-05-25)
- [audit/51-final-cleanup-summary-2026-05-25.md](./audit/51-final-cleanup-summary-2026-05-25.md) - FINAL_CLEANUP 3-session summary: 42→11 PRs (−74%), 44→18 local branches (−59%), 22→1 worktrees (−95%), 658.89→49.15 MiB pack (−92%), 0 production incidents, 0 forensic loss. Archive at `~/bookbed-final-audit-archive-20260525-185455/`; carryover queue prioritized starting with PR #481 merge (2026-05-25)
- [audit/53-prod-stripe-name-leak-2025-12-21.md](./audit/53-prod-stripe-name-leak-2025-12-21.md) - **P0** PROD Stripe live key leaked via Secret Manager NAME (SF-051): `firebase-managed: functions` secret `SK_LIVE_51SIS_..._LD9VEX1` (123 chars) is sanitized uppercase form of `sk_live_51SIsGkBomKO...` value (same sha256 as proper-named `STRIPE_SECRET_KEY`). Zero CF bindings — dangling. Visible since 2025-12-21 to anyone with `roles/secretmanager.viewer`. Rotate key + delete secret + IAM audit. Discovered during PR #513 iOS smoke (2026-05-26)
- [audit/54-cf-smoke-2026-05-26.md](./audit/54-cf-smoke-2026-05-26.md) - CF-level security smoke on bookbed-dev for SF-038/047/048 + Sentry + TTL: 3 GREEN (B subdomain rate-limit, C delete cooldown, E TTL policy) + 2 deferred (A webhook dedup Stripe acct mismatch, D Sentry runtime filter). PR #515 reconciles Sentry DSN env-var fix lost during branch divergence; throwaway-user + parallel-call test patterns. NOT prod-cutover-ready. (2026-05-26)
- [audit/55-f50-02-pr517-design-note-2026-05-27.md](./audit/55-f50-02-pr517-design-note-2026-05-27.md) - F-50-02 CLOSED via PR #517 (SF-050) dev smoke + narrative correction. 3 CFs in eu-west1 (`recordLoginFailure`/`getLoginLockoutStatus`/`clearLoginAttempts`), `loginAttempts/{email}` rule locked to `read, write: if false`, `rate_limit_service.dart` refactored. 3/3 smokes PASS on bookbed-dev. **Narrative correction**: `_rateLimit.resetAttempts(email)` is already POST `signIn`/`createUser` at both call sites (722 + 954) — earlier "reorder pre→post-auth" follow-up was based on inverted audit-doc, no longer needed. **Design tradeoff**: IP rate limit on `recordLoginFailure` (1/60s) means rapid same-IP mistypes only bump counter by 1 — lockout reachable via slow user OR distributed attacker (App Check closes the latter). Re-runnable smokes at `audit/smoke/f50-02-smoke{1,2,3}.sh`. (2026-05-27, PR #517)
- [audit/56-pr514-review-2026-05-26.md](./audit/56-pr514-review-2026-05-26.md) - PR #514 review: 9 audit findings all PASS (1 HIGH webhook compensating-delete + 5 MED return-URL allowlist / launchUrl scheme / postMessage origin / SSRF DNS pin / token-expiration auth + 3 LOW rules). Live SSRF smoke on bookbed-dev exposed pinned `https.RequestOptions.lookup` callback regression: Node 18+ `autoSelectFamily` passes `options.all=true`, PR returned 3-arg form → `ERR_INVALID_IP_ADDRESS: Invalid IP address: undefined` — every legit feed would break post-merge. Fix `1c3d6985`: detect `options.all` + dispatch array OR 3-arg. Regression test added (synthetic options, no real network). 8/8 SSRF vectors still BLOCKED on fixed deploy. 10/10 CI green. Deferred: hex IPv4-mapped IPv6 regex hole in `isPrivateOrUnsafeIp` (SF-052 candidate, [[ssrf-ipv4-mapped-ipv6-hex-hole]]) + stripePayment.ts local `isAllowedReturnUrl` duplication. (2026-05-26)
- [audit/57-vibe-security-2026-05-27.md](./audit/57-vibe-security-2026-05-27.md) - `/vibe-security` 4-agent full baseline on `main` HEAD (`a2831e91` post PR #514/#516). 26 OPEN findings: 3 CRITICAL all CLOSED in-PR (C-01/C-02/C-03 via PR #514), 8 HIGH (H-01..H-09 minus already-closed H-03), 11 MEDIUM (M-01..M-11), 7 LOW (L-01..L-07). H-01 Stripe-linkage UID-squat applied to `firestore.rules` deny-list this session — `customer.subscription.deleted` webhook `.where(stripeSubscriptionId).limit(1)` is order-unstable → victim-sub squat downgrades wrong UID. 28/28 rules tests green. (2026-05-27)
- [audit/58-vibe-security-delta-2026-05-27.md](./audit/58-vibe-security-delta-2026-05-27.md) - Delta scan vs audit/57 baseline + 3 fix batches applied. Net-new: N1 npm 12 moderate (transitive, unreachable), N2 `audit/raw/secrets.txt` Firebase Web keys (false positive — public by design), N3 hosting-header gap matrix (refines M-09), N4 Node engine mismatch (dev-ergonomics). SF-vibe57 batch CLOSED 11 findings across **PRs #526 (rules H-01/M-04/M-05/L-04 + 11 new tests) + #527 (CF code H-04/H-06/H-08/H-09/M-11 + 15 new tests in cc9cbdcf) + #528 (hosting M-09 partial + N3)**. M-09 owner+admin CSP DEFERRED (canvaskit needs `unsafe-eval` + visual smoke). Verification: rules 39/39, unit 317/317, tsc 0. Open: H-02 (largest), H-05, H-07 + 7 meds + 6 lows. (2026-05-27, SF-056)
- [audit/58-chrome-devtools-audit-2026-05-27.md](./audit/58-chrome-devtools-audit-2026-05-27.md) - HTTP-only surface audit on bookbed-dev hosting + CFs (no DevTools panels — chrome-devtools MCP not loaded). 17 findings (4 P1, 3 P2, 7 P3, 3 info). Headlines: F-58-01 PaymentBridge origin whitelist missing DEV hosts → dev payment silently broken; F-58-02 widget DEV hosting unshipped since audit/33 §11.4 FCM SW fix landed; F-58-03 admin DEV 4.5 months stale; F-58-07 `onCall` framework default reflects arbitrary Origin on ALL ~35 callables (not just `cors:true` — confirmed round-3 us-central1 probe); F-58-08 major CF region split (~22 us-central1 incl Stripe/booking/email; ~13 eu-west1 incl admin/auth-security). Re-verified positives: source maps not exposed (PR #516), HSTS preload, anon Firestore properties/units read PER DESIGN (`firestore.rules:178/184`), Stripe webhook signature gate fires, Semgrep 1.156.0 0 SAST findings on 14 files. (2026-05-27)
- [audit/58b-walkthrough-plan-2026-05-27.md](./audit/58b-walkthrough-plan-2026-05-27.md) - Walkthrough test plan staged for post-restart chrome-devtools MCP session: owner+widget+admin coverage matrix, destructive policy, account creds, output spec. Pre-flight: `tool/deploy-dev.sh widget && tool/deploy-dev.sh admin` to close audit/58 F-58-02/03 BEFORE walkthrough. (2026-05-27)
- [audit/58c-live-walkthrough-2026-05-27.md](./audit/58c-live-walkthrough-2026-05-27.md) - Live Chrome walkthrough on bookbed-dev (Playwright 1.58.2 over CDP, real Chrome 148 headed session). 21 findings. **P1 NEW: F-58c-13 `ipwhois.app` + `ipapi.co` PII leak on every login/signup** — `lib/core/services/ip_geolocation_service.dart` called from `enhanced_auth_provider.dart:734/:973/:2263` (3 callsites); Sentry filter in `main.dart:539-542` + `widget_main.dart:155-158` silences failures; 403 already observed (rate-limited). P2: F-58c-14 logout requires 4-store clear (sessionStorage + localStorage + IDB + cookies + reload); F-58c-20 notification badge inconsistency confirmed 3× (drawer=9, bell=6, then=1). 0 console errors across 9 owner routes + widget. Routes: 8 working / 10 confirmed-404 (settings/profile/email/ai = `ai-assistant`/faq etc). Owner-side "Nova rezervacija" modal verified: 5 required fields, XSS payload typed → inert. Widget calendar dates render canvas-only — screen reader users CANNOT pick dates (a11y P3 F-58c-21). Chrome left running at CDP port 9222. (2026-05-27)
- [audit/62-ios-e2e-smoke-2026-05-28.md](./audit/62-ios-e2e-smoke-2026-05-28.md) - iOS Owner E2E smoke on bookbed-dev via Marionette MCP. 15 PASS / 2 FAIL / 56 DEFERRED across 73-test matrix (scope/network/risk-driven deferrals). 6 net-new findings: F-62-01 logout no confirm modal (P2), F-62-02 `connectivity_plus` false-negative "Nema interneta" while Firebase succeeds (INFO), F-62-03 iOS confirms F-58c-14 multi-store-clear gap (P3), F-62-04 wizard 4 steps not 5 (spec note), F-62-05 `bookbed://unit/{id}` warm-start no-op (P2), F-62-06 Firebase 12.8→12.13 pod-update cascade (build runbook). 0 P0/P1 net-new. Plist swap PROD→dev→PROD verified clean. No throwaway writes (network reliability). Pods updated locally (uncommitted). (2026-05-28)
- [audit/63-android-e2e-smoke-2026-05-28.md](./audit/63-android-e2e-smoke-2026-05-28.md) - Android Owner E2E smoke on bookbed-dev (Pixel_8 emulator). F-63-04 — at system font_scale=2.0 "Zadnjih 30/90/365 dana" tabs clip viewport edge with no horizontal scroll affordance; "Otkazane" partial-clipped to "O…" already at 1.0× HR locale. Closed by [audit/65](./audit/65-code-fixes-batch-2026-05-28.md) PR #535 (Wrap refactor + Container.alignment fix b5332f92). (2026-05-28)
- [audit/64-chrome-e2e-smoke-2026-05-28.md](./audit/64-chrome-e2e-smoke-2026-05-28.md) - Chrome E2E smoke on bookbed-dev across 12 viewports (`H1`-`H12`) + prod surfaces (`M1`-`M3`) + dev admin/widget probes (`A1`/`C1`/`C2`). F-64-04 — `<html>` missing `lang` attr, Chrome a11y audit flag. Closed by [audit/65](./audit/65-code-fixes-batch-2026-05-28.md) PR #534. Lighthouse a11y 100/100 post-fix. (2026-05-28)
- [audit/65-code-fixes-batch-2026-05-28.md](./audit/65-code-fixes-batch-2026-05-28.md) - Batch fix for 5 findings from audit/62+63+64: PR #532 (F-62-01 logout confirmation), #533 (F-62-03 clear saved_email + remember_me on explicit logout, stacked on #532), #534 (F-64-04 html lang=hr), #535 (F-63-04 chip Wrap on Pregled + Rezervacije, follow-up b5332f92 removes Container.alignment that caused desktop full-width stack regression). F-62-05 deep-link warm-start DEFERRED — no `app_links` plugin + no listener wiring + `/unit/{id}` route case missing; >50 LOC + architectural. MCP smoke 4 rounds: HR-light + EN-light + EN-dark + Pixel_8 EN; Lighthouse a11y 100/100; 0 console errors. flutter test 1205/1205 each branch. (2026-05-28)
- ⏳ [audit/66-ios-deepflow-2026-05-28.md](./audit/66-ios-deepflow-2026-05-28.md) - **IN PROGRESS** (background agent `a1926b49`): iOS deep-flow retest of audit/62 56-deferred-test set on bookbed-dev via Marionette MCP (Flutter VM, `--target lib/main_dev.dart`, `--machine` JSON). Priority G booking lifecycle > C wizard publish > A destructive auth > F iCal > H. **Spec correction** from pre-flight grep: Odobri/Odbij/Otkaži/Završi buttons live on `BookingCardActions` in `owner_bookings_screen.dart`, NOT in `BookingDetailsDialogV2`; owner-side cancel = bookkeeping write only (status=cancelled + cancellation_reason + cancelled_at) — Stripe refund only via `guestCancelBooking` CF on guest surface, so G6/G7 reframed as "owner cancel preserves payment record". **E Stripe BLOCKED on iOS** — owner app has no embedded widget (web-surface only → see audit/67). PROD plist swap → `.plist.backup` per `.claude/rules/ios-development.md`. Output pending. (2026-05-28)
- 🚨 [audit/67-chrome-deepflow-2026-05-28.md](./audit/67-chrome-deepflow-2026-05-28.md) - Chrome DevTools deep-flow retest closing audit/64 C-G spec-gap on bookbed-dev. C wizard 7/8 ✅, D widget 9/12 ✅, F iCal 3/5 ✅, J security 3/3 ✅. **E BLOCKED** at pre-Stripe — `createStripeCheckoutSession` 400 `FAILED_PRECONDITION: "Owner has not connected their Stripe account"` (egress NOT blocked, contrary to [[ios-smoke-2026-05-26]]; needs Connect onboarding for `bookbed-test@bookbed.io`). **6 net-new findings**: F-67-01 **P1** Owner Confirm/Reject UI silent no-op (UI direct-writes Firestore, T11c rules deny, no error surfaced — **all Web booking lifecycle broken**); F-67-02 P2 "Unknown Guest" everywhere — schema split `guest_name` vs `guest_first_name`/`guest_last_name`; F-67-03 P2 Widget Special Requests cross-session localStorage/IDB leak (`pt:alert(document.cookie)` fragment observed on fresh load); F-67-04 P2-tool Flutter web `fill()` drops 1-5 leading chars (workaround `click→Meta+a→Delete→fill`); F-67-05 P3 `syncIcalFeedNow` leaks upstream host in error; F-67-06 INFO slug auto-fill 1-char. `createBookingAtomic` confirmed 2-stage (validation→commit-via-Stripe-webhook). Bookings live at `properties/{pid}/bookings/{bid}` (NOT under units subcol). Cleanup: unit + ical_feed deleted, 0 bookings created. (2026-05-28)
- [audit/68-stripe-dashboard-tasks-2026-05-28.md](./audit/68-stripe-dashboard-tasks-2026-05-28.md) - Stripe Dashboard tasks executed via REST + PROD `STRIPE_SECRET_KEY` v5 (CLI on CallidusOS sandbox `acct_1T6Y41Q82cgbc9Mn` → REST fallback to PROD `acct_1SIsGkBomKO7vDr0`). **Task 1 DONE** F-61-01/07/08: webhook `we_1SgiznBomKO7vDr0CSwE9NNj` expanded 2→7 events (`charge.refunded`, `customer.subscription.{deleted,updated}`, `invoice.{paid,payment_failed}` added); api_version unchanged `2025-09-30.clover` ([[stripe-webhook-api-version-immutable]] — pinning = 6-step rotation); no signing-secret rotation, no CF redeploy (audit/61 handlers already cover). **Task 2 BLOCKED** F-64-bonus: `business_profile.name` via `POST /v1/accounts/{platform-own-acct}` errors "only connected accounts" → Dashboard-only ([[stripe-platform-own-account-api-locked]]). **Task 3 DONE**: 3 abandoned Connect children marked `rejected.other`. **Task 4 DEFERRED** F-61-03: dev webhook api_version parity. (2026-05-28)
- [audit/84-security-sweep-2026-05-29.md](./audit/84-security-sweep-2026-05-29.md) - Autonomous PROD sweep closes audit/79 §3 findings via PR #557 (CSP owner+admin + hosting headers redeployed), PR #558 (F-58c-13 IP-geo CF `getClientGeolocation` europe-west1 + F-58c-14 `signOut()` multi-store wipe via conditional import), PR #559 (F-58-07 10 explicit `cors: true` → `getCorsAllowlist()` allowlist). App Check flip DEFERRED — `firebase_app_check` pub dep loaded but no `FirebaseAppCheck.instance.activate(...)` callsite. **OPERATIONAL**: deploying onCall with `cors: ARRAY` (vs `cors: true`) on Firebase v2 stripped `allUsers/invoker` IAM on PROD for all 7 updated CFs (eu-west1 + us-central1); ~60s degraded window before `gcloud run services add-iam-policy-binding` re-grant. (2026-05-29)
- 🚨 [audit/90-prod-cutover-runbook.md](./audit/90-prod-cutover-runbook.md) - PROD cutover runbook (sequenced). §0 **F-90-01 P1 silent broken**: PROD SF-050 loginLockout trio (`recordloginfailure`/`getloginlockoutstatus`/`clearloginattempts`) have empty IAM policy (etag ACAB, no allUsers) — OPTIONS preflight returns HTTP/2 403 from GFE on all three vs positive control `getunitavailability` 204+ACAO; `rate_limit_service.dart` falls open → per-email server-side login-attempt counter NON-FUNCTIONAL on PROD right now; fix is independent 3-line `gcloud run services add-iam-policy-binding` loop, NOT bundled with cutover. §1 pre-cutover: ICAL_TOKEN_PEPPER MISSING on PROD (blocks PR #482), ALLOWED_SUBSCRIPTION_PRICE_IDS bound but EMPTY across all probed CFs (fail-CLOSED), daily_prices composite READY, 0 real CF orphans (5 expected Firebase Extensions), all 50+ Cloud Run service names lowercase verified, STRIPE_SECRET_KEY v=5 healthy. §3 sequenced: PR #565 (SF-062 CORS on 8 callables) → PR #482 (SF-021 widget_secrets). §4 IAM re-grant loop mandatory post any cors-shape-change deploy. §6 8 operator blockers (B-1..B-8). §7 out-of-scope: SF-061 App Check enforcement, SF-052 Sentry lazy init, staging cleanup, audit/88 branch deletes. (PR #566, 2026-05-29)
- [audit/91-data-layer-smoke.md](./audit/91-data-layer-smoke.md) - Data-layer smoke on bookbed-dev: emulator rules 46/46 PASS (brief expected 53 — count drift documented), live Firestore + Storage rulesets byte-identical to `main` worktree, **37/37 Firestore probes + 16/16 Storage probes PASS** across anon + auth + foreign-uid actors, 64/64 indexes deployed + READY (incl. `daily_prices` COLLECTION `available+date` target), 0 orphans/missing. **F-91-02 P3**: storage `users/{uid}/**` client-SDK DELETE returns 403 because `allow write` requires `request.resource.size`/`.contentType` which fail when `resource=null` on DELETE — class analytically extends to `properties/{pid}/**` + `ical-exports/{pid}/{uid}/**`; UX bug (users can't remove uploaded files via SDK), no CF helper. **F-91-03 P2**: `users/{uid}/devices/{deviceId}` Firestore rule has NO field allowlist — `PATCH attacker_field` accepted 200; defense-in-depth gap vs CLAUDE.md memory implying SF-062 devices allowlist (memory mis-tagged; SF-062 on `docs/audit-90-prod-cutover-runbook` branch is CORS work). F-91-04 INFO partial coverage on `widget_settings` noSecrets (needs owned-property seed). Reproduction recipe + REST gotchas (reserved-ID `__` prefix; `pageSize` rejected on indexes list) in §8. F-91-01 reserved for parallel `sanitizeEmail` finding ([[sanitize-email-no-format-check]]). (2026-05-30)
- 🚨 [audit/93-cf-smoke-payment-2026-05-30.md](./audit/93-cf-smoke-payment-2026-05-30.md) - Payment + booking CF smoke on bookbed-dev (51 cases, 9 CFs, NULL PROD writes). **F-93-02 P1**: `findBookingById` Strategy 2 builds bookingChecks against `properties/*/units/*/bookings/{id}` (4-level legacy) but canonical write target is `properties/*/bookings/{id}` (3-level, `atomicBooking.ts:1216`) → `guestCancelBooking` + `updateBookingTokenExpiration` (the 2 callers without ownerId Strategy-1 hint) silently NOT_FOUND every legit booking. Fixed in-PR: parallel-check both paths + `unitId ?? data.unit_id` fallback; 10/10 jest green incl. new canonical-path regression. Other findings: F-93-01 P3 `BASE_ALLOWED_DOMAINS` includes `http://localhost` for ALL envs (PROD too); F-93-03 P3 webhook accepts GET/PUT; F-93-04 P3 webhook returns 500 (not 400) on malformed JSON. Verified: SF-001 ownerId server-fetch, SF-005 phone XSS strip, SF-008 notes 1000 cap, SF-022 Sentry HttpsError client-fault filter clean, SF-027 priceId fail-CLOSED (allowlist empty), SF-034/054 NO stack leak in 51 responses. Skipped: webhook dedup smoke (needs Stripe-signed event replay), Connect refund (blocked F-70-02 hCaptcha). Renumbered from 91→92→93 to avoid collision with parallel sessions [[sanitize-email-no-format-check]] + [[ical-export-empty-token-bypass]]. (2026-05-30)
- 🟡 [audit/92-cf-smoke-ical-email-2026-05-30.md](./audit/92-cf-smoke-ical-email-2026-05-30.md) - Autonomous CF smoke on bookbed-dev (iCal + email + notif + lifecycle): 15-CF matrix; F-92-01 **MEDIUM** `getUnitIcalFeed` empty-token bypass on partially-migrated widget_secrets — verifyIcalToken("","") returns true; trigger URL `…/.ics` strips to empty token; SEED 2/2 vulnerable on dev (PR #482 wrote `ical_export_token_{plaintext,hash}` but code still reads `ical_export_token`); PROD VERIFIED 0/13 vulnerable (legacy slot populated, migration not run). F-92-02 LOW `sendCustomEmailToGuest` validation order (length/CRLF/RFC after DB lookup) makes C3/C4/C5 INCONCLUSIVE this run. F-92-03 INFO `autoCancelExpiredBookings` lacks external/iCal source filter parity with autoComplete. SSRF guards + BEGIN:VCALENDAR guard STATIC-only (behavioural deferred). All scheduled CFs deployed + firing. round-trip ical_external + echo skip + platform attrib GREEN. resendBookingEmail H-06 5/hr rate limit GREEN. all 4 bookingActions ownership-gate GREEN. Cleanup: 0 throwaway users, 0 orphan ical_events. (2026-05-30)
- [audit/95-f93-bundle.md](./audit/95-f93-bundle.md) - SF numbering reconciliation (#565→SF-062, #567 5-fix group→SF-064/065/068/069/070, #568→SF-066, #574→SF-063, #575→SF-067) + F-93 P3 bundle on `functions/src/stripePayment.ts`: F-93-03 (SF-071) `handleStripeWebhook` POST-only 405 with `Allow: POST`; F-93-04 (SF-072) malformed JSON → 400 "Invalid JSON payload" via `SyntaxError` + `StripeInvalidRequestError` + `/JSON/i` matcher in catch; F-93-01 (SF-073) `localhost` / `127.0.0.1` moved from unconditional `base` to `if (isEmulator)` append in `getAllowedReturnDomains()`. 395/395 jest + 46/46 rules green; no PROD deploy. (2026-05-30)
- 🟡 [audit/92-f92-01-ical-token.md](./audit/92-f92-01-ical-token.md) - F-92-01 MEDIUM (SF-063) `getUnitIcalFeed` empty-token bypass: `crypto.timingSafeEqual(Buffer.from(""), Buffer.from(""))` returns true → URL `…/{p}/{u}/.ics` strips third segment to empty, matches empty `tokenToCompare` (PR #482 widget_secrets migration on bookbed-dev moved tokens to `_plaintext`/`_hash` suffixed fields that `main`'s `icalExport.ts:165` does not read → fall-through to legacy blank → bypass). 3 URL forms exploit on bookbed-dev: `/.ics`, `/.ICS` (regex `/i`), `/%2eics` (Express URL-decode). HEAD also leaks via cache-headers. 2/2 SEED units VULNERABLE; PROD non-vulnerable (legacy slot still populated). Fix: 5-line fail-CLOSED `if (providedToken.length === 0 || storedToken.length === 0) return false;` in `verifyIcalToken` before pad+timingSafeEqual. Tests: 16/16 icalExport (+4 new) + 391/391 functions, 0 tsc. Branch `test/f92-01-ical-token-deep-0530`, PR pending, NOT deployed. SF-062 reserved for audit/89 PR #565. (2026-05-30)
- 🚨 [audit/91-f91-02-storage-delete.md](./audit/91-f91-02-storage-delete.md) - F-91-02 storage DELETE deny + SEC-001/SF-025 silent-no-op closure (SF-067). storage.rules: `allow write` bundled `request.resource.size`+`contentType` gates → null on DELETE → silent owner DELETE deny across `users/**`, `properties/**`, `ical-exports/**`. **Bonus** discovery: SEC-001 (Jan 7) + SF-025 (May 22) Firestore lookups used `get(...)` (Firestore-rules-only — compiler `[W] Invalid function name: get`) and `$(database)` (unbound in Storage rules) → owner write/delete on `properties/**` + `ical-exports/**` silently denied for 5 months / 8 days. Hidden by `users/{uid}/properties/...` upload path + `ical_export_service.dart:131-137` catch-and-log. Fix: split `allow create, update` + `allow delete` + `get`→`firestore.get` + `$(database)`→`(default)`. **IAM**: grant `roles/datastore.viewer` to `service-{PROJECT_NUMBER}@gcp-sa-firebasestorage.iam.gserviceaccount.com` (bookbed-dev ✅ 2026-05-30; PROD operator-gated). 17/17 smoke PASS on bookbed-dev. PROD cutover prereq logged to [audit/90](./audit/90-prod-cutover-runbook.md). (2026-05-30)
- ✅ [audit/89-f86-01-cors-fix.md](./audit/89-f86-01-cors-fix.md) - F-86-01 closure (SF-062): `cors: getCorsAllowlist()` wired on 8 framework-default callables left untouched by audit/84 PR #559. Payment hot-path (`createBookingAtomic`, `createStripeCheckoutSession`, `guestCancelBooking`) + `checkSubdomainAvailability` (us-central1) + auth-sec stack (`deleteUserAccount`, `recordLoginFailure`, `getLoginLockoutStatus`, `clearLoginAttempts`) on europe-west1. 2 test mocks extended (`firebase-functions/params` → `Expression: class Expression {}`) to keep module-load `instanceof` check from `TypeError`. PR #565 dev-deployed bookbed-dev + IAM re-grant both regions; 34-cell smoke matrix GREEN (8 OPTIONS × 3 origins + 9 widget-origin incl wildcard regex + 1 functional POST). **Cloud Run service-name gotcha**: dev services are lowercase (firebase v2 normalization) → `gcloud run services list` first before scripting IAM loop. PROD deploy + IAM re-grant deferred to manual gate per `[[cf-deploy-cors-shape-iam-strip]]`. (2026-05-29)
- [audit/89-audit-50-backlog.md](./audit/89-audit-50-backlog.md) - Audit/50 backlog close-out via PR #567 (5 SFs in one PR). **SF-061** F-50-05a undici override audited (tree no longer pulls undici under firebase-admin 12.6 + Node 20 native fetch; override stays defense-in-depth, 0 CVE matches). **SF-062** F-50-09 `devices/{deviceId}` update key allowlist (`lastSeenAt`/`fcmToken`/`appVersion`/`platform` only; `deviceId`/`createdAt`/`userAgent` immutable) + 7 regression tests `functions/test/firestore_rules/devices.test.ts` — verified vs `lib/core/services/security_events_service.dart:270-280` `set(merge:true)` (advisor caught fabricated `pushEnabled`/`tokenUpdatedAt`/`lastActiveAt` extras → tightened in commit `c700ea8b`). **SF-063** F-50-10 `web/index.html:669` `eval('class … () => … \`tmpl\`')` → native `typeof`-probes (`Symbol`/`Promise`/`Map`/`Set`/`Proxy`/`Reflect`). **SF-064** F-50-11 `web/iframe_resizer.js` postMessage `'*'` → handshake-pinned parent origin (`{type:'bookbed-widget-init'}` event.origin or referrer fallback; never broadcasts). **SF-065** F-50-12 `git rm -r audit/raw/` (22 files inc. `secrets.txt` recon dump) + `.gitignore` rule. Verification: `tsc` 0, jest 387/387, rules 53/53 (46 base + 7 new), 0 undici CVEs. F-50-04/02/03 already closed in earlier PRs (#495/#517/audit/70); F-50-06/07/08/05b shipped via SF-057. F-50-05 App Check still deferred (no client `activate(...)` callsite). (2026-05-29)
- [audit/89-audit-50-backlog.md](./audit/89-audit-50-backlog.md) - Audit/50 backlog close-out via PR #567 (5 SFs in one PR). **SF-064** F-50-05a undici override audited (tree no longer pulls undici under firebase-admin 12.6 + Node 20 native fetch; override stays defense-in-depth, 0 CVE matches). **SF-065** F-50-09 `devices/{deviceId}` update key allowlist (`lastSeenAt`/`fcmToken`/`appVersion`/`platform` only; `deviceId`/`createdAt`/`userAgent` immutable) + 7 regression tests `functions/test/firestore_rules/devices.test.ts` — verified vs `lib/core/services/security_events_service.dart:270-280` `set(merge:true)` (advisor caught fabricated `pushEnabled`/`tokenUpdatedAt`/`lastActiveAt` extras → tightened in commit `c700ea8b`). **SF-068** F-50-10 `web/index.html:669` `eval('class … () => … \`tmpl\`')` → native `typeof`-probes (`Symbol`/`Promise`/`Map`/`Set`/`Proxy`/`Reflect`). **SF-069** F-50-11 `web/iframe_resizer.js` postMessage `'*'` → handshake-pinned parent origin (`{type:'bookbed-widget-init'}` event.origin or referrer fallback; never broadcasts). **SF-070** F-50-12 `git rm -r audit/raw/` (22 files inc. `secrets.txt` recon dump) + `.gitignore` rule. Verification: `tsc` 0, jest 387/387, rules 53/53 (46 base + 7 new), 0 undici CVEs. F-50-04/02/03 already closed in earlier PRs (#495/#517/audit/70); F-50-06/07/08/05b shipped via SF-057. F-50-05 App Check still deferred (no client `activate(...)` callsite). (2026-05-29)
- [audit/91-flutter-7b-ical-noise.md](./audit/91-flutter-7b-ical-noise.md) - **FLUTTER-7B CLOSED** via PR #568 / SF-066. `functions/src/icalSync.ts` adds `isUserFaultIcalError()` next to `isTransientFetchError()`; routes SSRF guard rejections / HTTP 4xx / malformed-URL errors through `logWarn` in all 3 catch sites (syncSingleFeed inner, syncIcalFeedNow outer, scheduledIcalSync loop). `feed.last_error` + `status:"error"` persistence + SSRF guard logic untouched. **Key finding**: F-67-05 (PR `50753cf5`) converted inner throws to `HttpsError("failed-precondition")` so `sentry.ts` `beforeSend` filter drops the thrown path, BUT `fetchIcalData` still rejects plain `Error('HTTP 4\d\d:')` for upstream 4xx — bypasses `beforeSend` (filter only matches HttpsError exception type) and re-surfaces noise on every wrong feed URL owner pastes. Tests 389/389 (+2 regression: file:// → logWarn, empty-body → logError stays). (2026-05-29)

---

## NIKADA NE MIJENJAJ

| Komponenta | Razlog |
|------------|--------|
| Cjenovnik tab (`unified_unit_hub_screen.dart`) | FROZEN - referentna implementacija |
| Unit Wizard publish flow | 3 Firestore docs redoslijed kritičan |
| Timeline Calendar z-index | Cancelled bookings at base level (drawn first), confirmed on top |
| Calendar Repository (`firebase_booking_calendar_repository.dart`) | 989 linija, duplikacija NAMJERNA - bez unit testova NE DIRATI |
| Owner email u `atomicBooking.ts` | UVIJEK šalje - NE vraćaj conditional check |
| Subdomain validation regex | `/^[a-z0-9][a-z0-9-]{1,28}[a-z0-9]$/` (3-30 chars) |
| `generateViewBookingUrl()` u `emailService.ts` | Email URL logika |
| Navigator.push za confirmation | NE vraćaj state-based navigaciju |
| Timeline Calendar fixed dimensions (`timeline_dimensions.dart`) | FIXED 50/42/100/60px za SVE uređaje — NE vraćaj responsive breakpoints |
| `bookings` read rule — `unit_id+status` clause 1 | ✅ T11c CLOSED 2026-05-22 (`fix/t11c-proper-bookings-migration`, commit `ab6bdb3d`). All 3 rule surfaces (subcollection + CG + deprecated top-level) tightened. Widget calendar + booking-submit gate route through `getUnitAvailability` callable (`functions/src/availability.ts`, eu-west1). Realtime `.snapshots()` for bookings sacrificed → 30 s polling via `FirebaseAvailabilityRepository._defaultPollInterval`. Privacy-driven: pending/confirmed visual distinction in widget no longer exists (synthesized `BookingModel.status = confirmed`). See `docs/SECURITY_FIXES.md` SF-019 → T11c CLOSED section + `audit/06-availability-cf-design.md`. |

---

## STANDARDI

```dart
// Gradients (preferred method)
final gradients = context.gradients;

// Input fields - UVIJEK 12px borderRadius
InputDecorationHelper.buildDecoration()

// Provider invalidation - POSLIJE save-a
await repository.updateData(...);
ref.invalidate(dataProvider);

// Nested config - UVIJEK copyWith
currentSettings.emailConfig.copyWith(requireEmailVerification: false)
// NE: EmailNotificationConfig(requireEmailVerification: false) - gubi polja!

// Provider error handling - UVIJEK graceful degradation
try {
  return await repository.fetchData();
} catch (e, stackTrace) {
  await LoggingService.logError('Provider: Failed', e, stackTrace);
  return []; // ili null - NE throw
}
```

**Design tokens (NEW code):**
- Koristi `BB*` iz `lib/core/design/tokens.dart` (`BBSpace`/`BBRadius`/`BBColor`/`BBType`/`BBShadow`) — canonical namespace
- `AppColors`/`AppDimensions`/`AppTypography`/`AppShadows` su i dalje source of truth (BB* delegira na njih); **NE** refaktoriraj postojeće call sites in-place — bulk codemod je zaseban PR
- 3 off-scale TODO consts (čekaju codemod podatke): `BBSpace.xs2=12`, `BBRadius.xs2=8`, svih 9 `BBType.*` (AppTypography nema scalar fontSize konstante)
- Detalji: `audit/05-design.md` Section 8

---

## QUICK CHECKLIST

**Prije commitanja:**
- [ ] `flutter analyze` = 0 issues
- [ ] Pročitaj CLAUDE.md ako diraš kritične sekcije
- [ ] `ref.invalidate()` POSLIJE repository poziva
- [ ] `mounted` check prije async setState/navigation

**Responsive breakpoints:**
- Desktop: ≥1200px
- Tablet: 600-1199px
- Mobile: <600px

---

## OBAVEZNO PRIJE COMMITA

**Dart formatiranje** - CI će odbiti PR ako kod nije formatiran:
```bash
dart format .
```

**Za AI agente (Jules, Sentinel, Bolt):** UVIJEK pokreni `dart format .` prije kreiranja commita. CI workflow provjerava formatiranje i odbija neformatirani kod.

**CI build-android job** (`.github/workflows/ci.yml` Job 3): koristi `./tool/build_aab.sh --release` wrapper — NE `flutter build appbundle` direktno (pukne na flutter_native_splash registry bug). Vidi `.claude/rules/hosting-build.md` § "Android AAB Build" + `audit/16-android-regression-full.md` Appendix B.

---

## TOOLING GOTCHA: `flutter analyze` phantom errors

Ako `flutter analyze` izvijesti **tisuće** `uri_does_not_exist` / `undefined_identifier` / `undefined_method` errora — **NE TRETIRAJ ih kao bug u kodu**. Skoro sigurno je pub-cache desync: `.dart_tool/package_config.json` pokazuje na pakete u `~/.pub-cache/hosted/pub.dev/` koji ne postoje na disku.

**Quick check:**
```bash
ls -d ~/.pub-cache/hosted/pub.dev/firebase_core-* 2>/dev/null
```

**Fix:** `flutter pub get` — re-download missing packages. Nakon toga `flutter analyze` će ponovo davati real signal. Vidi `audit/04b-flutter-analyze-summary.md` za primjer (6053 reported → 0 real).

---

## Path-Scoped Rules (`.claude/rules/`)

Ovi fajlovi se učitavaju SAMO kad radiš na matchujućim fajlovima:

| Fajl | Path scope | Sadržaj |
|------|-----------|---------|
| `cloud-functions.md` | `functions/src/**/*.ts` | Logger, UTC, rate limiting, Sentry, bookingLookup, FieldPath bug |
| `stripe.md` | `functions/src/stripe*.ts`, `lib/**/stripe*`, `lib/**/payment*` | LIVE MODE, checkout flow, webhook, min amount |
| `calendar.md` | `lib/**/calendar/**`, `lib/**/timeline/**` | DateStatus, turnover, fixed dimensions, repository rules |
| `widget.md` | `lib/features/widget/**`, `lib/widget_main*.dart`, `web/bookbed-overlay.js` | URL slugs, subdomene, snackbar boje, iframe overlay |
| `admin.md` | `lib/features/admin/**`, `lib/admin_main*.dart`, `functions/src/admin/**` | Admin panel, Firestore rules, providers |
| `ui-ux.md` | `lib/**/*.dart` | Design system, animacije, dialogs, skeleton loaders |
| `keyboard-fix.md` | `lib/**/presentation/screens/**`, `web/index.html`, `lib/core/utils/keyboard_dismiss*` | Android mixin, 3 koraka za nove forme |
| `hosting-build.md` | `firebase.json`, `.firebaserc`, `web/**`, `.github/workflows/**`, `android/**`, `ios/**`, `pubspec.yaml` | Domene, build commands, deploy targets, dependency verzije |
| `firestore.md` | `firestore.rules`, `firestore.indexes.json` | Composite vs single-field, collection group, deploy |
| `fcm-pwa.md` | `lib/core/services/fcm_service*`, `web/firebase-messaging-sw.js`, `functions/src/fcmService.ts`, `lib/**/pwa/**` | Push notifikacije, PWA install, service worker |
| `auth.md` | `lib/features/auth/**`, `lib/**/enhanced_auth_provider*`, `functions/src/auth*`, `functions/src/emailVerification*` | Apple/Google Sign-In, email verifikacija, Remember Me, provider cache security |
| `ios-development.md` | `ios/**`, `lib/main*.dart`, `lib/widget_main*.dart` | GoogleService-Info.plist swap procedure, `--target` requirement, Dart-level project ID asserts (Wave 0 contamination prevention) |
| `android-development.md` | `android/**`, `lib/main*.dart`, `lib/widget_main*.dart`, `tool/build_aab.sh` | google-services.json swap procedure, debug-build `--release` requirement, AAB blocker fix (`tool/build_aab.sh`), 16KB page-size compliance, deep-link warm/cold coverage |
| `build-runner.md` | `pubspec.yaml`, `build.yaml`, `analysis_options.yaml`, `**/*.g.dart` | Fresh-clone `--delete-conflicting-outputs` recipe, regen triggers, distinguishing pub-cache desync from build_runner errors |

---

**Last Updated**: 2026-05-29 | **Version**: 7.11

# context-mode — MANDATORY routing rules

You have context-mode MCP tools available. These rules are NOT optional — they protect your context window from flooding. A single unrouted command can dump 56 KB into context and waste the entire session.

## BLOCKED commands — do NOT attempt these

### curl / wget — BLOCKED
Any Bash command containing `curl` or `wget` is intercepted and replaced with an error message. Do NOT retry.
Instead use:
- `ctx_fetch_and_index(url, source)` to fetch and index web pages
- `ctx_execute(language: "javascript", code: "const r = await fetch(...)")` to run HTTP calls in sandbox

### Inline HTTP — BLOCKED
Any Bash command containing `fetch('http`, `requests.get(`, `requests.post(`, `http.get(`, or `http.request(` is intercepted and replaced with an error message. Do NOT retry with Bash.
Instead use:
- `ctx_execute(language, code)` to run HTTP calls in sandbox — only stdout enters context

### WebFetch — BLOCKED
WebFetch calls are denied entirely. The URL is extracted and you are told to use `ctx_fetch_and_index` instead.
Instead use:
- `ctx_fetch_and_index(url, source)` then `ctx_search(queries)` to query the indexed content

## REDIRECTED tools — use sandbox equivalents

### Bash (>20 lines output)
Bash is ONLY for: `git`, `mkdir`, `rm`, `mv`, `cd`, `ls`, `npm install`, `pip install`, and other short-output commands.
For everything else, use:
- `ctx_batch_execute(commands, queries)` — run multiple commands + search in ONE call
- `ctx_execute(language: "shell", code: "...")` — run in sandbox, only stdout enters context

### Read (for analysis)
If you are reading a file to **Edit** it → Read is correct (Edit needs content in context).
If you are reading to **analyze, explore, or summarize** → use `ctx_execute_file(path, language, code)` instead. Only your printed summary enters context. The raw file content stays in the sandbox.

### Grep (large results)
Grep results can flood context. Use `ctx_execute(language: "shell", code: "grep ...")` to run searches in sandbox. Only your printed summary enters context.

## Tool selection hierarchy

1. **GATHER**: `ctx_batch_execute(commands, queries)` — Primary tool. Runs all commands, auto-indexes output, returns search results. ONE call replaces 30+ individual calls.
2. **FOLLOW-UP**: `ctx_search(queries: ["q1", "q2", ...])` — Query indexed content. Pass ALL questions as array in ONE call.
3. **PROCESSING**: `ctx_execute(language, code)` | `ctx_execute_file(path, language, code)` — Sandbox execution. Only stdout enters context.
4. **WEB**: `ctx_fetch_and_index(url, source)` then `ctx_search(queries)` — Fetch, chunk, index, query. Raw HTML never enters context.
5. **INDEX**: `ctx_index(content, source)` — Store content in FTS5 knowledge base for later search.

## Subagent routing

When spawning subagents (Agent/Task tool), the routing block is automatically injected into their prompt. Bash-type subagents are upgraded to general-purpose so they have access to MCP tools. You do NOT need to manually instruct subagents about context-mode.

## Output constraints

- Keep responses under 500 words.
- Write artifacts (code, configs, PRDs) to FILES — never return them as inline text. Return only: file path + 1-line description.
- When indexing content, use descriptive source labels so others can `ctx_search(source: "label")` later.

## ctx commands

| Command | Action |
|---------|--------|
| `ctx stats` | Call the `ctx_stats` MCP tool and display the full output verbatim |
| `ctx doctor` | Call the `ctx_doctor` MCP tool, run the returned shell command, display as checklist |
| `ctx upgrade` | Call the `ctx_upgrade` MCP tool, run the returned shell command, display as checklist |
