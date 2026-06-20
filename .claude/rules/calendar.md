---
paths:
  - "lib/**/calendar/**"
  - "lib/**/timeline/**"
  - "lib/**/calendar_*.dart"
  - "lib/**/timeline_*.dart"
---

# Calendar System — KRITIČNO

## Repository: `firebase_booking_calendar_repository.dart`

- Koristi `DateTime.utc()` za SVE map keys
- Stream errors: `onErrorReturnWith()` vraća prazan map
- Turnover detection MORA provjeriti: `partialCheckIn`, `partialCheckOut`, `booked`, `partialBoth`

## DateStatus enum

- `pending` → žuta + dijagonalni uzorak (`#6B4C00` @ 60%)
- `partialBoth` → turnover day (oba bookinga)
- `isCheckOutPending` / `isCheckInPending` → prati koja polovica je pending

## NE REFAKTORISATI

Duplikacija `_buildCalendarMap` vs `_buildYearCalendarMap` je NAMJERNA safety net. Prethodni refaktoring uveo 5+ bugova.

## Timeline Calendar Fixed Dimensions

`timeline_dimensions.dart` — FIXED 50/42/100/60px za SVE uređaje — NE vraćaj responsive breakpoints!

Fixed values: dayWidth=50px, rowHeight=42px, columnWidth=100px, headerHeight=60px

Timeline is horizontally scrollable — wider screens show more days with same cell size.

## Timeline Calendar z-index

Cancelled bookings at base level (drawn first), confirmed on top.

**DORMANT** — cancelled filtered pre-paint (`owner_calendar_provider:108-119`), rule retired by removal not inverted.

## Provider Invalidation Pattern

```dart
// CORRECT - invalidate both base AND filtered providers
ref.invalidate(calendarBookingsProvider);        // base provider
ref.invalidate(timelineCalendarBookingsProvider); // filtered provider UI watches
```
