// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'owner_bookings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$ownerUnitIdsHash() => r'67f25344a1b88a6ad6046f0eb35b5152d178a9d7';

/// Owner unit IDs provider - cached list of unit IDs for pagination
/// This is small data (just IDs) so OK to cache
/// keepAlive: Prevents re-fetching on every navigation (used by 5+ providers)
///
/// Copied from [ownerUnitIds].
@ProviderFor(ownerUnitIds)
final ownerUnitIdsProvider = FutureProvider<List<String>>.internal(
  ownerUnitIds,
  name: r'ownerUnitIdsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$ownerUnitIdsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef OwnerUnitIdsRef = FutureProviderRef<List<String>>;
String _$ownerBookingsHash() => r'5824d4d121f45efda3e447f320d757ed175f0604';

/// Convenience provider for bookings list (unwrapped from state)
///
/// Copied from [ownerBookings].
@ProviderFor(ownerBookings)
final ownerBookingsProvider = AutoDisposeProvider<List<OwnerBooking>>.internal(
  ownerBookings,
  name: r'ownerBookingsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$ownerBookingsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef OwnerBookingsRef = AutoDisposeProviderRef<List<OwnerBooking>>;
String _$hasMoreBookingsHash() => r'ab20fde5f1b29e3e384c9473e063ca8101398387';

/// Convenience provider for hasMore flag
///
/// Copied from [hasMoreBookings].
@ProviderFor(hasMoreBookings)
final hasMoreBookingsProvider = AutoDisposeProvider<bool>.internal(
  hasMoreBookings,
  name: r'hasMoreBookingsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$hasMoreBookingsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HasMoreBookingsRef = AutoDisposeProviderRef<bool>;
String _$isLoadingBookingsHash() => r'6bbdc4bb1af7be179b54f0180350feb44ce629af';

/// Convenience provider for loading state
///
/// Copied from [isLoadingBookings].
@ProviderFor(isLoadingBookings)
final isLoadingBookingsProvider = AutoDisposeProvider<bool>.internal(
  isLoadingBookings,
  name: r'isLoadingBookingsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isLoadingBookingsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsLoadingBookingsRef = AutoDisposeProviderRef<bool>;
String _$isLoadingMoreBookingsHash() =>
    r'cf41edddf9af06c289eb86b033871c5a170767a1';

/// Convenience provider for loading more state
///
/// Copied from [isLoadingMoreBookings].
@ProviderFor(isLoadingMoreBookings)
final isLoadingMoreBookingsProvider = AutoDisposeProvider<bool>.internal(
  isLoadingMoreBookings,
  name: r'isLoadingMoreBookingsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isLoadingMoreBookingsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsLoadingMoreBookingsRef = AutoDisposeProviderRef<bool>;
String _$pendingBookingsCountHash() =>
    r'f5b4069cd4694dea50dd877a896d4f2ebb5d9df1';

/// Pending bookings count - for drawer badge
/// OPTIMIZED: Uses Firestore count() aggregation (0 document reads!)
/// keepAlive: Caches result to avoid re-fetching on every drawer open
///
/// Copied from [pendingBookingsCount].
@ProviderFor(pendingBookingsCount)
final pendingBookingsCountProvider = FutureProvider<int>.internal(
  pendingBookingsCount,
  name: r'pendingBookingsCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pendingBookingsCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PendingBookingsCountRef = FutureProviderRef<int>;
String _$recentOwnerBookingsHash() =>
    r'0b5dcb31c4158d6a6cd95544fa8ff487ab0918fc';

/// Recent owner bookings provider (for dashboard activity)
/// Small dataset (10 items), OK to use simple query
/// keepAlive: Dashboard is frequently visited, avoid re-fetching
///
/// Copied from [recentOwnerBookings].
@ProviderFor(recentOwnerBookings)
final recentOwnerBookingsProvider = FutureProvider<List<OwnerBooking>>.internal(
  recentOwnerBookings,
  name: r'recentOwnerBookingsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$recentOwnerBookingsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RecentOwnerBookingsRef = FutureProviderRef<List<OwnerBooking>>;
String _$bookingsFiltersNotifierHash() =>
    r'74c608cdd7800e0193b07ef32cbf2e5ccdef8ea7';

/// Bookings filters notifier
///
/// Copied from [BookingsFiltersNotifier].
@ProviderFor(BookingsFiltersNotifier)
final bookingsFiltersNotifierProvider =
    AutoDisposeNotifierProvider<
      BookingsFiltersNotifier,
      BookingsFilters
    >.internal(
      BookingsFiltersNotifier.new,
      name: r'bookingsFiltersNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$bookingsFiltersNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$BookingsFiltersNotifier = AutoDisposeNotifier<BookingsFilters>;
String _$paginatedBookingsNotifierHash() =>
    r'1fc382873e04dbe3875f8577f83dd92ed55eb03c';

/// Paginated bookings notifier - TRUE server-side pagination
/// Only fetches [pageSize] bookings per request from Firestore
///
/// Copied from [PaginatedBookingsNotifier].
@ProviderFor(PaginatedBookingsNotifier)
final paginatedBookingsNotifierProvider =
    AutoDisposeNotifierProvider<
      PaginatedBookingsNotifier,
      PaginatedBookingsState
    >.internal(
      PaginatedBookingsNotifier.new,
      name: r'paginatedBookingsNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$paginatedBookingsNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$PaginatedBookingsNotifier =
    AutoDisposeNotifier<PaginatedBookingsState>;
String _$windowedBookingsNotifierHash() =>
    r'18c9de637760552fae3b0466358b48d8b1e02084';

/// Windowed bookings notifier - bidirectional virtual scrolling
/// Maintains a sliding window of bookings in memory for optimal performance
///
/// Window sizes:
/// - Card View: 20 items (page size 20)
/// - Table View: 50 items (page size 50)
///
/// Copied from [WindowedBookingsNotifier].
@ProviderFor(WindowedBookingsNotifier)
final windowedBookingsNotifierProvider =
    AutoDisposeNotifierProvider<
      WindowedBookingsNotifier,
      WindowedBookingsState
    >.internal(
      WindowedBookingsNotifier.new,
      name: r'windowedBookingsNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$windowedBookingsNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$WindowedBookingsNotifier = AutoDisposeNotifier<WindowedBookingsState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
