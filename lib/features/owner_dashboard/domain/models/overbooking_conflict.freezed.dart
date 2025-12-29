// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'overbooking_conflict.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

OverbookingConflict _$OverbookingConflictFromJson(Map<String, dynamic> json) {
  return _OverbookingConflict.fromJson(json);
}

/// @nodoc
mixin _$OverbookingConflict {
  /// Unique conflict ID (generated from booking IDs)
  String get id => throw _privateConstructorUsedError;

  /// Unit ID where conflict occurs
  String get unitId => throw _privateConstructorUsedError;

  /// Unit name for display
  String get unitName => throw _privateConstructorUsedError;

  /// First booking in conflict
  BookingModel get booking1 => throw _privateConstructorUsedError;

  /// Second booking in conflict
  BookingModel get booking2 => throw _privateConstructorUsedError;

  /// List of dates where conflict occurs
  List<DateTime> get conflictDates => throw _privateConstructorUsedError;

  /// When conflict was detected
  DateTime get detectedAt => throw _privateConstructorUsedError;

  /// Whether conflict has been resolved
  bool get isResolved => throw _privateConstructorUsedError;

  /// Serializes this OverbookingConflict to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OverbookingConflict
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OverbookingConflictCopyWith<OverbookingConflict> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OverbookingConflictCopyWith<$Res> {
  factory $OverbookingConflictCopyWith(
    OverbookingConflict value,
    $Res Function(OverbookingConflict) then,
  ) = _$OverbookingConflictCopyWithImpl<$Res, OverbookingConflict>;
  @useResult
  $Res call({
    String id,
    String unitId,
    String unitName,
    BookingModel booking1,
    BookingModel booking2,
    List<DateTime> conflictDates,
    DateTime detectedAt,
    bool isResolved,
  });

  $BookingModelCopyWith<$Res> get booking1;
  $BookingModelCopyWith<$Res> get booking2;
}

/// @nodoc
class _$OverbookingConflictCopyWithImpl<$Res, $Val extends OverbookingConflict>
    implements $OverbookingConflictCopyWith<$Res> {
  _$OverbookingConflictCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OverbookingConflict
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? unitId = null,
    Object? unitName = null,
    Object? booking1 = null,
    Object? booking2 = null,
    Object? conflictDates = null,
    Object? detectedAt = null,
    Object? isResolved = null,
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
            unitName: null == unitName
                ? _value.unitName
                : unitName // ignore: cast_nullable_to_non_nullable
                      as String,
            booking1: null == booking1
                ? _value.booking1
                : booking1 // ignore: cast_nullable_to_non_nullable
                      as BookingModel,
            booking2: null == booking2
                ? _value.booking2
                : booking2 // ignore: cast_nullable_to_non_nullable
                      as BookingModel,
            conflictDates: null == conflictDates
                ? _value.conflictDates
                : conflictDates // ignore: cast_nullable_to_non_nullable
                      as List<DateTime>,
            detectedAt: null == detectedAt
                ? _value.detectedAt
                : detectedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            isResolved: null == isResolved
                ? _value.isResolved
                : isResolved // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }

  /// Create a copy of OverbookingConflict
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BookingModelCopyWith<$Res> get booking1 {
    return $BookingModelCopyWith<$Res>(_value.booking1, (value) {
      return _then(_value.copyWith(booking1: value) as $Val);
    });
  }

  /// Create a copy of OverbookingConflict
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BookingModelCopyWith<$Res> get booking2 {
    return $BookingModelCopyWith<$Res>(_value.booking2, (value) {
      return _then(_value.copyWith(booking2: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$OverbookingConflictImplCopyWith<$Res>
    implements $OverbookingConflictCopyWith<$Res> {
  factory _$$OverbookingConflictImplCopyWith(
    _$OverbookingConflictImpl value,
    $Res Function(_$OverbookingConflictImpl) then,
  ) = __$$OverbookingConflictImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String unitId,
    String unitName,
    BookingModel booking1,
    BookingModel booking2,
    List<DateTime> conflictDates,
    DateTime detectedAt,
    bool isResolved,
  });

  @override
  $BookingModelCopyWith<$Res> get booking1;
  @override
  $BookingModelCopyWith<$Res> get booking2;
}

/// @nodoc
class __$$OverbookingConflictImplCopyWithImpl<$Res>
    extends _$OverbookingConflictCopyWithImpl<$Res, _$OverbookingConflictImpl>
    implements _$$OverbookingConflictImplCopyWith<$Res> {
  __$$OverbookingConflictImplCopyWithImpl(
    _$OverbookingConflictImpl _value,
    $Res Function(_$OverbookingConflictImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OverbookingConflict
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? unitId = null,
    Object? unitName = null,
    Object? booking1 = null,
    Object? booking2 = null,
    Object? conflictDates = null,
    Object? detectedAt = null,
    Object? isResolved = null,
  }) {
    return _then(
      _$OverbookingConflictImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        unitId: null == unitId
            ? _value.unitId
            : unitId // ignore: cast_nullable_to_non_nullable
                  as String,
        unitName: null == unitName
            ? _value.unitName
            : unitName // ignore: cast_nullable_to_non_nullable
                  as String,
        booking1: null == booking1
            ? _value.booking1
            : booking1 // ignore: cast_nullable_to_non_nullable
                  as BookingModel,
        booking2: null == booking2
            ? _value.booking2
            : booking2 // ignore: cast_nullable_to_non_nullable
                  as BookingModel,
        conflictDates: null == conflictDates
            ? _value._conflictDates
            : conflictDates // ignore: cast_nullable_to_non_nullable
                  as List<DateTime>,
        detectedAt: null == detectedAt
            ? _value.detectedAt
            : detectedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        isResolved: null == isResolved
            ? _value.isResolved
            : isResolved // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$OverbookingConflictImpl implements _OverbookingConflict {
  const _$OverbookingConflictImpl({
    required this.id,
    required this.unitId,
    required this.unitName,
    required this.booking1,
    required this.booking2,
    required final List<DateTime> conflictDates,
    required this.detectedAt,
    this.isResolved = false,
  }) : _conflictDates = conflictDates;

  factory _$OverbookingConflictImpl.fromJson(Map<String, dynamic> json) =>
      _$$OverbookingConflictImplFromJson(json);

  /// Unique conflict ID (generated from booking IDs)
  @override
  final String id;

  /// Unit ID where conflict occurs
  @override
  final String unitId;

  /// Unit name for display
  @override
  final String unitName;

  /// First booking in conflict
  @override
  final BookingModel booking1;

  /// Second booking in conflict
  @override
  final BookingModel booking2;

  /// List of dates where conflict occurs
  final List<DateTime> _conflictDates;

  /// List of dates where conflict occurs
  @override
  List<DateTime> get conflictDates {
    if (_conflictDates is EqualUnmodifiableListView) return _conflictDates;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_conflictDates);
  }

  /// When conflict was detected
  @override
  final DateTime detectedAt;

  /// Whether conflict has been resolved
  @override
  @JsonKey()
  final bool isResolved;

  @override
  String toString() {
    return 'OverbookingConflict(id: $id, unitId: $unitId, unitName: $unitName, booking1: $booking1, booking2: $booking2, conflictDates: $conflictDates, detectedAt: $detectedAt, isResolved: $isResolved)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OverbookingConflictImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.unitId, unitId) || other.unitId == unitId) &&
            (identical(other.unitName, unitName) ||
                other.unitName == unitName) &&
            (identical(other.booking1, booking1) ||
                other.booking1 == booking1) &&
            (identical(other.booking2, booking2) ||
                other.booking2 == booking2) &&
            const DeepCollectionEquality().equals(
              other._conflictDates,
              _conflictDates,
            ) &&
            (identical(other.detectedAt, detectedAt) ||
                other.detectedAt == detectedAt) &&
            (identical(other.isResolved, isResolved) ||
                other.isResolved == isResolved));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    unitId,
    unitName,
    booking1,
    booking2,
    const DeepCollectionEquality().hash(_conflictDates),
    detectedAt,
    isResolved,
  );

  /// Create a copy of OverbookingConflict
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OverbookingConflictImplCopyWith<_$OverbookingConflictImpl> get copyWith =>
      __$$OverbookingConflictImplCopyWithImpl<_$OverbookingConflictImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$OverbookingConflictImplToJson(this);
  }
}

abstract class _OverbookingConflict implements OverbookingConflict {
  const factory _OverbookingConflict({
    required final String id,
    required final String unitId,
    required final String unitName,
    required final BookingModel booking1,
    required final BookingModel booking2,
    required final List<DateTime> conflictDates,
    required final DateTime detectedAt,
    final bool isResolved,
  }) = _$OverbookingConflictImpl;

  factory _OverbookingConflict.fromJson(Map<String, dynamic> json) =
      _$OverbookingConflictImpl.fromJson;

  /// Unique conflict ID (generated from booking IDs)
  @override
  String get id;

  /// Unit ID where conflict occurs
  @override
  String get unitId;

  /// Unit name for display
  @override
  String get unitName;

  /// First booking in conflict
  @override
  BookingModel get booking1;

  /// Second booking in conflict
  @override
  BookingModel get booking2;

  /// List of dates where conflict occurs
  @override
  List<DateTime> get conflictDates;

  /// When conflict was detected
  @override
  DateTime get detectedAt;

  /// Whether conflict has been resolved
  @override
  bool get isResolved;

  /// Create a copy of OverbookingConflict
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OverbookingConflictImplCopyWith<_$OverbookingConflictImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
