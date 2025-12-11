import 'package:cloud_firestore/cloud_firestore.dart';

/// Shared Firestore utilities for owner dashboard repositories.
/// Eliminates code duplication across analytics, performance, and revenue repos.
mixin FirestoreRepositoryMixin {
  /// Firestore batch limit for whereIn queries
  static const int batchLimit = 10;

  /// Firestore batch limit for count queries (higher limit allowed)
  static const int countBatchLimit = 30;

  /// Booking statuses used for revenue/analytics calculations
  static const List<String> confirmedStatuses = ['confirmed', 'completed'];
  static const List<String> activeStatuses = [
    'pending',
    'confirmed',
    'completed',
  ];

  /// Get all unit IDs for given properties from subcollections.
  /// Used by analytics, performance, and revenue repositories.
  Future<List<String>> getUnitIdsForProperties(
    FirebaseFirestore firestore,
    List<String> propertyIds,
  ) async {
    final List<String> unitIds = [];
    for (final propertyId in propertyIds) {
      final unitsSnapshot = await firestore
          .collection('properties')
          .doc(propertyId)
          .collection('units')
          .get();
      unitIds.addAll(unitsSnapshot.docs.map((doc) => doc.id));
    }
    return unitIds;
  }

  /// Execute a batched query with Firestore's whereIn limit.
  /// Aggregates results across all batches.
  ///
  /// Example:
  /// ```dart
  /// final bookings = await queryInBatches<BookingModel>(
  ///   firestore: _firestore,
  ///   collection: 'bookings',
  ///   fieldPath: 'unit_id',
  ///   values: unitIds,
  ///   queryBuilder: (query) => query.where('status', whereIn: confirmedStatuses),
  ///   mapper: (doc) => BookingModel.fromJson({...doc.data(), 'id': doc.id}),
  /// );
  /// ```
  Future<List<T>> queryInBatches<T>({
    required FirebaseFirestore firestore,
    required String collection,
    required String fieldPath,
    required List<String> values,
    Query Function(Query query)? queryBuilder,
    required T Function(QueryDocumentSnapshot<Map<String, dynamic>> doc) mapper,
    int batchSize = batchLimit,
  }) async {
    if (values.isEmpty) return [];

    final List<T> results = [];

    for (int i = 0; i < values.length; i += batchSize) {
      final batch = values.skip(i).take(batchSize).toList();

      Query<Map<String, dynamic>> query = firestore
          .collection(collection)
          .where(fieldPath, whereIn: batch);

      if (queryBuilder != null) {
        query = queryBuilder(query) as Query<Map<String, dynamic>>;
      }

      final snapshot = await query.get();

      for (final doc in snapshot.docs) {
        try {
          results.add(mapper(doc));
        } catch (_) {
          // Skip invalid documents
        }
      }
    }

    return results;
  }

  /// Calculate sum from bookings using a field extractor
  double sumBookingField(
    List<Map<String, dynamic>> bookings,
    String fieldName,
  ) {
    return bookings.fold<double>(
      0.0,
      (total, b) => total + ((b[fieldName] as num?)?.toDouble() ?? 0.0),
    );
  }

  /// Get start and end of current month
  ({DateTime start, DateTime end}) getCurrentMonthRange() {
    final now = DateTime.now();
    return (
      start: DateTime(now.year, now.month),
      end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
    );
  }

  /// Get start and end of last month
  ({DateTime start, DateTime end}) getLastMonthRange() {
    final now = DateTime.now();
    return (
      start: DateTime(now.year, now.month - 1),
      end: DateTime(now.year, now.month, 0, 23, 59, 59),
    );
  }

  /// Calculate percentage change between two values
  double calculateTrend(double current, double previous) {
    if (previous == 0) return 0.0;
    return ((current - previous) / previous) * 100;
  }

  /// Safely extract a double from Firestore data
  double safeDouble(dynamic value, {double fallback = 0.0}) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  /// Safely extract an int from Firestore data
  int safeInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  /// Month labels for charts
  static const List<String> monthLabels = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// Get month label (1-indexed)
  String getMonthLabel(int month) => monthLabels[month - 1];
}
