// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'widget_context.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$WidgetContext {
  /// Parent property containing this unit
  PropertyModel get property => throw _privateConstructorUsedError;

  /// The unit being booked
  UnitModel get unit => throw _privateConstructorUsedError;

  /// Widget settings for this unit (payment, approval, etc.)
  WidgetSettings get settings => throw _privateConstructorUsedError;

  /// Owner's user ID (extracted for convenience)
  String get ownerId => throw _privateConstructorUsedError;

  /// Create a copy of WidgetContext
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WidgetContextCopyWith<WidgetContext> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WidgetContextCopyWith<$Res> {
  factory $WidgetContextCopyWith(
    WidgetContext value,
    $Res Function(WidgetContext) then,
  ) = _$WidgetContextCopyWithImpl<$Res, WidgetContext>;
  @useResult
  $Res call({
    PropertyModel property,
    UnitModel unit,
    WidgetSettings settings,
    String ownerId,
  });

  $PropertyModelCopyWith<$Res> get property;
  $UnitModelCopyWith<$Res> get unit;
}

/// @nodoc
class _$WidgetContextCopyWithImpl<$Res, $Val extends WidgetContext>
    implements $WidgetContextCopyWith<$Res> {
  _$WidgetContextCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WidgetContext
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? property = null,
    Object? unit = null,
    Object? settings = null,
    Object? ownerId = null,
  }) {
    return _then(
      _value.copyWith(
            property: null == property
                ? _value.property
                : property // ignore: cast_nullable_to_non_nullable
                      as PropertyModel,
            unit: null == unit
                ? _value.unit
                : unit // ignore: cast_nullable_to_non_nullable
                      as UnitModel,
            settings: null == settings
                ? _value.settings
                : settings // ignore: cast_nullable_to_non_nullable
                      as WidgetSettings,
            ownerId: null == ownerId
                ? _value.ownerId
                : ownerId // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }

  /// Create a copy of WidgetContext
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PropertyModelCopyWith<$Res> get property {
    return $PropertyModelCopyWith<$Res>(_value.property, (value) {
      return _then(_value.copyWith(property: value) as $Val);
    });
  }

  /// Create a copy of WidgetContext
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UnitModelCopyWith<$Res> get unit {
    return $UnitModelCopyWith<$Res>(_value.unit, (value) {
      return _then(_value.copyWith(unit: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$WidgetContextImplCopyWith<$Res>
    implements $WidgetContextCopyWith<$Res> {
  factory _$$WidgetContextImplCopyWith(
    _$WidgetContextImpl value,
    $Res Function(_$WidgetContextImpl) then,
  ) = __$$WidgetContextImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    PropertyModel property,
    UnitModel unit,
    WidgetSettings settings,
    String ownerId,
  });

  @override
  $PropertyModelCopyWith<$Res> get property;
  @override
  $UnitModelCopyWith<$Res> get unit;
}

/// @nodoc
class __$$WidgetContextImplCopyWithImpl<$Res>
    extends _$WidgetContextCopyWithImpl<$Res, _$WidgetContextImpl>
    implements _$$WidgetContextImplCopyWith<$Res> {
  __$$WidgetContextImplCopyWithImpl(
    _$WidgetContextImpl _value,
    $Res Function(_$WidgetContextImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of WidgetContext
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? property = null,
    Object? unit = null,
    Object? settings = null,
    Object? ownerId = null,
  }) {
    return _then(
      _$WidgetContextImpl(
        property: null == property
            ? _value.property
            : property // ignore: cast_nullable_to_non_nullable
                  as PropertyModel,
        unit: null == unit
            ? _value.unit
            : unit // ignore: cast_nullable_to_non_nullable
                  as UnitModel,
        settings: null == settings
            ? _value.settings
            : settings // ignore: cast_nullable_to_non_nullable
                  as WidgetSettings,
        ownerId: null == ownerId
            ? _value.ownerId
            : ownerId // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$WidgetContextImpl extends _WidgetContext {
  const _$WidgetContextImpl({
    required this.property,
    required this.unit,
    required this.settings,
    required this.ownerId,
  }) : super._();

  /// Parent property containing this unit
  @override
  final PropertyModel property;

  /// The unit being booked
  @override
  final UnitModel unit;

  /// Widget settings for this unit (payment, approval, etc.)
  @override
  final WidgetSettings settings;

  /// Owner's user ID (extracted for convenience)
  @override
  final String ownerId;

  @override
  String toString() {
    return 'WidgetContext(property: $property, unit: $unit, settings: $settings, ownerId: $ownerId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WidgetContextImpl &&
            (identical(other.property, property) ||
                other.property == property) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.settings, settings) ||
                other.settings == settings) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, property, unit, settings, ownerId);

  /// Create a copy of WidgetContext
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WidgetContextImplCopyWith<_$WidgetContextImpl> get copyWith =>
      __$$WidgetContextImplCopyWithImpl<_$WidgetContextImpl>(this, _$identity);
}

abstract class _WidgetContext extends WidgetContext {
  const factory _WidgetContext({
    required final PropertyModel property,
    required final UnitModel unit,
    required final WidgetSettings settings,
    required final String ownerId,
  }) = _$WidgetContextImpl;
  const _WidgetContext._() : super._();

  /// Parent property containing this unit
  @override
  PropertyModel get property;

  /// The unit being booked
  @override
  UnitModel get unit;

  /// Widget settings for this unit (payment, approval, etc.)
  @override
  WidgetSettings get settings;

  /// Owner's user ID (extracted for convenience)
  @override
  String get ownerId;

  /// Create a copy of WidgetContext
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WidgetContextImplCopyWith<_$WidgetContextImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
