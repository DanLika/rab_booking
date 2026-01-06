import 'package:freezed_annotation/freezed_annotation.dart';

part 'guest_pii_model.freezed.dart';
part 'guest_pii_model.g.dart';

/// Model for storing Guest's Personally Identifiable Information (PII)
/// This is kept separate from the main BookingModel to prevent accidental exposure.
@freezed
class GuestPiiModel with _$GuestPiiModel {
  const factory GuestPiiModel({
    /// Guest name
    @JsonKey(name: 'guest_name') String? guestName,

    /// Guest email
    @JsonKey(name: 'guest_email') String? guestEmail,

    /// Guest phone
    @JsonKey(name: 'guest_phone') String? guestPhone,
  }) = _GuestPiiModel;

  /// Create from JSON
  factory GuestPiiModel.fromJson(Map<String, dynamic> json) =>
      _$GuestPiiModelFromJson(json);
}
