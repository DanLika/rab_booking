import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/enums.dart';
import '../../data/firebase/firebase_owner_bookings_repository.dart';
import '../../domain/models/windowed_bookings_state.dart';
import '../utils/scroll_direction_tracker.dart';
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
      status != null ||
      propertyId != null ||
      startDate != null ||
      endDate != null;
}

/// Paginated bookings state - server-side pagination
/// Only loads [pageSize] bookings at a time from Firestore
class PaginatedBookingsState {
  final List<OwnerBooking> bookings;
  final DocumentSnapshot? lastDocument; // Cursor for next page
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  const PaginatedBookingsState({
    this.bookings = const [],
    this.lastDocument,
    this.hasMore = true,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  PaginatedBookingsState copyWith({
    List<OwnerBooking>? bookings,
    DocumentSnapshot? lastDocument,
    bool clearLastDocument = false,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
  }) {
    return PaginatedBookingsState(
      bookings: bookings ?? this.bookings,
      lastDocument: clearLastDocument
          ? null
          : (lastDocument ?? this.lastDocument),
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }

  /// Initial loading state
  static const initial = PaginatedBookingsState(isLoading: true);
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
    state = state.copyWith(
      propertyId: propertyId,
      clearProperty: propertyId == null,
    );
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

/// Owner unit IDs provider - cached list of unit IDs for pagination
/// This is small data (just IDs) so OK to cache
@riverpod
Future<List<String>> ownerUnitIds(Ref ref) async {
  final repository = ref.watch(ownerBookingsRepositoryProvider);
  final auth = FirebaseAuth.instance;
  final userId = auth.currentUser?.uid;

  if (userId == null) {
    throw AuthException(
      'User not authenticated',
      code: 'auth/not-authenticated',
    );
  }

  return repository.getOwnerUnitIds(userId);
}

/// Paginated bookings notifier - TRUE server-side pagination
/// Only fetches [pageSize] bookings per request from Firestore
@riverpod
class PaginatedBookingsNotifier extends _$PaginatedBookingsNotifier {
  static const int pageSize = 20;

  @override
  PaginatedBookingsState build() {
    // Auto-load first page when provider is created
    Future.microtask(loadFirstPage);
    return PaginatedBookingsState.initial;
  }

  /// Load first page of bookings
  Future<void> loadFirstPage() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final repository = ref.read(ownerBookingsRepositoryProvider);
      final filters = ref.read(bookingsFiltersNotifierProvider);
      final auth = FirebaseAuth.instance;
      final userId = auth.currentUser?.uid;

      if (userId == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'User not authenticated',
        );
        return;
      }

      // Get unit IDs (cached)
      final unitIds = await ref.read(ownerUnitIdsProvider.future);

      final result = await repository.getOwnerBookingsPaginated(
        ownerId: userId,
        unitIds: unitIds,
        propertyId: filters.propertyId,
        status: filters.status,
        startDate: filters.startDate,
        endDate: filters.endDate,
      );

      state = PaginatedBookingsState(
        bookings: result.bookings,
        lastDocument: result.lastDocument,
        hasMore: result.hasMore,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load next page of bookings (append to existing)
  Future<void> loadMore() async {
    // Don't load if already loading or no more data
    if (state.isLoadingMore || state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final repository = ref.read(ownerBookingsRepositoryProvider);
      final filters = ref.read(bookingsFiltersNotifierProvider);
      final auth = FirebaseAuth.instance;
      final userId = auth.currentUser?.uid;

      if (userId == null) {
        state = state.copyWith(isLoadingMore: false);
        return;
      }

      // Get unit IDs (cached)
      final unitIds = await ref.read(ownerUnitIdsProvider.future);

      final result = await repository.getOwnerBookingsPaginated(
        ownerId: userId,
        unitIds: unitIds,
        propertyId: filters.propertyId,
        status: filters.status,
        startDate: filters.startDate,
        endDate: filters.endDate,
        startAfterDocument: state.lastDocument,
      );

      // Append new bookings to existing list
      state = state.copyWith(
        bookings: [...state.bookings, ...result.bookings],
        lastDocument: result.lastDocument,
        hasMore: result.hasMore,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  /// Refresh bookings (reset and reload first page)
  Future<void> refresh() async {
    state = const PaginatedBookingsState(isLoading: true);
    await loadFirstPage();
  }

  /// Remove a booking from local state (after delete/status change)
  void removeBooking(String bookingId) {
    state = state.copyWith(
      bookings: state.bookings.where((b) => b.booking.id != bookingId).toList(),
    );
  }

  /// Update a booking in local state (after status change)
  void updateBookingStatus(String bookingId, BookingStatus newStatus) {
    final updatedBookings = state.bookings.map((ownerBooking) {
      if (ownerBooking.booking.id == bookingId) {
        return OwnerBooking(
          booking: ownerBooking.booking.copyWith(status: newStatus),
          property: ownerBooking.property,
          unit: ownerBooking.unit,
          guestName: ownerBooking.guestName,
          guestEmail: ownerBooking.guestEmail,
          guestPhone: ownerBooking.guestPhone,
        );
      }
      return ownerBooking;
    }).toList();

    // Re-sort by status priority
    updatedBookings.sort((a, b) {
      final priorityCompare = b.booking.status.sortPriority.compareTo(
        a.booking.status.sortPriority,
      );
      if (priorityCompare != 0) return priorityCompare;
      return b.booking.createdAt.compareTo(a.booking.createdAt);
    });

    state = state.copyWith(bookings: updatedBookings);
  }
}

/// Windowed bookings notifier - bidirectional virtual scrolling
/// Maintains a sliding window of bookings in memory for optimal performance
///
/// Window sizes:
/// - Card View: 20 items (page size 20)
/// - Table View: 50 items (page size 50)
@riverpod
class WindowedBookingsNotifier extends _$WindowedBookingsNotifier {
  // Document snapshots for cursor-based pagination
  // Limited to prevent memory bloat on large datasets
  final Map<String, DocumentSnapshot> _documentCache = {};
  static const int _maxCacheSize = 100;

  /// Add document to cache with size limit (FIFO eviction)
  void _addToCache(DocumentSnapshot doc) {
    if (_documentCache.length >= _maxCacheSize) {
      // Remove oldest entry (first key in insertion order)
      final oldestKey = _documentCache.keys.first;
      _documentCache.remove(oldestKey);
    }
    _documentCache[doc.id] = doc;
  }

  @override
  WindowedBookingsState build() {
    // Auto-load first page when provider is created
    Future.microtask(loadFirstPage);
    return WindowedBookingsState.cardViewInitial;
  }

  /// Set view mode (card or table) with different window sizes
  void setViewMode({required bool isTableView}) {
    if (isTableView) {
      state = state.copyWith(windowSize: 50, pageSize: 50);
    } else {
      state = state.copyWith(windowSize: 20, pageSize: 20);
    }
    // Reload with new page size
    refresh();
  }

  /// Load first page of bookings
  Future<void> loadFirstPage() async {
    state = state.copyWith(
      isInitialLoad: true,
      isLoadingBottom: true,
      clearError: true,
    );

    try {
      final repository = ref.read(ownerBookingsRepositoryProvider);
      final filters = ref.read(bookingsFiltersNotifierProvider);
      final auth = FirebaseAuth.instance;
      final userId = auth.currentUser?.uid;

      if (userId == null) {
        state = state.copyWith(
          isInitialLoad: false,
          isLoadingBottom: false,
          error: 'User not authenticated',
        );
        return;
      }

      final unitIds = await ref.read(ownerUnitIdsProvider.future);

      final result = await repository.getOwnerBookingsPaginated(
        ownerId: userId,
        unitIds: unitIds,
        propertyId: filters.propertyId,
        status: filters.status,
        startDate: filters.startDate,
        endDate: filters.endDate,
        limit: state.pageSize,
      );

      // Cache document snapshots for cursor-based pagination
      if (result.lastDocument != null) {
        _addToCache(result.lastDocument!);
      }

      state = WindowedBookingsState(
        visibleBookings: result.bookings,
        topCursor: result.bookings.isNotEmpty ? result.lastDocument : null,
        bottomCursor: result.lastDocument,
        hasMoreBottom: result.hasMore,
        isInitialLoad: false,
        windowSize: state.windowSize,
        pageSize: state.pageSize,
      );
    } catch (e) {
      state = state.copyWith(
        isInitialLoad: false,
        isLoadingBottom: false,
        error: e.toString(),
      );
    }
  }

  /// Load more bookings below (scrolling down)
  Future<void> loadMoreBottom() async {
    if (!state.canLoadBottom) return;

    state = state.copyWith(
      isLoadingBottom: true,
      lastScrollDirection: ScrollDirection.down,
    );

    try {
      final repository = ref.read(ownerBookingsRepositoryProvider);
      final filters = ref.read(bookingsFiltersNotifierProvider);
      final auth = FirebaseAuth.instance;
      final userId = auth.currentUser?.uid;

      if (userId == null) {
        state = state.copyWith(isLoadingBottom: false);
        return;
      }

      final unitIds = await ref.read(ownerUnitIdsProvider.future);

      final result = await repository.getOwnerBookingsPaginated(
        ownerId: userId,
        unitIds: unitIds,
        propertyId: filters.propertyId,
        status: filters.status,
        startDate: filters.startDate,
        endDate: filters.endDate,
        limit: state.pageSize,
        startAfterDocument: state.bottomCursor,
      );

      if (result.bookings.isEmpty) {
        state = state.copyWith(isLoadingBottom: false, hasMoreBottom: false);
        return;
      }

      // Cache new document
      if (result.lastDocument != null) {
        _addToCache(result.lastDocument!);
      }

      // Append new bookings
      final newBookings = [...state.visibleBookings, ...result.bookings];

      state = state.copyWith(
        visibleBookings: newBookings,
        bottomCursor: result.lastDocument,
        hasMoreBottom: result.hasMore,
        isLoadingBottom: false,
      );

      // NOTE: Trimming disabled - for datasets < 500 items, keeping all in memory is fine
    } catch (e) {
      state = state.copyWith(isLoadingBottom: false, error: e.toString());
    }
  }

  /// Load more bookings above (scrolling up)
  Future<void> loadMoreTop() async {
    if (!state.canLoadTop || state.topCursor == null) return;

    state = state.copyWith(
      isLoadingTop: true,
      lastScrollDirection: ScrollDirection.up,
    );

    try {
      final repository = ref.read(ownerBookingsRepositoryProvider);
      final filters = ref.read(bookingsFiltersNotifierProvider);
      final auth = FirebaseAuth.instance;
      final userId = auth.currentUser?.uid;

      if (userId == null) {
        state = state.copyWith(isLoadingTop: false);
        return;
      }

      final unitIds = await ref.read(ownerUnitIdsProvider.future);

      final result = await repository.getOwnerBookingsBefore(
        ownerId: userId,
        unitIds: unitIds,
        propertyId: filters.propertyId,
        status: filters.status,
        startDate: filters.startDate,
        endDate: filters.endDate,
        limit: state.pageSize,
        endBeforeDocument: state.topCursor!,
      );

      if (result.bookings.isEmpty) {
        state = state.copyWith(isLoadingTop: false, hasMoreTop: false);
        return;
      }

      // Cache new documents
      if (result.firstDocument != null) {
        _addToCache(result.firstDocument!);
      }

      // Prepend new bookings
      final newBookings = [...result.bookings, ...state.visibleBookings];

      state = state.copyWith(
        visibleBookings: newBookings,
        topCursor: result.firstDocument,
        hasMoreTop: result.hasMoreTop,
        isLoadingTop: false,
      );

      // NOTE: Trimming disabled - for datasets < 500 items, keeping all in memory is fine
    } catch (e) {
      state = state.copyWith(isLoadingTop: false, error: e.toString());
    }
  }

  /// Update scroll direction (called from UI)
  void updateScrollDirection(ScrollDirection direction) {
    if (state.lastScrollDirection != direction) {
      state = state.copyWith(lastScrollDirection: direction);
    }
  }

  /// Refresh bookings (reset window and reload)
  Future<void> refresh() async {
    _documentCache.clear();
    state = WindowedBookingsState(
      windowSize: state.windowSize,
      pageSize: state.pageSize,
    );
    await loadFirstPage();
  }

  /// Remove a booking from visible list
  void removeBooking(String bookingId) {
    _documentCache.remove(bookingId);
    state = state.copyWith(
      visibleBookings: state.visibleBookings
          .where((b) => b.booking.id != bookingId)
          .toList(),
    );
  }

  /// Update booking status in visible list
  void updateBookingStatus(String bookingId, BookingStatus newStatus) {
    final updatedBookings = state.visibleBookings.map((ownerBooking) {
      if (ownerBooking.booking.id == bookingId) {
        return OwnerBooking(
          booking: ownerBooking.booking.copyWith(status: newStatus),
          property: ownerBooking.property,
          unit: ownerBooking.unit,
          guestName: ownerBooking.guestName,
          guestEmail: ownerBooking.guestEmail,
          guestPhone: ownerBooking.guestPhone,
        );
      }
      return ownerBooking;
    }).toList();

    // Re-sort by status priority
    updatedBookings.sort((a, b) {
      final priorityCompare = b.booking.status.sortPriority.compareTo(
        a.booking.status.sortPriority,
      );
      if (priorityCompare != 0) return priorityCompare;
      return b.booking.createdAt.compareTo(a.booking.createdAt);
    });

    state = state.copyWith(visibleBookings: updatedBookings);
  }

  /// Get debug info for overlay
  WindowingDebugInfo getDebugInfo({
    required double scrollPosition,
    required double maxScrollExtent,
  }) {
    return WindowingDebugInfo(
      visibleCount: state.visibleBookings.length,
      windowSize: state.windowSize,
      trimThreshold: state.trimThreshold,
      hasMoreTop: state.hasMoreTop,
      hasMoreBottom: state.hasMoreBottom,
      isLoadingTop: state.isLoadingTop,
      isLoadingBottom: state.isLoadingBottom,
      scrollDirection: state.lastScrollDirection,
      scrollPosition: scrollPosition,
      maxScrollExtent: maxScrollExtent,
    );
  }

  /// Fetch a specific booking by ID (for deep-link support)
  /// Used when the booking is not in the current window
  Future<OwnerBooking?> fetchAndShowBooking(String bookingId) async {
    try {
      final repository = ref.read(ownerBookingsRepositoryProvider);
      final auth = FirebaseAuth.instance;
      final userId = auth.currentUser?.uid;

      if (userId == null) return null;

      // Fetch the specific booking directly
      return await repository.getOwnerBookingById(bookingId);
    } catch (e) {
      // Booking not found or error fetching
      return null;
    }
  }
}

/// Convenience provider for bookings list (unwrapped from state)
@riverpod
List<OwnerBooking> ownerBookings(Ref ref) {
  final state = ref.watch(paginatedBookingsNotifierProvider);
  return state.bookings;
}

/// Convenience provider for hasMore flag
@riverpod
bool hasMoreBookings(Ref ref) {
  final state = ref.watch(paginatedBookingsNotifierProvider);
  return state.hasMore;
}

/// Convenience provider for loading state
@riverpod
bool isLoadingBookings(Ref ref) {
  final state = ref.watch(paginatedBookingsNotifierProvider);
  return state.isLoading;
}

/// Convenience provider for loading more state
@riverpod
bool isLoadingMoreBookings(Ref ref) {
  final state = ref.watch(paginatedBookingsNotifierProvider);
  return state.isLoadingMore;
}

/// Pending bookings count - for drawer badge
/// Uses small optimized query (just count, not full data)
@riverpod
Future<int> pendingBookingsCount(Ref ref) async {
  final repository = ref.watch(ownerBookingsRepositoryProvider);
  final auth = FirebaseAuth.instance;
  final userId = auth.currentUser?.uid;

  if (userId == null) return 0;

  try {
    // Use existing method but only count pending
    final unitIds = await ref.watch(ownerUnitIdsProvider.future);
    final result = await repository.getOwnerBookingsPaginated(
      ownerId: userId,
      unitIds: unitIds,
      status: BookingStatus.pending,
      limit: 100, // Cap at 100 for count
    );
    return result.bookings.length;
  } catch (_) {
    return 0;
  }
}

/// Recent owner bookings provider (for dashboard activity)
/// Small dataset (10 items), OK to use simple query
@riverpod
Future<List<OwnerBooking>> recentOwnerBookings(Ref ref) async {
  final repository = ref.watch(ownerBookingsRepositoryProvider);
  final auth = FirebaseAuth.instance;
  final userId = auth.currentUser?.uid;

  if (userId == null) {
    throw AuthException(
      'User not authenticated',
      code: 'auth/not-authenticated',
    );
  }

  // Get unit IDs (cached)
  final unitIds = await ref.watch(ownerUnitIdsProvider.future);

  // Fetch just 10 most recent
  final result = await repository.getOwnerBookingsPaginated(
    ownerId: userId,
    unitIds: unitIds,
    limit: 10,
  );

  return result.bookings;
}
