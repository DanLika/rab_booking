# Claude Code - Project Documentation

**BookBed** - Booking management platforma za property owner-e.

**Dodatni dokumenti:**
- [CLAUDE_BUGS_ARCHIVE.md](./docs/bugs-archive/CLAUDE_BUGS_ARCHIVE.md) - Detaljni bug fix-evi sa code examples
- [CLAUDE_WIDGET_SYSTEM.md](./docs/cloud-widget-systems/CLAUDE_WIDGET_SYSTEM.md) - Widget modovi, payment logic, pricing
- [CLAUDE_MCP_TOOLS.md](./docs/cloud-mcp-tools/CLAUDE_MCP_TOOLS.md) - MCP serveri, slash commands
- [EMAIL_SYSTEM.md](./docs/features/email-templates/EMAIL_SYSTEM.md) - Email template-i, payment rok, reminders
- [SECURITY_FIXES.md](./docs/SECURITY_FIXES.md) - Sigurnosne ispravke (SF-001..SF-073)
- [CHANGELOG.md](./docs/CHANGELOG.md) - Svi changelogi
- [TODO.md](./docs/TODO.md) - Planirani zadaci

**Audit log** (one-line index; detail in each audit/*.md file):
- [11-cloudfunctions-inventory](./audit/11-cloudfunctions-inventory.md) — CF inventory dev/prod + orphans (2026-05-21)
- [11-sentry-env-fix](./audit/11-sentry-env-fix.md) — Sentry env-tag + Gen2 `GCLOUD_PROJECT` (2026-05-21)
- [17-sf023-sf025-rules-fix](./audit/17-sf023-sf025-rules-fix.md) — SF-023 ical_events lockdown + SF-025 storage rules (2026-05-22)
- [18-booking-count-audit](./audit/18-booking-count-audit.md) — booking-count surface audit (2026-05-22)
- [19-wave3-cleanup](./audit/19-wave3-cleanup.md) — Wave 3 cleanup tracking (2026-05-22)
- [20-error-boundary-narrowing](./audit/20-error-boundary-narrowing.md) — ErrorBoundary VM-extension narrowing (2026-05-23)
- [21-sprint-summary](./audit/21-sprint-summary-2026-05-22-23.md) — PRs #447/#448/#449 + fail-CLOSED matrix (2026-05-23)
- [22-prod-cutover-plan](./audit/22-prod-cutover-plan.md) — T11c + SF-023..026 cutover order (2026-05-23)
- [23-misc-follow-ups](./audit/23-misc-follow-ups.md) — Tier 2D doc-only follow-ups (2026-05-23)
- [24-p3-backlog](./audit/24-p3-backlog-investigations.md) — P3 backlog from audit/21 (2026-05-23)
- [25-e2e-test-catalog](./audit/25-e2e-test-catalog.md) — E2E surfaces + gaps + runbook (2026-05-23)
- [26-bb-e2e-findings](./audit/26-bb-e2e-findings.md) — owner direct-write bypass + provider_id gap (2026-05-23)
- [27-bb-e2e-cc-reject](./audit/27-bb-e2e-cc-reject.md) — CC reject: pending→cancelled + calendar release (2026-05-23)
- [28-tier4-resend-sentry](./audit/28-tier4-resend-sentry-baseline.md) — 18-template provider_id matrix + DORMANT-5 (2026-05-23)
- [30-ical-cache-invalidation](./audit/30-ical-cache-invalidation.md) — PR #461 helper + 4 call sites (2026-05-24)
- [32-tier4-widget-ui-smoke](./audit/32-tier4-widget-ui-smoke-2026-05-23.md) — widget UI smoke pre-#450 (PR #464, 2026-05-23)
- [33-owner-dashboard-web-smoke](./audit/33-owner-dashboard-web-smoke-2026-05-24.md) — dev hosting served PROD bundle; fix `ae1b18f3` + PR #467 (2026-05-24)
- [34-booking-lifecycle-e2e](./audit/34-booking-lifecycle-e2e-2026-05-24.md) — onBookingCreated `emails_sent` gap (PR #465, 2026-05-24)
- [35-auth-flows-smoke](./audit/35-auth-flows-smoke-2026-05-24.md) — register/verify/reset; PR #466/#470 closure; digits kept in `sanitizeName` (2026-05-24)
- [36-ios-owner-smoke](./audit/36-ios-owner-smoke-2026-05-24.md) — iOS smoke; iOS-01/02 RESOLVED via PR #455 + audit/40 (PR #468, 2026-05-24)
- [37-admin-dashboard-smoke](./audit/37-admin-dashboard-smoke-2026-05-24.md) — admin DEV pre-check (PR #469, 2026-05-24)
- [38-pr462-env-prereq](./audit/38-pr462-env-prereq.md) — ALLOWED_SUBSCRIPTION_PRICE_IDS empty/missing on dev+prod (2026-05-24)
- [39-n4-flutter-keyboard-converter](./audit/39-n4-flutter-keyboard-converter-2026-05-24.md) — Flutter Engine KeyboardConverter crash; SAFETY no-fix (2026-05-24)
- [40-finding-ios-02](./audit/40-finding-ios-02-investigation.md) — seed wrote `check_in_date` not `check_in`; fix `be93449a` worktree-only (2026-05-24)
- [48-consolidation](./audit/48-consolidation-2026-05-24.md) — closed 6-day CI red; 22 PRs Wave 2A–2I (2026-05-24)
- [49-post-merge-smoke](./audit/49-post-merge-smoke-orchestration-2026-05-24.md) — parallel platform smoke + env-tag fix (2026-05-24)
- [50-security-audit](./audit/50-security-audit-2026-05-25.md) — 15 findings; F-50-01/02/03 CRITICAL (2026-05-25)
- [51-final-cleanup-summary](./audit/51-final-cleanup-summary-2026-05-25.md) — 42→11 PRs, 658→49 MiB pack, 0 incidents (2026-05-25)
- ✅ [53-prod-stripe-name-leak](./audit/53-prod-stripe-name-leak-2025-12-21.md) — SF-051 CLOSED (key rotated, secret deleted, 2026-05-26)
- [54-cf-smoke](./audit/54-cf-smoke-2026-05-26.md) — SF-038/047/048 + Sentry + TTL on dev; PR #515 (2026-05-26)
- ✅ [55-f50-02-pr517-design-note](./audit/55-f50-02-pr517-design-note-2026-05-27.md) — F-50-02 CLOSED via PR #517 SF-050 (2026-05-27)
- [56-pr514-review](./audit/56-pr514-review-2026-05-26.md) — 9 findings PASS + lookup-callback fix `1c3d6985`; hex IPv6 hole deferred (2026-05-26)
- [57-vibe-security](./audit/57-vibe-security-2026-05-27.md) — 26 OPEN findings; H-01 Stripe-linkage UID-squat (2026-05-27)
- [58-vibe-security-delta](./audit/58-vibe-security-delta-2026-05-27.md) — SF-056 batch via PRs #526/#527/#528; 11 closures (2026-05-27)
- [58-chrome-devtools-audit](./audit/58-chrome-devtools-audit-2026-05-27.md) — 17 findings; F-58-01/02/03/07/08 (2026-05-27)
- [58b-walkthrough-plan](./audit/58b-walkthrough-plan-2026-05-27.md) — chrome-devtools test plan (2026-05-27)
- 🚨 [58c-live-walkthrough](./audit/58c-live-walkthrough-2026-05-27.md) — F-58c-13 IP-geo PII leak + F-58c-14 logout multi-store; 21 findings (2026-05-27)
- [62-ios-e2e-smoke](./audit/62-ios-e2e-smoke-2026-05-28.md) — 15 PASS/2 FAIL/56 DEFERRED; 6 net-new F-62-* (2026-05-28)
- ✅ [63-android-e2e-smoke](./audit/63-android-e2e-smoke-2026-05-28.md) — F-63-04 chip clip @ font 2.0× (PR #535 closure, 2026-05-28)
- ✅ [64-chrome-e2e-smoke](./audit/64-chrome-e2e-smoke-2026-05-28.md) — F-64-04 html lang attr (PR #534 closure, 2026-05-28)
- [65-code-fixes-batch](./audit/65-code-fixes-batch-2026-05-28.md) — PRs #532/#533/#534/#535; F-62-05 deep-link DEFERRED (2026-05-28)
- ⏳ [66-ios-deepflow](./audit/66-ios-deepflow-2026-05-28.md) — IN PROGRESS iOS deepflow on 56-deferred set (2026-05-28)
- 🚨 [67-chrome-deepflow](./audit/67-chrome-deepflow-2026-05-28.md) — F-67-01 P1 Confirm/Reject silent no-op + 5 more (2026-05-28)
- [68-stripe-dashboard-tasks](./audit/68-stripe-dashboard-tasks-2026-05-28.md) — F-61-01/07/08 webhook expand 2→7 events (2026-05-28)
- [84-security-sweep](./audit/84-security-sweep-2026-05-29.md) — PRs #557/#558/#559 close audit/79 §3; CORS-shape IAM strip gotcha (2026-05-29)
- 🚨 [90-prod-cutover-runbook](./audit/90-prod-cutover-runbook.md) — F-90-01 PROD loginLockout IAM gap; PR #565→#482 order (2026-05-29)
- [91-data-layer-smoke](./audit/91-data-layer-smoke.md) — 37/37 Firestore + 16/16 Storage probes; F-91-02/03 (2026-05-30)
- 🚨 [91-f91-02-storage-delete](./audit/91-f91-02-storage-delete.md) — F-91-02 DELETE deny + SEC-001/SF-025 silent no-op closure SF-067 (2026-05-30)
- [91-flutter-7b-ical-noise](./audit/91-flutter-7b-ical-noise.md) — FLUTTER-7B CLOSED via PR #568 SF-066 (2026-05-29)
- 🟡 [92-cf-smoke-ical-email](./audit/92-cf-smoke-ical-email-2026-05-30.md) — F-92-01 MED iCal empty-token bypass; 15-CF matrix (2026-05-30)
- 🟡 [92-f92-01-ical-token](./audit/92-f92-01-ical-token.md) — F-92-01 fix; `verifyIcalToken` empty-fail-CLOSED (SF-063, 2026-05-30)
- 🚨 [93-cf-smoke-payment](./audit/93-cf-smoke-payment-2026-05-30.md) — F-93-02 P1 `findBookingById` Strategy 2 path; PR #572 (2026-05-30)
- [95-f93-bundle](./audit/95-f93-bundle.md) — SF numbering reconciliation + F-93 P3 bundle SF-071/072/073 (2026-05-30)
- ✅ [89-f86-01-cors-fix](./audit/89-f86-01-cors-fix.md) — F-86-01 SF-062 closure; PR #565 8 callables (2026-05-29)
- [89-audit-50-backlog](./audit/89-audit-50-backlog.md) — PR #567 closes 5 SFs; F-50-09/10/11/12 (2026-05-29)
- [98-dev-cutover-smoke](./audit/98-dev-cutover-smoke.md) — bookbed-dev cutover dry-run; F-CUT-01 lockfile drift closed via commit `167e6353` (2026-05-30)
- [99-coverage-gap-map](./audit/99-coverage-gap-map.md) — SF + CF coverage gap map; 6 CFs never smoke-tested (PR #608, 2026-05-30)
- 🚨 [99-security-audit](./audit/99-security-audit-2026-05-30.md) — multi-agent sweep; F-99-01 HIGH bookings deny-list gap + 3 MED + 7 LOW + 4 INFO + 1 CONFIRM-OPEN audit/89 (2026-05-30)
- 🟡 [100-audit99-high-bundle](./audit/100-audit99-high-bundle.md) — SF-078: F-99-01 bookings deny + H-1 host-only returnUrl + H-2 SF-073 localhost gate + H-3 17-callable CORS; PR #609 DEV-only (2026-05-31)
- 🟡 [101-vibe-security-delta](./audit/101-vibe-security-delta-2026-05-31.md) — F-101-01/02 returnUrl `startsWith` boundary + SF-073 utils localhost regression (closed PR #609 parallel branch); F-101-03 MED in-memory rate-limit Map multi-instance bypass OPEN (2026-05-31)
- ✅ [102-prod-cutover](./audit/102-prod-cutover-2026-05-31.md) — PROD cutover at HEAD `3a8b6b66`: CFs+regrant 35/35+OPTIONS 3/3, indexes no-drift, widget HTTP 200, rules+storage 4/4 smoke; **SF-067 PROD `datastore.viewer` IAM confirmed via owner upload+delete on `properties/…png`** (2026-05-31)
- [cutover-dryrun-2026-05-30/runbook.md](./audit/cutover-dryrun-2026-05-30/runbook.md) — full ledger + 4a/4b/4c/4d phase logs + IAM re-grant script (2026-05-30)
- [103-redesign-tokens-primitives-shell](./audit/103-redesign-tokens-primitives-shell.md) — Phase 1 foundation (PR #611) + §Amendment Phase 1.7 `BbAdminDarkTokens` deep-purple admin shellBg `#1E1A33` ThemeExtension (PR #643, additive — owner light+dark untouched, isolation-guard tests enforce, 2026-06-01) + §Amendment Phase 2 Admin Login Bb* swap + route-scoped extension injection (PR #650, `ThemeData.dark` base, +195/-321, 2026-06-02)
- [106-qa-visual-regression](./audit/106-qa-visual-regression-2026-06-01.md) — 12 Phase 2 screens, 0 UNINT drift, 1 BLOCKED (Widget Confirmation Navigator.push), 1 product Q (Pregled KPI tile content swap) (2026-06-01)
- 🟡 [107-security-audit](./audit/107-security-audit-2026-06-01.md) — multi-agent sweep on `main @ 866cc823`; F-107-01 HIGH `widget_secrets` `affectedKeys` gap + F-107-02 MED CORS 5 callables (audit/89 follow-up) + F-107-03 MED widget surface minimal CSP; 9 NEW + 4 KNOWN-OPEN + 25 verified-closed (2026-06-01)
- ⏸️ [108-admin-redesign-smoke-blocked](./audit/108-admin-redesign-smoke-blocked-2026-06-02.md) — Tier 3 admin `BbCard` panelBg `#2A2342` smoke ABORTED at precondition; PRs #646 (canonicalize admin shell→panelBg) + #647 (BbCard resolves admin panelBg via ext) both OPEN on `main @ 4d81e106`; re-run after merge (2026-06-02)
- ✅ [114-owner-mobile-design-qa](./audit/114-owner-mobile-design-qa-2026-06-05.md) — 22-screen Marionette + adb sweep vs `design_handoff` Premium; 3 rounds. R1: 7-item P-queue (3× P1 + 4× P2). R2: F1 (Mjesečni `Završeno` purple via `BBColor.statusCompleted`, PR #677) + F2 closed false-positive (Booking.com brand mark IS B-in-blue) + F4 re-scoped → F4b. R3: PR #675 (Pregled hero command €0+ / occupancy radial / AI insight kDebug-gated / channel mix kDebug-gated placeholder) + PR #676 (Notifications inline `Odobri`/`Odbij` on `bookingCreated` cards) verified live on `bookbed-dev`; F4b CLOSED-as-design-intent (PR #615 swapped `rd.heroGradient → rd.softBg` deliberately). Process gotchas → [[design-sweep-gotchas]]: worktree `build_runner` before analyze, hot-restart needs logout+relogin, sparse `revenueHistory` hides hero delta+sparkline by design. PRs #675+#676+#677 merged 2026-06-05 (2026-06-05)

---

## NIKADA NE MIJENJAJ

| Komponenta | Razlog |
|------------|--------|
| Cjenovnik tab CONTENT (`unified_unit_hub_screen.dart` — pricing grid + Spremi) | FROZEN - referentna implementacija. Hub screen-shell chrome (premium header above existing layout, theme/AppBar) je additive-OK; FROZEN scope = tab content only. |
| Unit Wizard publish flow | 2-doc serial write (unit → widget_settings, Doc 2 id sourced from Doc 1) — redoslijed kritičan |
| Timeline Calendar z-index | Cancelled bookings at base (drawn first), confirmed on top |
| Calendar Repository (`firebase_booking_calendar_repository.dart`) | 989 linija, duplikacija NAMJERNA - bez unit testova NE DIRATI |
| Owner email u `atomicBooking.ts` | UVIJEK šalje - NE vraćaj conditional check |
| Subdomain validation regex | `/^[a-z0-9][a-z0-9-]{1,28}[a-z0-9]$/` (3-30 chars) |
| `generateViewBookingUrl()` u `emailService.ts` | Email URL logika |
| Navigator.push za confirmation | NE vraćaj state-based navigaciju |
| Timeline Calendar fixed dimensions (`timeline_dimensions.dart`) | FIXED 50/42/100/60px za SVE uređaje — NE vraćaj responsive breakpoints |
| `bookings` read rule — `unit_id+status` clause 1 | ✅ T11c CLOSED 2026-05-22 (commit `ab6bdb3d`). All 3 rule surfaces tightened. Widget calendar + booking-submit route through `getUnitAvailability` callable (eu-west1). Realtime → 30s polling. Privacy-driven: pending/confirmed visual distinction sacrificed. Vidi SF-019 + audit/06. |

---

## STANDARDI

```dart
// Gradients
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
- `AppColors`/`AppDimensions`/`AppTypography`/`AppShadows` su source of truth (BB* delegira); **NE** refaktoriraj postojeće call sites in-place — bulk codemod je zaseban PR
- 3 off-scale TODO consts: `BBSpace.xs2=12`, `BBRadius.xs2=8`, svih 9 `BBType.*`
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

**Dart formatiranje** - CI odbija PR ako kod nije formatiran:
```bash
dart format .
```

**Za AI agente:** UVIJEK pokreni `dart format .` prije commit-a.

**CI build-android job** (`.github/workflows/ci.yml` Job 3): koristi `./tool/build_aab.sh --release` wrapper — NE `flutter build appbundle` direktno (pukne na flutter_native_splash registry bug). Vidi `.claude/rules/hosting-build.md` + `audit/16-android-regression-full.md` Appendix B.

---

## TOOLING GOTCHA: `flutter analyze` phantom errors

Ako `flutter analyze` izvijesti **tisuće** `uri_does_not_exist` / `undefined_identifier` / `undefined_method` errora — **NE TRETIRAJ ih kao bug u kodu**. Skoro sigurno je pub-cache desync.

**Quick check:** `ls -d ~/.pub-cache/hosted/pub.dev/firebase_core-* 2>/dev/null`

**Fix:** `flutter pub get`. Vidi `audit/04b-flutter-analyze-summary.md` (6053 reported → 0 real).

---

## Path-Scoped Rules (`.claude/rules/`)

Učitavaju se SAMO kad radiš na matchujućim fajlovima:

| Fajl | Path scope | Sadržaj |
|------|-----------|---------|
| `cloud-functions.md` | `functions/src/**/*.ts` | Logger, UTC, rate limiting, Sentry, bookingLookup, FieldPath bug |
| `stripe.md` | `functions/src/stripe*.ts`, `lib/**/stripe*`, `lib/**/payment*` | LIVE MODE, checkout flow, webhook, min amount |
| `calendar.md` | `lib/**/calendar/**`, `lib/**/timeline/**` | DateStatus, turnover, fixed dimensions, repository rules |
| `widget.md` | `lib/features/widget/**`, `lib/widget_main*.dart`, `web/bookbed-overlay.js` | URL slugs, subdomene, snackbar boje, iframe overlay |
| `admin.md` | `lib/features/admin/**`, `lib/admin_main*.dart`, `functions/src/admin/**` | Admin panel, Firestore rules, providers |
| `ui-ux.md` | `lib/**/*.dart` | Design system, animacije, dialogs, skeleton loaders |
| `keyboard-fix.md` | `lib/**/presentation/screens/**`, `web/index.html`, `lib/core/utils/keyboard_dismiss*` | Android mixin, 3 koraka za nove forme |
| `hosting-build.md` | `firebase.json`, `.firebaserc`, `web/**`, `.github/workflows/**`, `android/**`, `ios/**`, `pubspec.yaml` | Domene, build commands, deploy targets |
| `firestore.md` | `firestore.rules`, `firestore.indexes.json` | Composite vs single-field, collection group, deploy |
| `fcm-pwa.md` | `lib/core/services/fcm_service*`, `web/firebase-messaging-sw.js`, `functions/src/fcmService.ts`, `lib/**/pwa/**` | Push notifikacije, PWA install, SW |
| `auth.md` | `lib/features/auth/**`, `lib/**/enhanced_auth_provider*`, `functions/src/auth*`, `functions/src/emailVerification*` | Sign-In flows, email verifikacija, Remember Me, provider cache security |
| `ios-development.md` | `ios/**`, `lib/main*.dart`, `lib/widget_main*.dart` | GoogleService-Info.plist swap, `--target` requirement, Dart project-ID asserts |
| `android-development.md` | `android/**`, `lib/main*.dart`, `lib/widget_main*.dart`, `tool/build_aab.sh` | google-services.json swap, debug-build `--release`, AAB blocker fix, 16KB page-size |
| `build-runner.md` | `pubspec.yaml`, `build.yaml`, `analysis_options.yaml`, `**/*.g.dart` | Fresh-clone `--delete-conflicting-outputs`, pub-cache desync distinction |

---

**Last Updated**: 2026-06-06 | **Version**: 7.13.1

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
