// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'platform_connection.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PlatformConnection _$PlatformConnectionFromJson(Map<String, dynamic> json) {
  return _PlatformConnection.fromJson(json);
}

/// @nodoc
mixin _$PlatformConnection {
  String get id => throw _privateConstructorUsedError;
  String get ownerId => throw _privateConstructorUsedError;
  PlatformType get platform => throw _privateConstructorUsedError;
  String get unitId => throw _privateConstructorUsedError;
  String get externalPropertyId => throw _privateConstructorUsedError;
  String get externalUnitId => throw _privateConstructorUsedError;
  DateTime get expiresAt => throw _privateConstructorUsedError;
  ConnectionStatus get status => throw _privateConstructorUsedError;
  String? get lastError => throw _privateConstructorUsedError;
  DateTime? get lastSyncedAt => throw _privateConstructorUsedError;
  int? get lastSyncEventCount => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this PlatformConnection to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PlatformConnection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlatformConnectionCopyWith<PlatformConnection> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlatformConnectionCopyWith<$Res> {
  factory $PlatformConnectionCopyWith(
    PlatformConnection value,
    $Res Function(PlatformConnection) then,
  ) = _$PlatformConnectionCopyWithImpl<$Res, PlatformConnection>;
  @useResult
  $Res call({
    String id,
    String ownerId,
    PlatformType platform,
    String unitId,
    String externalPropertyId,
    String externalUnitId,
    DateTime expiresAt,
    ConnectionStatus status,
    String? lastError,
    DateTime? lastSyncedAt,
    int? lastSyncEventCount,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class _$PlatformConnectionCopyWithImpl<$Res, $Val extends PlatformConnection>
    implements $PlatformConnectionCopyWith<$Res> {
  _$PlatformConnectionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlatformConnection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ownerId = null,
    Object? platform = null,
    Object? unitId = null,
    Object? externalPropertyId = null,
    Object? externalUnitId = null,
    Object? expiresAt = null,
    Object? status = null,
    Object? lastError = freezed,
    Object? lastSyncedAt = freezed,
    Object? lastSyncEventCount = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            ownerId: null == ownerId
                ? _value.ownerId
                : ownerId // ignore: cast_nullable_to_non_nullable
                      as String,
            platform: null == platform
                ? _value.platform
                : platform // ignore: cast_nullable_to_non_nullable
                      as PlatformType,
            unitId: null == unitId
                ? _value.unitId
                : unitId // ignore: cast_nullable_to_non_nullable
                      as String,
            externalPropertyId: null == externalPropertyId
                ? _value.externalPropertyId
                : externalPropertyId // ignore: cast_nullable_to_non_nullable
                      as String,
            externalUnitId: null == externalUnitId
                ? _value.externalUnitId
                : externalUnitId // ignore: cast_nullable_to_non_nullable
                      as String,
            expiresAt: null == expiresAt
                ? _value.expiresAt
                : expiresAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as ConnectionStatus,
            lastError: freezed == lastError
                ? _value.lastError
                : lastError // ignore: cast_nullable_to_non_nullable
                      as String?,
            lastSyncedAt: freezed == lastSyncedAt
                ? _value.lastSyncedAt
                : lastSyncedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            lastSyncEventCount: freezed == lastSyncEventCount
                ? _value.lastSyncEventCount
                : lastSyncEventCount // ignore: cast_nullable_to_non_nullable
                      as int?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PlatformConnectionImplCopyWith<$Res>
    implements $PlatformConnectionCopyWith<$Res> {
  factory _$$PlatformConnectionImplCopyWith(
    _$PlatformConnectionImpl value,
    $Res Function(_$PlatformConnectionImpl) then,
  ) = __$$PlatformConnectionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String ownerId,
    PlatformType platform,
    String unitId,
    String externalPropertyId,
    String externalUnitId,
    DateTime expiresAt,
    ConnectionStatus status,
    String? lastError,
    DateTime? lastSyncedAt,
    int? lastSyncEventCount,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class __$$PlatformConnectionImplCopyWithImpl<$Res>
    extends _$PlatformConnectionCopyWithImpl<$Res, _$PlatformConnectionImpl>
    implements _$$PlatformConnectionImplCopyWith<$Res> {
  __$$PlatformConnectionImplCopyWithImpl(
    _$PlatformConnectionImpl _value,
    $Res Function(_$PlatformConnectionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PlatformConnection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ownerId = null,
    Object? platform = null,
    Object? unitId = null,
    Object? externalPropertyId = null,
    Object? externalUnitId = null,
    Object? expiresAt = null,
    Object? status = null,
    Object? lastError = freezed,
    Object? lastSyncedAt = freezed,
    Object? lastSyncEventCount = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$PlatformConnectionImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        ownerId: null == ownerId
            ? _value.ownerId
            : ownerId // ignore: cast_nullable_to_non_nullable
                  as String,
        platform: null == platform
            ? _value.platform
            : platform // ignore: cast_nullable_to_non_nullable
                  as PlatformType,
        unitId: null == unitId
            ? _value.unitId
            : unitId // ignore: cast_nullable_to_non_nullable
                  as String,
        externalPropertyId: null == externalPropertyId
            ? _value.externalPropertyId
            : externalPropertyId // ignore: cast_nullable_to_non_nullable
                  as String,
        externalUnitId: null == externalUnitId
            ? _value.externalUnitId
            : externalUnitId // ignore: cast_nullable_to_non_nullable
                  as String,
        expiresAt: null == expiresAt
            ? _value.expiresAt
            : expiresAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as ConnectionStatus,
        lastError: freezed == lastError
            ? _value.lastError
            : lastError // ignore: cast_nullable_to_non_nullable
                  as String?,
        lastSyncedAt: freezed == lastSyncedAt
            ? _value.lastSyncedAt
            : lastSyncedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        lastSyncEventCount: freezed == lastSyncEventCount
            ? _value.lastSyncEventCount
            : lastSyncEventCount // ignore: cast_nullable_to_non_nullable
                  as int?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PlatformConnectionImpl extends _PlatformConnection {
  const _$PlatformConnectionImpl({
    required this.id,
    required this.ownerId,
    required this.platform,
    required this.unitId,
    required this.externalPropertyId,
    required this.externalUnitId,
    required this.expiresAt,
    this.status = ConnectionStatus.pending,
    this.lastError,
    this.lastSyncedAt,
    this.lastSyncEventCount,
    required this.createdAt,
    required this.updatedAt,
  }) : super._();

  factory _$PlatformConnectionImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlatformConnectionImplFromJson(json);

  @override
  final String id;
  @override
  final String ownerId;
  @override
  final PlatformType platform;
  @override
  final String unitId;
  @override
  final String externalPropertyId;
  @override
  final String externalUnitId;
  @override
  final DateTime expiresAt;
  @override
  @JsonKey()
  final ConnectionStatus status;
  @override
  final String? lastError;
  @override
  final DateTime? lastSyncedAt;
  @override
  final int? lastSyncEventCount;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'PlatformConnection(id: $id, ownerId: $ownerId, platform: $platform, unitId: $unitId, externalPropertyId: $externalPropertyId, externalUnitId: $externalUnitId, expiresAt: $expiresAt, status: $status, lastError: $lastError, lastSyncedAt: $lastSyncedAt, lastSyncEventCount: $lastSyncEventCount, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlatformConnectionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.platform, platform) ||
                other.platform == platform) &&
            (identical(other.unitId, unitId) || other.unitId == unitId) &&
            (identical(other.externalPropertyId, externalPropertyId) ||
                other.externalPropertyId == externalPropertyId) &&
            (identical(other.externalUnitId, externalUnitId) ||
                other.externalUnitId == externalUnitId) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.lastError, lastError) ||
                other.lastError == lastError) &&
            (identical(other.lastSyncedAt, lastSyncedAt) ||
                other.lastSyncedAt == lastSyncedAt) &&
            (identical(other.lastSyncEventCount, lastSyncEventCount) ||
                other.lastSyncEventCount == lastSyncEventCount) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    ownerId,
    platform,
    unitId,
    externalPropertyId,
    externalUnitId,
    expiresAt,
    status,
    lastError,
    lastSyncedAt,
    lastSyncEventCount,
    createdAt,
    updatedAt,
  );

  /// Create a copy of PlatformConnection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlatformConnectionImplCopyWith<_$PlatformConnectionImpl> get copyWith =>
      __$$PlatformConnectionImplCopyWithImpl<_$PlatformConnectionImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PlatformConnectionImplToJson(this);
  }
}

abstract class _PlatformConnection extends PlatformConnection {
  const factory _PlatformConnection({
    required final String id,
    required final String ownerId,
    required final PlatformType platform,
    required final String unitId,
    required final String externalPropertyId,
    required final String externalUnitId,
    required final DateTime expiresAt,
    final ConnectionStatus status,
    final String? lastError,
    final DateTime? lastSyncedAt,
    final int? lastSyncEventCount,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _$PlatformConnectionImpl;
  const _PlatformConnection._() : super._();

  factory _PlatformConnection.fromJson(Map<String, dynamic> json) =
      _$PlatformConnectionImpl.fromJson;

  @override
  String get id;
  @override
  String get ownerId;
  @override
  PlatformType get platform;
  @override
  String get unitId;
  @override
  String get externalPropertyId;
  @override
  String get externalUnitId;
  @override
  DateTime get expiresAt;
  @override
  ConnectionStatus get status;
  @override
  String? get lastError;
  @override
  DateTime? get lastSyncedAt;
  @override
  int? get lastSyncEventCount;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of PlatformConnection
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlatformConnectionImplCopyWith<_$PlatformConnectionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
