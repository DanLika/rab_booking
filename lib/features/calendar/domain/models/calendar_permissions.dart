import 'package:freezed_annotation/freezed_annotation.dart';
import 'calendar_day.dart';

part 'calendar_permissions.freezed.dart';

/// User roles for calendar permissions
enum UserRole {
  guest,
  owner,
  superAdmin,
}

/// Booking model for permission checks
class Booking {
  final String id;
  final String userId;
  final String unitId;
  final DateTime checkIn;
  final DateTime checkOut;
  final String status;

  const Booking({
    required this.id,
    required this.userId,
    required this.unitId,
    required this.checkIn,
    required this.checkOut,
    required this.status,
  });
}

/// Property ownership information
class PropertyOwnership {
  final String propertyId;
  final String ownerId;
  final List<String> coOwners;

  const PropertyOwnership({
    required this.propertyId,
    required this.ownerId,
    this.coOwners = const [],
  });

  /// Check if user is owner or co-owner
  bool isOwner(String userId) {
    return userId == ownerId || coOwners.contains(userId);
  }
}

/// Calendar permissions manager
class CalendarPermissions {
  final UserRole role;
  final String userId;
  final PropertyOwnership? property;

  const CalendarPermissions({
    required this.role,
    required this.userId,
    this.property,
  });

  /// Factory: Create from user data
  factory CalendarPermissions.fromUser({
    required String userId,
    required String userRole,
    PropertyOwnership? property,
  }) {
    final role = _parseRole(userRole);
    return CalendarPermissions(
      role: role,
      userId: userId,
      property: property,
    );
  }

  /// Factory: Create guest permissions (no auth required)
  /// Guests can view calendar and select available dates
  factory CalendarPermissions.guest() {
    return const CalendarPermissions(
      role: UserRole.guest,
      userId: '',
    );
  }

  /// Factory: Create owner permissions
  factory CalendarPermissions.owner({
    required String userId,
    PropertyOwnership? property,
  }) {
    return CalendarPermissions(
      role: UserRole.owner,
      userId: userId,
      property: property,
    );
  }

  /// Factory: Create admin permissions
  factory CalendarPermissions.admin({required String userId}) {
    return CalendarPermissions(
      role: UserRole.superAdmin,
      userId: userId,
    );
  }

  /// Parse role string to enum
  static UserRole _parseRole(String roleString) {
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
  }

  // ==========================================================================
  // DATE SELECTION PERMISSIONS
  // ==========================================================================

  /// Check if user can select a specific date
  bool canSelectDate(CalendarDay day) {
    if (role == UserRole.guest) {
      // Guests can only select available dates
      return day.status == DayStatus.available;
    }

    // Owners and admins can select any date (for management purposes)
    return role == UserRole.owner || role == UserRole.superAdmin;
  }

  /// Check if user can select a date range
  bool canSelectDateRange(List<CalendarDay> days) {
    if (role == UserRole.guest) {
      // All days in range must be available for guests
      return days.every((day) => day.status == DayStatus.available);
    }

    // Owners and admins can select any range
    return role == UserRole.owner || role == UserRole.superAdmin;
  }

  // ==========================================================================
  // BOOKING PERMISSIONS
  // ==========================================================================

  /// Check if user can create a booking
  bool canCreateBooking(DateTimeRange range) {
    // All authenticated users can create bookings
    // (availability conflicts are handled separately)
    return true;
  }

  /// Check if user can view booking details
  bool canViewBooking(Booking booking) {
    if (role == UserRole.guest) {
      // Guests can only view their own bookings
      return booking.userId == userId;
    }

    // Owners and admins can view all bookings
    if (role == UserRole.superAdmin) return true;

    if (role == UserRole.owner && property != null) {
      // Owners can view bookings for their properties
      return property!.isOwner(userId);
    }

    return false;
  }

  /// Check if user can cancel a booking
  bool canCancelBooking(Booking booking) {
    if (role == UserRole.guest) {
      // Guests can only cancel their own bookings before check-in
      final isOwnBooking = booking.userId == userId;
      final isBeforeCheckIn = DateTime.now().isBefore(booking.checkIn);

      return isOwnBooking && isBeforeCheckIn;
    }

    // Super admins can cancel any booking
    if (role == UserRole.superAdmin) return true;

    // Owners can cancel bookings for their properties
    if (role == UserRole.owner && property != null) {
      return property!.isOwner(userId);
    }

    return false;
  }

  /// Check if user can modify a booking
  bool canModifyBooking(Booking booking) {
    if (role == UserRole.guest) {
      // Guests can only modify their own bookings before check-in
      final isOwnBooking = booking.userId == userId;
      final isBeforeCheckIn = DateTime.now().isBefore(booking.checkIn);

      return isOwnBooking && isBeforeCheckIn;
    }

    // Super admins can modify any booking
    if (role == UserRole.superAdmin) return true;

    // Owners can modify bookings for their properties
    if (role == UserRole.owner && property != null) {
      return property!.isOwner(userId);
    }

    return false;
  }

  // ==========================================================================
  // AVAILABILITY MANAGEMENT PERMISSIONS
  // ==========================================================================

  /// Check if user can block dates
  bool canBlockDates() {
    // Only owners and super admins can block dates
    return role == UserRole.owner || role == UserRole.superAdmin;
  }

  /// Check if user can unblock dates
  bool canUnblockDates() {
    // Only owners and super admins can unblock dates
    return role == UserRole.owner || role == UserRole.superAdmin;
  }

  /// Check if user can view blocked dates reason
  bool canViewBlockedReason() {
    // Owners and admins can see block reasons
    return role == UserRole.owner || role == UserRole.superAdmin;
  }

  // ==========================================================================
  // SETTINGS PERMISSIONS
  // ==========================================================================

  /// Check if user can modify calendar settings
  bool canModifySettings() {
    // Only owners and super admins can modify calendar settings
    return role == UserRole.owner || role == UserRole.superAdmin;
  }

  /// Check if user can set check-in/check-out times
  bool canSetDefaultTimes() {
    return role == UserRole.owner || role == UserRole.superAdmin;
  }

  /// Check if user can set minimum/maximum stay requirements
  bool canSetStayRequirements() {
    return role == UserRole.owner || role == UserRole.superAdmin;
  }

  /// Check if user can enable/disable same-day turnover
  bool canToggleSameDayTurnover() {
    return role == UserRole.owner || role == UserRole.superAdmin;
  }

  // ==========================================================================
  // VIEW PERMISSIONS
  // ==========================================================================

  /// Check if user can see check-in/check-out times
  bool canSeeBookingTimes() {
    // Only owners and admins can see specific times
    return role == UserRole.owner || role == UserRole.superAdmin;
  }

  /// Check if user can see guest information
  bool canSeeGuestInfo() {
    // Only owners and admins can see guest details
    return role == UserRole.owner || role == UserRole.superAdmin;
  }

  /// Check if user can see booking prices
  bool canSeePricing() {
    // All roles can see pricing (their own or as owner)
    return true;
  }

  /// Check if user can access owner dashboard
  bool canAccessOwnerDashboard() {
    return role == UserRole.owner || role == UserRole.superAdmin;
  }

  // ==========================================================================
  // ANALYTICS PERMISSIONS
  // ==========================================================================

  /// Check if user can view occupancy analytics
  bool canViewAnalytics() {
    return role == UserRole.owner || role == UserRole.superAdmin;
  }

  /// Check if user can view revenue reports
  bool canViewRevenueReports() {
    return role == UserRole.owner || role == UserRole.superAdmin;
  }

  /// Check if user can export calendar data
  bool canExportCalendar() {
    return role == UserRole.owner || role == UserRole.superAdmin;
  }

  // ==========================================================================
  // HELPER METHODS
  // ==========================================================================

  /// Check if user is a guest
  bool get isGuest => role == UserRole.guest;

  /// Check if user is an owner
  bool get isOwner => role == UserRole.owner;

  /// Check if user is a super admin
  bool get isSuperAdmin => role == UserRole.superAdmin;

  /// Check if user has elevated permissions (owner or admin)
  bool get hasElevatedPermissions =>
      role == UserRole.owner || role == UserRole.superAdmin;

  /// Get display name for role
  String get roleDisplayName {
    switch (role) {
      case UserRole.guest:
        return 'Guest';
      case UserRole.owner:
        return 'Owner';
      case UserRole.superAdmin:
        return 'Super Admin';
    }
  }

  @override
  String toString() {
    return 'CalendarPermissions(role: $roleDisplayName, userId: $userId)';
  }
}

/// Permission check result with explanation
@freezed
class PermissionCheckResult with _$PermissionCheckResult {
  const factory PermissionCheckResult({
    required bool allowed,
    String? reason,
    String? suggestion,
  }) = _PermissionCheckResult;

  factory PermissionCheckResult.allowed() {
    return const PermissionCheckResult(allowed: true);
  }

  factory PermissionCheckResult.denied({
    required String reason,
    String? suggestion,
  }) {
    return PermissionCheckResult(
      allowed: false,
      reason: reason,
      suggestion: suggestion,
    );
  }
}
