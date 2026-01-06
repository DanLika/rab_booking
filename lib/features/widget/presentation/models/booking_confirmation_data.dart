import '../../../../shared/models/booking_model.dart';
import '../../domain/models/widget_settings.dart';

/// Data class for booking confirmation parameters.
///
/// Groups related booking data to reduce constructor parameter count
/// in BookingConfirmationScreen from 13+ parameters to a single object.
///
/// Usage:
/// ```dart
/// final data = BookingConfirmationData(
///   bookingReference: 'BK-123',
///   guestEmail: 'guest@example.com',
///   guestName: 'John Doe',
///   checkIn: DateTime(2025, 1, 15),
///   checkOut: DateTime(2025, 1, 20),
///   totalPrice: 500.0,
///   nights: 5,
///   guests: 2,
///   propertyName: 'Beach Villa',
///   paymentMethod: 'stripe',
/// );
///
/// BookingConfirmationScreen(data: data);
/// ```
class BookingConfirmationData {
  /// Unique booking reference (e.g., "BK-ABC123")
  final String bookingReference;

  /// Guest's email address
  final String guestEmail;

  /// Guest's full name
  final String guestName;

  /// Check-in date
  final DateTime checkIn;

  /// Check-out date
  final DateTime checkOut;

  /// Total price for the booking
  final double totalPrice;

  /// Number of nights
  final int nights;

  /// Number of guests
  final int guests;

  /// Property name
  final String propertyName;

  /// Unit name (optional, for multi-unit properties)
  final String? unitName;

  /// Payment method used (stripe, bank_transfer, pay_on_arrival)
  final String paymentMethod;

  /// Full booking model (optional, for additional features)
  final BookingModel? booking;

  /// Email configuration (optional)
  final EmailNotificationConfig? emailConfig;

  /// Widget settings (optional)
  final WidgetSettings? widgetSettings;

  /// Property ID for navigation
  final String? propertyId;

  /// Unit ID for navigation
  final String? unitId;

  /// Sentinel value for copyWith to distinguish between "not provided" and "explicitly set to null"
  static const _sentinel = Object();

  /// Helper to return non-empty string or fallback
  /// Handles both null and empty string cases
  static String _nonEmptyOr(String? value, String fallback) {
    return (value?.isNotEmpty ?? false) ? value! : fallback;
  }

  const BookingConfirmationData({
    required this.bookingReference,
    required this.guestEmail,
    required this.guestName,
    required this.checkIn,
    required this.checkOut,
    required this.totalPrice,
    required this.nights,
    required this.guests,
    required this.propertyName,
    this.unitName,
    required this.paymentMethod,
    this.booking,
    this.emailConfig,
    this.widgetSettings,
    this.propertyId,
    this.unitId,
  });

  /// Creates from a BookingModel
  factory BookingConfirmationData.fromBooking({
    required BookingModel booking,
    required String propertyName,
    required String guestName,
    required String guestEmail,
    String? unitName,
    EmailNotificationConfig? emailConfig,
    WidgetSettings? widgetSettings,
    String? propertyId,
    String? unitId,
  }) {
    return BookingConfirmationData(
      bookingReference: _nonEmptyOr(booking.bookingReference, booking.id),
      guestEmail: guestEmail,
      guestName: guestName,
      checkIn: booking.checkIn,
      checkOut: booking.checkOut,
      totalPrice: booking.totalPrice,
      nights: booking.checkOut.difference(booking.checkIn).inDays,
      guests: booking.guestCount,
      propertyName: propertyName,
      unitName: unitName,
      paymentMethod: _nonEmptyOr(booking.paymentMethod, 'unknown'),
      booking: booking,
      emailConfig: emailConfig,
      widgetSettings: widgetSettings,
      propertyId: propertyId,
      unitId: unitId,
    );
  }

  /// Creates a copy with some fields replaced
  ///
  /// For nullable fields, you can explicitly set them to null:
  /// ```dart
  /// data.copyWith(unitName: null) // Sets unitName to null
  /// ```
  ///
  /// If you don't provide a nullable field, it keeps the existing value:
  /// ```dart
  /// data.copyWith(propertyName: 'New Name') // unitName stays unchanged
  /// ```
  BookingConfirmationData copyWith({
    String? bookingReference,
    String? guestEmail,
    String? guestName,
    DateTime? checkIn,
    DateTime? checkOut,
    double? totalPrice,
    int? nights,
    int? guests,
    String? propertyName,
    String? paymentMethod,
    // Nullable fields use sentinel pattern to support explicit null assignment
    Object? unitName = _sentinel,
    Object? booking = _sentinel,
    Object? emailConfig = _sentinel,
    Object? widgetSettings = _sentinel,
    Object? propertyId = _sentinel,
    Object? unitId = _sentinel,
  }) {
    return BookingConfirmationData(
      bookingReference: bookingReference ?? this.bookingReference,
      guestEmail: guestEmail ?? this.guestEmail,
      guestName: guestName ?? this.guestName,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      totalPrice: totalPrice ?? this.totalPrice,
      nights: nights ?? this.nights,
      guests: guests ?? this.guests,
      propertyName: propertyName ?? this.propertyName,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      // Use sentinel pattern for nullable fields to support explicit null
      unitName: identical(unitName, _sentinel)
          ? this.unitName
          : unitName as String?,
      booking: identical(booking, _sentinel)
          ? this.booking
          : booking as BookingModel?,
      emailConfig: identical(emailConfig, _sentinel)
          ? this.emailConfig
          : emailConfig as EmailNotificationConfig?,
      widgetSettings: identical(widgetSettings, _sentinel)
          ? this.widgetSettings
          : widgetSettings as WidgetSettings?,
      propertyId: identical(propertyId, _sentinel)
          ? this.propertyId
          : propertyId as String?,
      unitId: identical(unitId, _sentinel) ? this.unitId : unitId as String?,
    );
  }
}
