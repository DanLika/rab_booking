// ignore_for_file: avoid_redundant_argument_values
// Note: Explicit default values kept in tests for documentation clarity
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rab_booking/features/widget/data/repositories/firebase_daily_price_repository.dart';
import 'package:rab_booking/shared/models/daily_price_model.dart';

void main() {
  group('FirebaseDailyPriceRepository', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirebaseDailyPriceRepository repository;

    const testUnitId = 'unit123';

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      repository = FirebaseDailyPriceRepository(fakeFirestore);
    });

    group('constructor', () {
      test('initializes with Firestore instance', () {
        expect(repository, isNotNull);
      });
    });

    group('getPriceForDate', () {
      test('returns null when no price exists', () async {
        final price = await repository.getPriceForDate(
          unitId: testUnitId,
          date: DateTime(2024, 1, 15),
        );

        expect(price, isNull);
      });

      // NOTE: Getting exact price by date has timing issues with fake_cloud_firestore
      // Timestamp equality queries don't work reliably. Full tests work with real Firestore.
    });

    group('getPricesForDateRange', () {
      test('returns empty list when no prices exist', () async {
        final prices = await repository.getPricesForDateRange(
          unitId: testUnitId,
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 31),
        );

        expect(prices, isEmpty);
      });

      test('returns prices within range', () async {
        // Add some daily prices
        await fakeFirestore.collection('daily_prices').add({
          'unit_id': testUnitId,
          'date': Timestamp.fromDate(DateTime(2024, 1, 10)),
          'price': 100.0,
          'available': true,
          'created_at': Timestamp.now(),
        });
        await fakeFirestore.collection('daily_prices').add({
          'unit_id': testUnitId,
          'date': Timestamp.fromDate(DateTime(2024, 1, 15)),
          'price': 120.0,
          'available': true,
          'created_at': Timestamp.now(),
        });
        await fakeFirestore.collection('daily_prices').add({
          'unit_id': testUnitId,
          'date': Timestamp.fromDate(DateTime(2024, 1, 20)),
          'price': 150.0,
          'available': true,
          'created_at': Timestamp.now(),
        });

        final prices = await repository.getPricesForDateRange(
          unitId: testUnitId,
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 31),
        );

        expect(prices.length, 3);
        expect(prices.map((p) => p.price), containsAll([100.0, 120.0, 150.0]));
      });

      test('filters by unit_id', () async {
        await fakeFirestore.collection('daily_prices').add({
          'unit_id': testUnitId,
          'date': Timestamp.fromDate(DateTime(2024, 1, 15)),
          'price': 100.0,
          'available': true,
          'created_at': Timestamp.now(),
        });
        await fakeFirestore.collection('daily_prices').add({
          'unit_id': 'other_unit',
          'date': Timestamp.fromDate(DateTime(2024, 1, 15)),
          'price': 200.0,
          'available': true,
          'created_at': Timestamp.now(),
        });

        final prices = await repository.getPricesForDateRange(
          unitId: testUnitId,
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 31),
        );

        expect(prices.length, 1);
        expect(prices.first.price, 100.0);
      });
    });

    group('calculateBookingPrice', () {
      test('uses fallback price when no daily prices exist', () async {
        final price = await repository.calculateBookingPrice(
          unitId: testUnitId,
          checkIn: DateTime(2024, 1, 15),
          checkOut: DateTime(2024, 1, 18),
          fallbackPrice: 100.0,
        );

        // 3 nights at 100€ each
        expect(price, 300.0);
      });

      test('applies weekend price for weekend nights', () async {
        final price = await repository.calculateBookingPrice(
          unitId: testUnitId,
          checkIn: DateTime(2024, 1, 19), // Friday
          checkOut: DateTime(2024, 1, 22), // Monday
          fallbackPrice: 100.0,
          weekendBasePrice: 150.0,
          weekendDays: [6, 7], // Saturday, Sunday
        );

        // Fri(100) + Sat(150) + Sun(150) = 400
        expect(price, 400.0);
      });

      test('uses custom weekend days', () async {
        final price = await repository.calculateBookingPrice(
          unitId: testUnitId,
          checkIn: DateTime(2024, 1, 18), // Thursday
          checkOut: DateTime(2024, 1, 21), // Sunday
          fallbackPrice: 100.0,
          weekendBasePrice: 150.0,
          weekendDays: [5, 6], // Friday, Saturday
        );

        // Thu(100) + Fri(150) + Sat(150) = 400
        expect(price, 400.0);
      });
    });

    group('setPriceForDate', () {
      test('creates new price entry', () async {
        final result = await repository.setPriceForDate(
          unitId: testUnitId,
          date: DateTime(2024, 1, 15),
          price: 150.0,
        );

        expect(result.unitId, testUnitId);
        expect(result.price, 150.0);
        expect(result.id, isNotEmpty);

        // Verify in Firestore
        final snapshot = await fakeFirestore
            .collection('daily_prices')
            .where('unit_id', isEqualTo: testUnitId)
            .get();

        expect(snapshot.docs.length, 1);
        expect(snapshot.docs.first.data()['price'], 150.0);
      });

      test('creates price with full model', () async {
        final model = DailyPriceModel(
          id: '',
          unitId: testUnitId,
          date: DateTime(2024, 1, 15),
          price: 100.0,
          weekendPrice: 130.0,
          blockCheckIn: true,
          blockCheckOut: false,
          minNightsOnArrival: 2,
          maxNightsOnArrival: 7,
          notes: 'Holiday pricing',
          createdAt: DateTime.now(),
        );

        final result = await repository.setPriceForDate(
          unitId: testUnitId,
          date: DateTime(2024, 1, 15),
          price: 100.0,
          priceModel: model,
        );

        expect(result.price, 100.0);
        expect(result.weekendPrice, 130.0);
        expect(result.blockCheckIn, true);
        expect(result.minNightsOnArrival, 2);
        expect(result.notes, 'Holiday pricing');
      });
    });

    group('bulkUpdatePrices', () {
      test('creates prices for date range', () async {
        final results = await repository.bulkUpdatePrices(
          unitId: testUnitId,
          startDate: DateTime(2024, 1, 10),
          endDate: DateTime(2024, 1, 15),
          price: 120.0,
        );

        // Should create 6 days (10, 11, 12, 13, 14, 15)
        expect(results.length, 6);
        expect(results.every((p) => p.price == 120.0), true);

        // Verify in Firestore
        final snapshot = await fakeFirestore
            .collection('daily_prices')
            .where('unit_id', isEqualTo: testUnitId)
            .get();

        expect(snapshot.docs.length, 6);
      });
    });

    group('deletePriceForDate', () {
      test('deletes price for specific date', () async {
        // Create a price
        await repository.setPriceForDate(
          unitId: testUnitId,
          date: DateTime(2024, 1, 15),
          price: 100.0,
        );

        // Verify exists
        var snapshot = await fakeFirestore
            .collection('daily_prices')
            .where('unit_id', isEqualTo: testUnitId)
            .get();
        expect(snapshot.docs.length, 1);

        // Delete
        await repository.deletePriceForDate(
          unitId: testUnitId,
          date: DateTime(2024, 1, 15),
        );

        // Verify deleted
        snapshot = await fakeFirestore
            .collection('daily_prices')
            .where('unit_id', isEqualTo: testUnitId)
            .get();
        expect(snapshot.docs.length, 0);
      });
    });

    group('deletePricesForDateRange', () {
      test('deletes all prices in range', () async {
        // Create prices
        await repository.bulkUpdatePrices(
          unitId: testUnitId,
          startDate: DateTime(2024, 1, 10),
          endDate: DateTime(2024, 1, 20),
          price: 100.0,
        );

        // Verify exists (11 days)
        var snapshot = await fakeFirestore
            .collection('daily_prices')
            .where('unit_id', isEqualTo: testUnitId)
            .get();
        expect(snapshot.docs.length, 11);

        // Delete subset
        await repository.deletePricesForDateRange(
          unitId: testUnitId,
          startDate: DateTime(2024, 1, 12),
          endDate: DateTime(2024, 1, 18),
        );

        // Verify remaining (should be 4: 10, 11, 19, 20)
        snapshot = await fakeFirestore
            .collection('daily_prices')
            .where('unit_id', isEqualTo: testUnitId)
            .get();
        expect(snapshot.docs.length, 4);
      });
    });

    group('hasCustomPrice', () {
      test('returns false when no price exists', () async {
        final hasPrice = await repository.hasCustomPrice(
          unitId: testUnitId,
          date: DateTime(2024, 1, 15),
        );

        expect(hasPrice, false);
      });

      // NOTE: Exact date match has timing issues with fake_cloud_firestore
      // Timestamp equality queries don't work reliably.
    });

    group('fetchAllPricesForUnit', () {
      test('returns empty list when no prices exist', () async {
        final prices = await repository.fetchAllPricesForUnit(testUnitId);
        expect(prices, isEmpty);
      });

      test('returns all prices for unit', () async {
        await repository.bulkUpdatePrices(
          unitId: testUnitId,
          startDate: DateTime(2024, 1, 10),
          endDate: DateTime(2024, 1, 15),
          price: 100.0,
        );

        final prices = await repository.fetchAllPricesForUnit(testUnitId);
        expect(prices.length, 6);
      });
    });

    group('bulkPartialUpdate', () {
      test('returns empty list when no dates provided', () async {
        final results = await repository.bulkPartialUpdate(
          unitId: testUnitId,
          dates: [],
          partialData: {'available': false},
        );

        expect(results, isEmpty);
      });

      test('creates new entries with partial data', () async {
        final results = await repository.bulkPartialUpdate(
          unitId: testUnitId,
          dates: [DateTime(2024, 1, 15), DateTime(2024, 1, 16)],
          partialData: {
            'price': 100.0,
            'available': false,
            'block_checkin': true,
          },
        );

        expect(results.length, 2);
        expect(results.every((p) => p.available == false), true);
        expect(results.every((p) => p.blockCheckIn == true), true);
      });
    });

    group('watchPricesForDateRange', () {
      test('emits empty list when no prices exist', () async {
        final stream = repository.watchPricesForDateRange(
          unitId: testUnitId,
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 31),
        );

        final prices = await stream.first;
        expect(prices, isEmpty);
      });

      test('emits prices when they exist', () async {
        await fakeFirestore.collection('daily_prices').add({
          'unit_id': testUnitId,
          'date': Timestamp.fromDate(DateTime(2024, 1, 15)),
          'price': 100.0,
          'available': true,
          'created_at': Timestamp.now(),
        });

        final stream = repository.watchPricesForDateRange(
          unitId: testUnitId,
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 31),
        );

        final prices = await stream.first;
        expect(prices.length, 1);
        expect(prices.first.price, 100.0);
      });
    });
  });
}
