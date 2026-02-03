import 'package:intl/intl.dart';
import '../../shared/models/booking_model.dart';
import '../../shared/models/unit_model.dart';
import '../../features/owner_dashboard/domain/models/ical_feed.dart';
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
  /// Now also includes imported iCal events (from Booking.com, Airbnb, etc.)
  static String generateUnitCalendar({
    required UnitModel unit,
    required List<BookingModel> bookings,
    List<IcalEvent>? importedEvents,
  }) {
    final buffer = StringBuffer();

    // Calendar header (RFC 5545 requires CRLF line endings)
    buffer.write('BEGIN:VCALENDAR\r\n');
    buffer.write('VERSION:2.0\r\n');
    buffer.write('PRODID:-//BookBed//NONSGML Event Calendar//EN\r\n');
    buffer.write('CALSCALE:GREGORIAN\r\n');
    buffer.write('METHOD:PUBLISH\r\n');
    buffer.write('X-WR-CALNAME:${_escape(unit.name)} - Bookings\r\n');
    buffer.write('X-WR-TIMEZONE:Europe/Zagreb\r\n');
    buffer.write('X-WR-CALDESC:Booking calendar for ${_escape(unit.name)}\r\n');

    // Add each booking as an event
    for (final booking in bookings) {
      buffer.write(_formatEvent(booking, unit.name));
    }

    // Add imported iCal events (from external platforms)
    if (importedEvents != null) {
      for (final event in importedEvents) {
        buffer.write(_formatIcalEvent(event, unit.name));
      }
    }

    // Calendar footer
    buffer.write('END:VCALENDAR\r\n');

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

    // Calendar header (RFC 5545 requires CRLF line endings)
    buffer.write('BEGIN:VCALENDAR\r\n');
    buffer.write('VERSION:2.0\r\n');
    buffer.write('PRODID:-//BookBed//NONSGML Event Calendar//EN\r\n');
    buffer.write('CALSCALE:GREGORIAN\r\n');
    buffer.write('METHOD:PUBLISH\r\n');

    // Single event
    buffer.write(_formatEvent(booking, unitName));

    // Calendar footer
    buffer.write('END:VCALENDAR\r\n');

    return buffer.toString();
  }

  /// Format a single booking as VEVENT
  ///
  /// Creates an all-day event from checkIn to checkOut
  static String _formatEvent(BookingModel booking, String unitName) {
    final buffer = StringBuffer();

    // Event start
    buffer.write('BEGIN:VEVENT\r\n');

    // UID - Unique identifier (required by RFC 5545)
    buffer.write('UID:booking-${booking.id}@bookbed.io\r\n');

    // DTSTAMP - Timestamp when event was created (required)
    buffer.write('DTSTAMP:${_formatTimestamp(booking.createdAt)}\r\n');

    // DTSTART - Start date (all-day event)
    buffer.write('DTSTART;VALUE=DATE:${_formatDate(booking.checkIn)}\r\n');

    // DTEND - End date (all-day event, exclusive)
    buffer.write('DTEND;VALUE=DATE:${_formatDate(booking.checkOut)}\r\n');

    // SUMMARY - Event title
    final guestName = booking.guestName ?? 'Guest';
    buffer.write('SUMMARY:${_escape('Booking: $guestName - $unitName')}\r\n');

    // DESCRIPTION - Event details
    final description = _buildDescription(booking, unitName);
    buffer.write('DESCRIPTION:${_escape(description)}\r\n');

    // STATUS - Booking status
    final status = _mapBookingStatus(booking.status);
    buffer.write('STATUS:$status\r\n');

    // LOCATION - Unit name
    buffer.write('LOCATION:${_escape(unitName)}\r\n');

    // LAST-MODIFIED - Last update timestamp
    if (booking.updatedAt != null) {
      buffer.write('LAST-MODIFIED:${_formatTimestamp(booking.updatedAt!)}\r\n');
    }

    // CREATED - Creation timestamp
    buffer.write('CREATED:${_formatTimestamp(booking.createdAt)}\r\n');

    // Event end
    buffer.write('END:VEVENT\r\n');

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

  /// Format an imported iCal event as VEVENT
  ///
  /// Creates an all-day event from startDate to endDate
  /// Used for events imported from external platforms (Booking.com, Airbnb, etc.)
  static String _formatIcalEvent(IcalEvent event, String unitName) {
    final buffer = StringBuffer();

    // Event start
    buffer.write('BEGIN:VEVENT\r\n');

    // UID - Unique identifier (required by RFC 5545)
    // Use external ID from the imported event
    buffer.write('UID:${event.externalId}@bookbed.io\r\n');

    // DTSTAMP - Timestamp when event was created (required)
    buffer.write('DTSTAMP:${_formatTimestamp(event.createdAt)}\r\n');

    // DTSTART - Start date (all-day event)
    buffer.write('DTSTART;VALUE=DATE:${_formatDate(event.startDate)}\r\n');

    // DTEND - End date (all-day event, exclusive)
    buffer.write('DTEND;VALUE=DATE:${_formatDate(event.endDate)}\r\n');

    // SUMMARY - Event title with source platform
    buffer.write(
      'SUMMARY:${_escape('${event.guestName} (${event.source}) - $unitName')}\r\n',
    );

    // DESCRIPTION - Event details
    final descriptionParts = <String>[];
    descriptionParts.add('Unit: $unitName');
    descriptionParts.add('Source: ${event.source}');
    descriptionParts.add('Guest: ${event.guestName}');
    if (event.description != null && event.description!.isNotEmpty) {
      descriptionParts.add('Notes: ${event.description}');
    }
    descriptionParts.add('Imported Event ID: ${event.id}');
    buffer.write('DESCRIPTION:${_escape(descriptionParts.join('\n'))}\r\n');

    // STATUS - Always CONFIRMED for imported events
    buffer.write('STATUS:CONFIRMED\r\n');

    // LOCATION - Unit name
    buffer.write('LOCATION:${_escape(unitName)}\r\n');

    // LAST-MODIFIED - Last update timestamp
    buffer.write('LAST-MODIFIED:${_formatTimestamp(event.updatedAt)}\r\n');

    // CREATED - Creation timestamp
    buffer.write('CREATED:${_formatTimestamp(event.createdAt)}\r\n');

    // Event end
    buffer.write('END:VEVENT\r\n');

    return buffer.toString();
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
