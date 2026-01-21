import 'package:flutter/material.dart';

import '../presentation/widgets/country_code_dropdown.dart';
import '../presentation/providers/booking_price_provider.dart';

/// Centralized state management for the booking widget form.
///
/// Extracted from BookingWidgetScreen to reduce state variable sprawl
/// and improve testability. Contains all form-related state including:
/// - Date selection
/// - Form controllers
/// - Guest counts
/// - Payment selection
/// - UI state flags
///
/// Usage:
/// ```dart
/// class _BookingWidgetScreenState extends ConsumerState<BookingWidgetScreen> {
///   final _formState = BookingFormState();
///
///   @override
///   void dispose() {
///     _formState.dispose();
///     super.dispose();
///   }
/// }
/// ```
class BookingFormState {
  // ============================================
  // DATE SELECTION
  // ============================================

  /// Selected check-in date (null if not selected)
  DateTime? checkIn;

  /// Selected check-out date (null if not selected)
  DateTime? checkOut;

  // ============================================
  // FORM CONTROLLERS
  // ============================================

  /// Form key for validation
  final formKey = GlobalKey<FormState>();

  /// Guest first name
  final firstNameController = TextEditingController();

  /// Guest last name
  final lastNameController = TextEditingController();

  /// Guest email address
  final emailController = TextEditingController();

  /// Guest phone number (without country code)
  final phoneController = TextEditingController();

  /// Special requests / notes
  final notesController = TextEditingController();

  // ============================================
  // GUEST COUNT
  // ============================================

  /// Number of adult guests (minimum 1)
  int adults = 1;

  /// Number of child guests
  int children = 0;

  /// Total guest count
  int get totalGuests => adults + children;

  // ============================================
  // COUNTRY SELECTION
  // ============================================

  /// Selected country for phone number
  Country selectedCountry = defaultCountry;

  // ============================================
  // PAYMENT SELECTION
  // ============================================

  /// Selected payment method: 'stripe', 'bank_transfer', 'pay_on_arrival'
  String selectedPaymentMethod = 'stripe';

  /// Selected payment option: 'deposit' or 'full'
  String selectedPaymentOption = 'deposit';

  // ============================================
  // VERIFICATION & ACCEPTANCE
  // ============================================

  /// Whether guest email has been verified via OTP
  bool emailVerified = false;

  /// Whether guest accepted tax/legal disclaimer (Bug #68)
  bool taxLegalAccepted = false;

  // ============================================
  // UI STATE FLAGS
  // ============================================

  /// Whether guest form panel is currently shown
  bool showGuestForm = false;

  /// Whether a booking operation is in progress
  bool isProcessing = false;

  /// Whether email verification is in progress (loading state for verify button)
  bool isVerifyingEmail = false;

  /// Whether user dismissed the pill bar with X button (Bug Fix: Auto-open)
  bool pillBarDismissed = false;

  /// Whether user has interacted with booking flow (clicked Reserve)
  bool hasInteractedWithBookingFlow = false;

  // ============================================
  // PRICE LOCKING (Bug #64)
  // ============================================

  /// Locked price calculation to prevent payment mismatches
  BookingPriceCalculation? lockedPriceCalculation;

  // ============================================
  // METHODS
  // ============================================

  /// Dispose all text controllers
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    notesController.dispose();
  }

  /// Reset all form state to initial values
  ///
  /// Called after successful booking or when user closes booking flow.
  /// Does NOT invalidate providers - caller should do that.
  void resetState() {
    // Clear text controllers
    firstNameController.clear();
    lastNameController.clear();
    emailController.clear();
    phoneController.clear();
    notesController.clear();

    // Reset date selection
    checkIn = null;
    checkOut = null;

    // Reset guest count to defaults
    adults = 1;
    children = 0;

    // Reset country to default
    selectedCountry = defaultCountry;

    // Reset payment to default
    selectedPaymentMethod = 'stripe';
    selectedPaymentOption = 'deposit';

    // Reset booking flow state
    hasInteractedWithBookingFlow = false;
    pillBarDismissed = false;
    showGuestForm = false;

    // Reset verification & acceptance
    emailVerified = false;
    taxLegalAccepted = false;

    // Reset UI state
    lockedPriceCalculation = null;
    isProcessing = false;
    isVerifyingEmail = false;
  }

  /// Calculate number of nights from selected dates
  ///
  /// Returns 0 if dates are not selected.
  int get nights {
    final checkInDate = checkIn;
    final checkOutDate = checkOut;
    if (checkInDate == null || checkOutDate == null) return 0;
    return checkOutDate.difference(checkInDate).inDays;
  }

  /// Check if dates are selected
  bool get hasDatesSelected => checkIn != null && checkOut != null;

  /// Get full guest name from controllers
  ///
  /// Returns empty string if both fields are empty (expected behavior).
  String get guestFullName {
    final first = firstNameController.text.trim();
    final last = lastNameController.text.trim();
    final fullName = '$first $last'.trim();
    return fullName;
  }

  /// Get full phone number with country code
  ///
  /// Returns empty string if phone is not entered.
  String get fullPhoneNumber {
    final phone = phoneController.text.trim();
    if (phone.isEmpty) {
      return ''; // Return empty string if phone is not entered
    }
    return '${selectedCountry.dialCode} $phone';
  }

  /// Adjust guest count to respect max capacity
  ///
  /// Called when unit data is loaded to ensure defaults don't exceed limits.
  void adjustGuestCountToCapacity(int maxGuests) {
    if (maxGuests <= 0) return; // Defensive check

    if (totalGuests > maxGuests) {
      adults = maxGuests; // maxGuests is already >= 1 (checked above)
      children = 0;
    }
  }
}
