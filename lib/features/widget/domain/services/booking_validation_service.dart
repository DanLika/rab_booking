import 'package:flutter/material.dart';

import '../models/widget_mode.dart';
import '../models/widget_settings.dart';

/// Result of a validation check
class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final Duration snackBarDuration;
  final bool isWarning; // Warning doesn't block, just shows message

  const ValidationResult.success()
    : isValid = true,
      errorMessage = null,
      snackBarDuration = const Duration(seconds: 3),
      isWarning = false;

  const ValidationResult.failure(
    this.errorMessage, {
    this.snackBarDuration = const Duration(seconds: 3),
  }) : isValid = false,
       isWarning = false;

  const ValidationResult.warning(
    this.errorMessage, {
    this.snackBarDuration = const Duration(seconds: 7),
  }) : isValid = true, // Warnings don't block
       isWarning = true;
}

/// Service for validating booking form data
/// All methods are static since they don't require state
class BookingValidationService {
  /// Validate form using Flutter's built-in form validation
  /// If formKey is null, skip validation (no form to validate)
  static ValidationResult validateForm(GlobalKey<FormState>? formKey) {
    // If no form key provided, skip form validation
    if (formKey == null) {
      return const ValidationResult.success();
    }
    if (formKey.currentState?.validate() != true) {
      // Form validation failed - form widgets show their own errors
      return const ValidationResult.failure(null);
    }
    return const ValidationResult.success();
  }

  /// Validate email verification if required by widget settings
  static ValidationResult validateEmailVerification({
    required bool requireEmailVerification,
    required bool emailVerified,
  }) {
    if (requireEmailVerification && !emailVerified) {
      return const ValidationResult.failure(
        'Please verify your email before booking',
      );
    }
    return const ValidationResult.success();
  }

  /// Validate tax/legal disclaimer acceptance if required
  static ValidationResult validateTaxLegal({
    required TaxLegalConfig? taxConfig,
    required bool taxLegalAccepted,
  }) {
    if (taxConfig != null && taxConfig.enabled && !taxLegalAccepted) {
      return const ValidationResult.failure(
        'Please accept the tax and legal obligations before booking',
        snackBarDuration: Duration(seconds: 5),
      );
    }
    return const ValidationResult.success();
  }

  /// Validate that dates are selected and check-out is after check-in
  static ValidationResult validateDates({
    required DateTime? checkIn,
    required DateTime? checkOut,
  }) {
    if (checkIn == null || checkOut == null) {
      return const ValidationResult.failure(
        'Please select check-in and check-out dates.',
      );
    }

    if (checkOut.isBefore(checkIn) || checkOut.isAtSameMomentAs(checkIn)) {
      return const ValidationResult.failure(
        'Check-out must be after check-in date.',
      );
    }

    return const ValidationResult.success();
  }

  /// Check if same-day check-in is after standard check-in time (3 PM)
  /// Returns warning (doesn't block booking)
  static ValidationResult checkSameDayCheckIn({
    required DateTime checkIn,
    int checkInTimeHour = 15, // 3 PM default
  }) {
    // Bug #65 Fix: Use UTC for DST-safe date comparison
    final now = DateTime.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);
    final checkInDate = DateTime.utc(checkIn.year, checkIn.month, checkIn.day);

    if (checkInDate.isAtSameMomentAs(today)) {
      if (now.hour >= checkInTimeHour) {
        return ValidationResult.warning(
          'Same-day check-in: Property check-in time is $checkInTimeHour:00. '
          'Please note that you may not be able to check in until tomorrow.',
        );
      }
    }

    return const ValidationResult.success();
  }

  /// Validate that property and owner IDs are loaded
  static ValidationResult validatePropertyOwner({
    required String? propertyId,
    required String? ownerId,
  }) {
    if (propertyId == null || ownerId == null) {
      return const ValidationResult.failure(
        'Property information not loaded. Please refresh the page.',
      );
    }
    return const ValidationResult.success();
  }

  /// Validate payment method selection for bookingInstant mode
  static ValidationResult validatePaymentMethod({
    required WidgetMode widgetMode,
    required String selectedPaymentMethod,
    required WidgetSettings? widgetSettings,
  }) {
    // Skip validation for bookingPending mode (no payment required)
    if (widgetMode != WidgetMode.bookingInstant) {
      return const ValidationResult.success();
    }

    final isStripeEnabled = widgetSettings?.stripeConfig?.enabled == true;
    final isBankTransferEnabled =
        widgetSettings?.bankTransferConfig?.enabled == true;
    final isPayOnArrivalEnabled = widgetSettings?.allowPayOnArrival == true;

    // Check if at least one payment method is enabled
    if (!isStripeEnabled && !isBankTransferEnabled && !isPayOnArrivalEnabled) {
      return const ValidationResult.failure(
        'No payment methods are currently available. Please contact the property owner.',
        snackBarDuration: Duration(seconds: 5),
      );
    }

    // Check if selected payment method is valid
    if (selectedPaymentMethod == 'stripe' && !isStripeEnabled) {
      return const ValidationResult.failure(
        'Stripe payment is not available. Please select another payment method.',
        snackBarDuration: Duration(seconds: 5),
      );
    }

    if (selectedPaymentMethod == 'bank_transfer' && !isBankTransferEnabled) {
      return const ValidationResult.failure(
        'Bank transfer is not available. Please select another payment method.',
        snackBarDuration: Duration(seconds: 5),
      );
    }

    if (selectedPaymentMethod == 'pay_on_arrival' &&
        !(widgetSettings?.allowPayOnArrival ?? false)) {
      return const ValidationResult.failure(
        'Pay on arrival is not available. Please select another payment method.',
        snackBarDuration: Duration(seconds: 5),
      );
    }

    return const ValidationResult.success();
  }

  /// Validate guest count against property capacity
  static ValidationResult validateGuestCount({
    required int adults,
    required int children,
    required int maxGuests,
  }) {
    final totalGuests = adults + children;
    if (totalGuests > maxGuests) {
      final guestWord = maxGuests == 1 ? 'guest' : 'guests';
      final selectedWord = totalGuests == 1 ? 'guest' : 'guests';
      return ValidationResult.failure(
        'Maximum $maxGuests $guestWord allowed for this property. '
        'You selected $totalGuests $selectedWord.',
        snackBarDuration: const Duration(seconds: 5),
      );
    }
    return const ValidationResult.success();
  }

  /// Validate minimum 1 adult required
  static ValidationResult validateAdultCount({required int adults}) {
    if (adults == 0) {
      return const ValidationResult.failure(
        'At least 1 adult is required for booking.',
        snackBarDuration: Duration(seconds: 5),
      );
    }
    return const ValidationResult.success();
  }

  /// Run all validations and return first failure (or success if all pass)
  /// Note: Price lock check and same-day warning are handled separately
  /// because they show dialogs/warnings rather than blocking errors
  static ValidationResult validateAllBlocking({
    required GlobalKey<FormState>? formKey,
    required bool requireEmailVerification,
    required bool emailVerified,
    required TaxLegalConfig? taxConfig,
    required bool taxLegalAccepted,
    required DateTime? checkIn,
    required DateTime? checkOut,
    required String? propertyId,
    required String? ownerId,
    required WidgetMode widgetMode,
    required String selectedPaymentMethod,
    required WidgetSettings? widgetSettings,
    required int adults,
    required int children,
    required int maxGuests,
  }) {
    // 1. Form validation
    final formResult = validateForm(formKey);
    if (!formResult.isValid) return formResult;

    // 2. Email verification
    final emailResult = validateEmailVerification(
      requireEmailVerification: requireEmailVerification,
      emailVerified: emailVerified,
    );
    if (!emailResult.isValid) return emailResult;

    // 3. Tax/Legal acceptance
    final taxResult = validateTaxLegal(
      taxConfig: taxConfig,
      taxLegalAccepted: taxLegalAccepted,
    );
    if (!taxResult.isValid) return taxResult;

    // 4. Date validation
    final dateResult = validateDates(checkIn: checkIn, checkOut: checkOut);
    if (!dateResult.isValid) return dateResult;

    // 5. Property/Owner validation
    final propertyResult = validatePropertyOwner(
      propertyId: propertyId,
      ownerId: ownerId,
    );
    if (!propertyResult.isValid) return propertyResult;

    // 6. Payment method validation
    final paymentResult = validatePaymentMethod(
      widgetMode: widgetMode,
      selectedPaymentMethod: selectedPaymentMethod,
      widgetSettings: widgetSettings,
    );
    if (!paymentResult.isValid) return paymentResult;

    // 7. Guest count validation
    final guestResult = validateGuestCount(
      adults: adults,
      children: children,
      maxGuests: maxGuests,
    );
    if (!guestResult.isValid) return guestResult;

    // 8. Adult count validation
    final adultResult = validateAdultCount(adults: adults);
    if (!adultResult.isValid) return adultResult;

    return const ValidationResult.success();
  }
}
