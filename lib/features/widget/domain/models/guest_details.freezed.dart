// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'guest_details.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

GuestDetails _$GuestDetailsFromJson(Map<String, dynamic> json) {
  return _GuestDetails.fromJson(json);
}

/// @nodoc
mixin _$GuestDetails {
  String get name => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String get phone => throw _privateConstructorUsedError;
  String get message => throw _privateConstructorUsedError;

  /// Serializes this GuestDetails to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GuestDetails
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GuestDetailsCopyWith<GuestDetails> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GuestDetailsCopyWith<$Res> {
  factory $GuestDetailsCopyWith(
    GuestDetails value,
    $Res Function(GuestDetails) then,
  ) = _$GuestDetailsCopyWithImpl<$Res, GuestDetails>;
  @useResult
  $Res call({String name, String email, String phone, String message});
}

/// @nodoc
class _$GuestDetailsCopyWithImpl<$Res, $Val extends GuestDetails>
    implements $GuestDetailsCopyWith<$Res> {
  _$GuestDetailsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GuestDetails
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? email = null,
    Object? phone = null,
    Object? message = null,
  }) {
    return _then(
      _value.copyWith(
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            email: null == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String,
            phone: null == phone
                ? _value.phone
                : phone // ignore: cast_nullable_to_non_nullable
                      as String,
            message: null == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$GuestDetailsImplCopyWith<$Res>
    implements $GuestDetailsCopyWith<$Res> {
  factory _$$GuestDetailsImplCopyWith(
    _$GuestDetailsImpl value,
    $Res Function(_$GuestDetailsImpl) then,
  ) = __$$GuestDetailsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String name, String email, String phone, String message});
}

/// @nodoc
class __$$GuestDetailsImplCopyWithImpl<$Res>
    extends _$GuestDetailsCopyWithImpl<$Res, _$GuestDetailsImpl>
    implements _$$GuestDetailsImplCopyWith<$Res> {
  __$$GuestDetailsImplCopyWithImpl(
    _$GuestDetailsImpl _value,
    $Res Function(_$GuestDetailsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GuestDetails
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? email = null,
    Object? phone = null,
    Object? message = null,
  }) {
    return _then(
      _$GuestDetailsImpl(
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        email: null == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String,
        phone: null == phone
            ? _value.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String,
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$GuestDetailsImpl implements _GuestDetails {
  const _$GuestDetailsImpl({
    required this.name,
    required this.email,
    required this.phone,
    this.message = '',
  });

  factory _$GuestDetailsImpl.fromJson(Map<String, dynamic> json) =>
      _$$GuestDetailsImplFromJson(json);

  @override
  final String name;
  @override
  final String email;
  @override
  final String phone;
  @override
  @JsonKey()
  final String message;

  @override
  String toString() {
    return 'GuestDetails(name: $name, email: $email, phone: $phone, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GuestDetailsImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.message, message) || other.message == message));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, email, phone, message);

  /// Create a copy of GuestDetails
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GuestDetailsImplCopyWith<_$GuestDetailsImpl> get copyWith =>
      __$$GuestDetailsImplCopyWithImpl<_$GuestDetailsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GuestDetailsImplToJson(this);
  }
}

abstract class _GuestDetails implements GuestDetails {
  const factory _GuestDetails({
    required final String name,
    required final String email,
    required final String phone,
    final String message,
  }) = _$GuestDetailsImpl;

  factory _GuestDetails.fromJson(Map<String, dynamic> json) =
      _$GuestDetailsImpl.fromJson;

  @override
  String get name;
  @override
  String get email;
  @override
  String get phone;
  @override
  String get message;

  /// Create a copy of GuestDetails
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GuestDetailsImplCopyWith<_$GuestDetailsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
