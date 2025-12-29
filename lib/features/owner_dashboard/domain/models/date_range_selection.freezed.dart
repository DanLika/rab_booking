// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'date_range_selection.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

DateRangeSelection _$DateRangeSelectionFromJson(Map<String, dynamic> json) {
  return _DateRangeSelection.fromJson(json);
}

/// @nodoc
mixin _$DateRangeSelection {
  DateTime get startDate => throw _privateConstructorUsedError;
  DateTime get endDate => throw _privateConstructorUsedError;

  /// Serializes this DateRangeSelection to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DateRangeSelection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DateRangeSelectionCopyWith<DateRangeSelection> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DateRangeSelectionCopyWith<$Res> {
  factory $DateRangeSelectionCopyWith(
    DateRangeSelection value,
    $Res Function(DateRangeSelection) then,
  ) = _$DateRangeSelectionCopyWithImpl<$Res, DateRangeSelection>;
  @useResult
  $Res call({DateTime startDate, DateTime endDate});
}

/// @nodoc
class _$DateRangeSelectionCopyWithImpl<$Res, $Val extends DateRangeSelection>
    implements $DateRangeSelectionCopyWith<$Res> {
  _$DateRangeSelectionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DateRangeSelection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? startDate = null, Object? endDate = null}) {
    return _then(
      _value.copyWith(
            startDate: null == startDate
                ? _value.startDate
                : startDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            endDate: null == endDate
                ? _value.endDate
                : endDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DateRangeSelectionImplCopyWith<$Res>
    implements $DateRangeSelectionCopyWith<$Res> {
  factory _$$DateRangeSelectionImplCopyWith(
    _$DateRangeSelectionImpl value,
    $Res Function(_$DateRangeSelectionImpl) then,
  ) = __$$DateRangeSelectionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({DateTime startDate, DateTime endDate});
}

/// @nodoc
class __$$DateRangeSelectionImplCopyWithImpl<$Res>
    extends _$DateRangeSelectionCopyWithImpl<$Res, _$DateRangeSelectionImpl>
    implements _$$DateRangeSelectionImplCopyWith<$Res> {
  __$$DateRangeSelectionImplCopyWithImpl(
    _$DateRangeSelectionImpl _value,
    $Res Function(_$DateRangeSelectionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DateRangeSelection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? startDate = null, Object? endDate = null}) {
    return _then(
      _$DateRangeSelectionImpl(
        startDate: null == startDate
            ? _value.startDate
            : startDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        endDate: null == endDate
            ? _value.endDate
            : endDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DateRangeSelectionImpl extends _DateRangeSelection {
  const _$DateRangeSelectionImpl({
    required this.startDate,
    required this.endDate,
  }) : super._();

  factory _$DateRangeSelectionImpl.fromJson(Map<String, dynamic> json) =>
      _$$DateRangeSelectionImplFromJson(json);

  @override
  final DateTime startDate;
  @override
  final DateTime endDate;

  @override
  String toString() {
    return 'DateRangeSelection(startDate: $startDate, endDate: $endDate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DateRangeSelectionImpl &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, startDate, endDate);

  /// Create a copy of DateRangeSelection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DateRangeSelectionImplCopyWith<_$DateRangeSelectionImpl> get copyWith =>
      __$$DateRangeSelectionImplCopyWithImpl<_$DateRangeSelectionImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$DateRangeSelectionImplToJson(this);
  }
}

abstract class _DateRangeSelection extends DateRangeSelection {
  const factory _DateRangeSelection({
    required final DateTime startDate,
    required final DateTime endDate,
  }) = _$DateRangeSelectionImpl;
  const _DateRangeSelection._() : super._();

  factory _DateRangeSelection.fromJson(Map<String, dynamic> json) =
      _$DateRangeSelectionImpl.fromJson;

  @override
  DateTime get startDate;
  @override
  DateTime get endDate;

  /// Create a copy of DateRangeSelection
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DateRangeSelectionImplCopyWith<_$DateRangeSelectionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
