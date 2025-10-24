import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/booking_repository.dart';
import '../../domain/models/booking.dart';

/// Provider za Booking Repository
final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository(Supabase.instance.client);
});

/// Provider za pojedinačnu rezervaciju
final bookingProvider =
    FutureProvider.family<Booking?, String>((ref, bookingId) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getBookingById(bookingId);
});

/// Stream provider za pojedinačnu rezervaciju (real-time)
final bookingStreamProvider =
    StreamProvider.family<Booking?, String>((ref, bookingId) {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.watchBooking(bookingId);
});

/// Provider za rezervacije određene jedinice
final unitBookingsProvider =
    FutureProvider.family<List<Booking>, String>((ref, unitId) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getBookingsByUnit(unitId);
});

/// Stream provider za rezervacije određene jedinice (real-time)
final unitBookingsStreamProvider =
    StreamProvider.family<List<Booking>, String>((ref, unitId) {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.watchBookingsByUnit(unitId);
});

/// Provider za rezervacije vlasnika
final ownerBookingsProvider =
    FutureProvider.family<List<Booking>, String>((ref, ownerId) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getBookingsByOwner(ownerId);
});

/// State Notifier za upravljanje booking operacijama
class BookingNotifier extends StateNotifier<AsyncValue<Booking?>> {
  final BookingRepository _repository;

  BookingNotifier(this._repository) : super(const AsyncValue.loading());

  /// Kreira novu rezervaciju
  Future<Booking> createBooking(Booking booking) async {
    state = const AsyncValue.loading();

    try {
      final createdBooking = await _repository.createBooking(booking);
      state = AsyncValue.data(createdBooking);
      return createdBooking;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Učitava rezervaciju
  Future<void> loadBooking(String bookingId) async {
    state = const AsyncValue.loading();

    try {
      final booking = await _repository.getBookingById(bookingId);
      state = AsyncValue.data(booking);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Ažurira status rezervacije
  Future<Booking> updateStatus(
    String bookingId,
    String status, {
    String? cancellationReason,
  }) async {
    try {
      final updatedBooking = await _repository.updateBookingStatus(
        bookingId,
        status,
        cancellationReason: cancellationReason,
      );
      state = AsyncValue.data(updatedBooking);
      return updatedBooking;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Ažurira payment status
  Future<Booking> updatePaymentStatus(
    String bookingId,
    String paymentStatus, {
    double? paidAmount,
    String? paymentIntentId,
  }) async {
    try {
      final updatedBooking = await _repository.updatePaymentStatus(
        bookingId,
        paymentStatus,
        paidAmount: paidAmount,
        paymentIntentId: paymentIntentId,
      );
      state = AsyncValue.data(updatedBooking);
      return updatedBooking;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Potvrđuje rezervaciju
  Future<Booking> confirmBooking(String bookingId) async {
    return updateStatus(bookingId, 'confirmed');
  }

  /// Otkazuje rezervaciju
  Future<Booking> cancelBooking(
    String bookingId,
    String cancellationReason,
  ) async {
    return updateStatus(
      bookingId,
      'cancelled',
      cancellationReason: cancellationReason,
    );
  }

  /// Označava da je avans plaćen
  Future<Booking> markAdvancePaid(
    String bookingId,
    double advanceAmount,
  ) async {
    return updatePaymentStatus(
      bookingId,
      'advance_paid',
      paidAmount: advanceAmount,
    );
  }

  /// Označava da je cijela suma plaćena
  Future<Booking> markFullyPaid(
    String bookingId,
    double totalPrice,
  ) async {
    return updatePaymentStatus(
      bookingId,
      'fully_paid',
      paidAmount: totalPrice,
    );
  }
}

/// Provider za Booking Notifier
final bookingNotifierProvider =
    StateNotifierProvider<BookingNotifier, AsyncValue<Booking?>>((ref) {
  final repository = ref.watch(bookingRepositoryProvider);
  return BookingNotifier(repository);
});

/// Provider za provjeru dostupnosti
final checkAvailabilityProvider = FutureProvider.family<bool,
    ({String unitId, DateTime checkIn, DateTime checkOut})>((ref, params) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.checkAvailability(
    params.unitId,
    params.checkIn,
    params.checkOut,
  );
});
