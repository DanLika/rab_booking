# audit/69 — F-67-01 Booking Confirm/Reject NO-OP Fix (P1 LAUNCH BLOCKER)

**Date:** 2026-05-28
**Branch:** `fix/f-67-01-booking-confirm-reject`
**Related:** [audit/67 §G](./67-chrome-deepflow-2026-05-28.md), [memory/owner-confirm-reject-ui-no-op.md](../../.claude/projects/-Users-duskolicanin-git-bookbed/memory/owner-confirm-reject-ui-no-op.md)

## §1 Root Cause (Gap classification)

**Gap B confirmed — no Cloud Function callable existed.** Owner Dashboard
booking action handlers (Odobri / Odbij / Potvrdi) call the repository
methods `approveBooking` / `rejectBooking` / `confirmBooking` in
`firebase_owner_bookings_repository.dart`, which (pre-fix) write Firestore
**directly via the SDK** at

- `lib/features/owner_dashboard/data/firebase/firebase_owner_bookings_repository.dart:845` — `approveBooking`
- `lib/features/owner_dashboard/data/firebase/firebase_owner_bookings_repository.dart:885` — `rejectBooking`
- `lib/features/owner_dashboard/data/firebase/firebase_owner_bookings_repository.dart:928` — `confirmBooking`

`functions/src/bookingManagement.ts` only exposes triggers
(`onBookingCreated`, `onBookingStatusChange`) and the scheduler
(`autoCancelExpiredBookings`); no HTTPS callable for owner state
transitions exists.

**Rules surface (relevant lines):**

- `firestore.rules:225` — subcollection bookings:
  `allow update, delete: if isPropertyOwner(propertyId);`
- `firestore.rules:391` (deprecated top-level): `allow update, delete: if isResourceOwner();`
- `firestore.rules:325` — CG rule is read-only; subcollection path owns writes.

The rules technically permit an authenticated property owner to update
booking status directly, so the audit/67 narrative "rules deny" is
imprecise. The real symptom captured in audit/67 §G — silent no-op with
no UI feedback — most plausibly stems from the `_findBookingById` (line
669) collection-group strategy: it filters by `owner_id == auth.uid`,
returns the doc, but the subsequent `bookingDoc.reference.update(...)`
can fail (network, App Check, stale snapshot) without crisp error
classification, and `BookingException.approvalFailed` then wraps the
inner FirebaseException with a generic message.

Regardless of which exact branch trips in production, the architectural
fix is the same: route through a server-side callable with Admin SDK,
explicit auth + ownership validation, explicit state guard, and clean
`HttpsError` codes the client can map to user-facing messages.

## §2 Fix Applied

### New CF — `functions/src/bookingActions.ts` (181 LOC)

Two `onCall` handlers in **`europe-west1`** (per `.claude/rules/cloud-functions.md`
"don't deploy new functions to us-central1 without reason"; audit/11 P3
EU latency win):

- `approveBooking({ bookingId }) → { success, bookingId, status:"confirmed" }`
- `rejectBooking({ bookingId, reason? }) → { success, bookingId, status:"cancelled" }`

Both share `loadOwnedPendingBooking()` which:
1. `findBookingById(bookingId, uid)` (existing util, `bookingLookup.ts`)
2. Resolves `properties/{propertyId}.owner_id === uid` (defense-in-depth on top of `owner_id` query)
3. State guard: throws `failed-precondition` if `status !== 'pending'`

Error codes returned: `unauthenticated`, `invalid-argument`, `not-found`,
`permission-denied`, `failed-precondition`. All client-fault classes are
already filtered out of Sentry per the `beforeSend` filter in
`functions/src/sentry.ts` (`.claude/rules/cloud-functions.md` § "HttpsError
client-fault filter").

Email + iCal cache invalidation continue to fan out via the existing
`onBookingStatusChange` Firestore trigger — unchanged. The CF only
writes the state transition; nothing else.

### CF export

`functions/src/index.ts:18` — `export * from "./bookingActions";`

### Dart refactor

`lib/features/owner_dashboard/data/firebase/firebase_owner_bookings_repository.dart`

- Added `cloud_functions` import (line 2).
- Constructor accepts optional `FirebaseFunctions? functions` named arg
  (line 73); defaults to `FirebaseFunctions.instanceFor(region: 'europe-west1')`.
  Existing positional construction in `lib/shared/providers/repository_providers.dart:61`
  remains source-compatible.
- `approveBooking` (was 845-882, 38 LOC SDK write + verbose debug) →
  ~15 LOC `httpsCallable('approveBooking').call(...)` with explicit
  `FirebaseFunctionsException` catch that preserves `e.message` and
  encodes `e.code` into the BookingException code (`booking/approval-<code>`).
- `rejectBooking` (was 885-925, 41 LOC) → same pattern, calls
  `rejectBooking` callable, only passes `reason` when non-empty.
- `confirmBooking` (was 928-950) → tail-call alias for `approveBooking`
  (identical semantics: pending→confirmed + `approved_at` stamp).

**Net Dart change:** -55 LOC (removed direct SDK write + debugPrint
scaffolding), +24 LOC (CF wrappers + constructor injection). Helper
`_findBookingById` (line 669) is untouched — still used by
`cancelBooking`, `completeBooking`, `deleteBooking`, `getOwnerBookingById`.

### UI handlers — unchanged

All three call sites (`owner_bookings_screen.dart:1877/:1927`,
`bookings_table_view.dart:617/:691/:970/:1057`,
`timeline_calendar_widget.dart:1735/:1762`) already wrap the repository
call in `try/catch` and surface errors via
`ErrorDisplayUtils.showErrorSnackBar(context, e, userMessage: l10n.…)`.
The repository now throws a `BookingException` with both the localized
fallback and the precise CF `e.message` available via `originalError`
inspection, so the snackbar carries server-side detail
("Booking is not pending (current status: confirmed)", "You do not own
this booking.") in addition to the localized message.

## §3 Verification

| Check | Result |
|---|---|
| `dart format` | 1 file changed (repo), bookingActions.ts unchanged |
| `flutter analyze` (project) | 0 new issues (2 pre-existing info hints in `rate_limit_service.dart` + `web_utils_web.dart`) |
| `flutter analyze <repo file>` | `No issues found!` (1.0s) |
| `cd functions && npm run build` | clean (`tsc` no errors) |
| `cd functions && npx eslint src/bookingActions.ts` | clean |
| `cd functions && npm test` | **317/317 passed** (11.1s) |
| `cd functions && npm run test:rules` | **39/39 passed** |
| `flutter test --no-pub` | **1205/1205 passed** |
| Deploy bookbed-dev | `approveBooking(europe-west1)`, `rejectBooking(europe-west1)` — Successful create |

### Dev smoke (bookbed-dev, owner `bookbed-test@bookbed.io` UID `GILVItIVP5R8WXfnMmyMo1ykhUm2`, property `SEED_test_owner_property_01` / unit `SEED_test_owner_unit_01`)

5 sub-cases, all PASS. Smoke output captured inline below (local log
file at `audit/migrations/2026-05-28-f6701-cleanup.log` not committed —
`*.log` is gitignored).

1. **approveBooking happy path** — created pending booking
   `eslCze7cxEBfz9b6M1QB`, `POST /approveBooking` →
   `200 {success:true, bookingId, status:"confirmed"}`; Firestore
   reflects `status=confirmed, approved_at` present.
2. **rejectBooking happy path** — created `3kG0vFHcc71k73Ykx3Mg`, called with
   `reason="F-67-01 smoke reject"` → `200`; Firestore reflects
   `status=cancelled, rejection_reason=…, rejected_at` present.
3. **Error surfacing on bad bookingId** — bogus ID →
   `404 {error.message:"Booking not found.", status:"NOT_FOUND"}` (no silent failure).
4. **State guard** — re-approve already-confirmed booking →
   `400 {error.message:"Booking is not pending (current status: confirmed).", status:"FAILED_PRECONDITION"}`.
5. **Argument validation** — empty bookingId →
   `400 {error.message:"bookingId is required.", status:"INVALID_ARGUMENT"}`.

Both throwaway bookings deleted in the `finally` block; 0 residual test
data left on bookbed-dev.

Smoke script ran via Admin SDK (Firestore writes) + REST
`signInWithPassword` (no IAM `signBlob` needed) + REST callable POST.

## §4 Cross-platform Note

This PR fixes the **WEB** Owner Dashboard flow exercised in audit/67.
The same code paths back **iOS** and **Android** owner apps:

- `owner_bookings_screen.dart` is platform-agnostic Flutter, shared across web + mobile.
- `timeline_calendar_widget.dart` calendar actions ditto.
- `bookings_table_view.dart` is desktop/wide-layout; mobile uses the card view (`booking_card_actions.dart:283/:285`).

Because the fix is in the repository layer, **all three surfaces inherit
the routing change automatically.** No per-platform changes were made.

**Cross-ref:** [audit/66 iOS deepflow](./66-ios-deepflow-2026-05-28.md) §G
(if Terminal B captured the same flow on iOS during the in-progress
Marionette smoke), and audit/63 Android. Worth re-verifying the
approve/reject flow on iOS/Android once Terminal B finishes its iOS
session to confirm the snackbar surfaces error messages clearly on
mobile-card UI as well as on desktop-table UI.

## §5 Related Findings — explicitly NOT touched

- **F-67-02 Widget guest_name silent failure** (audit/67 §G2) — different
  layer (widget submission, not owner action). Not adjacent to this PR.
- **Rules tightening to deny client status writes** — could shrink the
  surface further now that no client code writes status, but a `diff()`
  affectedKeys check (mirroring `users` rule) is non-trivial and risks
  blocking legitimate update flows (`cancelBooking`, `completeBooking`,
  edit dialog still SDK-writes). **Deferred to follow-up PR** with a
  dedicated rules-test pass.
- **`cancelBooking` / `completeBooking` still SDK-direct.** Out of scope
  for F-67-01 (audit/67 §G only covers Confirm/Reject). If we ever
  enforce server-only writes via rules, these need analogous callables
  first.
- **`getUnitIcalFeed` cache invalidation on reject** — already handled by
  the `onBookingStatusChange` trigger (`bookingManagement.ts:474+` calls
  `invalidateIcalCache`); unchanged by this PR. memory
  [[ical-cache-no-invalidation]] is about the 5-min TTL gap during
  *pending* lifecycle, not status transitions, and isn't affected.

## §6 Deploy + Rollback

**Deployed to bookbed-dev:** `approveBooking(europe-west1)`,
`rejectBooking(europe-west1)` (2026-05-28 09:22 UTC).

**PROD cutover:** included in the next PROD CF deploy batch (NOT in this
PR). No prereq env vars; no rules change; safe alongside the existing
`onBookingStatusChange` trigger. Rollback = redeploy without the two
callables; the SDK-direct path is preserved in git history if needed
(it was just removed from the Dart repo — but old client builds calling
SDK directly would still work against the unchanged rules).

**Client compatibility:** old app builds that still call
`bookingDoc.reference.update(...)` directly would continue to work
against the existing rules (no rule tightening this PR). New builds
route through CF.
