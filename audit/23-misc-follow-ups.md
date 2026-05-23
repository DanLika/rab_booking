# audit/23 — Misc audit follow-ups (Tier 2D consolidated investigation)

**Date:** 2026-05-23
**Scope:** Doc-only investigation of 4 items deferred from prior audits. No code changed.
**Source items:** `audit/18-booking-count-audit.md`, `audit/12-widget-e2e-dev.md`, `audit/21-sprint-summary-2026-05-22-23.md` outstanding work.

---

## A. Adults/Children/Pets counter does not trigger `_saveFormData`

### Current state

`lib/features/widget/presentation/screens/booking_widget_screen.dart:3323-3348`:

```dart
GuestCountPicker(
  adults: _adults,
  children: _children,
  maxGuests: _unit?.maxGuests ?? 10,
  petFee: _unit?.petFee,
  maxPets: _unit?.maxPets,
  pets: _pets,
  isDarkMode: ref.watch(themeProvider),
  onAdultsChanged: (value) {
    if (mounted) {
      setState(() => _adults = value);
    }
  },
  onChildrenChanged: (value) {
    if (mounted) {
      setState(() => _children = value);
    }
  },
  onPetsChanged: _unit?.petFee != null
      ? (value) {
          if (mounted) {
            setState(() => _pets = value);
          }
        }
      : null,
),
```

Sibling form fields that DO persist:
- `_firstNameController` / `_lastNameController` / `_emailController` / `_phoneController` / `_notesController` — addListener(_saveFormDataDebounced) at lines 316-320
- Date picker `onDatesChanged` → `_saveFormData()` at line 2398
- Pill bar `onClose` / `onReserve` → `_saveFormData()` at lines 2788, 2799

### Problem statement

`_adults` and `_children` ARE in the persisted `BookingFormData` payload (`form_persistence_service.dart:24-25, 62-63, 96-97`), but the picker setState callbacks never trigger a write. A guest can adjust the counter, refresh the iframe, and lose their selection (falls back to `_adults: 2, _children: 0` defaults). Date selection persists; guest count silently doesn't.

**Secondary gap:** `_pets` is NOT in the persisted payload at all. Even adding `_saveFormData()` to `onPetsChanged` would not persist it — `form_persistence_service.dart` has no `pets` field.

### Recommended fix

`lib/features/widget/presentation/screens/booking_widget_screen.dart:3331-3347`:

```dart
onAdultsChanged: (value) {
  if (mounted) {
    setState(() => _adults = value);
  }
  _saveFormData();
},
onChildrenChanged: (value) {
  if (mounted) {
    setState(() => _children = value);
  }
  _saveFormData();
},
onPetsChanged: _unit?.petFee != null
    ? (value) {
        if (mounted) {
          setState(() => _pets = value);
        }
        _saveFormData();
      }
    : null,
```

For the pets persistence gap (separate sub-fix): add `pets` field to `BookingFormData` model in `form_persistence_service.dart` (constructor, `toJson`, `fromJson` with `?? 0` default), then thread through `_buildPersistedFormData()` (line 1747-ish) and `_loadFormData()` (line 1793-ish).

### Risk + priority

**P2.** UX-degradation only. No data integrity / security risk. Guest can re-select counter on refresh. But the per-field debounce pattern is already established for text inputs and the omission looks like an oversight from when the picker was added.

### Effort estimate

**XS** (3 lines for adults/children, 1 line for pets) — guest-count-only fix. **S** if including pets persistence (`form_persistence_service.dart` model field + 2 call sites).

---

## B. `in_progress` status parity across server-side conflict checks

### Current state

**Server (TypeScript) — 3 sites missing `in_progress`:**

`functions/src/availability.ts:152-153`:
```typescript
.collectionGroup("bookings")
.where("unit_id", "==", unitId)
.where("status", "in", ["pending", "confirmed"])
```

`functions/src/atomicBooking.ts:742`:
```typescript
.collection("bookings")
.where("status", "in", ["pending", "confirmed"])
.where("check_in", "<", checkOutDate)
.where("check_out", ">", checkInDate);
```

`functions/src/stripePayment.ts:604`:
```typescript
.collection("bookings")
.where("status", "in", ["pending", "confirmed"])
.where("check_in", "<", checkOutDate)
.where("check_out", ">", checkInDate);
```

**Client (Dart) — 2 sites include `in_progress`:**

`lib/features/widget/domain/constants/widget_constants.dart:175-179`:
```dart
abstract final class ActiveBookingStatuses {
  static const List<String> values = [
    BookingStatusValues.pending,
    BookingStatusValues.confirmed,
    'in_progress', // Legacy status still in some documents
  ];
}
```

`lib/shared/repositories/firebase/firebase_unit_repository.dart:166`:
```dart
.where('status', whereIn: ['pending', 'confirmed', 'in_progress'])
```

### Problem statement

Drift between client and server. Per the inline comment in `widget_constants.dart:178` ("Legacy status still in some documents"), `in_progress` exists in production bookings. The client correctly treats it as an active/blocking status. The three server hot-paths do NOT:

- `availability.ts` returns availability data missing `in_progress` blocks → widget calendar may show a slot as available
- `atomicBooking.ts` conflict check at booking creation → could allow double-booking against an `in_progress` doc
- `stripePayment.ts` placeholder conflict check → same risk during Stripe checkout flow

**Severity caveat:** If `in_progress` is truly legacy (no longer being written by any current code path), the doc count is finite and stable. If a backfill migration cleaned it up, the drift is documentation-only. If any documents still bear that status, this is a real concurrent-write hole.

**Verification needed:** Firestore query (read-only) — count of bookings with `status == "in_progress"` per environment.

### Recommended fix

Define a single shared constant in `functions/src/utils/bookingStatus.ts` (new file):

```typescript
export const ACTIVE_BOOKING_STATUSES = ["pending", "confirmed", "in_progress"] as const;
```

Then replace all 3 server literals with `ACTIVE_BOOKING_STATUSES`. Verify the composite index `(unit_id, status, check_in, check_out)` accommodates 3 status values without `in`-clause cardinality issues (Firestore allows up to 30 values in `in` — well within bounds).

Document the chosen source-of-truth in CLAUDE.md (functions/src cloud-functions rule).

### Risk + priority

**P1.** Data integrity. If any `in_progress` bookings exist in prod, the current code lets a second guest book overlapping dates. Read-side leak (availability) is observable; write-side (atomicBooking/stripePayment) is silent double-booking.

Need to run the verification query before sizing. If count == 0 in both envs, downgrade to P3 (code-hygiene only). If count > 0, P1 stays.

### Effort estimate

**S.** New shared constant file + 3 single-line replacements. Plus a 1-time read-only count query (Firestore Console or `admin.firestore().collectionGroup('bookings').where('status', '==', 'in_progress').count().get()`) before deploy to size the existing exposure.

---

## C. `_PoweredByBadge` hardcoded `https://bookbed.io`

### Current state

`lib/features/widget/presentation/screens/booking_widget_screen.dart:4772-4811`:

```dart
class _PoweredByBadge extends StatefulWidget {
  final String text;
  final Color color;
  const _PoweredByBadge({required this.text, required this.color});
  ...
}

class _PoweredByBadgeState extends State<_PoweredByBadge> {
  ...
  @override
  Widget build(BuildContext context) {
    ...
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => launchUrl(
          Uri.parse('https://bookbed.io'),
          mode: LaunchMode.externalApplication,
        ),
        ...
```

Centralization layer that already exists:

`lib/core/config/environment.dart:73`:
```dart
static String get marketingHost => 'bookbed.io';
```

Per the `widget.md` rule (audit/08 T13 centralization, commit `b0bad83c`): all `view.bookbed.io` / `app.bookbed.io` / `bookbed.io` literals should route through `EnvironmentConfig`. The badge URL violates that convention.

**Functional implication:** Because `marketingHost` is hardcoded `'bookbed.io'` across all envs (`environment.dart:73` — no per-env switch, per the rule's note "all environments share `bookbed.io`"), routing through it produces the same URL today. The refactor is consistency-only with one upside: if a future hosting decision changes the marketing domain (e.g. `book-bed.com` for legal reasons — that domain already appears in the AI KB as the support email host), the badge URL would track automatically.

### Embedder risk

The badge ships in the widget iframe content. External embedders see the click-through but don't depend on the specific URL (they cannot read iframe internals due to same-origin policy). No third-party integration in `docs/`, `audit/`, or `web/bookbed-overlay.js` references the badge URL. Safe to change.

### Recommended fix

`lib/features/widget/presentation/screens/booking_widget_screen.dart:4794-4798`:

```dart
import '../../../core/config/environment.dart';
...
child: GestureDetector(
  onTap: () => launchUrl(
    Uri.parse('https://${EnvironmentConfig.marketingHost}'),
    mode: LaunchMode.externalApplication,
  ),
```

Consider adding a `marketingBaseUrl` getter to `EnvironmentConfig` (mirroring `widgetBaseUrl` / `dashboardBaseUrl` already at lines 76 / 79) so the call site reads `Uri.parse(EnvironmentConfig.marketingBaseUrl)` without manual `https://` concatenation. That's a one-line addition to `environment.dart`.

### Risk + priority

**P3.** Pure consistency / future-proofing. No behavior change at runtime. The widget.md rule already documents that iCal UID domains + embed-snippet copy MUST stay literal `bookbed.io`. The badge is neither and was missed during T13 centralization.

### Effort estimate

**XS.** 1 import + 1 line replacement. (Plus 1 optional line to add `marketingBaseUrl` getter for symmetry.)

---

## D. `calculateBookingNights()` — throw vs default-to-1 for same-civil-day edge

### Current state

`functions/src/utils/dateValidation.ts:246-261`:

```typescript
export function calculateBookingNights(
  checkIn: admin.firestore.Timestamp,
  checkOut: admin.firestore.Timestamp
): number {
  const nights = Math.ceil(
    (checkOut.toDate().getTime() - checkIn.toDate().getTime()) /
      (1000 * 60 * 60 * 24)
  );

  // Sanity check (should never happen if dates are validated)
  if (nights < 1) {
    throw new Error("Booking nights calculation resulted in < 1 night");
  }

  return nights;
}
```

Upstream validator `validateAndConvertBookingDates()` at `functions/src/utils/dateValidation.ts:162-168`:

```typescript
// Check: checkOut MUST be after checkIn
if (checkOutDateObj <= checkInDateObj) {
  throw new HttpsError(
    "invalid-argument",
    "Check-out date must be after check-in date"
  );
}
```

Then `STEP 6 NORMALIZE` (lines 211-215) snaps BOTH dates to UTC midnight of their Zagreb civil day via `normalizeToZagrebCivilDayUTC()`. So a request like `checkIn=2026-05-23T08:00`, `checkOut=2026-05-23T20:00` (same civil day, 12h apart, both >= today):

1. Line 163 check passes (12h > 0).
2. Normalization snaps both to `2026-05-23T00:00 UTC` → identical Timestamps.
3. Downstream `calculateBookingNights()` computes `Math.ceil(0)` → 0 → throws plain `Error`.

Callers:
- `functions/src/atomicBooking.ts:776` — wrapped in transaction, plain `Error` surfaces as `internal` HttpsError to client + Sentry alert
- `functions/src/stripePayment.ts:430` — same wrapping
- `functions/src/verifyBookingAccess.ts:168`, `functions/src/getBookingByStripeSession.ts:92` — read-side, on already-persisted bookings; same-day data cannot exist there because writes throw

### Problem statement

Two concerns:

1. **Error type:** Plain `Error` from `calculateBookingNights` becomes `internal`-code HttpsError, which is NOT in the dropped-set per the `sentry.ts` `beforeSend` filter (`cloud-functions.md`). Every same-day attempt fires a Sentry alert tagged as a server bug. The actual cause is invalid input that pre-normalization validation missed. Wrong tier of error noise.

2. **Sequencing:** The validator throws a user-friendly `invalid-argument` HttpsError ONLY when raw checkOut <= raw checkIn. The same-civil-day case (12h apart) bypasses that and crashes in a downstream helper. User sees a confusing "internal error" instead of "you selected the same day for arrival and departure — minimum stay is 1 night".

### Risk analysis: throw vs default-to-1

| Choice | Behavior | Risk |
|---|---|---|
| **Current — throw plain Error** | 500 Internal to client, Sentry noise | Bad UX, bad signal-to-noise |
| **Throw HttpsError(invalid-argument)** | Clear client message, no Sentry alert (per beforeSend filter) | Safe. Caller still rejects the booking. |
| **Default-to-1** | Booking succeeds, guest charged for 1 night they did not intend | **Unsafe.** Silently coerces ambiguous intent into a chargeable transaction. Could trigger payment dispute / refund request. |

The "default-to-1" framing is a bait option — it sounds defensive but trades data integrity for hiding the error. Same-civil-day is not a typo; it's "I want to arrive and leave the same day," which is not a valid booking in this product. The right behavior is to reject early with a clear message, NOT to assume the guest meant +1 night.

### Recommended fix

Move the same-civil-day rejection to `validateAndConvertBookingDates` AFTER normalization, so all date-order checks live at the validator boundary:

`functions/src/utils/dateValidation.ts` — after line 215 (where `checkInDate` and `checkOutDate` Timestamps are built post-normalization):

```typescript
// Post-normalization: reject same-civil-day after Zagreb-TZ snap.
// Pre-normalization order check (line 163) only catches raw checkOut <= checkIn;
// it lets through cases where 2 timestamps fall on the same Zagreb civil day
// (e.g. 08:00 + 20:00 same date), which normalize to identical midnights.
if (checkInDate.isEqual(checkOutDate)) {
  throw new HttpsError(
    "invalid-argument",
    "Stay must be at least 1 night. Please select different check-in and check-out dates."
  );
}
```

Then either keep `calculateBookingNights`'s sanity-check throw (now genuinely unreachable, so leave as defense-in-depth) OR upgrade its `throw new Error` to `throw new HttpsError("internal", ...)` so if it ever fires, at least Sentry attribution is correct.

### Risk + priority

**P2.** UX bug + Sentry noise. Not security, not data corruption. But each occurrence wastes oncall attention via Sentry. Frequency is bounded by how often guests construct same-civil-day URLs (rare in normal widget flow because the date picker enforces selecting two different days — likely only reachable via direct API call or malformed iframe params).

### Effort estimate

**XS.** ~5 lines added to validator, optional 1-line cleanup of `calculateBookingNights` error type. Plus unit test if a test file for `dateValidation` exists (none currently — separate gap).

---

## Bundle into 1 PR or 4?

### File overlap matrix

| Item | Files touched |
|---|---|
| A | `lib/features/widget/presentation/screens/booking_widget_screen.dart`, optional `lib/features/widget/services/form_persistence_service.dart` |
| B | `functions/src/utils/bookingStatus.ts` (new), `functions/src/availability.ts`, `functions/src/atomicBooking.ts`, `functions/src/stripePayment.ts` |
| C | `lib/features/widget/presentation/screens/booking_widget_screen.dart`, optional `lib/core/config/environment.dart` |
| D | `functions/src/utils/dateValidation.ts` |

A and C touch the same file (`booking_widget_screen.dart`). B and D touch `functions/src/`. No overlap between client+server.

### Recommendation: **2 PRs**

**PR-1 (Flutter, A + C):** `fix(widget): persist guest counter + route badge URL through EnvironmentConfig`
- A and C share `booking_widget_screen.dart`. Combined diff stays small (~10 lines net).
- Both are P2/P3 UX-tier. No behavior risk worth isolating.

**PR-2 (CF, B + D):** `fix(functions): in_progress conflict-check parity + same-day validation`
- B and D are both Cloud Functions changes that benefit from a single deploy cycle.
- B is P1 (pending verification query result) — could carry D as a quick rider.
- Different files within `functions/src/` but a shared `cd functions && npm run deploy` step per CLAUDE.md Critical Learning #3 → one CF deploy covers both.

**NOT recommended: 1 PR.** Mixing CF + Flutter triggers different review paths, different CI gates (CF lint vs `flutter analyze`), and complicates rollback if B's read-only count query reveals a larger problem than expected.

**NOT recommended: 4 PRs.** A and C are 1-line each on the same file — splitting is pure ceremony.

### Priority summary

| Item | Priority | Effort | PR |
|---|---|---|---|
| B (in_progress parity) | **P1** (pending verification) | S | PR-2 |
| A (guest counter persist) | **P2** | XS | PR-1 |
| D (same-day validation) | **P2** | XS | PR-2 |
| C (badge URL) | **P3** | XS | PR-1 |

### Sequencing

1. Run the B verification count query first (read-only, ~5 min). If `in_progress` count == 0 in both envs, B drops to P3 and PR-2 reduces to D-only (~5 min PR).
2. Otherwise PR-2 ships first (higher priority, contains the safety fix).
3. PR-1 (Flutter UX) ships alongside or after.

---

## See also

- `audit/18-booking-count-audit.md` — calculateBookingNights canonical helper context (T1)
- `audit/12-widget-e2e-dev.md` — Q7 marketing-host centralization origin
- `audit/21-sprint-summary-2026-05-22-23.md` — outstanding work list
- `.claude/rules/cloud-functions.md` — Sentry beforeSend client-fault filter (drives D recommendation)
- `.claude/rules/widget.md` — `EnvironmentConfig` convention for host literals (drives C recommendation)
