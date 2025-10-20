import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/user_booking.dart';
import '../../data/repositories/user_bookings_repository.dart';
import '../../domain/constants/booking_constants.dart';

part 'user_bookings_provider.g.dart';

/// State class for paginated bookings
class PaginatedBookingsState {
  final List<UserBooking> bookings;
  final bool hasMore;
  final bool isLoadingMore;
  final int currentPage;
  final int? totalCount;

  const PaginatedBookingsState({
    required this.bookings,
    required this.hasMore,
    this.isLoadingMore = false,
    this.currentPage = 0,
    this.totalCount,
  });

  PaginatedBookingsState copyWith({
    List<UserBooking>? bookings,
    bool? hasMore,
    bool? isLoadingMore,
    int? currentPage,
    int? totalCount,
  }) {
    return PaginatedBookingsState(
      bookings: bookings ?? this.bookings,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      currentPage: currentPage ?? this.currentPage,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

@riverpod
class UserBookings extends _$UserBookings {
  @override
  Future<PaginatedBookingsState> build() async {
    final repository = ref.watch(userBookingsRepositoryProvider);
    final bookings = await repository.getUserBookings(limit: BookingConstants.bookingsPerPage);
    final totalCount = await repository.getUserBookingsCount();

    return PaginatedBookingsState(
      bookings: bookings,
      hasMore: bookings.length >= BookingConstants.bookingsPerPage,
      currentPage: 0,
      totalCount: totalCount,
    );
  }

  Future<void> loadMore() async {
    final currentState = state.value;
    if (currentState == null || currentState.isLoadingMore || !currentState.hasMore) {
      return;
    }

    // Set loading state
    state = AsyncValue.data(currentState.copyWith(isLoadingMore: true));

    try {
      final repository = ref.read(userBookingsRepositoryProvider);
      final nextPage = currentState.currentPage + 1;
      final offset = nextPage * BookingConstants.bookingsPerPage;

      final moreBookings = await repository.getUserBookings(
        limit: BookingConstants.bookingsPerPage,
        offset: offset,
      );

      final allBookings = [...currentState.bookings, ...moreBookings];

      state = AsyncValue.data(
        PaginatedBookingsState(
          bookings: allBookings,
          hasMore: moreBookings.length >= BookingConstants.bookingsPerPage,
          isLoadingMore: false,
          currentPage: nextPage,
          totalCount: currentState.totalCount,
        ),
      );
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(userBookingsRepositoryProvider);
      final bookings = await repository.getUserBookings(limit: BookingConstants.bookingsPerPage);
      final totalCount = await repository.getUserBookingsCount();

      return PaginatedBookingsState(
        bookings: bookings,
        hasMore: bookings.length >= BookingConstants.bookingsPerPage,
        currentPage: 0,
        totalCount: totalCount,
      );
    });
  }

  /// Cancel booking and return refund amount
  /// Automatically calculates refund based on cancellation policy
  Future<double> cancelBooking(String bookingId, String reason) async {
    final repository = ref.read(userBookingsRepositoryProvider);
    final refundAmount = await repository.cancelBooking(bookingId, reason);
    await refresh();
    return refundAmount;
  }
}

@riverpod
Future<List<UserBooking>> upcomingBookings(Ref ref) async {
  final paginatedState = await ref.watch(userBookingsProvider.future);
  return paginatedState.bookings.where((booking) => booking.isUpcoming).toList();
}

@riverpod
Future<List<UserBooking>> pastBookings(Ref ref) async {
  final paginatedState = await ref.watch(userBookingsProvider.future);
  return paginatedState.bookings.where((booking) => booking.isPast).toList();
}

@riverpod
Future<List<UserBooking>> cancelledBookings(Ref ref) async {
  final paginatedState = await ref.watch(userBookingsProvider.future);
  return paginatedState.bookings.where((booking) => booking.isCancelled).toList();
}

@riverpod
Future<UserBooking> bookingDetails(
  Ref ref,
  String bookingId,
) async {
  final repository = ref.watch(userBookingsRepositoryProvider);
  return repository.getBookingById(bookingId);
}
