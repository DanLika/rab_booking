import '../models/booking_model.dart';
import '../../features/booking/domain/models/booking_status.dart';

/// Abstract booking repository interface
abstract class BookingRepository {
  /// Create new booking
  Future<BookingModel> createBooking(BookingModel booking);

  /// Get booking by ID
  Future<BookingModel?> fetchBookingById(String id);

  /// Get bookings by guest user ID
  Future<List<BookingModel>> fetchUserBookings(String userId);

  /// Get bookings by unit ID
  Future<List<BookingModel>> fetchUnitBookings(String unitId);

  /// Get bookings by property ID (all units)
  Future<List<BookingModel>> fetchPropertyBookings(String propertyId);

  /// Update booking
  Future<BookingModel> updateBooking(BookingModel booking);

  /// Update booking status
  Future<BookingModel> updateBookingStatus(String id, BookingStatus status);

  /// Cancel booking
  Future<BookingModel> cancelBooking(String id, String reason);

  /// Delete booking (admin only)
  Future<void> deleteBooking(String id);

  /// Check if dates are available for unit
  Future<bool> areDatesAvailable({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
    String? excludeBookingId,
  });

  /// Get overlapping bookings for unit and date range
  Future<List<BookingModel>> getOverlappingBookings({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
  });

  /// Get upcoming bookings for user
  Future<List<BookingModel>> getUpcomingBookings(String userId);

  /// Get past bookings for user
  Future<List<BookingModel>> getPastBookings(String userId);

  /// Get current bookings for user (currently staying)
  Future<List<BookingModel>> getCurrentBookings(String userId);

  /// Get bookings by status
  Future<List<BookingModel>> getBookingsByStatus({
    required String userId,
    required BookingStatus status,
  });

  /// Get bookings for owner (all properties)
  Future<List<BookingModel>> getOwnerBookings(String ownerId);

  /// Update booking payment
  Future<BookingModel> updateBookingPayment({
    required String bookingId,
    required double paidAmount,
    String? paymentIntentId,
  });

  /// Complete booking payment
  Future<BookingModel> completeBookingPayment(String bookingId);

  /// Get bookings within date range
  Future<List<BookingModel>> getBookingsInRange({
    String? userId,
    String? unitId,
    DateTime? startDate,
    DateTime? endDate,
  });
}
