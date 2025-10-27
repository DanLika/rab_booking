import 'package:cloud_firestore/cloud_firestore.dart';
import '../daily_price_repository.dart';
import '../../models/daily_price_model.dart';

class FirebaseDailyPriceRepository implements DailyPriceRepository {
  final FirebaseFirestore _firestore;

  FirebaseDailyPriceRepository(this._firestore);

  @override
  Future<double?> getPriceForDate({
    required String unitId,
    required DateTime date,
  }) async {
    final dateKey = _getDateKey(date);
    final snapshot = await _firestore
        .collection('daily_prices')
        .where('unit_id', isEqualTo: unitId)
        .where('date', isEqualTo: Timestamp.fromDate(DateTime(date.year, date.month, date.day)))
        .get();

    if (snapshot.docs.isEmpty) return null;
    final price = DailyPriceModel.fromJson({...snapshot.docs.first.data(), 'id': snapshot.docs.first.id});
    return price.price;
  }

  @override
  Future<List<DailyPriceModel>> getPricesForDateRange({
    required String unitId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final snapshot = await _firestore
        .collection('daily_prices')
        .where('unit_id', isEqualTo: unitId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();
    return snapshot.docs
        .map((doc) => DailyPriceModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  @override
  Future<double> calculateBookingPrice({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
    double? fallbackPrice,
  }) async {
    final prices = await getPricesForDateRange(
      unitId: unitId,
      startDate: checkIn,
      endDate: checkOut,
    );

    double total = 0;
    DateTime current = checkIn;

    while (current.isBefore(checkOut)) {
      final priceForDate = prices.firstWhere(
        (p) => _isSameDay(p.date, current),
        orElse: () => DailyPriceModel(
          id: '',
          unitId: unitId,
          date: current,
          price: fallbackPrice ?? 0,
          createdAt: DateTime.now(),
        ),
      );
      total += priceForDate.price;
      current = current.add(const Duration(days: 1));
    }

    return total;
  }

  @override
  Future<DailyPriceModel> setPriceForDate({
    required String unitId,
    required DateTime date,
    required double price,
    DailyPriceModel? priceModel,
  }) async {
    // If priceModel is provided, use it; otherwise create basic one
    final modelToSave = priceModel ?? DailyPriceModel(
      id: '',
      unitId: unitId,
      date: DateTime(date.year, date.month, date.day),
      price: price,
      createdAt: DateTime.now(),
    );

    // Check if price already exists for this date
    final existingSnapshot = await _firestore
        .collection('daily_prices')
        .where('unit_id', isEqualTo: unitId)
        .where('date', isEqualTo: Timestamp.fromDate(DateTime(date.year, date.month, date.day)))
        .get();

    if (existingSnapshot.docs.isNotEmpty) {
      // Update existing document
      final docId = existingSnapshot.docs.first.id;
      final updateData = modelToSave.copyWith(
        id: docId,
        updatedAt: DateTime.now(),
      ).toJson();

      await _firestore.collection('daily_prices').doc(docId).update(updateData);
      return modelToSave.copyWith(id: docId, updatedAt: DateTime.now());
    } else {
      // Create new document
      final createData = modelToSave.copyWith(
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final docRef = await _firestore.collection('daily_prices').add(createData.toJson());
      return createData.copyWith(id: docRef.id);
    }
  }

  @override
  Future<List<DailyPriceModel>> bulkUpdatePrices({
    required String unitId,
    required DateTime startDate,
    required DateTime endDate,
    required double price,
  }) async {
    final List<DailyPriceModel> created = [];
    DateTime current = startDate;

    while (current.isBefore(endDate.add(const Duration(days: 1)))) {
      final priceModel = await setPriceForDate(
        unitId: unitId,
        date: current,
        price: price,
      );
      created.add(priceModel);
      current = current.add(const Duration(days: 1));
    }

    return created;
  }

  @override
  Future<void> deletePriceForDate({
    required String unitId,
    required DateTime date,
  }) async {
    final snapshot = await _firestore
        .collection('daily_prices')
        .where('unit_id', isEqualTo: unitId)
        .where('date', isEqualTo: Timestamp.fromDate(DateTime(date.year, date.month, date.day)))
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  @override
  Future<void> deletePricesForDateRange({
    required String unitId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final snapshot = await _firestore
        .collection('daily_prices')
        .where('unit_id', isEqualTo: unitId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  @override
  Future<List<DailyPriceModel>> fetchAllPricesForUnit(String unitId) async {
    final snapshot = await _firestore
        .collection('daily_prices')
        .where('unit_id', isEqualTo: unitId)
        .get();

    return snapshot.docs
        .map((doc) => DailyPriceModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  @override
  Future<bool> hasCustomPrice({
    required String unitId,
    required DateTime date,
  }) async {
    final price = await getPriceForDate(unitId: unitId, date: date);
    return price != null;
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
