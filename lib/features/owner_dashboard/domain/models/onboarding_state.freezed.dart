// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'onboarding_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

OnboardingState _$OnboardingStateFromJson(Map<String, dynamic> json) {
  return _OnboardingState.fromJson(json);
}

/// @nodoc
mixin _$OnboardingState {
  int get currentStep => throw _privateConstructorUsedError;
  List<int> get completedSteps => throw _privateConstructorUsedError;
  PropertyFormData? get propertyData => throw _privateConstructorUsedError;
  UnitFormData? get unitData => throw _privateConstructorUsedError;
  PricingFormData? get pricingData => throw _privateConstructorUsedError;
  bool get isSkipped => throw _privateConstructorUsedError;
  bool get isCompleted => throw _privateConstructorUsedError;

  /// Serializes this OnboardingState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OnboardingState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OnboardingStateCopyWith<OnboardingState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OnboardingStateCopyWith<$Res> {
  factory $OnboardingStateCopyWith(
    OnboardingState value,
    $Res Function(OnboardingState) then,
  ) = _$OnboardingStateCopyWithImpl<$Res, OnboardingState>;
  @useResult
  $Res call({
    int currentStep,
    List<int> completedSteps,
    PropertyFormData? propertyData,
    UnitFormData? unitData,
    PricingFormData? pricingData,
    bool isSkipped,
    bool isCompleted,
  });

  $PropertyFormDataCopyWith<$Res>? get propertyData;
  $UnitFormDataCopyWith<$Res>? get unitData;
  $PricingFormDataCopyWith<$Res>? get pricingData;
}

/// @nodoc
class _$OnboardingStateCopyWithImpl<$Res, $Val extends OnboardingState>
    implements $OnboardingStateCopyWith<$Res> {
  _$OnboardingStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OnboardingState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentStep = null,
    Object? completedSteps = null,
    Object? propertyData = freezed,
    Object? unitData = freezed,
    Object? pricingData = freezed,
    Object? isSkipped = null,
    Object? isCompleted = null,
  }) {
    return _then(
      _value.copyWith(
            currentStep: null == currentStep
                ? _value.currentStep
                : currentStep // ignore: cast_nullable_to_non_nullable
                      as int,
            completedSteps: null == completedSteps
                ? _value.completedSteps
                : completedSteps // ignore: cast_nullable_to_non_nullable
                      as List<int>,
            propertyData: freezed == propertyData
                ? _value.propertyData
                : propertyData // ignore: cast_nullable_to_non_nullable
                      as PropertyFormData?,
            unitData: freezed == unitData
                ? _value.unitData
                : unitData // ignore: cast_nullable_to_non_nullable
                      as UnitFormData?,
            pricingData: freezed == pricingData
                ? _value.pricingData
                : pricingData // ignore: cast_nullable_to_non_nullable
                      as PricingFormData?,
            isSkipped: null == isSkipped
                ? _value.isSkipped
                : isSkipped // ignore: cast_nullable_to_non_nullable
                      as bool,
            isCompleted: null == isCompleted
                ? _value.isCompleted
                : isCompleted // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }

  /// Create a copy of OnboardingState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PropertyFormDataCopyWith<$Res>? get propertyData {
    if (_value.propertyData == null) {
      return null;
    }

    return $PropertyFormDataCopyWith<$Res>(_value.propertyData!, (value) {
      return _then(_value.copyWith(propertyData: value) as $Val);
    });
  }

  /// Create a copy of OnboardingState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UnitFormDataCopyWith<$Res>? get unitData {
    if (_value.unitData == null) {
      return null;
    }

    return $UnitFormDataCopyWith<$Res>(_value.unitData!, (value) {
      return _then(_value.copyWith(unitData: value) as $Val);
    });
  }

  /// Create a copy of OnboardingState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PricingFormDataCopyWith<$Res>? get pricingData {
    if (_value.pricingData == null) {
      return null;
    }

    return $PricingFormDataCopyWith<$Res>(_value.pricingData!, (value) {
      return _then(_value.copyWith(pricingData: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$OnboardingStateImplCopyWith<$Res>
    implements $OnboardingStateCopyWith<$Res> {
  factory _$$OnboardingStateImplCopyWith(
    _$OnboardingStateImpl value,
    $Res Function(_$OnboardingStateImpl) then,
  ) = __$$OnboardingStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int currentStep,
    List<int> completedSteps,
    PropertyFormData? propertyData,
    UnitFormData? unitData,
    PricingFormData? pricingData,
    bool isSkipped,
    bool isCompleted,
  });

  @override
  $PropertyFormDataCopyWith<$Res>? get propertyData;
  @override
  $UnitFormDataCopyWith<$Res>? get unitData;
  @override
  $PricingFormDataCopyWith<$Res>? get pricingData;
}

/// @nodoc
class __$$OnboardingStateImplCopyWithImpl<$Res>
    extends _$OnboardingStateCopyWithImpl<$Res, _$OnboardingStateImpl>
    implements _$$OnboardingStateImplCopyWith<$Res> {
  __$$OnboardingStateImplCopyWithImpl(
    _$OnboardingStateImpl _value,
    $Res Function(_$OnboardingStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OnboardingState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentStep = null,
    Object? completedSteps = null,
    Object? propertyData = freezed,
    Object? unitData = freezed,
    Object? pricingData = freezed,
    Object? isSkipped = null,
    Object? isCompleted = null,
  }) {
    return _then(
      _$OnboardingStateImpl(
        currentStep: null == currentStep
            ? _value.currentStep
            : currentStep // ignore: cast_nullable_to_non_nullable
                  as int,
        completedSteps: null == completedSteps
            ? _value._completedSteps
            : completedSteps // ignore: cast_nullable_to_non_nullable
                  as List<int>,
        propertyData: freezed == propertyData
            ? _value.propertyData
            : propertyData // ignore: cast_nullable_to_non_nullable
                  as PropertyFormData?,
        unitData: freezed == unitData
            ? _value.unitData
            : unitData // ignore: cast_nullable_to_non_nullable
                  as UnitFormData?,
        pricingData: freezed == pricingData
            ? _value.pricingData
            : pricingData // ignore: cast_nullable_to_non_nullable
                  as PricingFormData?,
        isSkipped: null == isSkipped
            ? _value.isSkipped
            : isSkipped // ignore: cast_nullable_to_non_nullable
                  as bool,
        isCompleted: null == isCompleted
            ? _value.isCompleted
            : isCompleted // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$OnboardingStateImpl implements _OnboardingState {
  const _$OnboardingStateImpl({
    this.currentStep = 0,
    final List<int> completedSteps = const [],
    this.propertyData,
    this.unitData,
    this.pricingData,
    this.isSkipped = false,
    this.isCompleted = false,
  }) : _completedSteps = completedSteps;

  factory _$OnboardingStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$OnboardingStateImplFromJson(json);

  @override
  @JsonKey()
  final int currentStep;
  final List<int> _completedSteps;
  @override
  @JsonKey()
  List<int> get completedSteps {
    if (_completedSteps is EqualUnmodifiableListView) return _completedSteps;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_completedSteps);
  }

  @override
  final PropertyFormData? propertyData;
  @override
  final UnitFormData? unitData;
  @override
  final PricingFormData? pricingData;
  @override
  @JsonKey()
  final bool isSkipped;
  @override
  @JsonKey()
  final bool isCompleted;

  @override
  String toString() {
    return 'OnboardingState(currentStep: $currentStep, completedSteps: $completedSteps, propertyData: $propertyData, unitData: $unitData, pricingData: $pricingData, isSkipped: $isSkipped, isCompleted: $isCompleted)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OnboardingStateImpl &&
            (identical(other.currentStep, currentStep) ||
                other.currentStep == currentStep) &&
            const DeepCollectionEquality().equals(
              other._completedSteps,
              _completedSteps,
            ) &&
            (identical(other.propertyData, propertyData) ||
                other.propertyData == propertyData) &&
            (identical(other.unitData, unitData) ||
                other.unitData == unitData) &&
            (identical(other.pricingData, pricingData) ||
                other.pricingData == pricingData) &&
            (identical(other.isSkipped, isSkipped) ||
                other.isSkipped == isSkipped) &&
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    currentStep,
    const DeepCollectionEquality().hash(_completedSteps),
    propertyData,
    unitData,
    pricingData,
    isSkipped,
    isCompleted,
  );

  /// Create a copy of OnboardingState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OnboardingStateImplCopyWith<_$OnboardingStateImpl> get copyWith =>
      __$$OnboardingStateImplCopyWithImpl<_$OnboardingStateImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$OnboardingStateImplToJson(this);
  }
}

abstract class _OnboardingState implements OnboardingState {
  const factory _OnboardingState({
    final int currentStep,
    final List<int> completedSteps,
    final PropertyFormData? propertyData,
    final UnitFormData? unitData,
    final PricingFormData? pricingData,
    final bool isSkipped,
    final bool isCompleted,
  }) = _$OnboardingStateImpl;

  factory _OnboardingState.fromJson(Map<String, dynamic> json) =
      _$OnboardingStateImpl.fromJson;

  @override
  int get currentStep;
  @override
  List<int> get completedSteps;
  @override
  PropertyFormData? get propertyData;
  @override
  UnitFormData? get unitData;
  @override
  PricingFormData? get pricingData;
  @override
  bool get isSkipped;
  @override
  bool get isCompleted;

  /// Create a copy of OnboardingState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OnboardingStateImplCopyWith<_$OnboardingStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PropertyFormData _$PropertyFormDataFromJson(Map<String, dynamic> json) {
  return _PropertyFormData.fromJson(json);
}

/// @nodoc
mixin _$PropertyFormData {
  String get name => throw _privateConstructorUsedError;
  String get propertyType => throw _privateConstructorUsedError;
  String get address => throw _privateConstructorUsedError;
  String get city => throw _privateConstructorUsedError;
  String get country => throw _privateConstructorUsedError;
  String? get phone => throw _privateConstructorUsedError;
  String? get email => throw _privateConstructorUsedError;
  String? get website => throw _privateConstructorUsedError;

  /// Serializes this PropertyFormData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PropertyFormData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PropertyFormDataCopyWith<PropertyFormData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PropertyFormDataCopyWith<$Res> {
  factory $PropertyFormDataCopyWith(
    PropertyFormData value,
    $Res Function(PropertyFormData) then,
  ) = _$PropertyFormDataCopyWithImpl<$Res, PropertyFormData>;
  @useResult
  $Res call({
    String name,
    String propertyType,
    String address,
    String city,
    String country,
    String? phone,
    String? email,
    String? website,
  });
}

/// @nodoc
class _$PropertyFormDataCopyWithImpl<$Res, $Val extends PropertyFormData>
    implements $PropertyFormDataCopyWith<$Res> {
  _$PropertyFormDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PropertyFormData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? propertyType = null,
    Object? address = null,
    Object? city = null,
    Object? country = null,
    Object? phone = freezed,
    Object? email = freezed,
    Object? website = freezed,
  }) {
    return _then(
      _value.copyWith(
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            propertyType: null == propertyType
                ? _value.propertyType
                : propertyType // ignore: cast_nullable_to_non_nullable
                      as String,
            address: null == address
                ? _value.address
                : address // ignore: cast_nullable_to_non_nullable
                      as String,
            city: null == city
                ? _value.city
                : city // ignore: cast_nullable_to_non_nullable
                      as String,
            country: null == country
                ? _value.country
                : country // ignore: cast_nullable_to_non_nullable
                      as String,
            phone: freezed == phone
                ? _value.phone
                : phone // ignore: cast_nullable_to_non_nullable
                      as String?,
            email: freezed == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String?,
            website: freezed == website
                ? _value.website
                : website // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PropertyFormDataImplCopyWith<$Res>
    implements $PropertyFormDataCopyWith<$Res> {
  factory _$$PropertyFormDataImplCopyWith(
    _$PropertyFormDataImpl value,
    $Res Function(_$PropertyFormDataImpl) then,
  ) = __$$PropertyFormDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String name,
    String propertyType,
    String address,
    String city,
    String country,
    String? phone,
    String? email,
    String? website,
  });
}

/// @nodoc
class __$$PropertyFormDataImplCopyWithImpl<$Res>
    extends _$PropertyFormDataCopyWithImpl<$Res, _$PropertyFormDataImpl>
    implements _$$PropertyFormDataImplCopyWith<$Res> {
  __$$PropertyFormDataImplCopyWithImpl(
    _$PropertyFormDataImpl _value,
    $Res Function(_$PropertyFormDataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PropertyFormData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? propertyType = null,
    Object? address = null,
    Object? city = null,
    Object? country = null,
    Object? phone = freezed,
    Object? email = freezed,
    Object? website = freezed,
  }) {
    return _then(
      _$PropertyFormDataImpl(
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        propertyType: null == propertyType
            ? _value.propertyType
            : propertyType // ignore: cast_nullable_to_non_nullable
                  as String,
        address: null == address
            ? _value.address
            : address // ignore: cast_nullable_to_non_nullable
                  as String,
        city: null == city
            ? _value.city
            : city // ignore: cast_nullable_to_non_nullable
                  as String,
        country: null == country
            ? _value.country
            : country // ignore: cast_nullable_to_non_nullable
                  as String,
        phone: freezed == phone
            ? _value.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String?,
        email: freezed == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String?,
        website: freezed == website
            ? _value.website
            : website // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PropertyFormDataImpl implements _PropertyFormData {
  const _$PropertyFormDataImpl({
    required this.name,
    required this.propertyType,
    required this.address,
    required this.city,
    required this.country,
    this.phone,
    this.email,
    this.website,
  });

  factory _$PropertyFormDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$PropertyFormDataImplFromJson(json);

  @override
  final String name;
  @override
  final String propertyType;
  @override
  final String address;
  @override
  final String city;
  @override
  final String country;
  @override
  final String? phone;
  @override
  final String? email;
  @override
  final String? website;

  @override
  String toString() {
    return 'PropertyFormData(name: $name, propertyType: $propertyType, address: $address, city: $city, country: $country, phone: $phone, email: $email, website: $website)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PropertyFormDataImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.propertyType, propertyType) ||
                other.propertyType == propertyType) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.country, country) || other.country == country) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.website, website) || other.website == website));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    name,
    propertyType,
    address,
    city,
    country,
    phone,
    email,
    website,
  );

  /// Create a copy of PropertyFormData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PropertyFormDataImplCopyWith<_$PropertyFormDataImpl> get copyWith =>
      __$$PropertyFormDataImplCopyWithImpl<_$PropertyFormDataImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PropertyFormDataImplToJson(this);
  }
}

abstract class _PropertyFormData implements PropertyFormData {
  const factory _PropertyFormData({
    required final String name,
    required final String propertyType,
    required final String address,
    required final String city,
    required final String country,
    final String? phone,
    final String? email,
    final String? website,
  }) = _$PropertyFormDataImpl;

  factory _PropertyFormData.fromJson(Map<String, dynamic> json) =
      _$PropertyFormDataImpl.fromJson;

  @override
  String get name;
  @override
  String get propertyType;
  @override
  String get address;
  @override
  String get city;
  @override
  String get country;
  @override
  String? get phone;
  @override
  String? get email;
  @override
  String? get website;

  /// Create a copy of PropertyFormData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PropertyFormDataImplCopyWith<_$PropertyFormDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UnitFormData _$UnitFormDataFromJson(Map<String, dynamic> json) {
  return _UnitFormData.fromJson(json);
}

/// @nodoc
mixin _$UnitFormData {
  String get name => throw _privateConstructorUsedError;
  String get unitType => throw _privateConstructorUsedError;
  int get maxGuests => throw _privateConstructorUsedError;
  int? get numBeds => throw _privateConstructorUsedError;
  int? get numBathrooms => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;

  /// Serializes this UnitFormData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UnitFormData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UnitFormDataCopyWith<UnitFormData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UnitFormDataCopyWith<$Res> {
  factory $UnitFormDataCopyWith(
    UnitFormData value,
    $Res Function(UnitFormData) then,
  ) = _$UnitFormDataCopyWithImpl<$Res, UnitFormData>;
  @useResult
  $Res call({
    String name,
    String unitType,
    int maxGuests,
    int? numBeds,
    int? numBathrooms,
    String? description,
  });
}

/// @nodoc
class _$UnitFormDataCopyWithImpl<$Res, $Val extends UnitFormData>
    implements $UnitFormDataCopyWith<$Res> {
  _$UnitFormDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UnitFormData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? unitType = null,
    Object? maxGuests = null,
    Object? numBeds = freezed,
    Object? numBathrooms = freezed,
    Object? description = freezed,
  }) {
    return _then(
      _value.copyWith(
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            unitType: null == unitType
                ? _value.unitType
                : unitType // ignore: cast_nullable_to_non_nullable
                      as String,
            maxGuests: null == maxGuests
                ? _value.maxGuests
                : maxGuests // ignore: cast_nullable_to_non_nullable
                      as int,
            numBeds: freezed == numBeds
                ? _value.numBeds
                : numBeds // ignore: cast_nullable_to_non_nullable
                      as int?,
            numBathrooms: freezed == numBathrooms
                ? _value.numBathrooms
                : numBathrooms // ignore: cast_nullable_to_non_nullable
                      as int?,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UnitFormDataImplCopyWith<$Res>
    implements $UnitFormDataCopyWith<$Res> {
  factory _$$UnitFormDataImplCopyWith(
    _$UnitFormDataImpl value,
    $Res Function(_$UnitFormDataImpl) then,
  ) = __$$UnitFormDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String name,
    String unitType,
    int maxGuests,
    int? numBeds,
    int? numBathrooms,
    String? description,
  });
}

/// @nodoc
class __$$UnitFormDataImplCopyWithImpl<$Res>
    extends _$UnitFormDataCopyWithImpl<$Res, _$UnitFormDataImpl>
    implements _$$UnitFormDataImplCopyWith<$Res> {
  __$$UnitFormDataImplCopyWithImpl(
    _$UnitFormDataImpl _value,
    $Res Function(_$UnitFormDataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UnitFormData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? unitType = null,
    Object? maxGuests = null,
    Object? numBeds = freezed,
    Object? numBathrooms = freezed,
    Object? description = freezed,
  }) {
    return _then(
      _$UnitFormDataImpl(
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        unitType: null == unitType
            ? _value.unitType
            : unitType // ignore: cast_nullable_to_non_nullable
                  as String,
        maxGuests: null == maxGuests
            ? _value.maxGuests
            : maxGuests // ignore: cast_nullable_to_non_nullable
                  as int,
        numBeds: freezed == numBeds
            ? _value.numBeds
            : numBeds // ignore: cast_nullable_to_non_nullable
                  as int?,
        numBathrooms: freezed == numBathrooms
            ? _value.numBathrooms
            : numBathrooms // ignore: cast_nullable_to_non_nullable
                  as int?,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UnitFormDataImpl implements _UnitFormData {
  const _$UnitFormDataImpl({
    required this.name,
    required this.unitType,
    required this.maxGuests,
    this.numBeds,
    this.numBathrooms,
    this.description,
  });

  factory _$UnitFormDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$UnitFormDataImplFromJson(json);

  @override
  final String name;
  @override
  final String unitType;
  @override
  final int maxGuests;
  @override
  final int? numBeds;
  @override
  final int? numBathrooms;
  @override
  final String? description;

  @override
  String toString() {
    return 'UnitFormData(name: $name, unitType: $unitType, maxGuests: $maxGuests, numBeds: $numBeds, numBathrooms: $numBathrooms, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UnitFormDataImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.unitType, unitType) ||
                other.unitType == unitType) &&
            (identical(other.maxGuests, maxGuests) ||
                other.maxGuests == maxGuests) &&
            (identical(other.numBeds, numBeds) || other.numBeds == numBeds) &&
            (identical(other.numBathrooms, numBathrooms) ||
                other.numBathrooms == numBathrooms) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    name,
    unitType,
    maxGuests,
    numBeds,
    numBathrooms,
    description,
  );

  /// Create a copy of UnitFormData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UnitFormDataImplCopyWith<_$UnitFormDataImpl> get copyWith =>
      __$$UnitFormDataImplCopyWithImpl<_$UnitFormDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UnitFormDataImplToJson(this);
  }
}

abstract class _UnitFormData implements UnitFormData {
  const factory _UnitFormData({
    required final String name,
    required final String unitType,
    required final int maxGuests,
    final int? numBeds,
    final int? numBathrooms,
    final String? description,
  }) = _$UnitFormDataImpl;

  factory _UnitFormData.fromJson(Map<String, dynamic> json) =
      _$UnitFormDataImpl.fromJson;

  @override
  String get name;
  @override
  String get unitType;
  @override
  int get maxGuests;
  @override
  int? get numBeds;
  @override
  int? get numBathrooms;
  @override
  String? get description;

  /// Create a copy of UnitFormData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UnitFormDataImplCopyWith<_$UnitFormDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PricingFormData _$PricingFormDataFromJson(Map<String, dynamic> json) {
  return _PricingFormData.fromJson(json);
}

/// @nodoc
mixin _$PricingFormData {
  double? get basePrice => throw _privateConstructorUsedError;
  String? get currency => throw _privateConstructorUsedError;

  /// Serializes this PricingFormData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PricingFormData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PricingFormDataCopyWith<PricingFormData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PricingFormDataCopyWith<$Res> {
  factory $PricingFormDataCopyWith(
    PricingFormData value,
    $Res Function(PricingFormData) then,
  ) = _$PricingFormDataCopyWithImpl<$Res, PricingFormData>;
  @useResult
  $Res call({double? basePrice, String? currency});
}

/// @nodoc
class _$PricingFormDataCopyWithImpl<$Res, $Val extends PricingFormData>
    implements $PricingFormDataCopyWith<$Res> {
  _$PricingFormDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PricingFormData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? basePrice = freezed, Object? currency = freezed}) {
    return _then(
      _value.copyWith(
            basePrice: freezed == basePrice
                ? _value.basePrice
                : basePrice // ignore: cast_nullable_to_non_nullable
                      as double?,
            currency: freezed == currency
                ? _value.currency
                : currency // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PricingFormDataImplCopyWith<$Res>
    implements $PricingFormDataCopyWith<$Res> {
  factory _$$PricingFormDataImplCopyWith(
    _$PricingFormDataImpl value,
    $Res Function(_$PricingFormDataImpl) then,
  ) = __$$PricingFormDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double? basePrice, String? currency});
}

/// @nodoc
class __$$PricingFormDataImplCopyWithImpl<$Res>
    extends _$PricingFormDataCopyWithImpl<$Res, _$PricingFormDataImpl>
    implements _$$PricingFormDataImplCopyWith<$Res> {
  __$$PricingFormDataImplCopyWithImpl(
    _$PricingFormDataImpl _value,
    $Res Function(_$PricingFormDataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PricingFormData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? basePrice = freezed, Object? currency = freezed}) {
    return _then(
      _$PricingFormDataImpl(
        basePrice: freezed == basePrice
            ? _value.basePrice
            : basePrice // ignore: cast_nullable_to_non_nullable
                  as double?,
        currency: freezed == currency
            ? _value.currency
            : currency // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PricingFormDataImpl implements _PricingFormData {
  const _$PricingFormDataImpl({this.basePrice, this.currency});

  factory _$PricingFormDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$PricingFormDataImplFromJson(json);

  @override
  final double? basePrice;
  @override
  final String? currency;

  @override
  String toString() {
    return 'PricingFormData(basePrice: $basePrice, currency: $currency)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PricingFormDataImpl &&
            (identical(other.basePrice, basePrice) ||
                other.basePrice == basePrice) &&
            (identical(other.currency, currency) ||
                other.currency == currency));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, basePrice, currency);

  /// Create a copy of PricingFormData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PricingFormDataImplCopyWith<_$PricingFormDataImpl> get copyWith =>
      __$$PricingFormDataImplCopyWithImpl<_$PricingFormDataImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PricingFormDataImplToJson(this);
  }
}

abstract class _PricingFormData implements PricingFormData {
  const factory _PricingFormData({
    final double? basePrice,
    final String? currency,
  }) = _$PricingFormDataImpl;

  factory _PricingFormData.fromJson(Map<String, dynamic> json) =
      _$PricingFormDataImpl.fromJson;

  @override
  double? get basePrice;
  @override
  String? get currency;

  /// Create a copy of PricingFormData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PricingFormDataImplCopyWith<_$PricingFormDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
