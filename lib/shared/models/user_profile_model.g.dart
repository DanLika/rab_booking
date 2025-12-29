// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AddressImpl _$$AddressImplFromJson(Map<String, dynamic> json) =>
    _$AddressImpl(
      country: json['country'] as String? ?? '',
      city: json['city'] as String? ?? '',
      street: json['street'] as String? ?? '',
      postalCode: json['postalCode'] as String? ?? '',
    );

Map<String, dynamic> _$$AddressImplToJson(_$AddressImpl instance) =>
    <String, dynamic>{
      'country': instance.country,
      'city': instance.city,
      'street': instance.street,
      'postalCode': instance.postalCode,
    };

_$SocialLinksImpl _$$SocialLinksImplFromJson(Map<String, dynamic> json) =>
    _$SocialLinksImpl(
      website: json['website'] as String? ?? '',
      facebook: json['facebook'] as String? ?? '',
    );

Map<String, dynamic> _$$SocialLinksImplToJson(_$SocialLinksImpl instance) =>
    <String, dynamic>{
      'website': instance.website,
      'facebook': instance.facebook,
    };

_$CompanyDetailsImpl _$$CompanyDetailsImplFromJson(Map<String, dynamic> json) =>
    _$CompanyDetailsImpl(
      companyName: json['companyName'] as String? ?? '',
      taxId: json['taxId'] as String? ?? '',
      vatId: json['vatId'] as String? ?? '',
      bankAccountIban: json['bankAccountIban'] as String? ?? '',
      swift: json['swift'] as String? ?? '',
      bankName: json['bankName'] as String? ?? '',
      accountHolder: json['accountHolder'] as String? ?? '',
      address: json['address'] == null
          ? const Address()
          : Address.fromJson(json['address'] as Map<String, dynamic>),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$CompanyDetailsImplToJson(
  _$CompanyDetailsImpl instance,
) => <String, dynamic>{
  'companyName': instance.companyName,
  'taxId': instance.taxId,
  'vatId': instance.vatId,
  'bankAccountIban': instance.bankAccountIban,
  'swift': instance.swift,
  'bankName': instance.bankName,
  'accountHolder': instance.accountHolder,
  'address': instance.address,
  'updatedAt': instance.updatedAt?.toIso8601String(),
};

_$UserProfileImpl _$$UserProfileImplFromJson(Map<String, dynamic> json) =>
    _$UserProfileImpl(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String? ?? '',
      emailContact: json['emailContact'] as String? ?? '',
      phoneE164: json['phoneE164'] as String? ?? '',
      address: json['address'] == null
          ? const Address()
          : Address.fromJson(json['address'] as Map<String, dynamic>),
      social: json['social'] == null
          ? const SocialLinks()
          : SocialLinks.fromJson(json['social'] as Map<String, dynamic>),
      propertyType: json['propertyType'] as String? ?? '',
      logoUrl: json['logoUrl'] as String? ?? '',
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$UserProfileImplToJson(_$UserProfileImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'displayName': instance.displayName,
      'emailContact': instance.emailContact,
      'phoneE164': instance.phoneE164,
      'address': instance.address,
      'social': instance.social,
      'propertyType': instance.propertyType,
      'logoUrl': instance.logoUrl,
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

_$UserDataImpl _$$UserDataImplFromJson(Map<String, dynamic> json) =>
    _$UserDataImpl(
      profile: UserProfile.fromJson(json['profile'] as Map<String, dynamic>),
      company: json['company'] == null
          ? const CompanyDetails()
          : CompanyDetails.fromJson(json['company'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$UserDataImplToJson(_$UserDataImpl instance) =>
    <String, dynamic>{'profile': instance.profile, 'company': instance.company};
