import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/enums.dart';
import '../../data/firebase/firebase_owner_bookings_repository.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../core/exceptions/app_exceptions.dart';

part 'owner_bookings_provider.g.dart';

// Note: OwnerBooking is defined in firebase_owner_bookings_repository.dart (already imported above)

/// Bookings filter state
class BookingsFilters {
  final BookingStatus? status;
  final String? propertyId;
  final DateTime? startDate;
  final DateTime? endDate;

  const BookingsFilters({
    this.status,
    this.propertyId,
    this.startDate,
    this.endDate,
  });

  BookingsFilters copyWith({
    BookingStatus? status,
    bool clearStatus = false,
    String? propertyId,
    bool clearProperty = false,
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? endDate,
    bool clearEndDate = false,
  }) {
    return BookingsFilters(
      status: clearStatus ? null : (status ?? this.status),
      propertyId: clearProperty ? null : (propertyId ?? this.propertyId),
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
    );
  }

  bool get hasActiveFilters =>
      status != null || propertyId != null || startDate != null || endDate != null;
}

/// Pagination state for bookings
class BookingsPagination {
  final int displayLimit; // How many bookings to display
  final int pageSize; // How many to load per "load more"
  final bool isLoadingMore;

  const BookingsPagination({
    this.displayLimit = 10,
    this.pageSize = 10,
    this.isLoadingMore = false,
  });

  BookingsPagination copyWith({
    int? displayLimit,
    int? pageSize,
    bool? isLoadingMore,
  }) {
    return BookingsPagination(
      displayLimit: displayLimit ?? this.displayLimit,
      pageSize: pageSize ?? this.pageSize,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  BookingsPagination loadMore() {
    return copyWith(displayLimit: displayLimit + pageSize);
  }
}

/// Bookings filters notifier
@riverpod
class BookingsFiltersNotifier extends _$BookingsFiltersNotifier {
  @override
  BookingsFilters build() {
    // Default to showing ALL bookings on initial load (sorted by status priority + creation date)
    return const BookingsFilters();
  }

  void setStatus(BookingStatus? status) {
    state = state.copyWith(status: status, clearStatus: status == null);
  }

  void setProperty(String? propertyId) {
    state = state.copyWith(propertyId: propertyId, clearProperty: propertyId == null);
  }

  void setDateRange(DateTime? startDate, DateTime? endDate) {
    state = state.copyWith(
      startDate: startDate,
      clearStartDate: startDate == null,
      endDate: endDate,
      clearEndDate: endDate == null,
    );
  }

  void clearFilters() {
    state = const BookingsFilters();
  }
}

/// Pagination notifier
@riverpod
class BookingsPaginationNotifier extends _$BookingsPaginationNotifier {
  @override
  BookingsPagination build() {
    return const BookingsPagination();
  }

  void loadMore() {
    state = state.loadMore();
  }

  void reset() {
    state = const BookingsPagination();
  }

  void setLoadingMore(bool loading) {
    state = state.copyWith(isLoadingMore: loading);
  }
}

/// All owner bookings (full list, cached)
@riverpod
Future<List<OwnerBooking>> allOwnerBookings(Ref ref) async {
  final repository = ref.watch(ownerBookingsRepositoryProvider);
  final filters = ref.watch(bookingsFiltersNotifierProvider);
  final auth = FirebaseAuth.instance;
  final userId = auth.currentUser?.uid;

  if (userId == null) {
    throw AuthException('User not authenticated', code: 'auth/not-authenticated');
  }

  final bookings = await repository.getOwnerBookings(
    ownerId: userId,
    propertyId: filters.propertyId,
    status: filters.status,
    startDate: filters.startDate,
    endDate: filters.endDate,
  );

  // Sort bookings by status priority (pending > confirmed > cancelled/completed)
  // then by creation date descending (newest first)
  final sortedBookings = List<OwnerBooking>.from(bookings)
    ..sort((a, b) {
      // Priority order: pending (3), confirmed (2), cancelled/completed (1)
      final aPriority = a.booking.status == BookingStatus.pending
          ? 3
          : a.booking.status == BookingStatus.confirmed
              ? 2
              : 1;
      final bPriority = b.booking.status == BookingStatus.pending
          ? 3
          : b.booking.status == BookingStatus.confirmed
              ? 2
              : 1;

      // First sort by status priority (descending)
      if (aPriority != bPriority) {
        return bPriority.compareTo(aPriority);
      }

      // Then sort by creation date descending (newest first)
      return b.booking.createdAt.compareTo(a.booking.createdAt);
    });

  return sortedBookings;
}

/// Owner bookings provider with pagination (displays limited subset)
@riverpod
Future<List<OwnerBooking>> ownerBookings(Ref ref) async {
  final allBookings = await ref.watch(allOwnerBookingsProvider.future);
  final pagination = ref.watch(bookingsPaginationNotifierProvider);

  // Return only the limited subset for display
  return allBookings.take(pagination.displayLimit).toList();
}

/// Check if there are more bookings to load
@riverpod
Future<bool> hasMoreBookings(Ref ref) async {
  final allBookings = await ref.watch(allOwnerBookingsProvider.future);
  final pagination = ref.watch(bookingsPaginationNotifierProvider);

  return allBookings.length > pagination.displayLimit;
}

/// Recent owner bookings provider (for dashboard activity)
@riverpod
Future<List<OwnerBooking>> recentOwnerBookings(Ref ref) async {
  final repository = ref.watch(ownerBookingsRepositoryProvider);
  final auth = FirebaseAuth.instance;
  final userId = auth.currentUser?.uid;

  if (userId == null) {
    throw AuthException('User not authenticated', code: 'auth/not-authenticated');
  }

  final allBookings = await repository.getOwnerBookings(ownerId: userId);

  // Sort by created date and take latest 10
  final sortedBookings = List<OwnerBooking>.from(allBookings)
    ..sort((a, b) => b.booking.createdAt.compareTo(a.booking.createdAt));

  return sortedBookings.take(10).toList();
}
