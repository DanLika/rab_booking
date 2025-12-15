import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../shared/models/daily_price_model.dart';
import '../../../../shared/repositories/daily_price_repository.dart';
import '../../../../core/services/logging_service.dart';

/// Firebase implementation of daily price repository
class FirebaseDailyPriceRepository implements DailyPriceRepository {
  final FirebaseFirestore _firestore;

  /// Firestore collection name for daily prices
  static const String _collectionName = 'daily_prices';

  /// Maximum operations per Firestore batch
  static const int _maxBatchSize = 500;

  FirebaseDailyPriceRepository(this._firestore);

  /// Normalize DateTime to midnight (strips time component)
  DateTime _normalizeDate(DateTime date) => DateTime.utc(date.year, date.month, date.day);

  /// Normalize DateTime to end of day (23:59:59)
  DateTime _normalizeEndOfDay(DateTime date) => DateTime.utc(date.year, date.month, date.day, 23, 59, 59);

  /// Validate and check if document data has required fields
  bool _isValidPriceDocument(Map<String, dynamic> data) =>
      data['date'] != null && data['date'] is Timestamp && data['unit_id'] != null;

  /// Parse Firestore document to DailyPriceModel (returns null on error)
  DailyPriceModel? _parseDocument(QueryDocumentSnapshot doc) {
    try {
      return DailyPriceModel.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id});
    } catch (e) {
      LoggingService.logError('Error parsing daily price', e);
      return null;
    }
  }

  /// Parse list of documents, filtering invalid ones
  List<DailyPriceModel> _parseDocuments(List<QueryDocumentSnapshot> docs) {
    return docs
        .where((doc) => _isValidPriceDocument(doc.data() as Map<String, dynamic>))
        .map(_parseDocument)
        .whereType<DailyPriceModel>()
        .toList();
  }

  /// Format date as document ID (YYYY-MM-DD)
  String _formatDateAsId(DateTime date) {
    final normalized = _normalizeDate(date);
    return '${normalized.year}-${normalized.month.toString().padLeft(2, '0')}-${normalized.day.toString().padLeft(2, '0')}';
  }

  /// Find unit document to get propertyId
  /// Returns null if unit not found
  Future<DocumentSnapshot?> _findUnitDocument(String unitId) async {
    try {
      // Use collection group query to find unit across all properties
      final snapshot = await _firestore.collectionGroup('units').where(FieldPath.documentId, isEqualTo: unitId).limit(1).get();

      if (snapshot.docs.isEmpty) return null;
      return snapshot.docs.first;
    } catch (e) {
      unawaited(LoggingService.logError('Error finding unit document', e));
      return null;
    }
  }

  @override
  Future<double?> getPriceForDate({required String unitId, required DateTime date}) async {
    try {
      // NEW STRUCTURE: Need propertyId to build path
      // First, find unit to get propertyId
      final unitDoc = await _findUnitDocument(unitId);
      if (unitDoc == null) return null;

      final propertyId = unitDoc.reference.parent.parent!.id;
      final dateOnly = _normalizeDate(date);
      final dateStr = _formatDateAsId(dateOnly);

      // Direct document fetch using date as ID (faster than query)
      final docRef = _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('units')
          .doc(unitId)
          .collection(_collectionName)
          .doc(dateStr);

      final doc = await docRef.get();
      if (!doc.exists) return null;

      final priceData = doc.data();
      return (priceData?['price'] as num?)?.toDouble();
    } catch (e) {
      unawaited(LoggingService.logError('Error getting price for date', e));
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
      // NEW STRUCTURE: Need propertyId to build path
      final unitDoc = await _findUnitDocument(unitId);
      if (unitDoc == null) return [];

      final propertyId = unitDoc.reference.parent.parent!.id;
      final startDateOnly = _normalizeDate(startDate);
      final endDateOnly = _normalizeEndOfDay(endDate);

      final snapshot = await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('units')
          .doc(unitId)
          .collection(_collectionName)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDateOnly))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDateOnly))
          .get();

      return _parseDocuments(snapshot.docs);
    } catch (e) {
      unawaited(LoggingService.logError('Error getting prices for date range', e));
      return [];
    }
  }

  @override
  Future<double> calculateBookingPrice({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
    double? fallbackPrice,
    double? weekendBasePrice,
    List<int>? weekendDays,
  }) async {
    try {
      final prices = await getPricesForDateRange(unitId: unitId, startDate: checkIn, endDate: checkOut);

      final effectiveWeekendDays = weekendDays ?? [6, 7]; // Default: Sat=6, Sun=7

      // Normalize dates to ensure consistency with getPricesForDateRange and other methods
      final normalizedCheckIn = _normalizeDate(checkIn);
      final normalizedCheckOut = _normalizeDate(checkOut);

      if (prices.isEmpty && fallbackPrice != null) {
        // Use fallback price for each night with weekend pricing support
        double total = 0.0;
        DateTime current = normalizedCheckIn;
        while (current.isBefore(normalizedCheckOut)) {
          if (weekendBasePrice != null && effectiveWeekendDays.contains(current.weekday)) {
            total += weekendBasePrice;
          } else {
            total += fallbackPrice;
          }
          current = current.add(const Duration(days: 1));
        }
        return total;
      }

      // Sum up all daily prices
      double total = 0.0;
      DateTime current = normalizedCheckIn;

      while (current.isBefore(normalizedCheckOut)) {
        final price = prices.firstWhere(
          (p) => p.date.year == current.year && p.date.month == current.month && p.date.day == current.day,
          orElse: () {
            // Create fallback with weekendBasePrice from unit if applicable
            final isWeekend = effectiveWeekendDays.contains(current.weekday);
            final effectivePrice = (isWeekend && weekendBasePrice != null) ? weekendBasePrice : (fallbackPrice ?? 0.0);
            return DailyPriceModel(
              id: '',
              unitId: unitId,
              date: current,
              price: effectivePrice,
              createdAt: DateTime.now().toUtc(),
            );
          },
        );

        // Use getEffectivePrice() which returns weekendPrice on configured weekend days
        // Note: For fallback models, the price is already set correctly above
        total += price.getEffectivePrice(weekendDays: weekendDays);
        current = current.add(const Duration(days: 1));
      }

      return total;
    } catch (e) {
      unawaited(LoggingService.logError('Error calculating booking price', e));
      return 0.0;
    }
  }

  @override
  Future<DailyPriceModel> setPriceForDate({
    required String unitId,
    required DateTime date,
    required double price,
    DailyPriceModel? priceModel,
  }) async {
    // NEW STRUCTURE: Need propertyId to build path
    final unitDoc = await _findUnitDocument(unitId);
    if (unitDoc == null) {
      throw Exception('Unit not found: $unitId');
    }

    final propertyId = unitDoc.reference.parent.parent!.id;
    final dateOnly = _normalizeDate(date);
    final dateStr = _formatDateAsId(dateOnly);
    final now = DateTime.now().toUtc();

    // Document reference using date as ID
    final docRef = _firestore
        .collection('properties')
        .doc(propertyId)
        .collection('units')
        .doc(unitId)
        .collection(_collectionName)
        .doc(dateStr);

    // Check if document exists
    final existingDoc = await docRef.get();

    // If priceModel is provided, use all its fields
    if (priceModel != null) {
      final data = priceModel.copyWith(unitId: unitId, date: dateOnly, updatedAt: now).toJson();

      // Remove ID from JSON before saving (ID is in the path)
      data.remove('id');
      data.remove('unit_id'); // unitId is in the path

      if (existingDoc.exists) {
        // UPDATE existing document
        await docRef.update(data);
        return priceModel.copyWith(id: dateStr, unitId: unitId, date: dateOnly, updatedAt: now);
      } else {
        // CREATE new document
        data['created_at'] = Timestamp.fromDate(now);
        await docRef.set(data);
        return priceModel.copyWith(id: dateStr, unitId: unitId, date: dateOnly, updatedAt: now);
      }
    }

    // Otherwise, create/update basic price entry
    final data = {
      'date': Timestamp.fromDate(dateOnly),
      'price': price,
      'available': true, // Default to available
      'updated_at': Timestamp.fromDate(now),
    };

    if (existingDoc.exists) {
      // UPDATE existing document
      await docRef.update(data);
      return DailyPriceModel(id: dateStr, unitId: unitId, date: dateOnly, price: price, createdAt: now);
    } else {
      // CREATE new document
      data['created_at'] = Timestamp.fromDate(now);
      await docRef.set(data);
      return DailyPriceModel(id: dateStr, unitId: unitId, date: dateOnly, price: price, createdAt: now);
    }
  }

  @override
  Future<List<DailyPriceModel>> bulkUpdatePrices({
    required String unitId,
    required DateTime startDate,
    required DateTime endDate,
    required double price,
  }) async {
    // NEW STRUCTURE: Need propertyId to build path
    final unitDoc = await _findUnitDocument(unitId);
    if (unitDoc == null) {
      throw Exception('Unit not found: $unitId');
    }

    final propertyId = unitDoc.reference.parent.parent!.id;
    final List<DailyPriceModel> createdPrices = [];
    DateTime current = _normalizeDate(startDate);
    final end = _normalizeDate(endDate);

    WriteBatch batch = _firestore.batch();
    int operationCount = 0;

    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      final dateStr = _formatDateAsId(current);
      final docRef = _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('units')
          .doc(unitId)
          .collection(_collectionName)
          .doc(dateStr);

      final data = {
        'date': Timestamp.fromDate(current),
        'price': price,
        'created_at': Timestamp.now(),
      };

      batch.set(docRef, data);
      operationCount++;

      createdPrices.add(
        DailyPriceModel(id: dateStr, unitId: unitId, date: current, price: price, createdAt: DateTime.now().toUtc()),
      );

      if (operationCount >= _maxBatchSize) {
        await batch.commit();
        batch = _firestore.batch();
        operationCount = 0;
      }

      current = current.add(const Duration(days: 1));
    }

    if (operationCount > 0) {
      await batch.commit();
    }

    return createdPrices;
  }

  /// Bulk update prices with full DailyPriceModel support
  /// Supports all fields including availability, restrictions, etc.
  @override
  Future<List<DailyPriceModel>> bulkUpdatePricesWithModel({
    required String unitId,
    required List<DateTime> dates,
    required DailyPriceModel modelTemplate,
  }) async {
    // NEW STRUCTURE: Need propertyId to build path
    final unitDoc = await _findUnitDocument(unitId);
    if (unitDoc == null) {
      throw Exception('Unit not found: $unitId');
    }

    final propertyId = unitDoc.reference.parent.parent!.id;
    final List<DailyPriceModel> createdPrices = [];
    WriteBatch batch = _firestore.batch();
    int operationCount = 0;

    for (final date in dates) {
      final dateOnly = _normalizeDate(date);
      final dateStr = _formatDateAsId(dateOnly);
      final docRef = _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('units')
          .doc(unitId)
          .collection(_collectionName)
          .doc(dateStr);

      // Create model for this specific date
      final model = modelTemplate.copyWith(
        id: dateStr,
        unitId: unitId,
        date: dateOnly,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );

      // Convert to JSON and remove ID and unit_id (they're in the path)
      final data = model.toJson();
      data.remove('id');
      data.remove('unit_id');

      batch.set(docRef, data);
      operationCount++;

      createdPrices.add(model);

      // Commit batch if reaching limit
      if (operationCount >= _maxBatchSize) {
        await batch.commit();
        batch = _firestore.batch();
        operationCount = 0;
      }
    }

    // Commit remaining operations
    if (operationCount > 0) {
      await batch.commit();
    }

    return createdPrices;
  }

  /// Bulk PARTIAL update - merges fields without overwriting existing data
  /// This method preserves existing custom prices, notes, and other fields
  /// Only updates the specific fields provided in partialData
  @override
  Future<List<DailyPriceModel>> bulkPartialUpdate({
    required String unitId,
    required List<DateTime> dates,
    required Map<String, dynamic> partialData,
  }) async {
    // Early return if no dates provided
    if (dates.isEmpty) {
      return [];
    }

    // NEW STRUCTURE: Need propertyId to build path
    final unitDoc = await _findUnitDocument(unitId);
    if (unitDoc == null) {
      throw Exception('Unit not found: $unitId');
    }

    final propertyId = unitDoc.reference.parent.parent!.id;
    final List<DailyPriceModel> updatedPrices = [];

    // Normalize all dates to midnight (date-only)
    final normalizedDates = dates.map(_normalizeDate).toSet().toList();

    // Add timestamp to partial data
    final dataToUpdate = {...partialData, 'updated_at': Timestamp.now()};

    // Process in batches (Firestore limit is 500 operations per batch)
    int batchCount = 0;
    WriteBatch batch = _firestore.batch();

    for (final date in normalizedDates) {
      final dateStr = _formatDateAsId(date);
      final docRef = _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('units')
          .doc(unitId)
          .collection(_collectionName)
          .doc(dateStr);

      // Check if document exists
      final existingDoc = await docRef.get();

      if (existingDoc.exists) {
        // Document exists - UPDATE with partial data
        batch.update(docRef, dataToUpdate);

        // Merge existing data with updates for return value
        final existingData = existingDoc.data() as Map<String, dynamic>;
        final mergedData = {...existingData, ...dataToUpdate, 'id': dateStr, 'unit_id': unitId};

        try {
          updatedPrices.add(DailyPriceModel.fromJson(mergedData));
        } catch (e) {
          unawaited(LoggingService.logError('Error parsing updated price', e));
        }
      } else {
        // Document doesn't exist - CREATE with defaults + partial data
        final fullData = {
          'date': Timestamp.fromDate(date),
          'price': partialData['price'] ?? 0.0,
          'available': partialData['available'] ?? true,
          'created_at': Timestamp.now(),
          ...dataToUpdate,
        };

        batch.set(docRef, fullData);

        try {
          updatedPrices.add(DailyPriceModel.fromJson({...fullData, 'id': dateStr, 'unit_id': unitId}));
        } catch (e) {
          unawaited(LoggingService.logError('Error creating price', e));
        }
      }

      batchCount++;

      // Commit batch when reaching max size
      if (batchCount >= _maxBatchSize) {
        await batch.commit();
        batch = _firestore.batch();
        batchCount = 0;
      }
    }

    // Commit remaining operations
    if (batchCount > 0) {
      await batch.commit();
    }

    LoggingService.logSuccess('Bulk partial update completed: ${normalizedDates.length} dates for unit $unitId');

    return updatedPrices;
  }

  @override
  Future<void> deletePriceForDate({required String unitId, required DateTime date}) async {
    // NEW STRUCTURE: Need propertyId to build path
    final unitDoc = await _findUnitDocument(unitId);
    if (unitDoc == null) return;

    final propertyId = unitDoc.reference.parent.parent!.id;
    final dateOnly = _normalizeDate(date);
    final dateStr = _formatDateAsId(dateOnly);

    await _firestore
        .collection('properties')
        .doc(propertyId)
        .collection('units')
        .doc(unitId)
        .collection(_collectionName)
        .doc(dateStr)
        .delete();
  }

  @override
  Future<void> deletePricesForDateRange({
    required String unitId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // NEW STRUCTURE: Need propertyId to build path
    final unitDoc = await _findUnitDocument(unitId);
    if (unitDoc == null) return;

    final propertyId = unitDoc.reference.parent.parent!.id;
    final startDateOnly = _normalizeDate(startDate);
    final endDateOnly = _normalizeEndOfDay(endDate);

    final snapshot = await _firestore
        .collection('properties')
        .doc(propertyId)
        .collection('units')
        .doc(unitId)
        .collection(_collectionName)
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
      // NEW STRUCTURE: Need propertyId to build path
      final unitDoc = await _findUnitDocument(unitId);
      if (unitDoc == null) return [];

      final propertyId = unitDoc.reference.parent.parent!.id;

      final snapshot = await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('units')
          .doc(unitId)
          .collection(_collectionName)
          .orderBy('date', descending: false)
          .get();

      return _parseDocuments(snapshot.docs);
    } catch (e) {
      unawaited(LoggingService.logError('Error fetching all prices for unit', e));
      return [];
    }
  }

  @override
  Future<bool> hasCustomPrice({required String unitId, required DateTime date}) async {
    // NEW STRUCTURE: Need propertyId to build path
    final unitDoc = await _findUnitDocument(unitId);
    if (unitDoc == null) return false;

    final propertyId = unitDoc.reference.parent.parent!.id;
    final dateOnly = _normalizeDate(date);
    final dateStr = _formatDateAsId(dateOnly);

    final doc = await _firestore
        .collection('properties')
        .doc(propertyId)
        .collection('units')
        .doc(unitId)
        .collection(_collectionName)
        .doc(dateStr)
        .get();

    return doc.exists;
  }

  /// Stream prices for date range (for realtime updates)
  Stream<List<DailyPriceModel>> watchPricesForDateRange({
    required String unitId,
    required DateTime startDate,
    required DateTime endDate,
  }) async* {
    // NEW STRUCTURE: Need propertyId to build path
    final unitDoc = await _findUnitDocument(unitId);
    if (unitDoc == null) {
      yield [];
      return;
    }

    final propertyId = unitDoc.reference.parent.parent!.id;
    final startDateOnly = _normalizeDate(startDate);
    final endDateOnly = _normalizeEndOfDay(endDate);

    yield* _firestore
        .collection('properties')
        .doc(propertyId)
        .collection('units')
        .doc(unitId)
        .collection(_collectionName)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDateOnly))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDateOnly))
        .snapshots()
        .map((snapshot) => _parseDocuments(snapshot.docs));
  }
}
