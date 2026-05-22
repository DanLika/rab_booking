import 'package:flutter/material.dart';

import '../presentation/widgets/country_code_dropdown.dart';
import '../presentation/providers/booking_price_provider.dart';
import '../services/form_persistence_service.dart';
import '../utils/date_normalizer.dart';

/// Centralized state management for the booking widget form.
///
/// Extracted from BookingWidgetScreen to reduce state variable sprawl
/// and improve testability. Contains all form-related state including:
/// date selection, form controllers, guest counts, payment selection,
/// and UI state flags.
///
/// Extends [ChangeNotifier] so downstream composers can subscribe via
/// `ListenableBuilder` without prop-drilling. Existing screen code that
/// wraps mutations in `setState((){})` continues to work unchanged — the
/// notification is additive.
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
class BookingFormState extends ChangeNotifier {
  // ============================================
  // DATE SELECTION
  // ============================================

  DateTime? _checkIn;
  DateTime? get checkIn => _checkIn;
  set checkIn(DateTime? value) {
    if (_checkIn == value) return;
    _checkIn = value;
    notifyListeners();
  }

  DateTime? _checkOut;
  DateTime? get checkOut => _checkOut;
  set checkOut(DateTime? value) {
    if (_checkOut == value) return;
    _checkOut = value;
    notifyListeners();
  }

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

  int _adults = 1;
  int get adults => _adults;
  set adults(int value) {
    if (_adults == value) return;
    _adults = value;
    notifyListeners();
  }

  int _children = 0;
  int get children => _children;
  set children(int value) {
    if (_children == value) return;
    _children = value;
    notifyListeners();
  }

  int _pets = 0;
  int get pets => _pets;
  set pets(int value) {
    if (_pets == value) return;
    _pets = value;
    notifyListeners();
  }

  /// Total guest count
  int get totalGuests => _adults + _children;

  // ============================================
  // COUNTRY SELECTION
  // ============================================

  Country _selectedCountry = defaultCountry;
  Country get selectedCountry => _selectedCountry;
  set selectedCountry(Country value) {
    if (identical(_selectedCountry, value)) return;
    _selectedCountry = value;
    notifyListeners();
  }

  // ============================================
  // PAYMENT SELECTION
  // ============================================

  String _selectedPaymentMethod = 'stripe';
  String get selectedPaymentMethod => _selectedPaymentMethod;
  set selectedPaymentMethod(String value) {
    if (_selectedPaymentMethod == value) return;
    _selectedPaymentMethod = value;
    notifyListeners();
  }

  String _selectedPaymentOption = 'deposit';
  String get selectedPaymentOption => _selectedPaymentOption;
  set selectedPaymentOption(String value) {
    if (_selectedPaymentOption == value) return;
    _selectedPaymentOption = value;
    notifyListeners();
  }

  // ============================================
  // VERIFICATION & ACCEPTANCE
  // ============================================

  bool _emailVerified = false;
  bool get emailVerified => _emailVerified;
  set emailVerified(bool value) {
    if (_emailVerified == value) return;
    _emailVerified = value;
    notifyListeners();
  }

  bool _taxLegalAccepted = false;
  bool get taxLegalAccepted => _taxLegalAccepted;
  set taxLegalAccepted(bool value) {
    if (_taxLegalAccepted == value) return;
    _taxLegalAccepted = value;
    notifyListeners();
  }

  // ============================================
  // UI STATE FLAGS
  // ============================================

  bool _showGuestForm = false;
  bool get showGuestForm => _showGuestForm;
  set showGuestForm(bool value) {
    if (_showGuestForm == value) return;
    _showGuestForm = value;
    notifyListeners();
  }

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;
  set isProcessing(bool value) {
    if (_isProcessing == value) return;
    _isProcessing = value;
    notifyListeners();
  }

  bool _isVerifyingEmail = false;
  bool get isVerifyingEmail => _isVerifyingEmail;
  set isVerifyingEmail(bool value) {
    if (_isVerifyingEmail == value) return;
    _isVerifyingEmail = value;
    notifyListeners();
  }

  bool _pillBarDismissed = false;
  bool get pillBarDismissed => _pillBarDismissed;
  set pillBarDismissed(bool value) {
    if (_pillBarDismissed == value) return;
    _pillBarDismissed = value;
    notifyListeners();
  }

  bool _hasInteractedWithBookingFlow = false;
  bool get hasInteractedWithBookingFlow => _hasInteractedWithBookingFlow;
  set hasInteractedWithBookingFlow(bool value) {
    if (_hasInteractedWithBookingFlow == value) return;
    _hasInteractedWithBookingFlow = value;
    notifyListeners();
  }

  // ============================================
  // PRICE LOCKING (Bug #64)
  // ============================================

  BookingPriceCalculation? _lockedPriceCalculation;
  BookingPriceCalculation? get lockedPriceCalculation =>
      _lockedPriceCalculation;
  set lockedPriceCalculation(BookingPriceCalculation? value) {
    if (identical(_lockedPriceCalculation, value)) return;
    _lockedPriceCalculation = value;
    notifyListeners();
  }

  // ============================================
  // METHODS
  // ============================================

  /// Dispose all text controllers
  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    notesController.dispose();
    super.dispose();
  }

  /// Reset all form state to initial values.
  ///
  /// Called after successful booking or when user closes booking flow.
  /// Does NOT invalidate providers — caller should do that.
  /// Fires [notifyListeners] exactly once after all fields are reset.
  void resetState() {
    // Clear text controllers (these have their own listeners — fine to mutate)
    firstNameController.clear();
    lastNameController.clear();
    emailController.clear();
    phoneController.clear();
    notesController.clear();

    // Reset all private backing fields directly so we don't fan out 16 separate
    // notifyListeners() — one final call at the end.
    _checkIn = null;
    _checkOut = null;
    _adults = 1;
    _children = 0;
    _pets = 0;
    _selectedCountry = defaultCountry;
    _selectedPaymentMethod = 'stripe';
    _selectedPaymentOption = 'deposit';
    _hasInteractedWithBookingFlow = false;
    _pillBarDismissed = false;
    _showGuestForm = false;
    _emailVerified = false;
    _taxLegalAccepted = false;
    _lockedPriceCalculation = null;
    _isProcessing = false;
    _isVerifyingEmail = false;

    notifyListeners();
  }

  /// Calculate number of nights from selected dates.
  ///
  /// Returns 0 if dates are not selected.
  /// SF-026: DateNormalizer.nightsBetween normalizes to UTC midnight before
  /// diff so DST boundaries don't off-by-one.
  int get nights {
    final checkInDate = _checkIn;
    final checkOutDate = _checkOut;
    if (checkInDate == null || checkOutDate == null) return 0;
    return DateNormalizer.nightsBetween(checkInDate, checkOutDate);
  }

  /// Check if dates are selected
  bool get hasDatesSelected => _checkIn != null && _checkOut != null;

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
      return '';
    }
    return '${_selectedCountry.dialCode} $phone';
  }

  /// Adjust guest count to respect max capacity
  ///
  /// Called when unit data is loaded to ensure defaults don't exceed limits.
  /// Uses [effectiveMax] which should be maxTotalCapacity ?? maxGuests.
  /// Notifies listeners only when an adjustment actually happens.
  void adjustGuestCountToCapacity(int effectiveMax) {
    if (effectiveMax <= 0) return; // Defensive check

    if (totalGuests > effectiveMax) {
      _adults = effectiveMax;
      _children = 0;
      notifyListeners();
    }
  }

  /// Serialize the current state into a [PersistedFormData] blob suitable
  /// for [FormPersistenceService.saveFormData].
  ///
  /// [unitId] is required because persistence is keyed by unit. [propertyId]
  /// is optional — slug-resolved URLs may not have it at save time.
  PersistedFormData toPersistedFormData({
    required String unitId,
    String? propertyId,
  }) {
    return PersistedFormData(
      unitId: unitId,
      propertyId: propertyId,
      checkIn: _checkIn,
      checkOut: _checkOut,
      firstName: firstNameController.text,
      lastName: lastNameController.text,
      email: emailController.text,
      phone: phoneController.text,
      countryCode: _selectedCountry.dialCode,
      adults: _adults,
      children: _children,
      notes: notesController.text,
      paymentMethod: _selectedPaymentMethod,
      pillBarDismissed: _pillBarDismissed,
      hasInteractedWithBookingFlow: _hasInteractedWithBookingFlow,
      timestamp: DateTime.now().toUtc(),
    );
  }

  /// Restore state from a previously persisted [PersistedFormData] blob.
  ///
  /// All mutations happen against private backing fields so listeners only
  /// fire once at the end. Controllers are updated via `.text = …`.
  ///
  /// Note: capacity clamping and unit-specific constraints (e.g. pets
  /// disallowed) must be applied by the caller AFTER this call, because
  /// `BookingFormState` deliberately does not depend on `UnitModel`.
  void applyFromPersisted(PersistedFormData data) {
    _checkIn = data.checkIn;
    _checkOut = data.checkOut;
    firstNameController.text = data.firstName;
    lastNameController.text = data.lastName;
    emailController.text = data.email;
    phoneController.text = data.phone;
    _selectedCountry = data.country;
    _adults = data.adults;
    _children = data.children;
    notesController.text = data.notes;
    _selectedPaymentMethod = data.paymentMethod;
    _pillBarDismissed = data.pillBarDismissed;
    _hasInteractedWithBookingFlow = data.hasInteractedWithBookingFlow;

    notifyListeners();
  }
}
