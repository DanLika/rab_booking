// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'daily_price_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

DailyPriceModel _$DailyPriceModelFromJson(Map<String, dynamic> json) {
  return _DailyPriceModel.fromJson(json);
}

/// @nodoc
mixin _$DailyPriceModel {
  /// Daily Price ID (UUID)
  String get id => throw _privateConstructorUsedError;

  /// Unit ID
  @JsonKey(name: 'unit_id')
  String get unitId => throw _privateConstructorUsedError;

  /// Date
  @TimestampConverter()
  DateTime get date => throw _privateConstructorUsedError;

  /// Base price for this date
  double get price => throw _privateConstructorUsedError;

  /// Is this date available for booking? (false = closed/blocked)
  bool get available =>
      throw _privateConstructorUsedError; // === AVAILABILITY RESTRICTIONS ===
  /// Block check-in (guests cannot START their stay on this date)
  @JsonKey(name: 'block_checkin')
  bool get blockCheckIn => throw _privateConstructorUsedError;

  /// Block check-out (guests cannot END their stay on this date)
  @JsonKey(name: 'block_checkout')
  bool get blockCheckOut => throw _privateConstructorUsedError; // === LENGTH OF STAY RESTRICTIONS ===
  /// Minimum nights required if arriving on this date
  @JsonKey(name: 'min_nights_on_arrival')
  int? get minNightsOnArrival => throw _privateConstructorUsedError;

  /// Maximum nights allowed if arriving on this date
  @JsonKey(name: 'max_nights_on_arrival')
  int? get maxNightsOnArrival => throw _privateConstructorUsedError; // === PRICE PERSONALIZATION ===
  /// Weekend price override for this date
  @JsonKey(name: 'weekend_price')
  double? get weekendPrice => throw _privateConstructorUsedError; // === ADVANCE BOOKING WINDOW ===
  /// Minimum days in advance required to book this date
  @JsonKey(name: 'min_days_advance')
  int? get minDaysAdvance => throw _privateConstructorUsedError;

  /// Maximum days in advance allowed to book this date
  @JsonKey(name: 'max_days_advance')
  int? get maxDaysAdvance => throw _privateConstructorUsedError; // === TIMESTAMPS ===
  /// Created at timestamp
  @TimestampConverter()
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Updated at timestamp
  @NullableTimestampConverter()
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this DailyPriceModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DailyPriceModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DailyPriceModelCopyWith<DailyPriceModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DailyPriceModelCopyWith<$Res> {
  factory $DailyPriceModelCopyWith(
    DailyPriceModel value,
    $Res Function(DailyPriceModel) then,
  ) = _$DailyPriceModelCopyWithImpl<$Res, DailyPriceModel>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'unit_id') String unitId,
    @TimestampConverter() DateTime date,
    double price,
    bool available,
    @JsonKey(name: 'block_checkin') bool blockCheckIn,
    @JsonKey(name: 'block_checkout') bool blockCheckOut,
    @JsonKey(name: 'min_nights_on_arrival') int? minNightsOnArrival,
    @JsonKey(name: 'max_nights_on_arrival') int? maxNightsOnArrival,
    @JsonKey(name: 'weekend_price') double? weekendPrice,
    @JsonKey(name: 'min_days_advance') int? minDaysAdvance,
    @JsonKey(name: 'max_days_advance') int? maxDaysAdvance,
    @TimestampConverter() @JsonKey(name: 'created_at') DateTime createdAt,
    @NullableTimestampConverter()
    @JsonKey(name: 'updated_at')
    DateTime? updatedAt,
  });
}

/// @nodoc
class _$DailyPriceModelCopyWithImpl<$Res, $Val extends DailyPriceModel>
    implements $DailyPriceModelCopyWith<$Res> {
  _$DailyPriceModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DailyPriceModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? unitId = null,
    Object? date = null,
    Object? price = null,
    Object? available = null,
    Object? blockCheckIn = null,
    Object? blockCheckOut = null,
    Object? minNightsOnArrival = freezed,
    Object? maxNightsOnArrival = freezed,
    Object? weekendPrice = freezed,
    Object? minDaysAdvance = freezed,
    Object? maxDaysAdvance = freezed,
    Object? createdAt = null,
    Object? updatedAt = freezed,
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
            date: null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            price: null == price
                ? _value.price
                : price // ignore: cast_nullable_to_non_nullable
                      as double,
            available: null == available
                ? _value.available
                : available // ignore: cast_nullable_to_non_nullable
                      as bool,
            blockCheckIn: null == blockCheckIn
                ? _value.blockCheckIn
                : blockCheckIn // ignore: cast_nullable_to_non_nullable
                      as bool,
            blockCheckOut: null == blockCheckOut
                ? _value.blockCheckOut
                : blockCheckOut // ignore: cast_nullable_to_non_nullable
                      as bool,
            minNightsOnArrival: freezed == minNightsOnArrival
                ? _value.minNightsOnArrival
                : minNightsOnArrival // ignore: cast_nullable_to_non_nullable
                      as int?,
            maxNightsOnArrival: freezed == maxNightsOnArrival
                ? _value.maxNightsOnArrival
                : maxNightsOnArrival // ignore: cast_nullable_to_non_nullable
                      as int?,
            weekendPrice: freezed == weekendPrice
                ? _value.weekendPrice
                : weekendPrice // ignore: cast_nullable_to_non_nullable
                      as double?,
            minDaysAdvance: freezed == minDaysAdvance
                ? _value.minDaysAdvance
                : minDaysAdvance // ignore: cast_nullable_to_non_nullable
                      as int?,
            maxDaysAdvance: freezed == maxDaysAdvance
                ? _value.maxDaysAdvance
                : maxDaysAdvance // ignore: cast_nullable_to_non_nullable
                      as int?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DailyPriceModelImplCopyWith<$Res>
    implements $DailyPriceModelCopyWith<$Res> {
  factory _$$DailyPriceModelImplCopyWith(
    _$DailyPriceModelImpl value,
    $Res Function(_$DailyPriceModelImpl) then,
  ) = __$$DailyPriceModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'unit_id') String unitId,
    @TimestampConverter() DateTime date,
    double price,
    bool available,
    @JsonKey(name: 'block_checkin') bool blockCheckIn,
    @JsonKey(name: 'block_checkout') bool blockCheckOut,
    @JsonKey(name: 'min_nights_on_arrival') int? minNightsOnArrival,
    @JsonKey(name: 'max_nights_on_arrival') int? maxNightsOnArrival,
    @JsonKey(name: 'weekend_price') double? weekendPrice,
    @JsonKey(name: 'min_days_advance') int? minDaysAdvance,
    @JsonKey(name: 'max_days_advance') int? maxDaysAdvance,
    @TimestampConverter() @JsonKey(name: 'created_at') DateTime createdAt,
    @NullableTimestampConverter()
    @JsonKey(name: 'updated_at')
    DateTime? updatedAt,
  });
}

/// @nodoc
class __$$DailyPriceModelImplCopyWithImpl<$Res>
    extends _$DailyPriceModelCopyWithImpl<$Res, _$DailyPriceModelImpl>
    implements _$$DailyPriceModelImplCopyWith<$Res> {
  __$$DailyPriceModelImplCopyWithImpl(
    _$DailyPriceModelImpl _value,
    $Res Function(_$DailyPriceModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DailyPriceModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? unitId = null,
    Object? date = null,
    Object? price = null,
    Object? available = null,
    Object? blockCheckIn = null,
    Object? blockCheckOut = null,
    Object? minNightsOnArrival = freezed,
    Object? maxNightsOnArrival = freezed,
    Object? weekendPrice = freezed,
    Object? minDaysAdvance = freezed,
    Object? maxDaysAdvance = freezed,
    Object? createdAt = null,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$DailyPriceModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        unitId: null == unitId
            ? _value.unitId
            : unitId // ignore: cast_nullable_to_non_nullable
                  as String,
        date: null == date
            ? _value.date
            : date // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        price: null == price
            ? _value.price
            : price // ignore: cast_nullable_to_non_nullable
                  as double,
        available: null == available
            ? _value.available
            : available // ignore: cast_nullable_to_non_nullable
                  as bool,
        blockCheckIn: null == blockCheckIn
            ? _value.blockCheckIn
            : blockCheckIn // ignore: cast_nullable_to_non_nullable
                  as bool,
        blockCheckOut: null == blockCheckOut
            ? _value.blockCheckOut
            : blockCheckOut // ignore: cast_nullable_to_non_nullable
                  as bool,
        minNightsOnArrival: freezed == minNightsOnArrival
            ? _value.minNightsOnArrival
            : minNightsOnArrival // ignore: cast_nullable_to_non_nullable
                  as int?,
        maxNightsOnArrival: freezed == maxNightsOnArrival
            ? _value.maxNightsOnArrival
            : maxNightsOnArrival // ignore: cast_nullable_to_non_nullable
                  as int?,
        weekendPrice: freezed == weekendPrice
            ? _value.weekendPrice
            : weekendPrice // ignore: cast_nullable_to_non_nullable
                  as double?,
        minDaysAdvance: freezed == minDaysAdvance
            ? _value.minDaysAdvance
            : minDaysAdvance // ignore: cast_nullable_to_non_nullable
                  as int?,
        maxDaysAdvance: freezed == maxDaysAdvance
            ? _value.maxDaysAdvance
            : maxDaysAdvance // ignore: cast_nullable_to_non_nullable
                  as int?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DailyPriceModelImpl extends _DailyPriceModel {
  const _$DailyPriceModelImpl({
    required this.id,
    @JsonKey(name: 'unit_id') required this.unitId,
    @TimestampConverter() required this.date,
    required this.price,
    this.available = true,
    @JsonKey(name: 'block_checkin') this.blockCheckIn = false,
    @JsonKey(name: 'block_checkout') this.blockCheckOut = false,
    @JsonKey(name: 'min_nights_on_arrival') this.minNightsOnArrival,
    @JsonKey(name: 'max_nights_on_arrival') this.maxNightsOnArrival,
    @JsonKey(name: 'weekend_price') this.weekendPrice,
    @JsonKey(name: 'min_days_advance') this.minDaysAdvance,
    @JsonKey(name: 'max_days_advance') this.maxDaysAdvance,
    @TimestampConverter() @JsonKey(name: 'created_at') required this.createdAt,
    @NullableTimestampConverter() @JsonKey(name: 'updated_at') this.updatedAt,
  }) : super._();

  factory _$DailyPriceModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$DailyPriceModelImplFromJson(json);

  /// Daily Price ID (UUID)
  @override
  final String id;

  /// Unit ID
  @override
  @JsonKey(name: 'unit_id')
  final String unitId;

  /// Date
  @override
  @TimestampConverter()
  final DateTime date;

  /// Base price for this date
  @override
  final double price;

  /// Is this date available for booking? (false = closed/blocked)
  @override
  @JsonKey()
  final bool available;
  // === AVAILABILITY RESTRICTIONS ===
  /// Block check-in (guests cannot START their stay on this date)
  @override
  @JsonKey(name: 'block_checkin')
  final bool blockCheckIn;

  /// Block check-out (guests cannot END their stay on this date)
  @override
  @JsonKey(name: 'block_checkout')
  final bool blockCheckOut;
  // === LENGTH OF STAY RESTRICTIONS ===
  /// Minimum nights required if arriving on this date
  @override
  @JsonKey(name: 'min_nights_on_arrival')
  final int? minNightsOnArrival;

  /// Maximum nights allowed if arriving on this date
  @override
  @JsonKey(name: 'max_nights_on_arrival')
  final int? maxNightsOnArrival;
  // === PRICE PERSONALIZATION ===
  /// Weekend price override for this date
  @override
  @JsonKey(name: 'weekend_price')
  final double? weekendPrice;
  // === ADVANCE BOOKING WINDOW ===
  /// Minimum days in advance required to book this date
  @override
  @JsonKey(name: 'min_days_advance')
  final int? minDaysAdvance;

  /// Maximum days in advance allowed to book this date
  @override
  @JsonKey(name: 'max_days_advance')
  final int? maxDaysAdvance;
  // === TIMESTAMPS ===
  /// Created at timestamp
  @override
  @TimestampConverter()
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  /// Updated at timestamp
  @override
  @NullableTimestampConverter()
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'DailyPriceModel(id: $id, unitId: $unitId, date: $date, price: $price, available: $available, blockCheckIn: $blockCheckIn, blockCheckOut: $blockCheckOut, minNightsOnArrival: $minNightsOnArrival, maxNightsOnArrival: $maxNightsOnArrival, weekendPrice: $weekendPrice, minDaysAdvance: $minDaysAdvance, maxDaysAdvance: $maxDaysAdvance, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DailyPriceModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.unitId, unitId) || other.unitId == unitId) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.available, available) ||
                other.available == available) &&
            (identical(other.blockCheckIn, blockCheckIn) ||
                other.blockCheckIn == blockCheckIn) &&
            (identical(other.blockCheckOut, blockCheckOut) ||
                other.blockCheckOut == blockCheckOut) &&
            (identical(other.minNightsOnArrival, minNightsOnArrival) ||
                other.minNightsOnArrival == minNightsOnArrival) &&
            (identical(other.maxNightsOnArrival, maxNightsOnArrival) ||
                other.maxNightsOnArrival == maxNightsOnArrival) &&
            (identical(other.weekendPrice, weekendPrice) ||
                other.weekendPrice == weekendPrice) &&
            (identical(other.minDaysAdvance, minDaysAdvance) ||
                other.minDaysAdvance == minDaysAdvance) &&
            (identical(other.maxDaysAdvance, maxDaysAdvance) ||
                other.maxDaysAdvance == maxDaysAdvance) &&
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
    date,
    price,
    available,
    blockCheckIn,
    blockCheckOut,
    minNightsOnArrival,
    maxNightsOnArrival,
    weekendPrice,
    minDaysAdvance,
    maxDaysAdvance,
    createdAt,
    updatedAt,
  );

  /// Create a copy of DailyPriceModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DailyPriceModelImplCopyWith<_$DailyPriceModelImpl> get copyWith =>
      __$$DailyPriceModelImplCopyWithImpl<_$DailyPriceModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$DailyPriceModelImplToJson(this);
  }
}

abstract class _DailyPriceModel extends DailyPriceModel {
  const factory _DailyPriceModel({
    required final String id,
    @JsonKey(name: 'unit_id') required final String unitId,
    @TimestampConverter() required final DateTime date,
    required final double price,
    final bool available,
    @JsonKey(name: 'block_checkin') final bool blockCheckIn,
    @JsonKey(name: 'block_checkout') final bool blockCheckOut,
    @JsonKey(name: 'min_nights_on_arrival') final int? minNightsOnArrival,
    @JsonKey(name: 'max_nights_on_arrival') final int? maxNightsOnArrival,
    @JsonKey(name: 'weekend_price') final double? weekendPrice,
    @JsonKey(name: 'min_days_advance') final int? minDaysAdvance,
    @JsonKey(name: 'max_days_advance') final int? maxDaysAdvance,
    @TimestampConverter()
    @JsonKey(name: 'created_at')
    required final DateTime createdAt,
    @NullableTimestampConverter()
    @JsonKey(name: 'updated_at')
    final DateTime? updatedAt,
  }) = _$DailyPriceModelImpl;
  const _DailyPriceModel._() : super._();

  factory _DailyPriceModel.fromJson(Map<String, dynamic> json) =
      _$DailyPriceModelImpl.fromJson;

  /// Daily Price ID (UUID)
  @override
  String get id;

  /// Unit ID
  @override
  @JsonKey(name: 'unit_id')
  String get unitId;

  /// Date
  @override
  @TimestampConverter()
  DateTime get date;

  /// Base price for this date
  @override
  double get price;

  /// Is this date available for booking? (false = closed/blocked)
  @override
  bool get available; // === AVAILABILITY RESTRICTIONS ===
  /// Block check-in (guests cannot START their stay on this date)
  @override
  @JsonKey(name: 'block_checkin')
  bool get blockCheckIn;

  /// Block check-out (guests cannot END their stay on this date)
  @override
  @JsonKey(name: 'block_checkout')
  bool get blockCheckOut; // === LENGTH OF STAY RESTRICTIONS ===
  /// Minimum nights required if arriving on this date
  @override
  @JsonKey(name: 'min_nights_on_arrival')
  int? get minNightsOnArrival;

  /// Maximum nights allowed if arriving on this date
  @override
  @JsonKey(name: 'max_nights_on_arrival')
  int? get maxNightsOnArrival; // === PRICE PERSONALIZATION ===
  /// Weekend price override for this date
  @override
  @JsonKey(name: 'weekend_price')
  double? get weekendPrice; // === ADVANCE BOOKING WINDOW ===
  /// Minimum days in advance required to book this date
  @override
  @JsonKey(name: 'min_days_advance')
  int? get minDaysAdvance;

  /// Maximum days in advance allowed to book this date
  @override
  @JsonKey(name: 'max_days_advance')
  int? get maxDaysAdvance; // === TIMESTAMPS ===
  /// Created at timestamp
  @override
  @TimestampConverter()
  @JsonKey(name: 'created_at')
  DateTime get createdAt;

  /// Updated at timestamp
  @override
  @NullableTimestampConverter()
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;

  /// Create a copy of DailyPriceModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DailyPriceModelImplCopyWith<_$DailyPriceModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
