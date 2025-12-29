// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NotificationModelImpl _$$NotificationModelImplFromJson(
  Map<String, dynamic> json,
) => _$NotificationModelImpl(
  id: json['id'] as String,
  ownerId: json['ownerId'] as String,
  type: $enumDecode(_$NotificationTypeEnumMap, json['type']),
  title: json['title'] as String,
  message: json['message'] as String,
  timestamp: DateTime.parse(json['timestamp'] as String),
  isRead: json['isRead'] as bool? ?? false,
  bookingId: json['bookingId'] as String?,
  metadata: json['metadata'] as Map<String, dynamic>?,
  titleKey: json['titleKey'] as String?,
  messageKey: json['messageKey'] as String?,
);

Map<String, dynamic> _$$NotificationModelImplToJson(
  _$NotificationModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'ownerId': instance.ownerId,
  'type': _$NotificationTypeEnumMap[instance.type]!,
  'title': instance.title,
  'message': instance.message,
  'timestamp': instance.timestamp.toIso8601String(),
  'isRead': instance.isRead,
  'bookingId': instance.bookingId,
  'metadata': instance.metadata,
  'titleKey': instance.titleKey,
  'messageKey': instance.messageKey,
};

const _$NotificationTypeEnumMap = {
  NotificationType.bookingCreated: 'booking_created',
  NotificationType.bookingUpdated: 'booking_updated',
  NotificationType.bookingCancelled: 'booking_cancelled',
  NotificationType.paymentReceived: 'payment_received',
  NotificationType.system: 'system',
};
