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

## Drift prod ↔ `firestore.indexes.json` (audit 2026-05-18)

Prod (`rab-booking-248fc`) has console-created CG single-field exemptions that are **NOT** mirrored in this repo's `firestore.indexes.json`. Fresh-project deploys (e.g. `bookbed-dev`) will hit `FAILED_PRECONDITION` for:

| Field | Used by | Query |
|-------|---------|-------|
| `bookings.payment_intent_id` (CG) | `functions/src/stripePayment.ts:923` | `collectionGroup('bookings').where('payment_intent_id', '==', …).limit(1)` — every Stripe webhook |
| `bookings.guest_email` (CG) | `functions/src/deleteUserAccount.ts:152` | `collectionGroup('bookings').where('guest_email', '==', userEmail)` — account-deletion anonymize |

Before deploy to fresh project: add both as `fieldOverrides` in `firestore.indexes.json` OR diff `firebase firestore:indexes --project rab-booking-248fc > /tmp/prod.json` against the file and reconcile.

## ⚠️ HIGH security flag — bookings read rule

`firestore.rules` `match {path=**}/bookings/{bookingId}` (and the subcollection mirror) allow `read` when **both** `unit_id` and `status` exist on the doc. Since every booking has those, this effectively makes **every booking publicly readable** by any client with a Firebase API key — bypasses Flutter UI filtering. Comment in file labels it intentional ("Public for availability display, app code filters PII"); client-side filtering is NOT access control.

**DO NOT "fix" this casually** — calendar availability + widget flows depend on the public read. Any tightening (App Check token, sentinel placeholder docs, server-mediated availability) must come with a flow audit. Treat as separate triage item, not casual cleanup.

## Notification CG fallback is broken (silent)

`lib/.../services/notification_service.dart` (`:110, :145, :205, :250`) has an `ownerId == null` fallback that does `collectionGroup('notifications').where(FieldPath.documentId, ...)`. **Two failures stacked:**
1. No CG rule for `notifications` in `firestore.rules` (only `users/{uid}/notifications/{id}`) → rejected.
2. `FieldPath.documentId` + CG = empty result (Firestore expects full path — see MEMORY #4).

Happy path uses `ownerId != null` and works. Fallback silently returns nothing. Fix when refactoring; not urgent.
