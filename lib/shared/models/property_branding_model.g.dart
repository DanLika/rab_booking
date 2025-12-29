// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'property_branding_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PropertyBrandingImpl _$$PropertyBrandingImplFromJson(
  Map<String, dynamic> json,
) => _$PropertyBrandingImpl(
  displayName: json['display_name'] as String?,
  logoUrl: json['logo_url'] as String?,
  primaryColor: json['primary_color'] as String?,
  secondaryColor: json['secondary_color'] as String?,
  faviconUrl: json['favicon_url'] as String?,
);

Map<String, dynamic> _$$PropertyBrandingImplToJson(
  _$PropertyBrandingImpl instance,
) => <String, dynamic>{
  'display_name': instance.displayName,
  'logo_url': instance.logoUrl,
  'primary_color': instance.primaryColor,
  'secondary_color': instance.secondaryColor,
  'favicon_url': instance.faviconUrl,
};
