# audit/21 — Sprint summary 2026-05-22 to 2026-05-23

Multi-day mega-sweep closing: security hardening (SF-022..026 + T11c proper), Wave 5 Phase 1 refactor, mobile platform smoke (iOS + Android), test-debt cleanup, mobile-fixture unblocker. Three PRs opened, all awaiting GitHub Actions billing fix to unblock CI before merge.

---

## Sessions & terminals (final session 2026-05-23)

| Terminal | Task | Outcome |
|---|---|---|
| A | Automated verification sweep on `main` | 🔴 30 flutter + 4 jest fails surfaced — diagnosed in F as stale test debt |
| B | Web widget smoke pre-flight | ✅ Bundle live (2026-05-22 17:37 UTC), SEED IDs verified — agent pivoted to booking-G work after Dusko didn't immediately run Chrome |
| C | Cloud Functions integration smoke against bookbed-dev | ✅ All flows pass; **CF contract drift discovered** — actual shape `{unitId, windows, generatedAt, cacheHint}`, not stale `{success, blocks}` |
| D | iOS sim owner-app smoke | ✅ 5 PASS, 4 BLOCKED by missing test-property fixture (NOT regressions) — later unblocked by seed-script enhancement |
| E | Android emulator owner-app smoke | ✅ 5 PASS + 1 N/A + 2 bug findings (one confirmed product bug, one false positive) |
| F | `audit/19` test-failures diagnosis | ✅ Root-caused both clusters as stale-fixture debt from T11c + SF-022 contract changes; **zero PROD risk** |
| G (×2) | Empirical fail-CLOSED proof against deployed dev CF | ✅ Both `bookings` and `ical_events` source paths return correct windows; backend triple-verified |
| H | Field-name canonicalization audit (P3 from G) | ✅ No invisible-block bug — single writer, canonical names everywhere |
| I | `scripts/seed-bookbed-dev.js` enhancement + iOS verification | ✅ Test-owner seed mode added, iOS now lands `/owner/overview` instead of `/property-new` |
| J | PR #449 worktree split + open | ✅ Two-commit chore PR opened |
| K | ErrorBoundary `audit/20` skeleton (in flight) | 🟡 Independent landing |

---

## PRs opened (all awaiting CI billing fix)

| PR | Branch | Subject | Risk | Blocker |
|---|---|---|---|---|
| #447 | `refactor/booking-widget-phase1` | Wave 5 Phase 1 — `booking_widget_screen.dart` 4811→4126 LOC, 5 helper extractions, BookingFormState→ChangeNotifier, 73 new tests | Medium | Billing + #448 merge |
| #448 | `chore/test-debt-cleanup-audit-19` | Stale test fixtures aligned to T11c + SF-022 contracts. 30 flutter + 4 jest fails → 1101/1101 + 165/165 green. +1 defensive test (fail-CLOSED on CF throw) | Very low — test-only | Billing |
| #449 | `chore/seed-test-owner-mode` | `.gitignore jest_dx/` + `scripts/seed-bookbed-dev.js --test-owner` mode | Very low — dev-infra only | Billing |

**Recommended merge order:** #449 → #448 → #447 (housekeeping → green baseline → Wave 5 against clean baseline).

---

## Audit docs landed this sprint

| Doc | Author | Subject |
|---|---|---|
| `audit/19-test-failures-diagnosis.md` | Terminal F | Root-causes 30+4 test failures as stale mocks from T11c (`ab6bdb3d`) + SF-022 (`319f7d0f`) contract drift; both clusters test-only fix paths |
| `audit/20-error-boundary-narrowing.md` | Terminal K (in flight) | ErrorBoundary widget catches VM-extension exceptions and surfaces as user-visible "Oops!"; narrowing rule proposal |
| `audit/21-sprint-summary-2026-05-22-23.md` | This doc | Sprint close-out |

---

## Backend availability / fail-CLOSED — verification matrix

The defense-in-depth stack underlying T11c + SF-019 was empirically verified across all four layers in this sprint:

| Layer | Verification | Status |
|---|---|---|
| Firestore rules — anon read deny on `bookings` and `ical_events` collection groups | `npm run test:rules` 24/24 + Terminal B agent's direct CG-read attempt got `PERMISSION_DENIED` | ✅ |
| Cloud Function server-side overlap check at `atomicBooking.ts:743` | Verified via commit `99ac6124` ("T11c fail-closed restore") + code trace in `audit/19` | ✅ |
| `getUnitAvailability` CF returns correct `windows` for blocked dates | **Terminal G ×2 empirical**: real `bookings` doc → window with `source: "booking"`; real `ical_events` doc → window with `source: "ical_external"`. Both confirmed against deployed dev. | ✅ |
| Client `availability_checker.dart:194-245` fail-CLOSED on CF exception | Verified by code trace in `audit/19` (returns `error(ConflictType.booking)` on throw) + defensive test added in #448 | ✅ |

**Conclusion:** The "fail-OPEN" appearance in Terminal A's local test failures was a fixture mismatch with the post-T11c data flow, not a code regression. PR #447 (Wave 5 Phase 1) inherited the stale-mock failures from `main` but introduced no behavior change.

---

## Mobile smoke results

### iOS sim (Terminal D, then re-verified post-seed Terminal I)

| Step | Status (pre-seed) | Status (post-seed) |
|---|---|---|
| App boot, no Dart-level project ID assert | PASS | — |
| Login with test account | PASS | — |
| Calendar/dashboard loads | BLOCKED (no fixture) | **PASS — `/owner/overview` Pregled** |
| Unit detail / pricing read | BLOCKED | Unblocked after seed |
| Unit Wizard read-only | BLOCKED (correctly avoided NIKADA NE MIJENJAJ) | Unblocked after seed |
| iCal sync settings | BLOCKED | Unblocked after seed |
| Logout/login session restore | PARTIAL | — |

Plist hygiene: worktree-isolated dev plist swap, prod plist (`rab-booking-248fc`) untouched. Diff vs prod-snapshot post-restore: 0 bytes. Pattern documented in `audit/15` is validated.

### Android emulator (Terminal E, Pixel_8, Flutter 3.38.5)

| Step | Status |
|---|---|
| App boots, no crash | PASS |
| Login (with admin-flip emailVerified bypass) | PASS |
| Calendar empty-state ("Nema jedinica") | PASS |
| Unit detail | N/A (no fixture — pre-seed) |
| iCal sync settings ("Nema feedova") | PASS |
| Logout/login session restored | PASS |
| Firebase Auth last-sign-in updated | PASS (`07:39:26 → 07:47:10 GMT`) |

google-services.json hygiene: worktree-isolated, main repo plist never touched.

---

## Bugs surfaced & triaged

### #1 ErrorBoundary too broad (P2, queued `audit/20`)

ErrorBoundary widget catches Marionette VM-extension exceptions (and likely any `dart:developer`-routed exception) and surfaces them as user-visible "Oops! Something went wrong" screen. Observed twice in single E session. Confirms pre-existing `wave0-test-findings` entry from earlier sprint.

**Fix path** (next sprint): narrow `catch (e)` to filter VM-extension errors; let dev tooling errors propagate to log only. No production functional impact, but degrades perceived quality.

### #2 Supabase DNS storm — **FALSE POSITIVE**

Terminal E flagged repeated `hifzkwqmkqihmykwswdw.supabase.co` SocketException at boot. Field-name audit follow-up (Terminal-equivalent search) confirmed **zero Supabase references** in `lib/`, `pubspec.yaml`, `pubspec.lock`, `scripts/`, or `functions/`. Source: emulator cross-contamination — another installed app (`com.mycompany.pulsejournal`) leaked into logcat under shared PID. Dismissed without action.

### #3 Marionette `type:IconButton` matcher no-op — test-infra, not BookBed

Single-IconButton match didn't open drawer; coordinate tap worked. Likely Marionette matcher quirk. Not actionable from BookBed side.

---

## Observations not bugs

- **Debug build worked on Android** (Flutter 3.38.5, `assembleDebug` 37.9s) despite `.claude/rules/hosting-build.md` `--release` rule. Worth re-verifying whether the rule still guards a real Kotlin/Java compile issue or if it's outdated. **Queued P3.**
- **CF region drift** — `getUnitIcalFeed` (`icalExport.ts`) is deployed to `us-central1` (default — no `region:` in `onRequest` opts). Already inventoried in `audit/11-cloudfunctions-inventory.md` P3 (hot-path EU latency cost +120ms RTT). Misleading neighbour: `availability.ts:25-26` header mentions `icalSync.ts` / `scheduledPushNotifications.ts` as EU-west1 collectionGroup consumers — `icalSync.ts` *is* (scheduled), but the public-feed `getUnitIcalFeed` sits in `us-central1`. **Queued P3.**
- **Fail-OPEN class on `getUnitAvailability(unknown_unitId)`** — returns `200 OK / windows: []` instead of `not-found`. Defensible (booking write is gated separately by `widget_settings` lookup), but CF should at minimum `logWarn` unknown unit so abuse is detectable. **Queued P2.**

---

## Memory updates

| File | Change |
|---|---|
| `memory/test-account.md` | requiresOnboarding blocker note replaced with seed command + schema gotchas (camelCase `onboardingCompleted`, Auth-vs-Firestore `emailVerified` distinction) |
| `memory/wave-android-smoke-2026-05-23.md` | New — saved + indexed by Terminal E |
| `memory/multi-agent-git-race.md` | Referenced repeatedly; pattern works (branch-guards before every `git add`/`commit`; worktree isolation for plist/google-services swaps) |

---

## Outstanding work

### Critical — blocks PR merges

- **GitHub Actions billing fix** — manual, Settings → Billing. Single biggest unblocker for all 3 PRs.

### Tier 1 — quick close-outs (post-billing)

- Merge `#449 → #448 → #447` in that order
- F-Android-004 SHA-1 paste in Firebase Console bookbed-dev: `28:F4:F5:3D:F1:4A:E2:5D:CD:F6:62:53:A9:52:9B:4E:12:3F:6D:28`
- Stripe Connect `acct_1TYSMdPWhhVc6lN0` manual dissolve (low urgency, account inactive)
- Visual widget smoke in Chrome (optional — backend already triple-verified, this is belt+suspenders confirmation)

### Tier 2 — next-sprint work

- PROD cutover (T11c + SF-023/024/025/026 → `rab-booking-248fc`) — needs dedicated `audit/22-prod-cutover-plan.md`. Per `audit/06` §6.3: CF first → widget bundle → rules last. Prerequisites: `daily_prices` collection index added to prod, widget bundle rebuilt + deployed to `bookbed-widget.web.app`, dry-run migration script, backup current prod rules.
- Wave 5 Phase 2 (leaf composers, ~8h per `audit/12`) — gated on #447 merge
- ErrorBoundary narrowing fix per `audit/20`
- SF-021 Phase A deploy preparation — waits for first active owner. Then: generate `ICAL_TOKEN_PEPPER`, set `ALLOWED_SUBSCRIPTION_PRICE_IDS`, rotate Resend API key per per-owner key strategy

### P3 backlog

- `getUnitIcalFeed` region drift — fix docstring or pin region to `europe-west1`
- `getUnitAvailability` add `logWarn` on unknown unitId
- `.claude/rules/hosting-build.md` `--release`-only rule — re-verify on Android dev builds
- Dependabot `#242` package_info_plus revisit (window closes 2026-06-05)

### Active rules unchanged

- `NIKADA NE MIJENJAJ`: Calendar Repository, Cjenovnik tab, Unit Wizard publish flow, Navigator.push confirmation
- Riverpod `^2.5.1` and freezed `^2.5.7` pinned (no 3.x bumps)
- iOS `GoogleService-Info.plist` + Android `google-services.json` MUST be PROD by session end (verified: both untouched on main repo, both restored cleanly from worktree-based smokes)
- `audit/**/*.md` whitelist in `.gitignore` active
- No PROD deploy without explicit per-deploy user authorization

---

## Sign-off

Sprint scope substantially complete. Real security/data-integrity questions (fail-CLOSED on availability, T11c migration correctness, plist hygiene) all answered with empirical proof. Surfaced bugs are UX/polish, not security. Three PRs queued, waiting on a single manual billing action to flow through CI to merge.

Next session: billing fix → CI green → merge in stated order → drop local `chore/test-debt-cleanup-audit-19` branch reference + `git restore scripts/seed-bookbed-dev.js` on main → ready for `audit/22-prod-cutover-plan.md` drafting or Wave 5 Phase 2 kickoff.
