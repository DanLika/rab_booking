import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../shared/models/booking_model.dart';
import '../../../../shared/models/property_model.dart';
import '../../../../shared/models/unit_model.dart';
import '../../../../core/constants/enums.dart';

/// Owner bookings model with extended property/unit info
class OwnerBooking {
  final BookingModel booking;
  final PropertyModel property;
  final UnitModel unit;
  final String guestName;
  final String guestEmail;
  final String? guestPhone;

  const OwnerBooking({
    required this.booking,
    required this.property,
    required this.unit,
    required this.guestName,
    required this.guestEmail,
    this.guestPhone,
  });
}

/// Paginated result for owner bookings with Firestore cursor
class PaginatedBookingsResult {
  final List<OwnerBooking> bookings;
  final DocumentSnapshot? lastDocument; // Cursor for next page
  final bool hasMore;

  const PaginatedBookingsResult({
    required this.bookings,
    this.lastDocument,
    required this.hasMore,
  });
}

/// Bidirectional paginated result for windowed scrolling
/// Includes both top and bottom cursors for bidirectional loading
class BidirectionalBookingsResult {
  final List<OwnerBooking> bookings;
  final DocumentSnapshot?
  firstDocument; // Cursor for loading items above (scroll up)
  final DocumentSnapshot?
  lastDocument; // Cursor for loading items below (scroll down)
  final bool hasMoreTop;
  final bool hasMoreBottom;

  const BidirectionalBookingsResult({
    required this.bookings,
    this.firstDocument,
    this.lastDocument,
    required this.hasMoreTop,
    required this.hasMoreBottom,
  });
}

/// Firebase implementation of Owner Bookings Repository
class FirebaseOwnerBookingsRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirebaseOwnerBookingsRepository(this._firestore, this._auth);

  /// Helper method to safely extract String from dynamic value
  /// Handles cases where Firestore returns Map objects instead of Strings
  String? _safeExtractString(dynamic value, {String? fallback}) {
    if (value == null) return fallback;
    if (value is String) return value;
    if (value is Map) {
      // If it's a Map, try to get a meaningful string representation
      // Common case: {'value': 'actual_string'}
      if (value.containsKey('value')) {
        final mapValue = value['value'];
        if (mapValue is String) return mapValue;
      }
      // If no 'value' key, return the first string value found
      for (final v in value.values) {
        if (v is String) return v;
      }
      // Last resort: return toString()
      return fallback;
    }
    // For any other type, convert to string
    return value.toString();
  }

  /// Helper to format source name for display
  String _formatSourceName(String source) {
    switch (source.toLowerCase()) {
      case 'booking_com':
        return 'Booking.com';
      case 'airbnb':
        return 'Airbnb';
      case 'ical':
        return 'iCal';
      default:
        // Capitalize first letter
        if (source.isEmpty) return source;
        return source[0].toUpperCase() + source.substring(1);
    }
  }

  /// Get all bookings for owner's properties
  Future<List<OwnerBooking>> getOwnerBookings({
    String? ownerId,
    String? propertyId,
    String? unitId,
    BookingStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final userId = ownerId ?? _auth.currentUser?.uid;
      if (userId == null)
        throw AuthException(
          'User not authenticated',
          code: 'auth/not-authenticated',
        );

      // Step 1: Get all properties for owner (if not filtering by specific property)
      List<String> propertyIds = [];
      if (propertyId != null) {
        propertyIds = [propertyId];
      } else {
        final propertiesSnapshot = await _firestore
            .collection('properties')
            .where('owner_id', isEqualTo: userId)
            .get();
        propertyIds = propertiesSnapshot.docs.map((doc) => doc.id).toList();
      }

      if (propertyIds.isEmpty) return [];

      // Step 2: Get all units for these properties (if not filtering by specific unit)
      List<String> unitIds = [];
      final Map<String, UnitModel> unitsMap = {};
      final Map<String, String> unitToPropertyMap = {};

      if (unitId != null) {
        // Get specific unit - need to find which property it belongs to
        for (final propertyId in propertyIds) {
          final unitDoc = await _firestore
              .collection('properties')
              .doc(propertyId)
              .collection('units')
              .doc(unitId)
              .get();
          if (unitDoc.exists) {
            final unit = UnitModel.fromJson({
              ...unitDoc.data()!,
              'id': unitDoc.id,
            });
            unitIds = [unitId];
            unitsMap[unitId] = unit;
            unitToPropertyMap[unitId] = propertyId;
            break;
          }
        }
      } else {
        // Get all units for properties from subcollections
        for (final propertyId in propertyIds) {
          final unitsSnapshot = await _firestore
              .collection('properties')
              .doc(propertyId)
              .collection('units')
              .get();

          for (final doc in unitsSnapshot.docs) {
            final unit = UnitModel.fromJson({...doc.data(), 'id': doc.id});
            unitIds.add(doc.id);
            unitsMap[doc.id] = unit;
            unitToPropertyMap[doc.id] = propertyId;
          }
        }
      }

      if (unitIds.isEmpty) return [];

      // Step 3: Get bookings for these units (in batches of 10)
      final List<BookingModel> bookings = [];
      for (int i = 0; i < unitIds.length; i += 10) {
        final batch = unitIds.skip(i).take(10).toList();
        var query = _firestore
            .collection('bookings')
            .where('unit_id', whereIn: batch);

        // Apply filters
        if (status != null) {
          query = query.where('status', isEqualTo: status.value);
        }
        if (startDate != null) {
          query = query.where('check_in', isGreaterThanOrEqualTo: startDate);
        }
        if (endDate != null) {
          query = query.where('check_out', isLessThanOrEqualTo: endDate);
        }

        final bookingsSnapshot = await query.get();
        for (final doc in bookingsSnapshot.docs) {
          try {
            final booking = BookingModel.fromJson({
              ...doc.data(),
              'id': doc.id,
            });
            bookings.add(booking);
          } catch (e) {
            // Skip invalid bookings - log for debugging but don't fail entire query
            // ignore: avoid_print
            print('WARNING: Failed to parse booking ${doc.id}: $e');
          }
        }
      }

      // Step 4: Get properties data
      final Map<String, PropertyModel> propertiesMap = {};
      final uniquePropertyIds = unitToPropertyMap.values.toSet().toList();
      for (int i = 0; i < uniquePropertyIds.length; i += 10) {
        final batch = uniquePropertyIds.skip(i).take(10).toList();
        for (final propId in batch) {
          final propDoc = await _firestore
              .collection('properties')
              .doc(propId)
              .get();
          if (propDoc.exists) {
            propertiesMap[propId] = PropertyModel.fromJson({
              ...propDoc.data()!,
              'id': propDoc.id,
            });
          }
        }
      }

      // Step 5: Get user (guest) data for each booking (skip null userIds from widget bookings)
      final Map<String, Map<String, dynamic>> usersMap = {};
      final uniqueUserIds = bookings
          .map((b) => b.userId)
          .where((id) => id != null)
          .cast<String>()
          .toSet()
          .toList();
      for (final userId in uniqueUserIds) {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          usersMap[userId] = userDoc.data()!;
        }
      }

      // Step 6: Combine all data into OwnerBooking objects
      final ownerBookings = <OwnerBooking>[];
      for (final booking in bookings) {
        final unit = unitsMap[booking.unitId];
        if (unit == null) continue;

        final propertyId = unitToPropertyMap[booking.unitId];
        if (propertyId == null) continue;

        final property = propertiesMap[propertyId];
        if (property == null) continue;

        // For widget bookings, use guest details from booking; for authenticated bookings, use user data
        final userData = booking.userId != null
            ? usersMap[booking.userId]
            : null;
        final guestName =
            booking.guestName ??
            (userData != null
                ? '${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}'
                      .trim()
                : 'Unknown Guest');
        final guestEmail =
            booking.guestEmail ?? (userData?['email'] as String?) ?? '';
        final guestPhone =
            booking.guestPhone ?? (userData?['phone'] as String?);

        ownerBookings.add(
          OwnerBooking(
            booking: booking,
            property: property,
            unit: unit,
            guestName: guestName.isEmpty ? 'Unknown Guest' : guestName,
            guestEmail: guestEmail,
            guestPhone: guestPhone,
          ),
        );
      }

      // Sort by check-in date descending
      ownerBookings.sort(
        (a, b) => b.booking.checkIn.compareTo(a.booking.checkIn),
      );

      return ownerBookings;
    } catch (e) {
      throw BookingException(
        'Failed to fetch owner bookings',
        code: 'booking/fetch-failed',
        originalError: e,
      );
    }
  }

  /// Get bookings for calendar view (grouped by unit)
  /// Includes both regular bookings AND iCal events (Booking.com, Airbnb, etc.)
  Future<Map<String, List<BookingModel>>> getCalendarBookings({
    required String ownerId,
    String? propertyId,
    String? unitId,
    required DateTime startDate,
    required DateTime endDate,
    bool includeIcalEvents = true, // Optional: include external bookings
  }) async {
    try {
      // Step 1: Get units
      List<String> unitIds = [];
      if (unitId != null) {
        unitIds = [unitId];
      } else {
        // Get properties for owner
        List<String> propertyIds = [];
        if (propertyId != null) {
          propertyIds = [propertyId];
        } else {
          final propertiesSnapshot = await _firestore
              .collection('properties')
              .where('owner_id', isEqualTo: ownerId)
              .get();
          propertyIds = propertiesSnapshot.docs.map((doc) => doc.id).toList();
        }

        if (propertyIds.isEmpty) return {};

        // Get units for these properties from subcollections
        for (final propertyId in propertyIds) {
          final unitsSnapshot = await _firestore
              .collection('properties')
              .doc(propertyId)
              .collection('units')
              .get();
          unitIds.addAll(unitsSnapshot.docs.map((doc) => doc.id));
        }
      }

      if (unitIds.isEmpty) return {};

      // Step 2: Get bookings that overlap with date range
      final Map<String, List<BookingModel>> bookingsByUnit = {};

      for (int i = 0; i < unitIds.length; i += 10) {
        final batch = unitIds.skip(i).take(10).toList();

        // Get bookings where check_in <= endDate AND check_out >= startDate
        // NOTE: Firestore allows only ONE inequality filter per query
        // We filter by check_in on server, then check_out on client
        // OPTIMIZATION: Could add compound index (unit_id + check_out + check_in)
        // but requires schema migration - current approach works well for <1000 bookings/unit
        final bookingsSnapshot = await _firestore
            .collection('bookings')
            .where('unit_id', whereIn: batch)
            .where('check_in', isLessThanOrEqualTo: endDate)
            .get();

        for (final doc in bookingsSnapshot.docs) {
          final booking = BookingModel.fromJson({...doc.data(), 'id': doc.id});

          // OPTIMIZED: Client-side filter with early exit
          if (booking.checkOut.isBefore(startDate)) {
            continue; // Skip bookings that ended before range
          }

          final unitId = booking.unitId;
          if (!bookingsByUnit.containsKey(unitId)) {
            bookingsByUnit[unitId] = [];
          }
          bookingsByUnit[unitId]!.add(booking);
        }
      }

      // Step 3: OPTIONAL - Add iCal events as "pseudo-bookings" (Booking.com, Airbnb, etc.)
      if (includeIcalEvents) {
        try {
          await _addIcalEventsToCalendar(
            bookingsByUnit: bookingsByUnit,
            unitIds: unitIds,
            startDate: startDate,
            endDate: endDate,
          );
        } catch (icalError) {
          // GRACEFUL FALLBACK: If iCal query fails, continue with regular bookings
          // This ensures calendar works even if owner has no iCal feeds or there's an error
        }
      }

      // Sort bookings by check-in date
      for (final unitId in bookingsByUnit.keys) {
        bookingsByUnit[unitId]!.sort((a, b) => a.checkIn.compareTo(b.checkIn));
      }

      return bookingsByUnit;
    } catch (e) {
      throw BookingException(
        'Failed to fetch calendar bookings',
        code: 'booking/calendar-fetch-failed',
        originalError: e,
      );
    }
  }

/// OPTIMIZED: Get bookings using pre-fetched unitIds
  /// Skips redundant properties/units queries by accepting unitIds directly
  /// Use this when unitIds are already cached (e.g., from allOwnerUnitsProvider)
  ///
  /// Query savings: Eliminates 1 + N queries (1 properties + N units)
  Future<Map<String, List<BookingModel>>> getCalendarBookingsWithUnitIds({
    required List<String> unitIds,
    required DateTime startDate,
    required DateTime endDate,
    bool includeIcalEvents = true,
  }) async {
    try {
      if (unitIds.isEmpty) return {};

      final Map<String, List<BookingModel>> bookingsByUnit = {};

      // Batch query bookings (Firestore whereIn limit is 10)
      for (int i = 0; i < unitIds.length; i += 10) {
        final batch = unitIds.skip(i).take(10).toList();

        final bookingsSnapshot = await _firestore
            .collection('bookings')
            .where('unit_id', whereIn: batch)
            .where('check_in', isLessThanOrEqualTo: endDate)
            .get();

        for (final doc in bookingsSnapshot.docs) {
          final booking = BookingModel.fromJson({...doc.data(), 'id': doc.id});

          // Client-side filter: skip bookings that ended before range
          if (booking.checkOut.isBefore(startDate)) {
            continue;
          }

          final unitId = booking.unitId;
          if (!bookingsByUnit.containsKey(unitId)) {
            bookingsByUnit[unitId] = [];
          }
          bookingsByUnit[unitId]!.add(booking);
        }
      }

      // Add iCal events if enabled
      if (includeIcalEvents) {
        try {
          await _addIcalEventsToCalendar(
            bookingsByUnit: bookingsByUnit,
            unitIds: unitIds,
            startDate: startDate,
            endDate: endDate,
          );
        } catch (_) {
          // Graceful fallback - continue without iCal events
        }
      }

      // Sort bookings by check-in date
      for (final unitId in bookingsByUnit.keys) {
        bookingsByUnit[unitId]!.sort((a, b) => a.checkIn.compareTo(b.checkIn));
      }

      return bookingsByUnit;
    } catch (e) {
      throw BookingException(
        'Failed to fetch calendar bookings',
        code: 'booking/calendar-fetch-failed',
        originalError: e,
      );
    }
  }

  /// OPTIONAL: Add iCal events (Booking.com, Airbnb, etc.) to calendar bookings
  /// Converts iCal events to pseudo-BookingModel objects for display
  /// Gracefully fails if no iCal feeds exist or query fails
  Future<void> _addIcalEventsToCalendar({
    required Map<String, List<BookingModel>> bookingsByUnit,
    required List<String> unitIds,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Query iCal events in batches (Firestore whereIn limit is 10)
    for (int i = 0; i < unitIds.length; i += 10) {
      final batch = unitIds.skip(i).take(10).toList();

      final icalSnapshot = await _firestore
          .collection('ical_events')
          .where('unit_id', whereIn: batch)
          .where('start_date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      // Convert iCal events to pseudo-BookingModel objects
      for (final doc in icalSnapshot.docs) {
        try {
          final data = doc.data();
          final startDateTimestamp = data['start_date'] as Timestamp;
          final endDateTimestamp = data['end_date'] as Timestamp;
          final eventStartDate = startDateTimestamp.toDate();
          final eventEndDate = endDateTimestamp.toDate();

          // Skip events that ended before range
          if (eventEndDate.isBefore(startDate)) {
            continue;
          }

          final unitId = data['unit_id'] as String;
          final source =
              _safeExtractString(data['source'], fallback: 'ical') ?? 'ical';
          final guestName =
              _safeExtractString(
                data['guest_name'],
                fallback: 'External Booking',
              ) ??
              'External Booking';

          // Create pseudo-BookingModel for iCal event
          // Using special ID prefix 'ical_' to distinguish from regular bookings
          final pseudoBooking = BookingModel(
            id: 'ical_${doc.id}', // Special prefix to identify iCal bookings
            unitId: unitId,
            checkIn: eventStartDate,
            checkOut: eventEndDate,
            status: BookingStatus.confirmed, // Always show as confirmed
            paymentMethod:
                'external', // External bookings - payment tracked on source platform
            source:
                source, // CRITICAL: Set source for external booking detection (read-only)
            guestName: guestName,
            notes: 'Imported from ${_formatSourceName(source)} via iCal sync',
            createdAt: eventStartDate,
            updatedAt: eventStartDate,
          );

          // Add to bookings map
          if (!bookingsByUnit.containsKey(unitId)) {
            bookingsByUnit[unitId] = [];
          }
          bookingsByUnit[unitId]!.add(pseudoBooking);
        } catch (parseError) {
          // Skip malformed iCal events
        }
      }
    }
  }

  /// Get a single booking by ID with property and unit info
  /// Used for deep-links when booking is not in current window
  Future<OwnerBooking?> getOwnerBookingById(String bookingId) async {
    try {
      final bookingDoc = await _firestore
          .collection('bookings')
          .doc(bookingId)
          .get();
      if (!bookingDoc.exists) return null;

      final bookingData = bookingDoc.data()!;
      final booking = BookingModel.fromJson({
        ...bookingData,
        'id': bookingDoc.id,
      });

      // Get unit and property
      final unitId = booking.unitId;
      final propertyId = booking.propertyId;

      final propertyDoc = await _firestore
          .collection('properties')
          .doc(propertyId)
          .get();
      if (!propertyDoc.exists) return null;

      final property = PropertyModel.fromJson({
        ...propertyDoc.data()!,
        'id': propertyDoc.id,
      });

      final unitDoc = await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('units')
          .doc(unitId)
          .get();
      if (!unitDoc.exists) return null;

      final unit = UnitModel.fromJson({...unitDoc.data()!, 'id': unitDoc.id});

      // Extract guest info
      final guestName =
          _safeExtractString(bookingData['guest_name']) ?? 'Unknown Guest';
      final guestEmail = _safeExtractString(bookingData['guest_email']) ?? '';
      final guestPhone = _safeExtractString(bookingData['guest_phone']);

      return OwnerBooking(
        booking: booking,
        property: property,
        unit: unit,
        guestName: guestName,
        guestEmail: guestEmail,
        guestPhone: guestPhone,
      );
    } catch (e) {
      throw BookingException(
        'Failed to fetch booking',
        code: 'booking/fetch-failed',
        originalError: e,
      );
    }
  }

  /// Approve pending booking (owner approval workflow)
  Future<void> approveBooking(String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': BookingStatus.confirmed.value,
        'approved_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      // Email notification will be sent by onBookingStatusChange Cloud Function
    } catch (e) {
      throw BookingException.approvalFailed(e);
    }
  }

  /// Reject pending booking (owner approval workflow)
  Future<void> rejectBooking(String bookingId, {String? reason}) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': BookingStatus.cancelled.value,
        'rejection_reason': reason ?? 'Rejected by owner',
        'rejected_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      // Email notification will be sent by onBookingStatusChange Cloud Function
    } catch (e) {
      throw BookingException(
        'Failed to reject booking',
        code: 'booking/rejection-failed',
        originalError: e,
      );
    }
  }

  /// Confirm pending booking
  Future<void> confirmBooking(String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': BookingStatus.confirmed.value,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw BookingException(
        'Failed to confirm booking',
        code: 'booking/confirmation-failed',
        originalError: e,
      );
    }
  }

  /// Cancel booking with reason
  /// Note: Cancellation email is automatically sent by onBookingStatusChange Cloud Function trigger
  Future<void> cancelBooking(
    String bookingId,
    String reason, {
    bool sendEmail = true,
  }) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': BookingStatus.cancelled.value,
        'cancellation_reason': reason,
        'cancelled_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Email is automatically sent by onBookingStatusChange Cloud Function
      // when status changes to 'cancelled'
    } catch (e) {
      throw BookingException.cancellationFailed(e);
    }
  }

  /// Mark booking as completed
  Future<void> completeBooking(String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': BookingStatus.completed.value,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw BookingException(
        'Failed to complete booking',
        code: 'booking/completion-failed',
        originalError: e,
      );
    }
  }

  /// Permanently delete booking
  Future<void> deleteBooking(String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).delete();
    } catch (e) {
      throw BookingException.deletionFailed(e);
    }
  }

  /// Get owner's unit IDs (cached for pagination)
  /// Returns list of unit IDs that belong to owner's properties
  Future<List<String>> getOwnerUnitIds(String ownerId) async {
    try {
      // Get all properties for owner
      final propertiesSnapshot = await _firestore
          .collection('properties')
          .where('owner_id', isEqualTo: ownerId)
          .get();

      final propertyIds = propertiesSnapshot.docs.map((doc) => doc.id).toList();
      if (propertyIds.isEmpty) return [];

      // Get all units for these properties
      final List<String> unitIds = [];
      for (final propertyId in propertyIds) {
        final unitsSnapshot = await _firestore
            .collection('properties')
            .doc(propertyId)
            .collection('units')
            .get();
        unitIds.addAll(unitsSnapshot.docs.map((doc) => doc.id));
      }

      return unitIds;
    } catch (e) {
      throw BookingException(
        'Failed to fetch owner unit IDs',
        code: 'booking/fetch-units-failed',
        originalError: e,
      );
    }
  }

  /// Get count of bookings by status using Firestore aggregation
  /// OPTIMIZED: Uses count() which doesn't charge for document reads
  /// Only counts - no document data is downloaded
  Future<int> getBookingsCountByStatus({
    required List<String> unitIds,
    required BookingStatus status,
  }) async {
    if (unitIds.isEmpty) return 0;

    int totalCount = 0;

    // Batch unit IDs (Firestore whereIn limit is 30 for count queries)
    for (int i = 0; i < unitIds.length; i += 30) {
      final batch = unitIds.skip(i).take(30).toList();

      final countQuery = await _firestore
          .collection('bookings')
          .where('unit_id', whereIn: batch)
          .where('status', isEqualTo: status.name)
          .count()
          .get();

      totalCount += countQuery.count ?? 0;
    }

    return totalCount;
  }

  /// Get paginated bookings for owner with Firestore cursor
  /// Uses server-side pagination - only fetches [limit] bookings per page
  ///
  /// NOTE: Ordering is by created_at DESC (most recent first)
  /// Status priority sorting is done client-side on each page
  Future<PaginatedBookingsResult> getOwnerBookingsPaginated({
    required String ownerId,
    required List<String> unitIds, // Pre-fetched unit IDs
    String? propertyId,
    BookingStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 20,
    DocumentSnapshot? startAfterDocument, // Cursor from previous page
  }) async {
    try {
      if (unitIds.isEmpty) {
        return const PaginatedBookingsResult(bookings: [], hasMore: false);
      }

      // Filter unit IDs by property if specified
      List<String> filteredUnitIds = unitIds;
      if (propertyId != null) {
        final unitsSnapshot = await _firestore
            .collection('properties')
            .doc(propertyId)
            .collection('units')
            .get();
        final propertyUnitIds = unitsSnapshot.docs.map((doc) => doc.id).toSet();
        filteredUnitIds = unitIds.where(propertyUnitIds.contains).toList();
        if (filteredUnitIds.isEmpty) {
          return const PaginatedBookingsResult(bookings: [], hasMore: false);
        }
      }

      // Build paginated query
      // NOTE: Firestore whereIn has 30 item limit, so we batch
      final List<QueryDocumentSnapshot> allDocs = [];

      // Per-batch limit: 3x requested limit (safety margin for merge-sort), capped at 100
      // This prevents fetching ALL bookings when we only need a few
      final batchLimit = (limit * 3).clamp(10, 100);

      for (int i = 0; i < filteredUnitIds.length; i += 10) {
        final batch = filteredUnitIds.skip(i).take(10).toList();

        Query query = _firestore
            .collection('bookings')
            .where('unit_id', whereIn: batch)
            .orderBy('created_at', descending: true)
            .limit(batchLimit); // OPTIMIZATION: Limit per batch to reduce reads

        // Apply filters
        if (status != null) {
          query = query.where('status', isEqualTo: status.value);
        }

        // NOTE: Can't combine whereIn + inequality on different fields easily
        // Date filtering would require composite index per batch
        // For now, we do date filtering client-side for simplicity

        final snapshot = await query.get();
        allDocs.addAll(snapshot.docs);
      }

      // Sort all docs by created_at DESC (merge sort from batches)
      allDocs.sort((a, b) {
        final aCreated =
            (a.data() as Map<String, dynamic>)['created_at'] as Timestamp?;
        final bCreated =
            (b.data() as Map<String, dynamic>)['created_at'] as Timestamp?;
        if (aCreated == null && bCreated == null) return 0;
        if (aCreated == null) return 1;
        if (bCreated == null) return -1;
        return bCreated.compareTo(aCreated);
      });

      // Apply client-side date filtering if needed
      var filteredDocs = allDocs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        if (startDate != null) {
          final checkIn = (data['check_in'] as Timestamp?)?.toDate();
          if (checkIn != null && checkIn.isBefore(startDate)) return false;
        }
        if (endDate != null) {
          final checkOut = (data['check_out'] as Timestamp?)?.toDate();
          if (checkOut != null && checkOut.isAfter(endDate)) return false;
        }
        return true;
      }).toList();

      // Apply cursor (skip documents until we find startAfterDocument)
      if (startAfterDocument != null) {
        final startIndex = filteredDocs.indexWhere(
          (doc) => doc.id == startAfterDocument.id,
        );
        if (startIndex != -1) {
          filteredDocs = filteredDocs.sublist(startIndex + 1);
        }
      }

      // Take limit + 1 to check if there are more
      final hasMore = filteredDocs.length > limit;
      final pageDocs = filteredDocs.take(limit).toList();
      final lastDoc = pageDocs.isNotEmpty ? pageDocs.last : null;

      // Parse bookings
      final List<BookingModel> bookings = [];
      for (final doc in pageDocs) {
        try {
          final booking = BookingModel.fromJson({
            ...(doc.data() as Map<String, dynamic>),
            'id': doc.id,
          });
          bookings.add(booking);
        } catch (e) {
          // Skip invalid bookings
        }
      }

      if (bookings.isEmpty) {
        return const PaginatedBookingsResult(bookings: [], hasMore: false);
      }

      // Fetch related data for this page only
      final ownerBookings = await _enrichBookingsWithRelatedData(bookings);

      // Sort by status priority (client-side for this page)
      ownerBookings.sort((a, b) {
        final priorityCompare = b.booking.status.sortPriority.compareTo(
          a.booking.status.sortPriority,
        );
        if (priorityCompare != 0) return priorityCompare;
        return b.booking.createdAt.compareTo(a.booking.createdAt);
      });

      return PaginatedBookingsResult(
        bookings: ownerBookings,
        lastDocument: lastDoc,
        hasMore: hasMore,
      );
    } catch (e) {
      throw BookingException(
        'Failed to fetch paginated bookings',
        code: 'booking/paginated-fetch-failed',
        originalError: e,
      );
    }
  }

  /// Get bookings BEFORE a cursor (for scrolling up / loading previous items)
  /// Returns items ordered by created_at DESC, ending before the cursor
  ///
  /// Used for bidirectional windowing when user scrolls back up
  Future<BidirectionalBookingsResult> getOwnerBookingsBefore({
    required String ownerId,
    required List<String> unitIds,
    String? propertyId,
    BookingStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 20,
    required DocumentSnapshot endBeforeDocument,
  }) async {
    try {
      if (unitIds.isEmpty) {
        return const BidirectionalBookingsResult(
          bookings: [],
          hasMoreTop: false,
          hasMoreBottom: true,
        );
      }

      // Filter unit IDs by property if specified
      List<String> filteredUnitIds = unitIds;
      if (propertyId != null) {
        final unitsSnapshot = await _firestore
            .collection('properties')
            .doc(propertyId)
            .collection('units')
            .get();
        final propertyUnitIds = unitsSnapshot.docs.map((doc) => doc.id).toSet();
        filteredUnitIds = unitIds.where(propertyUnitIds.contains).toList();
        if (filteredUnitIds.isEmpty) {
          return const BidirectionalBookingsResult(
            bookings: [],
            hasMoreTop: false,
            hasMoreBottom: true,
          );
        }
      }

      // Build query - fetch all docs first, then apply cursor client-side
      // This is necessary because we need to sort across multiple batches
      final List<QueryDocumentSnapshot> allDocs = [];

      for (int i = 0; i < filteredUnitIds.length; i += 10) {
        final batch = filteredUnitIds.skip(i).take(10).toList();

        Query query = _firestore
            .collection('bookings')
            .where('unit_id', whereIn: batch)
            .orderBy('created_at', descending: true);

        if (status != null) {
          query = query.where('status', isEqualTo: status.value);
        }

        final snapshot = await query.get();
        allDocs.addAll(snapshot.docs);
      }

      // Sort all docs by created_at DESC
      allDocs.sort((a, b) {
        final aCreated =
            (a.data() as Map<String, dynamic>)['created_at'] as Timestamp?;
        final bCreated =
            (b.data() as Map<String, dynamic>)['created_at'] as Timestamp?;
        if (aCreated == null && bCreated == null) return 0;
        if (aCreated == null) return 1;
        if (bCreated == null) return -1;
        return bCreated.compareTo(aCreated);
      });

      // Apply client-side date filtering
      final filteredDocs = allDocs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        if (startDate != null) {
          final checkIn = (data['check_in'] as Timestamp?)?.toDate();
          if (checkIn != null && checkIn.isBefore(startDate)) return false;
        }
        if (endDate != null) {
          final checkOut = (data['check_out'] as Timestamp?)?.toDate();
          if (checkOut != null && checkOut.isAfter(endDate)) return false;
        }
        return true;
      }).toList();

      // Find the cursor position and get items BEFORE it
      final cursorIndex = filteredDocs.indexWhere(
        (doc) => doc.id == endBeforeDocument.id,
      );
      if (cursorIndex == -1 || cursorIndex == 0) {
        // Cursor not found or at the beginning - no more items above
        return const BidirectionalBookingsResult(
          bookings: [],
          hasMoreTop: false,
          hasMoreBottom: true,
        );
      }

      // Get items before the cursor (items with index < cursorIndex)
      // Since list is sorted DESC, items before cursor are "newer" items
      final startIndex = (cursorIndex - limit).clamp(0, cursorIndex);
      final beforeCursorDocs = filteredDocs.sublist(startIndex, cursorIndex);

      // Check if there are more items above
      final hasMoreTop = startIndex > 0;

      // Parse bookings
      final List<BookingModel> bookings = [];
      for (final doc in beforeCursorDocs) {
        try {
          final booking = BookingModel.fromJson({
            ...(doc.data() as Map<String, dynamic>),
            'id': doc.id,
          });
          bookings.add(booking);
        } catch (e) {
          // Skip invalid bookings
        }
      }

      if (bookings.isEmpty) {
        return const BidirectionalBookingsResult(
          bookings: [],
          hasMoreTop: false,
          hasMoreBottom: true,
        );
      }

      // Fetch related data
      final ownerBookings = await _enrichBookingsWithRelatedData(bookings);

      // Sort by status priority (client-side)
      ownerBookings.sort((a, b) {
        final priorityCompare = b.booking.status.sortPriority.compareTo(
          a.booking.status.sortPriority,
        );
        if (priorityCompare != 0) return priorityCompare;
        return b.booking.createdAt.compareTo(a.booking.createdAt);
      });

      return BidirectionalBookingsResult(
        bookings: ownerBookings,
        firstDocument: beforeCursorDocs.isNotEmpty
            ? beforeCursorDocs.first
            : null,
        lastDocument: beforeCursorDocs.isNotEmpty
            ? beforeCursorDocs.last
            : null,
        hasMoreTop: hasMoreTop,
        hasMoreBottom: true, // Original cursor still has items below
      );
    } catch (e) {
      throw BookingException(
        'Failed to fetch bookings before cursor',
        code: 'booking/before-fetch-failed',
        originalError: e,
      );
    }
  }

  /// Enrich bookings with property, unit, and user data
  /// Used by paginated query to fetch related data for current page only
  ///
  /// OPTIMIZED: Uses batch queries instead of N×M individual queries
  /// - Before: 50+ queries for 5 properties × 10 units
  /// - After: ~5-7 queries total (1 properties + 1 per property for units + 1 users)
  Future<List<OwnerBooking>> _enrichBookingsWithRelatedData(
    List<BookingModel> bookings,
  ) async {
    if (bookings.isEmpty) return [];

    // Collect unique IDs
    final unitIds = bookings.map((b) => b.unitId).toSet().toList();
    final userIds = bookings
        .map((b) => b.userId)
        .where((id) => id != null)
        .cast<String>()
        .toSet()
        .toList();

    // Maps to store fetched data
    final Map<String, UnitModel> unitsMap = {};
    final Map<String, String> unitToPropertyMap = {};
    final Map<String, PropertyModel> propertiesMap = {};

    // ===== OPTIMIZED: Get only owner's properties (not ALL properties) =====
    // We need to find which properties contain our units
    // Strategy: Query each property's units subcollection with batch whereIn

    // First, get the current user's properties only
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    final ownerPropertiesSnapshot = await _firestore
        .collection('properties')
        .where('owner_id', isEqualTo: userId)
        .get();  // 1 QUERY

    for (final propDoc in ownerPropertiesSnapshot.docs) {
      propertiesMap[propDoc.id] = PropertyModel.fromJson({
        ...propDoc.data(),
        'id': propDoc.id,
      });
    }

    // ===== OPTIMIZED: Batch fetch units using whereIn =====
    // Instead of N×M individual queries, do 1 query per property with batch
    for (final propertyId in propertiesMap.keys) {
      // Firestore whereIn limit is 30, batch if needed
      for (int i = 0; i < unitIds.length; i += 30) {
        final batch = unitIds.skip(i).take(30).toList();
        if (batch.isEmpty) continue;

        final unitsSnapshot = await _firestore
            .collection('properties')
            .doc(propertyId)
            .collection('units')
            .where(FieldPath.documentId, whereIn: batch)
            .get();  // 1 QUERY per property (max ~5 for typical owner)

        for (final unitDoc in unitsSnapshot.docs) {
          unitsMap[unitDoc.id] = UnitModel.fromJson({
            ...unitDoc.data(),
            'id': unitDoc.id,
          });
          unitToPropertyMap[unitDoc.id] = propertyId;
        }
      }

      // Early exit if we found all units
      if (unitsMap.length >= unitIds.length) break;
    }

    // ===== OPTIMIZED: Batch fetch users using whereIn =====
    // Instead of N individual queries, do batched queries
    final Map<String, Map<String, dynamic>> usersMap = {};
    if (userIds.isNotEmpty) {
      // Firestore whereIn limit is 30, batch if needed
      for (int i = 0; i < userIds.length; i += 30) {
        final batch = userIds.skip(i).take(30).toList();
        if (batch.isEmpty) continue;

        final usersSnapshot = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: batch)
            .get();  // 1 QUERY for up to 30 users

        for (final userDoc in usersSnapshot.docs) {
          usersMap[userDoc.id] = userDoc.data();
        }
      }
    }

    // Build OwnerBooking objects
    final ownerBookings = <OwnerBooking>[];
    for (final booking in bookings) {
      final unit = unitsMap[booking.unitId];
      if (unit == null) continue;

      final propertyId = unitToPropertyMap[booking.unitId];
      if (propertyId == null) continue;

      final property = propertiesMap[propertyId];
      if (property == null) continue;

      final userData = booking.userId != null ? usersMap[booking.userId] : null;
      final guestName =
          booking.guestName ??
          (userData != null
              ? '${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}'
                    .trim()
              : 'Unknown Guest');
      final guestEmail =
          booking.guestEmail ?? (userData?['email'] as String?) ?? '';
      final guestPhone = booking.guestPhone ?? (userData?['phone'] as String?);

      ownerBookings.add(
        OwnerBooking(
          booking: booking,
          property: property,
          unit: unit,
          guestName: guestName.isEmpty ? 'Unknown Guest' : guestName,
          guestEmail: guestEmail,
          guestPhone: guestPhone,
        ),
      );
    }

    return ownerBookings;
  }

  /// Get dashboard statistics data efficiently
  /// Returns raw booking data needed for calculating dashboard stats
  /// Uses optimized queries with proper limits and date filters
  Future<DashboardStatsData> getDashboardStatsData({
    required List<String> unitIds,
  }) async {
    if (unitIds.isEmpty) {
      return const DashboardStatsData(
        confirmedBookings: [],
        upcomingCheckIns: [],
      );
    }

    final now = DateTime.now();
    final currentYearStart = DateTime(now.year);
    final next7Days = now.add(const Duration(days: 7));

    // Parallel queries for efficiency
    final confirmedBookingsFuture = _queryBookingsForStats(
      unitIds: unitIds,
      statuses: [BookingStatus.confirmed, BookingStatus.completed],
      createdAfter: currentYearStart, // Only this year's bookings
      limit: 500, // Reasonable cap for yearly data
    );

    final upcomingCheckInsFuture = _queryUpcomingCheckIns(
      unitIds: unitIds,
      checkInAfter: now,
      checkInBefore: next7Days,
      limit: 100, // Upcoming check-ins are limited
    );

    final results = await Future.wait([
      confirmedBookingsFuture,
      upcomingCheckInsFuture,
    ]);

    return DashboardStatsData(
      confirmedBookings: results[0],
      upcomingCheckIns: results[1],
    );
  }

  /// Query confirmed/completed bookings for revenue calculations
  Future<List<BookingModel>> _queryBookingsForStats({
    required List<String> unitIds,
    required List<BookingStatus> statuses,
    required DateTime createdAfter,
    required int limit,
  }) async {
    final List<BookingModel> allBookings = [];
    final batchLimit = (limit ~/ ((unitIds.length / 10).ceil())).clamp(10, 100);

    for (int i = 0; i < unitIds.length; i += 10) {
      final batch = unitIds.skip(i).take(10).toList();

      for (final status in statuses) {
        final query = _firestore
            .collection('bookings')
            .where('unit_id', whereIn: batch)
            .where('status', isEqualTo: status.value)
            .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(createdAfter))
            .orderBy('created_at', descending: true)
            .limit(batchLimit);

        final snapshot = await query.get();
        for (final doc in snapshot.docs) {
          try {
            final booking = BookingModel.fromJson({
              ...(doc.data()),
              'id': doc.id,
            });
            allBookings.add(booking);
          } catch (_) {
            // Skip invalid bookings
          }
        }
      }
    }

    return allBookings;
  }

  /// Query upcoming check-ins for next 7 days
  Future<List<BookingModel>> _queryUpcomingCheckIns({
    required List<String> unitIds,
    required DateTime checkInAfter,
    required DateTime checkInBefore,
    required int limit,
  }) async {
    final List<BookingModel> allBookings = [];
    final batchLimit = (limit ~/ ((unitIds.length / 10).ceil())).clamp(5, 50);

    for (int i = 0; i < unitIds.length; i += 10) {
      final batch = unitIds.skip(i).take(10).toList();

      // Query confirmed and pending bookings with upcoming check-ins
      for (final status in [BookingStatus.confirmed, BookingStatus.pending]) {
        final query = _firestore
            .collection('bookings')
            .where('unit_id', whereIn: batch)
            .where('status', isEqualTo: status.value)
            .where('check_in', isGreaterThanOrEqualTo: Timestamp.fromDate(checkInAfter))
            .where('check_in', isLessThan: Timestamp.fromDate(checkInBefore))
            .limit(batchLimit);

        final snapshot = await query.get();
        for (final doc in snapshot.docs) {
          try {
            final booking = BookingModel.fromJson({
              ...(doc.data()),
              'id': doc.id,
            });
            allBookings.add(booking);
          } catch (_) {
            // Skip invalid bookings
          }
        }
      }
    }

    return allBookings;
  }
}

/// Dashboard stats raw data - used by provider to calculate final stats
class DashboardStatsData {
  final List<BookingModel> confirmedBookings;
  final List<BookingModel> upcomingCheckIns;

  const DashboardStatsData({
    required this.confirmedBookings,
    required this.upcomingCheckIns,
  });
}
