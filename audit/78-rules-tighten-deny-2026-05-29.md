# audit/78 — Rules-Tighten Phase B: deny client status-machine writes

**Date:** 2026-05-29
**Branch:** `ops/rules-tighten-phase-b`
**Predecessor:** [audit/77](./77-rules-tighten-migration-2026-05-29.md) Phase A — `completeBooking` CF + first-time PROD deploy of `updateBookingAtomic` + `createOwnerBookingAtomic`.
**Successor:** none planned — F-67-01 class fully closed after this PR.

## §1 Scope

Phase B closes the F-67-01 booking-status-write surface at the rules layer. Client-SDK direct updates to the seven booking status-machine fields are now denied; transitions must go through the four owner-action callables (`approveBooking`, `rejectBooking`, `cancelBooking`, `completeBooking`) or `updateBookingAtomic`. Admin SDK still bypasses rules, so the CFs themselves are unaffected.

### §1.1 Denied fields (exact set)

Per the brief — exactly 7 fields:

```
status, approved_at, rejected_at, rejection_reason,
cancelled_at, cancellation_reason, completed_at
```

`updated_at_by_status_change` (from brief draft) was dropped — it does not appear in `bookingActions.ts` source. `refund_amount` / `refund_status` / `cancelled_by` (audit/77 §7 notes) were NOT added: brief is authoritative, and the three fields never enable a state transition on their own. Can be folded in via a follow-up if the scope is revisited.

### §1.2 Non-status fields stay writable

Owners continue to write `internal_notes`, `guest_count`, etc. directly via SDK. The denylist applies only to the seven status-machine fields.

## §2 Files Touched

| File | Change |
|---|---|
| `firestore.rules` | Bookings subcollection rule `allow update, delete` split into separate `allow update` (with `diff().affectedKeys().hasAny([...])` deny) + `allow delete` (unchanged). |
| `functions/test/firestore_rules/bookings.test.ts` | +7 Phase B test cases (status DENY, 6-field iteration DENY, non-status ALLOW, atomic-mix DENY, create-with-pending ALLOW, foreign uid DENY, delete ALLOW). |

## §3 Rule diff

```diff
- allow update, delete: if isPropertyOwner(propertyId);
+ allow update: if isPropertyOwner(propertyId)
+   && !request.resource.data.diff(resource.data).affectedKeys()
+        .hasAny(['status','approved_at','rejected_at','rejection_reason','cancelled_at','cancellation_reason','completed_at']);
+ allow delete: if isPropertyOwner(propertyId);
```

`diff().affectedKeys()` semantics: keys whose value (or presence) changed between `resource.data` and `request.resource.data`. A write that sets a field to its existing value is NOT affected — confirmed during test authoring (first version of the status DENY test failed because seed status='confirmed' and update wrote 'confirmed', so `affectedKeys()` was empty). Test now writes `'cancelled'` to force the diff.

## §4 Verification — local

| Gate | Command | Result |
|---|---|---|
| Rules tests | `cd functions && npm run test:rules` | ✅ 46 / 46 (up from 39 pre-PR, 7 new) |

## §5 Verification — deploy

```text
=== Deploy rules to bookbed-dev ===
✔  cloud.firestore: rules file firestore.rules compiled successfully
✔  firestore: released rules firestore.rules to cloud.firestore
✔  Deploy complete!

=== Deploy rules to PROD rab-booking-248fc ===
✔  cloud.firestore: rules file firestore.rules compiled successfully
✔  firestore: released rules firestore.rules to cloud.firestore
✔  Deploy complete!
```

Both environments now reject client status writes. Owner flow goes through the four PROD CFs deployed in audit/77 §6 / this session.

## §6 PROD CF prerequisites (audit/77 carryover)

Phase B requires the four owner-action CFs to be live on PROD. Verified this session:

| CF | Region | Deploy | IAM | Anon 401 |
|---|---|---|---|---|
| `approveBooking` | europe-west1 | ✅ (audit/76) | bound (audit/76) | UNAUTHENTICATED |
| `rejectBooking` | europe-west1 | ✅ (audit/76) | bound (audit/76) | UNAUTHENTICATED |
| `cancelBooking` | europe-west1 | ✅ (audit/76) | bound (audit/76) | UNAUTHENTICATED |
| `completeBooking` | europe-west1 | ✅ this session | bound this session | UNAUTHENTICATED |
| `updateBookingAtomic` | us-central1 | ✅ first PROD deploy this session | bound this session | UNAUTHENTICATED |
| `createOwnerBookingAtomic` | us-central1 | ✅ first PROD deploy this session | bound this session | UNAUTHENTICATED |

Anon 401 smoke ran against each post-IAM-binding; all returned canonical `{"error":{"message":"…","status":"UNAUTHENTICATED"}}` (not 403/GFE).

## §7 Worktree state

```text
M   firestore.rules
M   functions/test/firestore_rules/bookings.test.ts
?   audit/78-rules-tighten-deny-2026-05-29.md
```

`functions/.env*` and `functions/node_modules/` copied locally for emulator-driven rules tests (same pattern as audit/77 §8). Neither tracked.
