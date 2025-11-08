import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../shared/models/booking_model.dart';
import '../../../../shared/models/property_model.dart';
import '../../../../shared/models/unit_model.dart';
import '../../../../core/constants/enums.dart';
import '../../../widget/domain/models/payment_option.dart';

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

/// Firebase implementation of Owner Bookings Repository
class FirebaseOwnerBookingsRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirebaseOwnerBookingsRepository(this._firestore, this._auth);

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
      if (userId == null) throw Exception('User not authenticated');

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
            final unit = UnitModel.fromJson({...unitDoc.data()!, 'id': unitDoc.id});
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
        bookings.addAll(
          bookingsSnapshot.docs.map(
            (doc) => BookingModel.fromJson({...doc.data(), 'id': doc.id}),
          ),
        );
      }

      // Step 4: Get properties data
      final Map<String, PropertyModel> propertiesMap = {};
      final uniquePropertyIds = unitToPropertyMap.values.toSet().toList();
      for (int i = 0; i < uniquePropertyIds.length; i += 10) {
        final batch = uniquePropertyIds.skip(i).take(10).toList();
        for (final propId in batch) {
          final propDoc = await _firestore.collection('properties').doc(propId).get();
          if (propDoc.exists) {
            propertiesMap[propId] = PropertyModel.fromJson({...propDoc.data()!, 'id': propDoc.id});
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
        final userData = booking.userId != null ? usersMap[booking.userId] : null;
        final guestName = booking.guestName ??
            (userData != null
                ? '${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}'.trim()
                : 'Unknown Guest');
        final guestEmail = booking.guestEmail ??
            (userData?['email'] as String?) ??
            '';
        final guestPhone = booking.guestPhone ?? (userData?['phone'] as String?);

        ownerBookings.add(OwnerBooking(
          booking: booking,
          property: property,
          unit: unit,
          guestName: guestName.isEmpty ? 'Unknown Guest' : guestName,
          guestEmail: guestEmail,
          guestPhone: guestPhone,
        ));
      }

      // Sort by check-in date descending
      ownerBookings.sort((a, b) => b.booking.checkIn.compareTo(a.booking.checkIn));

      return ownerBookings;
    } catch (e) {
      throw Exception('Failed to fetch owner bookings: $e');
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
          print('⚠️ iCal events query failed (non-critical): $icalError');
        }
      }

      // Sort bookings by check-in date
      for (final unitId in bookingsByUnit.keys) {
        bookingsByUnit[unitId]!.sort((a, b) => a.checkIn.compareTo(b.checkIn));
      }

      return bookingsByUnit;
    } catch (e) {
      throw Exception('Failed to fetch calendar bookings: $e');
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
          final source = data['source'] as String? ?? 'ical';
          final guestName = data['guest_name'] as String? ?? 'External Booking';

          // Create pseudo-BookingModel for iCal event
          // Using special ID prefix 'ical_' to distinguish from regular bookings
          final pseudoBooking = BookingModel(
            id: 'ical_${doc.id}', // Special prefix to identify iCal bookings
            unitId: unitId,
            userId: null, // External bookings have no user
            checkIn: eventStartDate,
            checkOut: eventEndDate,
            guestCount: 1,
            totalPrice: 0.0, // External bookings don't have price in our system
            paidAmount: 0.0,
            status: BookingStatus.confirmed, // Always show as confirmed
            paymentMethod: 'on_place', // External bookings payment tracked elsewhere
            guestName: '$guestName ($source)', // e.g., "Booking.com Guest (booking_com)"
            guestEmail: null, // External bookings don't have email
            guestPhone: null,
            notes: 'Imported from $source via iCal sync',
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
          print('⚠️ Failed to parse iCal event ${doc.id}: $parseError');
        }
      }
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
      throw Exception('Failed to approve booking: $e');
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
      throw Exception('Failed to reject booking: $e');
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
      throw Exception('Failed to confirm booking: $e');
    }
  }

  /// Cancel booking with reason
  /// Note: Cancellation email is automatically sent by onBookingStatusChange Cloud Function trigger
  Future<void> cancelBooking(String bookingId, String reason, {bool sendEmail = true}) async {
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
      throw Exception('Failed to cancel booking: $e');
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
      throw Exception('Failed to complete booking: $e');
    }
  }

  /// Permanently delete booking
  Future<void> deleteBooking(String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).delete();
    } catch (e) {
      throw Exception('Failed to delete booking: $e');
    }
  }

  /// Block dates for a unit (create blocked booking)
  Future<void> blockDates({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
    String? reason,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      await _firestore.collection('bookings').add({
        'unit_id': unitId,
        'user_id': userId, // Owner blocks their own dates
        'check_in': Timestamp.fromDate(checkIn),
        'check_out': Timestamp.fromDate(checkOut),
        'status': BookingStatus.blocked.value,
        'total_price': 0.0,
        'paid_amount': 0.0,
        'guest_count': 0,
        'notes': reason ?? 'Blocked by owner',
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to block dates: $e');
    }
  }

  /// Unblock dates (delete blocked booking)
  Future<void> unblockDates(String bookingId) async {
    try {
      final doc = await _firestore.collection('bookings').doc(bookingId).get();
      if (doc.exists) {
        final data = doc.data()!;
        if (data['status'] == BookingStatus.blocked.value) {
          await _firestore.collection('bookings').doc(bookingId).delete();
        } else {
          throw Exception('Booking is not blocked');
        }
      }
    } catch (e) {
      throw Exception('Failed to unblock dates: $e');
    }
  }
}
