import 'package:freezed_annotation/freezed_annotation.dart';

part 'property_unit.freezed.dart';
part 'property_unit.g.dart';

/// Unit model (rooms/apartments within a property)
@freezed
class PropertyUnit with _$PropertyUnit {
  const factory PropertyUnit({
    required String id,
    required String propertyId,
    required String name,
    String? description,
    required double pricePerNight,
    required int maxGuests,
    required int bedrooms,
    required int bathrooms,
    required double area,
    @Default([]) List<String> amenities,
    @Default([]) List<String> images,
    String? coverImage,
    @Default(1) int quantity,
    @Default(1) int minStayNights,
    @Default(true) bool isAvailable,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _PropertyUnit;

  factory PropertyUnit.fromJson(Map<String, dynamic> json) =>
      _$PropertyUnitFromJson(json);
}
