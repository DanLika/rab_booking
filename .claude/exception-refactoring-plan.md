# Exception Refactoring Plan

## Problem Overview
- **93 generic Exception objects** across codebase
- **4+ hardcoded error strings** (not internationalized)
- Poor error handling and debugging experience

## Proposed Exception Hierarchy

```dart
// lib/core/exceptions/app_exceptions.dart

abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  AppException(this.message, {this.code, this.originalError, this.stackTrace});

  @override
  String toString() => 'AppException: $message${code != null ? ' (code: $code)' : ''}';
}

// AUTHENTICATION
class AuthException extends AppException {
  AuthException(String message, {String? code, dynamic originalError, StackTrace? stackTrace})
      : super(message, code: code, originalError: originalError, stackTrace: stackTrace);
}

// BOOKING OPERATIONS
class BookingException extends AppException {
  BookingException(String message, {String? code, dynamic originalError, StackTrace? stackTrace})
      : super(message, code: code, originalError: originalError, stackTrace: stackTrace);
}

// PROPERTY/UNIT OPERATIONS
class PropertyException extends AppException {
  PropertyException(String message, {String? code, dynamic originalError, StackTrace? stackTrace})
      : super(message, code: code, originalError: originalError, stackTrace: stackTrace);
}

// STORAGE/UPLOAD
class StorageException extends AppException {
  StorageException(String message, {String? code, dynamic originalError, StackTrace? stackTrace})
      : super(message, code: code, originalError: originalError, stackTrace: stackTrace);
}

// NOTIFICATIONS
class NotificationException extends AppException {
  NotificationException(String message, {String? code, dynamic originalError, StackTrace? stackTrace})
      : super(message, code: code, originalError: originalError, stackTrace: stackTrace);
}

// ANALYTICS
class AnalyticsException extends AppException {
  AnalyticsException(String message, {String? code, dynamic originalError, StackTrace? stackTrace})
      : super(message, code: code, originalError: originalError, stackTrace: stackTrace);
}

// EXTERNAL INTEGRATIONS
class IntegrationException extends AppException {
  IntegrationException(String message, {String? code, dynamic originalError, StackTrace? stackTrace})
      : super(message, code: code, originalError: originalError, stackTrace: stackTrace);
}
```

## Priority Levels

### 🔴 PHASE 1 - CRITICAL (15 occurrences)
**Impact**: Authentication & booking flow
- `enhanced_auth_provider.dart` (5) → `AuthException`
- `firebase_booking_repository.dart` (4) → `BookingException`
- `booking_lookup_provider.dart` (6) → `BookingException`
- `booking_widget_screen.dart` (1) → `BookingException`

**Estimated time**: 30 minutes

### 🟠 PHASE 2 - HIGH (32 occurrences)
**Impact**: Owner operations
- `firebase_owner_properties_repository.dart` (17) → `PropertyException`
- `firebase_owner_bookings_repository.dart` (9) → `BookingException`
- `notification_service.dart` (6) → `NotificationException`

**Estimated time**: 45 minutes

### 🟡 PHASE 3 - MEDIUM (30 occurrences)
**Impact**: Analytics & reporting
- Revenue analytics repository (6) → `AnalyticsException`
- Property performance repository (5) → `AnalyticsException`
- Analytics repository (1) → `AnalyticsException`
- Firebase unit/property repositories (5) → `PropertyException`
- Storage service (3) → `StorageException`
- User profile repository (3) → `AuthException`
- Email notification service (1) → `NotificationException`
- External calendar sync (4) → `IntegrationException`
- Unit wizard (4) → `PropertyException`
- Onboarding provider (2) → `PropertyException`

**Estimated time**: 1 hour

### 🟢 PHASE 4 - LOW (16 occurrences)
**Impact**: Less critical paths
- Calendar providers (4) → `BookingException`
- ICS download (1) → `IntegrationException`
- Remaining scattered exceptions

**Estimated time**: 30 minutes

---

## Hardcoded Strings Fix

### Locations:
1. `year_calendar_widget.dart:77` - `'Error: $error'`
2. `error_screen.dart:79` - error messages
3. `email_field_with_verification.dart:243` - `'Verify'`
4. `month_calendar_widget.dart:99` - `'Error: $error'`

### Solution:
Create `lib/core/localization/error_messages.dart`:
```dart
class ErrorMessages {
  static const String genericError = 'An error occurred';
  static const String loadingError = 'Failed to load data';
  static const String verifyButton = 'Verify';
  static const String retryButton = 'Retry';

  static String formatError(Object error) => 'Error: $error';
}
```

**Estimated time**: 15 minutes

---

## Total Effort Estimate
- Phase 1: 30 min
- Phase 2: 45 min
- Phase 3: 1 hour
- Phase 4: 30 min
- Hardcoded strings: 15 min
- Testing: 30 min

**TOTAL: ~3 hours 30 minutes**

---

## Benefits After Refactoring
1. ✅ **Better debugging** - specific exception types
2. ✅ **Error tracking** - can log exception types separately
3. ✅ **User-friendly errors** - can map exceptions to localized messages
4. ✅ **Type safety** - catch specific exceptions in try-catch
5. ✅ **Code maintainability** - clear error contracts

---

## Risk Assessment
- **Low risk** if done incrementally (phase by phase)
- **Medium risk** if done all at once without testing
- **No breaking changes** to public API
- **Requires manual testing** of error flows

---

## Recommendation

**Option A - Full Refactoring (3.5 hours)**
- Do all phases at once
- Comprehensive testing required
- Single large commit

**Option B - Incremental (Phase 1 only, 30 min)**
- Critical path only (auth + booking)
- Less testing burden
- Can deploy faster
- Continue with Phase 2-4 later

**My recommendation**: **Option B (Phase 1)** - fix critical paths first, then schedule Phase 2-4 for a separate session when there's more time for testing.
