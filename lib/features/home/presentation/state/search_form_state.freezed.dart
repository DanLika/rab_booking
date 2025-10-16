// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_form_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$SearchFormState {
  String get location => throw _privateConstructorUsedError;
  DateTime? get checkInDate => throw _privateConstructorUsedError;
  DateTime? get checkOutDate => throw _privateConstructorUsedError;
  int get adults => throw _privateConstructorUsedError;
  int get children => throw _privateConstructorUsedError;
  int get infants => throw _privateConstructorUsedError;

  /// Create a copy of SearchFormState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SearchFormStateCopyWith<SearchFormState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SearchFormStateCopyWith<$Res> {
  factory $SearchFormStateCopyWith(
    SearchFormState value,
    $Res Function(SearchFormState) then,
  ) = _$SearchFormStateCopyWithImpl<$Res, SearchFormState>;
  @useResult
  $Res call({
    String location,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    int adults,
    int children,
    int infants,
  });
}

/// @nodoc
class _$SearchFormStateCopyWithImpl<$Res, $Val extends SearchFormState>
    implements $SearchFormStateCopyWith<$Res> {
  _$SearchFormStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SearchFormState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? location = null,
    Object? checkInDate = freezed,
    Object? checkOutDate = freezed,
    Object? adults = null,
    Object? children = null,
    Object? infants = null,
  }) {
    return _then(
      _value.copyWith(
            location:
                null == location
                    ? _value.location
                    : location // ignore: cast_nullable_to_non_nullable
                        as String,
            checkInDate:
                freezed == checkInDate
                    ? _value.checkInDate
                    : checkInDate // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
            checkOutDate:
                freezed == checkOutDate
                    ? _value.checkOutDate
                    : checkOutDate // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
            adults:
                null == adults
                    ? _value.adults
                    : adults // ignore: cast_nullable_to_non_nullable
                        as int,
            children:
                null == children
                    ? _value.children
                    : children // ignore: cast_nullable_to_non_nullable
                        as int,
            infants:
                null == infants
                    ? _value.infants
                    : infants // ignore: cast_nullable_to_non_nullable
                        as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SearchFormStateImplCopyWith<$Res>
    implements $SearchFormStateCopyWith<$Res> {
  factory _$$SearchFormStateImplCopyWith(
    _$SearchFormStateImpl value,
    $Res Function(_$SearchFormStateImpl) then,
  ) = __$$SearchFormStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String location,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    int adults,
    int children,
    int infants,
  });
}

/// @nodoc
class __$$SearchFormStateImplCopyWithImpl<$Res>
    extends _$SearchFormStateCopyWithImpl<$Res, _$SearchFormStateImpl>
    implements _$$SearchFormStateImplCopyWith<$Res> {
  __$$SearchFormStateImplCopyWithImpl(
    _$SearchFormStateImpl _value,
    $Res Function(_$SearchFormStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SearchFormState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? location = null,
    Object? checkInDate = freezed,
    Object? checkOutDate = freezed,
    Object? adults = null,
    Object? children = null,
    Object? infants = null,
  }) {
    return _then(
      _$SearchFormStateImpl(
        location:
            null == location
                ? _value.location
                : location // ignore: cast_nullable_to_non_nullable
                    as String,
        checkInDate:
            freezed == checkInDate
                ? _value.checkInDate
                : checkInDate // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
        checkOutDate:
            freezed == checkOutDate
                ? _value.checkOutDate
                : checkOutDate // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
        adults:
            null == adults
                ? _value.adults
                : adults // ignore: cast_nullable_to_non_nullable
                    as int,
        children:
            null == children
                ? _value.children
                : children // ignore: cast_nullable_to_non_nullable
                    as int,
        infants:
            null == infants
                ? _value.infants
                : infants // ignore: cast_nullable_to_non_nullable
                    as int,
      ),
    );
  }
}

/// @nodoc

class _$SearchFormStateImpl extends _SearchFormState
    with DiagnosticableTreeMixin {
  const _$SearchFormStateImpl({
    this.location = 'Otok Rab',
    this.checkInDate,
    this.checkOutDate,
    this.adults = 2,
    this.children = 0,
    this.infants = 0,
  }) : super._();

  @override
  @JsonKey()
  final String location;
  @override
  final DateTime? checkInDate;
  @override
  final DateTime? checkOutDate;
  @override
  @JsonKey()
  final int adults;
  @override
  @JsonKey()
  final int children;
  @override
  @JsonKey()
  final int infants;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'SearchFormState(location: $location, checkInDate: $checkInDate, checkOutDate: $checkOutDate, adults: $adults, children: $children, infants: $infants)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'SearchFormState'))
      ..add(DiagnosticsProperty('location', location))
      ..add(DiagnosticsProperty('checkInDate', checkInDate))
      ..add(DiagnosticsProperty('checkOutDate', checkOutDate))
      ..add(DiagnosticsProperty('adults', adults))
      ..add(DiagnosticsProperty('children', children))
      ..add(DiagnosticsProperty('infants', infants));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SearchFormStateImpl &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.checkInDate, checkInDate) ||
                other.checkInDate == checkInDate) &&
            (identical(other.checkOutDate, checkOutDate) ||
                other.checkOutDate == checkOutDate) &&
            (identical(other.adults, adults) || other.adults == adults) &&
            (identical(other.children, children) ||
                other.children == children) &&
            (identical(other.infants, infants) || other.infants == infants));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    location,
    checkInDate,
    checkOutDate,
    adults,
    children,
    infants,
  );

  /// Create a copy of SearchFormState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SearchFormStateImplCopyWith<_$SearchFormStateImpl> get copyWith =>
      __$$SearchFormStateImplCopyWithImpl<_$SearchFormStateImpl>(
        this,
        _$identity,
      );
}

abstract class _SearchFormState extends SearchFormState {
  const factory _SearchFormState({
    final String location,
    final DateTime? checkInDate,
    final DateTime? checkOutDate,
    final int adults,
    final int children,
    final int infants,
  }) = _$SearchFormStateImpl;
  const _SearchFormState._() : super._();

  @override
  String get location;
  @override
  DateTime? get checkInDate;
  @override
  DateTime? get checkOutDate;
  @override
  int get adults;
  @override
  int get children;
  @override
  int get infants;

  /// Create a copy of SearchFormState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SearchFormStateImplCopyWith<_$SearchFormStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
