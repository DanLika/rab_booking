import 'package:freezed_annotation/freezed_annotation.dart';

part 'guest_details.freezed.dart';
part 'guest_details.g.dart';

@freezed
class GuestDetails with _$GuestDetails {
  const factory GuestDetails({
    required String name,
    required String email,
    required String phone,
    @Default('') String message,
  }) = _GuestDetails;

  factory GuestDetails.fromJson(Map<String, dynamic> json) =>
      _$GuestDetailsFromJson(json);

  factory GuestDetails.empty() => const GuestDetails(
        name: '',
        email: '',
        phone: '',
        message: '',
      );
}
