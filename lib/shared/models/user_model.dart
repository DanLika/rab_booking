import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/constants/enums.dart';
import '../../core/services/logging_service.dart';
import '../../core/utils/timestamp_converter.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

/// Account type for subscription management
/// - trial: Free tier with limited features
/// - premium: Paid subscription via Stripe
/// - enterprise: Business tier (future use)
/// - lifetime: Admin-granted permanent premium access
enum AccountType {
  trial,
  premium,
  enterprise,
  lifetime;

  /// Fail-open decoder for Firestore docs that carry an unrecognised value
  /// (e.g. legacy doc with `accountType: 'active'` — a leaked status value).
  /// Returns [AccountType.trial] (lowest tier — NEVER paid) on unknown and
  /// surfaces the bad value to Sentry as a warning. F-108-04.
  ///
  /// Security note: the fallback MUST stay at the lowest tier so a garbage
  /// or attacker-supplied value cannot accidentally grant paid features.
  static AccountType fromJson(Object? raw) {
    final String? value = raw is String ? raw : null;
    if (value != null) {
      for (final t in AccountType.values) {
        if (t.name == value) return t;
      }
    }
    // Unknown / null / non-string → log + safe default.
    LoggingService.logWarningToSentry(
      'UserModel.accountType: unrecognised value, defaulting to trial',
      data: <String, dynamic>{
        'finding': 'F-108-04',
        'raw': value ?? raw?.toString() ?? 'null',
        'rawType': raw?.runtimeType.toString() ?? 'Null',
      },
    );
    return AccountType.trial;
  }

  /// Nullable variant for fields where missing = unset (e.g.
  /// `adminOverrideAccountType`). Null/missing → null (NOT trial). An
  /// explicitly-present unknown value still falls open to trial + logs.
  static AccountType? fromJsonNullable(Object? raw) {
    if (raw == null) return null;
    return fromJson(raw);
  }
}

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

    /// User email address.
    /// Default empty for Firestore docs missing the field (e.g. legacy seed
    /// rows pre-dating the auth-trigger backfill). Surfaces as a blank email
    /// in admin UIs rather than crashing the whole list. F-108-01.
    @Default('') String email,

    /// User's first name. Default empty for legacy docs missing the field.
    @JsonKey(name: 'first_name') @Default('') String firstName,

    /// User's last name. Default empty for legacy docs missing the field.
    @JsonKey(name: 'last_name') @Default('') String lastName,

    /// User role (guest, owner, admin)
    required UserRole role,

    /// Account type (trial, premium, enterprise, lifetime).
    /// Fail-open decode via [AccountType.fromJson] — unrecognised Firestore
    /// values fall back to [AccountType.trial] (lowest tier) and are logged
    /// to Sentry rather than crashing the whole list paint. F-108-04.
    @JsonKey(fromJson: AccountType.fromJson)
    @Default(AccountType.trial)
    AccountType accountType,

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
    /// Nullable for race condition when Google sign-in creates profile
    /// before Cloud Function sets timestamps
    @NullableTimestampConverter()
    @JsonKey(name: 'created_at')
    DateTime? createdAt,

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

    /// Admin-controlled: Override account type.
    /// null = use calculated status, otherwise use this value.
    /// Fail-open decode (F-108-04): missing/null stays null; an explicit
    /// unknown value falls back to [AccountType.trial] and logs to Sentry.
    @JsonKey(
      name: 'admin_override_account_type',
      fromJson: AccountType.fromJsonNullable,
    )
    AccountType? adminOverrideAccountType,

    /// Feature discovery flags (track which features the user has seen)
    /// Keys are feature IDs, values are true if seen
    @Default({}) Map<String, bool> featureFlags,

    /// Profile completion status for social sign-in users.
    /// Default true for backwards compatibility (existing users).
    /// Set to false when user registers via Google/Apple for the first time.
    @JsonKey(name: 'profile_completed') @Default(true) bool profileCompleted,

    /// Last authentication provider used.
    /// Values: 'google.com', 'apple.com', 'password', null
    /// Used to auto-populate profile data from social providers.
    @JsonKey(name: 'last_provider') String? lastProvider,

    /// Lifetime license: Timestamp when admin granted lifetime access
    @NullableTimestampConverter()
    @JsonKey(name: 'lifetime_license_granted_at')
    DateTime? lifetimeLicenseGrantedAt,

    /// Lifetime license: Admin UID who granted the license
    @JsonKey(name: 'lifetime_license_granted_by')
    String? lifetimeLicenseGrantedBy,
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

  /// Check if user has lifetime license (admin-granted permanent premium access)
  bool get isLifetimeLicense =>
      accountType == AccountType.lifetime ||
      adminOverrideAccountType == AccountType.lifetime;

  /// Get effective account type (considering admin override)
  AccountType get effectiveAccountType =>
      adminOverrideAccountType ?? accountType;

  /// Check if user has premium-level access (premium, enterprise, or lifetime)
  bool get hasPremiumAccess =>
      effectiveAccountType == AccountType.premium ||
      effectiveAccountType == AccountType.enterprise ||
      effectiveAccountType == AccountType.lifetime;
}
