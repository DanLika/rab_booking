# audit/83 — Test coverage expansion (2026-05-29)

**Branch**: `ops/test-coverage-expansion` (worktree `/tmp/bb-tcov-wt`)
**Base**: `origin/main` @ `87cdfa48` (post #548)
**Scope**: tests only + no source changes
**Time budget**: ~90 min single PR

---

## Goal

Close the biggest coverage gaps in critical paths — booking lifecycle, T11c
availability CF, anon-DoS login lockout, scheduled cleanup jobs, and the
shared `findBookingById` helper that every booking-write CF depends on.

Spec target: **+5% overall coverage OR +20 new test cases**.
Delivered: **+80 new test cases** (+69 jest, +11 flutter) and **+3.54 pts
statements / +3.60 pts lines** on the functions side.

---

## Baseline → After

### functions (jest)

| Metric | Before | After | Δ |
|---|---|---|---|
| Test count | 318 | 387 | **+69** |
| Statements | 65.67% | **69.21%** | +3.54 pts |
| Branches | 52.62% | **55.44%** | +2.82 pts |
| Functions | 67.88% | **70.54%** | +2.66 pts |
| Lines | 66.29% | **69.89%** | +3.60 pts |

### flutter

| Metric | Before | After | Δ |
|---|---|---|---|
| Test count | 1205 | 1216 | **+11** |
| Lines | 18.72% | 18.77% | +0.05 pts |

All 14 baseline jest suites + 5 new suites pass. All 1216 flutter tests pass.

---

## Per-file deltas (0% → covered)

| File | Before | After | Δ | Test file |
|---|---|---|---|---|
| `functions/src/bookingActions.ts` | 0% | **97.11%** | +97.11 | `test/bookingActions.test.ts` (21 tests) |
| `functions/src/availability.ts` | 0% | **85.85%** | +85.85 | `test/availability.test.ts` (13 tests) |
| `functions/src/loginLockout.ts` | 0% | **100%** | +100.00 | `test/loginLockout.test.ts` (16 tests) |
| `functions/src/cleanupExpiredPendingBookings.ts` | 0% | **93.33%** | +93.33 | `test/scheduledBatch.test.ts` (4 tests) |
| `functions/src/completeCheckedOutBookings.ts` | 0% | **88.52%** | +88.52 | `test/scheduledBatch.test.ts` (6 tests) |
| `functions/src/utils/bookingLookup.ts` | 0% | **100%** | +100.00 | `test/bookingLookup.test.ts` (9 tests) |
| `lib/features/widget/data/models/availability_window.dart` | 9.09% | ~100% | +90.91 | `test/features/widget/data/models/availability_window_test.dart` (11 tests) |

7 production files moved from untested (or near-zero) into a high-coverage
band in a single PR.

---

## F-67-01 (audit/67) class — end-to-end coverage closed

The biggest qualitative win. `bookingActions.test.ts` exercises every
state-machine edge the pre-#549 direct-write flow silently swallowed:

### approveBooking
- Unauthenticated caller → `unauthenticated` HttpsError
- Missing / empty `bookingId` → `invalid-argument`
- Booking not found via `findBookingById` → `not-found`
- Booking missing `property_id` → `failed-precondition`
- Ownership mismatch (caller ≠ `properties.owner_id`) → `permission-denied`
- Status not `pending` → `failed-precondition` (`"not eligible"`)
- Happy path: `pending → confirmed`, stamps `approved_at` + `updated_at`

### rejectBooking
- Default reason `"Rejected by owner"` when none provided
- Trimmed custom reason preserved
- Non-string reason → `invalid-argument`
- Reason > 500 chars → `invalid-argument`
- Empty-trimmed reason falls back to default
- Status transition: `pending → cancelled` with `rejection_reason` +
  `rejected_at` stamps

### cancelBooking — refund leg (the F-67-01 "cancel + refund" sub-case)
- **Idempotent already-cancelled**: short-circuits, no update, no Stripe
  refund call, returns the recorded `refund_amount` / `refund_status`
- **Pending + paid via Stripe**: writes `refund_status = pending_stripe` +
  `refund_amount` inside the Firestore transaction, THEN
  `processStripeRefund` is called with `cancelledBy: "owner"` and the
  payment-intent id (mirrors `guestCancelBooking` exactly)
- **Confirmed + bank-transfer paid**: writes `pending_manual` and NEVER
  calls Stripe
- **Confirmed + unpaid (paid_amount = 0)**: writes `not_applicable`
- **Completed booking**: rejected by `loadOwnedBookingForAction` allowed-
  status gate
- Non-owner cancel attempt → `permission-denied`
- 500-char limit on cancellation reason
- Default reason `"Cancelled by owner"` when omitted

### completeBooking transition
Not added — the BookBed source has no `completeBooking` callable. The
`confirmed → completed` transition happens via the scheduled
`autoCompleteCheckedOutBookings` CF (daily 02:00 Zagreb), which is now
**88.52%** covered: happy-path batch update + external/iCal filter +
`ical_` ID prefix filter + batch-commit-fails-fallback + all-filtered
short-circuit, all under `scheduledBatch.test.ts`.

If we want a direct callable for owner-initiated complete, that's a
follow-up PR (source + tests together). Out of scope for this audit per
"NO refactor of production code beyond bug fixes".

---

## Other classes covered

### F-50-02 (audit/55, PR #517) — loginLockout state machine
`loginLockout.test.ts` covers all 3 callables:
- `recordLoginFailure`: empty / non-string email rejection, IP rate-limit
  rejection, first-failure state creation, increment-on-subsequent,
  lockout at MAX_ATTEMPTS=5 with `lockedUntilMs ≈ now + 15 min`,
  auto-reset after `ATTEMPT_RESET_MS` of inactivity
- `getLoginLockoutStatus`: clean state for unknown email, locked state
  with `lockedUntilMs`, auto-reset on read past reset window, IP
  rate-limit, invalid email
- `clearLoginAttempts`: unauth caller rejection, missing email rejection,
  cross-tenant clear attempt (`token.email !== request email`) →
  `permission-denied`, happy path

### T11c — `getUnitAvailability` CF
`availability.test.ts` covers all 3 sources + boundary clipping + PII
strip:
- Input validation (missing propertyId / unitId, unparseable / inverted /
  > 366-day range)
- Per-(unit, ip) rate limit
- Empty-data happy path returning `windows: []` with `cacheHint = 30`
- Three-source merge: booking + manual_block + ical_external, sorted by
  start
- **PII strip**: `guest_email` / `guest_name` are NEVER present in any
  returned window — asserted via `JSON.stringify` regex
- Platform attribution: preserved only for `ical_external`
- Echo skip: `status = "confirmed_echo"` events excluded
- Range clipping: windows entirely before requested start, entirely
  after requested end → dropped
- Bookings missing `check_in` or `check_out` → filtered out
- Firestore `Timestamp` (`.toDate()`) interop

### Scheduled batch jobs
`scheduledBatch.test.ts` covers both jobs identically:
- `cleanupExpiredStripePendingBookings`: empty result, happy-path batch
  delete, batch-commit-fails → per-doc fallback, partial-failure ID
  tracking
- `autoCompleteCheckedOutBookings`: empty result, external-source
  filter (`Airbnb` / `booking_com` / `ical` / `external`), `ical_`-ID
  prefix filter, all-filtered short-circuit, batch-commit-fails → per-doc
  fallback, happy-path `status = completed` batch write

### Shared helper — `findBookingById` / `findBookingByReference`
`bookingLookup.test.ts` covers all 3 strategies:
- Strategy 1 (owner_id collection group query) finds doc by exact id +
  ignores decoy docs (proving the `FieldPath.documentId()` bug guard)
- Strategy 2 (parallel `properties/<p>/units/<u>/bookings/<id>` search)
  finds doc in correct location
- Strategy 3 (legacy top-level `bookings/<id>` collection) fallback
- `findBookingByReference` CG hit + legacy fallback

### Flutter — `AvailabilityWindow` model
`availability_window_test.dart` (11 tests):
- `fromWire`: 3 explicit mappings (`booking` / `manual_block` /
  `ical_external`) + 2 fail-safe paths (unknown / empty → defaults to
  `booking`, matches source behaviour)
- `fromJson`: booking / ical_external / manual_block parsing, UTC
  coercion of non-UTC ISO, null-platform handling
- Constructor preserves explicit fields

---

## Source changes

**Zero**. All five new functions test files + one new flutter test file
are additions under `test/`. No production code touched.

---

## Verification

```bash
cd functions && npx jest               # 387 / 387 pass (was 318)
cd .. && flutter test                   # 1216 / 1216 pass (was 1205)
cd functions && npx jest --coverage     # All files 65.67 → 69.21 stmts
```

Coverage tables captured in
`/tmp/jest-cov.txt` (baseline) and
`/tmp/jest-cov-after.txt` (post-PR).

---

## Out-of-scope / follow-ups

- **`stripePayment.ts` 53.26%** — webhook event handlers
  (`charge.refunded`, `customer.subscription.*`, `invoice.paid`,
  `invoice.payment_failed` added per audit/68 §1) are still uncovered.
  Each one needs a `constructEvent` + downstream Firestore write fixture
  ≥ 50 LOC; deferred to a focused PR.
- **`atomicBooking.ts` 73.34%** — the daily_prices restriction loop
  (lines 813-941: `available=false`, `block_checkin`, `min/max nights`,
  `min/max days advance`) is uncovered. Worth a dedicated PR mirroring
  `priceValidation.ts` coverage style.
- **`icalSync.ts` 61.20%** — the interval-subtraction `save_trimmed`
  path is partially covered by `echoDetection.test.ts`; the full feed
  ingestion (fetch → parse → echo → write) is not. Defer.
- **`bookingHelpers.ts` 24.13%** — lowest critical-path file in the
  baseline. `fetchPropertyAndUnitDetails` + email-related helpers.
- **Flutter `firebase_booking_calendar_repository.dart` 47.98%** —
  Already has the largest test file in the project (`firebase_booking_calendar_repository_test.dart`).
  Marginal returns on more tests; T11c sub-cases (rate-limit retry,
  cache invalidation) would be the natural extension.
- **Flutter `firebase_availability_repository.dart` 0%** — wraps
  FirebaseFunctions HttpsCallable. Needs a `FirebaseFunctions` mock
  (mocktail) to test without Firebase init. Deferred — single-class file,
  23 LOC, ROI lower than the test mock setup cost.

---

## Process notes

- **`firebase-functions/params` mock with `cors: true`**: callables that
  set `cors: true` go through a `params.Expression instanceof` check in
  `node_modules/firebase-functions/lib/v2/providers/https.js:152`. The
  minimal mock `{defineSecret: () => ({...})}` returns `undefined` for
  `Expression`, which throws `Right-hand side of 'instanceof' is not an
  object` at module load. Fix: spread `jest.requireActual("firebase-
  functions/params")` so `Expression` is preserved. Pattern documented
  for all five new test files.
- **`admin.firestore.FieldValue.serverTimestamp()` mocking**: the
  callable `update({approved_at: admin.firestore.FieldValue.serverTimestamp()})`
  uses the `admin` import from `firebase-admin` directly, NOT the
  re-export from `./firebase`. Tests assert the field is `toBeDefined()`
  rather than equal to a stub sentinel, since the actual `firebase-admin`
  is not mocked.
- **`onCall` wrapper** — `firebase-functions-test`'s `wrap()` works for
  both `onCall` (auth + request shape) and `onSchedule` (no args), letting
  the same test harness exercise scheduled CFs.
- **No regressions**: every pre-existing test file still passes
  unchanged. Coverage on already-covered files (e.g. `atomicBooking.ts`
  73.34%) didn't move, confirming the new tests touched only their
  dedicated files.

---

## Branch + PR

- worktree: `/tmp/bb-tcov-wt`
- branch: `ops/test-coverage-expansion`
- base: `origin/main` (`87cdfa48`)
- commit subject: `test: expand coverage on critical paths — +69 jest, +11 flutter (+3.5% stmts)`
