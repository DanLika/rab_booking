// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_profile_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Address _$AddressFromJson(Map<String, dynamic> json) {
  return _Address.fromJson(json);
}

/// @nodoc
mixin _$Address {
  String get country => throw _privateConstructorUsedError;
  String get city => throw _privateConstructorUsedError;
  String get street => throw _privateConstructorUsedError;
  String get postalCode => throw _privateConstructorUsedError;

  /// Serializes this Address to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Address
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AddressCopyWith<Address> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AddressCopyWith<$Res> {
  factory $AddressCopyWith(Address value, $Res Function(Address) then) =
      _$AddressCopyWithImpl<$Res, Address>;
  @useResult
  $Res call({String country, String city, String street, String postalCode});
}

/// @nodoc
class _$AddressCopyWithImpl<$Res, $Val extends Address>
    implements $AddressCopyWith<$Res> {
  _$AddressCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Address
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? country = null,
    Object? city = null,
    Object? street = null,
    Object? postalCode = null,
  }) {
    return _then(
      _value.copyWith(
            country: null == country
                ? _value.country
                : country // ignore: cast_nullable_to_non_nullable
                      as String,
            city: null == city
                ? _value.city
                : city // ignore: cast_nullable_to_non_nullable
                      as String,
            street: null == street
                ? _value.street
                : street // ignore: cast_nullable_to_non_nullable
                      as String,
            postalCode: null == postalCode
                ? _value.postalCode
                : postalCode // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AddressImplCopyWith<$Res> implements $AddressCopyWith<$Res> {
  factory _$$AddressImplCopyWith(
    _$AddressImpl value,
    $Res Function(_$AddressImpl) then,
  ) = __$$AddressImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String country, String city, String street, String postalCode});
}

/// @nodoc
class __$$AddressImplCopyWithImpl<$Res>
    extends _$AddressCopyWithImpl<$Res, _$AddressImpl>
    implements _$$AddressImplCopyWith<$Res> {
  __$$AddressImplCopyWithImpl(
    _$AddressImpl _value,
    $Res Function(_$AddressImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Address
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? country = null,
    Object? city = null,
    Object? street = null,
    Object? postalCode = null,
  }) {
    return _then(
      _$AddressImpl(
        country: null == country
            ? _value.country
            : country // ignore: cast_nullable_to_non_nullable
                  as String,
        city: null == city
            ? _value.city
            : city // ignore: cast_nullable_to_non_nullable
                  as String,
        street: null == street
            ? _value.street
            : street // ignore: cast_nullable_to_non_nullable
                  as String,
        postalCode: null == postalCode
            ? _value.postalCode
            : postalCode // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AddressImpl implements _Address {
  const _$AddressImpl({
    this.country = '',
    this.city = '',
    this.street = '',
    this.postalCode = '',
  });

  factory _$AddressImpl.fromJson(Map<String, dynamic> json) =>
      _$$AddressImplFromJson(json);

  @override
  @JsonKey()
  final String country;
  @override
  @JsonKey()
  final String city;
  @override
  @JsonKey()
  final String street;
  @override
  @JsonKey()
  final String postalCode;

  @override
  String toString() {
    return 'Address(country: $country, city: $city, street: $street, postalCode: $postalCode)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AddressImpl &&
            (identical(other.country, country) || other.country == country) &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.street, street) || other.street == street) &&
            (identical(other.postalCode, postalCode) ||
                other.postalCode == postalCode));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, country, city, street, postalCode);

  /// Create a copy of Address
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AddressImplCopyWith<_$AddressImpl> get copyWith =>
      __$$AddressImplCopyWithImpl<_$AddressImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AddressImplToJson(this);
  }
}

abstract class _Address implements Address {
  const factory _Address({
    final String country,
    final String city,
    final String street,
    final String postalCode,
  }) = _$AddressImpl;

  factory _Address.fromJson(Map<String, dynamic> json) = _$AddressImpl.fromJson;

  @override
  String get country;
  @override
  String get city;
  @override
  String get street;
  @override
  String get postalCode;

  /// Create a copy of Address
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AddressImplCopyWith<_$AddressImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SocialLinks _$SocialLinksFromJson(Map<String, dynamic> json) {
  return _SocialLinks.fromJson(json);
}

/// @nodoc
mixin _$SocialLinks {
  String get website => throw _privateConstructorUsedError;
  String get facebook => throw _privateConstructorUsedError;

  /// Serializes this SocialLinks to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SocialLinks
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SocialLinksCopyWith<SocialLinks> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SocialLinksCopyWith<$Res> {
  factory $SocialLinksCopyWith(
    SocialLinks value,
    $Res Function(SocialLinks) then,
  ) = _$SocialLinksCopyWithImpl<$Res, SocialLinks>;
  @useResult
  $Res call({String website, String facebook});
}

/// @nodoc
class _$SocialLinksCopyWithImpl<$Res, $Val extends SocialLinks>
    implements $SocialLinksCopyWith<$Res> {
  _$SocialLinksCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SocialLinks
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? website = null, Object? facebook = null}) {
    return _then(
      _value.copyWith(
            website: null == website
                ? _value.website
                : website // ignore: cast_nullable_to_non_nullable
                      as String,
            facebook: null == facebook
                ? _value.facebook
                : facebook // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SocialLinksImplCopyWith<$Res>
    implements $SocialLinksCopyWith<$Res> {
  factory _$$SocialLinksImplCopyWith(
    _$SocialLinksImpl value,
    $Res Function(_$SocialLinksImpl) then,
  ) = __$$SocialLinksImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String website, String facebook});
}

/// @nodoc
class __$$SocialLinksImplCopyWithImpl<$Res>
    extends _$SocialLinksCopyWithImpl<$Res, _$SocialLinksImpl>
    implements _$$SocialLinksImplCopyWith<$Res> {
  __$$SocialLinksImplCopyWithImpl(
    _$SocialLinksImpl _value,
    $Res Function(_$SocialLinksImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SocialLinks
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? website = null, Object? facebook = null}) {
    return _then(
      _$SocialLinksImpl(
        website: null == website
            ? _value.website
            : website // ignore: cast_nullable_to_non_nullable
                  as String,
        facebook: null == facebook
            ? _value.facebook
            : facebook // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SocialLinksImpl implements _SocialLinks {
  const _$SocialLinksImpl({this.website = '', this.facebook = ''});

  factory _$SocialLinksImpl.fromJson(Map<String, dynamic> json) =>
      _$$SocialLinksImplFromJson(json);

  @override
  @JsonKey()
  final String website;
  @override
  @JsonKey()
  final String facebook;

  @override
  String toString() {
    return 'SocialLinks(website: $website, facebook: $facebook)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SocialLinksImpl &&
            (identical(other.website, website) || other.website == website) &&
            (identical(other.facebook, facebook) ||
                other.facebook == facebook));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, website, facebook);

  /// Create a copy of SocialLinks
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SocialLinksImplCopyWith<_$SocialLinksImpl> get copyWith =>
      __$$SocialLinksImplCopyWithImpl<_$SocialLinksImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SocialLinksImplToJson(this);
  }
}

abstract class _SocialLinks implements SocialLinks {
  const factory _SocialLinks({final String website, final String facebook}) =
      _$SocialLinksImpl;

  factory _SocialLinks.fromJson(Map<String, dynamic> json) =
      _$SocialLinksImpl.fromJson;

  @override
  String get website;
  @override
  String get facebook;

  /// Create a copy of SocialLinks
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SocialLinksImplCopyWith<_$SocialLinksImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CompanyDetails _$CompanyDetailsFromJson(Map<String, dynamic> json) {
  return _CompanyDetails.fromJson(json);
}

/// @nodoc
mixin _$CompanyDetails {
  String get companyName => throw _privateConstructorUsedError;
  String get taxId => throw _privateConstructorUsedError;
  String get vatId => throw _privateConstructorUsedError;
  String get bankAccountIban => throw _privateConstructorUsedError;
  String get swift => throw _privateConstructorUsedError;
  String get bankName => throw _privateConstructorUsedError;
  String get accountHolder => throw _privateConstructorUsedError;
  Address get address => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this CompanyDetails to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CompanyDetails
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CompanyDetailsCopyWith<CompanyDetails> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CompanyDetailsCopyWith<$Res> {
  factory $CompanyDetailsCopyWith(
    CompanyDetails value,
    $Res Function(CompanyDetails) then,
  ) = _$CompanyDetailsCopyWithImpl<$Res, CompanyDetails>;
  @useResult
  $Res call({
    String companyName,
    String taxId,
    String vatId,
    String bankAccountIban,
    String swift,
    String bankName,
    String accountHolder,
    Address address,
    DateTime? updatedAt,
  });

  $AddressCopyWith<$Res> get address;
}

/// @nodoc
class _$CompanyDetailsCopyWithImpl<$Res, $Val extends CompanyDetails>
    implements $CompanyDetailsCopyWith<$Res> {
  _$CompanyDetailsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CompanyDetails
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? companyName = null,
    Object? taxId = null,
    Object? vatId = null,
    Object? bankAccountIban = null,
    Object? swift = null,
    Object? bankName = null,
    Object? accountHolder = null,
    Object? address = null,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            companyName: null == companyName
                ? _value.companyName
                : companyName // ignore: cast_nullable_to_non_nullable
                      as String,
            taxId: null == taxId
                ? _value.taxId
                : taxId // ignore: cast_nullable_to_non_nullable
                      as String,
            vatId: null == vatId
                ? _value.vatId
                : vatId // ignore: cast_nullable_to_non_nullable
                      as String,
            bankAccountIban: null == bankAccountIban
                ? _value.bankAccountIban
                : bankAccountIban // ignore: cast_nullable_to_non_nullable
                      as String,
            swift: null == swift
                ? _value.swift
                : swift // ignore: cast_nullable_to_non_nullable
                      as String,
            bankName: null == bankName
                ? _value.bankName
                : bankName // ignore: cast_nullable_to_non_nullable
                      as String,
            accountHolder: null == accountHolder
                ? _value.accountHolder
                : accountHolder // ignore: cast_nullable_to_non_nullable
                      as String,
            address: null == address
                ? _value.address
                : address // ignore: cast_nullable_to_non_nullable
                      as Address,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }

  /// Create a copy of CompanyDetails
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AddressCopyWith<$Res> get address {
    return $AddressCopyWith<$Res>(_value.address, (value) {
      return _then(_value.copyWith(address: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CompanyDetailsImplCopyWith<$Res>
    implements $CompanyDetailsCopyWith<$Res> {
  factory _$$CompanyDetailsImplCopyWith(
    _$CompanyDetailsImpl value,
    $Res Function(_$CompanyDetailsImpl) then,
  ) = __$$CompanyDetailsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String companyName,
    String taxId,
    String vatId,
    String bankAccountIban,
    String swift,
    String bankName,
    String accountHolder,
    Address address,
    DateTime? updatedAt,
  });

  @override
  $AddressCopyWith<$Res> get address;
}

/// @nodoc
class __$$CompanyDetailsImplCopyWithImpl<$Res>
    extends _$CompanyDetailsCopyWithImpl<$Res, _$CompanyDetailsImpl>
    implements _$$CompanyDetailsImplCopyWith<$Res> {
  __$$CompanyDetailsImplCopyWithImpl(
    _$CompanyDetailsImpl _value,
    $Res Function(_$CompanyDetailsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CompanyDetails
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? companyName = null,
    Object? taxId = null,
    Object? vatId = null,
    Object? bankAccountIban = null,
    Object? swift = null,
    Object? bankName = null,
    Object? accountHolder = null,
    Object? address = null,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$CompanyDetailsImpl(
        companyName: null == companyName
            ? _value.companyName
            : companyName // ignore: cast_nullable_to_non_nullable
                  as String,
        taxId: null == taxId
            ? _value.taxId
            : taxId // ignore: cast_nullable_to_non_nullable
                  as String,
        vatId: null == vatId
            ? _value.vatId
            : vatId // ignore: cast_nullable_to_non_nullable
                  as String,
        bankAccountIban: null == bankAccountIban
            ? _value.bankAccountIban
            : bankAccountIban // ignore: cast_nullable_to_non_nullable
                  as String,
        swift: null == swift
            ? _value.swift
            : swift // ignore: cast_nullable_to_non_nullable
                  as String,
        bankName: null == bankName
            ? _value.bankName
            : bankName // ignore: cast_nullable_to_non_nullable
                  as String,
        accountHolder: null == accountHolder
            ? _value.accountHolder
            : accountHolder // ignore: cast_nullable_to_non_nullable
                  as String,
        address: null == address
            ? _value.address
            : address // ignore: cast_nullable_to_non_nullable
                  as Address,
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
class _$CompanyDetailsImpl extends _CompanyDetails {
  const _$CompanyDetailsImpl({
    this.companyName = '',
    this.taxId = '',
    this.vatId = '',
    this.bankAccountIban = '',
    this.swift = '',
    this.bankName = '',
    this.accountHolder = '',
    this.address = const Address(),
    this.updatedAt,
  }) : super._();

  factory _$CompanyDetailsImpl.fromJson(Map<String, dynamic> json) =>
      _$$CompanyDetailsImplFromJson(json);

  @override
  @JsonKey()
  final String companyName;
  @override
  @JsonKey()
  final String taxId;
  @override
  @JsonKey()
  final String vatId;
  @override
  @JsonKey()
  final String bankAccountIban;
  @override
  @JsonKey()
  final String swift;
  @override
  @JsonKey()
  final String bankName;
  @override
  @JsonKey()
  final String accountHolder;
  @override
  @JsonKey()
  final Address address;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'CompanyDetails(companyName: $companyName, taxId: $taxId, vatId: $vatId, bankAccountIban: $bankAccountIban, swift: $swift, bankName: $bankName, accountHolder: $accountHolder, address: $address, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CompanyDetailsImpl &&
            (identical(other.companyName, companyName) ||
                other.companyName == companyName) &&
            (identical(other.taxId, taxId) || other.taxId == taxId) &&
            (identical(other.vatId, vatId) || other.vatId == vatId) &&
            (identical(other.bankAccountIban, bankAccountIban) ||
                other.bankAccountIban == bankAccountIban) &&
            (identical(other.swift, swift) || other.swift == swift) &&
            (identical(other.bankName, bankName) ||
                other.bankName == bankName) &&
            (identical(other.accountHolder, accountHolder) ||
                other.accountHolder == accountHolder) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    companyName,
    taxId,
    vatId,
    bankAccountIban,
    swift,
    bankName,
    accountHolder,
    address,
    updatedAt,
  );

  /// Create a copy of CompanyDetails
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CompanyDetailsImplCopyWith<_$CompanyDetailsImpl> get copyWith =>
      __$$CompanyDetailsImplCopyWithImpl<_$CompanyDetailsImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CompanyDetailsImplToJson(this);
  }
}

abstract class _CompanyDetails extends CompanyDetails {
  const factory _CompanyDetails({
    final String companyName,
    final String taxId,
    final String vatId,
    final String bankAccountIban,
    final String swift,
    final String bankName,
    final String accountHolder,
    final Address address,
    final DateTime? updatedAt,
  }) = _$CompanyDetailsImpl;
  const _CompanyDetails._() : super._();

  factory _CompanyDetails.fromJson(Map<String, dynamic> json) =
      _$CompanyDetailsImpl.fromJson;

  @override
  String get companyName;
  @override
  String get taxId;
  @override
  String get vatId;
  @override
  String get bankAccountIban;
  @override
  String get swift;
  @override
  String get bankName;
  @override
  String get accountHolder;
  @override
  Address get address;
  @override
  DateTime? get updatedAt;

  /// Create a copy of CompanyDetails
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CompanyDetailsImplCopyWith<_$CompanyDetailsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) {
  return _UserProfile.fromJson(json);
}

/// @nodoc
mixin _$UserProfile {
  String get userId => throw _privateConstructorUsedError;
  String get displayName => throw _privateConstructorUsedError;
  String get emailContact => throw _privateConstructorUsedError;
  String get phoneE164 =>
      throw _privateConstructorUsedError; // E.164 format: +385911234567
  Address get address => throw _privateConstructorUsedError;
  SocialLinks get social => throw _privateConstructorUsedError;
  String get propertyType => throw _privateConstructorUsedError;
  String get logoUrl => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this UserProfile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserProfileCopyWith<UserProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserProfileCopyWith<$Res> {
  factory $UserProfileCopyWith(
    UserProfile value,
    $Res Function(UserProfile) then,
  ) = _$UserProfileCopyWithImpl<$Res, UserProfile>;
  @useResult
  $Res call({
    String userId,
    String displayName,
    String emailContact,
    String phoneE164,
    Address address,
    SocialLinks social,
    String propertyType,
    String logoUrl,
    DateTime? updatedAt,
  });

  $AddressCopyWith<$Res> get address;
  $SocialLinksCopyWith<$Res> get social;
}

/// @nodoc
class _$UserProfileCopyWithImpl<$Res, $Val extends UserProfile>
    implements $UserProfileCopyWith<$Res> {
  _$UserProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? displayName = null,
    Object? emailContact = null,
    Object? phoneE164 = null,
    Object? address = null,
    Object? social = null,
    Object? propertyType = null,
    Object? logoUrl = null,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            displayName: null == displayName
                ? _value.displayName
                : displayName // ignore: cast_nullable_to_non_nullable
                      as String,
            emailContact: null == emailContact
                ? _value.emailContact
                : emailContact // ignore: cast_nullable_to_non_nullable
                      as String,
            phoneE164: null == phoneE164
                ? _value.phoneE164
                : phoneE164 // ignore: cast_nullable_to_non_nullable
                      as String,
            address: null == address
                ? _value.address
                : address // ignore: cast_nullable_to_non_nullable
                      as Address,
            social: null == social
                ? _value.social
                : social // ignore: cast_nullable_to_non_nullable
                      as SocialLinks,
            propertyType: null == propertyType
                ? _value.propertyType
                : propertyType // ignore: cast_nullable_to_non_nullable
                      as String,
            logoUrl: null == logoUrl
                ? _value.logoUrl
                : logoUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AddressCopyWith<$Res> get address {
    return $AddressCopyWith<$Res>(_value.address, (value) {
      return _then(_value.copyWith(address: value) as $Val);
    });
  }

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SocialLinksCopyWith<$Res> get social {
    return $SocialLinksCopyWith<$Res>(_value.social, (value) {
      return _then(_value.copyWith(social: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$UserProfileImplCopyWith<$Res>
    implements $UserProfileCopyWith<$Res> {
  factory _$$UserProfileImplCopyWith(
    _$UserProfileImpl value,
    $Res Function(_$UserProfileImpl) then,
  ) = __$$UserProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String userId,
    String displayName,
    String emailContact,
    String phoneE164,
    Address address,
    SocialLinks social,
    String propertyType,
    String logoUrl,
    DateTime? updatedAt,
  });

  @override
  $AddressCopyWith<$Res> get address;
  @override
  $SocialLinksCopyWith<$Res> get social;
}

/// @nodoc
class __$$UserProfileImplCopyWithImpl<$Res>
    extends _$UserProfileCopyWithImpl<$Res, _$UserProfileImpl>
    implements _$$UserProfileImplCopyWith<$Res> {
  __$$UserProfileImplCopyWithImpl(
    _$UserProfileImpl _value,
    $Res Function(_$UserProfileImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? displayName = null,
    Object? emailContact = null,
    Object? phoneE164 = null,
    Object? address = null,
    Object? social = null,
    Object? propertyType = null,
    Object? logoUrl = null,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$UserProfileImpl(
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        displayName: null == displayName
            ? _value.displayName
            : displayName // ignore: cast_nullable_to_non_nullable
                  as String,
        emailContact: null == emailContact
            ? _value.emailContact
            : emailContact // ignore: cast_nullable_to_non_nullable
                  as String,
        phoneE164: null == phoneE164
            ? _value.phoneE164
            : phoneE164 // ignore: cast_nullable_to_non_nullable
                  as String,
        address: null == address
            ? _value.address
            : address // ignore: cast_nullable_to_non_nullable
                  as Address,
        social: null == social
            ? _value.social
            : social // ignore: cast_nullable_to_non_nullable
                  as SocialLinks,
        propertyType: null == propertyType
            ? _value.propertyType
            : propertyType // ignore: cast_nullable_to_non_nullable
                  as String,
        logoUrl: null == logoUrl
            ? _value.logoUrl
            : logoUrl // ignore: cast_nullable_to_non_nullable
                  as String,
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
class _$UserProfileImpl extends _UserProfile {
  const _$UserProfileImpl({
    required this.userId,
    this.displayName = '',
    this.emailContact = '',
    this.phoneE164 = '',
    this.address = const Address(),
    this.social = const SocialLinks(),
    this.propertyType = '',
    this.logoUrl = '',
    this.updatedAt,
  }) : super._();

  factory _$UserProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserProfileImplFromJson(json);

  @override
  final String userId;
  @override
  @JsonKey()
  final String displayName;
  @override
  @JsonKey()
  final String emailContact;
  @override
  @JsonKey()
  final String phoneE164;
  // E.164 format: +385911234567
  @override
  @JsonKey()
  final Address address;
  @override
  @JsonKey()
  final SocialLinks social;
  @override
  @JsonKey()
  final String propertyType;
  @override
  @JsonKey()
  final String logoUrl;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'UserProfile(userId: $userId, displayName: $displayName, emailContact: $emailContact, phoneE164: $phoneE164, address: $address, social: $social, propertyType: $propertyType, logoUrl: $logoUrl, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserProfileImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.emailContact, emailContact) ||
                other.emailContact == emailContact) &&
            (identical(other.phoneE164, phoneE164) ||
                other.phoneE164 == phoneE164) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.social, social) || other.social == social) &&
            (identical(other.propertyType, propertyType) ||
                other.propertyType == propertyType) &&
            (identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    userId,
    displayName,
    emailContact,
    phoneE164,
    address,
    social,
    propertyType,
    logoUrl,
    updatedAt,
  );

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserProfileImplCopyWith<_$UserProfileImpl> get copyWith =>
      __$$UserProfileImplCopyWithImpl<_$UserProfileImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserProfileImplToJson(this);
  }
}

abstract class _UserProfile extends UserProfile {
  const factory _UserProfile({
    required final String userId,
    final String displayName,
    final String emailContact,
    final String phoneE164,
    final Address address,
    final SocialLinks social,
    final String propertyType,
    final String logoUrl,
    final DateTime? updatedAt,
  }) = _$UserProfileImpl;
  const _UserProfile._() : super._();

  factory _UserProfile.fromJson(Map<String, dynamic> json) =
      _$UserProfileImpl.fromJson;

  @override
  String get userId;
  @override
  String get displayName;
  @override
  String get emailContact;
  @override
  String get phoneE164; // E.164 format: +385911234567
  @override
  Address get address;
  @override
  SocialLinks get social;
  @override
  String get propertyType;
  @override
  String get logoUrl;
  @override
  DateTime? get updatedAt;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserProfileImplCopyWith<_$UserProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserData _$UserDataFromJson(Map<String, dynamic> json) {
  return _UserData.fromJson(json);
}

/// @nodoc
mixin _$UserData {
  UserProfile get profile => throw _privateConstructorUsedError;
  CompanyDetails get company => throw _privateConstructorUsedError;

  /// Serializes this UserData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserDataCopyWith<UserData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserDataCopyWith<$Res> {
  factory $UserDataCopyWith(UserData value, $Res Function(UserData) then) =
      _$UserDataCopyWithImpl<$Res, UserData>;
  @useResult
  $Res call({UserProfile profile, CompanyDetails company});

  $UserProfileCopyWith<$Res> get profile;
  $CompanyDetailsCopyWith<$Res> get company;
}

/// @nodoc
class _$UserDataCopyWithImpl<$Res, $Val extends UserData>
    implements $UserDataCopyWith<$Res> {
  _$UserDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? profile = null, Object? company = null}) {
    return _then(
      _value.copyWith(
            profile: null == profile
                ? _value.profile
                : profile // ignore: cast_nullable_to_non_nullable
                      as UserProfile,
            company: null == company
                ? _value.company
                : company // ignore: cast_nullable_to_non_nullable
                      as CompanyDetails,
          )
          as $Val,
    );
  }

  /// Create a copy of UserData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UserProfileCopyWith<$Res> get profile {
    return $UserProfileCopyWith<$Res>(_value.profile, (value) {
      return _then(_value.copyWith(profile: value) as $Val);
    });
  }

  /// Create a copy of UserData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CompanyDetailsCopyWith<$Res> get company {
    return $CompanyDetailsCopyWith<$Res>(_value.company, (value) {
      return _then(_value.copyWith(company: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$UserDataImplCopyWith<$Res>
    implements $UserDataCopyWith<$Res> {
  factory _$$UserDataImplCopyWith(
    _$UserDataImpl value,
    $Res Function(_$UserDataImpl) then,
  ) = __$$UserDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({UserProfile profile, CompanyDetails company});

  @override
  $UserProfileCopyWith<$Res> get profile;
  @override
  $CompanyDetailsCopyWith<$Res> get company;
}

/// @nodoc
class __$$UserDataImplCopyWithImpl<$Res>
    extends _$UserDataCopyWithImpl<$Res, _$UserDataImpl>
    implements _$$UserDataImplCopyWith<$Res> {
  __$$UserDataImplCopyWithImpl(
    _$UserDataImpl _value,
    $Res Function(_$UserDataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UserData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? profile = null, Object? company = null}) {
    return _then(
      _$UserDataImpl(
        profile: null == profile
            ? _value.profile
            : profile // ignore: cast_nullable_to_non_nullable
                  as UserProfile,
        company: null == company
            ? _value.company
            : company // ignore: cast_nullable_to_non_nullable
                  as CompanyDetails,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UserDataImpl implements _UserData {
  const _$UserDataImpl({
    required this.profile,
    this.company = const CompanyDetails(),
  });

  factory _$UserDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserDataImplFromJson(json);

  @override
  final UserProfile profile;
  @override
  @JsonKey()
  final CompanyDetails company;

  @override
  String toString() {
    return 'UserData(profile: $profile, company: $company)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserDataImpl &&
            (identical(other.profile, profile) || other.profile == profile) &&
            (identical(other.company, company) || other.company == company));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, profile, company);

  /// Create a copy of UserData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserDataImplCopyWith<_$UserDataImpl> get copyWith =>
      __$$UserDataImplCopyWithImpl<_$UserDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserDataImplToJson(this);
  }
}

abstract class _UserData implements UserData {
  const factory _UserData({
    required final UserProfile profile,
    final CompanyDetails company,
  }) = _$UserDataImpl;

  factory _UserData.fromJson(Map<String, dynamic> json) =
      _$UserDataImpl.fromJson;

  @override
  UserProfile get profile;
  @override
  CompanyDetails get company;

  /// Create a copy of UserData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserDataImplCopyWith<_$UserDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
