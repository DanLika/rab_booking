// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unit_wizard_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UnitWizardDraftImpl _$$UnitWizardDraftImplFromJson(
  Map<String, dynamic> json,
) => _$UnitWizardDraftImpl(
  unitId: json['unitId'] as String?,
  currentStep: (json['currentStep'] as num?)?.toInt() ?? 1,
  completedSteps:
      (json['completedSteps'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(int.parse(k), e as bool),
      ) ??
      const {},
  skippedSteps:
      (json['skippedSteps'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(int.parse(k), e as bool),
      ) ??
      const {},
  name: json['name'] as String?,
  propertyId: json['propertyId'] as String?,
  description: json['description'] as String?,
  slug: json['slug'] as String?,
  bedrooms: (json['bedrooms'] as num?)?.toInt(),
  bathrooms: (json['bathrooms'] as num?)?.toInt(),
  maxGuests: (json['maxGuests'] as num?)?.toInt(),
  areaSqm: (json['areaSqm'] as num?)?.toDouble(),
  pricePerNight: (json['pricePerNight'] as num?)?.toDouble(),
  weekendBasePrice: (json['weekendBasePrice'] as num?)?.toDouble(),
  weekendDays:
      (json['weekendDays'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const [5, 6],
  minStayNights: (json['minStayNights'] as num?)?.toInt(),
  maxStayNights: (json['maxStayNights'] as num?)?.toInt(),
  seasons:
      (json['seasons'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ??
      const [],
  availableYearRound: json['availableYearRound'] as bool? ?? true,
  seasonStartDate: json['seasonStartDate'] == null
      ? null
      : DateTime.parse(json['seasonStartDate'] as String),
  seasonEndDate: json['seasonEndDate'] == null
      ? null
      : DateTime.parse(json['seasonEndDate'] as String),
  blockedDates:
      (json['blockedDates'] as List<dynamic>?)
          ?.map((e) => DateTime.parse(e as String))
          .toList() ??
      const [],
  images:
      (json['images'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  coverImageUrl: json['coverImageUrl'] as String?,
  widgetMode: json['widgetMode'] as String?,
  widgetTheme: json['widgetTheme'] as String?,
  widgetSettings: json['widgetSettings'] as Map<String, dynamic>?,
  icalConfig: json['icalConfig'] as Map<String, dynamic>?,
  emailConfig: json['emailConfig'] as Map<String, dynamic>?,
  taxLegalConfig: json['taxLegalConfig'] as Map<String, dynamic>?,
  isPublished: json['isPublished'] as bool? ?? false,
  lastSaved: json['lastSaved'] == null
      ? null
      : DateTime.parse(json['lastSaved'] as String),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$$UnitWizardDraftImplToJson(
  _$UnitWizardDraftImpl instance,
) => <String, dynamic>{
  'unitId': instance.unitId,
  'currentStep': instance.currentStep,
  'completedSteps': instance.completedSteps.map(
    (k, e) => MapEntry(k.toString(), e),
  ),
  'skippedSteps': instance.skippedSteps.map(
    (k, e) => MapEntry(k.toString(), e),
  ),
  'name': instance.name,
  'propertyId': instance.propertyId,
  'description': instance.description,
  'slug': instance.slug,
  'bedrooms': instance.bedrooms,
  'bathrooms': instance.bathrooms,
  'maxGuests': instance.maxGuests,
  'areaSqm': instance.areaSqm,
  'pricePerNight': instance.pricePerNight,
  'weekendBasePrice': instance.weekendBasePrice,
  'weekendDays': instance.weekendDays,
  'minStayNights': instance.minStayNights,
  'maxStayNights': instance.maxStayNights,
  'seasons': instance.seasons,
  'availableYearRound': instance.availableYearRound,
  'seasonStartDate': instance.seasonStartDate?.toIso8601String(),
  'seasonEndDate': instance.seasonEndDate?.toIso8601String(),
  'blockedDates': instance.blockedDates
      .map((e) => e.toIso8601String())
      .toList(),
  'images': instance.images,
  'coverImageUrl': instance.coverImageUrl,
  'widgetMode': instance.widgetMode,
  'widgetTheme': instance.widgetTheme,
  'widgetSettings': instance.widgetSettings,
  'icalConfig': instance.icalConfig,
  'emailConfig': instance.emailConfig,
  'taxLegalConfig': instance.taxLegalConfig,
  'isPublished': instance.isPublished,
  'lastSaved': instance.lastSaved?.toIso8601String(),
  'createdAt': instance.createdAt?.toIso8601String(),
};
