// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'booking_service_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

BookingServiceModel _$BookingServiceModelFromJson(Map<String, dynamic> json) {
  return _BookingServiceModel.fromJson(json);
}

/// @nodoc
mixin _$BookingServiceModel {
  /// Booking Service ID (UUID)
  String get id => throw _privateConstructorUsedError;

  /// Booking ID
  @JsonKey(name: 'booking_id')
  String get bookingId => throw _privateConstructorUsedError;

  /// Service ID
  @JsonKey(name: 'service_id')
  String get serviceId => throw _privateConstructorUsedError;

  /// Quantity
  int get quantity => throw _privateConstructorUsedError;

  /// Unit price (snapshot at booking time)
  @JsonKey(name: 'unit_price')
  double get unitPrice => throw _privateConstructorUsedError;

  /// Total price (calculated: quantity × unit_price × multiplier)
  @JsonKey(name: 'total_price')
  double get totalPrice => throw _privateConstructorUsedError;

  /// Created at timestamp
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this BookingServiceModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BookingServiceModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BookingServiceModelCopyWith<BookingServiceModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BookingServiceModelCopyWith<$Res> {
  factory $BookingServiceModelCopyWith(
    BookingServiceModel value,
    $Res Function(BookingServiceModel) then,
  ) = _$BookingServiceModelCopyWithImpl<$Res, BookingServiceModel>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'booking_id') String bookingId,
    @JsonKey(name: 'service_id') String serviceId,
    int quantity,
    @JsonKey(name: 'unit_price') double unitPrice,
    @JsonKey(name: 'total_price') double totalPrice,
    @JsonKey(name: 'created_at') DateTime createdAt,
  });
}

/// @nodoc
class _$BookingServiceModelCopyWithImpl<$Res, $Val extends BookingServiceModel>
    implements $BookingServiceModelCopyWith<$Res> {
  _$BookingServiceModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BookingServiceModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? bookingId = null,
    Object? serviceId = null,
    Object? quantity = null,
    Object? unitPrice = null,
    Object? totalPrice = null,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            bookingId: null == bookingId
                ? _value.bookingId
                : bookingId // ignore: cast_nullable_to_non_nullable
                      as String,
            serviceId: null == serviceId
                ? _value.serviceId
                : serviceId // ignore: cast_nullable_to_non_nullable
                      as String,
            quantity: null == quantity
                ? _value.quantity
                : quantity // ignore: cast_nullable_to_non_nullable
                      as int,
            unitPrice: null == unitPrice
                ? _value.unitPrice
                : unitPrice // ignore: cast_nullable_to_non_nullable
                      as double,
            totalPrice: null == totalPrice
                ? _value.totalPrice
                : totalPrice // ignore: cast_nullable_to_non_nullable
                      as double,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BookingServiceModelImplCopyWith<$Res>
    implements $BookingServiceModelCopyWith<$Res> {
  factory _$$BookingServiceModelImplCopyWith(
    _$BookingServiceModelImpl value,
    $Res Function(_$BookingServiceModelImpl) then,
  ) = __$$BookingServiceModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'booking_id') String bookingId,
    @JsonKey(name: 'service_id') String serviceId,
    int quantity,
    @JsonKey(name: 'unit_price') double unitPrice,
    @JsonKey(name: 'total_price') double totalPrice,
    @JsonKey(name: 'created_at') DateTime createdAt,
  });
}

/// @nodoc
class __$$BookingServiceModelImplCopyWithImpl<$Res>
    extends _$BookingServiceModelCopyWithImpl<$Res, _$BookingServiceModelImpl>
    implements _$$BookingServiceModelImplCopyWith<$Res> {
  __$$BookingServiceModelImplCopyWithImpl(
    _$BookingServiceModelImpl _value,
    $Res Function(_$BookingServiceModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BookingServiceModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? bookingId = null,
    Object? serviceId = null,
    Object? quantity = null,
    Object? unitPrice = null,
    Object? totalPrice = null,
    Object? createdAt = null,
  }) {
    return _then(
      _$BookingServiceModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        bookingId: null == bookingId
            ? _value.bookingId
            : bookingId // ignore: cast_nullable_to_non_nullable
                  as String,
        serviceId: null == serviceId
            ? _value.serviceId
            : serviceId // ignore: cast_nullable_to_non_nullable
                  as String,
        quantity: null == quantity
            ? _value.quantity
            : quantity // ignore: cast_nullable_to_non_nullable
                  as int,
        unitPrice: null == unitPrice
            ? _value.unitPrice
            : unitPrice // ignore: cast_nullable_to_non_nullable
                  as double,
        totalPrice: null == totalPrice
            ? _value.totalPrice
            : totalPrice // ignore: cast_nullable_to_non_nullable
                  as double,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$BookingServiceModelImpl extends _BookingServiceModel {
  const _$BookingServiceModelImpl({
    required this.id,
    @JsonKey(name: 'booking_id') required this.bookingId,
    @JsonKey(name: 'service_id') required this.serviceId,
    this.quantity = 1,
    @JsonKey(name: 'unit_price') required this.unitPrice,
    @JsonKey(name: 'total_price') required this.totalPrice,
    @JsonKey(name: 'created_at') required this.createdAt,
  }) : super._();

  factory _$BookingServiceModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$BookingServiceModelImplFromJson(json);

  /// Booking Service ID (UUID)
  @override
  final String id;

  /// Booking ID
  @override
  @JsonKey(name: 'booking_id')
  final String bookingId;

  /// Service ID
  @override
  @JsonKey(name: 'service_id')
  final String serviceId;

  /// Quantity
  @override
  @JsonKey()
  final int quantity;

  /// Unit price (snapshot at booking time)
  @override
  @JsonKey(name: 'unit_price')
  final double unitPrice;

  /// Total price (calculated: quantity × unit_price × multiplier)
  @override
  @JsonKey(name: 'total_price')
  final double totalPrice;

  /// Created at timestamp
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @override
  String toString() {
    return 'BookingServiceModel(id: $id, bookingId: $bookingId, serviceId: $serviceId, quantity: $quantity, unitPrice: $unitPrice, totalPrice: $totalPrice, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BookingServiceModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.bookingId, bookingId) ||
                other.bookingId == bookingId) &&
            (identical(other.serviceId, serviceId) ||
                other.serviceId == serviceId) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.unitPrice, unitPrice) ||
                other.unitPrice == unitPrice) &&
            (identical(other.totalPrice, totalPrice) ||
                other.totalPrice == totalPrice) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    bookingId,
    serviceId,
    quantity,
    unitPrice,
    totalPrice,
    createdAt,
  );

  /// Create a copy of BookingServiceModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BookingServiceModelImplCopyWith<_$BookingServiceModelImpl> get copyWith =>
      __$$BookingServiceModelImplCopyWithImpl<_$BookingServiceModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$BookingServiceModelImplToJson(this);
  }
}

abstract class _BookingServiceModel extends BookingServiceModel {
  const factory _BookingServiceModel({
    required final String id,
    @JsonKey(name: 'booking_id') required final String bookingId,
    @JsonKey(name: 'service_id') required final String serviceId,
    final int quantity,
    @JsonKey(name: 'unit_price') required final double unitPrice,
    @JsonKey(name: 'total_price') required final double totalPrice,
    @JsonKey(name: 'created_at') required final DateTime createdAt,
  }) = _$BookingServiceModelImpl;
  const _BookingServiceModel._() : super._();

  factory _BookingServiceModel.fromJson(Map<String, dynamic> json) =
      _$BookingServiceModelImpl.fromJson;

  /// Booking Service ID (UUID)
  @override
  String get id;

  /// Booking ID
  @override
  @JsonKey(name: 'booking_id')
  String get bookingId;

  /// Service ID
  @override
  @JsonKey(name: 'service_id')
  String get serviceId;

  /// Quantity
  @override
  int get quantity;

  /// Unit price (snapshot at booking time)
  @override
  @JsonKey(name: 'unit_price')
  double get unitPrice;

  /// Total price (calculated: quantity × unit_price × multiplier)
  @override
  @JsonKey(name: 'total_price')
  double get totalPrice;

  /// Created at timestamp
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;

  /// Create a copy of BookingServiceModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BookingServiceModelImplCopyWith<_$BookingServiceModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
