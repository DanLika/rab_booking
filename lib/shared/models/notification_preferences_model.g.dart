// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_preferences_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NotificationChannelsImpl _$$NotificationChannelsImplFromJson(
  Map<String, dynamic> json,
) => _$NotificationChannelsImpl(
  email: json['email'] as bool? ?? true,
  push: json['push'] as bool? ?? true,
  sms: json['sms'] as bool? ?? false,
);

Map<String, dynamic> _$$NotificationChannelsImplToJson(
  _$NotificationChannelsImpl instance,
) => <String, dynamic>{
  'email': instance.email,
  'push': instance.push,
  'sms': instance.sms,
};

_$NotificationCategoriesImpl _$$NotificationCategoriesImplFromJson(
  Map<String, dynamic> json,
) => _$NotificationCategoriesImpl(
  bookings: json['bookings'] == null
      ? const NotificationChannels()
      : NotificationChannels.fromJson(json['bookings'] as Map<String, dynamic>),
  payments: json['payments'] == null
      ? const NotificationChannels()
      : NotificationChannels.fromJson(json['payments'] as Map<String, dynamic>),
  calendar: json['calendar'] == null
      ? const NotificationChannels()
      : NotificationChannels.fromJson(json['calendar'] as Map<String, dynamic>),
  marketing: json['marketing'] == null
      ? const NotificationChannels(email: false, push: false)
      : NotificationChannels.fromJson(
          json['marketing'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$$NotificationCategoriesImplToJson(
  _$NotificationCategoriesImpl instance,
) => <String, dynamic>{
  'bookings': instance.bookings,
  'payments': instance.payments,
  'calendar': instance.calendar,
  'marketing': instance.marketing,
};

_$NotificationPreferencesImpl _$$NotificationPreferencesImplFromJson(
  Map<String, dynamic> json,
) => _$NotificationPreferencesImpl(
  userId: json['userId'] as String,
  masterEnabled: json['masterEnabled'] as bool? ?? true,
  categories: json['categories'] == null
      ? const NotificationCategories()
      : NotificationCategories.fromJson(
          json['categories'] as Map<String, dynamic>,
        ),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$$NotificationPreferencesImplToJson(
  _$NotificationPreferencesImpl instance,
) => <String, dynamic>{
  'userId': instance.userId,
  'masterEnabled': instance.masterEnabled,
  'categories': instance.categories,
  'updatedAt': instance.updatedAt?.toIso8601String(),
};
