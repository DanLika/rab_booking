import 'dart:async';

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
import '../../../../core/services/logging_service.dart';
import '../../../../core/providers/enhanced_auth_provider.dart';

part 'owner_bookings_provider.g.dart';

/// Provider for pending booking ID to show in dialog (from deep-link navigation)
/// This avoids issues with widget parameter passing during navigation
/// FIXED BUG #4: Added autoDispose to prevent state persistence across navigations
final pendingBookingIdProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);

// Note: OwnerBooking is defined in firebase_owner_bookings_repository.dart (already imported above)

/// Updates a booking's status in a list and re-sorts
///
/// Sorting: Pending bookings first (by check-in), then others by check-in (soonest first)
/// This matches the repository sorting for "All" filter
List<OwnerBooking> _updateBookingStatusInList(
  List<OwnerBooking> bookings,
  String bookingId,
  BookingStatus newStatus,
) {
  final updatedBookings = bookings.map((ownerBooking) {
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

  // Re-sort: pending first, then all by check-in (soonest first)
  updatedBookings.sort((a, b) {
    final aPending = a.booking.status == BookingStatus.pending ? 0 : 1;
    final bPending = b.booking.status == BookingStatus.pending ? 0 : 1;
    if (aPending != bPending) return aPending.compareTo(bPending);
    // Both pending and non-pending: sort by check-in (soonest first)
    return a.booking.checkIn.compareTo(b.booking.checkIn);
  });

  return updatedBookings;
}

/// Bookings filter state
class BookingsFilters {
  final BookingStatus? status;
  final String? propertyId;
  final DateTime? startDate;
  final DateTime? endDate;

  /// When true, shows only imported reservations (iCal events from Booking.com, Airbnb, etc.)
  final bool showImportedOnly;

  const BookingsFilters({
    this.status,
    this.propertyId,
    this.startDate,
    this.endDate,
    this.showImportedOnly = false,
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
    bool? showImportedOnly,
  }) {
    return BookingsFilters(
      status: clearStatus ? null : (status ?? this.status),
      propertyId: clearProperty ? null : (propertyId ?? this.propertyId),
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      showImportedOnly: showImportedOnly ?? this.showImportedOnly,
    );
  }

  bool get hasActiveFilters =>
      status != null ||
      propertyId != null ||
      startDate != null ||
      endDate != null ||
      showImportedOnly;
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
    // When setting a status, disable imported filter
    state = state.copyWith(
      status: status,
      clearStatus: status == null,
      showImportedOnly: false,
    );
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

  /// Toggle showing only imported reservations (iCal events)
  void setShowImportedOnly(bool value) {
    // When showing imported only, clear status filter
    state = state.copyWith(
      showImportedOnly: value,
      clearStatus: value, // Clear status when showing imported
    );
  }

  void clearFilters() {
    state = const BookingsFilters();
  }
}

/// Owner unit IDs provider - cached list of unit IDs for pagination
/// This is small data (just IDs) so OK to cache
/// keepAlive: Prevents re-fetching on every navigation (used by 5+ providers)
/// BUG FIX: Watch enhancedAuthProvider to auto-invalidate on user change
/// This fixes the bug where data persisted after logout/login with different account
@Riverpod(keepAlive: true)
Future<List<String>> ownerUnitIds(Ref ref) async {
  // Watch auth state - provider rebuilds when user changes (login/logout)
  final authState = ref.watch(enhancedAuthProvider);
  final userId = authState.userModel?.id;

  if (userId == null) {
    throw AuthException(
      'User not authenticated',
      code: 'auth/not-authenticated',
    );
  }

  final repository = ref.watch(ownerBookingsRepositoryProvider);
  return repository.getOwnerUnitIds(userId);
}

/// Paginated bookings notifier - TRUE server-side pagination
/// Only fetches [pageSize] bookings per request from Firestore
@riverpod
class PaginatedBookingsNotifier extends _$PaginatedBookingsNotifier {
  static const int pageSize = 20;

  Timer? _debounceTimer;

  @override
  PaginatedBookingsState build() {
    // Debounce: Riverpod provider graph stabilization causes multiple rapid
    // build() calls when dependencies load in cascade. Timer ensures only
    // the last rebuild triggers the Firestore query (~150ms is imperceptible).
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 150), loadFirstPage);
    ref.onDispose(_cancelDebounce);
    return PaginatedBookingsState.initial;
  }

  void _cancelDebounce() => _debounceTimer?.cancel();

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
      state = state.copyWith(
        isLoading: false,
        error: LoggingService.safeErrorToString(e),
      );
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

      // Append new bookings - server already returns sorted data
      // NOTE: Removed client-side re-sorting which caused UI jumps when items
      // shifted positions during scroll. Firestore ORDER BY ensures correct order.
      final allBookings = [...state.bookings, ...result.bookings];

      state = state.copyWith(
        bookings: allBookings,
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
    state = state.copyWith(
      bookings: _updateBookingStatusInList(
        state.bookings,
        bookingId,
        newStatus,
      ),
    );
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

  Timer? _debounceTimer;

  /// Add document to cache with size limit (FIFO eviction)
  void _addToCache(DocumentSnapshot doc) {
    if (_documentCache.length >= _maxCacheSize) {
      // Remove oldest entry (first key in insertion order)
      final oldestKey = _documentCache.keys.first;
      _documentCache.remove(oldestKey);
    }
    _documentCache[doc.id] = doc;
  }

  void _cancelDebounce() => _debounceTimer?.cancel();

  @override
  WindowedBookingsState build() {
    // Watch filters - when they change, the provider rebuilds and reloads
    ref.watch(bookingsFiltersNotifierProvider);

    // Debounce: Riverpod provider graph stabilization causes multiple rapid
    // build() calls when dependencies load in cascade. Timer ensures only
    // the last rebuild triggers the Firestore query (~150ms is imperceptible).
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 150), loadFirstPage);
    ref.onDispose(_cancelDebounce);
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
        error: LoggingService.safeErrorToString(e),
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

      // Append new bookings - server already returns sorted data
      // NOTE: Removed client-side re-sorting which caused UI jumps when items
      // shifted positions during scroll. Firestore ORDER BY ensures correct order.
      final newBookings = [...state.visibleBookings, ...result.bookings];

      state = state.copyWith(
        visibleBookings: newBookings,
        bottomCursor: result.lastDocument,
        hasMoreBottom: result.hasMore,
        isLoadingBottom: false,
      );

      // NOTE: Trimming disabled - for datasets < 500 items, keeping all in memory is fine
    } catch (e) {
      state = state.copyWith(
        isLoadingBottom: false,
        error: LoggingService.safeErrorToString(e),
      );
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

      // Prepend new bookings - server already returns sorted data
      // NOTE: Removed client-side re-sorting which caused UI jumps when items
      // shifted positions during scroll. Firestore ORDER BY ensures correct order.
      final newBookings = [...result.bookings, ...state.visibleBookings];

      state = state.copyWith(
        visibleBookings: newBookings,
        topCursor: result.firstDocument,
        hasMoreTop: result.hasMoreTop,
        isLoadingTop: false,
      );

      // NOTE: Trimming disabled - for datasets < 500 items, keeping all in memory is fine
    } catch (e) {
      state = state.copyWith(
        isLoadingTop: false,
        error: LoggingService.safeErrorToString(e),
      );
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
    state = state.copyWith(
      visibleBookings: _updateBookingStatusInList(
        state.visibleBookings,
        bookingId,
        newStatus,
      ),
    );
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

/// Pending bookings count - for drawer badge (REAL-TIME STREAM)
/// Uses Firestore snapshots() for instant updates when bookings change
/// Automatically updates badge when booking is confirmed/cancelled/created
@riverpod
Stream<int> pendingBookingsCount(Ref ref) {
  final repository = ref.watch(ownerBookingsRepositoryProvider);
  final auth = FirebaseAuth.instance;
  final userId = auth.currentUser?.uid;

  if (userId == null) return Stream.value(0);

  // Use stream-based method for real-time updates
  return repository.watchPendingBookingsCount();
}

/// Recent owner bookings provider (for dashboard activity)
/// Small dataset (10 items), OK to use simple query
/// keepAlive: Dashboard is frequently visited, avoid re-fetching
/// BUG FIX: Watch enhancedAuthProvider to auto-invalidate on user change
/// This fixes the bug where bookings persisted after logout/login with different account
@Riverpod(keepAlive: true)
Future<List<OwnerBooking>> recentOwnerBookings(Ref ref) async {
  // Watch auth state - provider rebuilds when user changes (login/logout)
  final authState = ref.watch(enhancedAuthProvider);
  final userId = authState.userModel?.id;

  if (userId == null) {
    throw AuthException(
      'User not authenticated',
      code: 'auth/not-authenticated',
    );
  }

  final repository = ref.watch(ownerBookingsRepositoryProvider);

  // Get unit IDs (cached, but also invalidates on user change now)
  final unitIds = await ref.watch(ownerUnitIdsProvider.future);

  // Fetch just 10 most recent
  final result = await repository.getOwnerBookingsPaginated(
    ownerId: userId,
    unitIds: unitIds,
    limit: 10,
  );

  return result.bookings;
}
