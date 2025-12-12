import '../../../../core/services/booking_service.dart';
import '../../../../shared/models/booking_model.dart';
import '../../../../shared/models/unit_model.dart';
import '../../../../shared/utils/validators/input_sanitizer.dart';
import '../../utils/email_notification_helper.dart';
import '../models/widget_mode.dart';
import '../models/widget_settings.dart';
import '../models/booking_submission_result.dart';

/// Parameters for booking submission.
class SubmitBookingParams {
  // Unit & Property
  final String unitId;
  final String propertyId;
  final String ownerId;
  final UnitModel? unit;
  final WidgetSettings? widgetSettings;

  // Dates
  final DateTime checkIn;
  final DateTime checkOut;

  // Guest Info
  final String firstName;
  final String lastName;
  final String email;
  final String phoneWithCountryCode;
  final String? notes;
  final int adults;
  final int children;

  // Payment
  final double totalPrice;
  final String paymentMethod; // 'stripe', 'bank_transfer', 'pay_on_arrival', 'none'
  final String paymentOption; // 'deposit', 'full', 'none'

  // Tax/Legal
  final bool taxLegalAccepted;

  const SubmitBookingParams({
    required this.unitId,
    required this.propertyId,
    required this.ownerId,
    this.unit,
    this.widgetSettings,
    required this.checkIn,
    required this.checkOut,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneWithCountryCode,
    this.notes,
    required this.adults,
    required this.children,
    required this.totalPrice,
    required this.paymentMethod,
    required this.paymentOption,
    required this.taxLegalAccepted,
  });

  /// Total guest count.
  int get totalGuests => adults + children;

  /// Full guest name.
  String get fullGuestName => '$firstName $lastName'.trim();
}

/// Use case for submitting a booking.
///
/// Handles booking creation for all widget modes and payment methods:
/// - bookingPending: Creates booking immediately with status=pending
/// - bookingInstant + Stripe: Validates availability, returns booking data for checkout
/// - bookingInstant + non-Stripe: Creates booking immediately
///
/// ## Responsibilities:
/// - Input sanitization (XSS prevention)
/// - Booking creation via BookingService
/// - Email notification coordination
/// - Returns appropriate result for UI to handle navigation
///
/// ## Does NOT handle (Widget's responsibility):
/// - Validation (use BookingValidationService before calling this)
/// - Price lock checks (use PriceLockService before calling this)
/// - UI updates (setState, mounted checks)
/// - Navigation (Navigator.push)
/// - Provider invalidation (ref.invalidate)
class SubmitBookingUseCase {
  final BookingService _bookingService;

  SubmitBookingUseCase(this._bookingService);

  /// Compute taxLegalAccepted value for booking creation.
  ///
  /// Returns null if tax/legal config is disabled, otherwise returns the accepted value.
  bool? _computeTaxLegalAccepted(WidgetSettings? settings, bool accepted) {
    if (settings?.taxLegalConfig == null || !settings!.taxLegalConfig.enabled) {
      return null;
    }
    return accepted;
  }

  /// Submit booking and return result.
  ///
  /// Throws exceptions on failure (BookingConflictException, PaymentException, etc.).
  /// Widget should catch and handle errors with appropriate UI feedback.
  Future<BookingSubmissionResult> execute(SubmitBookingParams params) async {
    final widgetMode = params.widgetSettings?.widgetMode ?? WidgetMode.bookingInstant;

    // Sanitize user input to prevent XSS and injection attacks
    final sanitizedGuestName = InputSanitizer.sanitizeName(params.fullGuestName);
    final sanitizedEmail = InputSanitizer.sanitizeEmail(params.email);
    final sanitizedPhone = InputSanitizer.sanitizePhone(params.phoneWithCountryCode);
    final sanitizedNotes = params.notes?.trim().isEmpty ?? true
        ? null
        : InputSanitizer.sanitizeText(params.notes!.trim());

    // Validate that required fields are not empty after sanitization
    // This prevents sending empty strings to the backend which would cause 400 errors
    if (sanitizedGuestName == null || sanitizedGuestName.trim().isEmpty) {
      throw Exception('Guest name is required and cannot be empty. Please enter your first and last name.');
    }
    if (sanitizedEmail == null || sanitizedEmail.trim().isEmpty) {
      throw Exception('Guest email is required and cannot be empty. Please enter a valid email address.');
    }

    // bookingPending mode: Create booking immediately (no payment)
    if (widgetMode == WidgetMode.bookingPending) {
      final bookingResult = await _bookingService.createBooking(
        unitId: params.unitId,
        propertyId: params.propertyId,
        ownerId: params.ownerId,
        checkIn: params.checkIn,
        checkOut: params.checkOut,
        guestName: sanitizedGuestName, // Validated above - guaranteed non-null
        guestEmail: sanitizedEmail, // Validated above - guaranteed non-null
        guestPhone: sanitizedPhone ?? params.phoneWithCountryCode,
        guestCount: params.totalGuests,
        totalPrice: params.totalPrice,
        paymentOption: 'none', // No payment for pending bookings
        paymentMethod: 'none',
        requireOwnerApproval: true, // Always requires approval in bookingPending mode
        notes: sanitizedNotes,
        taxLegalAccepted: _computeTaxLegalAccepted(params.widgetSettings, params.taxLegalAccepted),
      );

      final booking = bookingResult.booking!;

      // Send email notifications
      _sendBookingEmails(
        booking: booking,
        requiresApproval: true,
        widgetSettings: params.widgetSettings,
        unit: params.unit,
      );

      return BookingSubmissionResult.bookingCreated(booking: booking);
    }

    // bookingInstant mode: Create booking with payment
    final bookingResult = await _bookingService.createBooking(
      unitId: params.unitId,
      propertyId: params.propertyId,
      ownerId: params.ownerId,
      checkIn: params.checkIn,
      checkOut: params.checkOut,
      guestName: sanitizedGuestName, // Validated above - guaranteed non-null
      guestEmail: sanitizedEmail, // Validated above - guaranteed non-null
      guestPhone: sanitizedPhone ?? params.phoneWithCountryCode,
      guestCount: params.totalGuests,
      totalPrice: params.totalPrice,
      paymentOption: params.paymentOption, // 'deposit' or 'full'
      paymentMethod: params.paymentMethod, // 'stripe', 'bank_transfer', 'pay_on_arrival'
      requireOwnerApproval: params.widgetSettings?.requireOwnerApproval ?? false,
      notes: sanitizedNotes,
      taxLegalAccepted: _computeTaxLegalAccepted(params.widgetSettings, params.taxLegalAccepted),
    );

    // Stripe flow: Return booking data for checkout (booking not created yet)
    if (params.paymentMethod == 'stripe') {
      if (!bookingResult.isStripeValidation || bookingResult.stripeBookingData == null) {
        throw Exception('Invalid Stripe validation response from booking service');
      }

      return BookingSubmissionResult.stripeValidation(bookingData: bookingResult.stripeBookingData!);
    }

    // Non-Stripe flow: Booking created, send emails
    final booking = bookingResult.booking!;

    _sendBookingEmails(
      booking: booking,
      requiresApproval: params.widgetSettings?.requireOwnerApproval ?? false,
      widgetSettings: params.widgetSettings,
      unit: params.unit,
      paymentMethod: params.paymentMethod,
    );

    return BookingSubmissionResult.bookingCreated(booking: booking);
  }

  /// Helper to send booking emails.
  void _sendBookingEmails({
    required BookingModel booking,
    required bool requiresApproval,
    WidgetSettings? widgetSettings,
    UnitModel? unit,
    String? paymentMethod,
  }) {
    // Calculate payment deadline for bank transfer (if applicable)
    String? paymentDeadline;
    if (paymentMethod == 'bank_transfer') {
      final deadlineDays = widgetSettings?.bankTransferConfig?.paymentDeadlineDays ?? 3;
      final deadline = DateTime.now().add(Duration(days: deadlineDays));
      paymentDeadline =
          '${deadline.day.toString().padLeft(2, '0')}'
          '.${deadline.month.toString().padLeft(2, '0')}'
          '.${deadline.year}';
    }

    EmailNotificationHelper.sendBookingEmails(
      booking: booking,
      requiresApproval: requiresApproval,
      widgetSettings: widgetSettings,
      unit: unit,
      paymentMethod: paymentMethod,
      paymentDeadline: paymentDeadline,
    );
  }
}
