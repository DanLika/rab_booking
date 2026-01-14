import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/constants/enums.dart';
import '../../core/utils/timestamp_converter.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

/// Account type for subscription management
enum AccountType { trial, premium, enterprise }

/// Employee permission roles
enum EmployeeRole {
  administrator,
  reception,
  cleaning,
  investor,
  fullAccess,
  own, // Custom permissions
}

/// Device information for session tracking
@freezed
class DeviceInfo with _$DeviceInfo {
  const factory DeviceInfo({
    required String deviceId,
    required String platform, // iOS, Android, Web
    String? fcmToken,
    required DateTime lastSeenAt,
  }) = _DeviceInfo;

  factory DeviceInfo.fromJson(Map<String, dynamic> json) =>
      _$DeviceInfoFromJson(json);
}

/// Security event types
enum SecurityEventType {
  login,
  logout,
  registration,
  passwordChange,
  suspicious,
  emailVerification,
}

/// Security event for audit logging
@freezed
class SecurityEvent with _$SecurityEvent {
  const factory SecurityEvent({
    required SecurityEventType type,
    @TimestampConverter() required DateTime timestamp,
    String? deviceId,
    String? ipAddress,
    String? location,
    Map<String, dynamic>? metadata,
  }) = _SecurityEvent;

  factory SecurityEvent.fromJson(Map<String, dynamic> json) =>
      _$SecurityEventFromJson(json);

  factory SecurityEvent.fromFirestore(Map<String, dynamic> data) {
    return SecurityEvent(
      type: SecurityEventType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => SecurityEventType.login,
      ),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      deviceId: data['deviceId'] as String?,
      ipAddress: data['ipAddress'] as String?,
      location: data['location'] as String?,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }
}

/// Employee permissions (for employee role users)
@freezed
class EmployeePermissions with _$EmployeePermissions {
  const factory EmployeePermissions({
    required EmployeeRole role,
    Map<String, bool>? customPermissions,
  }) = _EmployeePermissions;

  factory EmployeePermissions.fromJson(Map<String, dynamic> json) =>
      _$EmployeePermissionsFromJson(json);
}

/// User model representing a user in the system
@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    /// User ID (UUID from Firebase Auth)
    required String id,

    /// User email address
    required String email,

    /// User's first name
    @JsonKey(name: 'first_name') required String firstName,

    /// User's last name
    @JsonKey(name: 'last_name') required String lastName,

    /// User role (guest, owner, admin)
    required UserRole role,

    /// Account type (trial, premium, enterprise)
    @Default(AccountType.trial) AccountType accountType,

    /// Email verification status
    @Default(false) bool emailVerified,

    /// Optional phone number
    String? phone,

    /// Optional avatar URL
    @JsonKey(name: 'avatar_url') String? avatarUrl,

    /// Display name (Firebase Auth)
    String? displayName,

    /// Onboarding completion status
    @Default(false) bool onboardingCompleted,

    /// Last login timestamp
    @NullableTimestampConverter() DateTime? lastLoginAt,

    /// Employee-specific: Owner user ID (if this user is an employee)
    String? employeeOf,

    /// Employee-specific: Permissions
    EmployeePermissions? permissions,

    /// Stripe Connect account ID
    @JsonKey(name: 'stripe_account_id') String? stripeAccountId,

    /// Stripe Connect onboarding completion timestamp
    @NullableTimestampConverter()
    @JsonKey(name: 'stripe_connected_at')
    DateTime? stripeConnectedAt,

    /// Stripe disconnection timestamp
    @NullableTimestampConverter()
    @JsonKey(name: 'stripe_disconnected_at')
    DateTime? stripeDisconnectedAt,

    /// Account creation timestamp
    @TimestampConverter()
    @JsonKey(name: 'created_at')
    required DateTime createdAt,

    /// Last update timestamp
    @NullableTimestampConverter()
    @JsonKey(name: 'updated_at')
    DateTime? updatedAt,

    /// Devices (for session management)
    @Default([]) List<DeviceInfo> devices,

    /// Security events (recent only, full history in subcollection)
    @Default([]) List<SecurityEvent> recentSecurityEvents,

    /// Admin-controlled: Hide subscription page from this user
    @JsonKey(name: 'hide_subscription') @Default(false) bool hideSubscription,

    /// Admin-controlled: Override account type
    /// null = use calculated status, otherwise use this value
    @JsonKey(name: 'admin_override_account_type')
    AccountType? adminOverrideAccountType,

    /// Feature discovery flags (track which features the user has seen)
    /// Keys are feature IDs, values are true if seen
    @Default({}) Map<String, bool> featureFlags,
  }) = _UserModel;

  const UserModel._();

  /// Create from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  /// Get full name
  String get fullName => '$firstName $lastName';

  /// Get initials for avatar
  String get initials {
    final first = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final last = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$first$last';
  }

  /// Check if user has completed profile
  bool get hasCompletedProfile {
    return firstName.isNotEmpty && lastName.isNotEmpty && email.isNotEmpty;
  }

  /// Check if user is a property owner
  bool get isOwner => role == UserRole.owner || role == UserRole.admin;

  /// Check if user is an admin
  bool get isAdmin => role == UserRole.admin;

  /// Check if user is an employee
  bool get isEmployee => employeeOf != null;

  /// Check if user has connected Stripe account
  bool get hasStripeConnected =>
      stripeAccountId != null && stripeAccountId!.isNotEmpty;

  /// Check if user needs onboarding
  bool get needsOnboarding => isOwner && !onboardingCompleted;
}
