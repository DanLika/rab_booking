import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../shared/models/daily_price_model.dart';
import '../../../../shared/repositories/daily_price_repository.dart';

/// Firebase implementation of daily price repository
class FirebaseDailyPriceRepository implements DailyPriceRepository {
  final FirebaseFirestore _firestore;

  FirebaseDailyPriceRepository(this._firestore);

  @override
  Future<double?> getPriceForDate({
    required String unitId,
    required DateTime date,
  }) async {
    try {
      final dateOnly = DateTime(date.year, date.month, date.day);
      final snapshot = await _firestore
          .collection('daily_prices')
          .where('unit_id', isEqualTo: unitId)
          .where('date', isEqualTo: Timestamp.fromDate(dateOnly))
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final priceData = snapshot.docs.first.data();
      return (priceData['price'] as num?)?.toDouble();
    } catch (e) {
      print('Error getting price for date: $e');
      return null;
    }
  }

  @override
  Future<List<DailyPriceModel>> getPricesForDateRange({
    required String unitId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final startDateOnly = DateTime(startDate.year, startDate.month, startDate.day);
      final endDateOnly = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

      final snapshot = await _firestore
          .collection('daily_prices')
          .where('unit_id', isEqualTo: unitId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDateOnly))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDateOnly))
          .get();

      return snapshot.docs
          .map((doc) {
            try {
              return DailyPriceModel.fromJson({...doc.data(), 'id': doc.id});
            } catch (e) {
              print('Error parsing daily price: $e');
              return null;
            }
          })
          .whereType<DailyPriceModel>()
          .toList();
    } catch (e) {
      print('Error getting prices for date range: $e');
      return [];
    }
  }

  @override
  Future<double> calculateBookingPrice({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
    double? fallbackPrice,
  }) async {
    try {
      final prices = await getPricesForDateRange(
        unitId: unitId,
        startDate: checkIn,
        endDate: checkOut,
      );

      if (prices.isEmpty && fallbackPrice != null) {
        // Use fallback price for each night
        final nights = checkOut.difference(checkIn).inDays;
        return fallbackPrice * nights;
      }

      // Sum up all daily prices
      double total = 0.0;
      DateTime current = checkIn;

      while (current.isBefore(checkOut)) {
        final price = prices.firstWhere(
          (p) => p.date.year == current.year &&
                 p.date.month == current.month &&
                 p.date.day == current.day,
          orElse: () => DailyPriceModel(
            id: '',
            unitId: unitId,
            date: current,
            price: fallbackPrice ?? 0.0,
            createdAt: DateTime.now(),
          ),
        );

        total += price.price;
        current = current.add(const Duration(days: 1));
      }

      return total;
    } catch (e) {
      print('Error calculating booking price: $e');
      return 0.0;
    }
  }

  @override
  Future<DailyPriceModel> setPriceForDate({
    required String unitId,
    required DateTime date,
    required double price,
  }) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final now = DateTime.now();

    final data = {
      'unit_id': unitId,
      'date': Timestamp.fromDate(dateOnly),
      'price': price,
      'created_at': Timestamp.fromDate(now),
    };

    final docRef = await _firestore.collection('daily_prices').add(data);

    return DailyPriceModel(
      id: docRef.id,
      unitId: unitId,
      date: dateOnly,
      price: price,
      createdAt: now,
    );
  }

  @override
  Future<List<DailyPriceModel>> bulkUpdatePrices({
    required String unitId,
    required DateTime startDate,
    required DateTime endDate,
    required double price,
  }) async {
    final List<DailyPriceModel> createdPrices = [];
    DateTime current = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    final batch = _firestore.batch();
    int operationCount = 0;
    const maxBatchSize = 500; // Firestore limit

    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      final docRef = _firestore.collection('daily_prices').doc();
      final data = {
        'unit_id': unitId,
        'date': Timestamp.fromDate(current),
        'price': price,
        'created_at': Timestamp.now(),
      };

      batch.set(docRef, data);
      operationCount++;

      createdPrices.add(DailyPriceModel(
        id: docRef.id,
        unitId: unitId,
        date: current,
        price: price,
        createdAt: DateTime.now(),
      ));

      if (operationCount >= maxBatchSize) {
        await batch.commit();
        operationCount = 0;
      }

      current = current.add(const Duration(days: 1));
    }

    if (operationCount > 0) {
      await batch.commit();
    }

    return createdPrices;
  }

  @override
  Future<void> deletePriceForDate({
    required String unitId,
    required DateTime date,
  }) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final snapshot = await _firestore
        .collection('daily_prices')
        .where('unit_id', isEqualTo: unitId)
        .where('date', isEqualTo: Timestamp.fromDate(dateOnly))
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  @override
  Future<void> deletePricesForDateRange({
    required String unitId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final startDateOnly = DateTime(startDate.year, startDate.month, startDate.day);
    final endDateOnly = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    final snapshot = await _firestore
        .collection('daily_prices')
        .where('unit_id', isEqualTo: unitId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDateOnly))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDateOnly))
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  @override
  Future<List<DailyPriceModel>> fetchAllPricesForUnit(String unitId) async {
    try {
      final snapshot = await _firestore
          .collection('daily_prices')
          .where('unit_id', isEqualTo: unitId)
          .orderBy('date', descending: false)
          .get();

      return snapshot.docs
          .map((doc) {
            try {
              return DailyPriceModel.fromJson({...doc.data(), 'id': doc.id});
            } catch (e) {
              print('Error parsing daily price: $e');
              return null;
            }
          })
          .whereType<DailyPriceModel>()
          .toList();
    } catch (e) {
      print('Error fetching all prices for unit: $e');
      return [];
    }
  }

  @override
  Future<bool> hasCustomPrice({
    required String unitId,
    required DateTime date,
  }) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final snapshot = await _firestore
        .collection('daily_prices')
        .where('unit_id', isEqualTo: unitId)
        .where('date', isEqualTo: Timestamp.fromDate(dateOnly))
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  /// Stream prices for date range (for realtime updates)
  Stream<List<DailyPriceModel>> watchPricesForDateRange({
    required String unitId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final startDateOnly = DateTime(startDate.year, startDate.month, startDate.day);
    final endDateOnly = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    return _firestore
        .collection('daily_prices')
        .where('unit_id', isEqualTo: unitId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDateOnly))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDateOnly))
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            try {
              return DailyPriceModel.fromJson({...doc.data(), 'id': doc.id});
            } catch (e) {
              print('Error parsing daily price: $e');
              return null;
            }
          })
          .whereType<DailyPriceModel>()
          .toList();
    });
  }
}
