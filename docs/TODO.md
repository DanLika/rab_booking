# BookBed TODO Items

Extracted from CLAUDE.md — inactive planning items.

---

## 🚨 TODO: PROD cutover queue (audit/90, 2026-05-29)

**Source:** `audit/90-prod-cutover-runbook.md` (PR #566). Read runbook end-to-end before acting on any item below.

**Operator priority order:**

1. **B-3 — F-90-01 SF-050 IAM grants (URGENT, INDEPENDENT of cutover).** PROD `recordloginfailure` / `getloginlockoutstatus` / `clearloginattempts` have empty IAM policy. `rate_limit_service.dart` fails open → per-email server-side login throttle currently non-functional on PROD. Fix:
   ```bash
   for SVC in recordloginfailure getloginlockoutstatus clearloginattempts; do
     gcloud run services add-iam-policy-binding "$SVC" \
       --project=rab-booking-248fc --region=europe-west1 \
       --member=allUsers --role=roles/run.invoker
   done
   ```
   Verify: OPTIONS preflight returns HTTP/2 204 + ACAO header on all three. Effort: XS (~5 min).

2. **B-4 — merge PR #565 (SF-062 CORS allowlist on 8 callables) → run audit/90 §3.1.** No env prereqs. Tests green. ~30 min including IAM re-grant loop + smoke.

3. **B-1 — provision PROD `ICAL_TOKEN_PEPPER`** (Secret Manager, needs `roles/secretmanager.admin` on `rab-booking-248fc`). Recipe in audit/90 §1.1. Gates B-5.

4. **B-2 — populate PROD `ALLOWED_SUBSCRIPTION_PRICE_IDS`** in `functions/.env.rab-booking-248fc` after creating PROD subscription Prices in Stripe Dashboard LIVE mode. Gates B-5.

5. **B-5 — promote PR #482 (SF-021 widget_secrets lockdown) from Draft → ready, merge → run audit/90 §3.2.** Only AFTER B-1 + B-2 green. ~45 min including migration + widget bundle + rules.

**Deferred (operator gate, NOT cutover-blocking):**

- **B-6 — audit/88 branch cleanup.** 12 remote merged-into-main candidates ready for delete; 47 remote unmerged review; 55 local. Per-batch approval required.
- **B-7 — staging cleanup decision.** audit/86 §"STAGING" — 5 real orphans + 13 missing CF deploys. Redeploy or retire staging (no half-mirror).
- **B-8 — SF-052 Sentry `defineString.value()` lazy init.** Cosmetic deploy-time warning. Bundle with next `functions/src/sentry.ts` touch.

**Explicit out-of-scope** (audit/90 §7): SF-061 App Check enforcement (DEFERRED — reCAPTCHA prereq + 7d verified-rate gate), wider CORS sweep beyond 18 already-migrated callables, App Check client init follow-ups (4 of 5 audit/85 boxes still unchecked).

---

## 🚨 TODO: audit/50 security findings (2026-05-25)

**Prioritet:** mixed (3 CRITICAL + 2 HIGH + 6 MEDIUM + 4 LOW = 15 findings)
**Izvor:** `audit/50-security-audit-2026-05-25.md` (/security-audit:run full results, commit `07069abf`)

Priority order matches audit/50 § "Suggested fix order". Single-best-move first:

### Highest-leverage move

- **PR #481 review + merge** (`fix/audit-38-security-sprint`). Manual ~1h. Title: "security(audit/38): role escalation + secrets exfil + price allowlist". Read scope against F-50-01 (`ALLOWED_SUBSCRIPTION_PRICE_IDS`) before merge — if #481 implements allow-list, F-50-01 auto-closes. If only provisions env var, F-50-01 needs separate PR uncommenting `functions/src/stripeSubscription.ts:47`. Cascade benefit: unblocks #454 / #457 / #462 + resolves audit/50 F-50-01 + makes PR #482 prereq #3 auto-resolved.

### CRITICAL (3) — anon-exploitable or money path

- **F-50-01** — Subscription `priceId` allow-list bypass. 🚧 **PR #481 in flight (CI green, awaiting smoke + merge — see audit/51 addendum)**. Originally tracked under PR #462 / audit/38 env prereq. Effort: blocked on operator smoke matrix per PR #481 body.
- **F-50-02** — ✅ **CLOSED** via SF-050 in PR #517 (`fix/f-50-02-login-attempts-server-side`). CF migration shipped: 3 new callables in `functions/src/loginLockout.ts` (`recordLoginFailure`, `getLoginLockoutStatus`, `clearLoginAttempts`) in eu-west1, IP-rate-limited; firestore.rules `loginAttempts/{email}` locked to `read, write: if false`; `lib/core/services/rate_limit_service.dart` refactored to call CFs (public API preserved). **Deploy ordering: CFs FIRST, then rule + client** — see PR body. **Residual risk:** distributed botnet can still bump victim's counter via many IPs; full closure on App Check rollout below. Pre-merge dev smoke 2026-05-27 (bookbed-dev): 3/3 PASS — see audit/55 design note. The earlier "reorder resetAttempts post-signIn" follow-up was based on an inverted narrative; verified during smoke that both call sites (722 + 954) are already POST-auth, so no follow-up PR needed.
- **F-50-03** — Stripe webhook lacks `event.id` dedup (functions/src/stripePayment.ts:887–901). Money path — duplicate-send risk on Stripe network retries. **Prereq:** scan Stripe Dashboard → Events tab for `id` duplicate pairs in last 7 days to size historical exposure. Fix: `stripe_webhook_events` Firestore dedup table + TTL policy. Effort: M.

### HIGH (2) — quick wins

- **F-50-04** — Error stacks logged to Cloud Logging in 5+ CFs (bookingManagement, verifyBookingAccess, getBookingByStripeSession, stripePayment, updateBookingTokenExpiration). 🚧 **PR #483 in flight (CI green, awaiting Sentry-dashboard smoke + merge)**. Fix: scrub `error.stack` from structured logs in `functions/src/logger.ts`. Keep stack on Sentry only.
- **F-50-05a** — `undici ≤6.23.0` (8 CVEs) reachable via owner-supplied iCal URLs in `icalSync.ts`. Fix: `overrides: { "undici": "^7.0.0" }` in `functions/package.json` + verify SDK compat. Effort: S (~30min).

### MEDIUM (6) — defense-in-depth

- **F-50-05** — App Check: 🚧 **partial via SF-046** (audit-only mode shipped on `getUnitAvailability` + `createStripeCheckoutSession` in security-sprint PR). F-50-02 prereq now MET (closed via PR #517 SF-050). Remaining blockers: `RECAPTCHA_SITE_KEY` provisioning + Flutter/web client App Check init. See "App Check launch checklist" section below — this is now the next critical-path item to close F-50-02 residual DoS risk. Effort remaining: L.
- **F-50-05b** — Owner + admin sites ship no `Content-Security-Policy` header. Fix: prereq remove `web/index.html:669` eval (F-50-10), then add `Content-Security-Policy-Report-Only` first → 1 week clean Sentry → promote to enforcing. Effort: M.
- **F-50-06** — Missing HSTS on all 3 hosting sites (firebase.json).
- **F-50-07** — Missing `Permissions-Policy` on all 3 sites.
- **F-50-08** — Widget site lacks `X-Content-Type-Options` + `Referrer-Policy`.
- **F-50-09** — `devices/{deviceId}` update unbounded (firestore.rules:127). Add `affectedKeys().hasOnly([...])`.

Bundle F-50-06 + F-50-07 + F-50-08 into 1 firebase.json headers PR.

### LOW (4) — defensive tightenings (can bundle into single XS PR)

- **F-50-10** — `web/index.html:669` `eval()` for ES6 feature detection. Replace with try-block.
- **F-50-11** — `web/iframe_resizer.js:13` `postMessage` `targetOrigin: '*'`. Capture parent origin via init handshake.
- **F-50-12** — `audit/raw/secrets.txt` checked into git (grep dump of code paths, not real secrets but leaks layout). Add `audit/raw/` to `.gitignore`, `git rm` the file.
- **F-50-13** — Residual `npm audit` moderate noise (fast-xml-parser via @google-cloud/storage). Monitor; pin via overrides if upstream lags past Q3.

### Done-when

- Each fix lands its own PR with link back to `audit/50` F-50-XX
- New SF-NNN entry added to `docs/SECURITY_FIXES.md` at PR merge time (allocated in arrival order, not pre-allocated — see "Planirane sigurnosne ispravke" section there for rationale)
- Carryover Semgrep follow-up run AFTER F-50-* sprint completes (better signal-to-noise once low-hanging removed)

---

## 🧹 TODO: PR #515 follow-ups (2026-05-27)

**Origin:** PR #515 merge `f871cc86` (Sentry DSN env-var cherry-pick) + smoke run on `bookbed-dev` (Terminal D, 2026-05-27 06:44Z).

Two follow-up candidates surfaced during deploy + verify. Both small, both deferrable but worth filing while context is fresh.

### SF-052 — Sentry lazy init (LOW)

- **What:** Move `sentryDsn.value()` read from `initSentry()` (module-load path) into `withSentry()` wrapper (handler-invocation path). Guard with `if (!isInitialized)` first-call check.
- **Why:** PR #515 introduced `defineString("SENTRY_DSN", {default: ""})` at `functions/src/sentry.ts:13`; `.value()` resolves during deploy *analysis* phase → false-positive `"Sentry DSN not provided, skipping initialization"` INFO log + firebase-functions WARNING on every redeploy. Runtime unaffected (verified). See SF-052 in `docs/SECURITY_FIXES.md`.
- **Effort:** XS (~30min). Single file, no behavior change at runtime.
- **Chain:** Standalone or bundle with next `functions/src/sentry.ts` touch (PR #483 fix-cycle was last toucher).

### SF-053 — CF orphan sweep + CI guard (MEDIUM)

- **What:** (a) Pre-PROD-deploy: sweep `rab-booking-248fc` for orphan CFs using the recipe in SF-053. (b) Long-term: add `tool/check-cf-orphans.sh` invoked from CI pre-deploy.
- **Why:** PR #515 deploy to `bookbed-dev` aborted on 3 orphans (`clearLoginAttempts` / `getLoginLockoutStatus` / `recordLoginFailure`) left behind by PR #512 source-removal — survived 5 days post-merge. `CI=true firebase deploy` is non-interactive → fails on every removed-CF transition. Real attack surface: anon-callable `recordLoginFailure` lived 5 days past F-50-02 rewrite. See SF-053 in `docs/SECURITY_FIXES.md`.
- **Effort:** Sweep S (~15min per env). CI guard S/M (~2h with workflow integration).
- **Chain:** Pairs with `pre-smoke-sanity.sh` (SF-049) + secret-name-sanity (SF-051) as the three legs of deploy-hygiene automation.

### Done-when

- SF-052 lands a PR moving `.value()` into `withSentry()`; next deploy shows 0 `params.SENTRY_DSN.value() invoked during function deployment` warnings.
- SF-053 (a) pre-PROD sweep run on `rab-booking-248fc` BEFORE next PROD CF deploy (likely SF-049/SF-051 PROD ops). (b) CI guard PR optional/deferrable.

---

## 🛡 App Check launch checklist (referenced from SF-046 + SF-061 deferred)

Security-sprint PR shipped App Check in **audit-only mode** (`enforceAppCheck: false, consumeAppCheckToken: true`) on `getUnitAvailability` and `createStripeCheckoutSession`. Functions log attestation when clients send a token; missing tokens are NOT rejected. Promoting to full enforcement (`enforceAppCheck: true`) requires:

- [ ] **Provision `RECAPTCHA_SITE_KEY`** on `bookbed-dev` + `rab-booking-248fc` (reCAPTCHA v3 site key for web; Console: APIs & Services → Credentials → reCAPTCHA Enterprise)
- [ ] **Web client init** in `web/index.html` + Flutter widget entry — initialize App Check with reCAPTCHA v3 provider after `Firebase.initializeApp`
- [ ] **Native client init** — Flutter mobile entry points init App Check with DeviceCheck (iOS) / Play Integrity (Android) providers; pubspec dep `firebase_app_check ^0.4.x` already present
- [ ] **Telemetry watch (1 week)** — confirm legit-traffic attestation rate > 99% in `serviceConfig.appCheckMetrics` before flipping enforcement
- [ ] **Flip `enforceAppCheck: true`** on both CFs in follow-up PR; expand to other anon-callable surfaces (`emailVerification`, `passwordReset`, `subdomainService` once SF-047 lands)

**Why blocked (audit/84 STEP 4, 2026-05-29):** automated sweep tried to flip
`enforceAppCheck: true` gated on Cloud Monitoring verified-rate ≥0.95 over
7d. `grep -rn 'FirebaseAppCheck.instance.activate\|FirebaseAppCheck' lib/`
returned ZERO hits — pub dep loaded but never activated. Verified rate
guaranteed 0%, gate correctly deferred. Re-attempt STEP 4 after the 5
unchecked boxes above are done.

---

## 🚨 TODO: audit/84 sweep follow-ups (2026-05-29)

Mostly informational — the sweep itself landed PR #557/#558/#559 closing
audit/79 §3 #2/#3/#5/#6 plus partial #4. Remaining work:

- [ ] **Broader `cors:` allowlist sweep on framework-default callables** —
      SF-060 only covered the 10 explicit `cors: true` occurrences. Other
      onCalls relying on Firebase v2 default `cors` are still reflective.
      Estimated ~25 callables. Wrap into `getCorsAllowlist()` per the
      helper already in `functions/src/utils/corsAllowlist.ts`.
- [ ] **`tool/deploy-cors-shape-iam-restore.sh`** — codify the
      `gcloud run services add-iam-policy-binding` re-grant loop into a
      script invoked automatically after any deploy that touches `cors`
      options on `onCall` CFs. Memory `[[cf-deploy-cors-shape-iam-strip]]`
      captures the manual recipe.
- [ ] **Worktree `.env` propagation** — fresh `git worktree add` doesn't
      copy gitignored `functions/.env*`, blocking CF deploy from
      worktrees. Add a post-worktree hook OR a `tool/wt-bootstrap.sh`
      that copies them. Hit twice during audit/84 sweep.

---

## 🧩 TODO: Booking widget refactor — Phases 2-5 (2026-05-22)

**Prioritet:** P2 (tech debt; no user-visible change)
**Izvor:** `audit/12-booking-widget-refactor-plan.md` + execution of Phase 0+1 on branch `refactor/booking-widget-phase1` (CHANGELOG 6.78)
**Status:** Phase 0+1 executed; Phases 2-5 deferred.

### Pre-merge of Phase 0+1 PR

- [ ] **Manual smoke matrix (mandatory per execution plan §Verification)** — cannot run from automated session:
  - Web (Chrome): fresh load, Stripe return with `?session_id=`, legacy `?bookingId=`, iframe parent, form persistence, reset flow, zoom controls, rotate overlay
  - iOS dev (per `.claude/rules/ios-development.md`): fresh load, Stripe return, iframe parent, form persistence
- [ ] **Regression checks**: no double-rebuild from `notifyListeners`, no `ChangeNotifier` retention across navigation, `localStorage` form-persistence schema byte-identical pre/post
- [ ] **`PoweredByBadge` URL audit (Q7 from audit/12 §8)**: literal `https://bookbed.io` preserved verbatim — decide if it should route through `EnvironmentConfig.marketingHost` per `.claude/rules/widget.md` § "Hardcoded `bookbed.io` exceptions" (currently NOT in the exception list)

### Phase 2 — leaf composers (~8 h, LOW/MEDIUM risk)

Source: `audit/12-booking-widget-refactor-plan.md` §4 + §6.
- [ ] `presentation/widgets/booking_widget_error_screen.dart` — extract inline 38-LOC error Scaffold from `build()`
- [ ] `presentation/widgets/booking_widget_overlays.dart` — extract `RotateDeviceOverlay` + backdrop + zoom button positioning (Stack children helper)
- [ ] `presentation/widgets/price_change_confirmation_dialog.dart` — extract inline AlertDialog from `_handleConfirmBooking` (returns `Future<bool?>`)
- [ ] `presentation/widgets/payment_delayed_dialog.dart` — extract `_showPaymentDelayedDialog` + `_buildInstructionItem`
- [ ] `state/booking_validation_orchestrator.dart` — extract `_validateUnitAndProperty` + `_retryValidation` + `_setDefaultPaymentMethod` (~230 LOC; async return-struct, no widget-state coupling)

### Phase 3 — form / payment composers (~12 h, MEDIUM risk)

- [ ] `presentation/widgets/guest_info_form_section.dart` — composer; reads/writes `BookingFormState` (now `ChangeNotifier`); takes `onConfirmPressed`/`onVerifyEmailPressed` callbacks
- [ ] `presentation/widgets/payment_method_section.dart` — composer; takes `onPaymentMethodChanged`/`onConfirmPressed`
- [ ] `presentation/widgets/floating_pill_bar.dart` — replaces `_buildFloatingDraggablePillBar` (358 LOC); 4 builder closures bound to extracted composers
- [ ] `presentation/widgets/booking_widget_calendar_section.dart` — Listener + InteractiveViewer + LazyCalendarContainer (uses `ZoomControlState` from Phase 1)
- **Smoke**: full booking flow on web + iOS dev for all 3 modes (`bookingInstant`, `bookingPending`, `calendarOnly`) and all 3 payment methods

### Phase 4 — submit-pipeline domain services (~14 h, MEDIUM risk)

- [ ] `domain/services/pre_submit_price_revalidator.dart` — fresh price recomputation + anomaly detection (NaN, >€10k); returns `PriceRevalidationResult`
- [ ] `domain/services/booking_submit_orchestrator.dart` — builds `SubmitBookingParams`, dispatches `BookingSubmissionStripe`/`BookingSubmissionCreated`, surfaces typed result
- [ ] `domain/services/stripe_return_handler.dart` — webhook poll loop (15× 2s for session) + legacy fetch-by-id 20s pending poll
- [ ] Reduce `_handleConfirmBooking` (495 LOC) to a thin sequencer
- **Smoke**: race-condition path (`BookingConflictException`), fresh-price mismatch dialog ≥€0.50 delta, Stripe return via session id + legacy bookingId

### Phase 5 — payment messaging + Stripe launcher (~18 h, BLOCKING risk — long pole)

- [ ] `domain/services/stripe_payment_launcher.dart` — popup pre-open, 4 popup-result branches (popup/redirect/blocked/unexpected)
- [ ] `state/booking_payment_messaging_controller.dart` — consolidates BroadcastChannel + iframe postMessage + PaymentBridge JS interop behind a single `Stream<PaymentEvent>`
- [ ] Reduce screen to pure orchestrator (≤300 LOC target)
- **Smoke**: cross-browser matrix (Chrome desktop, Chrome iOS, Safari iOS, Safari macOS, iframe + standalone for each), 30s timeout edge cases, popup-blocked path, mobile redirect path, PaymentBridge fallback path
- **Audit/12 §8 Q3 reconfirmation needed**: which of 3 messaging surfaces are redundant on which browser/iframe combinations — risk of regressing Safari iOS or popup-blocked without browser-matrix evidence

### Done-when (whole refactor)

- Screen `booking_widget_screen.dart` ≤300 LOC orchestrator
- No `setState` for form-state mutations in screen (composers `ListenableBuilder` on `BookingFormState`)
- All 4 Phase-4 domain services unit-tested
- Browser-matrix screenshot evidence checked into `audit/screenshots/` for Phase 5 messaging consolidation

---

## 🚨 TODO: audit/35 auth-flows outstanding items (2026-05-24)

**Prioritet:** mixed (MED + LOW + hygiene)
**Izvor:** `audit/35-auth-flows-smoke-2026-05-24.md` (PR #466 branch `doc/audit-35-auth-smoke`); status board in `audit/35-followups.md`.

PR #470 (commit `bad97caa`) closed **F-Auth-D1** (sanitizer digit-strip) and **F-Auth-D2** (CHANGELOG 6.44 cooldown drift). Remaining items:

- **F-Auth-D3 (MED)** — attach `X-RateLimit-Remaining` + `Retry-After` to `checkRegistrationRateLimit` (eu-west1) + `sendPasswordResetEmail` (us-central1). Effort: S.
- **F-Auth-D5 (LOW)** — consolidate `FirebaseAuth.authStateChanges()` listeners across Riverpod providers; `accounts:lookup` polling rate suspect. Effort: M.
- **§3.5 (LOW)** — admin-SDK script to dump `security_events` subcollection (client-blind during smoke). Effort: XS.
- **§5.2 (LOW, DEFERRED)** — capture Gmail `Authentication-Results:` header for `bookings@bookbed.io` + `noreply@firebaseapp.com`; closes audit/28 §5.3. Requires real `@gmail.com` recipient. Effort: XS.
- **§6 (P2 hygiene)** — operator delete 2 PROD test UIDs from Firebase Console (project `rab-booking-248fc`). Effort: XS.

See `audit/35-followups.md` for full action recipes per item.

---

## 🚨 TODO: Wave 3 deferred UI fixes (2026-05-22)

**Prioritet:** P2 (mobile UX papercuts; no regression introduced)
**Izvor:** `audit/19-wave3-cleanup.md` § Deferred + originally referenced (missing) `audit/07-chrome-smoke-test.md`

The 2026-05-22 Wave 3 responsive-cleanup session shipped 2 of 4 fixes (price row Flexible + admin footer year — CHANGELOG 6.75). 3 items deferred because the source audit doc `audit/07-chrome-smoke-test.md` is missing from the repo, so the bug descriptions + screenshots can't be cross-checked.

### Blocking prerequisite

**0. Recover or rebuild `audit/07-chrome-smoke-test.md`.** The follow-up `audit/08-null-tostring-fix.md` references it at lines 5, 23, 778 but the source itself is absent. Without primary screenshots/stack traces, the 3 items below are guesswork. Rebuild via a fresh Chrome smoke test on `bookbed-dev` widget + owner + admin, captured at 320/375/768/1440px breakpoints.

### Items

**1. Login CanvasKit text-input sync gap.** `lib/features/auth/presentation/screens/enhanced_login_screen.dart` + `lib/features/auth/presentation/widgets/premium_input_field.dart`. Claimed defect: text typed into email/password fields doesn't sync to `TextEditingController`, so `_handleLogin` reads empty fields. Known workaround in `memory/flutter-web-input-bypass.md`: bypass via direct `firebase_auth.signInWithEmailAndPassword` call. Code audit shows no obvious defect — controllers exist, listeners attached, `_handleLogin` snapshots into locals before async, `PremiumInputField` has `autocorrect:false`/`enableSuggestions:false`/`textCapitalization:none`. **Need browser console capture + screen recording** to triage.

**2. Owner mobile heading truncation.** Claimed: section headers on `/owner/overview` render as "Nedav…", "Rezer…", "Fi…" on iPhone X (375px) instead of "Nedavne", "Rezervacije", "Finansije". Code audit located no truncating widget — `RecentActivityWidget` already uses `AutoSizeText`/`minFontSize:14`, `_buildChartHeader` uses `Expanded`. Possible candidate: `CommonAppBar` title (not yet inspected) or the drawer items at narrow open widths. **Need screenshot at 375px Croatian locale (`?lang=hr`)** to pinpoint the offending widget.

**3. Admin "Em…" placeholder.** Claimed: a placeholder reads "Em…" instead of its full string. Low-confidence candidates: `admin_login_screen.dart:263-264` (`labelText:'Email Address'`, `hintText:'admin@bookbed.io'`) or `users_list_screen.dart:190` (`hintText:'Search users by name or email...'`) — the latter is the more plausible match if rendered in a narrow filter chip. **Need screenshot of the offending screen** to identify whether this is a `TextField.hint` (widen constraint), a `Text` ellipsis (drop `maxLines:1`), or a chip label (shorten copy).

### Done-when

- `audit/07-chrome-smoke-test.md` (or equivalent successor) committed with screenshots at 320/375/768/1440px.
- Each item above has either (a) a verified code fix landed via PR + closed against the rebuilt audit doc, or (b) a one-line "cannot reproduce" note attached to the audit item if the bug no longer surfaces on the current `main`.
- Follow-up bullets from `audit/19-wave3-cleanup.md` § "Out-of-scope follow-ups" actioned: `golden_test` for `PriceRowWidget` at 280/320/400px, plus a `grep -rn "mainAxisAlignment: MainAxisAlignment.spaceBetween" lib/features/widget/` sweep for sibling Row patterns missing `Flexible`.

---

## ✅ DONE: Cleanup-session execution (resolved 2026-05-23)

**Prioritet:** P2 hygiene → resolved
**Izvor:** `audit/18-stash-classification-2026-05-22.md` + `audit/18-dependabot-triage-2026-05-22.md`

### Stash drops — 29/32 resolved

- **Dropped 29** (Class A race debris merged + Class B Wave 0 debris + Class E ancient obsolete) via descending-index drop.
- **Kept 3**: T11c sibling debris (`1eb3b205`), jules-audit (`4151b352`, owner review), diagonal-gradients mvp (`d0e71b62`, in-flight design work).
- See `audit/18-stash-classification-2026-05-22.md` Addendum 2026-05-23.

### Dependabot triage — 16/27 resolved

- **Merged 11 transitives**: PRs #309, #314, #316, #319, #327, #328, #369, #412, #414, #415, #416. Each batch validated locally (`flutter analyze`=0, `npm run build`=0).
- **Closed 1 superseded**: #281 minimatch 3.1.5 (covered by #416 at 9.0.9). Remote branch deleted.
- **Rejected 4 MAJOR** (yesterday): #270 stripe, #271 eslint, #240 flutter_secure_storage closed; #242 package_info_plus postponed.
- **Remaining 11** in INVESTIGATE pile: sentry_flutter, @sentry/node, node-ical, firebase group, multi-group bumps, github_actions majors, flutter_launcher_icons, protobufjs minor. Revisit in dedicated migration windows. See `audit/18-dependabot-triage-2026-05-22.md` Addendum 2026-05-23.

### Branch + history hygiene

- **Deleted 12 merged branches**: `fix/sf-026-booking-count-dst`, `docs/wave3-cleanup-fix-and-deferred`, `chore/cleanup-stash-dependabot-test-debt-2026-05-22`, `fix/icalpii-family-rules-and-cf`, `fix/auth-race-and-indexes-cleanup`, `chore/ci-enable-android-build`, `fix/ios-firebase-env-hardening`, `fix/sentry-dart-env-and-seed`, `fix/sentry-env-detection`, `chore/merge-trial-v2-winner`, `chore/kill-comeback-reminder`, `chore/kill-booking-airbnb-integration`.
- **Preserved**: `refactor/booking-widget-phase1` (active sibling), `hotfix/widget-secrets-exfil` (unmerged). Local non-main branch count: 14 → 2.
- Duplicate cherry-pick squash (`cf1546a0` ↔ `70c91f8e`): left as cosmetic noise (idempotent).

### Side-effect — CI on main still red

`Run Tests` / `Test Cloud Functions` / `Validate Firestore Rules` jobs failing on every commit since `ac225b3d` (2026-05-22 16:49Z). Pre-existing env/billing wall — **not caused** by any cleanup-session merge (all PRs were SUCCESS on those jobs at PR time). Tracked separately; user ack'd "Continue — env CI issue" during session.

---

## 🚨 TODO: Cloud Functions audit follow-ups (2026-05-21)

**Prioritet:** Mixed (P0 prod bugs, P1 cleanup, P2 hygiene, P3 long-term)
**Izvor:** `audit/11-cloudfunctions-inventory.md`

### P0 — production-affecting bugs

1. **Deploy `getBookingByStripeSession` to prod** (`rab-booking-248fc`). Source on `main` + dev; widget booking-confirmation Flutter path calls it on prod and currently 404s. _(Same item as Wave 0 cutover §1 below — kept in both places intentionally.)_
2. **Deploy `sendOwnerEmail` to prod**. Recent hotfix on `hotfix/widget-secrets-exfil` (commit `49af1625`) is dev-only; production owners do not currently receive widget inquiry emails.
3. ~~**Fix dead Flutter callsite `sendSuspiciousActivityAlert`** (`lib/core/services/security_events_service.dart:356`). Backend `securityEmail.ts` deleted in commit `4cb5a391`; every suspicious-login attempt logs an unhandled cloud-functions error. Either restore the backend or remove the caller.~~ **DONE 2026-05-22** — caller removed (decision: don't restore the backend, the `security_events` Firestore log is sufficient for the audit trail). `_sendSuspiciousActivityEmail` method + `cloud_functions` import deleted from `security_events_service.dart`. Suspicious-login detection still writes to the `security_events` collection unchanged. `flutter analyze` clean for this file.

### P1 — source-state cleanup

4. **Undeploy Airbnb / Booking.com OAuth orphans from `bookbed-dev`.** **Partially done.** Source + Flutter callers killed 2026-05-18 (`c3465034 feat(kill)`); PROD CFs deleted 2026-05-21 (CHANGELOG 6.71). **Gap discovered 2026-05-22 (audit/16 session):** CHANGELOG 6.71 claimed "Dev had already pruned these" but `firebase functions:list --project bookbed-dev` still shows 4 orphan CFs live:
   - `initiateAirbnbOAuth` (us-central1, callable)
   - `handleAirbnbOAuthCallback` (us-central1, https)
   - `initiateBookingComOAuth` (us-central1, callable)
   - `handleBookingComOAuthCallback` (us-central1, https)

   No Flutter caller, no source. Smoke probe confirms they respond OK_bad_request (`invalid-argument`) to empty calls — i.e. they're alive but useless. Cleanup commands:
   ```bash
   for fn in initiateAirbnbOAuth handleAirbnbOAuthCallback initiateBookingComOAuth handleBookingComOAuthCallback; do
     firebase functions:delete "$fn" --project bookbed-dev --force --region us-central1
   done
   ```
   Cross-reference `audit/06-platform-connections-check.md`, `audit/11-cloudfunctions-inventory.md` §3.3, CHANGELOG 6.71. Run when ready; closes TODO P1.4.

### P2 — hygiene

5. **Track Firebase Extensions in `firebase.json`.** Run `firebase ext:export --project rab-booking-248fc` so `delete-user-data` + `storage-resize-images` are version-controlled.
6. **Add `functions/.env.bookbed-dev`** with dev-specific `WIDGET_URL`, `BOOKING_DOMAIN`, `FROM_EMAIL`, `FROM_NAME`. Per `.claude/rules/hosting-build.md` this is required to stop dev from sending emails with prod URLs.

### P3 — long-term

7. **Region consolidation roadmap.** Move Stripe + booking hot-path functions from `us-central1` → `europe-west1`. Needs dual-deploy phase + Stripe webhook URL update in Dashboard. ~+120ms latency win per call for EU/HR users.

---

## 🚨 TODO: Wave 0 prod cutover

**Prioritet:** HIGH (Wave 0 is dev-only until this lands)
**Izvor:** `audit/09-wave0-promote-report.md`

Wave 0 branches landed on `main` 2026-05-18 (`pre-wave0-promote` `eadec3cc` → `post-wave0-stable` `a480e5f3`). Production (`rab-booking-248fc`) is untouched — these changes only affect `bookbed-dev` (`createStripeCheckoutSession` deployed) and local dev workflow.

### Required for prod cutover

1. Deploy `getBookingByStripeSession` Cloud Function to `rab-booking-248fc` (currently only on `bookbed-dev`).
2. Build + deploy widget bundle to prod hosting (`view.bookbed.io` widget target).
3. Deploy widget overlay JS to `view.bookbed.io` (`web/bookbed-overlay.js` → `build/web_widget/`).
4. Deploy `firestore.rules` to prod **last** — so the live widget never makes a now-blocked direct read during the cutover window.
5. Deploy `createStripeCheckoutSession` to prod (the env-aware allowlist is harmless on prod — `getAllowedReturnDomains()` only appends extras when `GCP_PROJECT == 'bookbed-dev'`/`'bookbed-staging'`).
6. Run the manual smoke checklist from `audit/06-bookings-hotfix-partial.md` §6.3 against the prod widget origin.

### Wave 1 prerequisites (run BEFORE this prod cutover)

- Stash triage (9 stashes — full table in `audit/09-wave0-promote-report.md` §Outstanding).
- Branch archive-and-delete (12 branches awaiting Wave 1).
- T8 silent-catch coverage verification — confirm T10 captured all 18 sites originally in `stash@{8}` "T8-silent-catches-WIP-rescued-by-T10" before dropping that stash.

---

## ✅ DONE: Widget `null.toString()` hardening (2026-05-18)

**Branch**: `fix/null-tostring-hardening` — **merged to `main`** via `6f187d1a`.
**Audit**: `audit/08-null-tostring-fix.md`

Closed the Wave 0 smoke-test finding about `Uncaught TypeError: Cannot read properties of null (reading 'toString')` on the widget `/view` path. Root cause: `Uri.queryParameters` passes each value through `.toString()` during encoding, and dart2js compiles that into literal `null.toString()` when the value is nullable. Fixed 2 sites in `booking_view_screen.dart` with `?? ''` coercion. Full test suite green.

## 🟡 TODO: Login submit crash on Flutter web (separate bug class)

**Source**: `audit/07-chrome-smoke-test.md` line 524.

The same JS-error-type appears on the login form submit, but the underlying cause is **CanvasKit text-input sync** — `_passwordController.text` reads empty even when the DOM `<input>` is populated. Form validator fails before any auth call fires. This is NOT the same Dart `null.toString()` bug, and the hardening branch does NOT address it. Needs:

1. Repro on `bookbed-dev` with DevTools open, capture the actual stack trace (audit speculation was that it shares the null.toString class — proven wrong by the widget-side fix not affecting login).
2. Investigate `keyboard_dismiss_fix_web.dart` interaction with autofill events.
3. Workaround in production: direct JS `firebase_auth.signInWithEmailAndPassword` call (smoke test used this).

## 🟡 TODO: Guest counter (adults / children / pets) doesn't persist to form cache (2026-05-23)

**Prioritet:** P3 (UX papercut — counters reset to defaults on refresh while name/email/phone restore correctly)
**Izvor:** PR #447 smoke verification (CHANGELOG 6.81), `booking_widget_screen.dart:2765-2782`
**Status:** Pre-existing on `main` — `git diff main..HEAD` over the region is empty as of 2026-05-23. NOT introduced by PR #447's Phase 0+1 refactor.

**Defect:** The `onAdultsChanged` / `onChildrenChanged` / `onPetsChanged` callbacks passed to `GuestCountPicker` only call `setState(() => _adults = value)` etc. They never trigger `_saveFormData()` — unlike the text controllers, which register `_saveFormDataDebounced` listeners (lines 262-266). As a result:

- The user picks Adults=3 in the form.
- They refresh the page (or navigate away + back).
- `FormPersistenceService.loadFormData` restores name/email/phone/dates/notes correctly.
- Adults silently resets to whatever was last saved (most commonly the default `1`), because no save fired when the counter incremented.

Verified during PR #447 smoke flow: pre-reload localStorage `adults: 1`, post-reload `adults: 1`, while the in-memory `_adults` was `2` just before reload.

### Fix (one-line per handler)

```dart
onAdultsChanged: (value) {
  if (mounted) {
    setState(() => _adults = value);
    _saveFormDataDebounced();  // add
  }
},
// same for onChildrenChanged + onPetsChanged
```

Use `_saveFormDataDebounced` (the existing 500 ms debouncer at line 1299) rather than `_saveFormData()` directly — counters typically click rapidly during selection, no need for one disk write per tap.

### Done-when

- All 3 handlers call the debounced save.
- Manual smoke: pick Adults=3 → refresh → form reopens with Adults=3.
- New unit test for `BookingFormState.adults` setter triggers a `notifyListeners` (already true post-PR #447 ChangeNotifier promotion) — but the screen-level handler is what currently swallows the save, so the test target is the handler wiring, not the model.

## ✅ DONE: T11c — Drop `unit_id+status` clause from bookings rule

**Prioritet:** HIGH (was largest remaining public-read surface on `bookings`)
**Status:** ✅ **CLOSED 2026-05-22** via PR #446 (branch `fix/t11c-proper-bookings-migration`, merge commit `3b810b2d`). ✅ Dev cutover complete 2026-05-22 (rules + CF + widget bundle + `daily_prices` COLLECTION composite index `available + date`, commit `a1fe3633`). Final smoke green: anon CG bookings → 403, `getUnitAvailability` → 200 with `windows[]`. Prod cutover pending.
**Izvor:** `audit/03-backend.md` §3.4 flag #1, `audit/06-bookings-hotfix-partial.md`, `audit/06-availability-cf-design.md`, `audit/17-sf023-sf025-rules-fix.md`

### Outcome

Last anonymous read surface on the `bookings` collection-group is closed. Widget calendar + booking-submit gate now route through the `getUnitAvailability` Cloud Function. `firestore.rules` clause 1 (`unit_id`+`status` public read) removed from all 3 surfaces (subcollection, CG, deprecated top-level).

### Sequence — final state

1. ✅ **`getUnitAvailability` CF** (SF-023, 2026-05-22, merge `d481bf11`). `functions/src/availability.ts`, region `europe-west1`. Returns `AvailabilityWindow[]` with `source` discriminator covering bookings + manual blocks + ical.
2. ✅ **Widget bookings snapshot stream migrated.** `firebase_booking_calendar_repository.dart` — 4 sites collapsed into single `_streamBlockedEvents` that demultiplexes CF windows by source. `availability_checker._checkBookings` replaced with `_fetchAvailabilityWindows` + per-source overlap helpers. Bookings + iCal now share one CF round-trip.
3. ⏳ **Cut-over to prod** — pending. Sequence:
   - Deploy `getUnitAvailability` CF to `rab-booking-248fc` (region `europe-west1`).
   - Deploy `daily_prices` COLLECTION composite index (`available + date`) via `firebase deploy --only firestore:indexes --project rab-booking-248fc`. Wait `READY` **+ ~30 s propagation buffer** before the rules deploy (Firestore needs the gap after `READY` before queries actually use a new composite — first CF call still 500s "index currently building" without it; observed in dev cutover).
   - Build + deploy the widget bundle to prod hosting.
   - Deploy `firestore.rules` to prod **last** (so the live widget never makes a now-blocked direct read).
   - Run smoke verify (anon CG `runQuery` on `bookings` with `unit_id`+`status` filter must return 403; `getUnitAvailability` must return 200 with `windows[]`).
4. ✅ **Rules-unit-test guard flipped.** `functions/test/firestore_rules/bookings.test.ts` — 2 "STILL ALLOWS" / "ALLOWED" assertions now `assertFails`. Test suite renamed to `bookings rule (T11c closed)`. 24/24 pass.

### Trade-offs accepted

- **Realtime → 30s polling** for widget bookings. Same cadence already used for iCal blocks after SF-023. Acceptable for an anonymous booking-flow surface.
- **Pending/confirmed visual distinction lost** in widget calendar. CF strips `status` for privacy; synthesized `BookingModel.status = confirmed`. Privacy win for anonymous viewers.

### Production deploy of T11-hotfix-partial + SF-023 + T11c

Currently all three are dev-only. Combined prod cutover checklist:

- Deploy `getBookingByStripeSession` CF to `rab-booking-248fc`.
- Deploy `getUnitAvailability` CF to `rab-booking-248fc` (region `europe-west1`).
- Deploy `daily_prices` COLLECTION composite (`available + date`) to prod via `firebase deploy --only firestore:indexes --project rab-booking-248fc`. Wait `READY` **+ ~30 s propagation buffer** before the rules deploy.
- Build + deploy the widget bundle to prod hosting (must include both the SF-023 ical-stream migration AND the T11c bookings-stream migration).
- Deploy `firestore.rules` + `storage.rules` to prod **last**.
- Run the manual smoke checklists in `audit/06-bookings-hotfix-partial.md` §6.3 + `audit/17-sf023-sf025-rules-fix.md` § Smoke verify on the prod widget origin.

### Cross-link

`docs/SECURITY_FIXES.md` SF-019 → "T11c CLOSED 2026-05-22" subsection. `CLAUDE.md` NIKADA NE MIJENJAJ row for bookings clause 1 flipped to ✅ CLOSED.

---

## ✅ DONE: SF-026 — booking night/guest count Timestamp normalization (2026-05-22)

**Branch:** `fix/sf-026-booking-count-dst`
**Commits on `main`:** `5f747740` (core), `0a6a6570` (merge), `dc554396` (migration index fix), `ff39fa8d` (smoke script).
**Audit:** `audit/18-booking-count-audit.md` → `docs/SECURITY_FIXES.md` SF-026 entry.
**Deploy:** `bookbed-dev` deployed 2026-05-22. Prod cutover pending operator.

### What landed (Option B)

- **STEP 6 normalization** (`functions/src/utils/dateValidation.ts`): new `normalizeToZagrebCivilDayUTC()` helper extracts civil day via `Intl.DateTimeFormat('en-CA', {timeZone: 'Europe/Zagreb'})` then stores Timestamps at UTC midnight of that civil day. Preserves display (a Zagreb client picking June 1 still sees "June 1" everywhere) while making `.difference().inDays` (Dart floor) and `Math.ceil(/86_400_000)` (TS ceil) return the same integer N. Naive `getUTCDate()` extraction would have shifted Zagreb-originated bookings backwards 1 day — caught by advisor mid-implementation.
- **Standardized derivation**: TS `verifyBookingAccess` + `getBookingByStripeSession` now call canonical `calculateBookingNights()`; Dart email service uses `booking.numberOfNights`; widget + form-state use `DateNormalizer.nightsBetween()`.
- **Backfill script** (`functions/scripts/normalize-booking-nights.js`): dry-run default, `--force` opt-in. Scans `collectionGroup('bookings')` filtered client-side (no Firestore index dep) for `confirmed | pending_payment | awaiting_owner_decision`, rewrites Timestamps where they differ from normalized.
- **Smoke script** (`functions/scripts/smoke-sf026-dev.js`): read-only sanity check — observed expected drift on bookbed-dev's seed booking (status=cancelled, out of migration scope, floor=2 vs ceil=3).
- **Tests** (`functions/test/dateValidation.test.ts`, 13/13 green): DST spring-forward (Zagreb 2026-03-29) → 4 nights; DST fall-back (2026-10-25) → 2 nights; long booking across both transitions → 240 nights; idempotency; validation guards.

### Outstanding (operator)

1. `firebase deploy --only functions --project bookbed-prod` — same Cloud Function update on prod.
2. `GOOGLE_CLOUD_PROJECT=bookbed-prod node functions/scripts/normalize-booking-nights.js` — prod dry-run to count drift.
3. After review, `--force` migration on prod.
4. (Optional) `--force` migration on dev — only 1 cancelled booking on dev today, status not eligible, so nothing to do.

### Open behavior change (filed, not fixed)

Same-Zagreb-civil-day check-in + check-out (different clock times within one day) now throws "< 1 night" in `calculateBookingNights()` whereas pre-fix it returned 1 via `Math.ceil(0.x)`. Widget picker constrains to whole dates so unreachable today; admin/script paths could trip it later. Out of scope for this PR.

### Promote to Option A only if

- Audit needs an immutable "billed for N nights" field — store `nights: number` on the booking doc and migrate read sites.
- Partial-day stays (early check-in / late check-out) become a pricing feature — Timestamp time-component becomes meaningful again, normalization no longer safe.

---

## 🚨 TODO: Tech Debt Audit Findings (2026-05-18)

**Prioritet:** Mixed (C1 critical, rest medium)
**Izvor:** `audit/04-techdebt.md`, `audit/04b-flutter-analyze-summary.md`, `audit/04c-hardcoded-urls.md`

### Critical
- ✅ **C1 — DONE** (Wave 1, commit `c3465034` 2026-05-18): `bookingComApi.ts` deleted entirely as part of KILL Booking.com/Airbnb integration. MD5 IV concern moot.
- **C3 — 2 silent catches in confirmation screen** (`lib/features/widget/presentation/screens/booking_confirmation_screen.dart:171,192`). Wrap `tabService.dispose()` failures with `LoggingService.logWarning` (debug-mode only, no Sentry noise). Attempted in branch `fix/widget-silent-catches` (commit `6f7419147`) but file reverted locally — re-apply.

### High / Medium
- **H2 — Stripe Price IDs hardcoded** (`functions/src/stripeSubscription.ts:44`). Replace with env-sourced IDs.
- ✅ **M1 — DONE** (Wave 1, commit `c3465034` 2026-05-18): Booking.com (`bookingComApi.ts`, 514 lines) and Airbnb (`airbnbApi.ts`, 451 lines) integration files removed; OAuth dead code purged.
- ✅ **M2 — DONE** (Wave 1, commits `6a7bdc13` / `fab63189` 2026-05-18): Trial expiry email templates migrated to V2 (`generateEmailHtml` + `template-helpers`). See `audit/06-trial-v2-content-diff.md`.
- ✅ **M4 — DONE** (T12 merge `2fdec297`): `ical_export_list_screen.dart:212` now uses `EnvironmentConfig.firebaseProjectId`.
- **M5 — Cancellation policy logic stub** (`functions/src/guestCancelBooking.ts:250`).
- **M6 — 7 production `print()` calls** in widget config/helpers (`tax_legal_config.dart`, `booking_price_calculator.dart`, `ical_export_config.dart`, `embed_url_params.dart`, `email_verification_service.dart`, `availability_checker.dart`). Route through `LoggingService`.
- ✅ **M7 — DONE** (T13 merge `e162d5d1`): 6 callsites refactored via `EnvironmentConfig.widgetHost` / `dashboardHost` / `marketingHost` / `isMarketingHost()`. See CHANGELOG 6.69 for details.

### Code-health
- ✅ **DONE** (T13 merge `e162d5d1`): Brittle `host.startsWith('view.')` replaced with `host == EnvironmentConfig.widgetHost` in both `subdomain_service.dart:51` and `booking_view_screen.dart:107`. Staging widget host no longer mis-parses as client subdomain.
- ✅ **DONE** (T13 merge `e162d5d1`): Duplicate `_subdomainBaseDomain` consts in `embed_widget_guide_screen.dart` and `embed_code_generator_dialog.dart` removed; both now route via `EnvironmentConfig.widgetHost`.
- 2 discontinued + 133 outdated packages reported by `flutter pub outdated` — separate hygiene pass.

---

## ✅ DONE: V2 Trial Email Migration (Wave 1, 2026-05-18)

**Merged:** `fab63189` ("Merge: trial email V2 templates") via branch `chore/merge-trial-v2-winner` (`6a7bdc13`).
**Winner pick:** `refactor/trial-email-templates-v2-5763908700715533391` (per `audit/06-trial-v2-content-diff.md`).
**Result:** `trial-expired.ts` + `trial-expiring-soon.ts` now use `generateEmailHtml` + `template-helpers` (V2). The other 5 Jules candidate branches are awaiting Wave 1 archive-and-delete.
**Deploy:** Pending — Cloud Functions don't reflect git without `cd functions && npm run deploy` per MEMORY.md #3.

---

## 📝 TODO: Bookbed Website Documentation

**Prioritet:** High
**Rok:** 2-3 dana
**Lokacija:** Bookbed React website (docs sekcija)

### Potrebna dokumentacija:

**Za Owners (Property Managers):**
1. Getting Started - Kreiranje property-ja i unita
2. Pricing Setup - Postavljanje cijena i sezonskih pravila
3. Stripe Connect - Povezivanje Stripe računa
4. Widget Configuration - Embed kod i postavke
5. Managing Bookings - Pregled i upravljanje rezervacijama
6. iCal Sync - Sinkronizacija sa Booking.com/Airbnb
7. Notifications - Email postavke i obavijesti

**Za Guests:**
1. How to Book - Koraci za rezervaciju
2. Payment Options - Stripe, bank transfer, pay on arrival
3. Booking Lookup - Pregled postojeće rezervacije
4. Cancellation - Otkazivanje rezervacije

**API Reference:**
1. Cloud Functions API - createBookingAtomic, verifyBookingAccess, etc.
2. Widget Embed Options - URL parametri, customization
3. Webhook Events - Stripe webhooks, booking events

**Izvor sadržaja:** Ovaj projekt (CLAUDE.md, SECURITY_FIXES.md, kod)

---

## 📝 TODO: Admin Controls Feature

**Prioritet:** Low (nice-to-have)
**Kompleksnost:** ~20-30 minuta
**Izvor:** Ekstrahirano iz branch `sentinel-firestore-audit-15445911159531971809`

### Opis
Admin kontrole za upravljanje korisničkim računima iz Admin panela bez potrebe za direktnim Firestore editiranjem.

### Nova polja u UserModel (`lib/shared/models/user_model.dart`):
```dart
/// Hide subscription page from this user (e.g., for special deals)
final bool hideSubscription;

/// Admin override of account type (bypasses subscription logic)
final AccountType? adminOverrideAccountType;
```

### Potrebne izmjene:

**1. UserModel** (`lib/shared/models/user_model.dart`):
- Dodati `hideSubscription` (bool, default: false)
- Dodati `adminOverrideAccountType` (AccountType?, nullable)
- Ažurirati `fromJson()` i `toJson()`
- Ažurirati `copyWith()`

**2. AdminUsersRepository** (`lib/features/admin/data/repositories/`):
```dart
Future<void> updateAdminFlags({
  required String userId,
  bool? hideSubscription,
  AccountType? adminOverrideAccountType,
  bool clearOverride = false,  // Set to true to remove override
}) async {
  final updates = <String, dynamic>{
    'updated_at': FieldValue.serverTimestamp(),
  };
  if (hideSubscription != null) {
    updates['hide_subscription'] = hideSubscription;
  }
  if (clearOverride) {
    updates['admin_override_account_type'] = FieldValue.delete();
  } else if (adminOverrideAccountType != null) {
    updates['admin_override_account_type'] = adminOverrideAccountType.name;
  }
  await _firestore.collection('users').doc(userId).update(updates);
}
```

**3. UserDetailScreen** (`lib/features/admin/presentation/screens/user_detail_screen.dart`):
- Dodati "Admin Controls" card sa:
  - Switch za `hideSubscription`
  - Dropdown za `adminOverrideAccountType` (None, Free, Premium, Enterprise)
  - Save button

**4. SubscriptionScreen** provjera:
```dart
// U subscription_screen.dart
if (user.hideSubscription) {
  // Redirect away or show "Contact admin" message
}

// Za account type provjeru
AccountType get effectiveAccountType =>
    user.adminOverrideAccountType ?? user.accountType;
```

### Korištenje
- Admin može sakriti subscription stranicu za korisnika koji ima special deal
- Admin može override-ati account type bez potrebe za Stripe subscription

---

## 📝 TODO: Security Branch Fixes (Za Kasnije)

**Prioritet:** Medium
**Branchevi:** Pregledani 2026-02-01, sadrže korisne security fixeve za budući deploy.

### Branch 1: `security-audit-2026-01-29-9611837304482000277`
**Šta radi**: Premješta `loginAttempts` Firestore write sa klijenta na Cloud Functions.
- `firestore.rules`: `loginAttempts` write → `allow write: if false`
- `authRateLimit.ts`: Nove CF `recordFailedLoginAttempt` + `resetLoginAttempts`
- `rate_limit_service.dart`: Poziva CF umjesto direktnog Firestore write-a
- `stripeSubscription.ts`: Generičke error poruke (ne leaka `error.message`)

**⚠️ Zahtijeva koordiniran deploy** (ovim redoslijedom):
1. Deploy Cloud Functions prvo
2. Deploy Flutter app
3. Deploy Firestore rules zadnje

### Branch 2: `security-audit-2025-05-22-13396931281884778762`
**Šta radi**: XSS fix u email template-ima + Stripe error sanitizacija.
- `trial-expired.ts`: `${userName}` → `${escapeHtml(userName)}`
- `trial-expiring-soon.ts`: isto `escapeHtml`
- `stripePayment.ts`: `error.message` → generička poruka
- `stripeSubscription.ts`: `error.message` → generička poruka

**Jednostavan za cherry-pick** - samo 4 fajla, mali fixevi.
