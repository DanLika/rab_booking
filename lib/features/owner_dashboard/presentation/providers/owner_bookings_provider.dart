import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/enums.dart';
import '../../data/firebase/firebase_owner_bookings_repository.dart';
import '../../../../shared/providers/repository_providers.dart';

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

/// Bookings filters notifier
@riverpod
class BookingsFiltersNotifier extends _$BookingsFiltersNotifier {
  @override
  BookingsFilters build() {
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

/// Owner bookings provider
@riverpod
Future<List<OwnerBooking>> ownerBookings(Ref ref) async {
  final repository = ref.watch(ownerBookingsRepositoryProvider);
  final filters = ref.watch(bookingsFiltersNotifierProvider);
  final auth = FirebaseAuth.instance;
  final userId = auth.currentUser?.uid;

  if (userId == null) {
    throw Exception('User not authenticated');
  }

  return repository.getOwnerBookings(
    ownerId: userId,
    propertyId: filters.propertyId,
    status: filters.status,
    startDate: filters.startDate,
    endDate: filters.endDate,
  );
}

/// Recent owner bookings provider (for dashboard activity)
@riverpod
Future<List<OwnerBooking>> recentOwnerBookings(Ref ref) async {
  final repository = ref.watch(ownerBookingsRepositoryProvider);
  final auth = FirebaseAuth.instance;
  final userId = auth.currentUser?.uid;

  if (userId == null) {
    throw Exception('User not authenticated');
  }

  final allBookings = await repository.getOwnerBookings(ownerId: userId);

  // Sort by created date and take latest 10
  final sortedBookings = List<OwnerBooking>.from(allBookings)
    ..sort((a, b) => b.booking.createdAt.compareTo(a.booking.createdAt));

  return sortedBookings.take(10).toList();
}
