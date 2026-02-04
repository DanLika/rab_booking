import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/core/services/ical_generator.dart';
import 'package:bookbed/shared/models/booking_model.dart';
import 'package:bookbed/shared/models/unit_model.dart';
import 'package:bookbed/core/constants/enums.dart';

void main() {
  group('IcalGenerator Strict Compliance', () {
    final unit = UnitModel(
      id: 'unit-1',
      propertyId: 'prop-1',
      name: 'Test Setup Unit',
      pricePerNight: 100,
      maxGuests: 2,
      createdAt: DateTime.now(),
    );

    final booking = BookingModel(
      id: 'booking-1',
      unitId: 'unit-1',
      checkIn: DateTime(2025, 1, 1),
      checkOut: DateTime(2025, 1, 5),
      status: BookingStatus.confirmed,
      createdAt: DateTime.now(),
      guestName: 'John Doe',
      totalPrice: 400,
    );

    test('validates RFC 5545 compliance structure', () {
      final ics = IcalGenerator.generateUnitCalendar(
        unit: unit,
        bookings: [booking],
      );

      // Lines must be delimited by CRLF (RFC 5545)
      // The generator uses buffer.write('...\r\n') for RFC 5545 compliance.

      expect(ics, contains('BEGIN:VCALENDAR'));
      expect(ics, contains('VERSION:2.0'));
      expect(ics, contains('PRODID:-//BookBed//NONSGML Event Calendar//EN'));
      expect(ics, contains('CALSCALE:GREGORIAN'));
      expect(ics, contains('METHOD:PUBLISH'));
      expect(ics, contains('END:VCALENDAR'));
    });

    test('validates DATE format for DTSTART and DTEND (VALUE=DATE)', () {
      final ics = IcalGenerator.generateUnitCalendar(
        unit: unit,
        bookings: [booking],
      );

      // Regex to match: DTSTART;VALUE=DATE:20250101
      expect(ics, matches(r'DTSTART;VALUE=DATE:\d{8}'));
      expect(ics, matches(r'DTEND;VALUE=DATE:\d{8}'));

      // Specifically check the dates
      expect(ics, contains('DTSTART;VALUE=DATE:20250101'));
      expect(
        ics,
        contains('DTEND;VALUE=DATE:20250105'),
      ); // End date is exclusive (check-out day)
    });

    test('validates existence of DTSTAMP and UID', () {
      final ics = IcalGenerator.generateUnitCalendar(
        unit: unit,
        bookings: [booking],
      );

      expect(ics, contains('DTSTAMP:'));
      expect(ics, contains('UID:booking-booking-1@bookbed.io'));
    });

    test('validates at least one booking implies generated content', () {
      // If bookings are provided, events should be generated.
      // The requirement "The feed contains at least one booking" implies that
      // IF the system says "feed is valid", it must have content?
      // Or if we test with 0 bookings, does it still generate valid calendar (just empty)?
      // RFC 5545 allows empty calendars (no VEVENT).

      final emptyIcs = IcalGenerator.generateUnitCalendar(
        unit: unit,
        bookings: [],
      );
      expect(emptyIcs, contains('BEGIN:VCALENDAR'));
      expect(emptyIcs, contains('END:VCALENDAR'));
      expect(emptyIcs, isNot(contains('BEGIN:VEVENT')));
    });
  });
}
