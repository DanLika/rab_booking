// ignore_for_file: avoid_redundant_argument_values, prefer_const_constructors
// Note: Explicit default values kept in tests for documentation clarity
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rab_booking/core/exceptions/app_exceptions.dart';
import 'package:rab_booking/features/widget/data/helpers/availability_checker.dart';
import 'package:rab_booking/features/widget/data/helpers/booking_price_calculator.dart';

void main() {
  group('PriceCalculationResult', () {
    group('constructor', () {
      test('creates result with all fields', () {
        final result = PriceCalculationResult(
          totalPrice: 500.0,
          nights: 5,
          priceBreakdown: {'2024-01-15': 100.0, '2024-01-16': 100.0},
          usedFallback: true,
          weekendNights: 2,
        );

        expect(result.totalPrice, 500.0);
        expect(result.nights, 5);
        expect(result.priceBreakdown.length, 2);
        expect(result.usedFallback, isTrue);
        expect(result.weekendNights, 2);
      });
    });

    group('zero factory', () {
      test('creates zero result', () {
        const result = PriceCalculationResult.zero();

        expect(result.totalPrice, 0.0);
        expect(result.nights, 0);
        expect(result.priceBreakdown, isEmpty);
        expect(result.usedFallback, isFalse);
        expect(result.weekendNights, 0);
      });
    });

    group('averagePrice', () {
      test('calculates correct average', () {
        final result = PriceCalculationResult(
          totalPrice: 500.0,
          nights: 5,
          priceBreakdown: const {},
          usedFallback: false,
          weekendNights: 0,
        );

        expect(result.averagePrice, 100.0);
      });

      test('returns 0 for zero nights', () {
        const result = PriceCalculationResult.zero();

        expect(result.averagePrice, 0.0);
      });

      test('handles uneven division', () {
        final result = PriceCalculationResult(
          totalPrice: 250.0,
          nights: 3,
          priceBreakdown: const {},
          usedFallback: false,
          weekendNights: 0,
        );

        expect(result.averagePrice, closeTo(83.33, 0.01));
      });
    });
  });

  group('BookingPriceCalculator', () {
    late FakeFirebaseFirestore fakeFirestore;
    late BookingPriceCalculator calculator;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      calculator = BookingPriceCalculator(
        firestore: fakeFirestore,
      );
    });

    group('calculate - base price only', () {
      test('calculates correct total with base price', () async {
        final result = await calculator.calculate(
          unitId: 'unit123',
          checkIn: DateTime(2024, 1, 15), // Monday
          checkOut: DateTime(2024, 1, 18), // Thursday (3 nights)
          basePrice: 100.0,
          checkAvailability: false,
        );

        expect(result.totalPrice, 300.0);
        expect(result.nights, 3);
        expect(result.usedFallback, isTrue);
        expect(result.priceBreakdown.length, 3);
      });

      test('returns zero for invalid date range', () async {
        final result = await calculator.calculate(
          unitId: 'unit123',
          checkIn: DateTime(2024, 1, 18),
          checkOut: DateTime(2024, 1, 15), // Before check-in
          basePrice: 100.0,
          checkAvailability: false,
        );

        expect(result.totalPrice, 0.0);
        expect(result.nights, 0);
      });

      test('returns zero for same day check-in/check-out', () async {
        final result = await calculator.calculate(
          unitId: 'unit123',
          checkIn: DateTime(2024, 1, 15),
          checkOut: DateTime(2024, 1, 15), // Same day
          basePrice: 100.0,
          checkAvailability: false,
        );

        expect(result.totalPrice, 0.0);
        expect(result.nights, 0);
      });
    });

    group('calculate - weekend pricing', () {
      test('applies weekend price for Saturday', () async {
        // Jan 20, 2024 is Saturday
        final result = await calculator.calculate(
          unitId: 'unit123',
          checkIn: DateTime(2024, 1, 20), // Saturday
          checkOut: DateTime(2024, 1, 21), // Sunday (1 night)
          basePrice: 100.0,
          weekendBasePrice: 150.0,
          checkAvailability: false,
        );

        expect(result.totalPrice, 150.0);
        expect(result.nights, 1);
        expect(result.weekendNights, 1);
      });

      test('applies weekend price for Sunday', () async {
        // Jan 21, 2024 is Sunday
        final result = await calculator.calculate(
          unitId: 'unit123',
          checkIn: DateTime(2024, 1, 21), // Sunday
          checkOut: DateTime(2024, 1, 22), // Monday (1 night)
          basePrice: 100.0,
          weekendBasePrice: 150.0,
          checkAvailability: false,
        );

        expect(result.totalPrice, 150.0);
        expect(result.nights, 1);
        expect(result.weekendNights, 1);
      });

      test('mixes weekend and weekday prices', () async {
        // Jan 19 = Friday, Jan 20 = Saturday, Jan 21 = Sunday
        final result = await calculator.calculate(
          unitId: 'unit123',
          checkIn: DateTime(2024, 1, 19), // Friday
          checkOut: DateTime(2024, 1, 22), // Monday (3 nights: Fri, Sat, Sun)
          basePrice: 100.0,
          weekendBasePrice: 150.0,
          checkAvailability: false,
        );

        // Friday = 100, Saturday = 150, Sunday = 150
        expect(result.totalPrice, 400.0);
        expect(result.nights, 3);
        expect(result.weekendNights, 2);
      });

      test('uses custom weekend days', () async {
        // Jan 19, 2024 is Friday (weekday 5)
        final result = await calculator.calculate(
          unitId: 'unit123',
          checkIn: DateTime(2024, 1, 19), // Friday
          checkOut: DateTime(2024, 1, 20), // Saturday (1 night on Friday)
          basePrice: 100.0,
          weekendBasePrice: 150.0,
          weekendDays: [5, 6], // Friday and Saturday as weekend
          checkAvailability: false,
        );

        expect(result.totalPrice, 150.0);
        expect(result.weekendNights, 1);
      });

      test('uses base price when weekendBasePrice is null', () async {
        final result = await calculator.calculate(
          unitId: 'unit123',
          checkIn: DateTime(2024, 1, 20), // Saturday
          checkOut: DateTime(2024, 1, 21), // Sunday (1 night)
          basePrice: 100.0,
          weekendBasePrice: null,
          checkAvailability: false,
        );

        expect(result.totalPrice, 100.0);
        expect(result.weekendNights, 0);
      });
    });

    // NOTE: Daily prices from Firestore tests are skipped because
    // fake_cloud_firestore doesn't properly handle Timestamp conversion
    // in inequality queries. These tests work correctly in integration tests
    // with real Firestore. The core calculator logic is tested via
    // base price and weekend price tests below.
    group('calculate - daily prices from Firestore', () {
      test('falls back to base price when no daily price for unit', () async {
        // This test doesn't use Timestamp queries - just verifies fallback
        final result = await calculator.calculate(
          unitId: 'unit123',
          checkIn: DateTime(2024, 1, 15),
          checkOut: DateTime(2024, 1, 16),
          basePrice: 100.0,
          checkAvailability: false,
        );

        expect(result.totalPrice, 100.0);
        expect(result.usedFallback, isTrue);
      });
    });

    group('calculate - availability check', () {
      test('throws DatesNotAvailableException when not available', () async {
        // Add conflicting booking
        await fakeFirestore.collection('bookings').add({
          'unit_id': 'unit123',
          'status': 'confirmed',
          'check_in': Timestamp.fromDate(DateTime(2024, 1, 15)),
          'check_out': Timestamp.fromDate(DateTime(2024, 1, 20)),
          'guest_name': 'Test Guest',
          'guest_email': 'test@test.com',
          'property_id': 'prop123',
          'total_price': 500.0,
          'nights': 5,
          'guests': 2,
          'created_at': Timestamp.now(),
        });

        final calculatorWithChecker = BookingPriceCalculator(
          firestore: fakeFirestore,
          availabilityChecker: AvailabilityChecker(fakeFirestore),
        );

        expect(
          () => calculatorWithChecker.calculate(
            unitId: 'unit123',
            checkIn: DateTime(2024, 1, 17),
            checkOut: DateTime(2024, 1, 22),
            basePrice: 100.0,
            checkAvailability: true,
          ),
          throwsA(isA<DatesNotAvailableException>()),
        );
      });

      test('calculates price when available', () async {
        final calculatorWithChecker = BookingPriceCalculator(
          firestore: fakeFirestore,
          availabilityChecker: AvailabilityChecker(fakeFirestore),
        );

        final result = await calculatorWithChecker.calculate(
          unitId: 'unit123',
          checkIn: DateTime(2024, 1, 15),
          checkOut: DateTime(2024, 1, 18),
          basePrice: 100.0,
          checkAvailability: true,
        );

        expect(result.totalPrice, 300.0);
        expect(result.nights, 3);
      });

      test('skips availability check when checkAvailability is false', () async {
        // Add conflicting booking
        await fakeFirestore.collection('bookings').add({
          'unit_id': 'unit123',
          'status': 'confirmed',
          'check_in': Timestamp.fromDate(DateTime(2024, 1, 15)),
          'check_out': Timestamp.fromDate(DateTime(2024, 1, 20)),
          'guest_name': 'Test Guest',
          'guest_email': 'test@test.com',
          'property_id': 'prop123',
          'total_price': 500.0,
          'nights': 5,
          'guests': 2,
          'created_at': Timestamp.now(),
        });

        final calculatorWithChecker = BookingPriceCalculator(
          firestore: fakeFirestore,
          availabilityChecker: AvailabilityChecker(fakeFirestore),
        );

        // Should NOT throw because availability check is disabled
        final result = await calculatorWithChecker.calculate(
          unitId: 'unit123',
          checkIn: DateTime(2024, 1, 17),
          checkOut: DateTime(2024, 1, 22),
          basePrice: 100.0,
          checkAvailability: false,
        );

        expect(result.totalPrice, 500.0);
        expect(result.nights, 5);
      });

      test('skips check when no availabilityChecker provided', () async {
        // Add conflicting booking
        await fakeFirestore.collection('bookings').add({
          'unit_id': 'unit123',
          'status': 'confirmed',
          'check_in': Timestamp.fromDate(DateTime(2024, 1, 15)),
          'check_out': Timestamp.fromDate(DateTime(2024, 1, 20)),
          'guest_name': 'Test Guest',
          'guest_email': 'test@test.com',
          'property_id': 'prop123',
          'total_price': 500.0,
          'nights': 5,
          'guests': 2,
          'created_at': Timestamp.now(),
        });

        // Calculator without availability checker
        final calcNoChecker = BookingPriceCalculator(
          firestore: fakeFirestore,
          // No availabilityChecker
        );

        // Should NOT throw even with checkAvailability: true
        final result = await calcNoChecker.calculate(
          unitId: 'unit123',
          checkIn: DateTime(2024, 1, 17),
          checkOut: DateTime(2024, 1, 22),
          basePrice: 100.0,
          checkAvailability: true,
        );

        expect(result.totalPrice, 500.0);
      });
    });

    group('calculateWithoutAvailabilityCheck', () {
      test('calculates price without checking availability', () async {
        // Add conflicting booking
        await fakeFirestore.collection('bookings').add({
          'unit_id': 'unit123',
          'status': 'confirmed',
          'check_in': Timestamp.fromDate(DateTime(2024, 1, 15)),
          'check_out': Timestamp.fromDate(DateTime(2024, 1, 20)),
          'guest_name': 'Test Guest',
          'guest_email': 'test@test.com',
          'property_id': 'prop123',
          'total_price': 500.0,
          'nights': 5,
          'guests': 2,
          'created_at': Timestamp.now(),
        });

        final calculatorWithChecker = BookingPriceCalculator(
          firestore: fakeFirestore,
          availabilityChecker: AvailabilityChecker(fakeFirestore),
        );

        final result = await calculatorWithChecker.calculateWithoutAvailabilityCheck(
          unitId: 'unit123',
          checkIn: DateTime(2024, 1, 17),
          checkOut: DateTime(2024, 1, 22),
          basePrice: 100.0,
        );

        expect(result.totalPrice, 500.0);
        expect(result.nights, 5);
      });
    });

    // NOTE: Daily price from Firestore tests are simplified because
    // fake_cloud_firestore doesn't properly handle Timestamp conversion
    // in equality queries. Full tests work in integration tests with real Firestore.
    group('getEffectivePriceForDate', () {
      test('returns base price when no daily price exists', () async {
        // When no daily_price document exists, falls back to base price
        final price = await calculator.getEffectivePriceForDate(
          unitId: 'unit123',
          date: DateTime(2024, 1, 15),
          basePrice: 100.0,
        );

        expect(price, 100.0);
      });

      test('returns weekend price for weekend without daily price', () async {
        final price = await calculator.getEffectivePriceForDate(
          unitId: 'unit123',
          date: DateTime(2024, 1, 20), // Saturday
          basePrice: 100.0,
          weekendBasePrice: 150.0,
        );

        expect(price, 150.0);
      });

      test('returns base price for weekday without daily price', () async {
        final price = await calculator.getEffectivePriceForDate(
          unitId: 'unit123',
          date: DateTime(2024, 1, 15), // Monday
          basePrice: 100.0,
          weekendBasePrice: 150.0,
        );

        expect(price, 100.0);
      });

      test('returns base price when weekendBasePrice is null', () async {
        final price = await calculator.getEffectivePriceForDate(
          unitId: 'unit123',
          date: DateTime(2024, 1, 20), // Saturday
          basePrice: 100.0,
          weekendBasePrice: null,
        );

        expect(price, 100.0);
      });

      test('uses custom weekend days', () async {
        final price = await calculator.getEffectivePriceForDate(
          unitId: 'unit123',
          date: DateTime(2024, 1, 19), // Friday
          basePrice: 100.0,
          weekendBasePrice: 150.0,
          weekendDays: [5, 6], // Friday and Saturday
        );

        expect(price, 150.0);
      });
    });

    group('price breakdown', () {
      test('generates correct date keys in breakdown', () async {
        final result = await calculator.calculate(
          unitId: 'unit123',
          checkIn: DateTime(2024, 1, 15),
          checkOut: DateTime(2024, 1, 18),
          basePrice: 100.0,
          checkAvailability: false,
        );

        // Date key format: 2024-1-15 (not zero-padded)
        expect(result.priceBreakdown.containsKey('2024-1-15'), isTrue);
        expect(result.priceBreakdown.containsKey('2024-1-16'), isTrue);
        expect(result.priceBreakdown.containsKey('2024-1-17'), isTrue);
        expect(result.priceBreakdown.containsKey('2024-1-18'), isFalse);
      });

      test('checkout date is not included in breakdown', () async {
        final result = await calculator.calculate(
          unitId: 'unit123',
          checkIn: DateTime(2024, 1, 15),
          checkOut: DateTime(2024, 1, 17),
          basePrice: 100.0,
          checkAvailability: false,
        );

        expect(result.nights, 2);
        // Date key format: 2024-1-15 (not zero-padded)
        expect(result.priceBreakdown.containsKey('2024-1-15'), isTrue);
        expect(result.priceBreakdown.containsKey('2024-1-16'), isTrue);
        // Checkout date should NOT be in breakdown
        expect(result.priceBreakdown.containsKey('2024-1-17'), isFalse);
      });
    });

    group('date normalization', () {
      test('normalizes dates with time components', () async {
        final result = await calculator.calculate(
          unitId: 'unit123',
          checkIn: DateTime(2024, 1, 15, 14, 30, 0), // With time
          checkOut: DateTime(2024, 1, 17, 10, 0, 0), // With time
          basePrice: 100.0,
          checkAvailability: false,
        );

        expect(result.nights, 2);
        expect(result.totalPrice, 200.0);
      });
    });
  });
}
