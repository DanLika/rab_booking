# Consolidated Bug Documentation (Archive)

**Status:** Archived
**Original Date:** 2024-07-29
**Archived:** 2026-01-07

> **Note:** This is an archive of historical bug reports that were resolved during early development.
> For current security fixes and bug tracking, see `docs/SECURITY_FIXES.md`.

---

## Repository & Service Files

### Bug #1: Timezone issues in `firebase_daily_price_repository.dart`
- **Priority:** Critical
- **Status:** ✅ RESOLVED
- **Problem:** The `_normalizeDate()` and `_normalizeEndOfDay()` methods were using local time instead of UTC.
- **Resolution:** Both methods updated to use `DateTime.utc()`.

### Bug #2: Inconsistent date normalization in `calculateBookingPrice()`
- **Priority:** Critical
- **Status:** ✅ RESOLVED
- **Problem:** `checkIn` and `checkOut` dates were not normalized before being used in the loop.
- **Resolution:** Dates are now normalized using `_normalizeDate()` before the loop.

### Bug #3: Use of local time in `_markPastDates()`
- **Priority:** Critical
- **Status:** ✅ RESOLVED
- **Problem:** `DateTime.now()` was used instead of UTC.
- **Resolution:** Now uses `DateTime.now().toUtc()`.

### Bug #4: Use of `DateTime.now()` instead of UTC
- **Priority:** Critical
- **Status:** ✅ RESOLVED
- **Problem:** `DateTime.now()` was used for `createdAt` and `updatedAt` fields.
- **Resolution:** Replaced with `DateTime.now().toUtc()`.

### Bug #5: Missing error handling in `watchWidgetSettings()` stream
- **Priority:** High
- **Status:** ✅ RESOLVED
- **Problem:** Stream would break if `WidgetSettings.fromFirestore()` threw an exception.
- **Resolution:** Added try-catch block and `.onErrorReturnWith()` handler.

### Bug #6: Batch size limit in `updateEmailVerificationForAllUnits()`
- **Priority:** High
- **Status:** ✅ RESOLVED
- **Problem:** Would fail if property had more than 500 units (Firestore batch limit).
- **Resolution:** Implemented batch chunking pattern.

### Bug #7: Missing error handling in `getAllPropertySettings()`
- **Priority:** High
- **Status:** ✅ RESOLVED
- **Problem:** Single document parse failure would fail entire operation.
- **Resolution:** Added individual error handling for each document.

### Bug #8: Checkout day in booking range
- **Priority:** Low
- **Status:** ✅ NOT A BUG
- **Problem:** Checkout day included in booking range.
- **Resolution:** Expected behavior - included for visual representation only.

### Bug #9: Inconsistent await-ing of logs
- **Priority:** Low
- **Status:** ✅ RESOLVED
- **Problem:** `LoggingService.logError()` was being awaited.
- **Resolution:** Replaced with `unawaited(LoggingService.logError())`.

### Bug #10: Switch expression syntax
- **Priority:** Critical
- **Status:** ✅ NOT A BUG
- **Problem:** `||` operator in switch expression thought to be syntax error.
- **Resolution:** Valid Dart 3.0+ syntax for logical OR patterns.

### Bug #11: DateTime.now() in widget_settings.dart
- **Priority:** Critical
- **Status:** ✅ RESOLVED
- **Problem:** `DateTime.now()` used instead of UTC.
- **Resolution:** Replaced with `DateTime.now().toUtc()`.

### Bug #12: Incorrect parsing of `last_synced_at`
- **Priority:** High
- **Status:** ✅ RESOLVED
- **Problem:** Code expected String but Firestore saved as Timestamp.
- **Resolution:** Now uses `DateTimeParser.parseFlexible()`.

### Bug #13: Color parsing in embed_url_params.dart
- **Priority:** Low
- **Status:** ✅ RESOLVED
- **Problem:** `_parseColor()` didn't handle all hex formats.
- **Resolution:** Updated to support #RRGGBB, #AARRGGBB, #RGB, #ARGB.
