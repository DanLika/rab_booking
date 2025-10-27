import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_preferences_model.freezed.dart';
part 'notification_preferences_model.g.dart';

/// Notification channels for a specific category
@freezed
class NotificationChannels with _$NotificationChannels {
  const factory NotificationChannels({
    @Default(true) bool email,
    @Default(true) bool push,
    @Default(false) bool sms,
  }) = _NotificationChannels;

  factory NotificationChannels.fromJson(Map<String, dynamic> json) =>
      _$NotificationChannelsFromJson(json);
}

/// Notification categories
@freezed
class NotificationCategories with _$NotificationCategories {
  const factory NotificationCategories({
    @Default(NotificationChannels()) NotificationChannels bookings,
    @Default(NotificationChannels()) NotificationChannels payments,
    @Default(NotificationChannels()) NotificationChannels calendar,
    @Default(NotificationChannels(email: false, push: false))
        NotificationChannels marketing,
  }) = _NotificationCategories;

  factory NotificationCategories.fromJson(Map<String, dynamic> json) =>
      _$NotificationCategoriesFromJson(json);
}

/// User notification preferences (stored in Firestore: users/{userId}/preferences)
@freezed
class NotificationPreferences with _$NotificationPreferences {
  const NotificationPreferences._();

  const factory NotificationPreferences({
    required String userId,
    @Default(true) bool masterEnabled,
    @Default(NotificationCategories()) NotificationCategories categories,
    DateTime? updatedAt,
  }) = _NotificationPreferences;

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      _$NotificationPreferencesFromJson(json);

  factory NotificationPreferences.fromFirestore(
    String userId,
    Map<String, dynamic> data,
  ) {
    return NotificationPreferences(
      userId: userId,
      masterEnabled: data['masterEnabled'] as bool? ?? true,
      categories: data['categories'] != null
          ? NotificationCategories.fromJson(
              data['categories'] as Map<String, dynamic>,
            )
          : const NotificationCategories(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert to Firestore data (exclude userId)
  Map<String, dynamic> toFirestore() {
    return {
      'masterEnabled': masterEnabled,
      'categories': categories.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
