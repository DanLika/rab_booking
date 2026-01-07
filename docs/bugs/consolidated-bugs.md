# Consolidated Bug Documentation

**Status:** Completed
**Date Created:** 2024-07-29
**Last Updated:** 2024-07-29

---

> **Note:** This document is a consolidation of all bug reports from the `docs/bugs`, `docs/unresolved-bugs`, and `docs/Resolved` directories. The purpose of this file is to provide a single source of truth for all bug reports, both resolved and unresolved.

---

## Repository & Service Files

### Bug #1: Timezone issues in `firebase_daily_price_repository.dart`
- **Priority:** Critical
- **Status:** ✅ RESOLVED
- **Verification Date:** 2024-07-29
- **Problem:** The `_normalizeDate()` and `_normalizeEndOfDay()` methods were using local time instead of UTC, which could cause inconsistencies with the rest of the codebase.
- **Resolution:** Both methods were updated to use `DateTime.utc()` instead of `DateTime()`. This ensures that all date normalization is done in UTC, which is consistent with the rest of the codebase.

### Bug #2: Inconsistent date normalization in `calculateBookingPrice()`
- **Priority:** Critical
- **Status:** ✅ RESOLVED
- **Verification Date:** 2024-07-29
- **Problem:** In the `calculateBookingPrice()` method, the `checkIn` and `checkOut` dates were not normalized before being used in the loop, which could cause issues if the dates had time components.
- **Resolution:** The `checkIn` and `checkOut` dates are now normalized using `_normalizeDate()` before the loop. This ensures that the dates are consistent with the normalized dates in `priceMap`.

### Bug #3: Use of local time in `_markPastDates()`
- **Priority:** Critical
- **Status:** ✅ RESOLVED
- **Verification Date:** 2024-07-29
- **Problem:** The `_markPastDates()` method in `firebase_booking_calendar_repository.dart` was using `DateTime.now()` to get the current date, which could cause issues with timezones.
- **Resolution:** The method now uses `DateTime.now().toUtc()` to get the current date in UTC, which is consistent with the rest of the codebase.

### Bug #4: Use of `DateTime.now()` instead of UTC
- **Priority:** Critical
- **Status:** ✅ RESOLVED
- **Verification Date:** 2024-07-29
- **Problem:** `DateTime.now()` was used for `createdAt` and `updatedAt` fields in `firebase_daily_price_repository.dart` and `daily_price_model.dart` instead of UTC time.
- **Resolution:** All instances of `DateTime.now()` for `createdAt` and `updatedAt` fields were replaced with `DateTime.now().toUtc()`.

### Bug #5: Missing error handling in `watchWidgetSettings()` stream
- **Priority:** High
- **Status:** ✅ RESOLVED
- **Verification Date:** 2024-07-29
- **Problem:** The `watchWidgetSettings()` stream in `firebase_widget_settings_repository.dart` would break if `WidgetSettings.fromFirestore()` threw an exception.
- **Resolution:** A `try-catch` block was added to the `map()` function to catch parsing errors, and an `.onErrorReturnWith()` handler was added to catch stream errors.

### Bug #6: Batch size limit in `updateEmailVerificationForAllUnits()`
- **Priority:** High
- **Status:** ✅ RESOLVED
- **Verification Date:** 2024-07-29
- **Problem:** The `updateEmailVerificationForAllUnits()` method in `firebase_widget_settings_repository.dart` would fail if a property had more than 500 units due to the Firestore batch limit.
- **Resolution:** The method now uses a batch chunking pattern, where the batch is committed when the limit of 500 operations is reached, and a new batch is created for the remaining operations.

### Bug #7: Missing error handling in `getAllPropertySettings()`
- **Priority:** High
- **Status:** ✅ RESOLVED
- **Verification Date:** 2024-07-29
- **Problem:** If a single document failed to parse in `getAllPropertySettings()`, the entire operation would fail and return an empty list.
- **Resolution:** Individual error handling was added for each document in the `map` operation. If a document fails to parse, the error is logged, and the document is filtered out of the results.

### Bug #8: Potential issue with including checkout day in booking range
- **Priority:** Low
- **Status:** ✅ NOT A BUG
- **Verification Date:** 2024-07-29
- **Problem:** The checkout day was included in the booking range in some parts of the code, which could lead to confusion.
- **Resolution:** This was determined to be the expected behavior. The checkout day is included for visual representation in the calendar but does not block new bookings and is not included in the price calculation. The code was documented to clarify this.

### Bug #9: Inconsistent await-ing of logs in `email_verification_service.dart`
- **Priority:** Low
- **Status:** ✅ RESOLVED
- **Verification Date:** 2024-07-29
- **Problem:** `LoggingService.logError()` was being awaited in `email_verification_service.dart`, which is inconsistent with other parts of the codebase and could slow down the error handling flow.
- **Resolution:** `await LoggingService.logError()` was replaced with `unawaited(LoggingService.logError())` for consistency.

### Bug #10: Syntax error in `widget_mode.dart` switch expression
- **Priority:** Critical
- **Status:** ✅ NOT A BUG
- **Verification Date:** 2024-07-29
- **Problem:** The `||` operator was used in a switch expression, which was thought to be a syntax error.
- **Resolution:** This is valid syntax in Dart 3.0+ for logical OR patterns in switch expressions.

### Bug #11: Use of `DateTime.now()` instead of UTC in `widget_settings.dart`
- **Priority:** Critical
- **Status:** ✅ RESOLVED
- **Verification Date:** 2024-07-29
- **Problem:** `DateTime.now()` was used instead of UTC time in various places in `widget_settings.dart`.
- **Resolution:** All instances of `DateTime.now()` were replaced with `DateTime.now().toUtc()`.

### Bug #12: Incorrect parsing of `last_synced_at` from Firestore
- **Priority:** High
- **Status:** ✅ RESOLVED
- **Verification Date:** 2024-07-29
- **Problem:** The code was expecting `last_synced_at` to be a String, but it was being saved as a Firestore `Timestamp`.
- **Resolution:** The code now uses the `DateTimeParser.parseFlexible()` method, which can handle both `Timestamp` and `String` formats.

### Bug #13: Potential issue with parsing colors in `embed_url_params.dart`
- **Priority:** Low
- **Status:** ✅ RESOLVED
- **Verification Date:** 2024-07-29
- **Problem:** The `_parseColor()` method did not handle all hex color formats.
- **Resolution:** The method was updated to support all hex formats, including #RRGGBB, #AARRGGBB, #RGB, and #ARGB.
