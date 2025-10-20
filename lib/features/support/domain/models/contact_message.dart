import 'package:freezed_annotation/freezed_annotation.dart';

part 'contact_message.freezed.dart';
part 'contact_message.g.dart';

@freezed
class ContactMessage with _$ContactMessage {
  const factory ContactMessage({
    String? id,
    required String name,
    required String email,
    required String subject,
    required String message,
    String? userId,
    @Default('new') String status,
    DateTime? createdAt,
  }) = _ContactMessage;

  factory ContactMessage.fromJson(Map<String, dynamic> json) =>
      _$ContactMessageFromJson(json);
}
