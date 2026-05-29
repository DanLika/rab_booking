// ignore_for_file: avoid_redundant_argument_values
// Note: DateTime.utc default day=1 / month=1 kept for documentation clarity.
import 'package:bookbed/features/widget/data/models/availability_window.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AvailabilityWindowSource.fromWire', () {
    test('maps "booking" to booking', () {
      expect(
        AvailabilityWindowSource.fromWire('booking'),
        AvailabilityWindowSource.booking,
      );
    });

    test('maps "manual_block" to manualBlock', () {
      expect(
        AvailabilityWindowSource.fromWire('manual_block'),
        AvailabilityWindowSource.manualBlock,
      );
    });

    test('maps "ical_external" to icalExternal', () {
      expect(
        AvailabilityWindowSource.fromWire('ical_external'),
        AvailabilityWindowSource.icalExternal,
      );
    });

    test('falls back to booking for unknown wire value (fail-safe)', () {
      expect(
        AvailabilityWindowSource.fromWire('unknown_string'),
        AvailabilityWindowSource.booking,
      );
    });

    test('falls back to booking for empty wire value', () {
      expect(
        AvailabilityWindowSource.fromWire(''),
        AvailabilityWindowSource.booking,
      );
    });
  });

  group('AvailabilityWindow.fromJson', () {
    test('parses booking window without platform', () {
      final w = AvailabilityWindow.fromJson({
        'start': '2026-06-01T00:00:00.000Z',
        'end': '2026-06-05T00:00:00.000Z',
        'source': 'booking',
      });
      expect(w.source, AvailabilityWindowSource.booking);
      expect(w.platform, isNull);
      expect(w.start.toUtc(), DateTime.utc(2026, 6, 1));
      expect(w.end.toUtc(), DateTime.utc(2026, 6, 5));
    });

    test('parses ical_external window with platform attribution', () {
      final w = AvailabilityWindow.fromJson({
        'start': '2026-07-10T00:00:00.000Z',
        'end': '2026-07-12T00:00:00.000Z',
        'source': 'ical_external',
        'platform': 'Airbnb',
      });
      expect(w.source, AvailabilityWindowSource.icalExternal);
      expect(w.platform, 'Airbnb');
    });

    test('parses manual_block window with no platform', () {
      final w = AvailabilityWindow.fromJson({
        'start': '2026-08-01T00:00:00.000Z',
        'end': '2026-08-02T00:00:00.000Z',
        'source': 'manual_block',
      });
      expect(w.source, AvailabilityWindowSource.manualBlock);
      expect(w.platform, isNull);
    });

    test('coerces non-UTC ISO into UTC instant', () {
      final w = AvailabilityWindow.fromJson({
        'start': '2026-06-01T02:00:00+02:00',
        'end': '2026-06-02T02:00:00+02:00',
        'source': 'booking',
      });
      expect(w.start, DateTime.utc(2026, 6, 1));
      expect(w.end, DateTime.utc(2026, 6, 2));
    });

    test('returns null platform when key absent', () {
      final w = AvailabilityWindow.fromJson({
        'start': '2026-06-01T00:00:00.000Z',
        'end': '2026-06-02T00:00:00.000Z',
        'source': 'manual_block',
      });
      expect(w.platform, isNull);
    });
  });

  group('AvailabilityWindow constructor', () {
    test('preserves explicit fields', () {
      final w = AvailabilityWindow(
        start: DateTime.utc(2026, 1, 1),
        end: DateTime.utc(2026, 1, 2),
        source: AvailabilityWindowSource.icalExternal,
        platform: 'Booking.com',
      );
      expect(w.start, DateTime.utc(2026, 1, 1));
      expect(w.end, DateTime.utc(2026, 1, 2));
      expect(w.source, AvailabilityWindowSource.icalExternal);
      expect(w.platform, 'Booking.com');
    });
  });
}
