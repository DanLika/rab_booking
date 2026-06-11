---
paths:
  - "firestore.rules"
  - "firestore.indexes.json"
---

# Firestore Indexi & Rules

## Composite vs Single-Field Indexi

- **Single-field indexi** = Firestore automatski kreira za SVA polja (equality, whereIn, orderBy)
- **Composite indexi** = MORAJU biti eksplicitno definirani u `firestore.indexes.json`

## Kada Treba Composite Index

```dart
// ✅ NE treba composite (single field equality)
.where('subdomain', isEqualTo: subdomain)

// ✅ NE treba composite (range na ISTOM polju)
.where('date', isGreaterThanOrEqualTo: start)
.where('date', isLessThanOrEqualTo: end)

// ❌ TREBA composite (equality + range na RAZLIČITIM poljima)
.where('unit_id', isEqualTo: unitId)
.where('start_date', isLessThanOrEqualTo: endDate)
```

## Collection vs Collection Group

- **Collection index** = query na subcollection (`collection('properties/{id}/units')`)
- **Collection group index** = query preko SVIH subcollections (`collectionGroup('bookings')`)
- ⚠️ **Collection group index NE pokriva collection query i obrnuto!**

## Potrebni Indexi (Widget & Cloud Functions)

| Collection | Fields | Scope |
|------------|--------|-------|
| `bookings` | `unit_id` + `status` | Collection Group |
| `bookings` | `unit_id` + `check_in` | Collection Group |
| `bookings` | `owner_id` + `created_at` | Collection Group |
| `daily_prices` | `unit_id` + `date` | Collection Group |
| `daily_prices` | `unit_id` + `available` | Collection Group |
| `ical_events` | `unit_id` + `start_date` | Collection Group |
| `ical_events` | `unit_id` + `start_date` | Collection |

## Analytics Security Rules

Analytics koristi `collectionGroup('bookings')` sa `whereIn` na `unit_id` i range filter na `check_in`.
```
// firestore.rules - Case 2 u bookings collection group
(isAuthenticated() && 'unit_id' in resource.data && 'check_in' in resource.data)
```
Bez ove rule, analytics query vraća `permission-denied` error.

## Deploy Indexa

```bash
firebase deploy --only firestore:indexes
```

## Napomena o index ordering

When combining range (`>=`) and equality/whereIn filters, equality fields must come FIRST in the index.

## Dead indexes pruned (changelog 6.74, 2026-05-22)

2 collection-group indexes removed from `firestore.indexes.json` after grep-verified zero `collectionGroup('<name>')` refs in `lib/` and `functions/src/`:

| Removed | Scope | Reason |
|---|---|---|
| `booking_services{booking_id + created_at}` | `COLLECTION_GROUP` | Collection name has zero refs ANYWHERE in repo. Likely never implemented. |
| `securityEvents{userId + timestamp}` | `COLLECTION_GROUP` | Only used as `users/{uid}/securityEvents` subcollection (4 sites in `security_events_service.dart`); CG path never queried. |

Server-side orphans remain on `bookbed-dev` until force-deleted (`firebase deploy --only firestore:indexes --force --project bookbed-dev`). Harmless — not regenerated.

**Before pruning more**: run `grep -rn "collectionGroup(" lib/ functions/src/ --include="*.dart" --include="*.ts"` and verify the candidate name yields zero hits. Sub-collection usage via `.collection('<name>')` does NOT count — only `collectionGroup(...)` consumes a CG index.

## Drift prod ↔ `firestore.indexes.json` (audit 2026-05-18)

Prod (`rab-booking-248fc`) has console-created CG single-field exemptions that are **NOT** mirrored in this repo's `firestore.indexes.json`. Fresh-project deploys (e.g. `bookbed-dev`) will hit `FAILED_PRECONDITION` for:

| Field | Used by | Query |
|-------|---------|-------|
| `bookings.payment_intent_id` (CG) | `functions/src/stripePayment.ts:923` | `collectionGroup('bookings').where('payment_intent_id', '==', …).limit(1)` — every Stripe webhook |
| `bookings.guest_email` (CG) | `functions/src/deleteUserAccount.ts:152` | `collectionGroup('bookings').where('guest_email', '==', userEmail)` — account-deletion anonymize |

Before deploy to fresh project: add both as `fieldOverrides` in `firestore.indexes.json` OR diff `firebase firestore:indexes --project rab-booking-248fc > /tmp/prod.json` against the file and reconcile.

## ✅ bookings read rule — T11c FULLY CLOSED (2026-05-22, commit `ab6bdb3d`)

### Status

`firestore.rules` originally allowed `read` on `bookings/{id}` (subcollection + CG + deprecated top-level) via FOUR disjunctive public-ish clauses. All public clauses are now REMOVED:

| Clause | Pre-hotfix | Now |
|---|---|---|
| `isPropertyOwner(propertyId)` | ✅ ALLOW | ✅ ALLOW (unchanged) |
| `owner_id == auth.uid` | ✅ ALLOW | ✅ ALLOW (unchanged) |
| `unit_id` + `status` field-presence | ✅ ALLOW (public) | ❌ REMOVED (T11c, 2026-05-22) |
| `stripe_session_id` field-presence | ✅ ALLOW (public) | ❌ REMOVED (T11-hotfix-partial, 2026-05-18) |
| `booking_reference` field-presence | ✅ ALLOW (public) | ❌ REMOVED (T11-hotfix-partial, 2026-05-18) |

Anonymous CG booking reads are fully denied (`firestore.rules:510-521` — admin or `owner_id == auth.uid` only). Replacement callables:
- Widget calendar availability → `getUnitAvailability(unitId, dateRange)` (eu-west1, zero PII)
- Stripe poll → `getBookingByStripeSession(sessionId)`
- Guest view → `verifyBookingAccess(ref, email, token)`

Privacy tradeoff accepted: widget lost pending/confirmed visual distinction; realtime → 30s polling. See SF-019 + CLAUDE.md NIKADA table.

⚠️ Audit gotcha (hit in audit/123): older copies of this doc described clause 1 as "INTENTIONALLY KEPT / deferred" — that was pre-2026-05-22 state. The rules file is ground truth; verify there before re-reporting CG bookings as publicly readable.

### Audit trail

- Partial fix: `audit/06-bookings-hotfix-partial.md`
- Full closure: T11c, commit `ab6bdb3d` (2026-05-22), SF-019

## Notification CG fallback is broken (silent)

`lib/.../services/notification_service.dart` (`:110, :145, :205, :250`) has an `ownerId == null` fallback that does `collectionGroup('notifications').where(FieldPath.documentId, ...)`. **Two failures stacked:**
1. No CG rule for `notifications` in `firestore.rules` (only `users/{uid}/notifications/{id}`) → rejected.
2. `FieldPath.documentId` + CG = empty result (Firestore expects full path — see MEMORY #4).

Happy path uses `ownerId != null` and works. Fallback silently returns nothing. Fix when refactoring; not urgent.
