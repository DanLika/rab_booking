# Booking night/guest count source-of-truth audit

**Branch**: `audit/booking-count-audit`
**Date**: 2026-05-22
**Status**: documentation only — no code changes
**Scope**: audit follow-up to `audit/07-chrome-smoke-test.md` issue #10 ("Booking night/guest count inconsistency across widget/calendar/CF")

## 0. TL;DR

- Persisted booking doc stores `check_in` + `check_out` (Firestore Timestamps) + `guest_count` (int). **`nights` is NEVER persisted.** Every surface derives it.
- Derivation uses two algorithms that disagree if Timestamps aren't UTC-midnight-aligned:
  - **Dart client**: `checkOut.difference(checkIn).inDays` → integer truncation toward zero (≈ `Math.floor`).
  - **TS server**: `Math.ceil((checkOut_ms - checkIn_ms) / 86_400_000)` → round up.
- `functions/src/utils/dateValidation.ts` validates date order + past-check but **persists raw client `Date`** via `Timestamp.fromDate(checkInDateObj)` — it does NOT normalize to midnight before write (lines 196-199). If the client sends ISO with time component, Firestore stores it as-is.
- **Floor vs ceil agreement**: when Timestamps are exact midnight, both = N. When time component drifts (e.g. DST 23h/25h day) Dart `inDays` rounds down by 1, TS `Math.ceil` rounds up — they can disagree by 1.
- Today's status: empirically widget always submits midnight dates (date picker only). Confirmation screens, email service, owner dashboard, iCal feeds all stay consistent **as long as** the upstream Timestamp lands at midnight. No production drift observed yet, but no architectural guard prevents it.
- Guest count flow is clean: single `guest_count` field, `totalGuests = adults + children` everywhere on read, `pet_count` separate.

## 1. Persisted booking-doc schema (read from `functions/src/atomicBooking.ts:1080-1121`)

```ts
{
  check_in: Firestore.Timestamp,    // raw client Date wrapped — see §3 below
  check_out: Firestore.Timestamp,   // raw client Date wrapped
  guest_count: number,              // adults + children, combined client-side
  pet_count: number,                // separate
  // ... payment, status, refs, etc.
  // NO `nights` field. NO `adults`/`children` split. NO `duration_nights`.
}
```

Implication: every read site computes nights anew from `(check_out - check_in)`. No back-reference, no immutable record of "this booking was billed for N nights at write time."

## 2. Night-count derivation sites

### 2.1 Dart (`.difference().inDays` family — floor)

| # | File:Line | Algorithm | Normalization | Notes |
|---|-----------|-----------|---------------|-------|
| D1 | `lib/shared/models/booking_model.dart:138` | `checkOut.difference(checkIn).inDays` | none | `BookingModel.numberOfNights` getter — used by owner dashboard tiles, calendar, analytics |
| D2 | `lib/features/widget/utils/date_normalizer.dart:89` | `normalizedOut.difference(normalizedIn).inDays` | UTC midnight | `DateNormalizer.nightsBetween()` — safe variant; DST-resilient |
| D3 | `lib/features/widget/utils/date_normalizer.dart:124` | `normalizedOut.difference(normalizedIn).inDays` | UTC midnight | `bookingNights(...)` returns day-by-day list, length = nights |
| D4 | `lib/core/services/email_notification_service.dart:289, 524, 705` | `booking.checkOut.difference(booking.checkIn).inDays` | none | Client-side email rendering paths (3 templates: confirmation, status update, owner notify) |
| D5 | `lib/features/widget/presentation/screens/booking_widget_screen.dart:2579, 2745, 2829, 3423` | `checkOut.difference(checkIn).inDays` | none | Widget price step, CTA button label ("Pay €X for Y nights"), confirmation transition |
| D6 | `lib/features/widget/data/helpers/booking_price_calculator.dart:112` | `DateNormalizer.nightsBetween(...)` | UTC midnight (via D2) | Server-mirror price calc helper |

### 2.2 TypeScript / Cloud Functions (`Math.ceil(/86_400_000)` family — ceil)

| # | File:Line | Algorithm | Notes |
|---|-----------|-----------|-------|
| T1 | `functions/src/utils/dateValidation.ts:211-226` | `Math.ceil((co - ci) / 86_400_000)` | `calculateBookingNights()` — canonical server helper. Throws if `< 1`. |
| T2 | `functions/src/atomicBooking.ts:776` | calls T1 | Used for min/max-nights validation against `daily_prices` + extra-guest/pet fee calc (`fee = max(0, guests - maxGuests) * extraBedFee * nights`, line 539) |
| T3 | `functions/src/stripePayment.ts:430` | calls T1 | Same role pre-checkout |
| T4 | `functions/src/verifyBookingAccess.ts:163-183` | inline `Math.ceil` | Returned in `BookingDetailsModel.nights` to guest-view + cancel flows |
| T5 | `functions/src/getBookingByStripeSession.ts:90-106` | inline `Math.ceil` | Returned in `BookingDetailsModel.nights` to Stripe-success confirmation poll |
| T6 | `functions/src/email/templates/booking-confirmation.ts:62`, `booking-approved.ts:62` | `calculateNights(checkIn, checkOut)` (template helper, uses T1 equivalent) | Email body renders "Broj noćenja: N noći" |

## 3. The disagreement scenario

### 3.1 Where Timestamps come from

```ts
// functions/src/utils/dateValidation.ts:196-199
const checkInDate  = admin.firestore.Timestamp.fromDate(checkInDateObj);
const checkOutDate = admin.firestore.Timestamp.fromDate(checkOutDateObj);
```

`checkInDateObj` / `checkOutDateObj` are constructed via `new Date(checkIn)` from whatever the client passed. STEP 5 of the same file creates a `checkInMidnight` UTC-aligned variant **only for the past-date validation**; the persisted Timestamp uses the raw object. So if the client sends `"2026-06-01T14:30:00.000Z"`, Firestore stores `2026-06-01T14:30:00Z`, not `2026-06-01T00:00:00Z`.

### 3.2 Floor vs ceil example

| Stored | Computed by Dart `D4`/`D5` (`.inDays`) | Computed by TS `T1` (`Math.ceil`) | Disagree? |
|---|---|---|---|
| `2026-06-01T00:00Z` → `2026-06-05T00:00Z` | 4 | 4 | no |
| `2026-06-01T14:30Z` → `2026-06-05T11:00Z` (3d 20.5h) | 3 (truncates 3.85) | 4 (ceils 3.85) | **yes** |
| `2026-06-01T00:00Z` → `2026-06-01T23:00Z` (DST clock-back 23h) | 0 | 1 | **yes** |

### 3.3 Today's empirical safety

The widget date picker (`booking_widget_screen.dart`) only allows whole-date selection, and `submit_booking_use_case.dart` passes ISO strings parsed from `DateTime(year, month, day)` which lands at local midnight → `toIso8601String()` adds the local offset. On the server, `new Date(iso)` re-parses to UTC. If local TZ is UTC+2 (Zagreb), `"2026-06-01T00:00:00+02:00"` parses to `2026-05-31T22:00:00Z`. **The Firestore Timestamp is therefore stored as 22:00 UTC of the prior day**, not midnight UTC.

Subsequent reads:
- Dart `BookingModel.numberOfNights` calls `.difference().inDays` on those 22:00-offset Timestamps. As long as **both** check-in and check-out have the same offset (always true — both come from the same picker), the difference cancels: `(co_22:00 - ci_22:00).inDays` = exact N. Safe.
- TS `Math.ceil((co_22:00 - ci_22:00) / 86_400_000)` = `Math.ceil(N.0)` = N. Safe.

**Why DST breaks this**: if check-in is before the spring-forward and check-out is after, the local clock loses 1 hour. Dart's `Duration.inDays` (Dart docs: "The number of days in this Duration, expressed as an integer") is computed from total microseconds; `(co_22:00 - ci_22:00)` is 23h × (N-1) + 24h = `N*24 - 1` hours = `N - 1/24` days → `.inDays` = `N - 1` (truncated). Server `Math.ceil` of the same value = `N`. **Off-by-one** on DST-straddling bookings.

### 3.4 Where it actually manifests today

| Surface | Source | Algorithm |
|---|---|---|
| Owner dashboard booking list | `BookingModel.numberOfNights` (D1, floor, no normalization) | floor |
| Owner dashboard analytics (revenue/occupancy) | varies — `firebase_revenue_analytics_repository.dart` uses `BookingModel.numberOfNights` | floor |
| Widget price step | `DateNormalizer.nightsBetween()` (D2, normalized floor) | floor (DST-safe) |
| Widget CTA / confirmation transition | inline `.difference().inDays` (D5, floor, no normalization) | floor (DST-fragile) |
| Stripe-success confirmation screen | `BookingDetailsModel.nights` from `getBookingByStripeSession` CF (T5, ceil) | ceil |
| Guest cancel view | `BookingDetailsModel.nights` from `verifyBookingAccess` CF (T4, ceil) | ceil |
| Owner email ("New booking arrived") | `email_notification_service.dart` (D4, floor) | floor (DST-fragile) |
| Guest email ("Booking confirmed") | CF email template (T6, ceil) | ceil |
| Owner email vs guest email for same booking | mismatched when DST-straddling | **off-by-one possible** |

The dominant production scenario (booking entirely inside one DST regime) keeps everything aligned at N nights regardless of algorithm. DST-straddling bookings are the empirical break point.

## 4. Guest-count flow

Simpler — single `guest_count` field, no algorithmic split.

| Stage | File:Line | Behavior |
|---|---|---|
| Client form | `lib/features/widget/state/booking_form_state.dart:75`, `lib/features/widget/domain/use_cases/submit_booking_use_case.dart:68` | `totalGuests = adults + children` (int + int) |
| Client validation | `lib/features/widget/domain/services/booking_validation_service.dart:194` | Same combine |
| Server validate | `functions/src/atomicBooking.ts:463` (`Number(guestCount) || 1`) | Coerces to number, defaults 1 |
| Server persist | `functions/src/atomicBooking.ts:1090` | `guest_count: numericGuestCount` |
| Server fees | `functions/src/atomicBooking.ts:539`, `stripePayment.ts:466-470` | `extraGuestFees = max(0, guestCount - maxGuests) * extraBedFee * nights` |
| Read display | `BookingModel.guestCount`, `BookingDetailsModel.guestCount` | single int |

Adults vs children breakdown **is not persisted** — only the sum. The widget guest picker collects adults + children + infants separately, but only `adults + children` is sent on the wire as `guest_count`. Infants are dropped before submit. This is a deliberate design choice (extra-bed fee tier is per "guest counting toward the bed", not per "human in the apartment"), not a bug. Document for future questions.

## 5. iCal export contract

`functions/src/icalExport.ts:492` comment:

> "So if check_out = July 5, guests stayed nights 1,2,3,4 and July 5 is FREE for new check-in."

= iCal `DTEND` is exclusive — matches `check_out` field. This is RFC-5545-correct; calendar clients (Booking.com / Airbnb / Adriagate / Holiday-Home all verified per `MEMORY/ical-sync.md`) interpret an event as occupying nights `[DTSTART, DTEND)`. **No drift here**; the nights count is `(DTEND - DTSTART).inDays` which matches `BookingModel.numberOfNights` exactly.

## 6. Recommendation — canonical source of truth

Two viable shapes:

**Option A — server-authoritative `nights` field on booking doc**
- Add `nights: number` to `bookingData` write in `atomicBooking.ts:1080-1121` and the placeholder write in `stripePayment.ts`.
- Use `calculateBookingNights(checkInDate, checkOutDate)` (T1).
- Migrate all read sites (D1, D4, D5, freezed models, CF email helpers) to read `data.nights` instead of recomputing.
- Backfill script for existing rows: same formula, run once on `bookbed-dev` and prod each.
- **Pro**: immutable record; survives future Timestamp normalization changes.
- **Con**: ~6 read sites to update + back-fill script + freezed model regen.

**Option B — normalize Timestamps at write time + standardize derivation**
- Inside `dateValidation.ts` STEP 6, replace `Timestamp.fromDate(checkInDateObj)` with `Timestamp.fromDate(checkInMidnight)` (the already-computed UTC-midnight variant from STEP 5; mirror for checkOut).
- Then `.difference().inDays` and `Math.ceil(/86_400_000)` agree on all bookings (no DST hazard — both Timestamps are absolute UTC midnight).
- Pick ONE derivation per language: Dart → `DateNormalizer.nightsBetween()` for read sites, deprecate `.difference().inDays` paths. TS → `calculateBookingNights()` everywhere.
- **Pro**: smaller diff, no schema migration, no back-fill.
- **Con**: still relies on derivation; future code can drift. Doesn't survive a developer adding a new "ceil" path next year.

**Preferred**: **B as a first pass** (immediate consistency, minimal risk, no migration). Promote to **A** if/when:
- Audit needs to verify "the customer was billed for N nights" against an immutable record.
- Multi-day bookings with partial-day check-out times become a feature (early check-in / late check-out pricing).

Either choice is independent of T11c. Suggest tracking as **SF-026** (separate from the security PR).

## 7. Out of scope / next steps

- This audit is documentation only. No `firestore.rules`, no `functions/src/`, no `lib/` edits in this PR.
- Fix lands in a follow-up PR; recommend Option B above as the smallest correct change.
- Cross-link from `docs/TODO.md` if/when promoted to scheduled work.
- DST regression test: add a unit test that creates a booking spanning the spring-forward boundary (e.g. `2026-03-28` → `2026-04-01` for Europe/Zagreb, which crosses CEST start on 2026-03-29 03:00) and asserts that all 9 read sites (D1-D6 + T1, T4, T5) return the same integer.

## 8. Related files

| File | Why |
|---|---|
| `audit/07-chrome-smoke-test.md` | Origin: issue #10 |
| `audit/06-bookings-hotfix-partial.md` | Sibling — bookings rules hotfix, T11c context |
| `audit/06-availability-cf-design.md` (referenced but not present in repo) | T11c migration design — may be drafted elsewhere |
| `docs/SECURITY_FIXES.md` | T11 entry; updated separately in this PR |
| `functions/src/utils/dateValidation.ts` | Where Option B fix lands |
| `lib/features/widget/utils/date_normalizer.dart` | Existing safe-derivation helper |
| `lib/shared/models/booking_model.dart:136-139` | `numberOfNights` getter — Option B promotes this to single Dart entry point |

