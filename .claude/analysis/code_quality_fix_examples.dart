// 🔧 CODE QUALITY FIX EXAMPLES
//
// This file demonstrates the recommended fixes for the 3 main code quality issues:
// 1. Internacionalizacija (i18n)
// 2. Generic Exception Handling
// 3. Platform-specific code
//
// DO NOT run this file - it's for reference only!

// ============================================================================
// EXAMPLE 1: BOOKING WIDGET SCREEN - CREATE BOOKING
// ============================================================================

// ❌ BEFORE (booking_widget_screen.dart:2100-2125)
void createBookingBefore() async {
  try {
    final booking = await _createBookingInFirestore(bookingData);

    if (mounted) {
      SnackBarHelper.showSuccess(
        context: context,
        message: 'Booking created successfully!', // ❌ Hardcoded
      );
    }
  } catch (e) { // ❌ Generic catch
    await LoggingService.logError('[BookingWidget] Error creating booking', e);

    if (mounted) {
      SnackBarHelper.showError(
        context: context,
        message: 'Error creating booking: $e', // ❌ Hardcoded + raw error
      );
    }
  }
}

// ✅ AFTER (Recommended)
void createBookingAfter() async {
  try {
    final booking = await _createBookingInFirestore(bookingData);

    if (mounted) {
      SnackBarHelper.showSuccess(
        context: context,
        message: S.of(context).bookingCreatedSuccessfully, // ✅ Localized
      );
    }
  } on BookingConflictException catch (e) { // ✅ Specific exception
    await LoggingService.logWarning(
      '[BookingWidget] Booking conflict - dates already booked',
      e,
    );

    if (mounted) {
      SnackBarHelper.showError(
        context: context,
        message: S.of(context).datesAlreadyBooked, // ✅ User-friendly
      );
      // Optional: Suggest alternative dates
      _showAlternativeDates();
    }
  } on BookingException catch (e) { // ✅ Specific exception
    await LoggingService.logError(
      '[BookingWidget] Booking creation failed',
      e,
    );

    if (mounted) {
      SnackBarHelper.showError(
        context: context,
        message: S.of(context).bookingCreationFailed, // ✅ Generic booking error
      );
    }
  } on FirebaseException catch (e) { // ✅ Firebase-specific
    await LoggingService.logError(
      '[BookingWidget] Firebase error during booking',
      e,
    );

    if (mounted) {
      // Handle specific Firebase errors
      final errorMessage = switch (e.code) {
        'permission-denied' => S.of(context).permissionDenied,
        'unavailable' => S.of(context).serverUnavailable,
        'deadline-exceeded' => S.of(context).requestTimeout,
        _ => S.of(context).serverError,
      };

      SnackBarHelper.showError(
        context: context,
        message: errorMessage,
      );
    }
  } catch (e) { // ✅ Fallback for unexpected errors
    await LoggingService.logError(
      '[BookingWidget] Unexpected error creating booking',
      e,
    );

    if (mounted) {
      SnackBarHelper.showError(
        context: context,
        message: S.of(context).unexpectedError,
      );
    }

    // Rethrow critical errors
    if (e is Error) rethrow;
  }
}

// ============================================================================
// EXAMPLE 2: EMAIL VERIFICATION DIALOG
// ============================================================================

// ❌ BEFORE (email_verification_dialog.dart:96-118)
Future<void> sendVerificationCodeBefore() async {
  setState(() {
    _isResending = true;
    _errorMessage = null;
  });

  try {
    final callable = functions.httpsCallable('sendEmailVerificationCode');
    await callable.call({'email': widget.email});

    if (mounted) {
      SnackBarHelper.showSuccess(
        context: context,
        message: 'Verification code sent! Check your inbox.', // ❌ Hardcoded
      );
    }
  } catch (e) { // ❌ Generic catch
    await LoggingService.logError('[EmailVerification] Functions error', e);

    if (mounted) {
      setState(() {
        _errorMessage = 'Failed to send verification code'; // ❌ Hardcoded
      });
    }
  } finally {
    if (mounted) {
      setState(() {
        _isResending = false;
      });
    }
  }
}

// ✅ AFTER (Recommended)
Future<void> sendVerificationCodeAfter() async {
  setState(() {
    _isResending = true;
    _errorMessage = null;
  });

  try {
    final callable = functions.httpsCallable('sendEmailVerificationCode');
    await callable.call({'email': widget.email});

    if (mounted) {
      SnackBarHelper.showSuccess(
        context: context,
        message: S.of(context).verificationCodeSent, // ✅ Localized
      );

      // Start cooldown timer
      _startResendCooldown();
    }
  } on FirebaseFunctionsException catch (e) { // ✅ Specific Firebase Functions error
    await LoggingService.logError(
      '[EmailVerification] Functions error: ${e.code}',
      e,
    );

    if (mounted) {
      // Handle specific function error codes
      final errorMessage = switch (e.code) {
        'invalid-argument' => S.of(context).invalidEmailAddress,
        'deadline-exceeded' => S.of(context).requestTimeout,
        'resource-exhausted' => S.of(context).tooManyRequests,
        'unauthenticated' => S.of(context).authenticationRequired,
        _ => S.of(context).failedToSendVerificationCode,
      };

      setState(() {
        _errorMessage = errorMessage;
      });
    }
  } on FirebaseException catch (e) { // ✅ Generic Firebase error
    await LoggingService.logError(
      '[EmailVerification] Firebase error',
      e,
    );

    if (mounted) {
      setState(() {
        _errorMessage = S.of(context).serverError;
      });
    }
  } catch (e) { // ✅ Fallback for unexpected errors
    await LoggingService.logError(
      '[EmailVerification] Unexpected error',
      e,
    );

    if (mounted) {
      setState(() {
        _errorMessage = S.of(context).unexpectedError;
      });
    }
  } finally {
    if (mounted) {
      setState(() {
        _isResending = false;
      });
    }
  }
}

// ============================================================================
// EXAMPLE 3: FIREBASE BOOKING CALENDAR REPOSITORY - DATA PARSING
// ============================================================================

// ❌ BEFORE (firebase_booking_calendar_repository.dart:100-108)
List<BookingModel> parseBookingsBefore(List<QueryDocumentSnapshot> docs) {
  return docs
      .map((doc) {
        try {
          return BookingModel.fromJson({...doc.data(), 'id': doc.id});
        } catch (e) { // ❌ Generic catch
          LoggingService.logError('Error parsing booking', e);
          return null;
        }
      })
      .where((booking) => booking != null)
      .cast<BookingModel>()
      .toList();
}

// ✅ AFTER (Recommended)
List<BookingModel> parseBookingsAfter(List<QueryDocumentSnapshot> docs) {
  final bookings = <BookingModel>[];

  for (final doc in docs) {
    try {
      final data = doc.data() as Map<String, dynamic>;
      final booking = BookingModel.fromJson({...data, 'id': doc.id});
      bookings.add(booking);
    } on FormatException catch (e) { // ✅ Specific parsing error
      LoggingService.logWarning(
        'Invalid booking data format for doc ${doc.id}: ${e.message}',
        e,
      );
      // Skip this booking - data format issue
      continue;
    } on TypeError catch (e) { // ✅ Type mismatch
      LoggingService.logWarning(
        'Type mismatch in booking data for doc ${doc.id}',
        e,
      );
      // Skip this booking - likely schema change
      continue;
    } on CheckedFromJsonException catch (e) { // ✅ Missing required fields
      LoggingService.logWarning(
        'Missing required fields in booking ${doc.id}: ${e.message}',
        e,
      );
      // Skip this booking
      continue;
    } catch (e, stackTrace) { // ✅ Unexpected error - DON'T skip silently
      LoggingService.logError(
        'Unexpected error parsing booking ${doc.id}',
        e,
        stackTrace,
      );

      // This is serious - might indicate data corruption
      // Consider throwing DataParsingException here instead of skipping
      throw DataParsingException.invalidFormat(
        'BookingModel',
        e,
      );
    }
  }

  return bookings;
}

// ============================================================================
// EXAMPLE 4: STRIPE PAYMENT LAUNCH
// ============================================================================

// ❌ BEFORE (booking_widget_screen.dart:2259-2280)
Future<void> launchStripeBefore(Uri uri) async {
  try {
    if (kIsWeb) { // ⚠️ Platform check OK but could be abstracted
      await url_launcher.launchUrl(uri, webOnlyWindowName: '_self');
    } else {
      await url_launcher.launchUrl(uri);
    }
  } catch (e) { // ❌ Generic catch
    await LoggingService.logError('[BookingWidget] Error launching Stripe', e);

    if (mounted) {
      SnackBarHelper.showError(
        context: context,
        message: 'Error launching Stripe: $e', // ❌ Hardcoded + raw error
      );
    }
  }
}

// ✅ AFTER (Recommended)
Future<void> launchStripeAfter(Uri uri) async {
  try {
    // Platform abstraction (optional improvement)
    if (kIsWeb) {
      // Same-tab redirect on web (user doesn't lose form state)
      await url_launcher.launchUrl(uri, webOnlyWindowName: '_self');
    } else {
      // External browser on mobile
      await url_launcher.launchUrl(uri);
    }
  } on PlatformException catch (e) { // ✅ Platform-specific error
    await LoggingService.logError(
      '[BookingWidget] Platform error launching Stripe: ${e.code}',
      e,
    );

    if (mounted) {
      // User-friendly message based on error code
      final errorMessage = switch (e.code) {
        'ACTIVITY_NOT_FOUND' => S.of(context).noBrowserAvailable,
        'INVALID_URL' => S.of(context).invalidPaymentLink,
        _ => S.of(context).failedToOpenPayment,
      };

      SnackBarHelper.showError(
        context: context,
        message: errorMessage,
      );
    }
  } catch (e) { // ✅ Fallback for unexpected errors
    await LoggingService.logError(
      '[BookingWidget] Unexpected error launching Stripe',
      e,
    );

    if (mounted) {
      SnackBarHelper.showError(
        context: context,
        message: S.of(context).unexpectedError,
      );
    }
  }
}

// ============================================================================
// EXAMPLE 5: IMPROVED PLATFORM ABSTRACTION (Optional)
// ============================================================================

// ✅ OPTION 1: Create PlatformService (if more platform code is added)
abstract class PlatformService {
  Future<void> launchUrl(Uri uri, {bool newTab = false});
  String? getSubdomain();
  TabCommunicationService? createTabCommunication();
}

class WebPlatformService implements PlatformService {
  @override
  Future<void> launchUrl(Uri uri, {bool newTab = false}) async {
    await url_launcher.launchUrl(
      uri,
      webOnlyWindowName: newTab ? '_blank' : '_self',
    );
  }

  @override
  String? getSubdomain() {
    final uri = Uri.base;
    // Parse subdomain from hostname...
    return null;
  }

  @override
  TabCommunicationService createTabCommunication() {
    return TabCommunicationServiceWeb();
  }
}

class MobilePlatformService implements PlatformService {
  @override
  Future<void> launchUrl(Uri uri, {bool newTab = false}) async {
    await url_launcher.launchUrl(uri);
  }

  @override
  String? getSubdomain() => null; // Not applicable

  @override
  TabCommunicationService? createTabCommunication() => null; // Not supported
}

// Usage in widget:
class BookingWidgetScreenImproved extends ConsumerStatefulWidget {
  final PlatformService platformService;

  Future<void> launchStripe(Uri uri) async {
    try {
      await platformService.launchUrl(uri);
    } on PlatformException catch (e) {
      // Handle error...
    }
  }
}

// ✅ OPTION 2: Keep current approach (RECOMMENDED for now)
// The current kIsWeb checks are fine because:
// 1. Only 6 locations
// 2. Web-specific features (BroadcastChannel, subdomain)
// 3. Already using conditional imports for TabCommunicationService
// 4. Minimal maintenance overhead

// ============================================================================
// REQUIRED ARB FILE ADDITIONS
// ============================================================================

/*
Add these to lib/l10n/app_en.arb:

{
  "@@locale": "en",

  // Booking messages
  "bookingCreatedSuccessfully": "Booking created successfully!",
  "bookingCreationFailed": "Failed to create booking. Please try again.",
  "datesAlreadyBooked": "Selected dates are no longer available. Please choose different dates.",

  // Email verification
  "verificationCodeSent": "Verification code sent! Check your inbox.",
  "invalidEmailAddress": "Invalid email address.",
  "failedToSendVerificationCode": "Failed to send verification code. Please try again.",

  // Payment
  "failedToOpenPayment": "Failed to open payment page. Please try again.",
  "noBrowserAvailable": "No browser available to open payment link.",
  "invalidPaymentLink": "Invalid payment link. Please contact support.",

  // Generic errors
  "permissionDenied": "Permission denied. Please check your account.",
  "serverError": "Server error. Please try again later.",
  "serverUnavailable": "Server is temporarily unavailable. Please try again.",
  "requestTimeout": "Request timed out. Please check your connection.",
  "tooManyRequests": "Too many requests. Please wait a moment.",
  "authenticationRequired": "Authentication required. Please sign in.",
  "unexpectedError": "An unexpected error occurred. Please try again."
}

Add these to lib/l10n/app_hr.arb (Croatian):

{
  "@@locale": "hr",

  "bookingCreatedSuccessfully": "Rezervacija uspješno kreirana!",
  "bookingCreationFailed": "Kreiranje rezervacije nije uspjelo. Pokušajte ponovo.",
  "datesAlreadyBooked": "Odabrani datumi više nisu dostupni. Molimo odaberite druge datume.",

  "verificationCodeSent": "Verifikacijski kod poslan! Provjerite inbox.",
  "invalidEmailAddress": "Neispravna email adresa.",
  "failedToSendVerificationCode": "Slanje verifikacijskog koda nije uspjelo. Pokušajte ponovo.",

  "failedToOpenPayment": "Otvaranje stranice za plaćanje nije uspjelo. Pokušajte ponovo.",
  "noBrowserAvailable": "Nema dostupnog browsera za otvaranje linka.",
  "invalidPaymentLink": "Neispravan link za plaćanje. Kontaktirajte podršku.",

  "permissionDenied": "Pristup odbijen. Provjerite svoj račun.",
  "serverError": "Greška servera. Pokušajte kasnije.",
  "serverUnavailable": "Server je privremeno nedostupan. Pokušajte ponovo.",
  "requestTimeout": "Zahtjev je istekao. Provjerite konekciju.",
  "tooManyRequests": "Previše zahtjeva. Pričekajte trenutak.",
  "authenticationRequired": "Potrebna autentifikacija. Molimo prijavite se.",
  "unexpectedError": "Došlo je do neočekivane greške. Pokušajte ponovo."
}
*/

// ============================================================================
// NEW EXCEPTIONS TO ADD TO app_exceptions.dart
// ============================================================================

/*
Add these classes to lib/core/exceptions/app_exceptions.dart:

/// Thrown when data parsing fails
class DataParsingException extends AppException {
  final String dataType;

  DataParsingException(
    super.message, {
    required this.dataType,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory DataParsingException.invalidFormat(String dataType, dynamic error) {
    return DataParsingException(
      'Invalid $dataType data format',
      dataType: dataType,
      code: 'data/invalid-format',
      originalError: error,
    );
  }
}

/// Thrown when payment operations fail
class PaymentException extends AppException {
  PaymentException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory PaymentException.stripeFailed(dynamic error) {
    return PaymentException(
      'Stripe payment failed',
      code: 'payment/stripe-failed',
      originalError: error,
    );
  }
}

/// Thrown when validation fails
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  ValidationException(
    super.message, {
    this.fieldErrors,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory ValidationException.dateConflict(DateTime checkIn, DateTime checkOut) {
    return ValidationException(
      'Date conflict: ${checkIn.toIso8601String()} to ${checkOut.toIso8601String()}',
      code: 'validation/date-conflict',
    );
  }
}
*/
