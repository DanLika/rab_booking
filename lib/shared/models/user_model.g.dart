// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DeviceInfoImpl _$$DeviceInfoImplFromJson(Map<String, dynamic> json) =>
    _$DeviceInfoImpl(
      deviceId: json['deviceId'] as String,
      platform: json['platform'] as String,
      fcmToken: json['fcmToken'] as String?,
      lastSeenAt: DateTime.parse(json['lastSeenAt'] as String),
    );

Map<String, dynamic> _$$DeviceInfoImplToJson(_$DeviceInfoImpl instance) =>
    <String, dynamic>{
      'deviceId': instance.deviceId,
      'platform': instance.platform,
      'fcmToken': instance.fcmToken,
      'lastSeenAt': instance.lastSeenAt.toIso8601String(),
    };

_$SecurityEventImpl _$$SecurityEventImplFromJson(Map<String, dynamic> json) =>
    _$SecurityEventImpl(
      type: $enumDecode(_$SecurityEventTypeEnumMap, json['type']),
      timestamp: const TimestampConverter().fromJson(json['timestamp']),
      deviceId: json['deviceId'] as String?,
      ipAddress: json['ipAddress'] as String?,
      location: json['location'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$SecurityEventImplToJson(_$SecurityEventImpl instance) =>
    <String, dynamic>{
      'type': _$SecurityEventTypeEnumMap[instance.type]!,
      'timestamp': const TimestampConverter().toJson(instance.timestamp),
      'deviceId': instance.deviceId,
      'ipAddress': instance.ipAddress,
      'location': instance.location,
      'metadata': instance.metadata,
    };

const _$SecurityEventTypeEnumMap = {
  SecurityEventType.login: 'login',
  SecurityEventType.logout: 'logout',
  SecurityEventType.registration: 'registration',
  SecurityEventType.passwordChange: 'passwordChange',
  SecurityEventType.suspicious: 'suspicious',
  SecurityEventType.emailVerification: 'emailVerification',
};

_$EmployeePermissionsImpl _$$EmployeePermissionsImplFromJson(
  Map<String, dynamic> json,
) => _$EmployeePermissionsImpl(
  role: $enumDecode(_$EmployeeRoleEnumMap, json['role']),
  customPermissions: (json['customPermissions'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, e as bool),
  ),
);

Map<String, dynamic> _$$EmployeePermissionsImplToJson(
  _$EmployeePermissionsImpl instance,
) => <String, dynamic>{
  'role': _$EmployeeRoleEnumMap[instance.role]!,
  'customPermissions': instance.customPermissions,
};

const _$EmployeeRoleEnumMap = {
  EmployeeRole.administrator: 'administrator',
  EmployeeRole.reception: 'reception',
  EmployeeRole.cleaning: 'cleaning',
  EmployeeRole.investor: 'investor',
  EmployeeRole.fullAccess: 'fullAccess',
  EmployeeRole.own: 'own',
};

_$UserModelImpl _$$UserModelImplFromJson(
  Map<String, dynamic> json,
) => _$UserModelImpl(
  id: json['id'] as String,
  email: json['email'] as String,
  firstName: json['first_name'] as String,
  lastName: json['last_name'] as String,
  role: $enumDecode(_$UserRoleEnumMap, json['role']),
  accountType:
      $enumDecodeNullable(_$AccountTypeEnumMap, json['accountType']) ??
      AccountType.trial,
  emailVerified: json['emailVerified'] as bool? ?? false,
  phone: json['phone'] as String?,
  avatarUrl: json['avatar_url'] as String?,
  displayName: json['displayName'] as String?,
  onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
  lastLoginAt: const NullableTimestampConverter().fromJson(json['lastLoginAt']),
  employeeOf: json['employeeOf'] as String?,
  permissions: json['permissions'] == null
      ? null
      : EmployeePermissions.fromJson(
          json['permissions'] as Map<String, dynamic>,
        ),
  stripeAccountId: json['stripe_account_id'] as String?,
  stripeConnectedAt: const NullableTimestampConverter().fromJson(
    json['stripe_connected_at'],
  ),
  stripeDisconnectedAt: const NullableTimestampConverter().fromJson(
    json['stripe_disconnected_at'],
  ),
  createdAt: const TimestampConverter().fromJson(json['created_at']),
  updatedAt: const NullableTimestampConverter().fromJson(json['updated_at']),
  devices:
      (json['devices'] as List<dynamic>?)
          ?.map((e) => DeviceInfo.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  recentSecurityEvents:
      (json['recentSecurityEvents'] as List<dynamic>?)
          ?.map((e) => SecurityEvent.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  hideSubscription: json['hide_subscription'] as bool? ?? false,
  adminOverrideAccountType: $enumDecodeNullable(
    _$AccountTypeEnumMap,
    json['admin_override_account_type'],
  ),
  featureFlags:
      (json['featureFlags'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as bool),
      ) ??
      const {},
  profileCompleted: json['profile_completed'] as bool? ?? true,
  lastProvider: json['last_provider'] as String?,
  lifetimeLicenseGrantedAt: const NullableTimestampConverter().fromJson(
    json['lifetime_license_granted_at'],
  ),
  lifetimeLicenseGrantedBy: json['lifetime_license_granted_by'] as String?,
);

Map<String, dynamic> _$$UserModelImplToJson(
  _$UserModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'first_name': instance.firstName,
  'last_name': instance.lastName,
  'role': _$UserRoleEnumMap[instance.role]!,
  'accountType': _$AccountTypeEnumMap[instance.accountType]!,
  'emailVerified': instance.emailVerified,
  'phone': instance.phone,
  'avatar_url': instance.avatarUrl,
  'displayName': instance.displayName,
  'onboardingCompleted': instance.onboardingCompleted,
  'lastLoginAt': const NullableTimestampConverter().toJson(
    instance.lastLoginAt,
  ),
  'employeeOf': instance.employeeOf,
  'permissions': instance.permissions,
  'stripe_account_id': instance.stripeAccountId,
  'stripe_connected_at': const NullableTimestampConverter().toJson(
    instance.stripeConnectedAt,
  ),
  'stripe_disconnected_at': const NullableTimestampConverter().toJson(
    instance.stripeDisconnectedAt,
  ),
  'created_at': const TimestampConverter().toJson(instance.createdAt),
  'updated_at': const NullableTimestampConverter().toJson(instance.updatedAt),
  'devices': instance.devices,
  'recentSecurityEvents': instance.recentSecurityEvents,
  'hide_subscription': instance.hideSubscription,
  'admin_override_account_type':
      _$AccountTypeEnumMap[instance.adminOverrideAccountType],
  'featureFlags': instance.featureFlags,
  'profile_completed': instance.profileCompleted,
  'last_provider': instance.lastProvider,
  'lifetime_license_granted_at': const NullableTimestampConverter().toJson(
    instance.lifetimeLicenseGrantedAt,
  ),
  'lifetime_license_granted_by': instance.lifetimeLicenseGrantedBy,
};

const _$UserRoleEnumMap = {
  UserRole.guest: 'guest',
  UserRole.owner: 'owner',
  UserRole.admin: 'admin',
};

const _$AccountTypeEnumMap = {
  AccountType.trial: 'trial',
  AccountType.premium: 'premium',
  AccountType.enterprise: 'enterprise',
  AccountType.lifetime: 'lifetime',
};
