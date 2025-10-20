import 'package:freezed_annotation/freezed_annotation.dart';

part 'property_unit.freezed.dart';
part 'property_unit.g.dart';

/// Unit model (rooms/apartments within a property)
@freezed
class PropertyUnit with _$PropertyUnit {
  const factory PropertyUnit({
    required String id,
    @JsonKey(name: 'property_id') required String propertyId,
    required String name,
    String? description,
    @JsonKey(name: 'base_price') required double pricePerNight,
    @JsonKey(name: 'max_guests') required int maxGuests,
    required int bedrooms,
    required int bathrooms,
    required double area,
    @Default([]) List<String> amenities,
    @Default([]) List<String> images,
    @JsonKey(name: 'cover_image') String? coverImage,
    @Default(1) int quantity,
    @JsonKey(name: 'min_stay_nights') @Default(1) int minStayNights,
    @JsonKey(name: 'is_available') @Default(true) bool isAvailable,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _PropertyUnit;

  factory PropertyUnit.fromJson(Map<String, dynamic> json) =>
      _$PropertyUnitFromJson(json);
}
