import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/utils/async_utils.dart';
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
  /// PERF-002: Refactored to reduce N+1 queries.
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
      if (userId == null) {
        throw AuthException(
          'User not authenticated',
          code: 'auth/not-authenticated',
        );
      }

      // Step 1: Get bookings using a collection group query.
      var query = _firestore
          .collectionGroup('bookings')
          .where('owner_id', isEqualTo: userId);

      // Apply filters
      if (propertyId != null) {
        query = query.where('property_id', isEqualTo: propertyId);
      }
      if (unitId != null) {
        query = query.where('unit_id', isEqualTo: unitId);
      }
      if (status != null) {
        query = query.where('status', isEqualTo: status.value);
      }
      if (startDate != null) {
        query = query.where('check_in', isGreaterThanOrEqualTo: startDate);
      }
      if (endDate != null) {
        query = query.where('check_out', isLessThanOrEqualTo: endDate);
      }

      // Add a limit to prevent fetching excessive data.
      final bookingsSnapshot =
      await query.limit(500).get().withListFetchTimeout(
        'getOwnerBookings',
      );

      final bookings = bookingsSnapshot.docs.map((doc) {
        try {
          return BookingModel.fromJson({...doc.data(), 'id': doc.id});
        } catch (e) {
          print('WARNING: Failed to parse booking ${doc.id}: $e');
          return null;
        }
      }).where((b) => b != null).cast<BookingModel>().toList();

      if (bookings.isEmpty) return [];

      // Step 2: Enrich bookings with related data.
      final ownerBookings = await _enrichBookingsWithRelatedData(bookings);

      // Sort by check-in date descending.
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
      // Step 1: Get units (needed for iCal events - they use propertyId)
      List<String> unitIds = [];
      List<String> propertyIds = [];
      final Map<String, String> unitToPropertyMap = {};

      if (unitId != null) {
        unitIds = [unitId];
        // Find which property this unit belongs to
        if (propertyId != null) {
          propertyIds = [propertyId];
          unitToPropertyMap[unitId] = propertyId;
        } else {
          final propertiesSnapshot = await _firestore
              .collection('properties')
              .where('owner_id', isEqualTo: ownerId)
              .get();
          for (final propDoc in propertiesSnapshot.docs) {
            final unitDoc = await _firestore
                .collection('properties')
                .doc(propDoc.id)
                .collection('units')
                .doc(unitId)
                .get();
            if (unitDoc.exists) {
              propertyIds = [propDoc.id];
              unitToPropertyMap[unitId] = propDoc.id;
              break;
            }
          }
        }
      } else {
        // Get properties for owner
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
        for (final propId in propertyIds) {
          final unitsSnapshot = await _firestore
              .collection('properties')
              .doc(propId)
              .collection('units')
              .get();
          for (final unitDoc in unitsSnapshot.docs) {
            unitIds.add(unitDoc.id);
            unitToPropertyMap[unitDoc.id] = propId;
          }
        }
      }

      if (unitIds.isEmpty) return {};

      // Step 2: Get bookings using collection group query (NEW STRUCTURE)
      final Map<String, List<BookingModel>> bookingsByUnit = {};

      // Single collection group query instead of batched whereIn
      // PERF-002: Add limit to prevent fetching excessive historical data
      // Firestore index recommendation:
      // Collection: bookings (collection group)
      // Fields: owner_id (asc), check_in (desc)
      final bookingsSnapshot = await _firestore
          .collectionGroup('bookings')
          .where('owner_id', isEqualTo: ownerId)
          .where('check_in', isLessThanOrEqualTo: endDate)
          .orderBy('check_in', descending: true)
          .limit(1000) // Limit to 1000 bookings for the calendar view
          .get()
          .withListFetchTimeout('getCalendarBookings');

      for (final doc in bookingsSnapshot.docs) {
        final booking = BookingModel.fromJson({...doc.data(), 'id': doc.id});

        // Filter by date range and property/unit if specified
        if (booking.checkOut.isBefore(startDate)) continue;
        if (propertyId != null && booking.propertyId != propertyId) continue;
        if (unitId != null && booking.unitId != unitId) continue;

        final bookingUnitId = booking.unitId;
        if (!bookingsByUnit.containsKey(bookingUnitId)) {
          bookingsByUnit[bookingUnitId] = [];
        }
        bookingsByUnit[bookingUnitId]!.add(booking);
      }

      // Step 3: OPTIONAL - Add iCal events as "pseudo-bookings" (Booking.com, Airbnb, etc.)
      if (includeIcalEvents) {
        try {
          await _addIcalEventsToCalendar(
            bookingsByUnit: bookingsByUnit,
            unitIds: unitIds,
            propertyIds: propertyIds,
            unitToPropertyMap: unitToPropertyMap,
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

      // Get current user's owner_id for collection group query
      final userId = _auth.currentUser?.uid;
      if (userId == null) return {};

      // Single collection group query instead of batched whereIn
      // PERF-002: Add limit to prevent fetching excessive historical data
      // Firestore index recommendation:
      // Collection: bookings (collection group)
      // Fields: owner_id (asc), check_in (desc)
      final bookingsSnapshot = await _firestore
          .collectionGroup('bookings')
          .where('owner_id', isEqualTo: userId)
          .where('check_in', isLessThanOrEqualTo: endDate)
          .orderBy('check_in', descending: true)
          .limit(1000) // Limit to 1000 bookings for the calendar view
          .get()
          .withListFetchTimeout('getCalendarBookingsWithUnitIds');

      for (final doc in bookingsSnapshot.docs) {
        final booking = BookingModel.fromJson({...doc.data(), 'id': doc.id});

        // Filter by date range and unit IDs
        if (booking.checkOut.isBefore(startDate)) continue;
        if (!unitIds.contains(booking.unitId)) continue;

        final unitId = booking.unitId;
        if (!bookingsByUnit.containsKey(unitId)) {
          bookingsByUnit[unitId] = [];
        }
        bookingsByUnit[unitId]!.add(booking);
      }

      // Add iCal events if enabled
      if (includeIcalEvents) {
        try {
          // Get property IDs and unit-to-property mapping for iCal events
          final propertyIds = <String>[];
          final unitToPropertyMap = <String, String>{};

          for (final unitId in unitIds) {
            // Find which property this unit belongs to
            final propertiesSnapshot = await _firestore
                .collection('properties')
                .where('owner_id', isEqualTo: userId)
                .get();

            for (final propDoc in propertiesSnapshot.docs) {
              final unitDoc = await _firestore
                  .collection('properties')
                  .doc(propDoc.id)
                  .collection('units')
                  .doc(unitId)
                  .get();
              if (unitDoc.exists) {
                if (!propertyIds.contains(propDoc.id)) {
                  propertyIds.add(propDoc.id);
                }
                unitToPropertyMap[unitId] = propDoc.id;
                break;
              }
            }
          }

          await _addIcalEventsToCalendar(
            bookingsByUnit: bookingsByUnit,
            unitIds: unitIds,
            propertyIds: propertyIds,
            unitToPropertyMap: unitToPropertyMap,
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
    required List<String> propertyIds,
    required Map<String, String> unitToPropertyMap,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Query iCal events from NEW subcollection structure
    // Path: properties/{propertyId}/ical_events
    for (final propertyId in propertyIds) {
      // PERF-002: Add limit to prevent fetching excessive historical data
      // Firestore index recommendation:
      // Collection: ical_events
      // Fields: start_date (desc)
      final icalSnapshot = await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('ical_events')
          .where('start_date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('start_date', descending: true)
          .limit(500) // Limit to 500 iCal events per property
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

          // Skip events for units not in our list
          if (!unitIds.contains(unitId)) {
            continue;
          }

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
            propertyId: propertyId,
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

  /// Helper method to find a booking document by ID
  /// Uses owner_id filter for security (only owner can access their bookings)
  /// IMPORTANT: FieldPath.documentId does NOT work with collectionGroup queries!
  /// Firestore expects full document path, not just ID when using collectionGroup.
  Future<DocumentSnapshot<Map<String, dynamic>>?> _findBookingById(
    String bookingId,
  ) async {
    final userId = _auth.currentUser?.uid;
    debugPrint(
      '[_findBookingById] Looking for booking: $bookingId, user: $userId',
    );
    if (userId == null) {
      debugPrint('[_findBookingById] ERROR: User not authenticated');
      return null;
    }

    // Strategy 1: Query by owner_id (fast, but only works if owner_id field exists)
    debugPrint(
      '[_findBookingById] Strategy 1: collectionGroup query by owner_id',
    );
    final ownerBookingsSnapshot = await _firestore
        .collectionGroup('bookings')
        .where('owner_id', isEqualTo: userId)
        .get();
    debugPrint(
      '[_findBookingById] Strategy 1: Found ${ownerBookingsSnapshot.docs.length} bookings for owner',
    );

    for (final doc in ownerBookingsSnapshot.docs) {
      if (doc.id == bookingId) {
        debugPrint(
          '[_findBookingById] Strategy 1: FOUND booking at path: ${doc.reference.path}',
        );
        return doc;
      }
    }
    debugPrint(
      '[_findBookingById] Strategy 1: Booking NOT found in owner bookings',
    );

    // Strategy 2: Fallback - check legacy top-level bookings collection
    final legacyDoc = await _firestore
        .collection('bookings')
        .doc(bookingId)
        .get();
    if (legacyDoc.exists) {
      // Verify ownership via property lookup
      final data = legacyDoc.data()!;
      final propertyId = data['property_id'] as String?;
      if (propertyId != null) {
        final propertyDoc = await _firestore
            .collection('properties')
            .doc(propertyId)
            .get();
        if (propertyDoc.exists && propertyDoc.data()?['owner_id'] == userId) {
          return legacyDoc;
        }
      }
    }

    // Strategy 3: Last resort - search all bookings in owner's properties
    // This handles edge cases where owner_id might not be set on the booking
    final propertiesSnapshot = await _firestore
        .collection('properties')
        .where('owner_id', isEqualTo: userId)
        .get();

    for (final propDoc in propertiesSnapshot.docs) {
      // Check units subcollection
      final unitsSnapshot = await _firestore
          .collection('properties')
          .doc(propDoc.id)
          .collection('units')
          .get();

      for (final unitDoc in unitsSnapshot.docs) {
        // Check if booking exists in this unit's bookings subcollection
        final bookingDoc = await _firestore
            .collection('properties')
            .doc(propDoc.id)
            .collection('units')
            .doc(unitDoc.id)
            .collection('bookings')
            .doc(bookingId)
            .get();

        if (bookingDoc.exists) {
          return bookingDoc;
        }
      }
    }

    return null;
  }

  /// Get a single booking by ID with property and unit info
  /// Used for deep-links when booking is not in current window
  Future<OwnerBooking?> getOwnerBookingById(String bookingId) async {
    try {
      // Use helper method to find booking (avoids FieldPath.documentId bug)
      final bookingDoc = await _findBookingById(bookingId);

      if (bookingDoc == null || !bookingDoc.exists) return null;

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
      debugPrint('[approveBooking] Starting approval for booking: $bookingId');

      // Find booking using helper method (avoids FieldPath.documentId bug)
      final bookingDoc = await _findBookingById(bookingId);
      debugPrint(
        '[approveBooking] _findBookingById result: ${bookingDoc != null ? 'found' : 'NOT FOUND'}',
      );

      if (bookingDoc == null) {
        debugPrint(
          '[approveBooking] ERROR: Booking not found in any collection',
        );
        throw BookingException('Booking not found', code: 'booking/not-found');
      }

      // Log the document path to verify correct subcollection
      debugPrint(
        '[approveBooking] Document path: ${bookingDoc.reference.path}',
      );
      debugPrint('[approveBooking] Current user: ${_auth.currentUser?.uid}');

      // Update using the found document reference
      debugPrint('[approveBooking] Attempting update...');
      await bookingDoc.reference.update({
        'status': BookingStatus.confirmed.value,
        'approved_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      debugPrint('[approveBooking] Update SUCCESS');
      // Email notification will be sent by onBookingStatusChange Cloud Function
    } catch (e, stackTrace) {
      debugPrint('[approveBooking] ERROR: $e');
      debugPrint('[approveBooking] Stack trace: $stackTrace');
      throw BookingException.approvalFailed(e);
    }
  }

  /// Reject pending booking (owner approval workflow)
  Future<void> rejectBooking(String bookingId, {String? reason}) async {
    try {
      debugPrint('[rejectBooking] Starting rejection for booking: $bookingId');

      // Find booking using helper method (avoids FieldPath.documentId bug)
      final bookingDoc = await _findBookingById(bookingId);
      debugPrint(
        '[rejectBooking] _findBookingById result: ${bookingDoc != null ? 'found' : 'NOT FOUND'}',
      );

      if (bookingDoc == null) {
        debugPrint(
          '[rejectBooking] ERROR: Booking not found in any collection',
        );
        throw BookingException('Booking not found', code: 'booking/not-found');
      }

      // Log the document path to verify correct subcollection
      debugPrint('[rejectBooking] Document path: ${bookingDoc.reference.path}');
      debugPrint('[rejectBooking] Current user: ${_auth.currentUser?.uid}');

      // Update using the found document reference
      debugPrint('[rejectBooking] Attempting update...');
      await bookingDoc.reference.update({
        'status': BookingStatus.cancelled.value,
        'rejection_reason': reason ?? 'Rejected by owner',
        'rejected_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      debugPrint('[rejectBooking] Update SUCCESS');
      // Email notification will be sent by onBookingStatusChange Cloud Function
    } catch (e, stackTrace) {
      debugPrint('[rejectBooking] ERROR: $e');
      debugPrint('[rejectBooking] Stack trace: $stackTrace');
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
      // Find booking using helper method (avoids FieldPath.documentId bug)
      final bookingDoc = await _findBookingById(bookingId);

      if (bookingDoc == null) {
        throw BookingException('Booking not found', code: 'booking/not-found');
      }

      // Update using the found document reference
      await bookingDoc.reference.update({
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
      // Find booking using helper method (avoids FieldPath.documentId bug)
      final bookingDoc = await _findBookingById(bookingId);

      if (bookingDoc == null) {
        throw BookingException('Booking not found', code: 'booking/not-found');
      }

      // Update using the found document reference
      await bookingDoc.reference.update({
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
      // Find booking using helper method (avoids FieldPath.documentId bug)
      final bookingDoc = await _findBookingById(bookingId);

      if (bookingDoc == null) {
        throw BookingException('Booking not found', code: 'booking/not-found');
      }

      // Update using the found document reference
      await bookingDoc.reference.update({
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
      // Find booking using helper method (avoids FieldPath.documentId bug)
      final bookingDoc = await _findBookingById(bookingId);

      if (bookingDoc == null) {
        throw BookingException('Booking not found', code: 'booking/not-found');
      }

      // Delete using the found document reference
      await bookingDoc.reference.delete();
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

    // Get current user's owner_id
    final userId = _auth.currentUser?.uid;
    if (userId == null) return 0;

    // NEW STRUCTURE: Single collection group count query (no batching!)
    final countQuery = await _firestore
        .collectionGroup('bookings')
        .where('owner_id', isEqualTo: userId)
        .where('status', isEqualTo: status.name)
        .count()
        .get();

    // Filter by unitIds client-side if needed (count doesn't support array-contains)
    // For now, return total count - caller can filter if needed
    return countQuery.count ?? 0;
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

      // NEW STRUCTURE: Single collection group query (no batching!)
      Query<Map<String, dynamic>> query = _firestore
          .collectionGroup('bookings')
          .where('owner_id', isEqualTo: ownerId)
          .orderBy('created_at', descending: true)
          .limit(limit + 1); // Fetch limit + 1 to check if there are more

      // Apply filters
      if (status != null) {
        query = query.where('status', isEqualTo: status.value);
      }

      // Apply cursor
      if (startAfterDocument != null) {
        query = query.startAfterDocument(startAfterDocument);
      }

      final snapshot = await query.get().withListFetchTimeout(
        'getOwnerBookingsPaginated',
      );

      // Check if there are more pages
      final hasMore = snapshot.docs.length > limit;
      final pageDocs = snapshot.docs.take(limit).toList();
      final lastDoc = pageDocs.isNotEmpty ? pageDocs.last : null;

      // Parse bookings and apply client-side filters
      final List<BookingModel> bookings = [];
      for (final doc in pageDocs) {
        try {
          final booking = BookingModel.fromJson({
            ...(doc.data()),
            'id': doc.id,
          });

          // Client-side filtering by unit IDs, property, and dates
          if (!filteredUnitIds.contains(booking.unitId)) continue;
          if (propertyId != null && booking.propertyId != propertyId) continue;
          if (startDate != null && booking.checkIn.isBefore(startDate)) {
            continue;
          }
          if (endDate != null && booking.checkOut.isAfter(endDate)) continue;

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

      // NEW STRUCTURE: Use collection group query with endBeforeDocument cursor
      Query<Map<String, dynamic>> query = _firestore
          .collectionGroup('bookings')
          .where('owner_id', isEqualTo: ownerId)
          .orderBy('created_at', descending: true)
          .endBeforeDocument(endBeforeDocument)
          .limitToLast(limit + 1); // Fetch limit + 1 to check if there are more

      if (status != null) {
        query = query.where('status', isEqualTo: status.value);
      }

      final snapshot = await query.get();

      // Check if there are more items above
      final hasMoreTop = snapshot.docs.length > limit;
      final beforeCursorDocs = snapshot.docs.take(limit).toList();

      // Parse bookings and apply client-side filters
      final List<BookingModel> bookings = [];
      for (final doc in beforeCursorDocs) {
        try {
          final booking = BookingModel.fromJson({
            ...(doc.data()),
            'id': doc.id,
          });

          // Client-side filtering
          if (!filteredUnitIds.contains(booking.unitId)) continue;
          if (propertyId != null && booking.propertyId != propertyId) continue;
          if (startDate != null && booking.checkIn.isBefore(startDate)) {
            continue;
          }
          if (endDate != null && booking.checkOut.isAfter(endDate)) continue;

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
        .get(); // 1 QUERY

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
            .get(); // 1 QUERY per property (max ~5 for typical owner)

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
            .get(); // 1 QUERY for up to 30 users

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
    ]).withListFetchTimeout('getDashboardStatsData');

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
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    final List<BookingModel> allBookings = [];

    // NEW STRUCTURE: Single collection group query per status (no batching!)
    for (final status in statuses) {
      final query = _firestore
          .collectionGroup('bookings')
          .where('owner_id', isEqualTo: userId)
          .where('status', isEqualTo: status.value)
          .where(
            'created_at',
            isGreaterThanOrEqualTo: Timestamp.fromDate(createdAfter),
          )
          .orderBy('created_at', descending: true)
          .limit(limit);

      final snapshot = await query.get().withBookingFetchTimeout(
        '_queryBookingsForStats',
      );
      for (final doc in snapshot.docs) {
        try {
          final booking = BookingModel.fromJson({
            ...(doc.data()),
            'id': doc.id,
          });
          // Filter by unitIds client-side
          if (unitIds.contains(booking.unitId)) {
            allBookings.add(booking);
          }
        } catch (_) {
          // Skip invalid bookings
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
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    final List<BookingModel> allBookings = [];

    // NEW STRUCTURE: Single collection group query per status (no batching!)
    for (final status in [BookingStatus.confirmed, BookingStatus.pending]) {
      final query = _firestore
          .collectionGroup('bookings')
          .where('owner_id', isEqualTo: userId)
          .where('status', isEqualTo: status.value)
          .where(
            'check_in',
            isGreaterThanOrEqualTo: Timestamp.fromDate(checkInAfter),
          )
          .where('check_in', isLessThan: Timestamp.fromDate(checkInBefore))
          .limit(limit);

      final snapshot = await query.get().withBookingFetchTimeout(
        '_queryUpcomingCheckIns',
      );
      for (final doc in snapshot.docs) {
        try {
          final booking = BookingModel.fromJson({
            ...(doc.data()),
            'id': doc.id,
          });
          // Filter by unitIds client-side
          if (unitIds.contains(booking.unitId)) {
            allBookings.add(booking);
          }
        } catch (_) {
          // Skip invalid bookings
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
        .get(); // 1 QUERY

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
            .get(); // 1 QUERY per property (max ~5 for typical owner)

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
            .get(); // 1 QUERY for up to 30 users

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
