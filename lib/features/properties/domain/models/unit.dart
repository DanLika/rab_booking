import 'package:freezed_annotation/freezed_annotation.dart';

part 'unit.freezed.dart';
part 'unit.g.dart';

/// Smještajna jedinica (apartman, soba, studio)
@freezed
class Unit with _$Unit {
  const factory Unit({
    required String id,
    required String propertyId,
    required String name,
    String? description,
    required double basePrice,
    @Default(2) int maxGuests,
    int? bedrooms,
    int? bathrooms,
    double? areaSqm,
    @Default([]) List<String> images,
    @Default([]) List<String> amenities,
    @Default(true) bool isActive,
    @Default(true) bool isAvailable,
    int? minStayNights,

    // iCal sync (for Booking.com integration - Post-MVP)
    String? icalUrl,
    DateTime? lastIcalSync,

    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Unit;

  factory Unit.fromJson(Map<String, dynamic> json) => _$UnitFromJson(json);
}
