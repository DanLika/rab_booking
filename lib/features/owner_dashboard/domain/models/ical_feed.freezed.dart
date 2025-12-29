// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ical_feed.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

IcalFeed _$IcalFeedFromJson(Map<String, dynamic> json) {
  return _IcalFeed.fromJson(json);
}

/// @nodoc
mixin _$IcalFeed {
  String get id => throw _privateConstructorUsedError;
  String get unitId => throw _privateConstructorUsedError;
  String get propertyId => throw _privateConstructorUsedError;
  IcalPlatform get platform => throw _privateConstructorUsedError;
  String get icalUrl => throw _privateConstructorUsedError;
  int get syncIntervalMinutes => throw _privateConstructorUsedError;
  DateTime? get lastSynced => throw _privateConstructorUsedError;
  IcalStatus get status => throw _privateConstructorUsedError;
  String? get lastError => throw _privateConstructorUsedError;
  int get syncCount => throw _privateConstructorUsedError;
  int get eventCount => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this IcalFeed to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of IcalFeed
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $IcalFeedCopyWith<IcalFeed> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $IcalFeedCopyWith<$Res> {
  factory $IcalFeedCopyWith(IcalFeed value, $Res Function(IcalFeed) then) =
      _$IcalFeedCopyWithImpl<$Res, IcalFeed>;
  @useResult
  $Res call({
    String id,
    String unitId,
    String propertyId,
    IcalPlatform platform,
    String icalUrl,
    int syncIntervalMinutes,
    DateTime? lastSynced,
    IcalStatus status,
    String? lastError,
    int syncCount,
    int eventCount,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class _$IcalFeedCopyWithImpl<$Res, $Val extends IcalFeed>
    implements $IcalFeedCopyWith<$Res> {
  _$IcalFeedCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of IcalFeed
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? unitId = null,
    Object? propertyId = null,
    Object? platform = null,
    Object? icalUrl = null,
    Object? syncIntervalMinutes = null,
    Object? lastSynced = freezed,
    Object? status = null,
    Object? lastError = freezed,
    Object? syncCount = null,
    Object? eventCount = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            unitId: null == unitId
                ? _value.unitId
                : unitId // ignore: cast_nullable_to_non_nullable
                      as String,
            propertyId: null == propertyId
                ? _value.propertyId
                : propertyId // ignore: cast_nullable_to_non_nullable
                      as String,
            platform: null == platform
                ? _value.platform
                : platform // ignore: cast_nullable_to_non_nullable
                      as IcalPlatform,
            icalUrl: null == icalUrl
                ? _value.icalUrl
                : icalUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            syncIntervalMinutes: null == syncIntervalMinutes
                ? _value.syncIntervalMinutes
                : syncIntervalMinutes // ignore: cast_nullable_to_non_nullable
                      as int,
            lastSynced: freezed == lastSynced
                ? _value.lastSynced
                : lastSynced // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as IcalStatus,
            lastError: freezed == lastError
                ? _value.lastError
                : lastError // ignore: cast_nullable_to_non_nullable
                      as String?,
            syncCount: null == syncCount
                ? _value.syncCount
                : syncCount // ignore: cast_nullable_to_non_nullable
                      as int,
            eventCount: null == eventCount
                ? _value.eventCount
                : eventCount // ignore: cast_nullable_to_non_nullable
                      as int,
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
abstract class _$$IcalFeedImplCopyWith<$Res>
    implements $IcalFeedCopyWith<$Res> {
  factory _$$IcalFeedImplCopyWith(
    _$IcalFeedImpl value,
    $Res Function(_$IcalFeedImpl) then,
  ) = __$$IcalFeedImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String unitId,
    String propertyId,
    IcalPlatform platform,
    String icalUrl,
    int syncIntervalMinutes,
    DateTime? lastSynced,
    IcalStatus status,
    String? lastError,
    int syncCount,
    int eventCount,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class __$$IcalFeedImplCopyWithImpl<$Res>
    extends _$IcalFeedCopyWithImpl<$Res, _$IcalFeedImpl>
    implements _$$IcalFeedImplCopyWith<$Res> {
  __$$IcalFeedImplCopyWithImpl(
    _$IcalFeedImpl _value,
    $Res Function(_$IcalFeedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of IcalFeed
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? unitId = null,
    Object? propertyId = null,
    Object? platform = null,
    Object? icalUrl = null,
    Object? syncIntervalMinutes = null,
    Object? lastSynced = freezed,
    Object? status = null,
    Object? lastError = freezed,
    Object? syncCount = null,
    Object? eventCount = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$IcalFeedImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        unitId: null == unitId
            ? _value.unitId
            : unitId // ignore: cast_nullable_to_non_nullable
                  as String,
        propertyId: null == propertyId
            ? _value.propertyId
            : propertyId // ignore: cast_nullable_to_non_nullable
                  as String,
        platform: null == platform
            ? _value.platform
            : platform // ignore: cast_nullable_to_non_nullable
                  as IcalPlatform,
        icalUrl: null == icalUrl
            ? _value.icalUrl
            : icalUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        syncIntervalMinutes: null == syncIntervalMinutes
            ? _value.syncIntervalMinutes
            : syncIntervalMinutes // ignore: cast_nullable_to_non_nullable
                  as int,
        lastSynced: freezed == lastSynced
            ? _value.lastSynced
            : lastSynced // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as IcalStatus,
        lastError: freezed == lastError
            ? _value.lastError
            : lastError // ignore: cast_nullable_to_non_nullable
                  as String?,
        syncCount: null == syncCount
            ? _value.syncCount
            : syncCount // ignore: cast_nullable_to_non_nullable
                  as int,
        eventCount: null == eventCount
            ? _value.eventCount
            : eventCount // ignore: cast_nullable_to_non_nullable
                  as int,
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
class _$IcalFeedImpl extends _IcalFeed {
  const _$IcalFeedImpl({
    required this.id,
    required this.unitId,
    required this.propertyId,
    required this.platform,
    required this.icalUrl,
    this.syncIntervalMinutes = 60,
    this.lastSynced,
    this.status = IcalStatus.active,
    this.lastError,
    this.syncCount = 0,
    this.eventCount = 0,
    required this.createdAt,
    required this.updatedAt,
  }) : super._();

  factory _$IcalFeedImpl.fromJson(Map<String, dynamic> json) =>
      _$$IcalFeedImplFromJson(json);

  @override
  final String id;
  @override
  final String unitId;
  @override
  final String propertyId;
  @override
  final IcalPlatform platform;
  @override
  final String icalUrl;
  @override
  @JsonKey()
  final int syncIntervalMinutes;
  @override
  final DateTime? lastSynced;
  @override
  @JsonKey()
  final IcalStatus status;
  @override
  final String? lastError;
  @override
  @JsonKey()
  final int syncCount;
  @override
  @JsonKey()
  final int eventCount;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'IcalFeed(id: $id, unitId: $unitId, propertyId: $propertyId, platform: $platform, icalUrl: $icalUrl, syncIntervalMinutes: $syncIntervalMinutes, lastSynced: $lastSynced, status: $status, lastError: $lastError, syncCount: $syncCount, eventCount: $eventCount, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$IcalFeedImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.unitId, unitId) || other.unitId == unitId) &&
            (identical(other.propertyId, propertyId) ||
                other.propertyId == propertyId) &&
            (identical(other.platform, platform) ||
                other.platform == platform) &&
            (identical(other.icalUrl, icalUrl) || other.icalUrl == icalUrl) &&
            (identical(other.syncIntervalMinutes, syncIntervalMinutes) ||
                other.syncIntervalMinutes == syncIntervalMinutes) &&
            (identical(other.lastSynced, lastSynced) ||
                other.lastSynced == lastSynced) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.lastError, lastError) ||
                other.lastError == lastError) &&
            (identical(other.syncCount, syncCount) ||
                other.syncCount == syncCount) &&
            (identical(other.eventCount, eventCount) ||
                other.eventCount == eventCount) &&
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
    unitId,
    propertyId,
    platform,
    icalUrl,
    syncIntervalMinutes,
    lastSynced,
    status,
    lastError,
    syncCount,
    eventCount,
    createdAt,
    updatedAt,
  );

  /// Create a copy of IcalFeed
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$IcalFeedImplCopyWith<_$IcalFeedImpl> get copyWith =>
      __$$IcalFeedImplCopyWithImpl<_$IcalFeedImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$IcalFeedImplToJson(this);
  }
}

abstract class _IcalFeed extends IcalFeed {
  const factory _IcalFeed({
    required final String id,
    required final String unitId,
    required final String propertyId,
    required final IcalPlatform platform,
    required final String icalUrl,
    final int syncIntervalMinutes,
    final DateTime? lastSynced,
    final IcalStatus status,
    final String? lastError,
    final int syncCount,
    final int eventCount,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _$IcalFeedImpl;
  const _IcalFeed._() : super._();

  factory _IcalFeed.fromJson(Map<String, dynamic> json) =
      _$IcalFeedImpl.fromJson;

  @override
  String get id;
  @override
  String get unitId;
  @override
  String get propertyId;
  @override
  IcalPlatform get platform;
  @override
  String get icalUrl;
  @override
  int get syncIntervalMinutes;
  @override
  DateTime? get lastSynced;
  @override
  IcalStatus get status;
  @override
  String? get lastError;
  @override
  int get syncCount;
  @override
  int get eventCount;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of IcalFeed
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$IcalFeedImplCopyWith<_$IcalFeedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

IcalEvent _$IcalEventFromJson(Map<String, dynamic> json) {
  return _IcalEvent.fromJson(json);
}

/// @nodoc
mixin _$IcalEvent {
  String get id => throw _privateConstructorUsedError;
  String get unitId => throw _privateConstructorUsedError;
  String get feedId => throw _privateConstructorUsedError;
  DateTime get startDate => throw _privateConstructorUsedError;
  DateTime get endDate => throw _privateConstructorUsedError;
  String get guestName => throw _privateConstructorUsedError;
  String get source => throw _privateConstructorUsedError;
  String get externalId => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this IcalEvent to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of IcalEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $IcalEventCopyWith<IcalEvent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $IcalEventCopyWith<$Res> {
  factory $IcalEventCopyWith(IcalEvent value, $Res Function(IcalEvent) then) =
      _$IcalEventCopyWithImpl<$Res, IcalEvent>;
  @useResult
  $Res call({
    String id,
    String unitId,
    String feedId,
    DateTime startDate,
    DateTime endDate,
    String guestName,
    String source,
    String externalId,
    String? description,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class _$IcalEventCopyWithImpl<$Res, $Val extends IcalEvent>
    implements $IcalEventCopyWith<$Res> {
  _$IcalEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of IcalEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? unitId = null,
    Object? feedId = null,
    Object? startDate = null,
    Object? endDate = null,
    Object? guestName = null,
    Object? source = null,
    Object? externalId = null,
    Object? description = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            unitId: null == unitId
                ? _value.unitId
                : unitId // ignore: cast_nullable_to_non_nullable
                      as String,
            feedId: null == feedId
                ? _value.feedId
                : feedId // ignore: cast_nullable_to_non_nullable
                      as String,
            startDate: null == startDate
                ? _value.startDate
                : startDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            endDate: null == endDate
                ? _value.endDate
                : endDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            guestName: null == guestName
                ? _value.guestName
                : guestName // ignore: cast_nullable_to_non_nullable
                      as String,
            source: null == source
                ? _value.source
                : source // ignore: cast_nullable_to_non_nullable
                      as String,
            externalId: null == externalId
                ? _value.externalId
                : externalId // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
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
abstract class _$$IcalEventImplCopyWith<$Res>
    implements $IcalEventCopyWith<$Res> {
  factory _$$IcalEventImplCopyWith(
    _$IcalEventImpl value,
    $Res Function(_$IcalEventImpl) then,
  ) = __$$IcalEventImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String unitId,
    String feedId,
    DateTime startDate,
    DateTime endDate,
    String guestName,
    String source,
    String externalId,
    String? description,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class __$$IcalEventImplCopyWithImpl<$Res>
    extends _$IcalEventCopyWithImpl<$Res, _$IcalEventImpl>
    implements _$$IcalEventImplCopyWith<$Res> {
  __$$IcalEventImplCopyWithImpl(
    _$IcalEventImpl _value,
    $Res Function(_$IcalEventImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of IcalEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? unitId = null,
    Object? feedId = null,
    Object? startDate = null,
    Object? endDate = null,
    Object? guestName = null,
    Object? source = null,
    Object? externalId = null,
    Object? description = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$IcalEventImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        unitId: null == unitId
            ? _value.unitId
            : unitId // ignore: cast_nullable_to_non_nullable
                  as String,
        feedId: null == feedId
            ? _value.feedId
            : feedId // ignore: cast_nullable_to_non_nullable
                  as String,
        startDate: null == startDate
            ? _value.startDate
            : startDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        endDate: null == endDate
            ? _value.endDate
            : endDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        guestName: null == guestName
            ? _value.guestName
            : guestName // ignore: cast_nullable_to_non_nullable
                  as String,
        source: null == source
            ? _value.source
            : source // ignore: cast_nullable_to_non_nullable
                  as String,
        externalId: null == externalId
            ? _value.externalId
            : externalId // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
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
class _$IcalEventImpl extends _IcalEvent {
  const _$IcalEventImpl({
    required this.id,
    required this.unitId,
    required this.feedId,
    required this.startDate,
    required this.endDate,
    required this.guestName,
    required this.source,
    required this.externalId,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  }) : super._();

  factory _$IcalEventImpl.fromJson(Map<String, dynamic> json) =>
      _$$IcalEventImplFromJson(json);

  @override
  final String id;
  @override
  final String unitId;
  @override
  final String feedId;
  @override
  final DateTime startDate;
  @override
  final DateTime endDate;
  @override
  final String guestName;
  @override
  final String source;
  @override
  final String externalId;
  @override
  final String? description;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'IcalEvent(id: $id, unitId: $unitId, feedId: $feedId, startDate: $startDate, endDate: $endDate, guestName: $guestName, source: $source, externalId: $externalId, description: $description, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$IcalEventImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.unitId, unitId) || other.unitId == unitId) &&
            (identical(other.feedId, feedId) || other.feedId == feedId) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.guestName, guestName) ||
                other.guestName == guestName) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.externalId, externalId) ||
                other.externalId == externalId) &&
            (identical(other.description, description) ||
                other.description == description) &&
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
    unitId,
    feedId,
    startDate,
    endDate,
    guestName,
    source,
    externalId,
    description,
    createdAt,
    updatedAt,
  );

  /// Create a copy of IcalEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$IcalEventImplCopyWith<_$IcalEventImpl> get copyWith =>
      __$$IcalEventImplCopyWithImpl<_$IcalEventImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$IcalEventImplToJson(this);
  }
}

abstract class _IcalEvent extends IcalEvent {
  const factory _IcalEvent({
    required final String id,
    required final String unitId,
    required final String feedId,
    required final DateTime startDate,
    required final DateTime endDate,
    required final String guestName,
    required final String source,
    required final String externalId,
    final String? description,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _$IcalEventImpl;
  const _IcalEvent._() : super._();

  factory _IcalEvent.fromJson(Map<String, dynamic> json) =
      _$IcalEventImpl.fromJson;

  @override
  String get id;
  @override
  String get unitId;
  @override
  String get feedId;
  @override
  DateTime get startDate;
  @override
  DateTime get endDate;
  @override
  String get guestName;
  @override
  String get source;
  @override
  String get externalId;
  @override
  String? get description;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of IcalEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$IcalEventImplCopyWith<_$IcalEventImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
