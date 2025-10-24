import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/calendar_permissions.dart';

part 'calendar_permissions_provider.g.dart';

/// Provider for current user's calendar permissions
@riverpod
Future<CalendarPermissions> calendarPermissions(
  CalendarPermissionsRef ref,
  String? propertyId,
) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;

  if (user == null) {
    // Guest user (not authenticated)
    return CalendarPermissions(
      role: UserRole.guest,
      userId: '',
    );
  }

  // Get user role from database
  final userRole = await _getUserRole(user.id);

  // Get property ownership if propertyId provided
  PropertyOwnership? ownership;
  if (propertyId != null) {
    ownership = await _getPropertyOwnership(propertyId);
  }

  return CalendarPermissions(
    role: userRole,
    userId: user.id,
    property: ownership,
  );
}

/// Get user role from database
Future<UserRole> _getUserRole(String userId) async {
  try {
    final supabase = Supabase.instance.client;

    // Query user role from users table
    final response = await supabase
        .from('users')
        .select('role')
        .eq('id', userId)
        .maybeSingle();

    if (response == null) {
      return UserRole.guest;
    }

    final roleString = response['role'] as String? ?? 'guest';

    switch (roleString.toLowerCase()) {
      case 'owner':
        return UserRole.owner;
      case 'superadmin':
      case 'super_admin':
        return UserRole.superAdmin;
      case 'guest':
      default:
        return UserRole.guest;
    }
  } catch (e) {
    // Default to guest on error
    return UserRole.guest;
  }
}

/// Get property ownership information
Future<PropertyOwnership?> _getPropertyOwnership(String propertyId) async {
  try {
    final supabase = Supabase.instance.client;

    // Query property ownership
    final response = await supabase
        .from('properties')
        .select('owner_id')
        .eq('id', propertyId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    final ownerId = response['owner_id'] as String;

    // TODO: Query co-owners if you have that feature
    // For now, just return owner

    return PropertyOwnership(
      propertyId: propertyId,
      ownerId: ownerId,
      coOwners: [],
    );
  } catch (e) {
    return null;
  }
}

/// Provider for checking if user can perform specific action
@riverpod
class PermissionChecker extends _$PermissionChecker {
  @override
  AsyncValue<PermissionCheckResult> build() {
    return const AsyncValue.data(
      PermissionCheckResult(allowed: true),
    );
  }

  /// Check if user can select date
  Future<void> checkCanSelectDate(
    CalendarPermissions permissions,
    CalendarDay day,
  ) async {
    final canSelect = permissions.canSelectDate(day);

    if (!canSelect) {
      state = AsyncValue.data(
        PermissionCheckResult.denied(
          reason: 'This date is not available for selection',
          suggestion: 'Please choose an available date',
        ),
      );
    } else {
      state = const AsyncValue.data(PermissionCheckResult(allowed: true));
    }
  }

  /// Check if user can create booking
  Future<void> checkCanCreateBooking(
    CalendarPermissions permissions,
    DateTimeRange range,
  ) async {
    final canCreate = permissions.canCreateBooking(range);

    if (!canCreate) {
      state = AsyncValue.data(
        PermissionCheckResult.denied(
          reason: 'You do not have permission to create bookings',
          suggestion: 'Please contact the property owner',
        ),
      );
    } else {
      state = const AsyncValue.data(PermissionCheckResult(allowed: true));
    }
  }

  /// Check if user can cancel booking
  Future<void> checkCanCancelBooking(
    CalendarPermissions permissions,
    Booking booking,
  ) async {
    final canCancel = permissions.canCancelBooking(booking);

    if (!canCancel) {
      String reason;
      String? suggestion;

      if (permissions.isGuest) {
        if (booking.userId != permissions.userId) {
          reason = 'You can only cancel your own bookings';
        } else if (DateTime.now().isAfter(booking.checkIn)) {
          reason = 'Cannot cancel booking after check-in date';
          suggestion = 'Please contact the property owner for assistance';
        } else {
          reason = 'Cannot cancel this booking';
        }
      } else {
        reason = 'You do not have permission to cancel this booking';
      }

      state = AsyncValue.data(
        PermissionCheckResult.denied(
          reason: reason,
          suggestion: suggestion,
        ),
      );
    } else {
      state = const AsyncValue.data(PermissionCheckResult(allowed: true));
    }
  }

  /// Check if user can block dates
  Future<void> checkCanBlockDates(CalendarPermissions permissions) async {
    final canBlock = permissions.canBlockDates();

    if (!canBlock) {
      state = AsyncValue.data(
        PermissionCheckResult.denied(
          reason: 'Only property owners can block dates',
          suggestion:
              'Guests cannot block availability. Please contact the owner.',
        ),
      );
    } else {
      state = const AsyncValue.data(PermissionCheckResult(allowed: true));
    }
  }

  /// Reset state
  void reset() {
    state = const AsyncValue.data(PermissionCheckResult(allowed: true));
  }
}

/// Provider for user role display name
@riverpod
String userRoleDisplayName(UserRoleDisplayNameRef ref, String? propertyId) {
  final permissionsAsync = ref.watch(calendarPermissionsProvider(propertyId));

  return permissionsAsync.when(
    data: (permissions) => permissions.roleDisplayName,
    loading: () => 'Loading...',
    error: (_, __) => 'Guest',
  );
}
