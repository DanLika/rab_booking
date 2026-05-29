# audit/77 — Rules-Tighten Migration (Phase A): close F-67-01 class

**Date:** 2026-05-29
**Branch:** `ops/rules-tighten-phase-a-complete-edit-cf`
**PR:** TBD
**Worktree:** `/tmp/bb-rulesA-wt`
**Predecessors:** [audit/72 owner-cancel CF](./72-owner-cancel-fix-2026-05-28.md) · [audit/76 PROD deploy](./76-prod-deploy-2026-05-28.md) §7
**Successor:** audit/78 — Phase B rules-tighten deny (separate PR, after Phase A merged + PROD-deployed)

## §1 Scope

The F-67-01 booking-status-write migration class still had one direct client SDK
write (`repository.completeBooking()`) and two dead-but-callable client methods
(`BookingService.updateBookingStatus`, `BookingService.cancelBooking`). audit/76
§7 listed them as "still pending" alongside the future rules-tighten work.

This PR closes the migration:

- **NEW CF:** `completeBooking` (europe-west1) in `functions/src/bookingActions.ts`,
  mirroring `approveBooking` / `rejectBooking` / `cancelBooking`.
- **Client rewrite:** `firebase_owner_bookings_repository.completeBooking()` now
  calls the CF via `httpsCallable` instead of `bookingDoc.reference.update(...)`.
- **Dead-method cleanup:** removed
  `BookingService.updateBookingStatus({bookingId, status})` and
  `BookingService.cancelBooking({bookingId, reason, cancelledBy})` from
  `lib/core/services/booking_service.dart`. Both had **zero callers** in `lib/`
  (verified by `grep -rn "bookingId:" lib --include='*.dart' | grep -iE
  "updateBookingStatus\(|cancelBooking\("` returning empty). Leaving them in
  would have left a residual rules-deny surface ahead of Phase B.
- **Test suite:** new `functions/test/bookingActions.test.ts` — first
  unit-test coverage for the four owner action CFs (audit/76 §7 follow-up).
  16 cases.

### §1.1 Out of scope — `editBooking`

The brief asked for a new `editBooking` CF on the assumption that the edit-dialog
status writes were still going direct to Firestore. They are not — `lib/features
/owner_dashboard/presentation/widgets/edit_booking_dialog.dart:696` already
routes through `ownerBookingCallableService.updateBooking()` →
`updateBookingAtomic` CF (`functions/src/atomicBooking.ts:1919`), which handles
field-by-field updates including `status` against
`OWNER_BOOKING_ALLOWED_STATUSES` (atomicBooking.ts:2086-2092).

A net-new `editBooking` CF would duplicate the same surface. The user-chosen
scope (see §1.2) shipped `completeBooking` only.

### §1.2 In-flight scope expansion — first-time PROD deploy of two CFs

`updateBookingAtomic` + `createOwnerBookingAtomic` exist in source and are
**deployed on bookbed-dev** (verified `gcloud functions list --project=bookbed-dev`)
but **never deployed on PROD** (gcloud lists `createBookingAtomic`,
`updateBookingTokenExpiration` etc., but neither `updateBookingAtomic` nor
`createOwnerBookingAtomic`). This means the PROD edit-dialog flow has been
silently 404'ing against a non-existent CF.

This PR's PROD deploy step ships both as a side-effect of closing the
migration class — the dependency is necessary so Phase B can deny client status
writes without stranding the edit dialog.

## §2 Files Touched

| File | Change |
|---|---|
| `functions/src/bookingActions.ts` | +50 lines: `completeBooking` `onCall`; JSDoc header refreshed to mention the four actions. |
| `lib/features/owner_dashboard/data/firebase/firebase_owner_bookings_repository.dart` | `completeBooking()` rewritten to call `httpsCallable('completeBooking')` mirror of existing `cancelBooking()` (line 934). |
| `lib/core/services/booking_service.dart` | Two methods deleted (updateBookingStatus + cancelBooking — both unreferenced); cleanup comment block in their place. |
| `functions/test/bookingActions.test.ts` | NEW. 16 cases (10 `completeBooking` + 3 `approveBooking` smoke + 3 `rejectBooking` smoke). |

`functions/src/atomicBooking.ts` is **untouched** — `updateBookingAtomic` +
`createOwnerBookingAtomic` exist in source, just need PROD deploy.

`firestore.rules` is **untouched** — Phase B (separate PR, audit/78).

## §3 completeBooking CF — design notes

- Region: `europe-west1` (consistent with sibling actions; audit/58 F-58-08).
- Source-status allow-list: **`['confirmed']` only**. Both UI entry points gate
  the button to `BookingStatus.confirmed && booking.isPast`
  (`owner_bookings_screen.dart:1819`, `bookings_table_view.dart:484`) — accepting
  `pending` server-side would enlarge the attack surface without enabling any
  legitimate workflow.
- Fields written by Admin SDK:
  `status='completed'`, `completed_at=serverTimestamp`,
  `updated_at=serverTimestamp`.
- Email / iCal fan-out: unchanged. The existing `onBookingStatusChange`
  Firestore trigger (`functions/src/bookingManagement.ts`) handles both.
- Ownership check: shared `loadOwnedBookingForAction` helper — same logic
  used by approve/reject/cancel.
- Auth check: shared `requireAuth` helper.

## §4 Verification — local

| Gate | Command | Result |
|---|---|---|
| Functions build | `cd functions && npm run build` | ✅ clean (tsc) |
| Functions unit tests | `cd functions && npm test` | ✅ 334 / 334 (up from 318 pre-PR, 16 new) |
| Rules tests (unchanged in this PR) | `cd functions && npm run test:rules` | ✅ 39 / 39 (no rules touched) |
| Flutter analyze | `flutter analyze` | ✅ 92 issues, identical to `main` baseline (no new) |
| Flutter test | `flutter test` | ✅ 1205 / 1205 |
| Dart format | `dart format --set-exit-if-changed lib/...` | ✅ unchanged |

`flutter analyze` raw count on first run was 1538 — pub-cache desync because
`.g.dart` files are gitignored and a fresh worktree has none. Recipe per
`.claude/rules/build-runner.md`:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

After regen → 92 issues, matching `main`. Documented for future worktrees.

## §5 Verification — dev deploy + smoke (bookbed-dev)

### §5.1 Deploy

```bash
cd /tmp/bb-rulesA-wt
firebase deploy --only functions:completeBooking --project bookbed-dev
# → ✔  functions[completeBooking(europe-west1)] Successful update operation.
```

### §5.2 IAM binding (anon 401 reachability prereq)

New CFs do not get `allUsers` `roles/run.invoker` automatically (audit/76 §3
class — same pattern). Bound explicitly so the canonical anonymous-401 check
fires from the CF, not GFE:

```bash
gcloud functions add-invoker-policy-binding completeBooking \
  --region=europe-west1 --member=allUsers --project=bookbed-dev
# → bindings:[{members:[allUsers], role:roles/run.invoker}]
```

### §5.3 Anon 401 (reachability)

```text
POST https://europe-west1-bookbed-dev.cloudfunctions.net/completeBooking
body: {"data":{"bookingId":"x"}}
→ HTTP=401
  {"error":{"message":"You must be signed in.","status":"UNAUTHENTICATED"}}
```

Matches the pattern from `approveBooking` / `rejectBooking` / `cancelBooking`
on dev (and audit/76 §6 on PROD).

### §5.4 End-to-end smoke (authenticated)

Script: `audit/smoke/complete-booking-smoke.js` (uses
`identitytoolkit:signInWithPassword` for the bookbed-test owner, web API key
loaded at runtime from `lib/firebase_options_dev.dart`). Test owner UID:
`GILVItIVP5R8WXfnMmyMo1ykhUm2`.

```text
1. mint id token
  idToken=922 chars OK
2. seed throwaway confirmed booking
  bookingId=rbM9xFqb9APBGnkrDDb8
3. call completeBooking CF
  HTTP=200
  body={"result":{"success":true,"bookingId":"rbM9xFqb9APBGnkrDDb8","status":"completed"}}
4. read-back assert
  status=completed
  completed_at=set
  updated_at=set
5. negative: re-call (should reject — not confirmed anymore)
  HTTP=400
  body={"error":{"message":"Booking status \"completed\" is not eligible for this action.","status":"FAILED_PRECONDITION"}}
SMOKE PASS
cleanup: throwaway booking deleted
```

Smoke covers: auth gate, ownership lookup, state guard, Firestore write,
read-back parity, idempotency rejection on second call. Throwaway booking
deleted on cleanup.

## §6 PROD Deploy — gate

Awaiting explicit gate word **`go prod cf complete edit`** per the brief.
Once gated:

```bash
cd /tmp/bb-rulesA-wt
firebase deploy \
  --only functions:completeBooking,functions:updateBookingAtomic,functions:createOwnerBookingAtomic \
  --project rab-booking-248fc
```

Three CFs ship together:

1. `completeBooking` — new (this PR).
2. `updateBookingAtomic` — first-time PROD deploy (existed in source; never
   deployed). Required so edit-dialog stops 404'ing.
3. `createOwnerBookingAtomic` — first-time PROD deploy (same class as #2).

### §6.1 Post-deploy IAM (audit/76 §3 pattern)

For all three new PROD CFs:

```bash
for FN in completeBooking updateBookingAtomic createOwnerBookingAtomic; do
  gcloud functions add-invoker-policy-binding "$FN" \
    --region=europe-west1 --member=allUsers --project=rab-booking-248fc
done
```

### §6.2 Anon 401 confirmation (per CF)

Expected `HTTP=401` body `{"error":{"message":"You must be signed in.","status":"UNAUTHENTICATED"}}`
from each:
- `https://europe-west1-rab-booking-248fc.cloudfunctions.net/completeBooking`
- `https://europe-west1-rab-booking-248fc.cloudfunctions.net/updateBookingAtomic`
- `https://europe-west1-rab-booking-248fc.cloudfunctions.net/createOwnerBookingAtomic`

A 403 (GFE) means the IAM binding for that CF was missed.

## §7 Phase B — preparation notes (for the next PR, NOT this one)

Carries forward into `audit/78-rules-tighten-deny-2026-05-29.md`. Things to
record now so the next worktree picks them up:

1. **Status-field denylist.** Brief proposed:
   `['status', 'approved_at', 'rejected_at', 'rejection_reason', 'cancelled_at',
   'cancellation_reason', 'completed_at', 'updated_at_by_status_change']`.
   Add CF-only fields actually written by `cancelBooking`:
   - `refund_amount`
   - `refund_status`
   - `cancelled_by`
   Without these in the denylist, Phase B leaves a partial-migration window
   where clients can still write refund / cancellation-source metadata even
   though the status itself is locked. Doesn't widen the privilege gap much
   (these never enable a state transition on their own) but the spec is
   "CFs own all status-machine writes" → include them.

2. **`updated_at_by_status_change`** — referenced in the brief but **not
   present in `cancelBooking`/`approveBooking`/`rejectBooking`/`completeBooking`
   CF source.** Drop from the denylist or grep to confirm it's not residual
   from an earlier proposal.

3. **Owner SDK update of non-status fields** — must remain ALLOWED so
   `internal_notes` / `guest_count` etc. paths via `updateBookingAtomic` keep
   working. The denylist applies only to the status-machine subset.

4. **Test count expectation:** 39 → ~43+ with the 4 new cases from the brief.

## §8 Worktree state

```text
M   functions/src/bookingActions.ts
M   lib/core/services/booking_service.dart
M   lib/features/owner_dashboard/data/firebase/firebase_owner_bookings_repository.dart
?   functions/test/bookingActions.test.ts
?   audit/77-rules-tighten-migration-2026-05-29.md
?   audit/smoke/complete-booking-smoke.js
```

`functions/.env*` files were `install`-copied from the main worktree
(`/Users/duskolicanin/git/bookbed/functions/.env{,.bookbed-dev,.rab-booking-248fc}`)
because they're gitignored and don't propagate via `git worktree`. Not
committed.

`functions/package-lock.json` was briefly modified by a stray local `npm
install`; restored from `origin/main` before deploy to avoid the
`@emnapi/runtime@1.10.0` cloud-build mismatch.

## §9 Commit

```text
feat(bookings): migrate completeBooking + close F-67-01 status-write class
```

## §10 PR body — outline

- Adds `completeBooking` CF (europe-west1), mirroring the audit/72 + audit/76
  pattern.
- Rewrites `completeBooking()` client to call the CF; the previous direct
  SDK write was silently no-op for PROD owners under T11c rules (audit/67 §G).
- Removes two dead `BookingService` methods that wrote `bookings.status` on
  paper but had no callers — shrinks the surface area before Phase B.
- Adds first unit-test coverage for the booking-action CFs (audit/76 §7
  follow-up). 16 cases.
- PROD deploy ships **three** CFs: `completeBooking` (new) plus first-time
  PROD deploys of `updateBookingAtomic` + `createOwnerBookingAtomic`
  (existed in source, missing on PROD per `gcloud functions list`).
- Follow-up PR (audit/78) tightens `firestore.rules` to deny client
  `bookings.status` writes.
