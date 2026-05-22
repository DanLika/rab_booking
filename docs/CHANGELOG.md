# BookBed Changelog

All version history from v4.6 to v6.67.

**Last Updated**: 2026-05-22 | **Version**: 6.80

---

**Changelog 6.80**: SF-026 — booking night count UTC midnight Zagreb-civil-day normalization (2026-05-22):

- **SF-026 landed** (branch `fix/sf-026-booking-count-dst`, commits `5f747740` core + `0a6a6570` merge + `dc554396` migration index fix + `ff39fa8d` smoke script). Closes the audit/18 finding (Option B per recommendation).
- **Server STEP 6 normalization** — `functions/src/utils/dateValidation.ts` now wraps `check_in`/`check_out` Timestamps via new `normalizeToZagrebCivilDayUTC()` helper before persist. Civil day extracted via `Intl.DateTimeFormat('en-CA', {timeZone: 'Europe/Zagreb'})` → UTC midnight of that day. Preserves "day the guest selected" through Zagreb display (naive `getUTCDate()` extraction would have shifted Zagreb-originated bookings backward 1 day — caught by advisor pre-commit).
- **Standardized derivation** — TS `verifyBookingAccess` + `getBookingByStripeSession` migrated off inline `Math.ceil(/86_400_000)` to canonical `calculateBookingNights()`. Dart sites: email service uses `booking.numberOfNights`; widget + form-state use `DateNormalizer.nightsBetween()` (UTC-normalized floor). With normalized inputs, floor and ceil yield same N — no more DST off-by-one.
- **Backfill script** — `functions/scripts/normalize-booking-nights.js`, dry-run default, `--force` opt-in. Scans `collectionGroup('bookings')` filtered client-side (no Firestore index required) for `confirmed | pending_payment | awaiting_owner_decision`, rewrites Timestamps where they differ from normalized.
- **Smoke script** — `functions/scripts/smoke-sf026-dev.js` confirms the bug pattern on bookbed-dev's seed booking: `check_in 2026-06-17T15:00:00Z` / `check_out 2026-06-20T11:00:00Z` → Dart floor=2 vs TS ceil=3 (off-by-one). Status=cancelled, out of migration scope, but proves audit/18 diagnosis on live data.
- **Tests** — `functions/test/dateValidation.test.ts` 13/13 green: Zagreb summer/winter midnight ulaz, DST spring-forward (2026-03-29) → 4 nights, DST fall-back (2026-10-25) → 2 nights, long booking across both transitions → 240 nights, single-night, idempotency, validation guards.
- **Deploy** — `bookbed-dev` deployed (background task `bzx1w2bql` exit 0). Prerequisite: deleted 2 pre-existing orphan CFs blocking non-interactive mode (`comebackReminder(europe-west1)`, `sendOwnerEmail(us-central1)`; both per audit/11 inventory). Prod cutover + `--force` migration pending operator approval.
- **Behavior change (filed, not fixed)** — same-Zagreb-civil-day check-in + check-out (different clock times within one day) now throws "< 1 night" in `calculateBookingNights()` whereas pre-fix it returned 1 via `Math.ceil(0.x)`. Widget picker constrains to whole dates so unreachable today; admin/script paths could trip it later.
- **Verification** — `cd functions && npm run build` 0 errors; `flutter analyze` 0 issues; 13/13 SF-026 tests + 161/165 functions suite (4 pre-existing `stripeConnect` failures unrelated); 1079/1100 flutter tests (21 pre-existing test-debt failures per commit `55981882`, unrelated).
- **Multi-agent race** — 2+ branch swaps during session (`refactor/booking-widget-phase1`, `fix/t11c-proper-bookings-migration`). Recovered via cherry-pick + explicit-staging. Race-debris and another agent's iOS plist swap preserved in stash + working tree.
- **Docs** — `docs/SECURITY_FIXES.md` SF-026 entry added; `docs/TODO.md` SF-026 row flipped to DONE.

---

**Changelog 6.79**: T11c proper CLOSED — bookings clause 1 locked + widget CF migration (2026-05-22):

- **T11c proper landed** (PR #446, branch `fix/t11c-proper-bookings-migration`, commits `ab6bdb3d` + `64b14bf0`). Closes SF-019 → T11c. Last anonymous read surface on the `bookings` collection-group is now closed.
- **Widget migration** — 5 anonymous-context sites migrated from `collectionGroup('bookings').snapshots()` to the `getUnitAvailability` callable:
  - `lib/features/widget/data/repositories/firebase_booking_calendar_repository.dart` — 4 streams (lines 107, 245, 386, 496) collapsed into single `_streamBlockedEvents` that demultiplexes CF windows by `source` (booking + ical_external + manual_block). Bookings synthesized into minimal `BookingModel(status: confirmed)` — privacy-driven loss of pending/confirmed visual distinction in widget calendar (accepted trade-off).
  - `lib/features/widget/data/helpers/availability_checker.dart` — `_checkBookings()` direct CG query replaced with `_fetchAvailabilityWindows()` + per-source overlap helpers. Bookings + iCal now share one CF round-trip.
- **Rules tightening** — clause 1 (`unit_id`+`status` public read) removed from all 3 surfaces (`firestore.rules`): subcollection `properties/{p}/units/{u}/bookings/{id}`, collection-group `{path=**}/bookings/{id}`, and deprecated top-level `/bookings/{id}`.
- **Tests** — 24/24 rules tests pass. 2 "STILL ALLOWS" / "ALLOWED" assertions in `functions/test/firestore_rules/bookings.test.ts` flipped to `assertFails` as clause-1 regression guards. Test suite description renamed from `bookings rule (T11-hotfix-partial)` to `bookings rule (T11c closed)`.
- **UX trade-off** — realtime `.snapshots()` for bookings sacrificed; widget now polls every 30 s via `FirebaseAvailabilityRepository._defaultPollInterval` (same cadence already in place for iCal blocks after SF-023).
- **CLAUDE.md NIKADA NE MIJENJAJ** — bookings clause-1 row flipped from "INTENTIONALLY public until T11c proper lands" to "✅ T11c CLOSED 2026-05-22" with pointer to `ab6bdb3d`. The `firebase_booking_calendar_repository.dart` row stays (file still has no unit tests; T11c only made the touched flows simpler, not safer to broadly refactor).
- **Verification** — `flutter analyze` 0 issues; `cd functions && npm run build` 0 errors; `cd functions && npm run test:rules` 24/24 pass.
- **Multi-agent race** — 4+ branch swaps during session per `memory/multi-agent-git-race.md`. Recovered via chained stash/checkout/pop/commit with abort safety. Both T11c commits (code + docs) intact on the branch.
- **Deploy** — pending PR #446 review. Dev rollout via `firebase deploy --only firestore:rules,functions:getUnitAvailability --project bookbed-dev`. Prod cutover separate. No push to origin/main yet.
- **Note** — claims version 6.79 (not 6.78) because PR #447 (Phase 1 widget refactor) already claims 6.78. Whichever PR merges second will resolve sequencing in the merge.

---

**Changelog 6.78**: Booking widget refactor Phase 0+1 — agent-log cleanup + pure-helper extraction (2026-05-22):

- **Audit doc**: `audit/12-booking-widget-refactor-plan.md` (339 lines) catalogues `booking_widget_screen.dart` (4811 LOC god-screen), proposes 21-unit split across 5 phases with risk per extraction, sibling-overlap check, 10 open decisions. Section-8 questions 1-3 resolved this PR (agent-log: delete; BookingFormState: ChangeNotifier; tests: service-layer only).
- **Phase 0 — agent-log instrumentation removed** (`08973bc9`): 18 `// #region agent log … // #endregion` blocks deleted (–419 LOC). Debug session closed; per `.claude/rules/widget.md` the silent-guard rule applies to messaging callbacks (postMessage / BroadcastChannel / PaymentBridge) and those remain intact.
- **Phase 1 extractions (5 new helpers)**:
  - `presentation/helpers/booking_widget_url_helpers.dart` — 5 static defense-in-depth validators (`sanitizeId`, `isValidBookingReference`, `isValidFirestoreId`, `isValidStripeSessionId`, `safeErrorToString`). Public functions; 9 screen call sites rewritten. **34-case unit test**.
  - `presentation/helpers/booking_widget_url_intent.dart` — sealed `BookingUrlIntent { FreshLoad, StripeReturnSession, LegacyStripeReturn, DirectBookingReturn }` + `parseInitialUrlIntent(Uri)`. Replaces 64 lines of inline URL inspection in `initState` with a single switch. Priority preserved: legacy > stripe-session > direct > fresh. **16-case unit test**.
  - `presentation/helpers/iframe_height_reporter.dart` — encapsulates `_contentKey` + `_lastSentHeight` + post-frame `sendIframeHeight`. Disposed flag pattern bails after teardown.
  - `presentation/helpers/zoom_control_state.dart` — owns `TransformationController` + viewer key + scale + centered-zoom matrix math + scroll-wheel pan. Side-effect fix: now disposes the controller (pre-existing leak in screen).
  - `presentation/widgets/powered_by_badge.dart` — file-private `_PoweredByBadge` promoted to public `PoweredByBadge`. Hardcoded `https://bookbed.io` preserved (audit Q7 punted to follow-up).
- **`BookingFormState` promoted to `ChangeNotifier`** (`a3acc3f7`): every mutable field becomes a private backing field + getter + value-equality-guarded setter that fires `notifyListeners()`. `dispose()` chains `super.dispose()`. `resetState()` writes to private fields and notifies exactly once. New factory methods `toPersistedFormData({unitId, propertyId})` + `applyFromPersisted(PersistedFormData)` collapse 57 LOC of (de)serialization in the screen. **23-case unit test**.
- **`booking_widget_screen.dart` LOC**: 4811 → 4126 (–685, –14%). 22 delegating getters/setters from prior Dec-2025 refactor (`bdd16fa0`) untouched — composers in follow-up phases will replace them.
- **Tests added (73 cases across 3 files)**: pure-function tests only per execution plan; no widget tests. CI gate (`flutter test --coverage` in `.github/workflows/ci.yml`) covers them automatically.
- **Multi-agent race observed**: branch `refactor/booking-widget-phase1` hijacked once by parallel agent who used it for SF-026 migration work and cherry-picked to main. Recovered via surgery: `git branch -D` polluted ref + `git branch -f` restore of `fix/t11c-proper-bookings-migration` + cherry-pick of audit-doc commit onto fresh refactor branch from current main. Branch swapped under foot ~6 times mid-edit; defensive `[ "$(git branch --show-current)" = "..." ] || exit 1` guard before every `git add` + `git commit` prevented stray landings.
- **Verification**: repo-wide `dart format --set-exit-if-changed .` clean (650 files). Repo-wide `flutter analyze --no-fatal-infos` clean (0 issues). Test parity vs `main` (via `git worktree add /tmp/bookbed-main-snapshot main`): main = `+640 -21` after build_runner, refactor branch = `+713 -21`; **same 21 pre-existing failures** (`daily_price_model.freezed.dart`-class), pass-count delta exactly = 73 new test cases I added. **No new regressions.**
- **Mandatory smoke deferred** (per execution plan §Verification): 8 web flows + 4 iOS-dev flows must run before PR open / merge. Cannot be run from automated session — flagged for follow-up.
- **Deploy**: none. Refactor only; no production surface changed.
- **Commits**: `074c2652` (audit doc), `08973bc9` (Phase 0 agent-log delete), `eaabf7ce` (URL helpers), `84a1d906` (URL intent), `a3acc3f7` (BookingFormState ChangeNotifier), `2243a6e7` (IframeHeightReporter), `3ac4af3b` (ZoomControlState), `4b01e033` (PoweredByBadge). Branch `refactor/booking-widget-phase1` — NOT pushed.
- **Follow-ups queued in `docs/TODO.md`**: Phase 2-5 of audit/12 — leaf composers (error screen, overlays, dialogs), state notifiers (validation, payment messaging — BLOCKING risk), Stripe pipeline domain services.

---

**Changelog 6.77**: T11c progress note + booking count audit + audit gitignore whitelist (2026-05-22):

- **T11c progress documented** (`docs/SECURITY_FIXES.md` line 1350, new "T11c progress update 2026-05-22" subsection under SF-019): captures the split status of T11c after SF-023 landed the `getUnitAvailability` CF half. Lists the 5 anonymous-context widget sites that still issue direct `collectionGroup('bookings').where('unit_id', '==', …).where('status', 'in', …)` and therefore block clause-1 removal — 4 streams in `firebase_booking_calendar_repository.dart:107/245/386/496` (`.snapshots()` realtime) + 1 one-shot in `availability_checker.dart:257` (booking-submit gate). Documents the 6-step migration plan + the realtime → ~30s polling UX regression that ships with it. Closes the doc gap that made T11c look ready to land when it wasn't (CF deployed but widget reads not migrated).
- **Booking night/guest count source-of-truth audit** (`audit/18-booking-count-audit.md`, 170 lines, doc-only): maps every persisted vs derived field on the booking doc and the 12 derivation sites (6 Dart `.difference().inDays` floor + 6 TS `Math.ceil(/86_400_000)` ceil). Booking schema persists `check_in`/`check_out` Timestamps + `guest_count` only — no `nights`, no adults/children split. Floor vs ceil agree today because timestamps come from a date picker (midnight-aligned), but DST-straddling bookings produce off-by-one disagreement (Dart `.inDays` truncates 23h day to N-1, TS `Math.ceil` rounds to N). Recommends Option B as minimum fix: in `functions/src/utils/dateValidation.ts` STEP 6, persist the existing `checkInMidnight` UTC-normalized variant (already computed for past-date validation) instead of the raw client Date. Tracked as SF-026 candidate in `docs/TODO.md`.
- **`.gitignore` audit/**/*.md whitelist** (commit `70c91f8e`): `*.md` rule on line 73 was implicitly blocking new files under `audit/`; the existing whitelist covered `README.md`, `CLAUDE.md`, `SECURITY.md`, `.claude/**/*.md`, `docs/**/*.md`, `assets/kb/*.md`, but not `audit/**/*.md`. Required `git add -f audit/18-booking-count-audit.md` for this PR. Added `!audit/**/*.md` (with comment) so future audit files no longer trip the same gotcha.
- **Multi-agent race — stash absorption pattern observed**: terminals A, B, and C all active. My first staged commit was absorbed into terminal A's commit `a1276a8a` (`docs: cross-reference SF-023+SF-025 + audit/17`) because their commit fired against the shared index after my `git add` but before my `git commit`. Net result intact (both audit/18 and the T11c progress section are inside `a1276a8a`); commit message understates scope. Different failure mode than the branch-swap pattern documented in `memory/multi-agent-git-race.md` — here HEAD stayed on `main` but a parallel agent's `git commit` consumed both their staged files AND mine. Memory file updated with the new lesson.
- **Verification skipped** (doc-only): no `functions/`, `firestore.rules`, or `lib/` changes → `npm run build` / `npm run test:rules` / `flutter analyze` / `flutter test` not run. Pre-commit `dart format` passed on the gitignore commit (642 files, 0 changed).
- **Deploy**: none. T11c proper deferred to follow-up PR (5 widget sites + clause drop + rules-test flip). SF-026 (Timestamp normalization) deferred to its own PR. No rules deploy, no CF deploy.
- **Commits**: `a1276a8a` (combined-with-terminal-A: cross-reference SF-023+SF-025 + audit/17 + T11c progress + audit/18) and `70c91f8e` (gitignore audit whitelist) on `main`. Pushed `b4eccec1..70c91f8e` to `origin/main`.

---

**Changelog 6.76**: Cleanup tasks — test debt + dependabot/stash triage docs + build-runner rule (2026-05-22):

- **Test debt — `availability_checker_test.dart` iCal callable mock**: post-SF-023, `_checkIcalEvents` routes through the `getUnitAvailability` callable via `FirebaseAvailabilityRepository`, so the old direct `fakeFirestore.collection('ical_events')` seed pattern no longer wired up. New `_FakeAvailabilityRepository implements IAvailabilityRepository` lives inline in the test file; iCal-specific tests now drive canned `AvailabilityWindow[]` directly. 40/40 tests pass.
- **New interface — `IAvailabilityRepository`** (`lib/features/widget/domain/services/i_availability_repository.dart`): minimal abstract with `fetchAvailability(...)`. `FirebaseAvailabilityRepository` now `implements` it (no behavior change). `AvailabilityChecker` field + constructor param re-typed to the interface so tests can inject a fake without booting Firebase. Calendar repository untouched (frozen per CLAUDE.md NIKADA NE MIJENJAJ).
- **`.claude/rules/build-runner.md` new + CLAUDE.md row**: fresh-clone `--delete-conflicting-outputs` recipe, regen triggers, distinguishing pub-cache desync from build_runner errors. Scoped to `pubspec.yaml`, `build.yaml`, `analysis_options.yaml`, `**/*.g.dart`. Version bumped 7.2 → 7.3.
- **Audit deliverables (execution deferred)**:
  - `audit/18-stash-classification-2026-05-22.md` — all 29 git stashes inventoried by SHA, classified DROP/INVESTIGATE/KEEP. Drops deferred to a quiet window: stash count grew 18 → 21 → 29 mid-session as sibling agents stashed concurrently, making index-based `git stash drop stash@{N}` race-prone (advisor flag).
  - `audit/18-dependabot-triage-2026-05-22.md` — 27 open dependabot branches classified against current `pubspec.yaml` + `functions/package.json` versions. Caught 4 MAJOR bumps the spec's mechanical "auto-merge patch+minor" would have merged: `eslint 8→10`, `stripe 19→20`, `package_info_plus 8→9`, `flutter_secure_storage 9→10`. Merges + PR closes deferred (CI watch impractical mid-race; destructive shared-state ops need user OK).
- **Multi-agent race observed**: stash count 18 → 21 → 29 in minutes, `.git/index.lock` briefly held by sibling, working tree mutated 3x with different file sets, branch swapped main↔cleanup mid-session, origin received independent pushes during fetch. Recovery: snapshotted stash SHAs upfront, cherry-picked sibling's `70c91f8e` (audit/**/*.md gitignore whitelist) onto cleanup branch to un-ignore audit deliverables, verified branch right before commit.
- **Verification**: `dart analyze` on the 4 touched files → no issues. `flutter test test/features/widget/data/helpers/availability_checker_test.dart` → 40/40 green. Pre-commit `dart format` clean (642 files, 0 changed).
- **Commits**: `55981882 chore: cleanup tasks…` on `chore/cleanup-stash-dependabot-test-debt-2026-05-22`, merged to `main` as `b6cd8f4a` and pushed to origin (`70c91f8e..b6cd8f4a`).
- **Known noise**: history contains both `70c91f8e` (sibling whitelist commit) and `cf1546a0` (cleanup-branch cherry-pick of the same diff). Idempotent — the +2 lines applied once; the duplicate is cosmetic in `git log` only. Squashable via interactive rebase + force-push if desired (force-push to `main` warned per CLAUDE.md).

---

**Changelog 6.75**: Widget price-row overflow + admin footer year (2026-05-22):

- **PriceRowWidget overflow fix** (`lib/features/widget/presentation/widgets/booking/price_row_widget.dart:43-91`): the row used `Row(mainAxisAlignment: spaceBetween, children: [Text(label), Text(amount)])` with no `Flexible`/`Expanded` wrapping on either side, so at ≤320px widths Croatian labels (e.g. `"Smještaj (5 noći)"`) + total amount visually clipped the right edge — the price `"€120.00"` rendered as `"€12"`. Wrapped label in `Flexible(child: Text(..., maxLines: 2, overflow: TextOverflow.ellipsis))` and amount in `Flexible(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: Text(...)))`. Label gives way first (ellipsis); amount scales down before clipping. Affects every `PriceRowWidget` caller — `PriceBreakdownWidget` (room price, extra guest fees, pet fees, additional services, total) which surfaces inside `CompactPillSummary` (mobile pill) and `PillBarContent._buildWideScreenLayout` (desktop split-pane).
- **Admin footer year dynamic** (`lib/features/admin/presentation/screens/admin_login_screen.dart:390`): `'© 2024 BookBed Inc. All rights reserved.'` → `'© ${DateTime.now().year} BookBed Inc. All rights reserved.'`. Copyright now self-updates each calendar year.
- **Deferred** (audit doc `audit/07-chrome-smoke-test.md` is missing from the repo, so the source descriptions and screenshots cannot be cross-checked):
  - Task 1 — Login CanvasKit text input sync gap (`enhanced_login_screen.dart`). `PremiumInputField` already has `autocorrect:false`, `enableSuggestions:false`; `_handleLogin` snapshots controllers into locals before async. No defect visible in code without primary repro.
  - Task 3 — Owner dashboard mobile heading truncation ("Nedav…", "Rezer…", "Fi…"). `RecentActivityWidget` already uses `AutoSizeText`/`minFontSize:14`; `_buildChartHeader` uses `Expanded`. No truncating widget located.
  - Task 4 partial — Admin "Em…" placeholder. Only `labelText:'Email Address'` and `hintText:'admin@bookbed.io'` candidates; neither obviously truncates without screenshots.
  - All three carried over to `docs/TODO.md`.
- **Verification**: `flutter analyze` on changed files → 0 issues. Pre-commit hook ran `dart format` → 641 files clean (0 changed).
- **Multi-agent git race encountered**: mid-task another agent twice swapped branch out from under me (`fix/widget-price-row-and-admin-footer-year` → `main` → `audit/booking-count-audit`), reverting working-tree edits once. Recovered by re-applying edits then stashing race-debris (other agents' `CLAUDE.md`, `.claude/rules/auth.md`, `.claude/rules/firestore.md`, `docs/CHANGELOG.md`, `docs/SECURITY_FIXES.md`). Sibling-agent leftovers preserved as `stash@{0}` and `stash@{1}` for their owners. Per `memory/multi-agent-git-race.md`: verified `git branch --show-current` immediately before `git add` and `git commit`.
- **Commits**: `bd329688 fix(ui): widget price row overflow + admin footer year` on `fix/widget-price-row-and-admin-footer-year`, merged to `main` as `a6374c35`. No origin push, no deploy.
- **Audit**: `audit/19-wave3-cleanup.md` (new).

---

**Changelog 6.74**: Cold-boot auth-race guard + dead CG index prune (2026-05-22):

- **Auth-race guard** (`lib/features/owner_dashboard/presentation/providers/owner_properties_provider.dart:52-67`): `propertyById` now awaits `enhancedAuthProvider.isLoading` before issuing the Firestore read. Previously, cold-boot deep links (e.g. `bookbed://owner/property/<id>`) fired the read before Firebase Auth had restored the session; Firestore rules then rejected the unauth read and Pigeon surfaced a noisy `FirebaseFirestoreHostApi.documentReferenceGet` stacktrace in logcat. The provider now holds in `AsyncLoading` until auth settles, so `PropertyEditLoader` (`lib/core/config/router_owner.dart:784`) keeps showing `UniversalLoader` instead of flashing. `ref.watch(enhancedAuthProvider)` (not `ref.read`) also satisfies the provider-cache-security rule in `.claude/rules/auth.md`. Scope deliberately limited to `propertyByIdProvider`; `unitByIdAcrossPropertiesProvider` left untouched — same shape but not flagged in audit/16-android.
- **2 dead CG indexes pruned** (`firestore.indexes.json`): removed `booking_services{booking_id+created_at}` (`COLLECTION_GROUP`) — zero `booking_services` refs anywhere in `lib/` / `functions/src/`; and `securityEvents{userId+timestamp}` (`COLLECTION_GROUP`) — collection used only as `users/{uid}/securityEvents` subcollection, never via `collectionGroup()`. 66 → 64 indexes. Firebase deploy reports "2 indexes defined in project not in file" — server-side orphans, harmless, not regenerated on subsequent deploys; `--force` deletion not in scope.
- **Verification**: `flutter analyze owner_properties_provider.dart` → 0 issues. `cd functions && npm run test:rules` → 28/28 green (2 suites). Pre-commit `dart format` clean (639 files, 0 changed).
- **Deploy**: indexes deployed to `bookbed-dev` only via `firebase deploy --only firestore:indexes --project bookbed-dev`. Prod untouched. No `git push`.
- **Multi-agent race encountered**: mid-task another agent repeatedly swapped working branch (`hotfix/widget-secrets-exfil`, `fix/t11c-proper-and-booking-count-audit`); fix-commit recovered via `git stash` + branch checkout + pop. Sibling-agent leftovers preserved in `git stash list`.
- **Docs**: `.claude/rules/auth.md` (new "Cold-boot auth-race guard" section with canonical pattern), `.claude/rules/firestore.md` (new "Dead indexes pruned" section logging the removals + verification command).
- **Commit**: `84163b6c` on `fix/auth-race-and-indexes-cleanup`, merged to `main` as `7cb0bac2`. Docs landed via `docs/auth-race-update` separately.

---

**Changelog 6.73**: CF error-class hygiene + dead callsite removal + audit/16 (2026-05-22):

- **6 catch-promote-internal sites fixed** (`functions/src/emailVerification.ts:464`, `stripeSubscription.ts:148`, `icalSync.ts:273`, `stripeConnect.ts:95, 179, 235`): added `if (error instanceof HttpsError) throw error;` guard at the top of each catch block. Prevents the handler's own client-fault HttpsErrors (`invalid-argument`, `not-found`, `failed-precondition`) from being unconditionally rewrapped as `internal`. Primary site `checkEmailVerificationStatus` previously returned HTTP 500 + `INTERNAL` for missing-email input; post-deploy returns HTTP 400 + `INVALID_ARGUMENT`. Five sibling sites in stripeSubscription/icalSync/stripeConnect had the same shape, all fixed. Secondary effect: Sentry noise drop, since `beforeSend` (v6.71) only filters client-fault HttpsErrors, not the over-promoted `internal` ones.
- **Dead Flutter callsite removed** (`lib/core/services/security_events_service.dart`): `_sendSuspiciousActivityEmail` method + `cloud_functions` import deleted. The backing CF `securityEmail.ts` was removed in commit `4cb5a391`; every new-device or new-location login was triggering `functions/not-found` in the Flutter client. Suspicious-login detection still writes to `security_events` Firestore collection unchanged — the audit trail is preserved.
- **3 new rules tests** (`functions/test/firestore_rules/bookings.test.ts`): clause-1 (`unit_id + status`) shape boundary — positive (both fields → unauth ALLOWED, T11c-pending widget path), `unit_id` alone (unauth DENIED), `status` alone (unauth DENIED). `npm run test:rules` 11/11 green.
- **Audit added**: `audit/16-cf-smoke-and-rules.md` — full 38-CF HTTP smoke matrix (callable + request endpoints, region-aware URLs, body-inspection verdict), rules-suite extension, perf baseline for 10 hot CFs. Live deployed-rules diff blocked on IAM (no `serviceUsageConsumer` on `bookbed-dev`); flagged as P3 followup.
- **Anti-pattern sweep**: 16 candidate `HttpsError("internal", …)` sites triaged across 12 files; 10 already had the guard or were no-anti-pattern (bare throws, no inner HttpsError in try). 6 TRUE POSITIVES fixed (above).
- **Co-existing in-flight (not part of this changelog)**: `functions/src/logger.ts` has uncommitted local modifications adding a centralized `CLIENT_FAULT_HTTPS_CODES` allowlist + `logError` downgrade to `WARN` for client-fault HttpsErrors. Complementary defense-in-depth at the logging layer; not authored by 6.73, untouched.
- **Verification**: `cd functions && npm run build` clean; `cd functions && npm run test:rules` 11/11; `flutter analyze` 0 new issues (1 pre-existing `marionette_flutter` dev import).
- **TODO.md**: P0.3 (dead callsite) marked done. P0.1 + P0.2 (prod deploys of `getBookingByStripeSession` + `sendOwnerEmail`) still pending — require explicit deploy authorization.
- **Security log**: `docs/SECURITY_FIXES.md` — added SF-022 entry covering both the catch-promote fix and dead callsite removal.
- **NOT shipped**: code on `main` working tree, NO commit, NO deploy. Awaiting user review.

---

**Changelog 6.72**: Sentry Dart env detection + iOS Firebase project contamination hardening + Wave 0 PROD cleanup (2026-05-21):

- **Sentry Dart env detection** (`lib/core/utils/sentry_env.dart` new; `lib/widget_main.dart:115`, `lib/main.dart:499` edited): mirrors yesterday's `functions/src/sentry.ts detectEnvironment()` (audit/11) on the Flutter side. Reads `Firebase.app().options.projectId` at runtime instead of the hardcoded `'production'` literal. Maps `bookbed-dev` → `development`, `bookbed-staging` → `staging`, `rab-booking-248fc` → `production`, anything else → `unknown`. Uses runtime project ID rather than `EnvironmentConfig.firebaseProjectId` because `widget_main.dart` never calls `setEnvironment` (audit/13).
- **iOS Firebase contamination hardening** (`lib/widget_main_staging.dart` new; 6 entry points edited): adds `kDebugMode` projectId asserts after every `Firebase.initializeApp` in `main.dart`, `main_dev.dart`, `main_staging.dart`, `main_prod.dart`, `widget_main.dart`, `widget_main_dev.dart`, and the new `widget_main_staging.dart`. Crashes early in debug if entry-point ↔ Firebase project mismatch. Defense against the Wave 0 root cause: `ios/Runner/GoogleService-Info.plist` hardcoded to PROD + default `flutter run` picks `lib/main.dart` (PROD options) + no native `FirebaseApp.configure()` → silent contamination on iOS dev testing. Documented in `.claude/rules/ios-development.md` (new) and referenced from `CLAUDE.md` Path-Scoped Rules table.
- **Deploy script fixes** (`scripts/deploy_dev.sh:10`, `scripts/deploy_staging.sh:10`): widget build target swapped from `lib/widget_main.dart` (PROD options) to `lib/widget_main_dev.dart` / `lib/widget_main_staging.dart`. Closes the dev/staging widget → prod Firebase exposure surface (audit/14). Scripts have been broken since `widget_main_dev.dart` was added 2026-01-10 (`a85a33f5`).
- **Sentry Dart fix deploy** (2026-05-21 ~20:50 UTC): owner+widget deployed to PROD via `firebase deploy --only hosting:owner,hosting:widget --project rab-booking-248fc`. Static-verified all 3 project ID literals + 4 env labels present in deployed `main.dart.js`. Runtime Sentry envelope verification structurally blocked by app's `PlatformDispatcher.instance.onError` swallower (`lib/main.dart:295-310`) which catches all uncaught errors and calls `LoggingService.log` (not `logError` → does not forward to Sentry). Code+static verify accepted by user.
- **Staging owner deploy** (2026-05-21 ~20:30 UTC): owner deployed to `bookbed-owner-staging.web.app` via `firebase deploy --only hosting:owner --project bookbed-staging` to validate the helper before prod cutover.
- **Wave 0 PROD contamination cleanup** (2026-05-21 ~20:23 UTC): deleted via `scripts/cleanup-prod-wave0-orphans.js --skip-stripe-check --execute`:
  - Auth user `wave0-smoke-202605181440@bookbed.test` (UID `qoN6aykKwqZI4n9REgqXfEFG8KM2`)
  - Firestore `users/qoN6...` doc
  - `properties/6VCCLt8rnSokrIani9oU` "Wave Test Vila" + nested `units/seg85UhyMQM8hw7ZpLhq` "Apartman A" + `widget_settings/seg85UhyMQM8hw7ZpLhq` (latter was a subcollection-walk surprise — earlier audits had missed it)
  - Total PROD properties 14 → 13. Verification rerun: all artifacts absent.
  - **Stripe Connect `acct_1TYSMdPWhhVc6lN0` NOT dissolved by this run** — `--skip-stripe-check` flag bypasses precheck. Account remains active in BookBed live mode; orphan record now (no linked Firestore user). Manual dissolution still required via Stripe Dashboard.
- **Audit artifacts added**: `audit/12-widget-e2e-dev.md` (partial widget E2E smoke, browser-drive blocked by missing Chrome DevTools MCP), `audit/13-sentry-dart-fix.md` (Sentry Dart fix narrative + verification posture), `audit/14-deploy-scripts-mismatch.md` (deploy script audit + Wave 0 contamination discovery), `audit/15-prod-contamination-deep-check.md` (Stripe Connect / FCM / OAuth deep check + cleanup execution log). Migration log: `audit/migrations/2026-05-21-prod-wave0-cleanup.log`.
- **Commits**: `c8d0bf8f fix(sentry): detect Dart-side env from Firebase project ID`, `0357f80d Merge: Sentry Dart env detection`, `6d8dbad5 fix(env): iOS Firebase project contamination hardening`, `3986962f Merge: iOS Firebase env hardening + cleanup script (gated)` on `main`.
- **Branch**: `fix/sentry-dart-env-and-seed` and `fix/ios-firebase-env-hardening` merged into `main` via `--no-ff`, both pushed to origin.
- **NOT yet shipped**: dev + staging widget redeploys with the new env-correct entry points. Next ticket. Awaiting user manual Stripe Connect dissolution before declaring Wave 0 cleanup fully complete.

---

**Changelog 6.71**: Sentry HttpsError noise filter + prod orphan-function cleanup (2026-05-21):
- **Filter** (`functions/src/sentry.ts`): added `beforeSend` to `Sentry.init` that drops events where the original exception is an `HttpsError` with a client-fault `code`. Dropped codes: `invalid-argument`, `unauthenticated`, `permission-denied`, `not-found`, `already-exists`, `failed-precondition`, `out-of-range`, `resource-exhausted`, `cancelled`. Server-fault codes (`internal`, `unknown`, `data-loss`, `unavailable`, `deadline-exceeded`, `aborted`) still report.
- **Why**: Sentry's `@sentry/node` firebase otel auto-instrumentation (`mechanism: auto.firebase.otel.functions`) captures every thrown `HttpsError` from `onCall` handlers, including 4xx-equivalent client mistakes. Three noisy issues in Sentry (FLUTTER-6C `getBookingByStripeSession` `invalid-argument`, FLUTTER-6E `verifyBookingAccess` `invalid-argument`, FLUTTER-6G `verifyBookingAccess` `permission-denied`) were all of this class.
- **Discriminator**: `err.httpErrorCode !== undefined && typeof err.code === "string" && clientFaultCodes.has(err.code)`. The `httpErrorCode` field is unique to firebase-functions `HttpsError` (set by `errorCodeMap[code]` in `https.js:81`) so non-Firebase errors with a `.code` string (Firestore errors etc.) are not falsely dropped.
- **Deploy**: dev (`bookbed-dev`) commit 8c9ebf1d on `hotfix/widget-secrets-exfil` (deployed in-place); prod (`rab-booking-248fc`) via cherry-pick onto `main` (commit 16224575 → origin/main), then `firebase deploy --only functions --project production`.
- **Prod orphan-function cleanup**: 5 functions still live on prod but already deleted from source (commits `ebddecaf feat(kill): remove comebackReminder` + `c3465034 feat(kill): remove Booking.com + Airbnb OAuth integration`). Dev had already pruned these; prod was out of sync. Deleted via `firebase functions:delete <name> --project production --force --region <region>`:
  - `comebackReminder` (europe-west1)
  - `handleAirbnbOAuthCallback`, `initiateAirbnbOAuth` (us-central1)
  - `handleBookingComOAuthCallback`, `initiateBookingComOAuth` (us-central1)
- **Branch**: `fix(sentry)` commit lives on both `hotfix/widget-secrets-exfil` (original) and `main` (cherry-pick).
- **Future**: when `hotfix/widget-secrets-exfil` lands on prod, no Sentry-filter conflict — the same file change is already on prod. Cherry-pick will reconcile cleanly.
- **NOT shipped on prod yet**: the rest of the `hotfix/widget-secrets-exfil` branch (widget_secrets split, `ICAL_TOKEN_PEPPER`, `ALLOWED_SUBSCRIPTION_PRICE_IDS`, `RESEND_API_KEY` allowlist enforcement). Three per-env prereqs required first — see `memory/widget-secrets-exfil-deploy-prereqs.md`.

---

**Changelog 6.70**: Wave 0 promote wrap-up (2026-05-18):
- **Scope**: 8 Wave 0 branches (T7/T8/T10/T11/T12) + 3 post-test fixes (null.toString hardening, ErrorBoundary reset + AI chat UX, env-url centralization) merged to `main`. Tags `pre-wave0-promote` (`eadec3cc`) and `post-wave0-stable` (`a480e5f3`) pushed to origin.
- **Stripe SSRF allowlist made env-aware** (`functions/src/stripePayment.ts`): `const ALLOWED_RETURN_DOMAINS` → `function getAllowedReturnDomains()`. Reads `process.env.GCP_PROJECT` / `GCLOUD_PROJECT` / `FUNCTIONS_EMULATOR`; appends `bookbed-widget-dev.web.app` + `bookbed-owner-dev.web.app` for dev, `bookbed-widget-staging.web.app` + `bookbed-owner-staging.web.app` for staging. Two callers updated (`isAllowedReturnUrl()`, security-log branch). `ALLOWED_WILDCARD_DOMAINS` untouched. Deployed to `bookbed-dev` only (`createStripeCheckoutSession(us-central1)`); prod (`rab-booking-248fc`) and staging untouched.
- **Jest config pre-existing fragility patched**: `functions/jest.config.js` now has `testPathIgnorePatterns: ["/node_modules/", "<rootDir>/test/firestore_rules/"]` so plain `npm test` skips the emulator-required suite (152/152). `functions/package.json` `test:rules` script adds CLI `--testPathIgnorePatterns=/node_modules/` to override the config-level ignore and re-include rules (8/8 with emulator). Don't change either side without testing both.
- **Conflicts resolved during merges** (6 total across 3 merges):
  - `fix/null-tostring-hardening`: 1 — `docs/TODO.md` (both sides added independent sections; kept both, null-tostring-related first).
  - `fix/error-boundary-and-chat-ux`: 3 — `CLAUDE.md` (kept context-mode section + v7.1 bump), `docs/CHANGELOG.md` (dropped redundant "Reserved v6.67" placeholder), `ai_chat_provider.dart` (dropped orphan `final errorMsg = e.toString();` left by T7).
  - `fix/environment-url-centralization`: 2 — `.claude/rules/widget.md` (dropped obsolete "Brittle host check" + "Hardcoded literals" sections, kept "Silent debug guards", took post-fix "Host comparisons"), `docs/CHANGELOG.md` (env-url entry bumped from claimed 6.67 → 6.69 to avoid collision with error-boundary 6.67).
- **Resmoke** (Phase 4, against `bookbed-dev`):
  - CF probes — `getBookingByStripeSession`: 404 ✓, `verifyBookingAccess`: 404 ✓, `createStripeCheckoutSession`: 400 INVALID_ARGUMENT ✓ (no 500 from SSRF regression).
  - Live rules regression — `stripe_session_id` query 403 ✓, `booking_reference` query 403 ✓, `unit_id+status` query 200 ✓ (T11c-deferred, intentional).
  - `flutter analyze` 0, `flutter test` 1100/1100, `npm test` 152/152, `npm run test:rules` 8/8.
- **Outstanding** (deferred to Wave 1):
  - 12 branches awaiting archive-and-delete (8 Wave 0 + 1 test/wave0-integration + 3 helper branches created mid-promote: `fix/stripe-dev-allowlist`, `chore/jest-exclude-rules-from-default`, `chore/jest-rules-script-fix`).
  - 9 stashes awaiting triage (`stash@{0}-{8}` Wave 0-era; full table in `audit/09-wave0-promote-report.md`).
  - Prod cutover (`rab-booking-248fc`) — Wave 0 changes are dev-only until separate prod deploy.
  - Stripe allowlist proper env-var refactor (forward-looking — current pattern is project-id-conditional).
  - T11c (drop `unit_id+status` clause) blocked on `getUnitAvailability` Cloud Function.
- **Audit doc**: `audit/09-wave0-promote-report.md` (committed `31c47c78`).
- **Multi-agent git race surfaced**: 5+ parallel claude sessions on host caused branch swaps during pre-flight. Documented in MEMORY → `wave0-promote-2026-05-18.md`. Future promote runs should serialize via external mutex.

---

**Changelog 6.69**: Environment URL Centralization (T13):
- **`EnvironmentConfig` API extended** (`lib/core/config/environment.dart`):
  - New getters: `widgetHost`, `dashboardHost`, `marketingHost`, `isWidgetHost()`, `isMarketingHost()`.
  - Dev `widgetBaseUrl`: `http://localhost:5000` → `https://bookbed-widget-dev.web.app` (real Firebase Hosting site, no emulator dependency).
  - Dev `dashboardBaseUrl`: `http://localhost:5001` → `https://bookbed-owner-dev.web.app`.
  - `marketingHost` returns `'bookbed.io'` for all envs (no dev/staging marketing hosting target exists in `firebase.json`).
- **6 prod-path callsites refactored** (replaced `view.bookbed.io` / `app.bookbed.io` literals with `EnvironmentConfig` getters):
  - `widget/subdomain_service.dart:51` — host-skip check
  - `widget/booking_view_screen.dart:107` — host-skip check
  - `widget/booking_widget_screen.dart:4036` — marketing-domain rewrite (uses `isMarketingHost()`)
  - `owner_dashboard/embed_widget_guide_screen.dart` — removed `_subdomainBaseDomain` const + 3 usages
  - `owner_dashboard/embed_code_generator_dialog.dart` — removed duplicate `_defaultWidgetBaseUrl` + `_subdomainBaseDomain` consts + 3 usages
  - `subscription/subscription_screen.dart` — removed `_webDashboardUrl` const, snackbar copy now interpolates `dashboardHost`
- **Latent staging bug fixed**: `host.startsWith('view.')` in `subdomain_service.dart:51` + `booking_view_screen.dart:107` would have parsed `'staging'` as a client subdomain on staging widget host. Replaced with `host == EnvironmentConfig.widgetHost`.
- **Stays hardcoded** (intentional): iCal UID `@bookbed.io` (RFC 5545 stable identifier), embed-snippet HTML for owner paste targets.
- **Follow-up**: `functions/src/stripePayment.ts` SSRF allowlist keyed on `.view.bookbed.io` — dev Stripe `returnUrl` now resolves to `bookbed-widget-dev.web.app` and will fail SSRF check. Backend env (`functions/.env.bookbed-dev`) needs `WIDGET_ALLOWED_HOSTS` extended.
- **Branch**: `fix/environment-url-centralization`.
- **Audit doc**: `audit/08-environment-url-centralization.md`.
- **Closes**: `audit/04c-hardcoded-urls.md` §3.1 (M7) + `audit/07-ios-smoke-test.md` "Hardcoded prod URLs".

---

**Changelog 6.68**: `null.toString()` hardening in widget URL building (2026-05-18):

- **Root cause** (`audit/08-null-tostring-fix.md`): `Uri()` constructor's `queryParameters` encoder calls `.toString()` on every value. In Flutter web (dart2js / CanvasKit) this becomes literal `null.toString()` at the JS layer and throws `TypeError: Cannot read properties of null (reading 'toString')`. Dart's sound null safety does not catch this because `Uri()` accepts `Map<String, dynamic>`.
- **Fix** (`lib/features/widget/presentation/screens/booking_view_screen.dart:191-198, 235-242`): coerce nullable `widget.bookingRef` / `widget.email` with `?? ''` before passing to `Uri.queryParameters`. The `if (widget.token != null) 'token': widget.token` collection-if pattern is preserved (Dart's flow analysis correctly narrows inside the if body).
- **Scope confirmed clean** via grep: `booking_widget_screen.dart`, `booking_confirmation_screen.dart`, `enhanced_login_screen.dart` — all `.toString()` and `jsonEncode` call sites already guarded by previously-merged T8 silent-catches work (e.g. `_safeErrorToString` helper at `booking_widget_screen.dart:131-143`).
- **Validation**: `flutter analyze` clean, `flutter test` 1100/1100, jest 152/152.
- **Out of scope**: Wave 0 smoke test also reported login-form submit crash with the same JS error type; that one is **CanvasKit text-input sync** (different bug class — TextEditingController drifts from DOM `<input>` value), tracked separately. Widget `additional_services` failed-precondition trigger was already closed by the dev composite-index deploy.

---

**Changelog 6.67**: Error-handling UX fixes (Wave 0 smoke follow-up):
- **Sticky ErrorBoundary** (`lib/core/error_handling/error_boundary.dart`):
  - `_tryAgain` / `_navigateToHome` only navigated — they never cleared the cached `_errorDetails`, so the boundary kept repainting the error widget even after the user "recovered". Reported in `audit/07-ios-smoke-test.md` issue #1.
  - Fix: new private `_resetErrorBoundary(context)` walks up with `findAncestorStateOfType<_ErrorBoundaryState>()` and nulls `_errorDetails` via `setState`. Both action handlers call it first. `mounted` guard inside.
- **Raw Gemini error leak in AI chat** (`lib/features/owner_dashboard/presentation/providers/ai_chat_provider.dart`, `…/screens/guides/ai_assistant_screen.dart`):
  - When Vertex AI is disabled on a project (`firebasevertexai.googleapis.com` off), the SDK throws `ServiceApiNotEnabled` with a full GCP error message including project number + console URL. The notifier was setting `state.error = 'DEBUG: $errorMsg'` and the UI banner had a fall-through that displayed it verbatim. Reported in `audit/07-chrome-smoke-test.md` line 539 ("Gemini call — FAIL").
  - Fix: new `_classifyGeminiError(Object e)` maps any `FirebaseAIException` (incl. `ServiceApiNotEnabled`, `QuotaExceeded`, `UnsupportedUserLocation`, `ServerException`, `InvalidApiKey`) to sentinel `'ai_unavailable'`, with string-match fallback on `permission_denied | has not been used | unavailable | resource_exhausted` for raw GCP errors that didn't get wrapped. Everything else → `'ai_error'`. UI banner branches on `'ai_unavailable'` → `l10n.aiAssistantUnavailable`. Unknown sentinels now fall back to the localized generic string instead of rendering raw exception text.
  - Full exception still routed to `LoggingService.logError` for Sentry/Crashlytics.
  - One stray `print('[AiChat] ERROR: $e')` in the same catch block removed (was leaking raw error to dev console). 13 other unrelated `print(` calls in `_aiModelProvider` / `sendMessage` instrumentation remain on `main` — separate cleanup.
- **New l10n keys** (`lib/l10n/app_en.arb`, `lib/l10n/app_hr.arb`):
  - `aiAssistantUnavailable` — "AI Assistant is temporarily unavailable. Please try again in a moment." / "AI Asistent trenutno nije dostupan. Pokušajte ponovno za nekoliko trenutaka."
  - `flutter gen-l10n` regenerated `app_localizations*.dart`.
- **StateNotifier deviation**: source prompt suggested routing l10n through `AppLocalizations.of(context)` inside the provider. `StateNotifier` has no `BuildContext`, so the provider sets a sentinel and UI does the lookup — same outcome, correct layering. Documented in `audit/08-error-handling-fixes.md`.
- **Verification**: `flutter analyze` = 0 issues, `flutter test` = 1100 tests pass. Runtime (Marionette / chrome-devtools) verification deferred — no live sim / widget server in this session.
- **Branch**: `fix/error-boundary-and-chat-ux` (NOT pushed, NOT merged).
- **Audit doc**: `audit/08-error-handling-fixes.md`.

---

**Changelog 6.66**: Echo Detection Timezone Fix + Interval Subtraction:
- **Timezone Bug in `generateNightSet()`** (`echoDetection.ts`):
  - `setUTCHours(0,0,0,0)` + `toISOString()` produced wrong date for bookings stored at 22:00 UTC (= midnight Zagreb CEST)
  - Example: Aug 17 booking at `2026-08-16T22:00:00Z` → normalized to `"2026-08-16"` instead of `"2026-08-17"`
  - Caused 13/14 containment instead of 14/14 → false 1-night "new" range → **overbooking on Timeline Calendar**
  - Fix: `toLocaleDateString('en-CA', {timeZone: 'Europe/Zagreb'})` with fallback, noon-UTC iteration (DST-safe)
- **Interval Subtraction (`save_trimmed`)** (`echoDetection.ts`):
  - New `RecommendedAction`: `save_trimmed` — imports ONLY genuinely new date ranges from aggregator events
  - `groupConsecutiveNights()` + `isNextDay()` — groups unblocked nights into contiguous ranges
  - Overrides `flag_review` when containment detects partial overlap (trimming is more precise than flagging)
- **New Tests** (`echoDetection.test.ts`):
  - Timezone offset test: booking at 22:00 UTC vs VEVENT at 06:00 UTC → same Zagreb date → `auto_skip`
  - Zagreb YYYY-MM-DD format sanity check
  - 8 interval subtraction tests (real-world Adriagate, 100% containment, 0% overlap, multiple ranges, turnover days, save_trimmed priority)

---

**Changelog 6.65**: AI Branch Audit #2 — Cherry-picked Bug Fixes from 3 Branches:
- **4 branches audited** (`fix-memory-resource-leaks`, `audit-ci-cd-updates`, `audit-auth-user-management`, `audit-monthly-architecture-audit`):
  - All 4 had same regressions: dependency downgrades, SF-008 removal, accountType sync removal, firestore rules rollback, docs rollback — all skipped
- **Apple Sign-In Name Propagation Fix** (`enhanced_auth_provider.dart`):
  - **REAL BUG** confirmed by Firestore data — native iOS Apple Sign-In users had empty `first_name`/`last_name`
  - Root cause: `appleCredential.givenName`/`familyName` available from Apple SDK but never passed to `_createUserProfile()`
  - Firebase does NOT auto-set `displayName` from native OAuthCredential flow (confirmed: both Apple users had `displayName: null`)
  - Fix: Added `firstName`/`lastName` params to `_createUserProfile()`, capture from `appleCredential`, fallback to `displayName` parsing
  - `displayName` now constructed from names if Firebase doesn't set it
- **AI Chat StateNotifier Mounted Checks** (`ai_chat_provider.dart`):
  - Added `if (!mounted) break/return` at 4 points during streaming response
  - Prevents "Bad state: Tried to use StateNotifier after dispose" if user navigates away during AI streaming
- **TextEditingController Disposal** (`email_verification_screen.dart`):
  - Wrapped both `showDialog` calls in `try/finally` with `controller.dispose()`
  - Minor memory leak fix — controllers created in methods weren't disposed
- **Widget Deploy Pipeline Fix** (`deploy-widget.yml`):
  - Added `cp web/bookbed-overlay.js build/web_widget/` step before Firebase deploy
  - Fixes MEMORY #21 critical deploy bug — overlay.js was never included in CI deploys
  - Without this, iframe scroll-trap fix didn't work on external sites after CI deploy
- **Navigator.Pop → Safe GoRouter Pattern** (`admin_shell_screen.dart`, `unit_form_screen.dart`):
  - Replaced `Navigator.of(context).pop()` with `context.canPop()` + `context.pop()` + fallback `context.go()`
  - 4 places in admin drawer + 1 in unit form save — prevents crash when no previous route on stack
- **Sentry/Logging Improvements** (5 provider files):
  - `calendar_drag_drop_provider.dart` — stackTrace added to move/undo catch blocks
  - `overbooking_detection_provider.dart` — `debugPrint` → `LoggingService.logInfo/logError`
  - `owner_bookings_provider.dart` — error logging for fetch booking by ID
  - `unified_bookings_provider.dart` — error logging for iCal events fetch (was empty `catch (_)`)
  - `platform_connections_provider.dart` — try/catch with logging + rethrow for remove connection
- **Key files**: `enhanced_auth_provider.dart`, `ai_chat_provider.dart`, `email_verification_screen.dart`, `deploy-widget.yml`, `admin_shell_screen.dart`, `unit_form_screen.dart`

**Changelog 6.64**: AI Branch Audit — Cherry-picked Security & CI Fixes:
- **CI Fix** (`.github/workflows/ci.yml`):
  - Disabled CodeQL Analysis job (requires GitHub Advanced Security — not available on private repos)
  - Changed Trivy security scan from SARIF upload to table output (SARIF upload also requires Code Scanning)
  - Both jobs were failing on every CI run — now skipped cleanly
- **EMAIL_SYSTEM.md** — Added `trial-expired.ts` and `trial-expiring-soon.ts` to template table and directory tree (existed since Feb 3 but were missing from docs, count 16→18)
- **Stripe accountType sync** (`functions/src/stripePayment.ts`):
  - Added `accountType: "premium"` to subscription activation webhook
  - Prevents accountStatus/accountType desync (MEMORY.md #23) when owner subscribes
  - Currently inactive code path (subscriptions not yet enabled), but ready for future
- **SF-008 server-side completion** (`functions/src/atomicBooking.ts`):
  - Added 1000 char limit on booking notes server-side
  - Client-side validation existed, server-side was missing
- **Firestore rules** (`firestore.rules`):
  - Added explicit `allow read, write: if false` for `oauth_states` and `sync_failures` collections
  - Both are Cloud Functions-only collections (Admin SDK bypasses rules)
  - Makes implicit default-deny explicit and documented
- **8 AI branches audited** (Jules/Sentinel/Bolt monthly audit Feb 2026):
  - All had dependency downgrades (branch forked before `3a29695c` bump) — skipped
  - All had same CI fix — applied once
  - Skipped: UTC timezone changes (theoretical), min-stay gap re-add (would revert `42157fa2`), auto-cancel refactor (risky rename), FCM push feature (new feature), Navigator.pop fixes (saved as TODO)
- **Key files**: `ci.yml`, `stripePayment.ts`, `atomicBooking.ts`, `firestore.rules`, `EMAIL_SYSTEM.md`

**Changelog 6.63**: Scroll Overlay v5, iCal HEAD Fix & Conflict Badge UI:
- **Scroll Overlay v5 — Universal iframe scroll-trap fix** (`web/bookbed-overlay.js`):
  - External JS served at `view.bookbed.io/bookbed-overlay.js` — host pages add single `<script>` tag
  - Auto-detects BookBed iframes (`src*="view.bookbed.io"`), no wrapper divs needed
  - Uses `position:fixed` + `getBoundingClientRect()` — works in any DOM structure (WordPress, React, Tailwind, etc.)
  - Guard div on `<body>` with RAF-throttled scroll/resize sync
  - Desktop only (`pointer: fine` media query) — mobile/touch unaffected
  - Click to interact → mouseleave restores scroll protection (Google Maps pattern)
  - MutationObserver watches for dynamically added iframes (SPA support)
  - **Previous versions failed**: v2 caused iframe reload (DOM move), v3 left iframe non-interactive, v4 wrong positioning with `offsetTop` in nested containers
- **iCal Export HEAD Request Fix** (`functions/src/icalExport.ts`):
  - iCal validators send HEAD requests to check content-type before GET
  - Was rejected with 405 Method Not Allowed — now allows HEAD alongside GET
  - Deployed to production
- **Calendar Conflict Badge** (`calendar_top_toolbar.dart`, `owner_app_drawer.dart`):
  - Conflict badge extracted from popup menu to standalone badge next to overflow menu icon
  - Always visible when conflicts exist (not hidden in dropdown)
  - Conflict count badge added to Calendar expansion tile in drawer
  - Uses `overbookingConflictCountProvider` for real-time count
- **Embed Guide — Scroll Protection Section** (`embed_widget_guide_screen.dart`):
  - "For Developers" section now includes scroll protection script tag with copy button
  - Explains the overlay pattern and provides the `<script>` tag to copy
- **.gitignore KB File Exception**: Fixed `assets/kb/bookbed_knowledge_base.md` being gitignored by `*.md` rule — CI fix
- **Version bump**: 1.0.9+18 deployed to Play Store
- **Key files**: `web/bookbed-overlay.js`, `calendar_top_toolbar.dart`, `owner_app_drawer.dart`, `icalExport.ts`

**Changelog 6.62**: AI Assistant Redesign, KB Consolidation & Quick Edit Delete:
- **AI Assistant UI Redesign** (`ai_assistant_screen.dart`):
  - New glassmorphism illustration, redesigned chat bubbles with gradients/shadows
  - Desktop split view with chat list + active chat panel
  - Streaming fix: duplicate bubbles resolved (new list per state update)
  - Empty state: illustration/title/subtitle/New Chat button grouped in same Column
  - Consent screen with privacy items before first use
- **AI Knowledge Base Consolidation**:
  - Removed 8 separate chatbot KB files (`docs/AI_Chatbot_Instructions/`)
  - Consolidated into single `assets/kb/bookbed_knowledge_base.md` (gitignored, in pubspec assets)
  - Professional tone ("BookBed tim" instead of personal references)
  - Added Section 10: AI Assistant documentation
  - Removed specific web dev pricing (directs to consultation instead)
  - Contact emails: `info@book-bed.com` for support, `dusko@book-bed.com` for web dev only
- **AI Provider Cleanup** (`ai_chat_provider.dart`):
  - Removed hardcoded predefined answers and blocked keywords
  - Consolidated to unified KB-driven approach
  - Switched from `FirebaseAI.vertexAI()` to `FirebaseAI.googleAI()` (Gemini Developer API)
  - Model: `gemini-2.5-flash-lite` (cheapest, replaces retired 2.0-flash-lite)
- **Booking Quick Edit Delete Button** (`booking_inline_edit_dialog.dart`):
  - Added red "Delete" button to footer alongside Cancel/Save
  - Mobile: Delete + Cancel side by side below Save button
  - Desktop: Delete left-aligned, Cancel + Save right-aligned
  - Uses shared `CalendarBookingActions.deleteBooking()` with confirmation dialog
- **Localization**: Updated EN/HR strings for AI chatbot consent and UI changes
- **Key files**: `ai_assistant_screen.dart`, `ai_chat_provider.dart`, `booking_inline_edit_dialog.dart`, `assets/kb/bookbed_knowledge_base.md`

**Changelog 6.61**: AI Chatbot, Timeline Scroll Sync Fix & Booking Card Improvements:
- **AI Assistant Chatbot** (`ai_assistant_screen.dart`, `ai_chat_provider.dart`):
  - Gemini 2.5 Flash Lite via Firebase AI Logic (`FirebaseAI.googleAI()`)
  - Knowledge base loaded from `assets/kb/bookbed_knowledge_base.md`
  - Predefined answers for common questions (pricing, Stripe, iCal, widget, units)
  - Blocked keywords filter for off-topic technical questions
  - GDPR consent stored in Firestore (`users/{uid}/data/ai_consent`)
  - Chat history in Firestore (`users/{uid}/ai_chats/{chatId}`)
  - Daily message limit: 30 messages per day
  - Streaming responses with real-time UI updates
  - Language detection (HR/EN) for responses
  - Firestore rules deployed for `ai_chats` subcollection
- **Timeline Calendar Scroll Sync Fix** (`timeline_calendar_widget.dart`, `owner_timeline_calendar_screen.dart`):
  - Split `_updateVisibleRange()`: date reporting runs ALWAYS (except TELEPORT), window management gated by flags
  - Removed `_isProgrammaticNavigation` from parent — `forceScrollKey` prevents feedback loop
  - Auto-extend forward when scrolling near end of visible window
  - Debug log cleanup: removed 68+ print statements
- **Month Calendar Fixes** (`month_calendar_screen.dart`):
  - FittedBox fix: replaced with Flexible + TextOverflow.ellipsis per text widget
  - DRY `_getBookingColor` as static method (reused by `_BookingDataSource`)
  - DateTime negative difference: `.clamp(0, 9999)` in booking_inline_edit_dialog
- **Booking Card Header** (`booking_card_header.dart`):
  - Status badge AND booking reference both fully visible
  - Replaced `Spacer()` with `SizedBox(width: 8)` gap
  - Badge: `Flexible(flex: 0)`, Reference: `Expanded` + `Align(centerRight)`
  - Removed unused `importedGuestName` parameter
- **Imported Reservation Visibility** (`booking_action_menu.dart`, `smart_booking_tooltip.dart`):
  - Platform name prominently displayed in purple header (16px bold white)
  - "Manage on" text enlarged from 12→14px with w600 weight
  - External booking badge enlarged in tooltip (icon 14px, text 12px, w700)
- **Dependencies**: `firebase_app_check` upgraded `^0.3.1+6` → `^0.4.1+4`
- **Key files**: `ai_chat_provider.dart`, `ai_assistant_screen.dart`, `ai_chat_repository.dart`, `ai_chat.dart`

**Changelog 6.60**: Security Hardening, Code Quality & Test Coverage:
- **IP-Based Rate Limiting on 4 Endpoints** (Cloud Functions):
  - Created shared `functions/src/utils/ipUtils.ts` — `getClientIp()` + `hashIp()` (SHA-256)
  - `emailVerification.ts`: 10 req/hr per IP (send verification code)
  - `passwordReset.ts`: 5 req/hr per IP (password reset email)
  - `verifyBookingAccess.ts`: 30 req/hr per IP (booking lookup)
  - `icalExport.ts`: 60 req/hr per IP (iCal feed requests, returns 429)
  - `authRateLimit.ts`: Refactored to use shared `ipUtils.ts` (was inline)
  - All use in-memory `checkRateLimit()` — resets on cold start, per-instance
  - Fixed missing `logWarn` imports in `emailVerification.ts` and `passwordReset.ts`
- **print() → LoggingService Migration** (Flutter):
  - `analytics_service.dart`: Full rewrite — all 20+ `print()` → `LoggingService.logDebug()`
  - `firebase_owner_bookings_repository.dart`: Warning log for failed booking parse
  - `email_verification_dialog.dart`: 8x `print()` → `LoggingService.logDebug/logError()`
  - Errors now include stack traces and go to Sentry automatically
- **Test Coverage** (manually copied from `test-coverage-improvement` branch):
  - `atomicBooking.test.ts`: 6 tests — validation, pricing, permissions
  - `authRateLimit.test.ts`: 5 tests — login/registration rate limiting (updated for SHA-256 hash)
  - `bookingManagement.test.ts`: 6 tests — CRUD operations
  - `passwordHistory.test.ts`: 6 tests — password history checks
  - `stripePayment.test.ts`: +8 lines — mock logger (fixes test isolation)
  - All 115 tests passing
- **UI Fix**: Removed unit icons from iCal Export page unit list (cleaner layout)
- **Branches Analyzed & Skipped**:
  - `security-scan-2025-02-03`: Encryption improvement (random IV) — useful but rollback risk
  - `security-scan-2025-02-03`: iCal notes removal — dead code (already removed in 6.56 GDPR)

**Changelog 6.59**: Syncfusion Month Calendar with Custom Cell Builder:
- **New Screen** (`calendar/month_calendar_screen.dart`):
  - Syncfusion Flutter Calendar with Month + Schedule views (2-view toggle)
  - Custom `monthCellBuilder` — date number (top-left), booking count badge (top-right), status dots (bottom)
  - Today highlight with `CircleAvatar`, leading/trailing month dates faded
  - Min/max date boundaries (1 year back, 2 years forward)
  - Unit filter dropdown with `InputDecorationHelper` styling
  - Status legend bar (confirmed/pending/completed/cancelled)
  - Custom `appointmentBuilder` with platform icons and conflict warnings
  - Schedule view with detailed appointment cards (guest name, unit, nights, status badge)
  - Tap appointment → `BookingInlineEditDialog`, tap empty date → `BookingCreateDialog`
  - Skeleton loader while data loads
- **Drawer Navigation** (`owner_app_drawer.dart`):
  - Calendar now uses expandable `_PremiumExpansionTile` with two sub-items:
    - Timeline Calendar (`/owner/calendar/timeline`)
    - Month Calendar (`/owner/calendar/month`)
- **Router** (`router_owner.dart`):
  - Added `OwnerRoutes.calendarMonth = '/owner/calendar/month'`
  - Added GoRoute with fade transition for `MonthCalendarScreen`
- **Dependencies**: `syncfusion_flutter_calendar: ^28.2.6` added to `pubspec.yaml`
- **Key files**: `month_calendar_screen.dart`, `router_owner.dart`, `owner_app_drawer.dart`

**Changelog 6.58**: Dynamic iCal Export URLs from Firestore Feeds:
- **Dynamic Platform Dropdown** (`ical_export_list_screen.dart`):
  - Replaced hardcoded 5-platform list with dynamic URLs from user's actual iCal import feeds
  - Dropdown selector auto-generates `?exclude=` URL per platform
  - Generic "Other / Google Calendar" option always available (no exclude param)
  - Deduplication by exclude value (2 Booking.com feeds → 1 URL card)
  - `_sanitizeSource()` mirrors Cloud Functions `sanitizeSource()` exactly
- **Dialog Redesign**:
  - Custom `Dialog` with dark/light theme support (was `AlertDialog`)
  - Uses `DropdownButton` (not `DropdownButtonFormField` — causes `child!.hasSize` crash in `Flexible > SingleChildScrollView`)
  - `StatefulBuilder` for local state, `icalFeedsStreamProvider.future` for async data
  - Platform icons/colors derived from `IcalFeed.platform` and `customPlatformName`
- **Documentation Sections Improved**:
  - Benefits: removed repetition (was 4 overlapping points → 4 distinct: Calendar Sync, Platform Sync, Auto Updates, Reminders)
  - Steps: rewritten for dropdown flow (was describing old all-cards-at-once UI)
  - Dialog texts: consolidated `platformUrlDesc` and `hubSpokeNote` (were saying the same thing)
  - Hero card: fixed bug showing "no units" text even when units exist (new `icalExportHeroDesc` key)
- **Key files**: `ical_export_list_screen.dart`, `app_en.arb`, `app_hr.arb`

**Changelog 6.57**: iCal Echo Detection Engine with Containment Analysis:
- **Echo Detection Engine** (`functions/src/utils/echoDetection.ts`):
  - 5-factor weighted scoring: Date Match (25%), Duration Match (25%), Export Correlation (25%), Platform Re-export (15%), Temporal (10%)
  - Export correlation INFERRED from existing data (no separate tracking needed): native booking + known re-exporter = 1.0
  - Confidence thresholds: >=95% auto-skip, 85-94% flag for review, <85% save as unique
  - **Containment analysis** for merged echoes (N:1 matching): detects when aggregator merges N adjacent bookings into 1 VEVENT
  - Checks if 100% of incoming nights are already blocked by union of existing bookings
  - Interval union matching verifies contiguous booking chain coverage
  - Safety: only runs for aggregator sources when 1:1 matching gives <95%
- **Platform Classification** (`functions/src/utils/platformClassification.ts`):
  - Authoritative: Booking.com, Airbnb (safe, no re-export)
  - Aggregator: Adriagate (re-exports, merges blocks), Holiday-Home (re-exports + corrupts dates)
  - Atraveo: aggregator with `&dontincludeimported=1` opt-out
- **Hub-and-Spoke Export** (`icalExport.ts`):
  - Per-channel filtered re-export using `?exclude=` query parameter
  - Each platform receives events from OTHER platforms, not its own
  - Prevents circular sync while maintaining full availability visibility
- **Import Controls** (`icalSync.ts`, `ical_feed.dart`):
  - `importEnabled` field for export-only mode (disable import for echo-prone platforms)
  - Echo detection integrated into import pipeline: analyzeEvent() called per event
  - Echo detection fields stored on ical_events: `echo_confidence`, `echo_reason`, `status`
  - Sync interval default changed from 30 to 15 minutes
- **Flutter UI** (`ical_sync_settings_screen.dart`, `ical_export_list_screen.dart`):
  - Import toggle in Add/Edit Feed dialog with explanatory note
  - Per-platform export URL cards with `?exclude=` parameter
  - Orange "Import disabled" indicator in feed list
  - ical_events filtering added to calendar/availability consumer files
- **Verified in production**: Adriagate simple echo auto-skipped at 100% confidence, merged blocks with native Adriagate bookings correctly imported

**Changelog 6.56**: iCal Sync Improvements — Custom Platform Names, GDPR Export, 15-min Sync:
- **Custom Platform Name for iCal Import** (`ical_feed.dart`, `ical_sync_settings_screen.dart`):
  - When selecting "Other" platform, user can now enter custom name (e.g., "Adriagate", "Smoobu")
  - New `customPlatformName` field in `IcalFeed` model, stored as `custom_platform_name` in Firestore
  - New `platformDisplayName` getter returns custom name if set, otherwise default enum display name
  - New localization strings: `icalCustomPlatformName`, `icalCustomPlatformNameHint`, `icalCustomPlatformNameRequired`
- **iCal Export GDPR Compliance** (`icalExport.ts`):
  - **REMOVED** guest PII from iCal export (industry standard: Airbnb, Booking.com, agencies all hide guest info)
  - `SUMMARY` changed from `"Booking: John Smith - Unit"` → `"Reserved"`
  - `DESCRIPTION` changed to minimal: `"{unitName}\nManaged by BookBed"` (no guest name, email, phone, price)
  - Removed unused `buildDescription()` function
- **iCal Sync Interval** (`icalSync.ts`):
  - Changed scheduled sync from **60 minutes → 15 minutes** for faster availability updates
  - Applies to all platforms: Booking.com, Airbnb, Adriagate, and other iCal sources
- **SF-002 REVISED - iCal URL Validation** (`icalSync.ts`):
  - **CHANGED** from whitelist to blocklist approach
  - Whitelist was too restrictive - hundreds of iCal providers exist (agencies, PMS, calendars)
  - Now: Block dangerous addresses (localhost, internal IPs, cloud metadata) but allow any public domain
  - Security maintained via: blocklist + HTTPS requirement + iCal content validation (`BEGIN:VCALENDAR`)

**Changelog 6.55**: Email Date Timezone Analysis — `timeZone: "Europe/Zagreb"` Sufficient:
- **Investigation**: User reported email dates showing -1 day offset (August 6 instead of August 7)
- **Root Cause**: `timeZone: "Europe/Zagreb"` parameter was added on Feb 3, 2026 (commit `fc9565ac`) but Cloud Functions were not deployed after that commit
- **Analysis Result**: The `timeZone` parameter in `toLocaleDateString()` is SUFFICIENT by itself:
  - Cloud Functions run in UTC timezone
  - `timeZone: "Europe/Zagreb"` correctly converts any UTC instant to Zagreb local date
  - No additional +12h normalization needed (would cause +1 day bug for times > 12:00 UTC)
- **Deployed**: Cloud Functions with existing `timeZone: "Europe/Zagreb"` fix
- **Worldwide Compatibility**: Zagreb timezone is correct for Croatian properties. USA users see Croatian check-in date (correct behavior for booking systems)
- **Future TODO**: For international properties, add `property.timezone` field and use it in `formatDate(date, propertyTimezone)`

**Changelog 6.54**: iCal Export Timezone Bug Fix — All Dates Shifted -1 Day:
- **ROOT CAUSE**: `truncateTime()` and `formatDate()` used `getUTCDate()` on Firestore dates stored as midnight local time (UTC+2)
  - Firestore: `May 28, 2026 at 00:00 UTC+2` → JS Date: `May 27, 22:00 UTC` → `getUTCDate()` = **27** (WRONG!)
  - ALL booking dates and gap blocks were shifted back by exactly 1 day in the iCal feed
  - Booking.com/Airbnb saw wrong availability dates
- **Fix** (`icalExport.ts`):
  - `truncateTime()`: Added +12h before `setUTCHours(0,0,0,0)` — ensures correct calendar date for any timezone (UTC-12 to UTC+14)
  - `generateBookingEvent()`: check_in/check_out now go through `truncateTime()` before `formatDate()`
  - Blocked days mapping: `daily_prices` dates normalized via `truncateTime()`
  - `generateBlockedEvent()`: range dates truncated, uses `setUTCDate()` for +1 day arithmetic
  - `calculateMinStayGapBlocks()`: `setDate()` → `setUTCDate()` for consistent UTC arithmetic
- **Verified**: All 5 bookings + 3 gap blocks + 2 off-season blocks now match Firestore exactly
- **Key Learning**: Firestore Timestamp `.toDate()` returns UTC representation — midnight in UTC+2 = 22:00 previous day in UTC. Always add 12h before extracting calendar date.

**Changelog 6.53**: Apple Sign-In iPad App Store Rejection Fix (Guideline 2.1):
- **ROOT CAUSE**: `CODE_SIGN_ENTITLEMENTS` was missing from `project.pbxproj`
  - `Runner.entitlements` existed on disk with correct `com.apple.developer.applesignin` capability
  - But it was NOT linked in Xcode project — binary had no Apple Sign-In entitlement embedded
  - Caused Sign in with Apple to fail on reviewer's iPad Pro 11-inch (M4) running iPadOS 26.2
- **Fix** (`ios/Runner.xcodeproj/project.pbxproj`):
  - Added `PBXFileReference` for `Runner.entitlements` (ID: `BBENTITLE001`)
  - Added `Runner.entitlements` to Runner group children
  - Added `CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;` to all 3 build configs (Debug, Profile, Release)
- **Fix** (`ios/Runner/Info.plist`):
  - Added `GIDClientID` key required by `google_sign_in` v6+ (discovered via Context7 MCP)
  - Value matches `CLIENT_ID` from `GoogleService-Info.plist`
- **Verified**: `flutter build ios --release --no-codesign` passes (71.2MB)
- **Cross-platform verification**: All auth configs verified for iOS, iPad, Android, and Web
- **Key Learning**: Entitlements file MUST be referenced in `project.pbxproj` — having it on disk alone is not enough

**Changelog 6.52**: Bookings Page Performance Optimization & Guide Update:
- **Optimization: Removed Client-Side Sorting** (`owner_bookings_provider.dart`):
  - Removed redundant `.sort()` calls in `WindowedBookingsNotifier` and `PaginatedBookingsNotifier`.
  - Reliance on Firestore's `orderBy` prevents UI jumps during progressive loading.
- **Optimization: Scroll Debounce** (`owner_bookings_screen.dart`):
  - Added 100ms debounce to scroll listener to reduce CPU load and prevent rapid-fire data requests.
  - Updated scroll thresholds (90%) for proactive background loading.
- **Embed Widget Guide Update** (`embed_widget_guide_screen.dart`):
  - Added "For Developers" section with styling customization info and security warnings about the src URL.
  - Updated English and Croatian localizations for the developer guide.

**Changelog 6.51**: iCal Export Critical Fixes — Same-Day Turnover & Min-Stay Gap Blocking:
- **DTEND Off-by-One Fix** (`icalExport.ts` → `generateBookingEvent`):
  - **Problem**: Added +1 day to check_out, blocking check-out day for new check-ins (no same-day turnover)
  - **Fix**: Set `DTEND = check_out` (no +1). In iCal, DTEND is exclusive, so check-out day is now free
  - Example: Booking 1-5 July → DTSTART=1, DTEND=5 → blocks nights 1,2,3,4; July 5 free for check-in
- **Min-Stay Gap Blocking** (`icalExport.ts` → `calculateMinStayGapBlocks`):
  - Detects gaps between bookings/blocks shorter than unit's `min_stay_nights`
  - These gaps are exported as "Not Available" (VEVENT with TRANSP:OPAQUE)
  - Prevents OTAs from accepting reservations that violate min-stay rules
- **Verified**: Same iCal feed works for Booking.com, Airbnb, VRBO, Google Calendar, etc. (RFC 5545 standard)

**Changelog 6.50**: Widget UI Fixes, iOS Compatibility & Email Terminology:
- **Additional Services Widget — Neutral Colors** (`additional_services_widget.dart`):
  - **Problem**: Widget booking form used green (`statusAvailableBorder`/`statusAvailableBackground`) colors — green is reserved for calendar availability status
  - **Fix**: Replaced with neutral minimalist colors:
    - Section container: `backgroundPrimary` (white/black)
    - Selected item: `backgroundSecondary` (#FAFAFA/#0A0A0A), border: `borderStrong`
    - Unselected item: `backgroundPrimary`, border: `borderDefault`
  - **Dark Mode Checkbox Fix**: Added explicit `activeColor: colors.textPrimary`, `checkColor: colors.backgroundPrimary`, `side: BorderSide(color: colors.textSecondary)`
  - **Price Breakdown**: Removed green color override from Additional Services row in `price_breakdown_widget.dart`
- **iOS Profile Image Upload Fix** (`storage_service.dart`, `profile_image_picker.dart`):
  - **Problem**: iOS HEIC format rejected by `_allowedExtensions` validation; `image_picker` converts bytes to JPEG but `XFile.name` retains `.heic` extension
  - **Fix**: Added `'heic'`/`'heif'` to allowed extensions, fixed upload path to `'users/$userId/profile/profile.jpg'`
  - Added `LoggingService.logError()` with stackTrace in `ProfileImagePicker` catch block
- **iOS Help & Support mailto: Fix** (`profile_screen.dart`):
  - **Problem**: `canLaunchUrl` returns false for `mailto:` on iOS without Mail configured
  - **Fix**: Replaced `canLaunchUrl` guard with try-catch around `launchUrl`
- **Email Terminology: "kapara" → "avans"** (4 Cloud Functions files):
  - Changed across: `payment-reminder.ts`, `booking-confirmation.ts`, `owner-notification.ts`, `template-helpers.ts`
  - **Bug Fix**: `booking-confirmation.ts` said "u roku od 3 dana" — fixed to "u roku od 7 dana" (actual payment deadline)
- **Max Guests Widget Fix** (`booking_widget_screen.dart`):
  - **Problem**: Guest count picker used `effectiveMaxCapacity` (includes extra beds) instead of `maxGuests` (Unit Hub Step 2 value)
  - **Fix**: Changed 5 references from `effectiveMaxCapacity` to `maxGuests`; removed `maxTotalCapacity` param from `GuestCountPicker`
  - Server-side (`atomicBooking.ts`) validates against `max_total_capacity` (more permissive) — no conflict
  - **Verified**: Booking log confirmed `guestCount: 4` (previously 6)

**Changelog 6.49**: iCal Export Compatibility & Booking.com Restriction FAQ:
- **iCal Export — `.ics` URL support** (`icalExport.ts`):
  - Token parsing now strips `.ics` extension: `pathParts[2].replace(/\.ics$/i, "")`
  - Allows calendar apps that require URL ending in `.ics` to work correctly
- **iCal Export — Pending → CONFIRMED** (`icalExport.ts`):
  - `mapBookingStatus("pending")` now returns `CONFIRMED` instead of `TENTATIVE`
  - Pending bookings block dates in our system — exporting as TENTATIVE allowed OTAs to ignore them
  - Airbnb only reliably imports CONFIRMED events; TENTATIVE may cause double-bookings
- **Booking.com iCal Import (February 2026 UPDATE)**:
  - ~~Previous info about URL restrictions was incorrect~~
  - Booking.com **DOES ACCEPT** custom PMS URLs including `cloudfunctions.net`
  - Successfully tested with `?exclude=booking_com` query parameter
  - Status: "U redu" (OK) in Booking.com Extranet after import
  - No workaround needed - direct import works
- **New FAQ entries** (EN + HR):
  - `icalExportFaq4Q/4A`: "Can I add this URL directly to Booking.com?" → Explains restriction + workaround
  - `ownerFaqIcal5Q/5A`: "Can I export BookBed calendar to Booking.com?" → Same info in main FAQ
  - Fixed `icalExportFaq1A`: Removed misleading "Booking.com syncs every 15-60 min"
- **FAQ Screen** (`faq_screen.dart`): Added both new FAQ items to iCalSync category

**Changelog 6.48**: Unit Wizard Reorganization, Services Display, Live Preview & UI Cleanup:
- **Unit Wizard Step 2 — Extra Beds, Pets & Additional Services**:
  - Extra Beds and Pets expandable sections moved from Step 3 (Pricing) to Step 2 (Capacity)
  - New "Additional Services" expandable section in Step 2 with full CRUD (add/edit/delete)
  - Services stored in Firestore via `AdditionalServiceModel` + `firebase_additional_services_repository`
  - Add service dialog: name, price, pricing type (per booking/per night/per guest/per guest per night), availability toggle
  - Services only available after unit is saved (unitId required for Firestore path)
- **Step 4 Review — Additional Services Display**:
  - New `_buildServicesCard()` using `FutureBuilder` to load services from Firestore
  - Shows service name + formatted price (e.g., "€5.00 per night")
  - Only appears when `unitId != null` and services exist
  - Displayed in both desktop (2x2 grid) and mobile (stacked) layouts
- **Unit Hub Basic Tab — Additional Services Section**:
  - Same `FutureBuilder` pattern with `ValueKey('services_${unitId}')` for unit change rebuild
  - Uses existing `_buildInfoCard` + `_buildDetailRow` helpers for consistent styling
- **Per-Day Override Fields Removed from Pricing Calendar**:
  - Removed 4 per-day override TextFormFields: `minNightsOnArrival`, `maxNightsOnArrival`, `minDaysAdvance`, `maxDaysAdvance`
  - Removed "Advanced Options" ExpansionTile, controllers, validation, parsing, disposal
  - Model fields kept nullable for backward compatibility — existing Firestore data won't break
  - Server/widget validation code unchanged — gracefully falls back to global settings when null
  - Removed ~16 localization keys (labels, hints, validation errors)
- **Embed Widget Guide — Live Preview Feature**:
  - Replaced "Test Your Widget" link with unit dropdown + "Preview Live" button
  - Dropdown uses `DropdownButtonFormField<UnitModel>` with property grouping for multi-property owners
  - Auto-selects first unit, opens `https://view.bookbed.io/?property={id}&unit={id}` directly
  - Dark theme dropdown fix: uses `InputDecorationHelper` for consistent `dropdownColor`, `borderRadius`, `fillColor`
  - New localization keys: `embedGuideSelectUnitHint`, `embedGuidePreviewLive` (EN + HR)
- **Drawer Cleanup** (`owner_app_drawer.dart`):
  - Removed `imagePath` property from `_DrawerItem`, `_DrawerItemWithBadge`, `_DrawerSubItem`
  - Deleted 6 drawer icon PNG assets (`assets/images/drawer_icons/`)
  - Removed `assets/images/drawer_icons/` from `pubspec.yaml` assets list
  - All drawer items now use Material Icons exclusively (simpler, consistent)
- **Offline Indicator Improvement** (`offline_indicator.dart`):
  - Converted from `ConsumerWidget` to `ConsumerStatefulWidget`
  - New "Ponovo povezano" (Back online) green banner on reconnection
  - Auto-hides after 2 seconds via `Timer`
  - Tracks `_wasOffline` / `_showReconnected` states
- **Booking Confirmation Timestamp**:
  - Added `approved_at: FieldValue.serverTimestamp()` when owner confirms a booking
  - Stored alongside existing `updated_at` field

**Changelog 6.47**: Google Sign-In Native SDK & Email Verification Fixes:
- **Google Sign-In Native SDK** (`enhanced_auth_provider.dart`):
  - **Problem**: Error "Failed to generate/retrieve public encryption key for Generic IDP flow" na Android native app
  - **Root Cause**: App koristio `signInWithProvider(GoogleAuthProvider())` - Generic IDP flow koji ne radi na Android native
  - **Fix**: Dodan `google_sign_in: ^6.2.2` paket za native mobile Google Sign-In
  - `signInWithGoogle()` sada koristi `GoogleSignIn().signIn()` za mobile (Android/iOS)
  - Web flow NEPROMIJENJEN - i dalje koristi `signInWithPopup(GoogleAuthProvider())`
  - Apple Sign-In NEPROMIJENJEN - i dalje koristi `signInWithProvider(OAuthProvider('apple.com'))`
  - **Files**: `pubspec.yaml`, `ios/Runner/Info.plist` (reversed client ID URL scheme), `enhanced_auth_provider.dart`
- **Email Verification Resend Network Error** (`email_verification_screen.dart`):
  - **Problem**: Resend dugme pokazivalo raw exception umjesto user-friendly poruke za network errore
  - **Fix**: Dodan network/socket/timeout/connection check u catch blok - sada prikazuje `errorNetworkFailed`
- **Email Verification Polling Error** (`enhanced_auth_provider.dart`):
  - **Problem**: Nakon verifikacije emaila, background polling pokazivao "Greska u mrezi" iako je email vec verified
  - **Root Cause**: `user.reload()` uspije (emailVerified=true), ali `getIdToken(true)` ili Firestore update fail-a, exception se rethrow-a
  - **Fix**: U catch bloku `refreshEmailVerificationStatus()`, ako je email vec verified, pokusaj `_loadUserProfile()` i vrati se bez errora
- **Google Reauth Native Fix** (`enhanced_auth_provider.dart`):
  - **Problem**: `reauthenticateWithGoogle()` koristio Generic IDP flow - ne radi na Android za brisanje accounta
  - **Fix**: `reauthenticateWithGoogle()` sada koristi native `GoogleSignIn` SDK na mobilnim platformama
- **Google Sign-In Account Picker** (`enhanced_auth_provider.dart`):
  - **Problem**: Google Sign-In automatski birao zadnji koristen account bez prikaza account pickera
  - **Fix**: Dodan `googleSignIn.signOut()` prije `signIn()` u `signInWithGoogle()` i `reauthenticateWithGoogle()`
  - `signOut()` briše kesirani account iz Google SDK-a, ali NE odlogovava iz Firebase Auth
- **Change Email Dialog Button Overlap** (`email_verification_screen.dart`):
  - **Problem**: Gumbi "Odustani" i "Promijeni e-poštu" se preklapali na manjim ekranima
  - **Fix**: Omotan `content` u `SingleChildScrollView` - sadržaj se scroll-a umjesto da se gumbi preklapaju

**Changelog 6.46**: Timeline Calendar Fixed Dimensions & UI Fixes:
- **Timeline Calendar — Fixed Cell Dimensions** (`timeline_dimensions.dart`):
  - **Problem**: Parallelogram booking blocks don't align correctly across different screen sizes. Responsive breakpoint-based sizing creates different cell widths per device, making positioning impossible to fix for all breakpoints simultaneously.
  - **Solution**: Replaced ALL responsive dimension calculations with fixed constants based on mobile 360px values. Timeline is horizontally scrollable, so wider screens simply show more days with the same cell size.
  - **Fixed values**: dayWidth=50px, rowHeight=42px, columnWidth=100px, headerHeight=60px
  - **Result**: Mobile ~5 days visible, Tablet ~12 days, Desktop ~25 days (scroll for more)
  - **Files**: `timeline_dimensions.dart` (single source of truth for all 11 timeline consumer files)
- **Booking Block Positioning Fix** (`timeline_grid_widget.dart`):
  - **Problem**: Parallelogram left edge bled into previous day (e.g., booking starting Feb 1 visible in Jan 31)
  - **Root Cause**: `- skewOffset/2` shift (23px) pushed bottom-left corner of parallelogram into previous day
  - **Fix**: Removed the shift — container left = `daysSinceFixedStart * dayWidth` (no offset)
  - Bottom-left corner now aligns with check-in day's left column boundary
  - Turnover gaps between adjacent bookings remain correct (4px)
- **Timeline Components — Fixed Compact Sizing**:
  - `timeline_unit_name_cell.dart`: Replaced responsive font/padding with fixed compact values (12px/10px fonts, 6px horizontal padding). Fixes 2px overflow from 42px row height.
  - `timeline_date_header.dart`: Month header font fixed at 11px, day header circle 24px, font 12px, padding 6px. No more responsive breakpoints.
  - `timeline_summary_cell.dart`: Hardcoded narrow layout (`isNarrow: true`) since dayWidth is always 50px.
- **Login Screen RenderFlex Overflow Fix** (`enhanced_login_screen.dart`):
  - **Problem**: 6.1px overflow in Remember Me row on narrow screens
  - **Fix**: Changed inner text to `Flexible`, compact padding on forgot password button
- **Error Boundary Fixes** (`error_boundary.dart`):
  - Fixed 25px button overflow: Changed `Row` with `Expanded` to `Wrap` with fixed-width `SizedBox(170)`
  - Fixed Navigator error: GoRouter as primary navigation, global navigator key as fallback
- **Social Login Icon Fallback** (`social_login_button.dart`):
  - Added `errorBuilder` to Google and Apple brand icons — shows Material icon if asset fails to load

**Changelog 6.45**: Android Property Form Navigation Crash Fix:
- **Problem**: App crashed on Android (release mode) when clicking "Add Property" after completing registration
- **Root Cause**: `Navigator.of(context).pop()` used in `property_form_screen.dart` crashes when:
  - User is directed to property form directly after registration (no previous route on stack)
  - Navigation was managed by GoRouter, not Navigator
- **Fix** (`property_form_screen.dart:1229-1239`):
  ```dart
  // OLD (crashes):
  Navigator.of(context).pop();

  // NEW (safe):
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/owner/properties');
  }
  ```
- **Android-specific**: Issue only appeared in Android release mode, not iOS
- **Pattern**: Always use `context.canPop()` check with GoRouter fallback instead of raw `Navigator.pop()`

**Changelog 6.44**: Email Verification Flow Fixes:
- **Email Verification Bypass Fix** (`enhanced_auth_provider.dart`):
  - **Problem**: After registration, user was redirected to dashboard instead of email verification page
  - **Root Cause**: `_createUserProfile()` overwrote auth state without `requiresEmailVerification` flag
  - **Fix**: Added email verification check in `_createUserProfile()`:
    ```dart
    final requiresVerification = !isSocialSignIn &&
        AuthFeatureFlags.requireEmailVerification &&
        !firebaseUser.emailVerified;
    state = state.copyWith(
      userModel: userModel,
      requiresEmailVerification: requiresVerification,
    );
    ```
- **Email Change Resend Fix** (`email_verification_screen.dart`, `enhanced_auth_provider.dart`):
  - **Problem**: After changing email, "Resend" button sent verification to OLD email
  - **Root Cause**: `updateEmail()` updated Firestore but not `userModel` in memory
  - **Fix**: `updateEmail()` now also updates `userModel.email` in state
  - Added `resendEmailChangeVerification()` method for re-sending to new email
- **Password Dialog for Email Change Resend** (`email_verification_screen.dart`):
  - **Problem**: `verifyBeforeUpdateEmail()` requires recent authentication
  - **Fix**: Added `_showResendPasswordDialog()` that prompts for password before resending
  - Extracted `_startCooldown()` helper method for code reuse
- **Initial Cooldown on Email Verification Screen**:
  - Added 30-second initial cooldown when screen opens
  - Prevents Firebase rate limit errors when user immediately clicks resend after registration
- **RenderFlex Overflow Fix** (`logout_tile.dart`, `premium_list_tile.dart`):
  - Added `maxLines: 1` and `overflow: TextOverflow.ellipsis` to title and subtitle Text widgets
  - Fixes overflow on iOS simulator with long text
- **Button Color Fix** (`email_verification_screen.dart`):
  - Added `foregroundColor: Colors.white` to ElevatedButton style in change email dialog
  - Fixes dark text on dark theme

**Changelog 6.43**: Security Hardening & CI Upgrades:
- **Security Fix - Encryption Key Validation** (`functions/src/bookingComApi.ts`):
  - **Problem**: Hardcoded fallback encryption key could be used if `ENCRYPTION_KEY` env var not set
  - **Fix**: New `getEncryptionKey()` helper function with fail-fast validation
  - Throws `HttpsError("internal")` if key is missing or uses default value
  - Prevents accidental use of insecure fallback in production
  ```typescript
  function getEncryptionKey(): string {
    const encryptionKey = process.env.ENCRYPTION_KEY;
    if (!encryptionKey || encryptionKey === "default-key-change-in-production") {
      throw new HttpsError("internal", "ENCRYPTION_KEY is not configured.");
    }
    return encryptionKey;
  }
  ```
- **GitHub Actions Upgrades** (`.github/workflows/ci.yml`, `deploy-widget.yml`):
  - `actions/checkout@v4` → `@v6`
  - `actions/upload-artifact@v4` → `@v6`
  - `actions/setup-node@v4` → `@v6`
  - `codecov/codecov-action@v4` → `@v5`
  - All versions tested compatible with `ubuntu-latest` runners
- **iCal Two-Way Sync Verification**:
  - Confirmed `icalExport.ts` correctly exports both bookings AND blocked days
  - Firestore index exists for `daily_prices` collection group query (`unit_id` + `available` + `date`)
  - Blocked days from `daily_prices` where `available=false` are exported as "Not Available" VEVENT entries
  - This prevents Booking.com/Airbnb from showing manually blocked days as available

**Changelog 6.42**: Dialog UI Standardization (Delete Account & Booking Overlap Warning):
- **Delete Account Dialog** (`delete_account_dialog.dart`):
  - Migrated from `AlertDialog` to custom `Dialog` widget matching app design system
  - Added gradient background using `context.gradients.sectionBackground`
  - New header with red (`AppColors.error`) background, warning icon, and close button
  - Footer with `AppColors.dialogFooterDark/Light` and section dividers
  - Proper shadows using `AppShadows.elevation4Dark/elevation4`
  - Responsive sizing using `ResponsiveDialogUtils`
  - Works correctly in both light and dark mode
- **Booking Overlap Warning Dialog** (`booking_create_dialog.dart`):
  - Same migration from `AlertDialog` to custom `Dialog` widget
  - Consistent red header for warning state
  - Theme-aware conflict cards that adapt to dark/light mode
  - Uses `AppColors.error` with proper opacity for conflict highlighting
  - Responsive sizing and proper footer styling
- **Pattern for Warning/Error Dialogs**:
  - Header: `AppColors.error` background with white icon and text
  - Content: `context.gradients.sectionBackground` with theme-aware elements
  - Footer: `AppColors.dialogFooterDark/Light` with section divider border
  - Use `ResponsiveDialogUtils` for width, padding, and height constraints

**Changelog 6.41**: Platform Icons & Booking Details Dialog v2:
- **Platform Logo Images** (`lib/shared/widgets/platform_icon.dart`):
  - Added actual logo images for Booking.com, Airbnb, and other platforms
  - Images stored in `assets/images/platforms/`
  - Circular clipped images with fallback to letters if image fails to load
  - Better visual recognition of booking sources in timeline calendar
- **Booking Details Dialog v2** (`booking_details_dialog_v2.dart`):
  - New improved booking details dialog with better UX
  - Enhanced layout and information display
- **Social Login Icons**: Updated Apple and Google login button icons

**Changelog 6.40**: iCal Import Date Fix & Booking Sorting Improvements:
- **iCal Import Date Fix** (`functions/src/icalSync.ts`):
  - **Problem**: Imported bookings showed as "new" because `created_at` was set to import time
  - **Fix**: Extract original booking date from iCal CREATED/DTSTAMP fields
  - Priority: CREATED > DTSTAMP > startDate (fallback)
  - Imported bookings now sort correctly by their original creation date
- **Navigator Context Fix** (`ical_sync_settings_screen.dart`):
  - **Problem**: "Navigator context not ready" error when editing Airbnb iCal events
  - **Root Cause**: `_checkPlatformMismatch()` called during `initState()` before widget mounted
  - **Fix**: Wrapped call in `WidgetsBinding.instance.addPostFrameCallback()`
- **Booking Sorting Change** (All filter):
  - Changed from `created_at DESC` to `check_in ASC` (soonest first)
  - More operationally relevant: owner sees upcoming bookings first
  - Pending bookings still appear first, then sorted by check-in date
  - Files: `firebase_owner_bookings_repository.dart`, `owner_bookings_provider.dart`, `unified_bookings_provider.dart`
- **Permission-Denied Fix** (`_findBookingById`):
  - Added try-catch for Strategy 2 and 3 to handle permission errors gracefully
  - Prevents crashes when booking not found in expected collections
- **UI Improvements**:
  - Month names in pricing calendar dropdown now localized (Croatian)
  - Embed widget guide header matches export reservations page style
  - Send email dialog buttons use AutoSizeText with maxLines=1

**Changelog 6.39**: Lifetime License Admin Feature:
- **NEW FEATURE**: Admin can grant/revoke lifetime licenses from Admin Dashboard
- **UserModel Changes** (`user_model.dart`):
  - Added `AccountType.lifetime` enum value (trial, premium, enterprise, **lifetime**)
  - Added `lifetimeLicenseGrantedAt` and `lifetimeLicenseGrantedBy` audit fields
  - Added helper getters: `isLifetimeLicense`, `effectiveAccountType`, `hasPremiumAccess`
- **Cloud Function** (`functions/src/admin/setLifetimeLicense.ts`):
  - Callable function for granting/revoking lifetime licenses
  - Security: Checks `isAdmin` custom claim on Firebase Auth token
  - Auditing: Logs all changes to `security_events` collection
  - Validation: Checks user exists, validates boolean `grant` parameter
- **Firestore Security Rules** (`firestore.rules`):
  - Protected fields: `lifetime_license_granted_at`, `lifetime_license_granted_by`
  - Users cannot modify these fields directly (only via Cloud Function)
- **Admin Dashboard UI** (`user_detail_screen.dart`):
  - New "Lifetime License" card with purple theme
  - Shows "ACTIVE" badge when license is granted
  - Displays grant date and admin who granted
  - Grant/Revoke buttons with confirmation dialog
  - Success/error message display
- **Dashboard Stats** (`admin_users_repository.dart`):
  - Added `lifetimeUsers` count to dashboard stats
- **Bug Fix** (`users_list_screen.dart`):
  - Added `AccountType.lifetime` case to switch statement (was causing non-exhaustive error)

**Changelog 6.38**: Timeline Calendar Visual Centering & Same-Day Turnover Support:
- **Visual Centering Fix** (`timeline_grid_widget.dart`):
  - **Problem**: Booking blocks appeared shifted right by ~half a day on timeline calendar
  - **Root Cause**: Parallelogram shape has `skewOffset ≈ dayWidth`, meaning top-left corner starts almost one full day right of container edge
  - **Fix**: Shift bookings left by `skewOffset / 2` so visual center aligns with day column boundaries
  - **Code**: `final left = (daysSinceFixedStart * dayWidth - skewOffset / 2).floorToDouble();`
- **Same-Day Turnover Support** (booking move operations):
  - **Problem**: Admin bookings couldn't be moved to turnover days (checkout == checkin), but Widget bookings could
  - **Root Cause**: Dates weren't normalized to midnight before overlap comparison, causing time component differences
  - **Fix** (`booking_model.dart`, `booking_action_menu.dart`, `timeline_booking_stacker.dart`):
    - `datesOverlap()` now normalizes all dates to midnight before comparison
    - Uses strict inequality (`isBefore`/`isAfter`) which allows checkout == checkin
    - `booking_action_menu` normalizes dates before calling `areDatesAvailable()`
    - `timeline_booking_stacker` uses normalized dates for stack level assignment
  - **Example**: Booking A (May 1-5) does NOT overlap with Booking B (May 5-10)
- **Repository Improvements** (`firebase_booking_repository.dart`):
  - `getOverlappingBookings()` now excludes completed bookings (only pending/confirmed block dates)
  - `deleteBooking()` accepts optional `booking` param to avoid permission issues with collectionGroup queries

**Changelog 6.37**: Timeline Calendar TELEPORT Bug Fixes:
- **Problem 1**: Clicking dates more than ~3 months away in date picker didn't work reliably
  - Sometimes jumped correctly, sometimes stayed in place or jumped to wrong date
- **Root Cause 1**: Timeline calendar uses 90-day "windowed" view for performance
  - When target date is outside visible window, animated scroll couldn't reach it
  - Recursive `_scrollToDate` calls caused race conditions
  - `_extendDateRangeIfNeeded` during scroll caused additional conflicts
- **Fix 1** (`timeline_calendar_widget.dart`):
  - **TELEPORT approach**: For far jumps (target outside visible window):
    1. Set `_isProgrammaticScroll = true` to block scroll listener updates
    2. Rebuild window around target date (set `_visibleStartIndex`, `_forceVisibleStartIndex = true`)
    3. Use `jumpTo()` (instant) instead of `animateTo()` (no race conditions)
    4. Reset flag after 500ms via Timer
  - Two TELEPORT blocks: one for range extension (past/future dates), one for far jumps within existing range
  - **Disabled `_extendDateRangeIfNeeded`**: No longer needed - TELEPORT handles range extension
- **Problem 2**: After TELEPORTing to distant dates and manually scrolling back, reservations disappeared
  - User reported: TELEPORT to May, scroll back towards January → reservations vanish
- **Root Cause 2**: TELEPORT scroll position calculation was missing `offsetWidth`
  - Content structure: `[SizedBox(offsetWidth)] + [day cells]`
  - TELEPORT calculated: `(newWindowTargetDay * dayWidth) - (viewport * 0.25)` ≈ 1550px
  - Should have been: `offsetWidth + (newWindowTargetDay * dayWidth) - (viewport * 0.25)` ≈ 19550px
  - Without `offsetWidth`, scroll landed in the spacer instead of the actual day cells
- **Fix 2** (`timeline_calendar_widget.dart` lines ~860 and ~970):
  ```dart
  // BUG FIX: Must include offsetWidth in scroll calculation!
  final offsetWidth = _visibleStartIndex * dimensions.dayWidth;
  final scrollInNewWindow =
      offsetWidth +
      (newWindowTargetDay * dimensions.dayWidth) -
      (dimensions.visibleContentWidth * 0.25);
  ```
- **Key insight**: Flag-based protection (`_isProgrammaticScroll`) must be set BEFORE `setState()` and reset AFTER scroll completes
- **Testing**: Confirmed working - TELEPORT + manual scroll back no longer causes reservations to disappear

**Changelog 6.36**: Calendar Timeline Booking Move Fixes:
- **UI Not Refreshing After Booking Move** (main fix):
  - **Problem**: After moving booking between units via drag-drop or menu, changes only visible after full app refresh
  - **Root Cause**: Only `calendarBookingsProvider` was invalidated, but UI watches `timelineCalendarBookingsProvider` (filtered provider)
  - **Fix** (`calendar_drag_drop_provider.dart`, `booking_action_menu.dart`):
    - Added `ref.invalidate(timelineCalendarBookingsProvider)` alongside `calendarBookingsProvider`
    - MUST invalidate BOTH: base provider AND filtered provider that UI watches
- **"Cannot use ref after widget disposed" Error**:
  - **Problem**: Error appeared after clicking "Move to" menu item
  - **Root Cause**: `Navigator.pop(context)` called BEFORE `_moveBookingToUnit()`, so `ref.invalidate()` executed after widget disposal
  - **Fix** (`booking_action_menu.dart`):
    - Execute move operation FIRST (while dialog still open)
    - Close dialog AFTER operation completes with `if (mounted && context.mounted)` check
    - Changed `_moveBookingToUnit` return type from `void` to `bool` for proper flow control
- **Provider Invalidation Pattern** (Important for future reference):
  ```dart
  // CORRECT - invalidate both base AND filtered providers
  ref.invalidate(calendarBookingsProvider);        // base provider
  ref.invalidate(timelineCalendarBookingsProvider); // filtered provider UI watches
  ```

**Changelog 6.35**: Web Push Notifications (FCM):
- **NEW FEATURE**: Push notifications za Owner Dashboard (web)
- **Components Created**:
  - `fcm_service.dart` - Flutter FCM service sa VAPID key, token management
  - `fcm_navigation_handler.dart` - Foreground snackbar + navigation handling
  - `firebase-messaging-sw.js` - Service Worker za background notifications
  - `fcmService.ts` - Cloud Functions za slanje push notifikacija
- **Token Storage**: `users/{userId}/data/fcmTokens` (Map format, supports multiple devices)
- **Integration** (`atomicBooking.ts`):
  - `sendPendingBookingPushNotification()` za pending bookinge
  - `sendBookingPushNotification()` za confirmed/updated/cancelled
- **Bug Fix**: "No GoRouter found in context" - SnackBar action koristi `ref.read(ownerRouterProvider).go()` umjesto `context.go()`
- **Foreground**: Shows snackbar with "View" button → navigates to booking
- **Background**: Service Worker shows system notification with click-to-open

**Changelog 6.34**: Weekend Pricing Display & UX Improvements:
- **Weekend Pricing in Widget Calendar** (main feature):
  - **Problem**: Weekend pricing showed correctly in owner dashboard but NOT in embedded widget calendar
  - **Root Cause**: Widget calendar only showed prices in hover tooltips (desktop-only), mobile users couldn't see prices
  - **Fix** (`month_calendar_widget.dart`, `year_calendar_widget.dart`):
    - Added `_buildDayCellContent()` helper with price display directly in calendar cells
    - Price hierarchy: custom daily price → weekend base price → base price
    - Year calendar: price only shows when cellSize >= 24px (responsive)
- **Registration Form UX Fix** (`enhanced_register_screen.dart`):
  - **Problem**: Button disabled on any validation failure without showing why
  - **Fix**: Button only disabled when fields are EMPTY. Validation errors shown on submit click
  - Better UX: users see exactly what needs fixing
- **Unit Hub Race Condition Fix** (`unified_unit_hub_screen.dart`):
  - **Problem**: Auto-selection failed when units loaded before properties (empty properties list)
  - **Fix**: Added guard `if (properties.isEmpty) return;` in `_handleUnitsChanged()`
  - Added `ref.listen` for properties changes to re-trigger auto-selection
- **Booking Details Dialog** (`booking_details_dialog.dart`):
  - Responsive spacing improvements for small screens
  - Payment method and payment option display added
- **Unit Wizard Simplified**: Reduced from 5 steps to 4 steps (removed Photos step - photos added via Unit Hub)

**Changelog 6.33**: Force Update System (Android) - IMPLEMENTED:
- **NEW FEATURE**: App version control sa force/optional update dialogs
- **Components Created**:
  - `AppConfig` model (freezed) - Firestore config za verzije
  - `VersionCheckService` - Version comparison logic (semantic versioning)
  - `ForceUpdateDialog` - Non-dismissible dialog za kritične update-e
  - `OptionalUpdateDialog` - Dismissible dialog, podseća svakih 24h
  - `VersionCheckWrapper` - Widget za automatic version checking
- **Integration** (`main.dart`):
  - VersionCheckWrapper wrap-uje GlobalNavigationOverlay
  - Check-uje verziju na app start i app resume
- **Firestore**:
  - Collection: `app_config/{platform}` (android, ios)
  - Security rules: Read za authenticated usere, write samo Admin SDK
- **Localization**: 10 novih stringova (EN + HR) za update dialogs
- **Documentation**: `docs/FORCE_UPDATE_SETUP.md` - setup instrukcije
- **Testing Required**: Kreirati test `app_config/android` dokument u Firestore
- **Next Release**: Force update će biti aktivan tek u 1.0.3+ (trenutno 1.0.2+6)

**Changelog 6.32**: Email Verification Network Error Fix (v1.0.2+6):
- **CRASH FIX**: Network errors during email verification no longer crash the app
- **Problem**: When checking email verification status, network failures (timeout, no connection) caused app crash
- **Root Cause**: `User.reload()` in `refreshEmailVerificationStatus()` had no error handling
- **Fix** (`enhanced_auth_provider.dart:781-806`):
  - Added try-catch around `user.reload()` to catch and log network errors
  - Error is rethrown for caller to handle gracefully
- **Fix** (`email_verification_screen.dart:55-75`):
  - Added try-catch around `_checkVerificationStatus()` call
  - Shows user-friendly error message: "Network error. Please check your internet connection"
  - User can retry manually or when app resumes
- **Result**: Graceful degradation instead of crash, better UX for poor network conditions
- **Version**: Bumped to 1.0.2+6 for Google Play release

**Changelog 6.31**: Admin Dashboard Documentation & Fixes:
- **Admin Dashboard Section Added** to CLAUDE.md:
  - URL: `https://bookbed-admin.web.app`
  - Entry point, screens, shell navigation documented
  - Firestore rules for admin access documented
  - Admin providers and repository patterns documented
- **Firestore Rules Fix** (`firestore.rules`):
  - Added `isAdmin() || isAdminFromFirestore() ||` to bookings collection group rules
  - Fixes: Admin couldn't see user's bookings count (permission-denied)
- **UI Fixes** (`admin_shell_screen.dart`, `users_list_screen.dart`):
  - Removed theme toggle from AppBar (kept only in drawer)
  - Fixed refresh button on Users page (moved to content row)
- **Hosting Targets Updated**: Added `admin` target for `bookbed-admin.web.app`

**Changelog 6.30**: Safari Web Compatibility Fixes:
- **Flutter Loader TypeError Fix** (`web/index.html`):
  - **Problem**: `TypeError: _flutter.loader.load is not a function` on Chrome & Safari
  - **Root Cause**: `flutter_bootstrap.js` adds `loader` as nested property on `_flutter` object
  - **Original Approach**: `Object.defineProperty` only intercepted initial `_flutter` assignment, not nested `loader`
  - **Fix**: JavaScript `Proxy` with `set` trap to intercept all property assignments including `loader`
  - **Renderer Fallback**: Check `buildConfig.builds` before injecting renderer config
  - Prevents "FlutterLoader could not find a build compatible" error
- **Safari Firebase Init Error Fix** (`main.dart`, `widget_main.dart`, `widget_main_dev.dart`):
  - **Problem**: `Null check operator used on a null value` during Firebase initialization on Safari
  - **Root Cause**: `Firebase.apps` getter throws on Safari when SDK hasn't fully initialized
  - **Fix**: Wrapped `Firebase.apps.isEmpty` in nested try-catch:
    ```dart
    bool needsInit = true;
    try {
      needsInit = Firebase.apps.isEmpty;
    } catch (_) {
      // Safari throws - assume needs init
      needsInit = true;
    }
    if (needsInit) await Firebase.initializeApp(...);
    ```
  - Applied to: Owner app (`main.dart`), Widget production (`widget_main.dart`), Widget dev (`widget_main_dev.dart`)
- **Removed Firebase Compat SDK Pre-initialization**:
  - Commented out `firebase-app-compat.js` and related SDK scripts in `index.html`
  - Was causing conflicts with Flutter's modular Firebase SDK
- **Files Modified**:
  - `web/index.html`: Proxy-based loader interception, renderer fallback, removed compat SDK
  - `lib/main.dart`: Safari-safe Firebase init with detailed logging
  - `lib/widget_main.dart`: Added `_initializeFirebaseSafely()` helper
  - `lib/widget_main_dev.dart`: Added `_initializeFirebaseSafelyDev()` helper
- **Result**: Both Owner Dashboard and Widget now work on Safari (tested on macOS Safari)

**Changelog 6.29**: App Store Submission Preparation & UI Fixes:
- **iOS Deployment Target Fix**:
  - Problem: Runner.xcodeproj targetao iOS 13.0, Podfile zahtijevao iOS 15.0
  - Fix: Ažurirane sve 3 instance `IPHONEOS_DEPLOYMENT_TARGET` na 15.0
  - Rezultat: `flutter build ios --release` sada prolazi
- **Subscription Screen Simplification**:
  - Problem: `trialStatusProvider` uzrokovao Firestore permission error
  - Fix: Uklonjena Firestore zavisnost, screen sada samo pokazuje web redirect button
  - Novi l10n: `subscriptionWebOnlyTitle`, `subscriptionWebOnlyMessage`, `subscriptionContinueToWeb`
  - App Store compliance: Subscription management na webu, ne u app-u
- **Stripe Loading Animation Fix**:
  - Problem: Currency simboli (€, $, £) se pomjerali ~640px umjesto 20px
  - Uzrok: `slideY(end: -20)` koristi widget height multiplier, ne pixele
  - Fix: Promijenjeno na `moveY(end: -20)` koji koristi apsolutne pixele
- **Unit Hub Menu Button Styling**:
  - Zamijenjen plain `IconButton` sa styled button (container, border, SmartTooltip)
  - Konzistentno sa calendar toolbar button stilom
- **App Store Audit**: Verified Sign in with Apple, ATT compliance, ATS, FCM config

**Changelog 6.28**: Dashboard Metrics Fix - Exclude Pending Bookings:
- **Problem**: Dashboard Revenue, Bookings Count, i Occupancy Rate uključivali pending bookinge
- **Izvor**: `fix/dashboard-metrics-6709532682132730445` branch (Jules AI)
- **Fix** (`unified_dashboard_provider.dart`):
  - Kreiran `confirmedAndCompletedBookings` filter
  - Revenue, bookingsCount, occupancyRate koriste samo confirmed/completed
  - **POBOLJŠANJE**: Charts (revenueHistory, bookingHistory) također filtrirani
- **Rezultat**: Summary metrike i chart totali sada konzistentni
- **Napomena**: Upcoming Check-ins i dalje uključuje pending (očekivano ponašanje)

**Changelog 6.27**: Logo Asset Implementation & FCM Push Notifications:
- **Logo Asset System**:
  - Nova `logo-light.avif` slika u `assets/images/`
  - Kreiran `BookBedLogo` widget (`lib/shared/widgets/bookbed_logo.dart`)
  - **Dark Mode Support**: Automatska inverzija boja putem `ColorFilter.matrix`
  - `AuthLogoIcon` ažuriran da koristi `Image.asset` umjesto `CustomPaint`
  - Uklonjena stara `_LogoPainter` klasa
  - Fallback na `Icons.home_work_outlined` ako asset ne učita
- **FCM Push Notifications** (Phase 2):
  - Integrirano u `atomicBooking.ts` za pending i confirmed bookinge
  - `sendBookingPushNotification()` sada prima opcionalne `checkInDate`/`checkOutDate` parametre
  - `sendPendingBookingPushNotification()` za pending bookinge
  - In-app notifikacije putem `createBookingNotification()`
  - Non-blocking izvršenje sa `.catch()` error handling
- **Modified Files**:
  - `pubspec.yaml`: Dodana `assets/images/` folder
  - `lib/shared/widgets/bookbed_logo.dart`: Novi widget
  - `lib/features/auth/presentation/widgets/auth_logo_icon.dart`: Image.asset + dark mode
  - `lib/core/widgets/owner_app_loader.dart`: Koristi `AuthLogoIcon`
  - `lib/features/widget/presentation/widgets/common/bookbed_loader.dart`: Koristi `AuthLogoIcon`
  - `functions/src/atomicBooking.ts`: FCM integracija
  - `functions/src/fcmService.ts`: Ažurirani parametri funkcije

**Changelog 6.26**: Security Audit Complete (SF-001 through SF-017):
- **Analizirani branchevi**: 12 AI agent brancheva (Google Jules, Sentinel, Bolt, Palette)
- **Implementirano**: 17 sigurnosnih ispravki (2 CRITICAL, 1 HIGH, ostalo Low/Medium)
- **Odbijeno**: 1 (SF-003 - mikro-optimizacija bez koristi)
- **Duplikati preskočeni**: 1 (sentinel/fix-pii-leak-calendar - već riješeno u SF-014)

**CRITICAL fixes:**
- **SF-007**: Uklonjena mogućnost spremanja lozinke u SecureStorage ("Remember Me" sada sprema samo email)
- **SF-011**: Dodan `service-account-key.json` u `.gitignore` (sprječava slučajno commitanje Firebase admin credentials)

**HIGH fix:**
- **SF-014**: Spriječeno izlaganje PII podataka (ime, email, telefon gosta) u public booking widget kalendaru

**Ostale ispravke:**
- SF-001: Owner ID validacija u booking creation (server-side)
- SF-002: SSRF prevencija u iCal sync (whitelist enabled)
- SF-004: IconButton hover/splash feedback
- SF-005: Phone number validacija
- SF-006: Sequential character password check (slova + brojevi)
- SF-008: Booking notes length limit (1000 chars)
- SF-009: Error handling info leakage prevention
- SF-010: Year calendar race condition fix
- SF-012: Secure error handling & email sanitization
- SF-013: Haptic feedback on password toggle
- SF-015: DebouncedSearchField ValueNotifier optimization
- SF-016: AnimatedGradientFAB ValueNotifier optimization
- SF-017: Password visibility toggle tooltips (accessibility)

**Dokumentacija**: Sve ispravke detaljno dokumentirane u `docs/SECURITY_FIXES.md`

**Changelog 6.25**: Security Fixes (SF-001, SF-002):
- **SF-001: Owner ID Validation in Booking Creation** (`atomicBooking.ts`):
  - **Problem**: `ownerId` parametar dolazio direktno iz klijentskog zahtjeva bez validacije
  - **Fix**: Sada se `owner_id` dohvaća iz property dokumenta u Firestore-u (server-side validacija)
  - **Benefit**: Sprječava maliciozne korisnike da postave pogrešan `owner_id`
- **SF-002: SSRF Prevention in iCal Sync** (`icalSync.ts`):
  - **Problem**: Whitelist validacija za iCal URL-ove bila zakomentirana - server dopuštao bilo koji URL
  - **Fix**: Omogućena whitelist validacija - samo poznate booking platforme (Booking.com, Airbnb, Google Calendar, etc.)
  - **Breaking Change**: URL-ovi koji nisu na whitelisti sada se blokiraju
  - **Otkrio**: Google Sentinel (automated security scan)
- **Nova dokumentacija**: `docs/SECURITY_FIXES.md` - prati sve sigurnosne ispravke s detaljima

**Changelog 6.24**: Embed Code URL Fix - Remove Subdomain Prefix:
- **Problem**: Embed kod generirao URL sa property subdomain prefiksom (npr. `jasko-apartments.view.bookbed.io`)
  - Subdomene nisu uvijek konfigurirane u Firebase Hosting
  - Property name se koristio kao subdomain, što ne odgovara stvarnoj konfiguraciji
- **Fix**: Embed kod sada uvijek koristi `view.bookbed.io` bez prefiksa
  - Property i Unit ID parametri su dovoljni za identifikaciju
  - Subdomene su opcionalne i koriste se samo za slug URL-ove (shareable links)
- **Izmijenjeni fajlovi**:
  - `embed_code_generator_dialog.dart`: `_iframeEmbedCode` sada koristi `_defaultWidgetBaseUrl`
  - `embed_widget_guide_screen.dart`: `_generateEmbedCode` sada koristi fiksni `view.bookbed.io`
- **Rezultat**: Embed kod radi na svim sajtovima bez potrebe za konfiguracijom subdomene

**Changelog 6.23**: flutter_animate Migration Phase 2-5 Complete:
- **Migrated Files** (AnimationController → flutter_animate):
  - `auth_logo_icon.dart`: Scale pulse + glow opacity animation
  - `booking_details_screen.dart`: Fade-in entrance animation
  - `booking_confirmation_screen.dart`: Fade-in entrance animation
  - `confirmation_header.dart`: Scale animation for success icon
  - `error_boundary.dart`: Float + rotate animation for error illustration
  - `year_calendar_skeleton.dart`: Shimmer effect
  - `month_calendar_skeleton.dart`: Shimmer effect
- **Critical Bug Fix - Parallel Animations**:
  - **Problem**: flutter_animate chains `.effect1().effect2()` run sequentially by default
  - **Original behavior**: Single AnimationController = simultaneous animations
  - **Fix**: Added `delay: Duration.zero` to second effect for parallel execution
  - Affected: `auth_logo_icon.dart` (scale + glow), `error_boundary.dart` (moveY + rotate)
- **Radians to Turns Conversion**:
  - flutter_animate `.rotate()` uses turns (1 turn = 360°), not radians
  - Formula: `radians / (2 * pi)` → turns (e.g., `0.05 rad / 6.283 ≈ 0.008 turns`)
- **Files NOT Migrated** (patterns incompatible with flutter_animate):
  - `owner_app_loader.dart`, `bookbed_loader.dart`, `bookbed_branded_loader.dart`: Custom `Alignment(-1 → 2)` animation
  - `connectivity_banner.dart`: Event-driven `forward()`/`reverse()` control
  - `enhanced_login_screen.dart`: Programmatic shake animation
  - `animated_success.dart`: Complex programmatic control with external trigger
- **Code Reduction**: ~55% average across migrated files (removed dispose, initState, AnimationController boilerplate)

**Changelog 6.22**: flutter_animate Migration & Dependency Cleanup:
- **Removed 12 Unused Packages** from pubspec.yaml:
  - `easy_localization` - projekt koristi `intl` umjesto toga
  - `photo_view` - nikad implementirano
  - `visibility_detector`, `step_progress_indicator` - nekorišteno
  - `flutter_map`, `flutter_map_marker_cluster`, `geolocator`, `geocoding`, `latlong2` - mape neće biti
  - `scrollable_positioned_list`, `flutter_dotenv`, `universal_io`, `vector_math` - nekorišteno
- **Moved `fake_cloud_firestore`** iz dependencies u dev_dependencies (test-only paket)
- **Kept for future use**: `pdf`, `printing` (fakture/izvještaji), `flutter_animate` (animacije)
- **flutter_animate Migration Phase 1 Complete**:
  - Created `flutter_animate_extensions.dart` - helper methods za AnimationTokens integraciju
  - Migrated `AnimatedEmptyState`: StatefulWidget (135 lines) → StatelessWidget (50 lines) = 63% reduction
  - Migrated `StaggeredEmptyState`: StatefulWidget (164 lines) → StatelessWidget (70 lines) = 57% reduction
  - Total: 299 → 120 lines = **60% code reduction**
  - Zero breaking changes - API remains identical
  - Benefits: No AnimationController disposal needed, no memory leak risk, simpler code

**Changelog 6.21**: Stripe Connect Return URL Routing Fix:
- **Sentry Error Fix**: `permission-denied` errors on `/owner/stripe-return` route
  - **Problem**: After completing Stripe Connect onboarding, Stripe redirects to `/owner/stripe-return`
  - **Root Cause**: Route was never defined in GoRouter, causing 404 fallback and race conditions with auth state
  - **Fix** (`router_owner.dart`):
    - Added `stripeReturn = '/owner/stripe-return'` and `stripeRefresh = '/owner/stripe-refresh'` route constants
    - Added GoRoute handlers that redirect to `OwnerRoutes.stripeIntegration` (`/owner/integrations/stripe`)
  - **Result**: Owner returns to Stripe Integration page after onboarding, where `_loadStripeAccountInfo()` fetches updated status
- **Note**: This fix only affects owner Stripe Connect flow (account linking), NOT widget Stripe payments

**Changelog 6.20**: Bank Account Routing Fix & Bottom Sheet Standardization:
- **Bank Account 404 Routing Fix** (`bank_account_screen.dart`):
  - **Problem**: Navigating Unit Hub → Widget Settings → Bank Transfer → Bank Account → Save caused 404 error
  - **Root Cause**: Hardcoded route string `/owner/integrations/payments` instead of route constant
  - **Fix**: Added `router_owner.dart` import and changed all 3 navigation points to use `OwnerRoutes.unitHub`
  - Lines affected: 121 (after save), 271 (cancel button), 319 (discard dialog)
  - Uses `context.canPop() ? context.pop() : context.go(OwnerRoutes.unitHub)` pattern
- **Bottom Sheet Height Standardization** (`notification_settings_bottom_sheet.dart`):
  - **Problem**: Notification Settings used fixed 600px height while Language/Theme used dynamic percentage
  - **Fix**: Changed to use `ResponsiveSpacingHelper.getBottomSheetMaxHeightPercent(context)`
  - All bottom sheets now use consistent responsive heights:
    - Landscape Mobile: 80% of screen
    - Portrait Mobile: 70% of screen
    - Tablet/Desktop: 60% of screen
- **Serbian to Croatian Localization Fixes** (`app_hr.arb`):
  - Fixed remaining Ekavian (Serbian) words to Ijekavian (Croatian)
  - Examples: "Ocene"→"Ocjene", "Sinhronizuj"→"Sinkroniziraj", "nalog"→"račun", etc.
- **SelectableText for Booking Details**:
  - Booking ID, guest email, and phone number now copyable via long-press
  - Added to `booking_card_header.dart` and `booking_card_guest_info.dart`

**Changelog 6.19**: Bookings Page UX Improvements & Automatic Status Updates:
- **Booking ID Display Fix** (`booking_card_header.dart`, `booking_details_dialog.dart`):
  - Changed from truncated document ID (`#abc123xy`) to user-friendly `booking_reference` (e.g., `BK-2024-001234`)
  - Fallback to document ID if `booking_reference` is null
  - Booking ID now copyable via SelectableText (from previous changelog)
- **iCal Bookings Already Displayed**:
  - Confirmed: NO source filter in repository - iCal bookings automatically shown
  - Table View already has "Source" column with platform badges (Widget, Booking.com, Airbnb, iCal)
  - Timeline Calendar already has platform icon in top-right corner
  - No changes needed - feature already works correctly
- **Email Template Duplicate Greeting Fixed** (`send_email_dialog.dart`):
  - **Problem**: "Poštovani {name}," appeared TWICE - once in Flutter template, once in Cloud Functions
  - **Fix**: Removed greeting from Flutter `getMessage()` method (lines 50-95)
  - Cloud Functions `generateGreeting()` already adds "Poštovani/a {name}," automatically
  - Affects all email templates: confirmation, reminder, cancellation, custom
- **Automatic Booking Status Updates** - NEW scheduled Cloud Function:
  - **Created**: `completeCheckedOutBookings.ts` - auto-completes bookings after checkout
  - **Schedule**: Daily at 2:00 AM (Zagreb timezone) - configurable via `AUTOCOMPLETE_SCHEDULE` env var
  - **Query**: `.where("status", "in", ["confirmed", "pending"]).where("check_out", "<", today)`
  - **Filters OUT**: External/iCal bookings (source: booking_com, airbnb, ical, external) and ID prefix `ical_`
  - **Batch Processing**: 400 docs/batch, max 5000 docs/run, error recovery with individual fallback
  - **Updates**: Sets `status: "completed"` and `updated_at: now()`
  - **Export**: Added to `index.ts` for deployment
  - **Firestore Index**: Added composite index `status` (ASC) + `check_out` (ASC) for collection group query
  - **Logging**: Structured logs with success/failure counts, duration tracking
  - **Benefits**: Owners get accurate historical data without manual status updates

**Changelog 6.18**: Dashboard Rolling Window Periods & Chart Improvements:
- **Period Calculations Changed to Rolling Windows**:
  - **Problem**: Period računanja bila kalendarska (1. dec - 21. dec), što daje nekonzistentne rezultate
    - "Prošlo tromjesečje" pokazivalo MANJE podataka nego "Ovaj mjesec" (nelogično)
    - Periodi nisu bili dinamički - morali se ručno mijenjati svaki dan
  - **Fix**: Rolling windows sa `today minus X dana` logikom
    - `last7Days()`: zadnjih 7 dana (bilo: prošli tjedan)
    - `last30Days()`: zadnjih 30 dana (bilo: kalendarski mjesec)
    - `last90Days()`: zadnjih 90 dana (bilo: kalendarski tromjesečje)
    - `last365Days()`: zadnjih 365 dana (bilo: kalendarskih 12 mjeseci)
  - **Rezultat**: Period sa više dana UVIJEK ima više/jednako podataka
- **Default Period**: Promijenjen sa `currentMonth()` na `last7Days()`
- **Choice Chip Labele Ažurirane**:
  - "Prošli tjedan" → "Zadnjih 7 dana" / "Last 7 days"
  - "Ovaj mjesec" → "Zadnjih 30 dana" / "Last 30 days"
  - "Prošlo tromjesečje" → "Zadnjih 90 dana" / "Last 90 days"
  - "Prošla godina" → "Zadnjih 365 dana" / "Last 365 days"
- **Chart Interakcije Pojednostavljene**:
  - Uklonjen zoom (scroll to zoom) - `horizontalRangeUpdater` removed iz `RectCoord`
  - Dodane vrijednosti na chartovima:
    - Revenue chart: €XXX prikazano iznad svake tačke
    - Bookings chart: broj rezervacija prikazano iznad svakog bara
  - Zadržani hover tooltips za detalje
- **Modified Files**:
  - `unified_dashboard_data.dart`: novi factory methods za rolling windows
  - `unified_dashboard_provider.dart`: `setPreset()` ažuriran za nove periode
  - `dashboard_overview_tab.dart`: chart labels sa vrijednostima, uklonjeni zoom eventi
  - `app_en.arb`, `app_hr.arb`: nove lokalizacije za choice chips

**Changelog 6.17**: Calendar Provider Cache Security Fix & Remember Me Feature:
- **CRITICAL SECURITY FIX - Calendar showing other owner's units**:
  - **Problem**: Owner A logs out, Owner B logs in → sees Owner A's units in Calendar Timeline
  - **Root Cause**: `keepAlive: true` providers cached previous user's data
    - `ownerPropertiesCalendarProvider` and `allOwnerUnitsProvider` used `FirebaseAuth.instance.currentUser`
    - Provider never invalidated on user change because `keepAlive: true` prevents disposal
  - **Fix** (`owner_calendar_provider.dart:20-24`):
    - Changed from `FirebaseAuth.instance.currentUser?.uid` to `ref.watch(enhancedAuthProvider)`
    - Now watches auth state changes → auto-invalidates on login/logout
    - New user gets fresh data, not cached data from previous user
  - **Key Learning**: `keepAlive: true` providers MUST watch auth state if they depend on current user
- **Remember Me / Auto-fill Feature** (AUTH_LOADING_STATES_PLAN.md):
  - Added `flutter_secure_storage: ^9.0.0` dependency
  - New `SecureStorageService` singleton (`lib/core/services/secure_storage_service.dart`)
  - New `SavedCredentials` freezed model (`lib/features/auth/models/saved_credentials.dart`)
  - Login screen auto-fills credentials if "Remember Me" was enabled
  - Credentials saved on successful login (if Remember Me checked)
  - Credentials cleared on logout
  - Platform-specific encryption: Android EncryptedSharedPreferences, iOS Keychain
- **Improved Auth Error Messages**:
  - New localization keys: `authErrorWrongPassword`, `authErrorUserNotFound`, `authErrorInvalidEmail`, etc.
  - Croatian and English translations
  - Generic fallback: `authErrorGeneric` for unmapped errors

**Changelog 6.16**: Stripe Live Payment Tested & Payment Method Display:
- **Stripe Live Payment Successfully Tested**:
  - First live transaction: €0.60 deposit payment
  - Webhook correctly updated booking status to `confirmed`
  - Email confirmation sent to guest
  - Stripe Connect Standard model working: money goes directly to owner
- **Payment Method Display in Booking Details** (`booking_details_dialog.dart`):
  - Added "Payment Method" row: Stripe, Bank Transfer, Cash, Other, Not specified
  - Added "Payment Option" row: Deposit, Full Payment
  - New localization strings in `app_en.arb`, `app_hr.arb`
  - Owners can now see how guests attempted to pay
- **Stripe Minimum Amount Fix** (`stripePayment.ts`):
  - Stripe requires minimum €0.50 for Checkout Sessions
  - Added validation: `Math.max(rawDepositCents, 50)`
  - Small deposits auto-adjusted to €0.50 minimum
- **iCal Import Testing**:
  - Created test iCal files for Booking.com and Airbnb formats
  - Overbooking detection confirmed working (33 conflicts displayed)
- **Timeline Calendar Position Fix**:
  - Fixed UTC vs LOCAL timezone mismatch in booking position calculation
  - `timeline_grid_widget.dart`, `timeline_booking_block.dart` now use `DateTime.utc()`
- **Booking Move Feature Fix** (`firebase_booking_repository.dart`):
  - Fixed `updateBooking()` to handle unit changes with atomic Firestore batch
  - Delete from old path + create at new path in single transaction

**Changelog 6.15**: Stripe Live Mode Setup & Mobile URL Fix:
- **Stripe Live Mode Activated**:
  - Firebase secrets updated: `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET` (Live keys)
  - Webhook endpoint: `https://us-central1-rab-booking-248fc.cloudfunctions.net/handleStripeWebhook`
  - Events: `checkout.session.completed`, `checkout.session.expired`
  - Platform profile completed in Stripe Dashboard
- **Mobile App URL Fix** (`stripe_connect_setup_screen.dart`):
  - **Problem**: `Uri.base` returns empty string on native Android/iOS apps
  - **Error**: "Not a valid URL" when connecting Stripe account from mobile app
  - **Fix**: Added fallback to `https://app.bookbed.io` for Stripe Connect return/refresh URLs
  - Mobile apps now correctly redirect back to owner dashboard after Stripe onboarding

**Changelog 6.14**: Smart Price Mismatch Alerting - completed above

**Changelog 6.13**: Widget Embed Code & Month Display Fix:
- **Iframe Embed Code Improvement**:
  - Embed kod sada koristi `view.bookbed.io` domenu (ne `bookbed.io`)
  - Direktan iframe umjesto script-based embed.js
  - Responsive visina sa `aspect-ratio: 1/1.4; min-height: 500px; max-height: 850px;`
  - Owner samo kopira i zalijepi - radi na bilo kojem sajtu
  - Fajlovi: `embed_code_generator_dialog.dart`, `embed_widget_guide_screen.dart`
- **Month/Year Display Always Visible**:
  - **Problem**: U embedded widgetu, mjesec/godina ("Dec 2025") se nije prikazivalo na uskim iframe-ovima
  - **Uzrok**: `isTinyScreen < 360px` check sakrivao tekst, ali iframe može biti uži od device-a
  - **Fix** (`month_calendar_widget.dart:217-230`):
    - Mjesec/godina se UVIJEK prikazuje (uklonjen `if (!isTinyScreen)` check)
    - Na malim ekranima koristi manji font (`fontSizeXS`) umjesto skrivanja
    - Korisnik uvijek zna koji mjesec gleda

**Changelog 6.12**: Timeline Calendar Scroll Fixes & Turnover Visibility:
- **Scroll Bounce-Back Fix** (Android weak swipe issue):
  - **Problem**: Weak swipes on Timeline Calendar would bounce back instead of scrolling
  - **Root Cause**: `ClampingScrollPhysics.createBallisticSimulation()` returns `null` for low-velocity gestures
  - **Fix**: New `TimelineSnapScrollPhysics` class (`timeline_snap_scroll_physics.dart`):
    - Custom `createBallisticSimulation()` that ALWAYS returns a snap simulation
    - Critically damped spring (no oscillation) for smooth stop at day boundary
    - Low `minFlingVelocity` (10.0) to capture weak Android swipes
- **Feedback Loop Fix** (auto-scroll backwards/forwards):
  - **Problem**: Calendar auto-scrolled continuously after user swipe
  - **Root Cause**: `_updateVisibleRange` → parent updates → `didUpdateWidget` → scroll → loop
  - **Fix** (`timeline_calendar_widget.dart`):
    - Report CENTER of visible range instead of START (prevents position drift)
    - `didUpdateWidget` only scrolls when `forceScrollKey` changes (explicit user action)
    - Increased skip threshold from `visibleWidth/4` to `visibleWidth/2`
- **Toolbar Navigation Fix**:
  - Previous/Next/DatePicker buttons now increment `forceScrollKey++`
  - Required after feedback loop fix to trigger scroll in `didUpdateWidget`
- **Turnover Day Visibility** (`skewed_booking_painter.dart`):
  - Increased `turnoverGap` from 2px to 4px
  - Added 50% opacity diagonal separator lines on check-in/check-out edges
  - Turnover days now clearly visible in Timeline Calendar

**Changelog 6.11**: Flutter Animation Widget Library:
- **New animation widgets** (`lib/shared/widgets/animations/`):
  - `AnimatedEmptyState`: Fade+scale entrance for empty state screens
  - `AnimatedContentSwitcher`: Smooth skeleton→content crossfade transitions
  - `AnimatedCheckmark`: Custom painted checkmark with draw animation
  - `SuccessOverlay`: Full-screen success celebration overlay
  - `HoverScaleCard`, `HoverListTile`: Desktop hover effects with scale+shadow
  - `AnimatedCardEntrance`: Staggered fade+slide entrance for lists
  - `AnimatedDialog`: Scale/slide-up dialog entrance helpers
  - `AnimatedButton`: Press feedback micro-interactions
- **Applied animations**:
  - `owner_bookings_screen.dart`: AnimatedEmptyState for no bookings
  - `notifications_screen.dart`: Staggered empty state with 3 animation controllers
  - `unified_unit_hub_screen.dart`: AnimatedEmptyState for no units
  - `dashboard_overview_tab.dart`: AnimatedEmptyState for chart empty states
  - `lazy_calendar_container.dart`: AnimatedContentSwitcher for skeleton→calendar fade
- **Removed unused packages**: `lottie: ^3.1.0`, `confetti: ^0.8.0` from pubspec.yaml
- **Implementation plan**: `docs/research/ANIMATION_IMPLEMENTATION_PLAN.md`

**Changelog 6.10**: iCal Export Permission-Denied Bug Fix + Missing Index:
- **iCal Export Bug**:
  - **Problem**: iCal export failed with `permission-denied` error when generating .ics files
  - **Root Cause**: `fetchUnitBookings()` query used only `unit_id` filter, but Firestore security rules (Case 3) require `unit_id` + `status` for collection group queries
  - **Fix** (`firebase_booking_repository.dart:13-35`):
    - Added `status` whereIn filter to `fetchUnitBookings()` query
    - Now fetches only `pending`, `confirmed`, `completed` bookings (excludes `cancelled`)
    - Matches security rule Case 3: `('unit_id' in resource.data && 'status' in resource.data)`
  - **Cleanup** (`ical_export_service.dart`):
    - Removed redundant client-side status filtering (now done at query level)
    - Removed unused `enums.dart` import
- **Missing Firestore Index**:
  - **Problem**: `syncReminders.ts` Cloud Function failed with `FAILED_PRECONDITION: The query requires an index`
  - **Query**: `.where("created_at", ">=", ...).where("status", "in", [...])`
  - **Fix**: Added composite index `status` ASC + `created_at` ASC to `firestore.indexes.json` (lines 154-160)
  - **Note**: When combining range (`>=`) and equality/whereIn filters, equality fields must come FIRST in the index

**Changelog 6.9**: Platform Source Display for External Bookings:
- **PlatformIcon Widget** (`lib/shared/widgets/platform_icon.dart`):
  - Reusable widget za prikaz platforme bookinga
  - Ikone: **B** (plava #003580) = Booking.com, **A** (crvena #FF5A5F) = Airbnb, **W** (ljubičasta #7C3AED) = Direct, **🔗** (narandžasta) = iCal/External
  - Static helpers: `getDisplayName(source)`, `shouldShowIcon(source)`
- **Timeline Booking Blocks** (`timeline_booking_block.dart`):
  - Platform ikona u gornjem desnom uglu za external bookinge
  - Automatski offset (28px) ako postoji conflict warning ikona
- **Booking Details Dialog** (`booking_details_dialog.dart`):
  - Dodano "Izvor/Source" polje u Guest Information sekciju
  - Prikazuje se samo za `isExternalBooking` bookinge
  - Nova `_DetailRowWithWidget` klasa za custom child widgets
- **Conflict Messages**:
  - Snackbar u `owner_timeline_calendar_screen.dart` sada prikazuje platformu: "Guest (Booking.com)"
  - `_ConflictWarningBanner` u tooltipima već prikazuje platformu za svaki konflikt
- **Lokalizacija**: `ownerDetailsSource` - "Source" (EN) / "Izvor" (HR)

**Changelog 6.8**: Comprehensive Sentry Integration:
- **Flutter LoggingService** (`logging_service.dart`):
  - `logError()` sada šalje na Sentry via `captureException()` (fire-and-forget, non-blocking)
  - Novi `logNavigation()` method za breadcrumbs
  - `setUser()` za user identification (owner uid + email)
  - `clearUser()` poziva se na logout
- **Flutter NavigatorObserver** (`sentry_navigator_observer.dart`):
  - Automatski logira sve navigacije kao Sentry breadcrumbs
  - Dodano u `router_owner.dart` i `router_widget.dart`
  - Prati: push, pop, replace, remove akcije
- **Cloud Functions logger.ts**:
  - `logError()` automatski šalje na Sentry via `captureException()`
  - Svi errori sada imaju user context ako je `setUser()` pozvan
- **Cloud Functions setUser()** dodano na 17 funkcija:
  - `atomicBooking.ts`, `stripePayment.ts`, `stripeConnect.ts`
  - `icalSync.ts`, `guestCancelBooking.ts`, `verifyBookingAccess.ts`
  - `customEmail.ts`, `resendBookingEmail.ts`, `updateBookingTokenExpiration.ts`
  - `subdomainService.ts`, `emailVerification.ts` (sve 3 funkcije)
  - `airbnbApi.ts`, `bookingComApi.ts`, `passwordHistory.ts` (2 funkcije)
  - `passwordReset.ts`, `revokeTokens.ts`
- Guest/unauthenticated actions koriste: `setUser(null, email)` pattern
- **SKIP**: `authRateLimit.ts` - poziva se PRIJE autentikacije (nema user ID)

**Changelog 6.7**: Clipboard API Error Handling:
- **Problem**: Clipboard.setData() može baciti exception na nekim browserima (Safari u iframe-u)
- **Fix**: Dodano try-catch na sve Clipboard operacije u widget fajlovima:
  - `popup_blocked_dialog.dart`: Pokazuje error snackbar ako kopiranje ne uspije
  - `booking_reference_card.dart`: Tihi fail (referenca je vidljiva na ekranu)
  - `bank_transfer_instructions_card.dart`: Tihi fail (podaci su vidljivi na ekranu)
- **Pattern za buduće Clipboard operacije**:
  ```dart
  try {
    await Clipboard.setData(ClipboardData(text: value));
    if (context.mounted) {
      // Show success
    }
  } catch (e) {
    // Clipboard API can fail on some browsers (e.g., Safari in iframe)
    // Handle gracefully
  }
  ```

**Changelog 6.14**: Smart Price Mismatch Alerting (False Positive Fix):
- **Problem**: Sentry dobivao HIGH severity alert za SVAKI price mismatch, čak i za benigne scenarije:
  - Cached prices na klijentu (€2-5 razlika je normalna)
  - Floating-point rounding (< €0.10 je bezopasno)
  - Owner promijenio cijenu dok je korisnik bio na stranici
- **Rješenje**: Smart threshold u `priceValidation.ts` (line 287-325):
  - Sentry alert SAMO za sumnjive mismatche: `difference > €10` ILI `percentageDifference > 5%`
  - Male razlike (€0.01-10) se loguju u Cloud Logs, ali NE šalju na Sentry
  - Booking i dalje USPIJEVA sa server-calculated cijenom u oba slučaja
- **Stripe Fee clarification**:
  - Stripe fee (1.4% + €0.25) se **SKIDA SA OWNER-A**, ne dodaje se na cijenu
  - Korisnik plaća: `totalPrice = roomPrice + servicesTotal`
  - Owner dobija: `totalPrice - stripeFee` (npr. 170€ → 167.73€)
  - `servicesTotal` parametar se UVIJEK šalje sa klijenta na server za validaciju

**Changelog 6.6**: Security Helper Integration - All Helpers Now Active:
- **logRateLimitExceeded() integration**:
  - `authRateLimit.ts`: Login and registration rate limit events (severity: medium)
  - `atomicBooking.ts`: Widget booking rate limit events
  - `bookingAccessToken.ts`: Token verification rate limit events
  - All rate limit blocks now logged to Firestore + Cloud Logging
- **logPriceMismatch() integration**:
  - `priceValidation.ts`: Price manipulation detection (severity: high → Sentry alert)
  - Logs: unitId, clientPrice, serverPrice, difference, propertyId, dates
- **Security monitoring coverage complete**:
  - All helper functions from `securityMonitoring.ts` now actively used
  - Events flow: Firestore `security_events` + Cloud Logging + Sentry (critical/high)

**Changelog 6.5**: Cloud Functions Performance & Security Monitoring:
- **bookingLookup.ts Strategy 2 optimization**:
  - Problem: O(N×M) sequential queries (~5s for 100 properties × 10 units)
  - Solution: Parallel queries using `Promise.all()` (~500ms for same data)
  - Step 1: Fetch all units for all properties in parallel
  - Step 2: Build list of all booking paths to check
  - Step 3: Check all booking paths in parallel
  - Performance improvement: ~10x faster for comprehensive search fallback
- **Sentry integration for security monitoring**:
  - Critical events (`severity: "critical"`) now sent to Sentry as `fatal` level
  - High severity events (`severity: "high"`) sent as `error` level
  - Enables real-time alerting via Sentry dashboard/email for security incidents
  - Events tracked: webhook signature failures, price mismatch, suspicious bookings
  - Import: `import {captureMessage} from "../sentry";`

**Changelog 6.4**: Timeline Calendar Performance & Navigation Fixes:
- **Month navigation buttons requiring 2 clicks**: Fixed by canceling animation instead of skipping
- **FAB shadow invisible on hover**: `0.5.toInt() = 0` → `(0.5 * 255).toInt()`
- **Excessive rebuilds during scroll**: Dynamic threshold (30 days during animation vs 10 days normally)
- **_getDateRange() optimization**: Added `_cachedFullDateRange` caching (1460 objects generated once)
- **Scroll retry logging**: Simplified to reduce console spam

**Changelog 6.3**: Platform Connections Security Rules & Price Calendar Validation:
- **Permission-denied bug fix za "Označi kao dostupno" bulk akciju**:
  - Problem: Bulk update uspije ("Batch commit successful"), ali permission-denied error se pojavi
  - Uzrok: `platformConnectionsForUnitProvider` query na `platform_connections` kolekciju PRIJE bulk update-a
  - `platform_connections` kolekcija NIJE IMALA Firestore security rules definirana
  - Fix: Dodana nova sekcija u `firestore.rules`:
    ```javascript
    match /platform_connections/{connectionId} {
      allow read: if isResourceOwner();
      allow create: if canCreateAsOwner();
      allow update, delete: if isResourceOwner();
    }
    ```
- **Cross-validacija za min/max polja u price calendar edit dialogu**:
  - Min noći ne može biti veće od max noći
  - Min dana unaprijed ne može biti veće od max dana unaprijed
  - Pokazuje warning snackbar ako korisnik unese nelogičnu kombinaciju
  - Nove lokalizacije: `priceCalendarMinNightsCannotExceedMax`, `priceCalendarMinAdvanceCannotExceedMax`

**Changelog 6.2**: Widget UI Polish & Form Component Alignment:
- **Form component heights ujednačene na 50px**:
  - Verify button: 49px → 50px
  - Verified badge: 51px → 50px
  - Country dropdown: 50px (već bilo OK)
  - TextFormField: ~50px (contentPadding 14px vertical)
- **Skraćeni tekstovi za bolji UX**:
  - "Verify Email" → "Verify" (svi jezici)
  - "Credit Card (Stripe)" → "Credit Card"
  - "Continue to Bank Transfer" → "Bank Transfer"
  - Calendar-only banner: uklonjena druga rečenica o kontaktiranju vlasnika
- **Padding/spacing poboljšanja**:
  - Booking pill bar: dodano 8px horizontalnog paddinga na mobile
  - Month calendar mobile: padding smanjen sa 16px na 8px (left/right)
  - Header content centriran sa jednakim left/right paddingom
  - Info banner: 8px top padding, Contact pill bar: 8px bottom padding (calendar-only mode)
- **Header ikone**: responsive sizing za tiny screens (<360px) - ikone 18px umjesto 20px
- **Contact pill bar**: uklonjen text underline iz kontakt linka

**Changelog 6.1**: Cloud Functions FieldPath.documentId Bug Fix:
- **CRITICAL BUG FIX**: `FieldPath.documentId()` NE RADI sa `collectionGroup()` queries
  - Error: `When querying a collection group and ordering by FieldPath.documentId(), the corresponding value must result in a valid document path`
  - Firestore očekuje PUNI PUT dokumenta (npr. `properties/xxx/units/yyy/bookings/zzz`), ne samo ID (`zzz`)
- **Nova helper funkcija**: `functions/src/utils/bookingLookup.ts`
  - `findBookingById(bookingId, ownerId?)` - tri strategije:
    1. Query po `owner_id` polju (brzo ako je owner poznat)
    2. Comprehensive search kroz sve properties/units (sporije ali uvijek radi)
    3. Fallback na legacy `bookings` collection
  - `findBookingByReference(bookingReference)` - query po `booking_reference` polju
- **Popravljene Cloud Functions**:
  - `resendBookingEmail.ts` - koristi `findBookingById`
  - `customEmail.ts` - koristi `findBookingById`
  - `guestCancelBooking.ts` - koristi `findBookingById`
  - `twoWaySync.ts` - koristi `findBookingById`
  - `updateBookingTokenExpiration.ts` - koristi `findBookingById`
- **Dodan Firestore index**: `owner_id` single-field index za `bookings` collection group
- **PRAVILO**: Nikada ne koristi `FieldPath.documentId()` sa `collectionGroup()` - uvijek query po custom polju

**Changelog 6.0**: Widget Hybrid Loading & Native Splash Update:
- **Hybrid Progressive Loading**: Widget UI prikazuje se ODMAH sa skeleton kalendarom
  - Uklonjeno: BookBed Loader iz `booking_widget_screen.dart`
  - `LazyCalendarContainer` prikazuje skeleton dok se podaci učitavaju
  - `hideNativeSplash()` poziva se u `widget_main.dart` initState
  - Loading vrijeme smanjeno sa ~10-14s na ~4s
- **Native Splash minimalistički dizajn**: Crno-bijela shema umjesto ljubičaste
  - Light mode: `#000000` progress bar, `rgba(0,0,0,0.2)` track
  - Dark mode: `#FFFFFF` progress bar, `rgba(255,255,255,0.2)` track
  - Usklađeno sa BookBed Loader bojama
- **Obrisani fajlovi** (više se ne koriste):
  - `loading_screen.dart`, `smart_loading_screen.dart`, `smart_progress_controller.dart`
  - `loading_screen_test.dart`
- **InteractiveViewer (zoom) testiran i UKLONJEN**:
  - Zoom na kalendaru (1x-2x) testirano ali odlučeno da nije potrebno
  - Responsive dizajn + OS-level zoom već zadovoljavaju accessibility potrebe

**Changelog 5.9**: Booking Dialog Race Condition Fix:
- **Problem**: Booking details dialog otvarao se 2-3 puta kada korisnik navigira sa notifications page na bookings page
- **Uzrok**: Async race condition između `setState()`, `router.go()` i `addPostFrameCallback()`
- **Fix** (`owner_bookings_screen.dart`):
  1. Uklonjen `!_isLoadingInitialBooking` check koji je blokirao dialog opening
  2. URL query params čiste se PRIJE resetovanja state flags-a (ne poslije)
  3. Dodani `!_dialogShownForBooking` checks na SVE putanje koje setuju `_pendingBookingToShow`
  4. `_pendingBookingToShow = null` postavlja se odmah nakon što se `_dialogShownForBooking = true` setuje
  5. Dodatni guard za `pendingBookingIdProvider` setting iz URL-a
- **Ključni princip**: Redoslijed cleanup-a je kritičan - URL mora biti očišćen PRIJE nego što se resetuju flags-ovi

**Changelog 5.8**: Analytics Security Rules Fix:
- **Problem**: Analytics page vraćala `permission-denied` error za `collectionGroup('bookings')` query
- **Uzrok**: Firestore security rules nisu dozvoljavale authenticated korisnicima query po `unit_id` + `check_in`
- **Fix**: Dodana nova rule u `firestore.rules` za analytics queries (Case 2)
- Dodano `print()` logging u analytics provider/repository za debug u release mode
- Index `bookings: unit_id + check_in` (Collection Group) već postojao - problem bio samo u rules

**Changelog 5.7**: Bug Fixes & Error Boundaries:
- ErrorBoundary wrapperi dodani na Loader widgete u `router_owner.dart` (PropertyEditLoader, UnitEditLoader, UnitPricingLoader, WidgetSettingsLoader)
- Warning dialogs integrirani: `UpdateBookingWarningDialog` u edit_booking_dialog, `UnblockWarningDialog` u price_list_calendar
- Timezone fix: `DateNormalizer.normalize()` u validateAdvanceBooking umjesto lokalnog DateTime
- Language fallback: `🌐` globe emoji za nepoznate jezike umjesto hardcoded `🇭🇷`
- Skeleton loader: named constants umjesto magic numbers u month_calendar_skeleton
- Async timeouts utility već postoji (`async_utils.dart`, `timeout_constants.dart`) - dokumentirano

**Changelog 5.6**: PWA install button i connectivity banner widgeti, JS/Dart interop za PWA install prompt.

**Changelog 5.5**: Email System Reorganization:
- Payment deadline: 3 dana → **7 dana** (atomicBooking.ts:870)
- Check-in reminder: 1 dan → **7 dana** prije
- Payment reminder: **Dan 6** (1 dan prije isteka)
- Uklonjeni `-v2` suffix iz template imena
- Premješteni template-i iz `version-2/` u `templates/`
- Uklonjen `suspicious-activity.ts` (TODO za budućnost)
- Nova dokumentacija: `EMAIL_SYSTEM.md`

**Changelog 5.4**: Stripe Security Improvements implementirane:
- Rate limiting na `createStripeCheckoutSession` (10 req/5min per IP)
- Stripe Connect account verification (`charges_enabled`, `card_payments`, `transfers`)
- Security monitoring (`securityMonitoring.ts`) - logira kritične security evente
- Firestore rules za bookings: selektivni pristup (owner, widget calendar, Stripe polling, booking view)
- Error message cleanup - generičke poruke za klijente, detalji samo u logovima

**Changelog 5.3**: Owner email UVIJEK se šalje za svaki booking (Bug Archive #2) - `forceIfCritical=true` u atomicBooking.ts. Dok nema push notifications, owner ne smije propustiti rezervaciju.

**Changelog 5.2**: Keyboard fix threshold usklađivanje (JS/Dart 12%/15%), window.resize fallback, EPC QR validacija sa currency parametrom.

**Changelog 5.1**: Dodana Firestore indexi sekcija, browser_detection conditional imports, upozorenje o dart:js_interop.

**Changelog 5.0**: Firestore collection group query bug fix - NE koristiti FieldPath.documentId sa collectionGroup(), dodano sessionId u cross-tab messaging.

**Changelog 4.9**: Android Chrome keyboard dismiss fix (Flutter #175074) - JavaScript "jiggle" method + Dart mixin za sve forme.

**Changelog 4.8**: Widget snackbar boje usklađene sa calendar statusima.

**Changelog 4.7**: Multi-platform build dokumentacija - Android release mode, conditional imports, dependency verzije.

**Changelog 4.6**: URL slug sistem za clean URLs (`/apartman-6` umjesto query params).

---

## Changelog 5.9: Performance & Security Optimizations (2026-01-13)

**Portirane optimizacije iz feature brancheva:**

### Performance
| Optimizacija | Datoteke | Korist |
|--------------|----------|--------|
| `keepAlive: true` calendar provider | `owner_calendar_provider.dart` | Nema re-fetch pri navigaciji |
| 3m/9m date range (umjesto 12m/12m) | `owner_calendar_provider.dart` | ~75% manje Firestore reads |
| `unitToPropertyMap` passthrough | `firebase_owner_bookings_repository.dart` | Eliminira N+1 queries za iCal |
| `aggregate(sum())` za revenue | `firebase_revenue_analytics_repository.dart` | 1 query umjesto 100+ reads |
| `collectionGroup.count()` | `admin_users_repository.dart` | N+1 → 1 query |
| Skip redundant profile fetch | `enhanced_auth_provider.dart` | Nema double-fetch na login |
| Memory cache za rate limit | `rate_limit_service.dart` | Manje Firestore reads za locked accounts |

### Security
| Fix | Datoteke | Opis |
|-----|----------|------|
| owner_id integrity check | `firestore.rules` | Sprječava fake owner_id injection |
| Log redaction (GDPR) | `logging_service.dart` | Redaktira passworde, tokene, API keys |
| Token masking | `ical_export_service.dart` | Maskira Firebase Storage tokene |

**Preskočene grane:** `bolt-optimize-booking-retrieval` (pagination rizik), `bolt-property-global-store` (veliko refaktoriranje), `jules/security-audit-fixes` (XSS već riješen), `chore/weekly-dependency-updates` (ručno updatati).
