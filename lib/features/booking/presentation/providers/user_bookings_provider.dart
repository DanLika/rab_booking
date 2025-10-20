import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/user_booking.dart';
import '../../data/repositories/user_bookings_repository.dart';

part 'user_bookings_provider.g.dart';

@riverpod
class UserBookings extends _$UserBookings {
  @override
  Future<List<UserBooking>> build() async {
    final repository = ref.watch(userBookingsRepositoryProvider);
    return repository.getUserBookings();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(userBookingsRepositoryProvider);
      return repository.getUserBookings();
    });
  }

  Future<void> cancelBooking(String bookingId, String reason) async {
    final repository = ref.read(userBookingsRepositoryProvider);
    await repository.cancelBooking(bookingId, reason);
    await refresh();
  }
}

@riverpod
Future<List<UserBooking>> upcomingBookings(Ref ref) async {
  final bookings = await ref.watch(userBookingsProvider.future);
  return bookings.where((booking) => booking.isUpcoming).toList();
}

@riverpod
Future<List<UserBooking>> pastBookings(Ref ref) async {
  final bookings = await ref.watch(userBookingsProvider.future);
  return bookings.where((booking) => booking.isPast).toList();
}

@riverpod
Future<List<UserBooking>> cancelledBookings(Ref ref) async {
  final bookings = await ref.watch(userBookingsProvider.future);
  return bookings.where((booking) => booking.isCancelled).toList();
}

@riverpod
Future<UserBooking> bookingDetails(
  Ref ref,
  String bookingId,
) async {
  final repository = ref.watch(userBookingsRepositoryProvider);
  return repository.getBookingById(bookingId);
}
