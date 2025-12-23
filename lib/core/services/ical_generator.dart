import 'package:intl/intl.dart';
import '../../shared/models/booking_model.dart';
import '../../shared/models/unit_model.dart';
import '../constants/enums.dart';

/// iCal (RFC 5545) generator for booking calendar export
///
/// Generates .ics files compatible with all major calendar applications:
/// - Google Calendar
/// - Apple Calendar
/// - Outlook
/// - Thunderbird
class IcalGenerator {
  IcalGenerator._(); // Private constructor

  /// Generate complete iCal calendar for all bookings of a unit
  ///
  /// Used for owner export - includes all bookings for a specific unit
  static String generateUnitCalendar({
    required UnitModel unit,
    required List<BookingModel> bookings,
  }) {
    final buffer = StringBuffer();

    // Calendar header
    buffer.writeln('BEGIN:VCALENDAR');
    buffer.writeln('VERSION:2.0');
    buffer.writeln('PRODID:-//BookBed//NONSGML Event Calendar//EN');
    buffer.writeln('CALSCALE:GREGORIAN');
    buffer.writeln('METHOD:PUBLISH');
    buffer.writeln('X-WR-CALNAME:${_escape(unit.name)} - Bookings');
    buffer.writeln('X-WR-TIMEZONE:Europe/Zagreb');
    buffer.writeln('X-WR-CALDESC:Booking calendar for ${_escape(unit.name)}');

    // Add each booking as an event
    for (final booking in bookings) {
      buffer.write(_formatEvent(booking, unit.name));
    }

    // Calendar footer
    buffer.writeln('END:VCALENDAR');

    return buffer.toString();
  }

  /// Generate single booking event as iCal
  ///
  /// Used for guest download - generates a single event for a specific booking
  static String generateBookingEvent({
    required BookingModel booking,
    required String unitName,
  }) {
    final buffer = StringBuffer();

    // Calendar header
    buffer.writeln('BEGIN:VCALENDAR');
    buffer.writeln('VERSION:2.0');
    buffer.writeln('PRODID:-//BookBed//NONSGML Event Calendar//EN');
    buffer.writeln('CALSCALE:GREGORIAN');
    buffer.writeln('METHOD:PUBLISH');

    // Single event
    buffer.write(_formatEvent(booking, unitName));

    // Calendar footer
    buffer.writeln('END:VCALENDAR');

    return buffer.toString();
  }

  /// Format a single booking as VEVENT
  ///
  /// Creates an all-day event from checkIn to checkOut
  static String _formatEvent(BookingModel booking, String unitName) {
    final buffer = StringBuffer();

    // Event start
    buffer.writeln('BEGIN:VEVENT');

    // UID - Unique identifier (required by RFC 5545)
    buffer.writeln('UID:booking-${booking.id}@bookbed.io');

    // DTSTAMP - Timestamp when event was created (required)
    buffer.writeln('DTSTAMP:${_formatTimestamp(booking.createdAt)}');

    // DTSTART - Start date (all-day event)
    buffer.writeln('DTSTART;VALUE=DATE:${_formatDate(booking.checkIn)}');

    // DTEND - End date (all-day event, exclusive - day after checkout)
    final endDate = booking.checkOut.add(const Duration(days: 1));
    buffer.writeln('DTEND;VALUE=DATE:${_formatDate(endDate)}');

    // SUMMARY - Event title
    final guestName = booking.guestName ?? 'Guest';
    buffer.writeln('SUMMARY:${_escape('Booking: $guestName - $unitName')}');

    // DESCRIPTION - Event details
    final description = _buildDescription(booking, unitName);
    buffer.writeln('DESCRIPTION:${_escape(description)}');

    // STATUS - Booking status
    final status = _mapBookingStatus(booking.status);
    buffer.writeln('STATUS:$status');

    // LOCATION - Unit name
    buffer.writeln('LOCATION:${_escape(unitName)}');

    // LAST-MODIFIED - Last update timestamp
    if (booking.updatedAt != null) {
      buffer.writeln('LAST-MODIFIED:${_formatTimestamp(booking.updatedAt!)}');
    }

    // CREATED - Creation timestamp
    buffer.writeln('CREATED:${_formatTimestamp(booking.createdAt)}');

    // Event end
    buffer.writeln('END:VEVENT');

    return buffer.toString();
  }

  /// Build event description with booking details
  static String _buildDescription(BookingModel booking, String unitName) {
    final parts = <String>[];

    // Unit
    parts.add('Unit: $unitName');

    // Guest info
    if (booking.guestName != null) {
      parts.add('Guest: ${booking.guestName}');
    }
    if (booking.guestEmail != null) {
      parts.add('Email: ${booking.guestEmail}');
    }
    if (booking.guestPhone != null) {
      parts.add('Phone: ${booking.guestPhone}');
    }

    // Guest count
    parts.add('Guests: ${booking.guestCount}');

    // Check-in/out times
    if (booking.checkInTime != null) {
      parts.add('Check-in: ${booking.checkInTime}');
    }
    if (booking.checkOutTime != null) {
      parts.add('Check-out: ${booking.checkOutTime}');
    }

    // Price
    if (booking.totalPrice > 0) {
      parts.add('Total: €${booking.totalPrice.toStringAsFixed(2)}');
    }

    // Payment status
    if (booking.paymentStatus != null) {
      parts.add('Payment: ${booking.paymentStatus}');
    }

    // Notes
    if (booking.notes != null && booking.notes!.isNotEmpty) {
      parts.add('Notes: ${booking.notes}');
    }

    // Booking ID
    parts.add('Booking ID: ${booking.id}');

    // Join with actual newlines - _escape() will convert to \n for iCal format
    return parts.join('\n');
  }

  /// Map BookingStatus to iCal STATUS
  static String _mapBookingStatus(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return 'CONFIRMED';
      case BookingStatus.pending:
        return 'TENTATIVE';
      case BookingStatus.cancelled:
        return 'CANCELLED';
      case BookingStatus.completed:
        return 'CONFIRMED';
    }
  }

  /// Format date as YYYYMMDD (for all-day events)
  static String _formatDate(DateTime date) {
    return DateFormat('yyyyMMdd').format(date);
  }

  /// Format timestamp as YYYYMMDDTHHMMSSZ (UTC)
  static String _formatTimestamp(DateTime dateTime) {
    final utc = dateTime.toUtc();
    return DateFormat('yyyyMMdd\'T\'HHmmss\'Z\'').format(utc);
  }

  /// Escape special characters for iCal format
  ///
  /// RFC 5545 requires escaping:
  /// - Comma (,) -> \,
  /// - Semicolon (;) -> \;
  /// - Backslash (\) -> \\
  /// - Newline (\n) -> \\n
  static String _escape(String text) {
    return text
        .replaceAll('\\', '\\\\')
        .replaceAll(',', '\\,')
        .replaceAll(';', '\\;')
        .replaceAll('\n', '\\n');
  }

  /// Generate filename for iCal export
  ///
  /// Format: unit-name-YYYYMMDD.ics
  static String generateFilename(String unitName) {
    final sanitized = unitName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');

    final date = DateFormat('yyyyMMdd').format(DateTime.now());
    return '$sanitized-$date.ics';
  }
}
