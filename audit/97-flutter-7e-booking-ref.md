# audit/97 — FLUTTER-7E booking_reference auto-heal + audit/34 §5 onBookingCreated idempotency

**Date**: 2026-05-30
**Branch**: `fix/flutter-7e-booking-ref-autoheal`
**PR**: TBD
**SF**: SF-077
**Scope**: `functions/src/bookingManagement.ts` + `functions/src/utils/bookingHelpers.ts` + `functions/test/bookingManagement.test.ts`

This audit bundles two closely-related CF email-pipeline fixes:

1. **FLUTTER-7E** — refless bookings tripped `validateRequiredString` in `sendBookingApproved/RejectedEmail`, burning 4 retries before surfacing.
2. **audit/34 §5** — `onBookingCreated` wrote ZERO `emails_sent.*` keys, so event redelivery re-flushed iCal cache + re-created the in-app notification each time.

Both share the same failure mode: missing idempotency markers on the booking trigger family let the `emailRetry` 4-attempt loop amplify minor data drift into Sentry storms. Closing them together because they share the file, the test file, and the type extension on `BookingEmailTracking`.

---

## 1. Sentry issue

**FLUTTER-7E** (event `e869c8b5`, dev) — `Error: bookingReference is required and must be a non-empty string`.

- Stack: `validateRequiredString` (emailService.ts:193) ← `sendBookingRejectedEmail` (emailService.ts:773) ← `bookingManagement.ts:329` (in compiled JS line numbers — `:460` in source) ← `sendEmailWithRetry` (emailRetry.ts:39).
- Trigger: `onbookingstatuschange-whc46z5xxq-uc.a.run.app` on `properties/SEED_test_owner_property_01/units/SEED_test_owner_unit_01/bookings/3kG0vFHcc71k73Ykx3Mg` flipping `pending` → `cancelled` with `rejection_reason: "F-67-01 smoke reject"` (audit/67 F-67-01 fixture).
- Burned 4 retries via `emailRetry` before surfacing.
- `handled: yes` — caught by the surrounding try/catch in `bookingManagement.ts:482`, so booking status update succeeded; only the email failed.

---

## 2. Root causes

### FLUTTER-7E

`bookingManagement.ts:460` (rejection branch) and `:388` (approval branch) passed `after.booking_reference || ""` straight to email senders. `validateRequiredString` in `emailService.ts:191-194` throws on empty string, defeating the `|| ""` fallback.

The cancellation branch (legacy line 514-532) already had the right pattern: detect missing ref, generate via `generateBookingReference(bookingId)`, write back to Firestore, mutate local snapshot. Rejection + approval branches lacked this mirror.

Source of refless bookings:
- SEED scripts (audit/67 + audit/40) that direct-write Firestore docs bypassing `createBookingAtomic`.
- Legacy bookings predating `booking_reference` rollout.
- Partial migrations.

### audit/34 §5 (compounding factor)

`onBookingCreated` performs three side effects: iCal cache flush, email send chain via `atomicBooking.ts`, in-app notification creation. None of them write a per-trigger marker on `emails_sent.*`. When the Firestore trigger redelivers (network, deploy, transient failure), all three re-run:

- iCal cache wasted re-flush (no correctness issue).
- Email re-send protected by `atomicBooking.ts`'s per-key markers (`emails_sent.pending_request` etc.) — safe.
- In-app notification duplicated (`createBookingNotification` has no dedup).

Per-trigger marker closes the third.

---

## 3. Fix

### A — `BookingEmailTracking` type extension

`functions/src/utils/bookingHelpers.ts:41-44` — add `initial_trigger_processed?: EmailSent`. Reuses the `emails_sent` map dot-notation so writers don't collide with `atomicBooking.ts`'s per-key writes.

### B — `onBookingCreated` idempotency (audit/34 §5)

`functions/src/bookingManagement.ts:217-230` — early-return guard reading `emailTracking?.initial_trigger_processed`. If set, log + return; skips iCal flush, emails, notification.

`functions/src/bookingManagement.ts:308-321` — after the notification create, append `emails_sent.initial_trigger_processed: {sent_at, email, booking_id, provider_id: null}` via `event.data?.ref.update(...)`. Dot-notation keeps writes additive.

### C — FLUTTER-7E auto-heal (approval + rejection branches)

`functions/src/bookingManagement.ts:385-408` (approval) and `:497-520` (rejection) — inline auto-heal before the email send. If `booking.booking_reference` is missing:

```ts
const newRef = generateBookingReference(event.params.bookingId);
await event.data?.after.ref.update({
  booking_reference: newRef,
  updated_at: admin.firestore.FieldValue.serverTimestamp(),
});
booking.booking_reference = newRef;
logWarn("[onStatusChange] Restored missing booking_reference (approval|rejection)", {...});
```

Email senders then receive `booking.booking_reference` (never `""`). Both branches also switched the rest of the field reads from `after.xxx` to `booking.xxx` for consistency with the local mutable snapshot.

Cancellation branch (line ~590) **unchanged** — already had inline auto-heal.

---

## 4. Out of scope (carry-forward)

- `bookingManagement.ts:158` — `autoCancelExpiredBookings` scheduled job passes `booking.booking_reference` raw (no fallback, no heal). Same FLUTTER-7E class. Tracked for a follow-up PR; would close the daily-schedule sibling.
- SEED scripts under `scripts/` (`seed-bookbed-dev.js` etc.) should write `booking_reference` to match canonical write path. Tracked under audit/40 + audit/67 fixture hygiene.
- `lib/`, `ios/`, `android/`, `firestore.rules` — untouched per scope.

---

## 5. Verification

```
cd functions
npm run build   # tsc: 0 errors
npm test        # 19 suites, 406 tests, all green (was 402, +4 regression)
```

New tests in `functions/test/bookingManagement.test.ts`:

1. **FLUTTER-7E rejection auto-heal** — refless `pending → cancelled` w/ `rejection_reason` flow; asserts `mockUpdate` called w/ `{booking_reference: "BK-3KG0VFHCC71K"}` (deterministic from doc ID `3kG0vFHcc71k73Ykx3Mg` from the Sentry event payload) AND `sendBookingRejectedEmail` invoked with healed ref.
2. **FLUTTER-7E approval auto-heal** — refless `pending → confirmed` w/ `approved_at`; same assertions on `sendBookingApprovedEmail`.
3. **audit/34 §5 marker write** — bank-transfer booking → marker persisted on `emails_sent.initial_trigger_processed` with `{email, booking_id, provider_id: null}`.
4. **audit/34 §5 short-circuit** — booking already carrying marker → `createBookingNotification` NOT called on redelivery.

Tests use the exact `bookingId` from the FLUTTER-7E Sentry event payload (`3kG0vFHcc71k73Ykx3Mg`) to lock the regression to the real-world data.

---

## 6. Cross-refs

- Sentry: FLUTTER-7E (issue 123267795), FLUTTER-79 (sibling — `Failed to create Stripe account.`, closed via PR #541 audit/74).
- Memory: `onbookingcreated-no-email-tracking.md` (audit/34 §5 idempotency exposure); `owner-confirm-reject-ui-no-op.md` (audit/67 F-67-01 root cause for the SEED fixture).
- Code: `functions/src/utils/bookingReferenceGenerator.ts` (helper used by auto-heal); `functions/src/emailService.ts:191-194` (`validateRequiredString` thrower); `functions/src/utils/emailRetry.ts:39` (4-attempt retry that amplifies the noise); `functions/src/atomicBooking.ts` (writes initial-email idempotency keys this PR does not touch).
- SF: SF-077 (this), SF-074 (PR #578, F-94 affected-keys deny), SF-076 (PR #581, F-94-02-CREATE).

---

## 7. Deploy plan

- Dev: deploy `onBookingStatusChange` + `onBookingCreated` (`firebase deploy --only functions:onBookingStatusChange,functions:onBookingCreated --project bookbed-dev`).
- Smoke:
  1. FLUTTER-7E — trigger rejection on a refless seed booking; expect `[onStatusChange] Restored missing booking_reference (rejection)` warn + email delivered; no FLUTTER-7E event in Sentry.
  2. audit/34 §5 — create a bank-transfer booking via widget; verify `emails_sent.initial_trigger_processed` written on the booking doc; replay the trigger via `firebase functions:shell` or by re-saving the doc; verify second pass logs `onBookingCreated already processed` and creates no duplicate notification.
- PROD: operator-gated. No schema, no rules, no IAM surface touched.
