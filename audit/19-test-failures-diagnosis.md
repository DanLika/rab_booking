# audit/19 — Test failures diagnosis (2026-05-23)

Pre-flight: branch `main`, HEAD `8af81ed1` (CHANGELOG 6.83). Read-only investigation. No code changes, no commits, no deploys.

Two failure clusters from Terminal A:

- **flutter test**: 30 failed / 1070 passed — confined to 3 widget-data files
- **functions npm test**: 4 failed / 161 passed — all in `test/stripeConnect.test.ts`

Both clusters are **stale test debt** from prior security hardening commits. Neither indicates a production regression.

---

## Cluster 1: `availability_checker` fail-OPEN appearance + 2 sibling files

**Failing files (all in `lib/features/widget/data/`):**

| File | Failed | Total |
|---|---|---|
| `helpers/availability_checker_test.dart` | varies | many |
| `helpers/booking_price_calculator_test.dart` | ~4 | 27 |
| `repositories/firebase_booking_calendar_repository_test.dart` | ~26 | 17+ groups |

(30 failed across these three.)

### Root cause: stale mocks — tests still write to client-readable collections that the helper no longer reads.

T11c (commit `ab6bdb3d`, 2026-05-22) migrated all booking + iCal availability reads to the `getUnitAvailability` Cloud Function callable. The client `AvailabilityChecker.check()` no longer queries `collectionGroup('bookings')` or `collectionGroup('ical_events')` — those were collapsed into one CF call that returns PII-stripped `AvailabilityWindow` records.

Tests inject a `_FakeAvailabilityRepository` whose `windows` field defaults to `const []`. They then write a booking doc into `fakeFirestore.collection('bookings')` and call `checker.isAvailable(...)`. Because the checker no longer reads `fakeFirestore` for bookings, the fake repo's empty `windows` list is the only signal — checker sees no conflict → returns `isAvailable: true` → test expects `false` → fail.

### Evidence

`lib/features/widget/data/helpers/availability_checker.dart:194-245`:

```dart
// T11c (2026-05-22): bookings + iCal now BOTH come from the same CF call.
// Single fetch dedups the network round-trip. CF failure short-circuits
// to fail-CLOSED ...
late final List<AvailabilityWindow> cfWindows;
try {
  cfWindows = await _availabilityRepo.fetchAvailability(...);
} catch (e) {
  unawaited(LoggingService.logError(...));
  return AvailabilityCheckResult.error(ConflictType.booking);  // fail-CLOSED
}
var result = _checkBookingsAgainstWindows(windows: cfWindows, ...);
```

`test/features/widget/data/helpers/availability_checker_test.dart:796-819` (typical):

```dart
test('returns false when not available', () async {
  await fakeFirestore.collection('bookings').add({
    'unit_id': 'unit123',
    'status': 'confirmed',
    ...
  });
  final isAvail = await checker.isAvailable(...);
  expect(isAvail, isFalse);   // FAILS — checker reads `fakeRepo.windows` (empty), not the fake firestore
});
```

The fake repo:

```dart
class _FakeAvailabilityRepository implements IAvailabilityRepository {
  List<AvailabilityWindow> windows = const [];
  @override
  Future<List<AvailabilityWindow>> fetchAvailability({...}) async => windows;
}
```

No test seeds `fakeRepo.windows = [AvailabilityWindow(source: booking, ...)]`, so every booking-overlap assertion now compares against an empty CF response.

### Risk on PROD: **NONE**

This is a **test-only** stale-mock failure. The checker is correctly **fail-CLOSED** on CF error and correctly checks the CF-supplied windows on success:

1. `check()` on CF exception → returns `AvailabilityCheckResult.error(ConflictType.booking)` (`isAvailable: false`) — verified by commit `99ac6124` ("T11c fail-closed restore — CF failure must reject"). Commit message also flags that the server-side `atomicBooking.ts:743` does its own overlap check during the booking transaction, so even an upstream client fail-open is a UX-not-security regression.
2. CF call itself runs server-side over admin SDK and honors all Firestore boundaries.
3. Anonymous reads on `bookings` / `ical_events` are denied at the rules layer (verified by 24/24 `npm run test:rules`).

The `[E]` markers in the Terminal A failure block (e.g. `'AvailabilityChecker isAvailable returns false when not available'`) reflect: "the fake repo returned no blocks, so the checker said available, but the test wrote a booking to fakeFirestore expecting that to count" — a mismatched fixture, not a code regression.

`booking_price_calculator_test.dart` failures inherit the same root cause via its dependency on `AvailabilityChecker` (the `calculate - availability check` subgroup). `firebase_booking_calendar_repository_test.dart` failures share it because the repo was refactored in the same T11c commit (313-line diff) to drop 4 `collectionGroup('bookings').snapshots()` streams in favor of `_streamBlockedEvents` over the CF.

### Fix path: **test-only update**

Tests should seed `fakeRepo.windows = [AvailabilityWindow(source: booking, ...)]` instead of (or in addition to) writing to `fakeFirestore.collection('bookings')`. The fake repo's `windows` setter is already public-mutable. Estimated 30 sites across 3 files.

Optional defense-in-depth: add ≥1 test asserting that on `_FakeAvailabilityRepository.fetchAvailability` throw, `check()` returns `isAvailable: false`. (Commit `99ac6124` was self-reviewed but lacks an explicit regression guard.)

### Recommended action: **doc-only on this PR; queue separate test-debt PR**

Not a merge blocker. T11c shipped clean (rules-layer + server-side overlap give defense-in-depth). The test suite needs a follow-up commit to re-align fixtures with the post-T11c data flow. Already tracked under `audit/19-wave3-cleanup.md` test-debt scope.

---

## Cluster 2: stripeConnect — 4 tests asserting old wrapped error messages

**Failing tests (all in `functions/test/stripeConnect.test.ts`):**

| # | Suite | Test | Line |
|---|---|---|---|
| 1 | `createStripeConnectAccount` | `should throw an error if the owner document is not found` | 163-170 |
| 2 | `getStripeAccountStatus` | `should throw an error if the owner document is not found` | ~232-242 |
| 3 | `disconnectStripeAccount` | `should throw an error if no Stripe account is connected` | ~275-285 |
| 4 | `disconnectStripeAccount` | `should throw an error if the owner document is not found` | ~290-300 |

### Root cause: CF error-class hygiene commit changed contracts; tests still assert old contracts.

Commit `319f7d0f` (2026-05-22, "fix: CF error-class hygiene + dead Flutter callsite (SF-022, audit/16)") guarded six catch blocks across `stripeConnect.ts`, `emailVerification.ts`, `icalSync.ts`, `stripeSubscription.ts` so they re-throw their own `HttpsError` instead of re-wrapping it as `internal: "Failed to X."`. The commit message explicitly documents the contract change:

> Each catch now executes `if (error instanceof HttpsError) throw error;` before falling through to `throw new HttpsError("internal", ...)`. Primary smoke result fixed: POST /checkEmailVerificationStatus with empty body now returns HTTP 400 INVALID_ARGUMENT instead of HTTP 500 INTERNAL.

### Evidence — jest output diff

```
● Stripe Connect Functions › createStripeConnectAccount
  › should throw an error if the owner document is not found

  Expected message: "Failed to create Stripe account."
  Received message: "Owner not found"
        43 |     const ownerDoc = await db.collection("users").doc(ownerId).get();
        44 |     if (!ownerDoc.exists) {
      > 45 |       throw new HttpsError("not-found", "Owner not found");
```

The CF correctly throws `not-found / "Owner not found"`. The test asserts the pre-SF-022 wrapped form `internal / "Failed to create Stripe account."`. Same pattern repeats for the three sibling tests (assertions targeting `"Failed to get account status."` and `"Failed to disconnect account."`).

### Risk on PROD: **NONE** — improvement, not regression

The SF-022 change is a **security/hygiene improvement**:
- Client-fault rejections (owner row missing, Stripe not connected) now correctly surface their original `HttpsError` class (`not-found`, `failed-precondition`).
- Sentry `beforeSend` filter (v6.71) can correctly drop these as expected client-faults instead of treating them as `internal` errors and forwarding them as alerts.
- HTTP status codes now match the failure class (404 vs 500), improving Flutter `FirebaseFunctionsException` handling.

### Fix path: **test-only update**

Flip the four `rejects.toThrow(...)` matchers to assert the new contract:

```ts
// before:
await expect(wrapped(validRequest)).rejects.toThrow(
  new HttpsError("internal", "Failed to create Stripe account.")
);
// after:
await expect(wrapped(validRequest)).rejects.toThrow(
  new HttpsError("not-found", "Owner not found")
);
```

Same shape for the other three (`"failed-precondition" / "No Stripe account connected"`, `"not-found" / "Owner not found"` ×2).

### Recommended action: **doc-only on this PR; queue separate test-debt PR**

Not a merge blocker. SF-022 / audit/16 explicitly mentions "test:rules now 11/11" but does not appear to have updated `stripeConnect.test.ts` in the same commit — the test sweep stopped at firestore rules tests. Fold these four assertion flips into the same test-debt commit as Cluster 1.

---

## Summary

| Cluster | Failures | PROD risk | Fix path | Merge-block? |
|---|---|---|---|---|
| 1. availability_checker + 2 siblings | 30 (Flutter) | None — fail-CLOSED verified, server has 2nd check | Test-only: seed `fakeRepo.windows` | No |
| 2. stripeConnect | 4 (Jest) | None — error-class hygiene is improvement | Test-only: update 4 `rejects.toThrow` matchers | No |

**Security-relevant cluster: Cluster 1 — but only by topic, not by risk.** The failures touch the availability/double-booking surface that motivated SF-019/T11c, which is *why* they're worth diagnosing here rather than dismissing as flakes. Both server-side overlap check (atomicBooking.ts:743) and rules-layer denial (24/24 rules tests green) hold; the client checker still fail-CLOSEs on CF errors. The fail-OPEN-looking test output is a fixture mismatch with the post-T11c data flow, not a code regression.

**No code changes proposed in this audit. No commits. No deploys.**

---

## Resolution (2026-05-23) — `chore/test-debt-cleanup-audit-19`

Both clusters closed test-only on branch `chore/test-debt-cleanup-audit-19`.

**Cluster 1 (Flutter, 3 files, 30 sites):**
- `test/features/widget/data/helpers/availability_checker_test.dart` — added `throwOnFetch` flag to `_FakeAvailabilityRepository`; seeded `fakeRepo.windows` (booking-source) in 8 booking-conflict tests + the priority-order test + the date-normalization test + the `isAvailable` test; flipped the stale `ignores non-icalExternal windows` test into a positive guard for the booking-before-iCal ordering inside `check()`; added 1 defensive test asserting `isAvailable=false` when the CF fetch throws (regression guard for commit `99ac6124`'s fail-CLOSED restore).
- `test/features/widget/data/helpers/booking_price_calculator_test.dart` — added a local `_FakeAvailabilityRepository implements IAvailabilityRepository`; wired all 4 `AvailabilityChecker(fakeFirestore)` call sites to inject the fake (otherwise `FirebaseFunctions.instanceFor` crashes at construction); also added the required `propertyId: 'prop123'` argument that `calculate(checkAvailability: true)` now enforces (`booking_price_calculator.dart:121-124`).
- `test/features/widget/data/repositories/firebase_booking_calendar_repository_test.dart` — added a `_FakeAvailabilityRepository extends FirebaseAvailabilityRepository` that takes a mocktail-stubbed `FirebaseFunctions` through `super(functions: ...)` and overrides both `fetchAvailability` + `streamAvailability` (the repo constructor takes the concrete class, not the interface); injected it via the existing `availabilityRepository:` named param; seeded `fakeRepo.windows` for every test whose calendar/availability expectation depended on a written booking or iCal event; flipped the stale `marks pending bookings with isPendingBooking flag` test into a positive guard for the T11c accepted trade-off (CF strips status; synthesized booking is always `status=confirmed`; widget loses pending-vs-confirmed visual distinction).

**Cluster 2 (Jest, `functions/test/stripeConnect.test.ts`, 4 matchers):**
- `createStripeConnectAccount` owner-not-found: `internal / "Failed to create Stripe account."` → `not-found / "Owner not found"` (matches `stripeConnect.ts:45`).
- `getStripeAccountStatus` owner-not-found: `internal / "Failed to get account status."` → `not-found / "Owner not found"` (`stripeConnect.ts:124`).
- `disconnectStripeAccount` no-Stripe-account: `internal / "Failed to disconnect account."` → `failed-precondition / "No Stripe account connected"` (`stripeConnect.ts:215`).
- `disconnectStripeAccount` owner-not-found: `internal / "Failed to disconnect account."` → `not-found / "Owner not found"` (`stripeConnect.ts:209`).

Each updated matcher carries a comment pinning the assertion to the SF-022 commit (`319f7d0f`) + the line in `stripeConnect.ts` it mirrors, so the contract is locked.

**Verification (post-fix):**

| Step | Pre-fix | Post-fix |
|---|---|---|
| `flutter analyze` | 0 issues | 0 issues |
| `flutter test` | 1070 passed / 30 failed | 1101 passed (+1 new defensive test) / 0 failed |
| `cd functions && npm run build` | 0 errors | 0 errors |
| `cd functions && npm test` | 161 passed / 4 failed | 165 passed / 0 failed |
| `cd functions && npm run test:rules` | 24 passed | 24 passed (untouched) |

**No production code changed.** All edits live under `test/**` and `functions/test/**` plus this audit file.

