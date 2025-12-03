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
    String? unitName,
    EmailNotificationConfig? emailConfig,
    WidgetSettings? widgetSettings,
    String? propertyId,
    String? unitId,
  }) {
    return BookingConfirmationData(
      bookingReference: booking.bookingReference ?? booking.id,
      guestEmail: booking.guestEmail ?? '',
      guestName: booking.guestName ?? '',
      checkIn: booking.checkIn,
      checkOut: booking.checkOut,
      totalPrice: booking.totalPrice,
      nights: booking.checkOut.difference(booking.checkIn).inDays,
      guests: booking.guestCount,
      propertyName: propertyName,
      unitName: unitName,
      paymentMethod: booking.paymentMethod ?? 'unknown',
      booking: booking,
      emailConfig: emailConfig,
      widgetSettings: widgetSettings,
      propertyId: propertyId,
      unitId: unitId,
    );
  }

  /// Creates a copy with some fields replaced
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
    String? unitName,
    String? paymentMethod,
    BookingModel? booking,
    EmailNotificationConfig? emailConfig,
    WidgetSettings? widgetSettings,
    String? propertyId,
    String? unitId,
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
      unitName: unitName ?? this.unitName,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      booking: booking ?? this.booking,
      emailConfig: emailConfig ?? this.emailConfig,
      widgetSettings: widgetSettings ?? this.widgetSettings,
      propertyId: propertyId ?? this.propertyId,
      unitId: unitId ?? this.unitId,
    );
  }
}
