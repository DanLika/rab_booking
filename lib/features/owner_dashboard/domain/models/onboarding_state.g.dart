// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OnboardingStateImpl _$$OnboardingStateImplFromJson(
  Map<String, dynamic> json,
) => _$OnboardingStateImpl(
  currentStep: (json['currentStep'] as num?)?.toInt() ?? 0,
  completedSteps:
      (json['completedSteps'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const [],
  propertyData: json['propertyData'] == null
      ? null
      : PropertyFormData.fromJson(json['propertyData'] as Map<String, dynamic>),
  unitData: json['unitData'] == null
      ? null
      : UnitFormData.fromJson(json['unitData'] as Map<String, dynamic>),
  pricingData: json['pricingData'] == null
      ? null
      : PricingFormData.fromJson(json['pricingData'] as Map<String, dynamic>),
  isSkipped: json['isSkipped'] as bool? ?? false,
  isCompleted: json['isCompleted'] as bool? ?? false,
);

Map<String, dynamic> _$$OnboardingStateImplToJson(
  _$OnboardingStateImpl instance,
) => <String, dynamic>{
  'currentStep': instance.currentStep,
  'completedSteps': instance.completedSteps,
  'propertyData': instance.propertyData,
  'unitData': instance.unitData,
  'pricingData': instance.pricingData,
  'isSkipped': instance.isSkipped,
  'isCompleted': instance.isCompleted,
};

_$PropertyFormDataImpl _$$PropertyFormDataImplFromJson(
  Map<String, dynamic> json,
) => _$PropertyFormDataImpl(
  name: json['name'] as String,
  propertyType: json['propertyType'] as String,
  address: json['address'] as String,
  city: json['city'] as String,
  country: json['country'] as String,
  phone: json['phone'] as String?,
  email: json['email'] as String?,
  website: json['website'] as String?,
);

Map<String, dynamic> _$$PropertyFormDataImplToJson(
  _$PropertyFormDataImpl instance,
) => <String, dynamic>{
  'name': instance.name,
  'propertyType': instance.propertyType,
  'address': instance.address,
  'city': instance.city,
  'country': instance.country,
  'phone': instance.phone,
  'email': instance.email,
  'website': instance.website,
};

_$UnitFormDataImpl _$$UnitFormDataImplFromJson(Map<String, dynamic> json) =>
    _$UnitFormDataImpl(
      name: json['name'] as String,
      unitType: json['unitType'] as String,
      maxGuests: (json['maxGuests'] as num).toInt(),
      numBeds: (json['numBeds'] as num?)?.toInt(),
      numBathrooms: (json['numBathrooms'] as num?)?.toInt(),
      description: json['description'] as String?,
    );

Map<String, dynamic> _$$UnitFormDataImplToJson(_$UnitFormDataImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'unitType': instance.unitType,
      'maxGuests': instance.maxGuests,
      'numBeds': instance.numBeds,
      'numBathrooms': instance.numBathrooms,
      'description': instance.description,
    };

_$PricingFormDataImpl _$$PricingFormDataImplFromJson(
  Map<String, dynamic> json,
) => _$PricingFormDataImpl(
  basePrice: (json['basePrice'] as num?)?.toDouble(),
  currency: json['currency'] as String?,
);

Map<String, dynamic> _$$PricingFormDataImplToJson(
  _$PricingFormDataImpl instance,
) => <String, dynamic>{
  'basePrice': instance.basePrice,
  'currency': instance.currency,
};
