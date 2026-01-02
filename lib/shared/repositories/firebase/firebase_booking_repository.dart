import 'package:cloud_firestore/cloud_firestore.dart';
import '../booking_repository.dart';
import '../../models/booking_model.dart';
import '../../../core/constants/enums.dart';

class FirebaseBookingRepository implements BookingRepository {
  final FirebaseFirestore _firestore;

  FirebaseBookingRepository(this._firestore);

  @override
  Future<List<BookingModel>> fetchUnitBookings(String unitId) async {
    final snapshot = await _firestore
        .collection('bookings')
        .where('unit_id', isEqualTo: unitId)
        .get();
    return snapshot.docs
        .map((doc) => BookingModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  @override
  Future<BookingModel?> fetchBookingById(String id) async {
    final doc = await _firestore.collection('bookings').doc(id).get();
    if (!doc.exists) return null;
    return BookingModel.fromJson({...doc.data()!, 'id': doc.id});
  }

  @override
  Future<BookingModel> createBooking(BookingModel booking) async {
    final docRef = await _firestore.collection('bookings').add(booking.toJson());
    return booking.copyWith(id: docRef.id);
  }

  @override
  Future<BookingModel> updateBooking(BookingModel booking) async {
    await _firestore.collection('bookings').doc(booking.id).update(booking.toJson());
    return booking;
  }

  @override
  Future<void> deleteBooking(String id) async {
    await _firestore.collection('bookings').doc(id).delete();
  }

  @override
  Future<List<BookingModel>> fetchUserBookings(String userId) async {
    final snapshot = await _firestore
        .collection('bookings')
        .where('user_id', isEqualTo: userId)
        .get();
    return snapshot.docs
        .map((doc) => BookingModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  @override
  Future<List<BookingModel>> fetchPropertyBookings(String propertyId) async {
    final snapshot = await _firestore
        .collection('bookings')
        .where('property_id', isEqualTo: propertyId)
        .get();
    return snapshot.docs
        .map((doc) => BookingModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  @override
  Future<BookingModel> updateBookingStatus(String id, BookingStatus status) async {
    // Optimization: Use a direct update instead of a "read-modify-write" pattern.
    // This is more efficient (fewer reads) and prevents race conditions.
    // FieldValue.serverTimestamp() ensures data consistency across clients.
    final updateData = {
      'status': status.value,
      'updated_at': FieldValue.serverTimestamp(),
    };

    final docRef = _firestore.collection('bookings').doc(id);
    await docRef.update(updateData);

    // Return the updated model by fetching it again to ensure we have the canonical server state.
    final updatedDoc = await docRef.get();
    return BookingModel.fromJson({...updatedDoc.data()!, 'id': updatedDoc.id});
  }

  @override
  Future<BookingModel> cancelBooking(String id, String reason) async {
    // Optimization: Use a direct update for atomicity and efficiency.
    final updateData = {
      'status': BookingStatus.cancelled.value,
      'cancellation_reason': reason,
      'cancelled_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };

    final docRef = _firestore.collection('bookings').doc(id);
    await docRef.update(updateData);

    // Return the updated model by fetching it again
    final updatedDoc = await docRef.get();
    return BookingModel.fromJson({...updatedDoc.data()!, 'id': updatedDoc.id});
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
    final snapshot = await _firestore
        .collection('bookings')
        .where('unit_id', isEqualTo: unitId)
        .where('status', whereIn: [
          BookingStatus.pending.value,
          BookingStatus.confirmed.value,
          BookingStatus.inProgress.value,
        ])
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
    // Firestore doesn't allow range queries on multiple fields
    // So we query by equality fields only and filter in memory
    var query = _firestore.collection('bookings') as Query<Map<String, dynamic>>;

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
    final snapshot = await _firestore
        .collection('bookings')
        .where('user_id', isEqualTo: userId)
        .where('status', isEqualTo: status.value)
        .get();

    return snapshot.docs
        .map((doc) => BookingModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  @override
  Future<List<BookingModel>> getUpcomingBookings(String userId) async {
    final now = DateTime.now();
    final snapshot = await _firestore
        .collection('bookings')
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
    final snapshot = await _firestore
        .collection('bookings')
        .where('user_id', isEqualTo: userId)
        .get();

    final bookings = snapshot.docs
        .map((doc) => BookingModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();

    return bookings.where((booking) => booking.isCurrent).toList();
  }

  @override
  Future<List<BookingModel>> getPastBookings(String userId) async {
    final now = DateTime.now();
    final snapshot = await _firestore
        .collection('bookings')
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
    final snapshot = await _firestore
        .collection('bookings')
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
    // Optimization: Use a direct update for atomicity and efficiency.
    final updateData = <String, dynamic>{
      'paid_amount': paidAmount,
      'payment_intent_id': paymentIntentId,
      'updated_at': FieldValue.serverTimestamp(),
    };

    final docRef = _firestore.collection('bookings').doc(bookingId);
    await docRef.update(updateData);

    // Return the updated model by fetching it again
    final updatedDoc = await docRef.get();
    return BookingModel.fromJson({...updatedDoc.data()!, 'id': updatedDoc.id});
  }

  @override
  Future<BookingModel> completeBookingPayment(String bookingId) async {
    final doc = await _firestore.collection('bookings').doc(bookingId).get();
    if (!doc.exists) throw Exception('Booking not found');

    final booking = BookingModel.fromJson({...doc.data()!, 'id': doc.id});
    final completed = booking.copyWith(
      paidAmount: booking.totalPrice,
      paymentStatus: 'paid',
      status: BookingStatus.confirmed,
      updatedAt: DateTime.now(),
    );

    await _firestore.collection('bookings').doc(bookingId).update(completed.toJson());
    return completed;
  }
}
