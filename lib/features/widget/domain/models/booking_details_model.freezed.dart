// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'booking_details_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

GuestCount _$GuestCountFromJson(Map<String, dynamic> json) {
  return _GuestCount.fromJson(json);
}

/// @nodoc
mixin _$GuestCount {
  int get adults => throw _privateConstructorUsedError;
  int get children => throw _privateConstructorUsedError;

  /// Serializes this GuestCount to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GuestCount
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GuestCountCopyWith<GuestCount> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GuestCountCopyWith<$Res> {
  factory $GuestCountCopyWith(
    GuestCount value,
    $Res Function(GuestCount) then,
  ) = _$GuestCountCopyWithImpl<$Res, GuestCount>;
  @useResult
  $Res call({int adults, int children});
}

/// @nodoc
class _$GuestCountCopyWithImpl<$Res, $Val extends GuestCount>
    implements $GuestCountCopyWith<$Res> {
  _$GuestCountCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GuestCount
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? adults = null, Object? children = null}) {
    return _then(
      _value.copyWith(
            adults: null == adults
                ? _value.adults
                : adults // ignore: cast_nullable_to_non_nullable
                      as int,
            children: null == children
                ? _value.children
                : children // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$GuestCountImplCopyWith<$Res>
    implements $GuestCountCopyWith<$Res> {
  factory _$$GuestCountImplCopyWith(
    _$GuestCountImpl value,
    $Res Function(_$GuestCountImpl) then,
  ) = __$$GuestCountImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int adults, int children});
}

/// @nodoc
class __$$GuestCountImplCopyWithImpl<$Res>
    extends _$GuestCountCopyWithImpl<$Res, _$GuestCountImpl>
    implements _$$GuestCountImplCopyWith<$Res> {
  __$$GuestCountImplCopyWithImpl(
    _$GuestCountImpl _value,
    $Res Function(_$GuestCountImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GuestCount
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? adults = null, Object? children = null}) {
    return _then(
      _$GuestCountImpl(
        adults: null == adults
            ? _value.adults
            : adults // ignore: cast_nullable_to_non_nullable
                  as int,
        children: null == children
            ? _value.children
            : children // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$GuestCountImpl implements _GuestCount {
  const _$GuestCountImpl({required this.adults, this.children = 0});

  factory _$GuestCountImpl.fromJson(Map<String, dynamic> json) =>
      _$$GuestCountImplFromJson(json);

  @override
  final int adults;
  @override
  @JsonKey()
  final int children;

  @override
  String toString() {
    return 'GuestCount(adults: $adults, children: $children)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GuestCountImpl &&
            (identical(other.adults, adults) || other.adults == adults) &&
            (identical(other.children, children) ||
                other.children == children));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, adults, children);

  /// Create a copy of GuestCount
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GuestCountImplCopyWith<_$GuestCountImpl> get copyWith =>
      __$$GuestCountImplCopyWithImpl<_$GuestCountImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GuestCountImplToJson(this);
  }
}

abstract class _GuestCount implements GuestCount {
  const factory _GuestCount({required final int adults, final int children}) =
      _$GuestCountImpl;

  factory _GuestCount.fromJson(Map<String, dynamic> json) =
      _$GuestCountImpl.fromJson;

  @override
  int get adults;
  @override
  int get children;

  /// Create a copy of GuestCount
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GuestCountImplCopyWith<_$GuestCountImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

BankDetails _$BankDetailsFromJson(Map<String, dynamic> json) {
  return _BankDetails.fromJson(json);
}

/// @nodoc
mixin _$BankDetails {
  String? get bankName => throw _privateConstructorUsedError;
  String? get accountHolder => throw _privateConstructorUsedError;
  String? get iban => throw _privateConstructorUsedError;
  String? get swift => throw _privateConstructorUsedError;

  /// Serializes this BankDetails to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BankDetails
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BankDetailsCopyWith<BankDetails> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BankDetailsCopyWith<$Res> {
  factory $BankDetailsCopyWith(
    BankDetails value,
    $Res Function(BankDetails) then,
  ) = _$BankDetailsCopyWithImpl<$Res, BankDetails>;
  @useResult
  $Res call({
    String? bankName,
    String? accountHolder,
    String? iban,
    String? swift,
  });
}

/// @nodoc
class _$BankDetailsCopyWithImpl<$Res, $Val extends BankDetails>
    implements $BankDetailsCopyWith<$Res> {
  _$BankDetailsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BankDetails
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? bankName = freezed,
    Object? accountHolder = freezed,
    Object? iban = freezed,
    Object? swift = freezed,
  }) {
    return _then(
      _value.copyWith(
            bankName: freezed == bankName
                ? _value.bankName
                : bankName // ignore: cast_nullable_to_non_nullable
                      as String?,
            accountHolder: freezed == accountHolder
                ? _value.accountHolder
                : accountHolder // ignore: cast_nullable_to_non_nullable
                      as String?,
            iban: freezed == iban
                ? _value.iban
                : iban // ignore: cast_nullable_to_non_nullable
                      as String?,
            swift: freezed == swift
                ? _value.swift
                : swift // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BankDetailsImplCopyWith<$Res>
    implements $BankDetailsCopyWith<$Res> {
  factory _$$BankDetailsImplCopyWith(
    _$BankDetailsImpl value,
    $Res Function(_$BankDetailsImpl) then,
  ) = __$$BankDetailsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String? bankName,
    String? accountHolder,
    String? iban,
    String? swift,
  });
}

/// @nodoc
class __$$BankDetailsImplCopyWithImpl<$Res>
    extends _$BankDetailsCopyWithImpl<$Res, _$BankDetailsImpl>
    implements _$$BankDetailsImplCopyWith<$Res> {
  __$$BankDetailsImplCopyWithImpl(
    _$BankDetailsImpl _value,
    $Res Function(_$BankDetailsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BankDetails
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? bankName = freezed,
    Object? accountHolder = freezed,
    Object? iban = freezed,
    Object? swift = freezed,
  }) {
    return _then(
      _$BankDetailsImpl(
        bankName: freezed == bankName
            ? _value.bankName
            : bankName // ignore: cast_nullable_to_non_nullable
                  as String?,
        accountHolder: freezed == accountHolder
            ? _value.accountHolder
            : accountHolder // ignore: cast_nullable_to_non_nullable
                  as String?,
        iban: freezed == iban
            ? _value.iban
            : iban // ignore: cast_nullable_to_non_nullable
                  as String?,
        swift: freezed == swift
            ? _value.swift
            : swift // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$BankDetailsImpl implements _BankDetails {
  const _$BankDetailsImpl({
    this.bankName,
    this.accountHolder,
    this.iban,
    this.swift,
  });

  factory _$BankDetailsImpl.fromJson(Map<String, dynamic> json) =>
      _$$BankDetailsImplFromJson(json);

  @override
  final String? bankName;
  @override
  final String? accountHolder;
  @override
  final String? iban;
  @override
  final String? swift;

  @override
  String toString() {
    return 'BankDetails(bankName: $bankName, accountHolder: $accountHolder, iban: $iban, swift: $swift)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BankDetailsImpl &&
            (identical(other.bankName, bankName) ||
                other.bankName == bankName) &&
            (identical(other.accountHolder, accountHolder) ||
                other.accountHolder == accountHolder) &&
            (identical(other.iban, iban) || other.iban == iban) &&
            (identical(other.swift, swift) || other.swift == swift));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, bankName, accountHolder, iban, swift);

  /// Create a copy of BankDetails
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BankDetailsImplCopyWith<_$BankDetailsImpl> get copyWith =>
      __$$BankDetailsImplCopyWithImpl<_$BankDetailsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BankDetailsImplToJson(this);
  }
}

abstract class _BankDetails implements BankDetails {
  const factory _BankDetails({
    final String? bankName,
    final String? accountHolder,
    final String? iban,
    final String? swift,
  }) = _$BankDetailsImpl;

  factory _BankDetails.fromJson(Map<String, dynamic> json) =
      _$BankDetailsImpl.fromJson;

  @override
  String? get bankName;
  @override
  String? get accountHolder;
  @override
  String? get iban;
  @override
  String? get swift;

  /// Create a copy of BankDetails
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BankDetailsImplCopyWith<_$BankDetailsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

BookingDetailsModel _$BookingDetailsModelFromJson(Map<String, dynamic> json) {
  return _BookingDetailsModel.fromJson(json);
}

/// @nodoc
mixin _$BookingDetailsModel {
  String get bookingId => throw _privateConstructorUsedError;
  String get bookingReference => throw _privateConstructorUsedError;
  String? get propertyId =>
      throw _privateConstructorUsedError; // Property ID for fetching widget settings
  String? get unitId =>
      throw _privateConstructorUsedError; // Unit ID for fetching widget settings
  String get propertyName => throw _privateConstructorUsedError;
  String get unitName => throw _privateConstructorUsedError;
  String get guestName => throw _privateConstructorUsedError;
  String get guestEmail => throw _privateConstructorUsedError;
  String? get guestPhone => throw _privateConstructorUsedError;
  String get checkIn => throw _privateConstructorUsedError; // ISO 8601 string
  String get checkOut => throw _privateConstructorUsedError; // ISO 8601 string
  int get nights => throw _privateConstructorUsedError;
  GuestCount get guestCount => throw _privateConstructorUsedError;
  double get totalPrice => throw _privateConstructorUsedError;
  double get depositAmount => throw _privateConstructorUsedError;
  double get remainingAmount => throw _privateConstructorUsedError;
  double get paidAmount => throw _privateConstructorUsedError;
  String get paymentStatus => throw _privateConstructorUsedError;
  String get paymentMethod => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String? get ownerEmail => throw _privateConstructorUsedError;
  String? get ownerPhone => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  String? get createdAt =>
      throw _privateConstructorUsedError; // ISO 8601 string
  String? get paymentDeadline =>
      throw _privateConstructorUsedError; // ISO 8601 string
  BankDetails? get bankDetails => throw _privateConstructorUsedError;

  /// Serializes this BookingDetailsModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BookingDetailsModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BookingDetailsModelCopyWith<BookingDetailsModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BookingDetailsModelCopyWith<$Res> {
  factory $BookingDetailsModelCopyWith(
    BookingDetailsModel value,
    $Res Function(BookingDetailsModel) then,
  ) = _$BookingDetailsModelCopyWithImpl<$Res, BookingDetailsModel>;
  @useResult
  $Res call({
    String bookingId,
    String bookingReference,
    String? propertyId,
    String? unitId,
    String propertyName,
    String unitName,
    String guestName,
    String guestEmail,
    String? guestPhone,
    String checkIn,
    String checkOut,
    int nights,
    GuestCount guestCount,
    double totalPrice,
    double depositAmount,
    double remainingAmount,
    double paidAmount,
    String paymentStatus,
    String paymentMethod,
    String status,
    String? ownerEmail,
    String? ownerPhone,
    String? notes,
    String? createdAt,
    String? paymentDeadline,
    BankDetails? bankDetails,
  });

  $GuestCountCopyWith<$Res> get guestCount;
  $BankDetailsCopyWith<$Res>? get bankDetails;
}

/// @nodoc
class _$BookingDetailsModelCopyWithImpl<$Res, $Val extends BookingDetailsModel>
    implements $BookingDetailsModelCopyWith<$Res> {
  _$BookingDetailsModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BookingDetailsModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? bookingId = null,
    Object? bookingReference = null,
    Object? propertyId = freezed,
    Object? unitId = freezed,
    Object? propertyName = null,
    Object? unitName = null,
    Object? guestName = null,
    Object? guestEmail = null,
    Object? guestPhone = freezed,
    Object? checkIn = null,
    Object? checkOut = null,
    Object? nights = null,
    Object? guestCount = null,
    Object? totalPrice = null,
    Object? depositAmount = null,
    Object? remainingAmount = null,
    Object? paidAmount = null,
    Object? paymentStatus = null,
    Object? paymentMethod = null,
    Object? status = null,
    Object? ownerEmail = freezed,
    Object? ownerPhone = freezed,
    Object? notes = freezed,
    Object? createdAt = freezed,
    Object? paymentDeadline = freezed,
    Object? bankDetails = freezed,
  }) {
    return _then(
      _value.copyWith(
            bookingId: null == bookingId
                ? _value.bookingId
                : bookingId // ignore: cast_nullable_to_non_nullable
                      as String,
            bookingReference: null == bookingReference
                ? _value.bookingReference
                : bookingReference // ignore: cast_nullable_to_non_nullable
                      as String,
            propertyId: freezed == propertyId
                ? _value.propertyId
                : propertyId // ignore: cast_nullable_to_non_nullable
                      as String?,
            unitId: freezed == unitId
                ? _value.unitId
                : unitId // ignore: cast_nullable_to_non_nullable
                      as String?,
            propertyName: null == propertyName
                ? _value.propertyName
                : propertyName // ignore: cast_nullable_to_non_nullable
                      as String,
            unitName: null == unitName
                ? _value.unitName
                : unitName // ignore: cast_nullable_to_non_nullable
                      as String,
            guestName: null == guestName
                ? _value.guestName
                : guestName // ignore: cast_nullable_to_non_nullable
                      as String,
            guestEmail: null == guestEmail
                ? _value.guestEmail
                : guestEmail // ignore: cast_nullable_to_non_nullable
                      as String,
            guestPhone: freezed == guestPhone
                ? _value.guestPhone
                : guestPhone // ignore: cast_nullable_to_non_nullable
                      as String?,
            checkIn: null == checkIn
                ? _value.checkIn
                : checkIn // ignore: cast_nullable_to_non_nullable
                      as String,
            checkOut: null == checkOut
                ? _value.checkOut
                : checkOut // ignore: cast_nullable_to_non_nullable
                      as String,
            nights: null == nights
                ? _value.nights
                : nights // ignore: cast_nullable_to_non_nullable
                      as int,
            guestCount: null == guestCount
                ? _value.guestCount
                : guestCount // ignore: cast_nullable_to_non_nullable
                      as GuestCount,
            totalPrice: null == totalPrice
                ? _value.totalPrice
                : totalPrice // ignore: cast_nullable_to_non_nullable
                      as double,
            depositAmount: null == depositAmount
                ? _value.depositAmount
                : depositAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            remainingAmount: null == remainingAmount
                ? _value.remainingAmount
                : remainingAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            paidAmount: null == paidAmount
                ? _value.paidAmount
                : paidAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            paymentStatus: null == paymentStatus
                ? _value.paymentStatus
                : paymentStatus // ignore: cast_nullable_to_non_nullable
                      as String,
            paymentMethod: null == paymentMethod
                ? _value.paymentMethod
                : paymentMethod // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            ownerEmail: freezed == ownerEmail
                ? _value.ownerEmail
                : ownerEmail // ignore: cast_nullable_to_non_nullable
                      as String?,
            ownerPhone: freezed == ownerPhone
                ? _value.ownerPhone
                : ownerPhone // ignore: cast_nullable_to_non_nullable
                      as String?,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as String?,
            paymentDeadline: freezed == paymentDeadline
                ? _value.paymentDeadline
                : paymentDeadline // ignore: cast_nullable_to_non_nullable
                      as String?,
            bankDetails: freezed == bankDetails
                ? _value.bankDetails
                : bankDetails // ignore: cast_nullable_to_non_nullable
                      as BankDetails?,
          )
          as $Val,
    );
  }

  /// Create a copy of BookingDetailsModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GuestCountCopyWith<$Res> get guestCount {
    return $GuestCountCopyWith<$Res>(_value.guestCount, (value) {
      return _then(_value.copyWith(guestCount: value) as $Val);
    });
  }

  /// Create a copy of BookingDetailsModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BankDetailsCopyWith<$Res>? get bankDetails {
    if (_value.bankDetails == null) {
      return null;
    }

    return $BankDetailsCopyWith<$Res>(_value.bankDetails!, (value) {
      return _then(_value.copyWith(bankDetails: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$BookingDetailsModelImplCopyWith<$Res>
    implements $BookingDetailsModelCopyWith<$Res> {
  factory _$$BookingDetailsModelImplCopyWith(
    _$BookingDetailsModelImpl value,
    $Res Function(_$BookingDetailsModelImpl) then,
  ) = __$$BookingDetailsModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String bookingId,
    String bookingReference,
    String? propertyId,
    String? unitId,
    String propertyName,
    String unitName,
    String guestName,
    String guestEmail,
    String? guestPhone,
    String checkIn,
    String checkOut,
    int nights,
    GuestCount guestCount,
    double totalPrice,
    double depositAmount,
    double remainingAmount,
    double paidAmount,
    String paymentStatus,
    String paymentMethod,
    String status,
    String? ownerEmail,
    String? ownerPhone,
    String? notes,
    String? createdAt,
    String? paymentDeadline,
    BankDetails? bankDetails,
  });

  @override
  $GuestCountCopyWith<$Res> get guestCount;
  @override
  $BankDetailsCopyWith<$Res>? get bankDetails;
}

/// @nodoc
class __$$BookingDetailsModelImplCopyWithImpl<$Res>
    extends _$BookingDetailsModelCopyWithImpl<$Res, _$BookingDetailsModelImpl>
    implements _$$BookingDetailsModelImplCopyWith<$Res> {
  __$$BookingDetailsModelImplCopyWithImpl(
    _$BookingDetailsModelImpl _value,
    $Res Function(_$BookingDetailsModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BookingDetailsModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? bookingId = null,
    Object? bookingReference = null,
    Object? propertyId = freezed,
    Object? unitId = freezed,
    Object? propertyName = null,
    Object? unitName = null,
    Object? guestName = null,
    Object? guestEmail = null,
    Object? guestPhone = freezed,
    Object? checkIn = null,
    Object? checkOut = null,
    Object? nights = null,
    Object? guestCount = null,
    Object? totalPrice = null,
    Object? depositAmount = null,
    Object? remainingAmount = null,
    Object? paidAmount = null,
    Object? paymentStatus = null,
    Object? paymentMethod = null,
    Object? status = null,
    Object? ownerEmail = freezed,
    Object? ownerPhone = freezed,
    Object? notes = freezed,
    Object? createdAt = freezed,
    Object? paymentDeadline = freezed,
    Object? bankDetails = freezed,
  }) {
    return _then(
      _$BookingDetailsModelImpl(
        bookingId: null == bookingId
            ? _value.bookingId
            : bookingId // ignore: cast_nullable_to_non_nullable
                  as String,
        bookingReference: null == bookingReference
            ? _value.bookingReference
            : bookingReference // ignore: cast_nullable_to_non_nullable
                  as String,
        propertyId: freezed == propertyId
            ? _value.propertyId
            : propertyId // ignore: cast_nullable_to_non_nullable
                  as String?,
        unitId: freezed == unitId
            ? _value.unitId
            : unitId // ignore: cast_nullable_to_non_nullable
                  as String?,
        propertyName: null == propertyName
            ? _value.propertyName
            : propertyName // ignore: cast_nullable_to_non_nullable
                  as String,
        unitName: null == unitName
            ? _value.unitName
            : unitName // ignore: cast_nullable_to_non_nullable
                  as String,
        guestName: null == guestName
            ? _value.guestName
            : guestName // ignore: cast_nullable_to_non_nullable
                  as String,
        guestEmail: null == guestEmail
            ? _value.guestEmail
            : guestEmail // ignore: cast_nullable_to_non_nullable
                  as String,
        guestPhone: freezed == guestPhone
            ? _value.guestPhone
            : guestPhone // ignore: cast_nullable_to_non_nullable
                  as String?,
        checkIn: null == checkIn
            ? _value.checkIn
            : checkIn // ignore: cast_nullable_to_non_nullable
                  as String,
        checkOut: null == checkOut
            ? _value.checkOut
            : checkOut // ignore: cast_nullable_to_non_nullable
                  as String,
        nights: null == nights
            ? _value.nights
            : nights // ignore: cast_nullable_to_non_nullable
                  as int,
        guestCount: null == guestCount
            ? _value.guestCount
            : guestCount // ignore: cast_nullable_to_non_nullable
                  as GuestCount,
        totalPrice: null == totalPrice
            ? _value.totalPrice
            : totalPrice // ignore: cast_nullable_to_non_nullable
                  as double,
        depositAmount: null == depositAmount
            ? _value.depositAmount
            : depositAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        remainingAmount: null == remainingAmount
            ? _value.remainingAmount
            : remainingAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        paidAmount: null == paidAmount
            ? _value.paidAmount
            : paidAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        paymentStatus: null == paymentStatus
            ? _value.paymentStatus
            : paymentStatus // ignore: cast_nullable_to_non_nullable
                  as String,
        paymentMethod: null == paymentMethod
            ? _value.paymentMethod
            : paymentMethod // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        ownerEmail: freezed == ownerEmail
            ? _value.ownerEmail
            : ownerEmail // ignore: cast_nullable_to_non_nullable
                  as String?,
        ownerPhone: freezed == ownerPhone
            ? _value.ownerPhone
            : ownerPhone // ignore: cast_nullable_to_non_nullable
                  as String?,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as String?,
        paymentDeadline: freezed == paymentDeadline
            ? _value.paymentDeadline
            : paymentDeadline // ignore: cast_nullable_to_non_nullable
                  as String?,
        bankDetails: freezed == bankDetails
            ? _value.bankDetails
            : bankDetails // ignore: cast_nullable_to_non_nullable
                  as BankDetails?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$BookingDetailsModelImpl implements _BookingDetailsModel {
  const _$BookingDetailsModelImpl({
    required this.bookingId,
    required this.bookingReference,
    this.propertyId,
    this.unitId,
    required this.propertyName,
    required this.unitName,
    required this.guestName,
    required this.guestEmail,
    this.guestPhone,
    required this.checkIn,
    required this.checkOut,
    required this.nights,
    required this.guestCount,
    required this.totalPrice,
    required this.depositAmount,
    required this.remainingAmount,
    required this.paidAmount,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.status,
    this.ownerEmail,
    this.ownerPhone,
    this.notes,
    this.createdAt,
    this.paymentDeadline,
    this.bankDetails,
  });

  factory _$BookingDetailsModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$BookingDetailsModelImplFromJson(json);

  @override
  final String bookingId;
  @override
  final String bookingReference;
  @override
  final String? propertyId;
  // Property ID for fetching widget settings
  @override
  final String? unitId;
  // Unit ID for fetching widget settings
  @override
  final String propertyName;
  @override
  final String unitName;
  @override
  final String guestName;
  @override
  final String guestEmail;
  @override
  final String? guestPhone;
  @override
  final String checkIn;
  // ISO 8601 string
  @override
  final String checkOut;
  // ISO 8601 string
  @override
  final int nights;
  @override
  final GuestCount guestCount;
  @override
  final double totalPrice;
  @override
  final double depositAmount;
  @override
  final double remainingAmount;
  @override
  final double paidAmount;
  @override
  final String paymentStatus;
  @override
  final String paymentMethod;
  @override
  final String status;
  @override
  final String? ownerEmail;
  @override
  final String? ownerPhone;
  @override
  final String? notes;
  @override
  final String? createdAt;
  // ISO 8601 string
  @override
  final String? paymentDeadline;
  // ISO 8601 string
  @override
  final BankDetails? bankDetails;

  @override
  String toString() {
    return 'BookingDetailsModel(bookingId: $bookingId, bookingReference: $bookingReference, propertyId: $propertyId, unitId: $unitId, propertyName: $propertyName, unitName: $unitName, guestName: $guestName, guestEmail: $guestEmail, guestPhone: $guestPhone, checkIn: $checkIn, checkOut: $checkOut, nights: $nights, guestCount: $guestCount, totalPrice: $totalPrice, depositAmount: $depositAmount, remainingAmount: $remainingAmount, paidAmount: $paidAmount, paymentStatus: $paymentStatus, paymentMethod: $paymentMethod, status: $status, ownerEmail: $ownerEmail, ownerPhone: $ownerPhone, notes: $notes, createdAt: $createdAt, paymentDeadline: $paymentDeadline, bankDetails: $bankDetails)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BookingDetailsModelImpl &&
            (identical(other.bookingId, bookingId) ||
                other.bookingId == bookingId) &&
            (identical(other.bookingReference, bookingReference) ||
                other.bookingReference == bookingReference) &&
            (identical(other.propertyId, propertyId) ||
                other.propertyId == propertyId) &&
            (identical(other.unitId, unitId) || other.unitId == unitId) &&
            (identical(other.propertyName, propertyName) ||
                other.propertyName == propertyName) &&
            (identical(other.unitName, unitName) ||
                other.unitName == unitName) &&
            (identical(other.guestName, guestName) ||
                other.guestName == guestName) &&
            (identical(other.guestEmail, guestEmail) ||
                other.guestEmail == guestEmail) &&
            (identical(other.guestPhone, guestPhone) ||
                other.guestPhone == guestPhone) &&
            (identical(other.checkIn, checkIn) || other.checkIn == checkIn) &&
            (identical(other.checkOut, checkOut) ||
                other.checkOut == checkOut) &&
            (identical(other.nights, nights) || other.nights == nights) &&
            (identical(other.guestCount, guestCount) ||
                other.guestCount == guestCount) &&
            (identical(other.totalPrice, totalPrice) ||
                other.totalPrice == totalPrice) &&
            (identical(other.depositAmount, depositAmount) ||
                other.depositAmount == depositAmount) &&
            (identical(other.remainingAmount, remainingAmount) ||
                other.remainingAmount == remainingAmount) &&
            (identical(other.paidAmount, paidAmount) ||
                other.paidAmount == paidAmount) &&
            (identical(other.paymentStatus, paymentStatus) ||
                other.paymentStatus == paymentStatus) &&
            (identical(other.paymentMethod, paymentMethod) ||
                other.paymentMethod == paymentMethod) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.ownerEmail, ownerEmail) ||
                other.ownerEmail == ownerEmail) &&
            (identical(other.ownerPhone, ownerPhone) ||
                other.ownerPhone == ownerPhone) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.paymentDeadline, paymentDeadline) ||
                other.paymentDeadline == paymentDeadline) &&
            (identical(other.bankDetails, bankDetails) ||
                other.bankDetails == bankDetails));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    bookingId,
    bookingReference,
    propertyId,
    unitId,
    propertyName,
    unitName,
    guestName,
    guestEmail,
    guestPhone,
    checkIn,
    checkOut,
    nights,
    guestCount,
    totalPrice,
    depositAmount,
    remainingAmount,
    paidAmount,
    paymentStatus,
    paymentMethod,
    status,
    ownerEmail,
    ownerPhone,
    notes,
    createdAt,
    paymentDeadline,
    bankDetails,
  ]);

  /// Create a copy of BookingDetailsModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BookingDetailsModelImplCopyWith<_$BookingDetailsModelImpl> get copyWith =>
      __$$BookingDetailsModelImplCopyWithImpl<_$BookingDetailsModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$BookingDetailsModelImplToJson(this);
  }
}

abstract class _BookingDetailsModel implements BookingDetailsModel {
  const factory _BookingDetailsModel({
    required final String bookingId,
    required final String bookingReference,
    final String? propertyId,
    final String? unitId,
    required final String propertyName,
    required final String unitName,
    required final String guestName,
    required final String guestEmail,
    final String? guestPhone,
    required final String checkIn,
    required final String checkOut,
    required final int nights,
    required final GuestCount guestCount,
    required final double totalPrice,
    required final double depositAmount,
    required final double remainingAmount,
    required final double paidAmount,
    required final String paymentStatus,
    required final String paymentMethod,
    required final String status,
    final String? ownerEmail,
    final String? ownerPhone,
    final String? notes,
    final String? createdAt,
    final String? paymentDeadline,
    final BankDetails? bankDetails,
  }) = _$BookingDetailsModelImpl;

  factory _BookingDetailsModel.fromJson(Map<String, dynamic> json) =
      _$BookingDetailsModelImpl.fromJson;

  @override
  String get bookingId;
  @override
  String get bookingReference;
  @override
  String? get propertyId; // Property ID for fetching widget settings
  @override
  String? get unitId; // Unit ID for fetching widget settings
  @override
  String get propertyName;
  @override
  String get unitName;
  @override
  String get guestName;
  @override
  String get guestEmail;
  @override
  String? get guestPhone;
  @override
  String get checkIn; // ISO 8601 string
  @override
  String get checkOut; // ISO 8601 string
  @override
  int get nights;
  @override
  GuestCount get guestCount;
  @override
  double get totalPrice;
  @override
  double get depositAmount;
  @override
  double get remainingAmount;
  @override
  double get paidAmount;
  @override
  String get paymentStatus;
  @override
  String get paymentMethod;
  @override
  String get status;
  @override
  String? get ownerEmail;
  @override
  String? get ownerPhone;
  @override
  String? get notes;
  @override
  String? get createdAt; // ISO 8601 string
  @override
  String? get paymentDeadline; // ISO 8601 string
  @override
  BankDetails? get bankDetails;

  /// Create a copy of BookingDetailsModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BookingDetailsModelImplCopyWith<_$BookingDetailsModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

BookingLookupResponse _$BookingLookupResponseFromJson(
  Map<String, dynamic> json,
) {
  return _BookingLookupResponse.fromJson(json);
}

/// @nodoc
mixin _$BookingLookupResponse {
  bool get success => throw _privateConstructorUsedError;
  BookingDetailsModel get booking => throw _privateConstructorUsedError;

  /// Serializes this BookingLookupResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BookingLookupResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BookingLookupResponseCopyWith<BookingLookupResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BookingLookupResponseCopyWith<$Res> {
  factory $BookingLookupResponseCopyWith(
    BookingLookupResponse value,
    $Res Function(BookingLookupResponse) then,
  ) = _$BookingLookupResponseCopyWithImpl<$Res, BookingLookupResponse>;
  @useResult
  $Res call({bool success, BookingDetailsModel booking});

  $BookingDetailsModelCopyWith<$Res> get booking;
}

/// @nodoc
class _$BookingLookupResponseCopyWithImpl<
  $Res,
  $Val extends BookingLookupResponse
>
    implements $BookingLookupResponseCopyWith<$Res> {
  _$BookingLookupResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BookingLookupResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? success = null, Object? booking = null}) {
    return _then(
      _value.copyWith(
            success: null == success
                ? _value.success
                : success // ignore: cast_nullable_to_non_nullable
                      as bool,
            booking: null == booking
                ? _value.booking
                : booking // ignore: cast_nullable_to_non_nullable
                      as BookingDetailsModel,
          )
          as $Val,
    );
  }

  /// Create a copy of BookingLookupResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BookingDetailsModelCopyWith<$Res> get booking {
    return $BookingDetailsModelCopyWith<$Res>(_value.booking, (value) {
      return _then(_value.copyWith(booking: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$BookingLookupResponseImplCopyWith<$Res>
    implements $BookingLookupResponseCopyWith<$Res> {
  factory _$$BookingLookupResponseImplCopyWith(
    _$BookingLookupResponseImpl value,
    $Res Function(_$BookingLookupResponseImpl) then,
  ) = __$$BookingLookupResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool success, BookingDetailsModel booking});

  @override
  $BookingDetailsModelCopyWith<$Res> get booking;
}

/// @nodoc
class __$$BookingLookupResponseImplCopyWithImpl<$Res>
    extends
        _$BookingLookupResponseCopyWithImpl<$Res, _$BookingLookupResponseImpl>
    implements _$$BookingLookupResponseImplCopyWith<$Res> {
  __$$BookingLookupResponseImplCopyWithImpl(
    _$BookingLookupResponseImpl _value,
    $Res Function(_$BookingLookupResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BookingLookupResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? success = null, Object? booking = null}) {
    return _then(
      _$BookingLookupResponseImpl(
        success: null == success
            ? _value.success
            : success // ignore: cast_nullable_to_non_nullable
                  as bool,
        booking: null == booking
            ? _value.booking
            : booking // ignore: cast_nullable_to_non_nullable
                  as BookingDetailsModel,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$BookingLookupResponseImpl implements _BookingLookupResponse {
  const _$BookingLookupResponseImpl({
    required this.success,
    required this.booking,
  });

  factory _$BookingLookupResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$BookingLookupResponseImplFromJson(json);

  @override
  final bool success;
  @override
  final BookingDetailsModel booking;

  @override
  String toString() {
    return 'BookingLookupResponse(success: $success, booking: $booking)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BookingLookupResponseImpl &&
            (identical(other.success, success) || other.success == success) &&
            (identical(other.booking, booking) || other.booking == booking));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, success, booking);

  /// Create a copy of BookingLookupResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BookingLookupResponseImplCopyWith<_$BookingLookupResponseImpl>
  get copyWith =>
      __$$BookingLookupResponseImplCopyWithImpl<_$BookingLookupResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$BookingLookupResponseImplToJson(this);
  }
}

abstract class _BookingLookupResponse implements BookingLookupResponse {
  const factory _BookingLookupResponse({
    required final bool success,
    required final BookingDetailsModel booking,
  }) = _$BookingLookupResponseImpl;

  factory _BookingLookupResponse.fromJson(Map<String, dynamic> json) =
      _$BookingLookupResponseImpl.fromJson;

  @override
  bool get success;
  @override
  BookingDetailsModel get booking;

  /// Create a copy of BookingLookupResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BookingLookupResponseImplCopyWith<_$BookingLookupResponseImpl>
  get copyWith => throw _privateConstructorUsedError;
}
