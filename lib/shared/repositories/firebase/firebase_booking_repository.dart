import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/exceptions/app_exceptions.dart';
import '../booking_repository.dart';
import '../../models/booking_model.dart';
import '../../../core/constants/enums.dart';

class FirebaseBookingRepository implements BookingRepository {
  final FirebaseFirestore _firestore;

  FirebaseBookingRepository(this._firestore);

  @override
  Future<List<BookingModel>> fetchUnitBookings(String unitId) async {
    // NEW STRUCTURE: Use collection group query to find bookings across all units
    // SECURITY: Must include 'status' filter to match Firestore rules Case 3
    // (rules require unit_id + status for widget/export queries)
    //
    // Fetches confirmed, pending, and completed bookings (excludes cancelled)
    // This covers all "active" bookings needed for:
    // - iCal export (visible to external calendars)
    // - Availability checking
    // - Calendar display
    final snapshot = await _firestore
        .collectionGroup('bookings')
        .where('unit_id', isEqualTo: unitId)
        .where(
          'status',
          whereIn: [
            BookingStatus.pending.value,
            BookingStatus.confirmed.value,
            BookingStatus.completed.value,
          ],
        )
        .get();
    return snapshot.docs
        .map((doc) => BookingModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  @override
  Future<BookingModel?> fetchBookingById(String id, {String? unitId}) async {
    // IMPORTANT: FieldPath.documentId does NOT work with collectionGroup queries!
    // Firestore expects full document path, not just ID when using collectionGroup.
    //
    // Strategy:
    // 1. Try legacy top-level collection first (fastest)
    // 2. If unitId is provided, query subcollection directly
    // 3. Fall back to collection group search (least efficient)

    // Try legacy top-level collection first
    final legacyDoc = await _firestore.collection('bookings').doc(id).get();
    if (legacyDoc.exists) {
      return BookingModel.fromJson({...legacyDoc.data()!, 'id': legacyDoc.id});
    }

    // If unitId provided, we can try a more targeted search
    if (unitId != null) {
      // Query bookings for this unit and find by ID
      final unitBookings = await _firestore
          .collectionGroup('bookings')
          .where('unit_id', isEqualTo: unitId)
          .get();
      for (final doc in unitBookings.docs) {
        if (doc.id == id) {
          return BookingModel.fromJson({...doc.data(), 'id': doc.id});
        }
      }
    }

    // Fall back: Search through collection group (least efficient)
    // This queries all bookings - use sparingly
    final snapshot = await _firestore.collectionGroup('bookings').get();

    for (final doc in snapshot.docs) {
      if (doc.id == id) {
        return BookingModel.fromJson({...doc.data(), 'id': doc.id});
      }
    }
    return null;
  }

  @override
  Future<BookingModel?> fetchBookingByStripeSessionId(String sessionId) async {
    // NEW STRUCTURE: Use collection group query
    final snapshot = await _firestore
        .collectionGroup('bookings')
        .where('stripe_session_id', isEqualTo: sessionId)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return BookingModel.fromJson({...doc.data(), 'id': doc.id});
  }

  @override
  Future<BookingModel> createBooking(BookingModel booking) async {
    // NEW STRUCTURE: Create in subcollection path
    // properties/{propertyId}/units/{unitId}/bookings/{bookingId}
    final docRef = await _firestore
        .collection('properties')
        .doc(booking.propertyId)
        .collection('units')
        .doc(booking.unitId)
        .collection('bookings')
        .add(booking.toJson());

    return booking.copyWith(id: docRef.id);
  }

  @override
  Future<BookingModel> updateBooking(BookingModel booking) async {
    // First, fetch the existing booking to check if unit changed
    final existingBooking = await fetchBookingById(booking.id);

    if (existingBooking == null) {
      throw BookingException('Booking not found', code: 'booking/not-found');
    }

    // Check if unit has changed (move to different unit)
    if (existingBooking.unitId != booking.unitId) {
      // UNIT CHANGED: Need to delete from old path and create at new path
      // Use a batch to ensure atomicity
      final batch = _firestore.batch();

      // Delete from old location
      final oldRef = _firestore
          .collection('properties')
          .doc(existingBooking.propertyId)
          .collection('units')
          .doc(existingBooking.unitId)
          .collection('bookings')
          .doc(booking.id);
      batch.delete(oldRef);

      // Create at new location (keeping same document ID)
      final newRef = _firestore
          .collection('properties')
          .doc(booking.propertyId)
          .collection('units')
          .doc(booking.unitId)
          .collection('bookings')
          .doc(booking.id);
      batch.set(newRef, booking.toJson());

      await batch.commit();
      return booking;
    }

    // SAME UNIT: Simple update in place
    await _firestore
        .collection('properties')
        .doc(booking.propertyId)
        .collection('units')
        .doc(booking.unitId)
        .collection('bookings')
        .doc(booking.id)
        .update(booking.toJson());
    return booking;
  }

  @override
  Future<void> deleteBooking(String id) async {
    // NEW STRUCTURE: First find the booking to get propertyId and unitId
    final booking = await fetchBookingById(id);
    if (booking == null) {
      throw BookingException('Booking not found', code: 'booking/not-found');
    }

    await _firestore
        .collection('properties')
        .doc(booking.propertyId)
        .collection('units')
        .doc(booking.unitId)
        .collection('bookings')
        .doc(id)
        .delete();
  }

  @override
  Future<List<BookingModel>> fetchUserBookings(String userId) async {
    // NEW STRUCTURE: Use collection group query
    final snapshot = await _firestore
        .collectionGroup('bookings')
        .where('user_id', isEqualTo: userId)
        .get();
    return snapshot.docs
        .map((doc) => BookingModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  @override
  Future<List<BookingModel>> fetchPropertyBookings(String propertyId) async {
    // NEW STRUCTURE: Use collection group query
    final snapshot = await _firestore
        .collectionGroup('bookings')
        .where('property_id', isEqualTo: propertyId)
        .get();
    return snapshot.docs
        .map((doc) => BookingModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  @override
  Future<BookingModel> updateBookingStatus(
    String id,
    BookingStatus status,
  ) async {
    // NEW STRUCTURE: Fetch booking first to get path
    final booking = await fetchBookingById(id);
    if (booking == null) {
      throw BookingException('Booking not found', code: 'booking/not-found');
    }

    final updated = booking.copyWith(status: status, updatedAt: DateTime.now());

    await _firestore
        .collection('properties')
        .doc(booking.propertyId)
        .collection('units')
        .doc(booking.unitId)
        .collection('bookings')
        .doc(id)
        .update(updated.toJson());
    return updated;
  }

  @override
  Future<BookingModel> cancelBooking(String id, String reason) async {
    // NEW STRUCTURE: Fetch booking first to get path
    final booking = await fetchBookingById(id);
    if (booking == null) {
      throw BookingException('Booking not found', code: 'booking/not-found');
    }

    final cancelled = booking.copyWith(
      status: BookingStatus.cancelled,
      cancellationReason: reason,
      cancelledAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestore
        .collection('properties')
        .doc(booking.propertyId)
        .collection('units')
        .doc(booking.unitId)
        .collection('bookings')
        .doc(id)
        .update(cancelled.toJson());
    return cancelled;
  }

  @override
  Future<bool> areDatesAvailable({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
    String? excludeBookingId,
  }) async {
    final overlapping = await getOverlappingBookings(
      unitId: unitId,
      checkIn: checkIn,
      checkOut: checkOut,
    );

    if (excludeBookingId != null) {
      return overlapping.where((b) => b.id != excludeBookingId).isEmpty;
    }

    return overlapping.isEmpty;
  }

  @override
  Future<List<BookingModel>> getOverlappingBookings({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    // NEW STRUCTURE: Use collection group query
    final snapshot = await _firestore
        .collectionGroup('bookings')
        .where('unit_id', isEqualTo: unitId)
        .where(
          'status',
          whereIn: [
            BookingStatus.pending.value,
            BookingStatus.confirmed.value,
            BookingStatus.completed.value,
          ],
        )
        .get();

    final bookings = snapshot.docs
        .map((doc) => BookingModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();

    return bookings.where((booking) {
      return booking.overlapsWithDates(checkIn, checkOut);
    }).toList();
  }

  @override
  Future<List<BookingModel>> getBookingsInRange({
    String? userId,
    String? unitId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // NEW STRUCTURE: Use collection group query
    // Firestore doesn't allow range queries on multiple fields
    // So we query by equality fields only and filter in memory
    Query<Map<String, dynamic>> query = _firestore.collectionGroup('bookings');

    if (userId != null) {
      query = query.where('user_id', isEqualTo: userId);
    }

    if (unitId != null) {
      query = query.where('unit_id', isEqualTo: unitId);
    }

    final snapshot = await query.get();
    var bookings = snapshot.docs
        .map((doc) => BookingModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();

    // Filter by date range in memory
    if (startDate != null || endDate != null) {
      bookings = bookings.where((booking) {
        if (startDate != null && booking.checkOut.isBefore(startDate)) {
          return false;
        }
        if (endDate != null && booking.checkIn.isAfter(endDate)) {
          return false;
        }
        return true;
      }).toList();
    }

    return bookings;
  }

  @override
  Future<List<BookingModel>> getBookingsByStatus({
    required String userId,
    required BookingStatus status,
  }) async {
    // NEW STRUCTURE: Use collection group query
    final snapshot = await _firestore
        .collectionGroup('bookings')
        .where('user_id', isEqualTo: userId)
        .where('status', isEqualTo: status.value)
        .get();

    return snapshot.docs
        .map((doc) => BookingModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  @override
  Future<List<BookingModel>> getUpcomingBookings(String userId) async {
    // NEW STRUCTURE: Use collection group query
    final now = DateTime.now();
    final snapshot = await _firestore
        .collectionGroup('bookings')
        .where('user_id', isEqualTo: userId)
        .where('check_in', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('check_in')
        .get();

    return snapshot.docs
        .map((doc) => BookingModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  @override
  Future<List<BookingModel>> getCurrentBookings(String userId) async {
    // NEW STRUCTURE: Use collection group query
    final snapshot = await _firestore
        .collectionGroup('bookings')
        .where('user_id', isEqualTo: userId)
        .get();

    final bookings = snapshot.docs
        .map((doc) => BookingModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();

    return bookings.where((booking) => booking.isCurrent).toList();
  }

  @override
  Future<List<BookingModel>> getPastBookings(String userId) async {
    // NEW STRUCTURE: Use collection group query
    final now = DateTime.now();
    final snapshot = await _firestore
        .collectionGroup('bookings')
        .where('user_id', isEqualTo: userId)
        .where('check_out', isLessThan: Timestamp.fromDate(now))
        .orderBy('check_out', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => BookingModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  @override
  Future<List<BookingModel>> getOwnerBookings(String ownerId) async {
    // NEW STRUCTURE: Use collection group query
    // NO MORE whereIn batching needed! This is the big win!
    final snapshot = await _firestore
        .collectionGroup('bookings')
        .where('owner_id', isEqualTo: ownerId)
        .orderBy('created_at', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => BookingModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  @override
  Future<BookingModel> updateBookingPayment({
    required String bookingId,
    required double paidAmount,
    String? paymentIntentId,
  }) async {
    // NEW STRUCTURE: Fetch booking first to get path
    final booking = await fetchBookingById(bookingId);
    if (booking == null) {
      throw BookingException('Booking not found', code: 'booking/not-found');
    }

    final updated = booking.copyWith(
      paidAmount: paidAmount,
      paymentIntentId: paymentIntentId,
      updatedAt: DateTime.now(),
    );

    await _firestore
        .collection('properties')
        .doc(booking.propertyId)
        .collection('units')
        .doc(booking.unitId)
        .collection('bookings')
        .doc(bookingId)
        .update(updated.toJson());
    return updated;
  }

  @override
  Future<BookingModel> completeBookingPayment(String bookingId) async {
    // NEW STRUCTURE: Fetch booking first to get path
    final booking = await fetchBookingById(bookingId);
    if (booking == null) {
      throw BookingException('Booking not found', code: 'booking/not-found');
    }

    final completed = booking.copyWith(
      paidAmount: booking.totalPrice,
      paymentStatus: 'paid',
      status: BookingStatus.confirmed,
      updatedAt: DateTime.now(),
    );

    await _firestore
        .collection('properties')
        .doc(booking.propertyId)
        .collection('units')
        .doc(booking.unitId)
        .collection('bookings')
        .doc(bookingId)
        .update(completed.toJson());
    return completed;
  }
}
