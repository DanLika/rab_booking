import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/constants/enums.dart';

part 'property_model.freezed.dart';
part 'property_model.g.dart';

/// Property model representing a vacation rental property
@freezed
class PropertyModel with _$PropertyModel {
  const factory PropertyModel({
    /// Property ID (UUID)
    required String id,

    /// Owner user ID
    required String ownerId,

    /// Property name/title
    required String name,

    /// Detailed description
    required String description,

    /// Location (city, address, etc.)
    required String location,

    /// Latitude coordinate
    double? latitude,

    /// Longitude coordinate
    double? longitude,

    /// List of amenities
    @Default([]) List<PropertyAmenity> amenities,

    /// List of image URLs
    @Default([]) List<String> images,

    /// Main cover image URL
    String? coverImage,

    /// Average rating (0-5)
    @Default(0.0) double rating,

    /// Number of reviews
    @Default(0) int reviewCount,

    /// Property creation timestamp
    required DateTime createdAt,

    /// Last update timestamp
    DateTime? updatedAt,

    /// Is property active/published
    @Default(true) bool isActive,
  }) = _PropertyModel;

  const PropertyModel._();

  /// Create from JSON
  factory PropertyModel.fromJson(Map<String, dynamic> json) =>
      _$PropertyModelFromJson(json);

  /// Get primary image (cover or first image)
  String? get primaryImage {
    if (coverImage != null && coverImage!.isNotEmpty) {
      return coverImage;
    }
    return images.isNotEmpty ? images.first : null;
  }

  /// Check if property has images
  bool get hasImages => images.isNotEmpty || coverImage != null;

  /// Check if property has location coordinates
  bool get hasCoordinates => latitude != null && longitude != null;

  /// Get formatted rating (e.g., "4.5")
  String get formattedRating => rating.toStringAsFixed(1);

  /// Check if property has good rating (>= 4.0)
  bool get hasGoodRating => rating >= 4.0;

  /// Get amenity count
  int get amenityCount => amenities.length;

  /// Check if property has specific amenity
  bool hasAmenity(PropertyAmenity amenity) => amenities.contains(amenity);

  /// Get essential amenities
  List<PropertyAmenity> get essentialAmenities {
    return amenities.where((a) => a.isEssential).toList();
  }

  /// Get location display name (can be enhanced with parsing)
  String get locationDisplay => location;
}
