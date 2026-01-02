import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rab_booking/features/widget/domain/errors/booking_errors.dart';
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
    try {
      final docRef = await _firestore.collection('bookings').add(booking.toJson());
      return booking.copyWith(id: docRef.id);
    } on FirebaseException catch (e) {
      // Log the original error for debugging
      print('FirebaseException during booking creation: ${e.message}');
      // Throw a custom, user-friendly exception
      throw BookingCreationException(
        'We could not save your booking. Please check your internet connection and try again.',
      );
    } catch (e) {
      // Catch any other unexpected errors
      print('Unexpected error during booking creation: $e');
      throw BookingCreationException(
        'An unexpected error occurred. Please try again later.',
      );
    }
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
    final doc = await _firestore.collection('bookings').doc(id).get();
    if (!doc.exists) throw Exception('Booking not found');

    final booking = BookingModel.fromJson({...doc.data()!, 'id': doc.id});
    final updated = booking.copyWith(
      status: status,
      updatedAt: DateTime.now(),
    );

    await _firestore.collection('bookings').doc(id).update(updated.toJson());
    return updated;
  }

  @override
  Future<BookingModel> cancelBooking(String id, String reason) async {
    final doc = await _firestore.collection('bookings').doc(id).get();
    if (!doc.exists) throw Exception('Booking not found');

    final booking = BookingModel.fromJson({...doc.data()!, 'id': doc.id});
    final cancelled = booking.copyWith(
      status: BookingStatus.cancelled,
      cancellationReason: reason,
      cancelledAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestore.collection('bookings').doc(id).update(cancelled.toJson());
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
    final doc = await _firestore.collection('bookings').doc(bookingId).get();
    if (!doc.exists) throw Exception('Booking not found');

    final booking = BookingModel.fromJson({...doc.data()!, 'id': doc.id});
    final updated = booking.copyWith(
      paidAmount: paidAmount,
      paymentIntentId: paymentIntentId,
      updatedAt: DateTime.now(),
    );

    await _firestore.collection('bookings').doc(bookingId).update(updated.toJson());
    return updated;
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
