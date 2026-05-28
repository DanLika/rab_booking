# audit/72 — Owner Cancel Booking NO-OP Fix (F-67-01 sibling, potential P1)

**Date:** 2026-05-28
**Branch:** `fix/owner-cancel-booking` (stacked on `fix/f-67-01-booking-confirm-reject` / PR #536)
**Related:** [audit/67 §G](./67-chrome-deepflow-2026-05-28.md), [audit/69 — F-67-01](./69-f6701-booking-action-fix-2026-05-28.md), PR #536, [memory/owner-confirm-reject-ui-no-op.md](../../.claude/projects/-Users-duskolicanin-git-bookbed/memory/owner-confirm-reject-ui-no-op.md)

## §1 Root Cause (gap classification)

**Gap B (partial reuse) confirmed.**

`firebase_owner_bookings_repository.dart:954` — owner Otkaži path — wrote
booking status via the Firestore SDK directly:

```dart
await bookingDoc.reference.update({
  'status': BookingStatus.cancelled.value,
  'cancellation_reason': reason,
  'cancelled_at': FieldValue.serverTimestamp(),
  'updated_at': FieldValue.serverTimestamp(),
});
```

Three UI sites wire to it:
- `owner_bookings_screen.dart:1995` — per-row Otkaži
- `bookings_table_view.dart:768` — desktop table cancel
- `timeline_calendar_widget.dart:1791` — calendar action menu cancel

(Plus `overbooking_detection_provider.dart:228` — overbooking auto-cancel,
also owner-context but executes silently in the background.)

This is the **same bug class** F-67-01 (audit/67 §G) found for owner
Confirm/Reject (PR #536) — except cancel also needs a Stripe **refund**
on paid bookings.

### Existing CF surface

- `functions/src/guestCancelBooking.ts` (475 LOC) — full cancellation
  pipeline (state guard + atomic transaction + Stripe refund + email),
  but **guest-token-only** (no owner path). The refund block lines
  pre-fix 297-365 is the canonical destination-refund implementation,
  destination=platform, `reverse_transfer: true`, idempotency key
  `refund-${bookingId}` (audit/52 F-52-01).
- `functions/src/bookingManagement.ts` `onBookingStatusChange` trigger —
  already sends the owner-cancellation email + invalidates iCal cache
  when status flips to `cancelled` (lines 474-…). Owner cancel inherits
  that fan-out for free.

So the gap is: **no owner-callable cancellation CF, and the refund leg
exists only inside the guest path.**

## §2 Fix Applied

Stacked on PR #536's `fix/f-67-01-booking-confirm-reject` branch so this
PR can extend `bookingActions.ts` without merge conflict.

### New helper — `functions/src/utils/bookingRefund.ts` (~125 LOC)

`processStripeRefund({ bookingId, bookingReference, bookingRef, ownerId,
stripePaymentIntentId, refundAmount, cancelledBy })` extracts the
post-transaction Stripe refund leg verbatim from guestCancelBooking:

- Owner-Stripe-account-id lookup from `users/{ownerId}`
- Guard on missing `stripe_account_id` / `stripe_payment_intent_id`
- `stripe.refunds.create({reverse_transfer: true, …})` with
  `idempotencyKey: refund-${bookingId}`
- Stamps `refund_status: "processed"` + `stripe_refund_id` on success
- Stamps `refund_status: "failed"` + `refund_error` on any throw
- **Never throws** — booking-cancellation must succeed even if refund
  fails (the operator retries refund manually from Stripe Dashboard)

### Refactored `functions/src/guestCancelBooking.ts`

- Dropped `getStripeClient` import + 73 lines of inline refund handling.
- Added `processStripeRefund` import + 11-line call site.
- Behaviour preserved byte-for-byte (`cancelledBy: "guest"` keeps the
  Stripe metadata identical).
- 317/317 existing CF tests pass post-refactor.

### Extended `functions/src/bookingActions.ts` (#536 file)

- Generalised `loadOwnedPendingBooking(uid, bookingId)` →
  `loadOwnedBookingForAction(uid, bookingId, allowedStatuses[])`.
  approveBooking/rejectBooking now pass `["pending"]`; cancelBooking
  passes `["pending", "confirmed", "cancelled"]` (the last entry lets
  the transactional short-circuit return idempotently).
- New `cancelBooking` `onCall` handler (~125 LOC):
  - `europe-west1`, `secrets: [stripeSecretKey]`, `cors: true`
  - Auth → ownership → state guard outside Tx
  - Firestore transaction: re-read, return `{alreadyCancelled: true}`
    if already cancelled (idempotent), reject `completed`/etc., compute
    refund_amount + refund_status (paid+stripe → `pending_stripe`;
    paid+other → `pending_manual`; else `not_applicable`), update
    booking with `cancelled_by: "owner"`, `cancellation_reason`,
    `cancelled_at`, refund fields.
  - Post-Tx: if `refund_status === "pending_stripe"`, call
    `processStripeRefund({ cancelledBy: "owner" })`.
  - Returns `{ success, bookingId, status: "cancelled", refundAmount,
    refundStatus, refundId? }`.

### Dart repo refactor

`lib/features/owner_dashboard/data/firebase/firebase_owner_bookings_repository.dart`
`cancelBooking` (was 22 LOC of SDK write):

```dart
await _functions
    .httpsCallable('cancelBooking')
    .call<Map<String, dynamic>>({
  'bookingId': bookingId,
  if (reason.trim().isNotEmpty) 'reason': reason.trim(),
});
```

- Throws `BookingException` with `code: 'booking/cancellation-${e.code}'`
  preserving the `FirebaseFunctionsException.message` for the snackbar.
- `sendEmail` named parameter retained for source-compat; documented as
  no-op (server-side trigger now owns email).
- Three UI handlers (`owner_bookings_screen.dart`, `bookings_table_view.dart`,
  `timeline_calendar_widget.dart`) already wrap `repository.cancelBooking`
  in `try/catch` + `ErrorDisplayUtils.showErrorSnackBar` — unchanged.

### Total diff

| File | LOC change |
|---|---|
| `functions/src/utils/bookingRefund.ts` (new) | +125 |
| `functions/src/guestCancelBooking.ts` | −60 (refactor) |
| `functions/src/bookingActions.ts` | +135 (cancel handler + loader generalisation) |
| `lib/features/owner_dashboard/data/firebase/firebase_owner_bookings_repository.dart` | −22 +20 (refactor) |
| `audit/72-owner-cancel-fix-2026-05-28.md` (new) | +180 |

## §3 Verification

| Check | Result |
|---|---|
| `dart format` | clean |
| `flutter analyze` | 0 new (2 pre-existing info hints) |
| `flutter analyze <repo file>` | `No issues found!` (1.5s) |
| `cd functions && npm run build` | clean |
| `cd functions && npm test` | **317/317 passed** |
| `cd functions && npm run test:rules` | **39/39 passed** |
| `flutter test --no-pub` | **1205/1205 passed** |
| Deploy bookbed-dev | `cancelBooking(europe-west1)` create, `guestCancelBooking(us-central1)` update, both successful |

### Post-deploy IAM hiccup

The fresh deploy of `cancelBooking(europe-west1)` did **not** receive
the `allUsers` `roles/run.invoker` binding that `approveBooking` /
`rejectBooking` got automatically last session. Initial smoke calls
returned a GFE-level 401 ("Your client does not have permission to the
requested URL"). Granted manually:

```
gcloud run services add-iam-policy-binding cancelbooking \
  --region=europe-west1 --project=bookbed-dev \
  --member=allUsers --role=roles/run.invoker
```

Function-level auth (`request.auth.uid`) still enforces sign-in — the
`allUsers` invoker only opens the Cloud Run front door so the Firebase
callable wrapper can extract the Bearer ID token. Same pattern as every
other Firebase callable on this project. **Pre-PROD checklist** §6
flags this as a step PROD cutover must repeat manually if Firebase
deployer doesn't auto-grant.

### Dev smoke (bookbed-dev, owner `bookbed-test@bookbed.io`, property `SEED_test_owner_property_01` / unit `SEED_test_owner_unit_01`)

7 sub-cases active, 1 deferred. Trace inlined; local log at
`audit/migrations/2026-05-28-owner-cancel-cleanup.log` (gitignored).

1. **confirmed + unpaid → cancelled.** Booking `efMdqa5x0thrlSvvEF3z`.
   `200 {status:"cancelled", refundAmount:0, refundStatus:"not_applicable"}`.
   Firestore: `status=cancelled`, `cancelled_by=owner`, `cancellation_reason="Owner smoke test cancel"`.
2. **pending + unpaid → cancelled (default reason).** `200 …`
   Firestore: `cancellation_reason="Cancelled by owner"`.
3. **Idempotent re-cancel.** Second call against #1 booking returns
   `200 {success:true, refundAmount:0, refundStatus:"not_applicable"}`
   without altering Firestore (already-cancelled short-circuit).
4. **State guard — completed.** `400 FAILED_PRECONDITION` with
   `Booking status "completed" is not eligible for this action.`
5. **Bogus bookingId.** `404 NOT_FOUND — Booking not found.`
6. **Empty bookingId.** `400 INVALID_ARGUMENT — bookingId is required.`
7. **Paid + Stripe synthetic PI.** Booking with `payment_status=paid`,
   `payment_method=stripe`, `stripe_payment_intent_id=pi_does_not_exist_…`.
   CF response: `200 {refundStatus:"pending_stripe"}` (transaction
   landed before async refund call). Post-2.5s reread:
   `refund_status=failed` — helper caught the Stripe `No such
   payment_intent` error and marked the refund leg failed without
   reverting the cancellation. Booking integrity preserved.
8. **Non-owner permission-denied** — **DEFERRED**. No second test-owner
   account on bookbed-dev; the ownership check
   (`propertyDoc.owner_id !== uid → permission-denied`) is identical to
   F-67-01 approveBooking which #536's smoke validated end-to-end. Code
   review confirms parity. Future follow-up: add a `bookingActions.test.ts`
   jest suite mocking `findBookingById` so this path is unit-covered.

All throwaway bookings deleted in `finally`; 0 residual data on bookbed-dev.

## §4 Dependency Note — stacked on PR #536

This branch was cut from `fix/f-67-01-booking-confirm-reject` (PR #536),
not from `main`. Reasons:

- `functions/src/bookingActions.ts` only exists on #536; extending it
  avoids a merge conflict on that file.
- `loadOwnedBookingForAction` is a refactor of #536's
  `loadOwnedPendingBooking` (rename + parameterise `allowedStatuses`).
  Both callers (approve, reject) updated in this PR — they need both
  changes shipped together.

**Merge order:** #536 first, then this PR rebases automatically on
`main` (the diff against #536 cleanly applies post-merge). If reviewers
want to merge in parallel, this PR's branch needs a quick
`git rebase main` after #536 lands.

## §5 Cross-platform

Same conclusion as audit/69 §4: the fix is in the **repository layer**
(`firebase_owner_bookings_repository.dart`). All three Owner Dashboard
surfaces — **web, iOS, Android** — inherit the routing change
automatically. No per-platform code touched.

Re-verification on iOS/Android can ride along with the next Terminal B
/ Terminal C smoke pass (audit/66 iOS deepflow, audit/63 Android E2E).

## §6 Pre-PROD Cutover Checklist

When this lands and is ready for PROD deploy:

1. `firebase deploy --only functions:cancelBooking,functions:guestCancelBooking --project rab-booking-248fc`
2. **Verify** `gcloud run services get-iam-policy cancelbooking --region=europe-west1 --project=rab-booking-248fc` shows `allUsers` invoker. If not, repeat the `add-iam-policy-binding` step from §3.
3. Owner Otkaži test on PROD with a throwaway booking — refund flow on PROD owners with real `stripe_account_id` (deferred on dev because the bookbed-test owner has no Stripe Connect onboarding).
4. Watch `onBookingStatusChange` trigger logs to confirm cancellation email + iCal cache invalidation fire.

## §7 Follow-ups (out of scope)

1. **Unit test `bookingActions.ts`** — mirror smoke cases as
   `functions/test/bookingActions.test.ts` (approve + reject + cancel).
   Closes the "only smoke is a regression guard" gap from audit/69 §3.
2. **Non-owner permission smoke** — needs a second test owner account on
   bookbed-dev (or use the existing `bookbed-test` plus a freshly-minted
   throwaway owner). Add to F-67-02/F-67-03 smoke battery.
3. **Rules tightening (still deferred)** — now that approve / reject /
   cancel all route through CFs, the `bookings` `allow update, delete:
   if isPropertyOwner(propertyId)` rule can be tightened with a
   `diff()` affectedKeys check. Still gated on `completeBooking` +
   `deleteBooking` + inline-edit-dialog all getting CF equivalents (or
   explicit field-level allowlist).
4. **`completeBooking` + `deleteBooking` migration** — same direct-SDK
   pattern lives at lines 983 + 1008 of the repo. Lower risk (rare
   ops) but worth the same CF treatment for consistency. Track as a
   F-67-01 cluster follow-up.
