# audit/112 — Trial gate Layer 2 (guest-path) scope map

**Drafted**: 2026-06-03
**Mode**: scope map for Step A2 — guest-path callables, gate on UNIT OWNER status (not caller — caller is anonymous or auth.uid = guest). Sibling of `audit/110` (L1). NO L1 / EXEMPT callables touched in this PR.
**Repo HEAD**: `cf65f9c8` on `main`.
**Status of SF-078 (L1)**: PR #666 open, NOT merged, deployed to `bookbed-dev` and smoke-passed 2026-06-03 (per task closure). L2 (this PR) is independent — different gate target.

## 1. Caller-vs-owner threat model

L1 (PR #666) gates on the CALLER's `accountStatus` because the caller IS the owner doing owner-management actions. L2 gates on a DIFFERENT subject:

- **L2 callers are guests** (anonymous web visitors completing a booking, or authenticated guests who already have a booking). Gating on the caller would be meaningless — guests don't have an `accountStatus`.
- **L2 gates on the unit's OWNER `accountStatus`.** A trial-expired owner shouldn't have a live booking funnel running against their property: the widget shouldn't show their availability + the checkout should refuse new bookings. Once the owner upgrades (via the EXEMPT `createSubscriptionCheckoutSession` path) the gate stops rejecting and the funnel resumes.

The helper takes a `propertyId`, reads `properties/{propertyId}.owner_id`, then applies the same allow-list (`['trial', 'active']`) as L1. Fail-closed + Sentry WARN semantics mirror L1.

## 2. L2 callables — classification

7 L2 callables per `audit/110 §L2`. Split by purpose:

### Group A — NEW-BOOKING path (3 callables) — GATE in this PR

Caller is creating a NEW booking (or feeding the calendar that drives the new-booking flow). If the owner is trial_expired, none of these should succeed.

| Callable | File:line | Caller | Unit/property resolution | Gate path |
|---|---|---|---|---|
| `getUnitAvailability` | `availability.ts:114` | anonymous (widget) | `propertyId` + `unitId` directly in `request.data` | gate on `properties/{propertyId}.owner_id` |
| `createBookingAtomic` | `atomicBooking.ts:61` | anonymous (widget) OR authenticated owner-dashboard | `propertyId` + `unitId` + `clientOwnerId` (validated server-side per SF-001) | gate on `properties/{propertyId}.owner_id` |
| `createStripeCheckoutSession` | `stripePayment.ts:52` | anonymous (widget checkout) | `bookingData.propertyId` + `bookingData.unitId` | gate on `properties/{propertyId}.owner_id` |

### Group B — EXISTING-booking management (4 callables) — DO NOT gate (anti-strand)

The guest already has a confirmed booking. They MUST be able to view / cancel / re-request emails / verify access regardless of the owner's account state. Locking a guest out of their own booking because the owner's trial lapsed = stranding paying guests with no recourse.

| Callable | File:line | Why exempt |
|---|---|---|
| `verifyBookingAccess` | `verifyBookingAccess.ts:21` | Guest verifies they own a booking via `(ref, email, token)`. Status check belongs to the booking, not the owner. |
| `guestCancelBooking` | `guestCancelBooking.ts:66` | Guest's right to cancel persists regardless of owner state. Anti-strand requirement. |
| `getBookingByStripeSession` | `getBookingByStripeSession.ts:27` | Post-checkout retrieval. Booking already paid. Owner status drift after payment must not prevent guest from finding their record. |
| `resendGuestBookingEmail` | `resendGuestBookingEmail.ts:42` | Guest re-requests their existing booking email. Token-validated; not an owner-driven action. |

If a trial_expired owner has stale guest bookings on their property, those guests retain full lifecycle access. This is the **anti-strand invariant** — explicit and tested in §5.

## 3. Frozen-scope check — how widget reacts when the gate rejects

CLAUDE.md `NIKADA NE MIJENJAJ` rows touched by the L2 gate intersection:
- **`firebase_booking_calendar_repository.dart`** (FROZEN) — widget calendar reads bookings + iCal via `getUnitAvailability` per the T11c row.
- `booking_widget_screen.dart` — frozen-adjacent (18 silent debug guards per `.claude/rules/widget.md`, but not strictly frozen).

The gate rejection paths and how each Flutter caller handles them:

### Path A — `getUnitAvailability` rejection

`lib/features/widget/data/helpers/availability_checker.dart:199-212`:

```dart
late final List<AvailabilityWindow> cfWindows;
try {
  cfWindows = await _availabilityRepo.fetchAvailability(
    propertyId: propertyId,
    unitId: unitId,
    start: normalizedCheckIn,
    end: normalizedCheckOut,
  );
} catch (e) {
  unawaited(LoggingService.logError('Error fetching availability windows', e));
  return AvailabilityCheckResult.error(ConflictType.booking);  // fail-CLOSED
}
```

`failed-precondition` from my gate gets caught + funnels into the existing `AvailabilityCheckResult.error(ConflictType.booking)` fail-CLOSED branch. UI shows the existing localized `AvailabilityErrorCode.checkError` message ("Check error, please try again" or equivalent). **No crash, no frozen change required.**

### Path B — `createBookingAtomic` rejection

`lib/core/services/booking_service.dart:303-330`:

```dart
} on FirebaseFunctionsException catch (e) {
  await LoggingService.logError('[BookingService] Cloud Function error: ${e.code} - ${e.message}', e);
  ...
  if (e.code == 'already-exists') { throw BookingConflictException(...); }
  if (e.code == 'invalid-argument') { throw BookingServiceException(...); }
  throw BookingServiceException('Failed to create booking: ${e.message}');
}
```

`failed-precondition` falls through to the generic `BookingServiceException('Failed to create booking: ${e.message}')`. The widget catches `BookingServiceException` and shows the message string in its error UI. My gate's message ("Trial expired. Please upgrade to continue." or "Account status unrecognised. Please contact support.") surfaces to the user. **No crash, no frozen change required.**

`booking_service.dart` is NOT in the FROZEN list (it lives in `lib/core/services/`, not `lib/features/widget/`).

### Path C — `createStripeCheckoutSession` rejection

`lib/core/services/stripe_service.dart:96-100` ALREADY has an explicit `failed-precondition` switch case:

```dart
case 'failed-precondition':
  userMessage = e.message
    ?? 'Payment setup incomplete. Please contact the property owner.';
  break;
```

The gate's message flows through `e.message ?? <fallback>` and surfaces cleanly. **No frozen change required.** `stripe_service.dart` is also not frozen.

### Frozen-scope verdict

**SAFE.** Server-only gate works. All 3 NEW-BOOKING callable rejections degrade gracefully through existing error handlers. No `firebase_booking_calendar_repository.dart` / `booking_widget_screen.dart` / other frozen-list file needs editing.

Optional future Flutter UX enhancement: extend `booking_service.dart:303-330` to surface `failed-precondition` as a tailored `OwnerSubscriptionExpiredException` for a cleaner user-facing message instead of "Failed to create booking: …". That's a UX scope-creep PR — not in scope here.

## 4. Helper API

```ts
// functions/src/utils/requireActiveUnitOwner.ts
export async function requireActiveUnitOwner(propertyId: string): Promise<string>
```

Returns the property's `owner_id` on success. Throws:
- `HttpsError('invalid-argument', ...)` — missing/empty propertyId
- `HttpsError('failed-precondition', ...)` — property doc missing, missing owner_id, or owner accountStatus ∉ `['trial', 'active']`. Sentry WARN on unknown/missing accountStatus (mirrors L1).
- `HttpsError('internal', ...)` — Firestore read failure (passes through caller's error wrapper)

Ordering: same invariant as L1 — runs BEFORE any rate-limit check so trial-expired-owner-targeted abuse doesn't burn the rate-limit budget for that unit.

User-facing messages (so client UI can distinguish):
- `trial_expired` → `"This property is currently unavailable for new bookings."`
- `suspended` → `"This property is currently unavailable for new bookings."`
- unknown / missing → `"This property is currently unavailable for new bookings."` + Sentry WARN

Deliberately generic and identical across blocking statuses on the GUEST side — guests should not learn the owner's billing posture. Operator sees details in Sentry/Cloud Logging.

## 5. Anti-strand test (mandatory)

Guest with an EXISTING booking on a unit whose owner is `trial_expired`:
- `verifyBookingAccess` must succeed (or fail only on bad token/email — same as today)
- `guestCancelBooking` must succeed
- `getBookingByStripeSession` must succeed
- `resendGuestBookingEmail` must succeed

If ANY of these reject with `failed-precondition` for a valid owner-expired booking → test FAILS, gate is too wide, regression.

## 6. SF number allocation

Next SF: **SF-079** (verified: `grep -nE "^## SF-079" docs/SECURITY_FIXES.md` returns 0 hits on `cf65f9c8` post-SF-078).

## 7. Summary

- **L2 NEW-BOOKING callables to gate (3)**: `getUnitAvailability`, `createBookingAtomic`, `createStripeCheckoutSession`
- **L2 EXISTING-management callables NOT gated (4)**: `verifyBookingAccess`, `guestCancelBooking`, `getBookingByStripeSession`, `resendGuestBookingEmail` — anti-strand
- **Gate target**: `properties/{propertyId}.owner_id` → `users/{owner_id}.accountStatus ∈ ['trial', 'active']` (mirror of L1 allow-list)
- **Unknown handling**: fail-closed + Sentry WARN (mirror of L1)
- **Frozen-scope verdict**: SAFE. Server-only fix works; widget calendar fail-CLOSED already handles CF errors; booking/stripe services surface error messages cleanly.
- **NO frozen-file edits in this PR.** `firebase_booking_calendar_repository.dart`, `booking_widget_screen.dart`, `unified_unit_hub_screen.dart`, etc. — all untouched.
- **Optional Flutter UX follow-up**: `booking_service.dart:303-330` could distinguish `failed-precondition` for a cleaner user message. Out of scope for this PR.
