// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

DeviceInfo _$DeviceInfoFromJson(Map<String, dynamic> json) {
  return _DeviceInfo.fromJson(json);
}

/// @nodoc
mixin _$DeviceInfo {
  String get deviceId => throw _privateConstructorUsedError;
  String get platform =>
      throw _privateConstructorUsedError; // iOS, Android, Web
  String? get fcmToken => throw _privateConstructorUsedError;
  DateTime get lastSeenAt => throw _privateConstructorUsedError;

  /// Serializes this DeviceInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DeviceInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DeviceInfoCopyWith<DeviceInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DeviceInfoCopyWith<$Res> {
  factory $DeviceInfoCopyWith(
    DeviceInfo value,
    $Res Function(DeviceInfo) then,
  ) = _$DeviceInfoCopyWithImpl<$Res, DeviceInfo>;
  @useResult
  $Res call({
    String deviceId,
    String platform,
    String? fcmToken,
    DateTime lastSeenAt,
  });
}

/// @nodoc
class _$DeviceInfoCopyWithImpl<$Res, $Val extends DeviceInfo>
    implements $DeviceInfoCopyWith<$Res> {
  _$DeviceInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DeviceInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? deviceId = null,
    Object? platform = null,
    Object? fcmToken = freezed,
    Object? lastSeenAt = null,
  }) {
    return _then(
      _value.copyWith(
            deviceId: null == deviceId
                ? _value.deviceId
                : deviceId // ignore: cast_nullable_to_non_nullable
                      as String,
            platform: null == platform
                ? _value.platform
                : platform // ignore: cast_nullable_to_non_nullable
                      as String,
            fcmToken: freezed == fcmToken
                ? _value.fcmToken
                : fcmToken // ignore: cast_nullable_to_non_nullable
                      as String?,
            lastSeenAt: null == lastSeenAt
                ? _value.lastSeenAt
                : lastSeenAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DeviceInfoImplCopyWith<$Res>
    implements $DeviceInfoCopyWith<$Res> {
  factory _$$DeviceInfoImplCopyWith(
    _$DeviceInfoImpl value,
    $Res Function(_$DeviceInfoImpl) then,
  ) = __$$DeviceInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String deviceId,
    String platform,
    String? fcmToken,
    DateTime lastSeenAt,
  });
}

/// @nodoc
class __$$DeviceInfoImplCopyWithImpl<$Res>
    extends _$DeviceInfoCopyWithImpl<$Res, _$DeviceInfoImpl>
    implements _$$DeviceInfoImplCopyWith<$Res> {
  __$$DeviceInfoImplCopyWithImpl(
    _$DeviceInfoImpl _value,
    $Res Function(_$DeviceInfoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DeviceInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? deviceId = null,
    Object? platform = null,
    Object? fcmToken = freezed,
    Object? lastSeenAt = null,
  }) {
    return _then(
      _$DeviceInfoImpl(
        deviceId: null == deviceId
            ? _value.deviceId
            : deviceId // ignore: cast_nullable_to_non_nullable
                  as String,
        platform: null == platform
            ? _value.platform
            : platform // ignore: cast_nullable_to_non_nullable
                  as String,
        fcmToken: freezed == fcmToken
            ? _value.fcmToken
            : fcmToken // ignore: cast_nullable_to_non_nullable
                  as String?,
        lastSeenAt: null == lastSeenAt
            ? _value.lastSeenAt
            : lastSeenAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DeviceInfoImpl implements _DeviceInfo {
  const _$DeviceInfoImpl({
    required this.deviceId,
    required this.platform,
    this.fcmToken,
    required this.lastSeenAt,
  });

  factory _$DeviceInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$DeviceInfoImplFromJson(json);

  @override
  final String deviceId;
  @override
  final String platform;
  // iOS, Android, Web
  @override
  final String? fcmToken;
  @override
  final DateTime lastSeenAt;

  @override
  String toString() {
    return 'DeviceInfo(deviceId: $deviceId, platform: $platform, fcmToken: $fcmToken, lastSeenAt: $lastSeenAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DeviceInfoImpl &&
            (identical(other.deviceId, deviceId) ||
                other.deviceId == deviceId) &&
            (identical(other.platform, platform) ||
                other.platform == platform) &&
            (identical(other.fcmToken, fcmToken) ||
                other.fcmToken == fcmToken) &&
            (identical(other.lastSeenAt, lastSeenAt) ||
                other.lastSeenAt == lastSeenAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, deviceId, platform, fcmToken, lastSeenAt);

  /// Create a copy of DeviceInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DeviceInfoImplCopyWith<_$DeviceInfoImpl> get copyWith =>
      __$$DeviceInfoImplCopyWithImpl<_$DeviceInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DeviceInfoImplToJson(this);
  }
}

abstract class _DeviceInfo implements DeviceInfo {
  const factory _DeviceInfo({
    required final String deviceId,
    required final String platform,
    final String? fcmToken,
    required final DateTime lastSeenAt,
  }) = _$DeviceInfoImpl;

  factory _DeviceInfo.fromJson(Map<String, dynamic> json) =
      _$DeviceInfoImpl.fromJson;

  @override
  String get deviceId;
  @override
  String get platform; // iOS, Android, Web
  @override
  String? get fcmToken;
  @override
  DateTime get lastSeenAt;

  /// Create a copy of DeviceInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DeviceInfoImplCopyWith<_$DeviceInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SecurityEvent _$SecurityEventFromJson(Map<String, dynamic> json) {
  return _SecurityEvent.fromJson(json);
}

/// @nodoc
mixin _$SecurityEvent {
  SecurityEventType get type => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get timestamp => throw _privateConstructorUsedError;
  String? get deviceId => throw _privateConstructorUsedError;
  String? get ipAddress => throw _privateConstructorUsedError;
  String? get location => throw _privateConstructorUsedError;
  Map<String, dynamic>? get metadata => throw _privateConstructorUsedError;

  /// Serializes this SecurityEvent to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SecurityEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SecurityEventCopyWith<SecurityEvent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SecurityEventCopyWith<$Res> {
  factory $SecurityEventCopyWith(
    SecurityEvent value,
    $Res Function(SecurityEvent) then,
  ) = _$SecurityEventCopyWithImpl<$Res, SecurityEvent>;
  @useResult
  $Res call({
    SecurityEventType type,
    @TimestampConverter() DateTime timestamp,
    String? deviceId,
    String? ipAddress,
    String? location,
    Map<String, dynamic>? metadata,
  });
}

/// @nodoc
class _$SecurityEventCopyWithImpl<$Res, $Val extends SecurityEvent>
    implements $SecurityEventCopyWith<$Res> {
  _$SecurityEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SecurityEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? timestamp = null,
    Object? deviceId = freezed,
    Object? ipAddress = freezed,
    Object? location = freezed,
    Object? metadata = freezed,
  }) {
    return _then(
      _value.copyWith(
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as SecurityEventType,
            timestamp: null == timestamp
                ? _value.timestamp
                : timestamp // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            deviceId: freezed == deviceId
                ? _value.deviceId
                : deviceId // ignore: cast_nullable_to_non_nullable
                      as String?,
            ipAddress: freezed == ipAddress
                ? _value.ipAddress
                : ipAddress // ignore: cast_nullable_to_non_nullable
                      as String?,
            location: freezed == location
                ? _value.location
                : location // ignore: cast_nullable_to_non_nullable
                      as String?,
            metadata: freezed == metadata
                ? _value.metadata
                : metadata // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SecurityEventImplCopyWith<$Res>
    implements $SecurityEventCopyWith<$Res> {
  factory _$$SecurityEventImplCopyWith(
    _$SecurityEventImpl value,
    $Res Function(_$SecurityEventImpl) then,
  ) = __$$SecurityEventImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    SecurityEventType type,
    @TimestampConverter() DateTime timestamp,
    String? deviceId,
    String? ipAddress,
    String? location,
    Map<String, dynamic>? metadata,
  });
}

/// @nodoc
class __$$SecurityEventImplCopyWithImpl<$Res>
    extends _$SecurityEventCopyWithImpl<$Res, _$SecurityEventImpl>
    implements _$$SecurityEventImplCopyWith<$Res> {
  __$$SecurityEventImplCopyWithImpl(
    _$SecurityEventImpl _value,
    $Res Function(_$SecurityEventImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SecurityEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? timestamp = null,
    Object? deviceId = freezed,
    Object? ipAddress = freezed,
    Object? location = freezed,
    Object? metadata = freezed,
  }) {
    return _then(
      _$SecurityEventImpl(
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as SecurityEventType,
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        deviceId: freezed == deviceId
            ? _value.deviceId
            : deviceId // ignore: cast_nullable_to_non_nullable
                  as String?,
        ipAddress: freezed == ipAddress
            ? _value.ipAddress
            : ipAddress // ignore: cast_nullable_to_non_nullable
                  as String?,
        location: freezed == location
            ? _value.location
            : location // ignore: cast_nullable_to_non_nullable
                  as String?,
        metadata: freezed == metadata
            ? _value._metadata
            : metadata // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SecurityEventImpl implements _SecurityEvent {
  const _$SecurityEventImpl({
    required this.type,
    @TimestampConverter() required this.timestamp,
    this.deviceId,
    this.ipAddress,
    this.location,
    final Map<String, dynamic>? metadata,
  }) : _metadata = metadata;

  factory _$SecurityEventImpl.fromJson(Map<String, dynamic> json) =>
      _$$SecurityEventImplFromJson(json);

  @override
  final SecurityEventType type;
  @override
  @TimestampConverter()
  final DateTime timestamp;
  @override
  final String? deviceId;
  @override
  final String? ipAddress;
  @override
  final String? location;
  final Map<String, dynamic>? _metadata;
  @override
  Map<String, dynamic>? get metadata {
    final value = _metadata;
    if (value == null) return null;
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'SecurityEvent(type: $type, timestamp: $timestamp, deviceId: $deviceId, ipAddress: $ipAddress, location: $location, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SecurityEventImpl &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.deviceId, deviceId) ||
                other.deviceId == deviceId) &&
            (identical(other.ipAddress, ipAddress) ||
                other.ipAddress == ipAddress) &&
            (identical(other.location, location) ||
                other.location == location) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    type,
    timestamp,
    deviceId,
    ipAddress,
    location,
    const DeepCollectionEquality().hash(_metadata),
  );

  /// Create a copy of SecurityEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SecurityEventImplCopyWith<_$SecurityEventImpl> get copyWith =>
      __$$SecurityEventImplCopyWithImpl<_$SecurityEventImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SecurityEventImplToJson(this);
  }
}

abstract class _SecurityEvent implements SecurityEvent {
  const factory _SecurityEvent({
    required final SecurityEventType type,
    @TimestampConverter() required final DateTime timestamp,
    final String? deviceId,
    final String? ipAddress,
    final String? location,
    final Map<String, dynamic>? metadata,
  }) = _$SecurityEventImpl;

  factory _SecurityEvent.fromJson(Map<String, dynamic> json) =
      _$SecurityEventImpl.fromJson;

  @override
  SecurityEventType get type;
  @override
  @TimestampConverter()
  DateTime get timestamp;
  @override
  String? get deviceId;
  @override
  String? get ipAddress;
  @override
  String? get location;
  @override
  Map<String, dynamic>? get metadata;

  /// Create a copy of SecurityEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SecurityEventImplCopyWith<_$SecurityEventImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

EmployeePermissions _$EmployeePermissionsFromJson(Map<String, dynamic> json) {
  return _EmployeePermissions.fromJson(json);
}

/// @nodoc
mixin _$EmployeePermissions {
  EmployeeRole get role => throw _privateConstructorUsedError;
  Map<String, bool>? get customPermissions =>
      throw _privateConstructorUsedError;

  /// Serializes this EmployeePermissions to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EmployeePermissions
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EmployeePermissionsCopyWith<EmployeePermissions> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EmployeePermissionsCopyWith<$Res> {
  factory $EmployeePermissionsCopyWith(
    EmployeePermissions value,
    $Res Function(EmployeePermissions) then,
  ) = _$EmployeePermissionsCopyWithImpl<$Res, EmployeePermissions>;
  @useResult
  $Res call({EmployeeRole role, Map<String, bool>? customPermissions});
}

/// @nodoc
class _$EmployeePermissionsCopyWithImpl<$Res, $Val extends EmployeePermissions>
    implements $EmployeePermissionsCopyWith<$Res> {
  _$EmployeePermissionsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EmployeePermissions
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? role = null, Object? customPermissions = freezed}) {
    return _then(
      _value.copyWith(
            role: null == role
                ? _value.role
                : role // ignore: cast_nullable_to_non_nullable
                      as EmployeeRole,
            customPermissions: freezed == customPermissions
                ? _value.customPermissions
                : customPermissions // ignore: cast_nullable_to_non_nullable
                      as Map<String, bool>?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$EmployeePermissionsImplCopyWith<$Res>
    implements $EmployeePermissionsCopyWith<$Res> {
  factory _$$EmployeePermissionsImplCopyWith(
    _$EmployeePermissionsImpl value,
    $Res Function(_$EmployeePermissionsImpl) then,
  ) = __$$EmployeePermissionsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({EmployeeRole role, Map<String, bool>? customPermissions});
}

/// @nodoc
class __$$EmployeePermissionsImplCopyWithImpl<$Res>
    extends _$EmployeePermissionsCopyWithImpl<$Res, _$EmployeePermissionsImpl>
    implements _$$EmployeePermissionsImplCopyWith<$Res> {
  __$$EmployeePermissionsImplCopyWithImpl(
    _$EmployeePermissionsImpl _value,
    $Res Function(_$EmployeePermissionsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of EmployeePermissions
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? role = null, Object? customPermissions = freezed}) {
    return _then(
      _$EmployeePermissionsImpl(
        role: null == role
            ? _value.role
            : role // ignore: cast_nullable_to_non_nullable
                  as EmployeeRole,
        customPermissions: freezed == customPermissions
            ? _value._customPermissions
            : customPermissions // ignore: cast_nullable_to_non_nullable
                  as Map<String, bool>?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$EmployeePermissionsImpl implements _EmployeePermissions {
  const _$EmployeePermissionsImpl({
    required this.role,
    final Map<String, bool>? customPermissions,
  }) : _customPermissions = customPermissions;

  factory _$EmployeePermissionsImpl.fromJson(Map<String, dynamic> json) =>
      _$$EmployeePermissionsImplFromJson(json);

  @override
  final EmployeeRole role;
  final Map<String, bool>? _customPermissions;
  @override
  Map<String, bool>? get customPermissions {
    final value = _customPermissions;
    if (value == null) return null;
    if (_customPermissions is EqualUnmodifiableMapView)
      return _customPermissions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'EmployeePermissions(role: $role, customPermissions: $customPermissions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EmployeePermissionsImpl &&
            (identical(other.role, role) || other.role == role) &&
            const DeepCollectionEquality().equals(
              other._customPermissions,
              _customPermissions,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    role,
    const DeepCollectionEquality().hash(_customPermissions),
  );

  /// Create a copy of EmployeePermissions
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EmployeePermissionsImplCopyWith<_$EmployeePermissionsImpl> get copyWith =>
      __$$EmployeePermissionsImplCopyWithImpl<_$EmployeePermissionsImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$EmployeePermissionsImplToJson(this);
  }
}

abstract class _EmployeePermissions implements EmployeePermissions {
  const factory _EmployeePermissions({
    required final EmployeeRole role,
    final Map<String, bool>? customPermissions,
  }) = _$EmployeePermissionsImpl;

  factory _EmployeePermissions.fromJson(Map<String, dynamic> json) =
      _$EmployeePermissionsImpl.fromJson;

  @override
  EmployeeRole get role;
  @override
  Map<String, bool>? get customPermissions;

  /// Create a copy of EmployeePermissions
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EmployeePermissionsImplCopyWith<_$EmployeePermissionsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserModel _$UserModelFromJson(Map<String, dynamic> json) {
  return _UserModel.fromJson(json);
}

/// @nodoc
mixin _$UserModel {
  /// User ID (UUID from Firebase Auth)
  String get id => throw _privateConstructorUsedError;

  /// User email address
  String get email => throw _privateConstructorUsedError;

  /// User's first name
  @JsonKey(name: 'first_name')
  String get firstName => throw _privateConstructorUsedError;

  /// User's last name
  @JsonKey(name: 'last_name')
  String get lastName => throw _privateConstructorUsedError;

  /// User role (guest, owner, admin)
  UserRole get role => throw _privateConstructorUsedError;

  /// Account type (trial, premium, enterprise)
  AccountType get accountType => throw _privateConstructorUsedError;

  /// Email verification status
  bool get emailVerified => throw _privateConstructorUsedError;

  /// Optional phone number
  String? get phone => throw _privateConstructorUsedError;

  /// Optional avatar URL
  @JsonKey(name: 'avatar_url')
  String? get avatarUrl => throw _privateConstructorUsedError;

  /// Display name (Firebase Auth)
  String? get displayName => throw _privateConstructorUsedError;

  /// Onboarding completion status
  bool get onboardingCompleted => throw _privateConstructorUsedError;

  /// Last login timestamp
  @NullableTimestampConverter()
  DateTime? get lastLoginAt => throw _privateConstructorUsedError;

  /// Employee-specific: Owner user ID (if this user is an employee)
  String? get employeeOf => throw _privateConstructorUsedError;

  /// Employee-specific: Permissions
  EmployeePermissions? get permissions => throw _privateConstructorUsedError;

  /// Stripe Connect account ID
  @JsonKey(name: 'stripe_account_id')
  String? get stripeAccountId => throw _privateConstructorUsedError;

  /// Stripe Connect onboarding completion timestamp
  @NullableTimestampConverter()
  @JsonKey(name: 'stripe_connected_at')
  DateTime? get stripeConnectedAt => throw _privateConstructorUsedError;

  /// Stripe disconnection timestamp
  @NullableTimestampConverter()
  @JsonKey(name: 'stripe_disconnected_at')
  DateTime? get stripeDisconnectedAt => throw _privateConstructorUsedError;

  /// Account creation timestamp
  @TimestampConverter()
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Last update timestamp
  @NullableTimestampConverter()
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Devices (for session management)
  List<DeviceInfo> get devices => throw _privateConstructorUsedError;

  /// Security events (recent only, full history in subcollection)
  List<SecurityEvent> get recentSecurityEvents =>
      throw _privateConstructorUsedError;

  /// Serializes this UserModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserModelCopyWith<UserModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserModelCopyWith<$Res> {
  factory $UserModelCopyWith(UserModel value, $Res Function(UserModel) then) =
      _$UserModelCopyWithImpl<$Res, UserModel>;
  @useResult
  $Res call({
    String id,
    String email,
    @JsonKey(name: 'first_name') String firstName,
    @JsonKey(name: 'last_name') String lastName,
    UserRole role,
    AccountType accountType,
    bool emailVerified,
    String? phone,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    String? displayName,
    bool onboardingCompleted,
    @NullableTimestampConverter() DateTime? lastLoginAt,
    String? employeeOf,
    EmployeePermissions? permissions,
    @JsonKey(name: 'stripe_account_id') String? stripeAccountId,
    @NullableTimestampConverter()
    @JsonKey(name: 'stripe_connected_at')
    DateTime? stripeConnectedAt,
    @NullableTimestampConverter()
    @JsonKey(name: 'stripe_disconnected_at')
    DateTime? stripeDisconnectedAt,
    @TimestampConverter() @JsonKey(name: 'created_at') DateTime createdAt,
    @NullableTimestampConverter()
    @JsonKey(name: 'updated_at')
    DateTime? updatedAt,
    List<DeviceInfo> devices,
    List<SecurityEvent> recentSecurityEvents,
  });

  $EmployeePermissionsCopyWith<$Res>? get permissions;
}

/// @nodoc
class _$UserModelCopyWithImpl<$Res, $Val extends UserModel>
    implements $UserModelCopyWith<$Res> {
  _$UserModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = null,
    Object? firstName = null,
    Object? lastName = null,
    Object? role = null,
    Object? accountType = null,
    Object? emailVerified = null,
    Object? phone = freezed,
    Object? avatarUrl = freezed,
    Object? displayName = freezed,
    Object? onboardingCompleted = null,
    Object? lastLoginAt = freezed,
    Object? employeeOf = freezed,
    Object? permissions = freezed,
    Object? stripeAccountId = freezed,
    Object? stripeConnectedAt = freezed,
    Object? stripeDisconnectedAt = freezed,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? devices = null,
    Object? recentSecurityEvents = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            email: null == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String,
            firstName: null == firstName
                ? _value.firstName
                : firstName // ignore: cast_nullable_to_non_nullable
                      as String,
            lastName: null == lastName
                ? _value.lastName
                : lastName // ignore: cast_nullable_to_non_nullable
                      as String,
            role: null == role
                ? _value.role
                : role // ignore: cast_nullable_to_non_nullable
                      as UserRole,
            accountType: null == accountType
                ? _value.accountType
                : accountType // ignore: cast_nullable_to_non_nullable
                      as AccountType,
            emailVerified: null == emailVerified
                ? _value.emailVerified
                : emailVerified // ignore: cast_nullable_to_non_nullable
                      as bool,
            phone: freezed == phone
                ? _value.phone
                : phone // ignore: cast_nullable_to_non_nullable
                      as String?,
            avatarUrl: freezed == avatarUrl
                ? _value.avatarUrl
                : avatarUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            displayName: freezed == displayName
                ? _value.displayName
                : displayName // ignore: cast_nullable_to_non_nullable
                      as String?,
            onboardingCompleted: null == onboardingCompleted
                ? _value.onboardingCompleted
                : onboardingCompleted // ignore: cast_nullable_to_non_nullable
                      as bool,
            lastLoginAt: freezed == lastLoginAt
                ? _value.lastLoginAt
                : lastLoginAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            employeeOf: freezed == employeeOf
                ? _value.employeeOf
                : employeeOf // ignore: cast_nullable_to_non_nullable
                      as String?,
            permissions: freezed == permissions
                ? _value.permissions
                : permissions // ignore: cast_nullable_to_non_nullable
                      as EmployeePermissions?,
            stripeAccountId: freezed == stripeAccountId
                ? _value.stripeAccountId
                : stripeAccountId // ignore: cast_nullable_to_non_nullable
                      as String?,
            stripeConnectedAt: freezed == stripeConnectedAt
                ? _value.stripeConnectedAt
                : stripeConnectedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            stripeDisconnectedAt: freezed == stripeDisconnectedAt
                ? _value.stripeDisconnectedAt
                : stripeDisconnectedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            devices: null == devices
                ? _value.devices
                : devices // ignore: cast_nullable_to_non_nullable
                      as List<DeviceInfo>,
            recentSecurityEvents: null == recentSecurityEvents
                ? _value.recentSecurityEvents
                : recentSecurityEvents // ignore: cast_nullable_to_non_nullable
                      as List<SecurityEvent>,
          )
          as $Val,
    );
  }

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $EmployeePermissionsCopyWith<$Res>? get permissions {
    if (_value.permissions == null) {
      return null;
    }

    return $EmployeePermissionsCopyWith<$Res>(_value.permissions!, (value) {
      return _then(_value.copyWith(permissions: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$UserModelImplCopyWith<$Res>
    implements $UserModelCopyWith<$Res> {
  factory _$$UserModelImplCopyWith(
    _$UserModelImpl value,
    $Res Function(_$UserModelImpl) then,
  ) = __$$UserModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String email,
    @JsonKey(name: 'first_name') String firstName,
    @JsonKey(name: 'last_name') String lastName,
    UserRole role,
    AccountType accountType,
    bool emailVerified,
    String? phone,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    String? displayName,
    bool onboardingCompleted,
    @NullableTimestampConverter() DateTime? lastLoginAt,
    String? employeeOf,
    EmployeePermissions? permissions,
    @JsonKey(name: 'stripe_account_id') String? stripeAccountId,
    @NullableTimestampConverter()
    @JsonKey(name: 'stripe_connected_at')
    DateTime? stripeConnectedAt,
    @NullableTimestampConverter()
    @JsonKey(name: 'stripe_disconnected_at')
    DateTime? stripeDisconnectedAt,
    @TimestampConverter() @JsonKey(name: 'created_at') DateTime createdAt,
    @NullableTimestampConverter()
    @JsonKey(name: 'updated_at')
    DateTime? updatedAt,
    List<DeviceInfo> devices,
    List<SecurityEvent> recentSecurityEvents,
  });

  @override
  $EmployeePermissionsCopyWith<$Res>? get permissions;
}

/// @nodoc
class __$$UserModelImplCopyWithImpl<$Res>
    extends _$UserModelCopyWithImpl<$Res, _$UserModelImpl>
    implements _$$UserModelImplCopyWith<$Res> {
  __$$UserModelImplCopyWithImpl(
    _$UserModelImpl _value,
    $Res Function(_$UserModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = null,
    Object? firstName = null,
    Object? lastName = null,
    Object? role = null,
    Object? accountType = null,
    Object? emailVerified = null,
    Object? phone = freezed,
    Object? avatarUrl = freezed,
    Object? displayName = freezed,
    Object? onboardingCompleted = null,
    Object? lastLoginAt = freezed,
    Object? employeeOf = freezed,
    Object? permissions = freezed,
    Object? stripeAccountId = freezed,
    Object? stripeConnectedAt = freezed,
    Object? stripeDisconnectedAt = freezed,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? devices = null,
    Object? recentSecurityEvents = null,
  }) {
    return _then(
      _$UserModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        email: null == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String,
        firstName: null == firstName
            ? _value.firstName
            : firstName // ignore: cast_nullable_to_non_nullable
                  as String,
        lastName: null == lastName
            ? _value.lastName
            : lastName // ignore: cast_nullable_to_non_nullable
                  as String,
        role: null == role
            ? _value.role
            : role // ignore: cast_nullable_to_non_nullable
                  as UserRole,
        accountType: null == accountType
            ? _value.accountType
            : accountType // ignore: cast_nullable_to_non_nullable
                  as AccountType,
        emailVerified: null == emailVerified
            ? _value.emailVerified
            : emailVerified // ignore: cast_nullable_to_non_nullable
                  as bool,
        phone: freezed == phone
            ? _value.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String?,
        avatarUrl: freezed == avatarUrl
            ? _value.avatarUrl
            : avatarUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        displayName: freezed == displayName
            ? _value.displayName
            : displayName // ignore: cast_nullable_to_non_nullable
                  as String?,
        onboardingCompleted: null == onboardingCompleted
            ? _value.onboardingCompleted
            : onboardingCompleted // ignore: cast_nullable_to_non_nullable
                  as bool,
        lastLoginAt: freezed == lastLoginAt
            ? _value.lastLoginAt
            : lastLoginAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        employeeOf: freezed == employeeOf
            ? _value.employeeOf
            : employeeOf // ignore: cast_nullable_to_non_nullable
                  as String?,
        permissions: freezed == permissions
            ? _value.permissions
            : permissions // ignore: cast_nullable_to_non_nullable
                  as EmployeePermissions?,
        stripeAccountId: freezed == stripeAccountId
            ? _value.stripeAccountId
            : stripeAccountId // ignore: cast_nullable_to_non_nullable
                  as String?,
        stripeConnectedAt: freezed == stripeConnectedAt
            ? _value.stripeConnectedAt
            : stripeConnectedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        stripeDisconnectedAt: freezed == stripeDisconnectedAt
            ? _value.stripeDisconnectedAt
            : stripeDisconnectedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        devices: null == devices
            ? _value._devices
            : devices // ignore: cast_nullable_to_non_nullable
                  as List<DeviceInfo>,
        recentSecurityEvents: null == recentSecurityEvents
            ? _value._recentSecurityEvents
            : recentSecurityEvents // ignore: cast_nullable_to_non_nullable
                  as List<SecurityEvent>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UserModelImpl extends _UserModel {
  const _$UserModelImpl({
    required this.id,
    required this.email,
    @JsonKey(name: 'first_name') required this.firstName,
    @JsonKey(name: 'last_name') required this.lastName,
    required this.role,
    this.accountType = AccountType.trial,
    this.emailVerified = false,
    this.phone,
    @JsonKey(name: 'avatar_url') this.avatarUrl,
    this.displayName,
    this.onboardingCompleted = false,
    @NullableTimestampConverter() this.lastLoginAt,
    this.employeeOf,
    this.permissions,
    @JsonKey(name: 'stripe_account_id') this.stripeAccountId,
    @NullableTimestampConverter()
    @JsonKey(name: 'stripe_connected_at')
    this.stripeConnectedAt,
    @NullableTimestampConverter()
    @JsonKey(name: 'stripe_disconnected_at')
    this.stripeDisconnectedAt,
    @TimestampConverter() @JsonKey(name: 'created_at') required this.createdAt,
    @NullableTimestampConverter() @JsonKey(name: 'updated_at') this.updatedAt,
    final List<DeviceInfo> devices = const [],
    final List<SecurityEvent> recentSecurityEvents = const [],
  }) : _devices = devices,
       _recentSecurityEvents = recentSecurityEvents,
       super._();

  factory _$UserModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserModelImplFromJson(json);

  /// User ID (UUID from Firebase Auth)
  @override
  final String id;

  /// User email address
  @override
  final String email;

  /// User's first name
  @override
  @JsonKey(name: 'first_name')
  final String firstName;

  /// User's last name
  @override
  @JsonKey(name: 'last_name')
  final String lastName;

  /// User role (guest, owner, admin)
  @override
  final UserRole role;

  /// Account type (trial, premium, enterprise)
  @override
  @JsonKey()
  final AccountType accountType;

  /// Email verification status
  @override
  @JsonKey()
  final bool emailVerified;

  /// Optional phone number
  @override
  final String? phone;

  /// Optional avatar URL
  @override
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;

  /// Display name (Firebase Auth)
  @override
  final String? displayName;

  /// Onboarding completion status
  @override
  @JsonKey()
  final bool onboardingCompleted;

  /// Last login timestamp
  @override
  @NullableTimestampConverter()
  final DateTime? lastLoginAt;

  /// Employee-specific: Owner user ID (if this user is an employee)
  @override
  final String? employeeOf;

  /// Employee-specific: Permissions
  @override
  final EmployeePermissions? permissions;

  /// Stripe Connect account ID
  @override
  @JsonKey(name: 'stripe_account_id')
  final String? stripeAccountId;

  /// Stripe Connect onboarding completion timestamp
  @override
  @NullableTimestampConverter()
  @JsonKey(name: 'stripe_connected_at')
  final DateTime? stripeConnectedAt;

  /// Stripe disconnection timestamp
  @override
  @NullableTimestampConverter()
  @JsonKey(name: 'stripe_disconnected_at')
  final DateTime? stripeDisconnectedAt;

  /// Account creation timestamp
  @override
  @TimestampConverter()
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  /// Last update timestamp
  @override
  @NullableTimestampConverter()
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  /// Devices (for session management)
  final List<DeviceInfo> _devices;

  /// Devices (for session management)
  @override
  @JsonKey()
  List<DeviceInfo> get devices {
    if (_devices is EqualUnmodifiableListView) return _devices;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_devices);
  }

  /// Security events (recent only, full history in subcollection)
  final List<SecurityEvent> _recentSecurityEvents;

  /// Security events (recent only, full history in subcollection)
  @override
  @JsonKey()
  List<SecurityEvent> get recentSecurityEvents {
    if (_recentSecurityEvents is EqualUnmodifiableListView)
      return _recentSecurityEvents;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_recentSecurityEvents);
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, firstName: $firstName, lastName: $lastName, role: $role, accountType: $accountType, emailVerified: $emailVerified, phone: $phone, avatarUrl: $avatarUrl, displayName: $displayName, onboardingCompleted: $onboardingCompleted, lastLoginAt: $lastLoginAt, employeeOf: $employeeOf, permissions: $permissions, stripeAccountId: $stripeAccountId, stripeConnectedAt: $stripeConnectedAt, stripeDisconnectedAt: $stripeDisconnectedAt, createdAt: $createdAt, updatedAt: $updatedAt, devices: $devices, recentSecurityEvents: $recentSecurityEvents)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.firstName, firstName) ||
                other.firstName == firstName) &&
            (identical(other.lastName, lastName) ||
                other.lastName == lastName) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.accountType, accountType) ||
                other.accountType == accountType) &&
            (identical(other.emailVerified, emailVerified) ||
                other.emailVerified == emailVerified) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.onboardingCompleted, onboardingCompleted) ||
                other.onboardingCompleted == onboardingCompleted) &&
            (identical(other.lastLoginAt, lastLoginAt) ||
                other.lastLoginAt == lastLoginAt) &&
            (identical(other.employeeOf, employeeOf) ||
                other.employeeOf == employeeOf) &&
            (identical(other.permissions, permissions) ||
                other.permissions == permissions) &&
            (identical(other.stripeAccountId, stripeAccountId) ||
                other.stripeAccountId == stripeAccountId) &&
            (identical(other.stripeConnectedAt, stripeConnectedAt) ||
                other.stripeConnectedAt == stripeConnectedAt) &&
            (identical(other.stripeDisconnectedAt, stripeDisconnectedAt) ||
                other.stripeDisconnectedAt == stripeDisconnectedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            const DeepCollectionEquality().equals(other._devices, _devices) &&
            const DeepCollectionEquality().equals(
              other._recentSecurityEvents,
              _recentSecurityEvents,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    email,
    firstName,
    lastName,
    role,
    accountType,
    emailVerified,
    phone,
    avatarUrl,
    displayName,
    onboardingCompleted,
    lastLoginAt,
    employeeOf,
    permissions,
    stripeAccountId,
    stripeConnectedAt,
    stripeDisconnectedAt,
    createdAt,
    updatedAt,
    const DeepCollectionEquality().hash(_devices),
    const DeepCollectionEquality().hash(_recentSecurityEvents),
  ]);

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserModelImplCopyWith<_$UserModelImpl> get copyWith =>
      __$$UserModelImplCopyWithImpl<_$UserModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserModelImplToJson(this);
  }
}

abstract class _UserModel extends UserModel {
  const factory _UserModel({
    required final String id,
    required final String email,
    @JsonKey(name: 'first_name') required final String firstName,
    @JsonKey(name: 'last_name') required final String lastName,
    required final UserRole role,
    final AccountType accountType,
    final bool emailVerified,
    final String? phone,
    @JsonKey(name: 'avatar_url') final String? avatarUrl,
    final String? displayName,
    final bool onboardingCompleted,
    @NullableTimestampConverter() final DateTime? lastLoginAt,
    final String? employeeOf,
    final EmployeePermissions? permissions,
    @JsonKey(name: 'stripe_account_id') final String? stripeAccountId,
    @NullableTimestampConverter()
    @JsonKey(name: 'stripe_connected_at')
    final DateTime? stripeConnectedAt,
    @NullableTimestampConverter()
    @JsonKey(name: 'stripe_disconnected_at')
    final DateTime? stripeDisconnectedAt,
    @TimestampConverter()
    @JsonKey(name: 'created_at')
    required final DateTime createdAt,
    @NullableTimestampConverter()
    @JsonKey(name: 'updated_at')
    final DateTime? updatedAt,
    final List<DeviceInfo> devices,
    final List<SecurityEvent> recentSecurityEvents,
  }) = _$UserModelImpl;
  const _UserModel._() : super._();

  factory _UserModel.fromJson(Map<String, dynamic> json) =
      _$UserModelImpl.fromJson;

  /// User ID (UUID from Firebase Auth)
  @override
  String get id;

  /// User email address
  @override
  String get email;

  /// User's first name
  @override
  @JsonKey(name: 'first_name')
  String get firstName;

  /// User's last name
  @override
  @JsonKey(name: 'last_name')
  String get lastName;

  /// User role (guest, owner, admin)
  @override
  UserRole get role;

  /// Account type (trial, premium, enterprise)
  @override
  AccountType get accountType;

  /// Email verification status
  @override
  bool get emailVerified;

  /// Optional phone number
  @override
  String? get phone;

  /// Optional avatar URL
  @override
  @JsonKey(name: 'avatar_url')
  String? get avatarUrl;

  /// Display name (Firebase Auth)
  @override
  String? get displayName;

  /// Onboarding completion status
  @override
  bool get onboardingCompleted;

  /// Last login timestamp
  @override
  @NullableTimestampConverter()
  DateTime? get lastLoginAt;

  /// Employee-specific: Owner user ID (if this user is an employee)
  @override
  String? get employeeOf;

  /// Employee-specific: Permissions
  @override
  EmployeePermissions? get permissions;

  /// Stripe Connect account ID
  @override
  @JsonKey(name: 'stripe_account_id')
  String? get stripeAccountId;

  /// Stripe Connect onboarding completion timestamp
  @override
  @NullableTimestampConverter()
  @JsonKey(name: 'stripe_connected_at')
  DateTime? get stripeConnectedAt;

  /// Stripe disconnection timestamp
  @override
  @NullableTimestampConverter()
  @JsonKey(name: 'stripe_disconnected_at')
  DateTime? get stripeDisconnectedAt;

  /// Account creation timestamp
  @override
  @TimestampConverter()
  @JsonKey(name: 'created_at')
  DateTime get createdAt;

  /// Last update timestamp
  @override
  @NullableTimestampConverter()
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;

  /// Devices (for session management)
  @override
  List<DeviceInfo> get devices;

  /// Security events (recent only, full history in subcollection)
  @override
  List<SecurityEvent> get recentSecurityEvents;

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserModelImplCopyWith<_$UserModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
