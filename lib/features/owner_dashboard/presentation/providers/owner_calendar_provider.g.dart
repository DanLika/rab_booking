// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'owner_calendar_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$ownerPropertiesCalendarHash() =>
    r'c563bd64c6223fa7e65d0cc0ad65181deef4ed17';

/// Owner properties provider - returns ALL properties for owner
/// keepAlive: Prevents re-fetching when filters dialog opens
/// SECURITY: Watches enhancedAuthProvider to invalidate cache on user change
///
/// Copied from [ownerPropertiesCalendar].
@ProviderFor(ownerPropertiesCalendar)
final ownerPropertiesCalendarProvider =
    FutureProvider<List<PropertyModel>>.internal(
      ownerPropertiesCalendar,
      name: r'ownerPropertiesCalendarProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$ownerPropertiesCalendarHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef OwnerPropertiesCalendarRef = FutureProviderRef<List<PropertyModel>>;
String _$allOwnerUnitsHash() => r'84fb9a5b4641de95497d4e75aa1aa6d952e51318';

/// All units provider - returns ALL ACTIVE units for ALL properties
/// Filters out soft-deleted units (deletedAt != null) and unavailable units
/// keepAlive: Prevents re-fetching when filters dialog opens/closes
///
/// Copied from [allOwnerUnits].
@ProviderFor(allOwnerUnits)
final allOwnerUnitsProvider = FutureProvider<List<UnitModel>>.internal(
  allOwnerUnits,
  name: r'allOwnerUnitsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$allOwnerUnitsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AllOwnerUnitsRef = FutureProviderRef<List<UnitModel>>;
String _$calendarBookingsHash() => r'd8a2960873952b1b514cacef6c090be2932ad18b';

/// Calendar bookings provider - returns all bookings except cancelled
/// Cancelled bookings are hidden as they don't occupy dates
///
/// OPTIMIZED: Uses pre-cached unitIds from allOwnerUnitsProvider
/// Saves 1 + N queries (properties + units) per invocation
///
/// Copied from [calendarBookings].
@ProviderFor(calendarBookings)
final calendarBookingsProvider =
    AutoDisposeFutureProvider<Map<String, List<BookingModel>>>.internal(
      calendarBookings,
      name: r'calendarBookingsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$calendarBookingsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CalendarBookingsRef =
    AutoDisposeFutureProviderRef<Map<String, List<BookingModel>>>;
String _$ownerCalendarRealtimeManagerHash() =>
    r'ac996295a1e0a739d9d5829e93edca395bbd5d37';

/// Realtime subscription manager for owner calendar
/// Automatically refreshes calendar when ANY booking changes
///
/// Copied from [OwnerCalendarRealtimeManager].
@ProviderFor(OwnerCalendarRealtimeManager)
final ownerCalendarRealtimeManagerProvider =
    AutoDisposeNotifierProvider<OwnerCalendarRealtimeManager, void>.internal(
      OwnerCalendarRealtimeManager.new,
      name: r'ownerCalendarRealtimeManagerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$ownerCalendarRealtimeManagerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$OwnerCalendarRealtimeManager = AutoDisposeNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
